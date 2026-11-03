#!/bin/bash
# Launched and restarted by supervisord (autorestart=true) -> that is the watchdog.
export DISPLAY="${DISPLAY:-:0}"
while ! xdpyinfo >/dev/null 2>&1; do sleep 0.5; done
rm -f "$CHROME_PROFILE_DIR"/Singleton{Lock,Cookie,Socket}   # stale lock after a crash

# RESTORE_SESSION=true (default): reopen the tabs from last run, and open START_URL only on first run.
# RESTORE_SESSION=false: always start fresh with START_URL.
PREFS="$CHROME_PROFILE_DIR/Default/Preferences"
# Mark the last exit as clean so Chrome restores silently (no "Restore pages?" bubble)
if [ "${RESTORE_SESSION,,}" = "true" ] && [ -f "$PREFS" ]; then
  sed -i 's/"exit_type":"[^"]*"/"exit_type":"Normal"/; s/"exited_cleanly":false/"exited_cleanly":true/' "$PREFS"
fi

if [ "${RESTORE_SESSION,,}" = "true" ] && [ -d "$CHROME_PROFILE_DIR/Default" ]; then
  RESTORE=(--restore-last-session)
  START_URL=""
else
  RESTORE=()
fi

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
  --test-type
)
# shellcheck disable=SC2206
ARGS=(${CHROME_ARGS:-${DEFAULT_ARGS[@]}} $CHROME_EXTRA_ARGS)

exec browser "${ARGS[@]}" "${RESTORE[@]}" \
  --user-data-dir="$CHROME_PROFILE_DIR" \
  --remote-debugging-port="$CDP_PORT" --remote-debugging-address=127.0.0.1 \
  --window-position=0,0 --window-size="${RESOLUTION%x*},${RESOLUTION#*x}" \
  ${START_URL:+"$START_URL"}
