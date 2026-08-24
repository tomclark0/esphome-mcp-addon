# ESPHome MCP — Home Assistant Add-on

A Home Assistant add-on wrapping [loryanstrant/ESPHome-MCP](https://github.com/loryanstrant/ESPHome-MCP) — an MCP (Model Context Protocol) server that exposes ESPHome Device Builder operations over Streamable HTTP.

With this add-on you can interact with your ESPHome devices through any MCP-compatible client (Claude Desktop, VS Code, OpenCode, etc.) at `http://<your-ha-host>:28080/mcp`.

## Prerequisites

- A running [Home Assistant](https://www.home-assistant.io/) installation with Supervisor (HAOS or Supervised).
- An ESPHome dashboard reachable from the add-on's container (e.g. the official ESPHome add-on or a standalone instance).

## Installation

1. Add this repository to your Home Assistant add-on store:

   ```
   https://github.com/tomclark0/esphome-mcp-addon
   ```

   In Home Assistant, go to **Settings** → **Add-ons** → **Add-on Store** → ⋮ (menu) → **Repositories**, paste the URL, and click **Add**.

2. Find **ESPHome MCP** in the add-on store and click **Install**.

3. Switch to the **Configuration** tab and set:

   ```yaml
   esphome_dashboard_url: "http://<your-esphome-host>:6052"
   ```

   Replace `<your-esphome-host>` with the hostname or IP of your ESPHome dashboard. If you run the official ESPHome add-on, the hostname is usually the add-on slug (e.g. `a0d7b954-esphome`).

4. Start the add-on.

## Configuration

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `esphome_dashboard_url` | `string` | **yes** | Full URL to your ESPHome dashboard (e.g. `http://localhost:6052` or `http://a0d7b954-esphome:6052`). |

You can also set the `ESPHOME_DASHBOARD_URL` environment variable as an override. The add-on will refuse to start if no URL is configured.

### Ports

The add-on exposes **TCP port 28080** on the host (mapped from container port 8080). The MCP endpoint is served at:

```
http://<your-ha-host>:28080/mcp
```

## Usage

Once the add-on is running, configure your MCP client to connect to the Streamable HTTP endpoint.

For example, in an MCP client configuration:

```json
{
  "mcpServers": {
    "esphome-mcp": {
      "type": "streamableHttp",
      "url": "http://<your-ha-host>:28080/mcp"
    }
  }
}
```

You can then ask the MCP client to list devices, compile firmware, upload, etc.

## Updating

### Add-on updates

When a new version of the add-on is published, Home Assistant will notify you in the add-on store. Update as usual.

Alternatively, rebuild locally:

```bash
# From the repo root, for a single architecture:
docker build \
  --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base-python:latest \
  -t esphome-mcp-local \
  esphome-mcp/
docker run --rm -p 28080:8080 -e ESPHOME_DASHBOARD_URL=http://your-esphome:6052 esphome-mcp-local
```

### Upstream sync (ESPHome-MCP)

This add-on pins a specific commit of [loryanstrant/ESPHome-MCP](https://github.com/loryanstrant/ESPHome-MCP) in `esphome-mcp/Dockerfile`. To update to the latest upstream:

```bash
./scripts/sync-upstream.sh
```

This fetches the latest upstream commit, updates the Dockerfile pin, and creates a commit. See the script for details and optional flags.

**Recommended cadence:** check upstream weekly. Always test after a sync by rebuilding (see above) and verifying the MCP handshake works (connect a client and list devices).

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Add-on won't start, "esphome_dashboard_url is not set" | Set the config option or the `ESPHOME_DASHBOARD_URL` env var. |
| Can't reach ESPHome dashboard | Check the dashboard hostname is reachable from within Home Assistant's Docker network. Use the add-on slug if the dashboard is another add-on. |
| Port already in use (28080) | Change the host port in the add-on configuration under **Network**. |
| MCP client can't connect | Verify the add-on is running and the port mapping is correct. Try `curl http://<ha-host>:28080/mcp`. |
| Rebuild fails on cache | Remove and re-add the repository in the add-on store to force a fresh pull. |

## Repository layout

```
esphome-mcp-addon/
├── repository.json              # HA add-on repository manifest
├── README.md
├── scripts/
│   └── sync-upstream.sh         # Upstream pin-sync tool
└── esphome-mcp/
    ├── config.yaml              # Add-on definition
    ├── Dockerfile               # Build recipe (pins loryanstrant/ESPHome-MCP)
    ├── build.yaml               # Per-architecture base images
    └── run.sh                   # Entrypoint script
```

## License

This add-on packaging is provided as-is. The upstream ESPHome-MCP project is maintained by [loryanstrant](https://github.com/loryanstrant/ESPHome-MCP).