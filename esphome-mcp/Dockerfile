ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-python:latest
FROM ${BUILD_FROM}

RUN apk add --no-cache git gcc musl-dev python3-dev \
 && pip3 install --no-cache-dir "git+https://github.com/loryanstrant/ESPHome-MCP.git@9fd5c36f86622baaca585bc512674e434c8bb6e4" \
 && apk del git gcc musl-dev python3-dev

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]