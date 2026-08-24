ARG BUILD_FROM
FROM ${BUILD_FROM}

# ---- Base image ----
# The loryanstrant ESPHome-MCP server only talks HTTP/WebSocket to the ESPHome
# dashboard add-on over the network. It does NOT need the ESPHome CLI or
# PlatformIO toolchain in this container, so we build on the lightweight
# homeassistant base (BUILD_FROM set in build.yaml) instead of the full
# ESPHome add-on image.

# Ensure git + pip are present (HOMEASSISTANT base has python/pip).
RUN (command -v git >/dev/null 2>&1 || apt-get update && apt-get install -y --no-install-recommends git) \
 && (command -v pip3 >/dev/null 2>&1 || apt-get update && apt-get install -y --no-install-recommends python3-pip)

# Install loryanstrant/ESPHome-MCP, pinned to the exact commit we have verified.
RUN pip3 install --no-cache-dir "git+https://github.com/loryanstrant/ESPHome-MCP.git@47b9d42d"

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]