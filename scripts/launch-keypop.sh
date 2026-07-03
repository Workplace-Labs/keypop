#!/usr/bin/env bash
# Manage keypop via a LaunchAgent so it survives terminal/session exit.
#
# Usage:
#   ./scripts/launch-keypop.sh [start|stop|restart|status|install|uninstall|uninstall-clean]
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
  </dict>
</dict>
</plist>
PLIST
  echo "Wrote ${PLIST}"
  echo "TCC: grant Input Monitoring + Accessibility to app bundle:"
  echo "  ${KEYPOP_APP}"
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
    kill_stale_keypop_processes "$binary"
    write_plist "$binary"
    load_agent
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
    if is_loaded; then
      unload_agent
    fi
    ensure_binary
    ensure_snippets
    binary="$(resolve_keypop_binary)"
    kill_stale_keypop_processes "$binary"
    write_plist "$binary"
    load_agent
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

  *)
    echo "Usage: $0 {start|stop|restart|status|install|uninstall|uninstall-clean}"
    exit 1
    ;;
esac
