#!/bin/sh
set -e

echo "[esphome-mcp] starting"

DASHBOARD_URL="${ESPHOME_DASHBOARD_URL:-}"
if [ -f /data/options.json ]; then
  VAL="$(python3 -c 'import json,sys; print(json.load(open("/data/options.json")).get("esphome_dashboard_url",""))' 2>/dev/null || true)"
  [ -n "$VAL" ] && DASHBOARD_URL="$VAL"
fi

if [ -z "$DASHBOARD_URL" ]; then
  echo "[esphome-mcp] ERROR: esphome_dashboard_url not set" >&2
  exit 1
fi

export ESPHOME_DASHBOARD_URL="$DASHBOARD_URL"
echo "[esphome-mcp] dashboard: $DASHBOARD_URL"
echo "[esphome-mcp] serving MCP over HTTP at :8080/mcp"

exec esphome-mcp-web