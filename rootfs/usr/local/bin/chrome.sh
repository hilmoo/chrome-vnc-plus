#!/bin/bash
# Launched and restarted by supervisord (autorestart=true) -> that is the watchdog.
export DISPLAY="${DISPLAY:-:0}"
while ! xdpyinfo >/dev/null 2>&1; do sleep 0.5; done
rm -f "$CHROME_PROFILE_DIR"/Singleton{Lock,Cookie,Socket}   # stale lock after a crash

# CHROME_ARGS replaces these defaults, CHROME_EXTRA_ARGS appends to them
DEFAULT_ARGS=(
  --no-sandbox
  --disable-dev-shm-usage
  --disable-gpu
  --disable-features=UseOzonePlatform
  --start-maximized
  --no-first-run
  --no-default-browser-check
  --disable-infobars
  --disable-extensions
  --disable-translate
  --disable-sync
  --password-store=basic
  --autoplay-policy=no-user-gesture-required
  --disable-logging
  --disable-breakpad
  --disable-component-update
)
# shellcheck disable=SC2206
ARGS=(${CHROME_ARGS:-${DEFAULT_ARGS[@]}} $CHROME_EXTRA_ARGS)

exec browser "${ARGS[@]}" \
  --user-data-dir="$CHROME_PROFILE_DIR" \
  --remote-debugging-port="$CDP_PORT" --remote-debugging-address=127.0.0.1 \
  --window-position=0,0 --window-size="${RESOLUTION%x*},${RESOLUTION#*x}" \
  "$START_URL"
