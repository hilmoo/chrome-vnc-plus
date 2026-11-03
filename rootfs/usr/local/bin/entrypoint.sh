#!/bin/bash
set -e
mkdir -p /data "$CHROME_PROFILE_DIR"
chown chrome:chrome /data "$CHROME_PROFILE_DIR"
# stale locks from a previous (killed) container
rm -f "$CHROME_PROFILE_DIR"/Singleton{Lock,Cookie,Socket} /tmp/.X0-lock /tmp/.X11-unix/X0

# VNC passwords: interactive port uses VNC_PASSWORD, view-only uses VNC_VIEW_PASSWORD (falls back to VNC_PASSWORD)
mkdir -p /etc/vnc
rm -f /etc/vnc/rw.pass /etc/vnc/ro.pass
[ -n "$VNC_PASSWORD" ] && x11vnc -storepasswd "$VNC_PASSWORD" /etc/vnc/rw.pass >/dev/null
VIEW_PW="${VNC_VIEW_PASSWORD:-$VNC_PASSWORD}"
[ -n "$VIEW_PW" ] && x11vnc -storepasswd "$VIEW_PW" /etc/vnc/ro.pass >/dev/null
chown -R chrome:chrome /etc/vnc

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
