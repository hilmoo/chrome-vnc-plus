FROM node:22-bookworm-slim AS node

FROM debian:bookworm-slim

ARG CHROME_DEVTOOLS_MCP_VERSION=1.12.0
ARG SUPERGATEWAY_VERSION=4.2.1
ENV DEBIAN_FRONTEND=noninteractive

# Node 22 (required by chrome-devtools-mcp) copied from the official image
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -s ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl gnupg tini supervisor \
      xvfb openbox x11vnc novnc websockify x11-utils xdotool imagemagick \
      python3 socat procps fonts-liberation fonts-noto-color-emoji dbus-x11 \
 && ARCH="$(dpkg --print-architecture)" \
 && if [ "$ARCH" = "amd64" ]; then \
      curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google.gpg \
      && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list \
      && apt-get update && apt-get install -y --no-install-recommends google-chrome-stable \
      && ln -s /usr/bin/google-chrome-stable /usr/local/bin/browser; \
    else \
      apt-get install -y --no-install-recommends chromium \
      && ln -s /usr/bin/chromium /usr/local/bin/browser; \
    fi \
 && rm -rf /var/lib/apt/lists/*

# Pre-install MCP packages so nothing is downloaded at runtime
RUN npm install -g chrome-devtools-mcp@${CHROME_DEVTOOLS_MCP_VERSION} supergateway@${SUPERGATEWAY_VERSION} \
 && npm cache clean --force

RUN useradd -m -u 1000 -s /bin/bash chrome && mkdir -p /data && chown chrome:chrome /data

COPY rootfs/ /
RUN chmod +x /usr/local/bin/*

ENV DISPLAY=:0 \
    RESOLUTION=1280x720 DEPTH=24 \
    VNC_PASSWORD= VNC_VIEW_PASSWORD= \
    START_URL=about:blank \
    CHROME_ARGS= CHROME_EXTRA_ARGS= \
    CHROME_PROFILE_DIR=/data/profile \
    CDP_PORT=9222 \
    WATCHDOG_INTERVAL=5 WATCHDOG_FAILURES=3 WATCHDOG_GRACE=30 \
    API_TOKEN= \
    MCP_ENABLED=true MCP_PORT=8931 MCP_EXTRA_ARGS= \
    CDP_PROXY_PORT=

VOLUME /data
# 6080 noVNC interactive | 6081 noVNC view-only | 5900/5901 raw VNC | 8080 screenshot API | 8931 MCP
EXPOSE 5900 5901 6080 6081 8080 8931
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s CMD curl -fs http://127.0.0.1:8080/healthz || exit 1
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
