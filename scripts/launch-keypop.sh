#!/usr/bin/env bash
# Manage keypop via a LaunchAgent so it survives terminal/session exit.
#
# Usage:
#   ./scripts/launch-keypop.sh [start|stop|restart|status|install|uninstall|uninstall-clean|debug|debug-off|diagnostics]
#
# Override binary: KEYPOP_BIN=/path/to/keypop

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=keypop-paths.sh
source "${SCRIPT_DIR}/keypop-paths.sh"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SNIPPETS="${KEYPOP_SNIPPETS}"
LOG_FILE="${KEYPOP_LOG}"

LABEL="io.keypop.daemon"
PLIST_DIR="${HOME}/Library/LaunchAgents"
PLIST="${PLIST_DIR}/${LABEL}.plist"
LAUNCHCTL_DOMAIN="gui/$(id -u)"
LAUNCHCTL_SERVICE="${LAUNCHCTL_DOMAIN}/${LABEL}"

diagnostics_until() {
  [[ -f "$KEYPOP_DIAGNOSTICS_SESSION" ]] || return 0
  local until now
  until="$(tr -d '[:space:]' < "$KEYPOP_DIAGNOSTICS_SESSION")"
  [[ "$until" =~ ^[0-9]+$ ]] || { rm -f "$KEYPOP_DIAGNOSTICS_SESSION"; return 0; }
  now="$(date +%s)"
  if (( until > now )); then
    echo "$until"
  else
    rm -f "$KEYPOP_DIAGNOSTICS_SESSION"
  fi
}

restart_agent() {
  if is_loaded; then
    unload_agent
  fi
  ensure_binary
  ensure_snippets
  local binary
  binary="$(resolve_keypop_binary)"
  kill_stale_keypop_processes "$binary"
  write_plist "$binary"
  load_agent
  wait_for_daemon "$binary"
}

wait_for_daemon() {
  local binary="$1"
  local _
  for _ in {1..20}; do
    if pgrep -f "${binary} run --snippets" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  echo "keypop did not start within 2 seconds; check log: $LOG_FILE" >&2
  return 1
}

resolve_keypop_binary() {
  if [[ -n "${KEYPOP_BIN:-}" && -x "${KEYPOP_BIN}" ]]; then
    echo "${KEYPOP_BIN}"
    return 0
  fi
  local app_binary="${KEYPOP_APP}/Contents/MacOS/keypop"
  if [[ -x "$app_binary" ]]; then
    echo "$app_binary"
    return 0
  fi
  local legacy_binary="${KEYPOP_APP_LEGACY}/Contents/MacOS/keypop"
  if [[ -x "$legacy_binary" ]]; then
    echo "$legacy_binary"
    return 0
  fi
  local installed="${KEYPOP_CLI}"
  if [[ -x "$installed" ]]; then
    echo "$installed"
    return 0
  fi
  local release="${PROJECT_DIR}/.build/release/keypop"
  if [[ -x "$release" ]]; then
    echo "$release"
    return 0
  fi
  local debug="${PROJECT_DIR}/.build/debug/keypop"
  if [[ -x "$debug" ]]; then
    echo "$debug"
    return 0
  fi
  return 1
}

ensure_binary() {
  if resolve_keypop_binary >/dev/null; then
    return 0
  fi
  echo "Building keypop (debug)..."
  swift build --package-path "$PROJECT_DIR" -q
  "${PROJECT_DIR}/scripts/bundle-keypop-app.sh" "${PROJECT_DIR}/.build/debug/keypop"
}

ensure_snippets() {
  if [[ ! -f "$SNIPPETS" ]]; then
    "${PROJECT_DIR}/scripts/sync-keypop.sh"
  fi
}

kill_stale_keypop_processes() {
  local expected="$1"
  local line pid cmd
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    pid="${line%% *}"
    cmd="${line#* }"
    if [[ "$cmd" == *"keypop run --snippets"* && "$cmd" != *"$expected"* ]]; then
      echo "Stopping stale keypop (pid ${pid}): ${cmd}" >&2
      kill "$pid" 2>/dev/null || true
    fi
  done < <(pgrep -fl "keypop run --snippets" 2>/dev/null || true)
}

plist_binary() {
  if [[ ! -f "$PLIST" ]]; then
    return 1
  fi
  /usr/libexec/PlistBuddy -c "Print :ProgramArguments:0" "$PLIST" 2>/dev/null || true
}

needs_plist_refresh() {
  local binary="$1"
  [[ ! -f "$PLIST" ]] && return 0
  [[ "$(plist_binary)" != "$binary" ]]
}

