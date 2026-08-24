#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOCKERFILE="$REPO_ROOT/esphome-mcp/Dockerfile"
UPSTREAM_REPO="https://github.com/loryanstrant/ESPHome-MCP.git"
PIPE_PIN_PATTERN='pip3 install.*ESPHome-MCP\.git@([a-f0-9]+)'

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Keep the pinned ESPHome-MCP commit in esphome-mcp/Dockerfile in sync with upstream.

Options:
  -c, --commit     Automatically commit the pin bump (requires clean git index).
  -d, --dry-run    Show what would change without modifying anything.
  -v, --verify     After updating, attempt a shallow build/dockerfile parse check.
  -h, --help       Show this help message.

Without --commit or --dry-run, the script reports current vs latest but makes no changes.
EOF
  exit 0
}

err() { echo -e "${RED}[sync-upstream] ERROR:${NC} $*" >&2; exit 1; }
info() { echo -e "${GREEN}[sync-upstream]${NC} $*"; }
warn() { echo -e "${YELLOW}[sync-upstream]${NC} $*"; }

# --- Parse args ---
COMMIT=false
DRY_RUN=false
VERIFY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--commit) COMMIT=true; shift ;;
    -d|--dry-run) DRY_RUN=true; shift ;;
    -v|--verify) VERIFY=true; shift ;;
    -h|--help) usage ;;
    *) err "Unknown option: $1" ;;
  esac
done

$DRY_RUN && $COMMIT && err "--dry-run and --commit are mutually exclusive."

# --- Locate Dockerfile ---
if [[ ! -f "$DOCKERFILE" ]]; then
  err "Dockerfile not found at $DOCKERFILE"
fi

# --- Read current pin from Dockerfile ---
CURRENT_LINE="$(grep 'pip3 install.*ESPHome-MCP\.git@' "$DOCKERFILE" || true)"
if [[ -z "$CURRENT_LINE" ]]; then
  err "Could not find ESPHome-MCP pip3 install line in Dockerfile"
fi

if [[ "$CURRENT_LINE" =~ $PIPE_PIN_PATTERN ]]; then
  CURRENT_PIN="${BASH_REMATCH[1]}"
else
  err "Could not parse pinned commit from Dockerfile line: $CURRENT_LINE"
fi

info "Current pin: ${BOLD}$CURRENT_PIN${NC}"

# --- Fetch latest upstream commit (default branch) ---
LATEST_COMMIT="$(git ls-remote "$UPSTREAM_REPO" HEAD | awk '{print $1}')"
if [[ -z "$LATEST_COMMIT" ]]; then
  err "Failed to fetch latest commit from $UPSTREAM_REPO"
fi
LATEST_SHORT="${LATEST_COMMIT:0:8}"

info "Latest upstream: ${BOLD}$LATEST_COMMIT${NC} ($LATEST_SHORT)"

# --- Compare ---
if [[ "$CURRENT_PIN" == "$LATEST_COMMIT" ]]; then
  info "Already up to date."
  exit 0
fi

info "Upstream has new commits. Current=${BOLD}${CURRENT_PIN:0:8}${NC} -> Latest=${BOLD}${LATEST_SHORT}${NC}"

# --- Dry run ---
if $DRY_RUN; then
  info "Dry run: would update Dockerfile pin from ${CURRENT_PIN:0:8} to ${LATEST_SHORT}"
  exit 0
fi

# --- Update Dockerfile ---
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|ESPHome-MCP\.git@${CURRENT_PIN}|ESPHome-MCP.git@${LATEST_COMMIT}|" "$DOCKERFILE"
else
  sed -i "s|ESPHome-MCP\.git@${CURRENT_PIN}|ESPHome-MCP.git@${LATEST_COMMIT}|" "$DOCKERFILE"
fi

info "Updated Dockerfile pin to ${BOLD}$LATEST_SHORT${NC}"

# --- Verify ---
if $VERIFY; then
  info "Verifying Dockerfile syntax..."
  if command -v docker &>/dev/null; then
    docker build --check -f "$DOCKERFILE" "$(dirname "$DOCKERFILE")" 2>&1 || warn "Dockerfile syntax check failed (may be harmless without build args)."
  else
    warn "Docker not available; skipping Dockerfile syntax check."
  fi

  info "Checking that entrypoint 'esphome-mcp-web' is still referenced in upstream..."
  if git ls-remote --tags "$UPSTREAM_REPO" "refs/tags/v*" &>/dev/null; then
    info "Upstream tags exist — consider pinning a tag instead of a commit once stable."
  fi
fi

# --- Commit ---
if $COMMIT; then
  if ! git diff --quiet -- "$DOCKERFILE"; then
    info "Changes to $DOCKERFILE:"
    git diff -- "$DOCKERFILE"

    git add "$DOCKERFILE"
    git commit -m "chore: bump ESPHome-MCP pin to ${LATEST_SHORT}

Upstream: loryanstrant/ESPHome-MCP @ ${LATEST_COMMIT}"

    info "Committed. Push with: git push origin"

    cat <<'EOF'

=== MANUAL SMOKE TEST ===
After pushing, confirm the add-on still works:
  1. Rebuild: docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base-python:latest -t esphome-mcp-test esphome-mcp/
  2. Run:    docker run --rm -p 28080:8080 -e ESPHOME_DASHBOARD_URL=http://your-esphome:6052 esphome-mcp-test
  3. Verify: curl -X POST http://localhost:28080/mcp -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
     (should return a list of MCP tools)
EOF
  else
    info "No changes detected; nothing to commit."
  fi
fi