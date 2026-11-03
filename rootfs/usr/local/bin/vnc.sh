#!/bin/bash
# usage: vnc.sh rw|ro PORT
MODE=$1; PORT=$2
export DISPLAY="${DISPLAY:-:0}"
while ! xdpyinfo >/dev/null 2>&1; do sleep 0.5; done
AUTH=(-nopw); [ -f /etc/vnc/$MODE.pass ] && AUTH=(-rfbauth /etc/vnc/$MODE.pass)
OPTS=(-forever -shared -noxdamage -rfbport "$PORT" -quiet)
[ "$MODE" = ro ] && OPTS+=(-viewonly)
# Chrome is maximized & undecorated, so the framebuffer == the Chrome window.
exec x11vnc -display "$DISPLAY" "${AUTH[@]}" "${OPTS[@]}"