write_plist() {
  local binary="$1"
  local diagnostics_until_value
  diagnostics_until_value="$(diagnostics_until)"
  mkdir -p "$PLIST_DIR" "$(dirname "$LOG_FILE")"
  cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>         <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${binary}</string>
    <string>run</string>
    <string>--snippets</string>
    <string>${SNIPPETS}</string>
  </array>
  <key>RunAtLoad</key>     <true/>
  <key>KeepAlive</key>     <true/>
  <key>ThrottleInterval</key> <integer>10</integer>
  <key>StandardOutPath</key>  <string>${LOG_FILE}</string>
  <key>StandardErrorPath</key><string>${LOG_FILE}</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key><string>${HOME}/.local/bin:/usr/local/bin:/usr/bin:/bin</string>
$(if [[ -n "$diagnostics_until_value" ]]; then cat <<ENV
    <key>KEYPOP_DIAGNOSTICS</key><string>1</string>
    <key>KEYPOP_DIAGNOSTICS_UNTIL</key><string>${diagnostics_until_value}</string>
ENV
fi)
  </dict>
</dict>
</plist>
PLIST
  echo "Wrote ${PLIST}"
  echo "TCC: grant Input Monitoring + Accessibility to app bundle:"
  echo "  ${KEYPOP_APP}"
  if [[ -n "$diagnostics_until_value" ]]; then
    echo "Diagnostics enabled until $(date -r "$diagnostics_until_value" '+%H:%M:%S')."
  fi
}

is_loaded() {
  launchctl print "${LAUNCHCTL_SERVICE}" &>/dev/null
}

load_agent() {
  if launchctl bootstrap "${LAUNCHCTL_DOMAIN}" "$PLIST" 2>/dev/null; then
    return 0
  fi
  launchctl load -w "$PLIST"
}

unload_agent() {
  if launchctl bootout "${LAUNCHCTL_SERVICE}" 2>/dev/null; then
    return 0
  fi
  launchctl unload -w "$PLIST" 2>/dev/null || launchctl unload "$PLIST" 2>/dev/null || true
}

ensure_plist() {
  local binary
  binary="$(resolve_keypop_binary)"
  if needs_plist_refresh "$binary"; then
    write_plist "$binary"
  fi
}

cmd="${1:-start}"

