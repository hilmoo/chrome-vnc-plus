#!/bin/bash
# optional: expose Chrome's CDP (bound to localhost) on $CDP_PROXY_PORT
[ -z "$CDP_PROXY_PORT" ] && exec sleep infinity
exec socat TCP-LISTEN:"$CDP_PROXY_PORT",fork,reuseaddr TCP:127.0.0.1:"$CDP_PORT"
