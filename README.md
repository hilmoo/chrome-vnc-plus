# chrome-vnc-plus

chrome-vnc-plus runs Chrome in a Docker container with a lightweight desktop (Xvfb + Openbox), VNC / noVNC access
(interactive and view-only), a screenshot API, an always-on watchdog and
[`chrome-devtools-mcp`](https://github.com/ChromeDevTools/chrome-devtools-mcp) exposed over HTTP.

## Quick start

```bash
cp .env.example .env      # edit passwords etc.
docker compose up -d --build
```

| What | URL / port |
|---|---|
| noVNC, interactive | http://localhost:6080/vnc.html |
| noVNC, view-only | http://localhost:6081/vnc.html |
| Raw VNC, interactive / view-only | `5900` / `5901` |
| Screenshot of the whole desktop | `GET http://localhost:8080/screenshot` (`?format=jpg` for JPEG) |
| Health check | `GET http://localhost:8080/healthz` |
| MCP (streamable HTTP) | `http://localhost:8931/mcp` |

MCP client config:

```json
{ "mcpServers": { "chrome-devtools": { "url": "http://localhost:8931/mcp" } } }
```

## How it works

- **Desktop:** Xvfb at `RESOLUTION` with Openbox. Openbox maximizes every window without decorations,
  so both VNC servers effectively show only the Chrome window.
- **View-only:** a second `x11vnc -viewonly` server, so it is enforced server-side.
- **Watchdog:** supervisord runs Chrome with `autorestart`; if Chrome exits it comes straight back.
- **Persistence:** the profile lives in `CHROME_PROFILE_DIR` (default `/data/profile`), backed by the `chrome-data` volume.
- **MCP:** `chrome-devtools-mcp` (version pinned in the `Dockerfile`) attaches to the running Chrome through its
  debugging port (`--browserUrl`), so MCP and VNC viewers share the same browser. `supergateway` turns the stdio server into HTTP.
- Services are split into `rootfs/etc/supervisor/conf.d/*.conf`.

## Configuration (environment variables)

| Variable | Default | Description |
|---|---|---|
| `RESOLUTION` | `1280x720` | Screen / Chrome window size |
| `DEPTH` | `24` | Color depth |
| `START_URL` | `about:blank` | Page opened on launch |
| `CHROME_ARGS` | *(built-in list in `chrome.sh`)* | Replaces the default Chrome flags |
| `CHROME_EXTRA_ARGS` | | Appended to the default flags |
| `CHROME_PROFILE_DIR` | `/data/profile` | Chrome user-data dir (persistent) |
| `CDP_PORT` | `9222` | Chrome debugging port (localhost inside the container) |
| `CDP_PROXY_PORT` | | If set, forwards this port to the debugging port (publish it yourself) |
| `VNC_PASSWORD` | | Interactive VNC password (empty = none) |
| `VNC_VIEW_PASSWORD` | `VNC_PASSWORD` | View-only VNC password |
| `VNC_RW_ENABLED` / `VNC_RO_ENABLED` | `true` | Start the raw VNC servers |
| `NOVNC_RW_ENABLED` / `NOVNC_RO_ENABLED` | `true` | Start the noVNC web pages (need their matching VNC server) |
| `API_TOKEN` | | Protects `/screenshot` (`?token=` or `Authorization: Bearer`) |
| `MCP_ENABLED` | `true` | Start the MCP server |
| `MCP_PORT` | `8931` | MCP HTTP port |
| `MCP_EXTRA_ARGS` | | Extra `chrome-devtools-mcp` flags |

## Security notes

- Chrome runs with `--no-sandbox` (usual for containers). Don't browse untrusted sites on a shared host without hardening.
- Set `VNC_PASSWORD` and `API_TOKEN`, and bind ports to `127.0.0.1` in `compose.yaml` if the host is not trusted.
  The MCP endpoint has **no authentication**.
- On amd64 the image ships Google Chrome; on other architectures it falls back to Chromium.

## Releases

Images are published to `ghcr.io/<owner>/<repo>` by GitHub Actions: `edge` from `main`, and
`X.Y.Z`, `X.Y`, `X`, `latest` from `vX.Y.Z` tags. Use [Task](https://taskfile.dev):

```bash
task version               # show current / next versions
task release:patch         # or release:minor / release:major
task release -- 1.4.0      # explicit version
DRY=true task release:patch
```

Renovate keeps the base images, GitHub Actions, `supergateway` and `chrome-devtools-mcp` up to date.

## Disclaimer

chrome-vnc-plus is an independent project, not affiliated with or endorsed by Google. "Chrome" is a trademark of Google LLC.

## License

[MIT](LICENSE)