case "$cmd" in
  install)
    ensure_binary
    ensure_snippets
    binary="$(resolve_keypop_binary)"
    # A rebuilt app bundle does not replace an already-running executable image.
    # Stop the current agent so a full install always starts the new binary.
    if is_loaded; then
      unload_agent
    fi
    kill_stale_keypop_processes "$binary"
    write_plist "$binary"
    load_agent
    wait_for_daemon "$binary"
    echo "keypop installed and started"
    echo "log: $LOG_FILE"
    ;;

  uninstall)
    if is_loaded; then
      unload_agent
    fi
    rm -f "$PLIST"
    echo "keypop uninstalled"
    ;;

  uninstall-clean)
    if is_loaded; then
      unload_agent
    fi
    rm -f "$PLIST"
    rm -rf "${KEYPOP_APP}" "${KEYPOP_APP_LEGACY}"
    rm -f "${KEYPOP_CLI}"
    tccutil reset ListenEvent io.keypop.app 2>/dev/null || true
    tccutil reset PostEvent io.keypop.app 2>/dev/null || true
    tccutil reset Accessibility io.keypop.app 2>/dev/null || true
    echo "keypop clean-uninstalled"
    echo "Reset TCC for io.keypop.app"
    ;;

  start)
    ensure_binary
    ensure_snippets
    binary="$(resolve_keypop_binary)"
    kill_stale_keypop_processes "$binary"
    if needs_plist_refresh "$binary"; then
      write_plist "$binary"
    else
      ensure_plist
    fi
    if is_loaded; then
      echo "keypop already loaded"
    else
      load_agent
      wait_for_daemon "$binary"
      echo "keypop started"
    fi
    echo "log: $LOG_FILE"
    ;;

  stop)
    if is_loaded; then
      unload_agent
      echo "keypop stopped (plist kept; will restart on next login)"
    else
      echo "keypop not loaded"
    fi
    ;;

  restart)
    restart_agent
    echo "keypop restarted"
    echo "log: $LOG_FILE"
    ;;

  status)
    if is_loaded; then
      BINARY="$(resolve_keypop_binary)"
      STALE="$(pgrep -fl "keypop run --snippets" 2>/dev/null | grep -v "$BINARY" || true)"
      if [[ -n "$STALE" ]]; then
        echo "warning: stale keypop process (not ${BINARY}):" >&2
        echo "$STALE" >&2
      fi
      PID="$(pgrep -f "${BINARY} run --snippets" 2>/dev/null | head -1 || true)"
      if [[ -n "$PID" ]]; then
        echo "running (pid $PID)"
        echo "binary: ${BINARY}"
        if until="$(diagnostics_until)"; [[ -n "$until" ]]; then
          echo "diagnostics: enabled until $(date -r "$until" '+%H:%M:%S')"
        else
          echo "diagnostics: off"
        fi
      else
        echo "loaded but not running (check log: $LOG_FILE)"
        echo "binary: ${BINARY}"
        exit 1
      fi
    else
      echo "not running"
      exit 1
    fi
    ;;

  debug)
    mkdir -p "$KEYPOP_DIAGNOSTICS_DIR"
    chmod 700 "$KEYPOP_DIAGNOSTICS_DIR"
    until="$(( $(date +%s) + 1800 ))"
    printf '%s\n' "$until" > "$KEYPOP_DIAGNOSTICS_SESSION"
    chmod 600 "$KEYPOP_DIAGNOSTICS_SESSION"
    restart_agent
    echo "KeyPop diagnostics enabled for 30 minutes. Reproduce once, then run:"
    echo "  ./scripts/launch-keypop.sh diagnostics"
    ;;

  debug-off)
    rm -f "$KEYPOP_DIAGNOSTICS_SESSION"
    restart_agent
    echo "KeyPop diagnostics disabled"
    ;;

  diagnostics)
    mkdir -p "$KEYPOP_DIAGNOSTICS_DIR"
    chmod 700 "$KEYPOP_DIAGNOSTICS_DIR"
    report="$KEYPOP_DIAGNOSTICS_DIR/report-$(date '+%Y%m%d-%H%M%S').txt"
    binary="$(resolve_keypop_binary 2>/dev/null || true)"
    pid="$(pgrep -f "${binary} run --snippets" 2>/dev/null | head -1 || true)"
    until="$(diagnostics_until)"
    recent_events="$(awk '
      /^diagnostic\|runtime_started\|diagnostics=enabled/ { events = "" }
      /^diagnostic\|/ { events = events $0 ORS }
      END { printf "%s", events }
    ' "$LOG_FILE" 2>/dev/null | tail -120 || true)"
    {
      echo "KeyPop diagnostic report"
      echo "generated_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
      echo "launchagent_loaded=$(is_loaded && echo true || echo false)"
      echo "expected_binary=${binary:-missing}"
      echo "daemon_pid=${pid:-none}"
      echo "diagnostics_until=${until:-off}"
      echo "snippet_file_present=$([[ -f "$SNIPPETS" ]] && echo true || echo false)"
      if [[ -x "${KEYPOP_APP}/Contents/MacOS/keypop" ]]; then
        echo "app_identifier=$(codesign -dvvv "$KEYPOP_APP" 2>&1 | awk -F= '/^Identifier=/{print $2; exit}')"
      fi
      echo "events_begin"
      [[ -n "$recent_events" ]] && printf '%s\n' "$recent_events"
      echo "events_end"
      if [[ -z "$pid" ]]; then
        echo "verdict=daemon_not_running"
      elif grep -q '^diagnostic|tap_reinstall_failed|' <<< "$recent_events"; then
        echo "verdict=tap_reinstall_failed"
      elif grep -q '^diagnostic|inject|.*outcome=failed' <<< "$recent_events"; then
        echo "verdict=match_observed_injection_failed"
      elif grep -q '^diagnostic|expansion|outcome=paste_posted' <<< "$recent_events"; then
        echo "verdict=paste_posted_app_insertion_unconfirmed"
      elif grep -q '^diagnostic|input_heartbeat|.*key_down_count=[1-9][0-9]*' <<< "$recent_events"; then
        echo "verdict=input_observed_no_abnormal_state"
      elif grep -q '^diagnostic|input_heartbeat|.*key_down_count=0' <<< "$recent_events"; then
        echo "verdict=no_input_observed_during_diagnostic_interval"
      else
        echo "verdict=no_abnormal_state_observed"
      fi
    } > "$report"
    chmod 600 "$report"
    echo "Wrote diagnostic report: $report"
    ;;

  *)
    echo "Usage: $0 {start|stop|restart|status|install|uninstall|uninstall-clean|debug|debug-off|diagnostics}"
    exit 1
    ;;
esac
