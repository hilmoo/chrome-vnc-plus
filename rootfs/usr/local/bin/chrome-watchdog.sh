#!/bin/bash
# Keeps Chrome alive: relaunches on exit, kills+relaunches if CDP stops responding.
export DISPLAY="${DISPLAY:-:0}"
W="${RESOLUTION%x*}"; H="${RESOLUTION#*x}"
DEFAULT_ARGS="--no-sandbox --test-type --disable-dev-shm-usage --no-first-run --no-default-browser-check --disable-infobars --disable-session-crashed-bubble --hide-crash-restore-bubble --password-store=basic"

while ! xdpyinfo >/dev/null 2>&1; do sleep 0.5; done

while true; do
  rm -f "$CHROME_PROFILE_DIR"/Singleton{Lock,Cookie,Socket}
  # CHROME_ARGS replaces the defaults, CHROME_EXTRA_ARGS appends to them
  ARGS="${CHROME_ARGS:-$DEFAULT_ARGS}"
  # shellcheck disable=SC2086
  browser $ARGS $CHROME_EXTRA_ARGS \
    --user-data-dir="$CHROME_PROFILE_DIR" \
    --remote-debugging-port="$CDP_PORT" --remote-debugging-address=127.0.0.1 \
    --window-position=0,0 --window-size="$W,$H" \
    "$START_URL" &
  PID=$!
  echo "[watchdog] chrome started pid=$PID"
  sleep "$WATCHDOG_GRACE" & wait $! 2>/dev/null   # startup grace
  FAILS=0
  while kill -0 "$PID" 2>/dev/null; do
    if curl -fs -m 3 "http://127.0.0.1:$CDP_PORT/json/version" >/dev/null; then FAILS=0
    else FAILS=$((FAILS+1)); echo "[watchdog] CDP check failed ($FAILS/$WATCHDOG_FAILURES)"; fi
    if [ "$FAILS" -ge "$WATCHDOG_FAILURES" ]; then
      echo "[watchdog] chrome unresponsive, killing"; pkill -9 -P "$PID" 2>/dev/null; kill -9 "$PID" 2>/dev/null; break
    fi
    sleep "$WATCHDOG_INTERVAL"
  done
  # make sure no orphaned chrome processes survive before relaunch
  pkill -9 -u chrome -f "user-data-dir=$CHROME_PROFILE_DIR" 2>/dev/null
  wait "$PID" 2>/dev/null
  echo "[watchdog] chrome exited, restarting in 1s"; sleep 1
done
