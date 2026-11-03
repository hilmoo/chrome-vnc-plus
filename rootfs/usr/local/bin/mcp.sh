#!/bin/bash
# chrome-devtools-mcp (pinned in Dockerfile) attached to the running Chrome, exposed as Streamable HTTP at :$MCP_PORT/mcp
while ! curl -fs "http://127.0.0.1:$CDP_PORT/json/version" >/dev/null; do sleep 1; done
exec supergateway --outputTransport streamableHttp --port "$MCP_PORT" --stateful \
  --stdio "chrome-devtools-mcp --no-usage-statistics --browserUrl http://127.0.0.1:$CDP_PORT $MCP_EXTRA_ARGS"
