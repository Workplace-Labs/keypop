#!/usr/bin/env bash
# Manage trexpand via a LaunchAgent so it survives terminal/session exit.
#
# Usage:
#   ./scripts/launch-trexpand.sh [start|stop|restart|status|install|uninstall]
#
# install   — write plist + load agent (persists across reboots)
# uninstall — unload + remove plist
# start     — load agent if already installed, else run install
# stop      — unload agent (leave plist; next login restarts it)
# restart   — stop + start (rewrites plist if binary path changed)
# status    — print running state
#
# Override binary: TREXPAND_BIN=/path/to/trexpand

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SNIPPETS="${HOME}/.config/trexpand/snippets.json"
LOG_FILE="${HOME}/.local/log/trexpand.log"

LABEL="io.trexpand.daemon"
PLIST_DIR="${HOME}/Library/LaunchAgents"
PLIST="${PLIST_DIR}/${LABEL}.plist"
LAUNCHCTL_DOMAIN="gui/$(id -u)"
LAUNCHCTL_SERVICE="${LAUNCHCTL_DOMAIN}/${LABEL}"

resolve_trexpand_binary() {
  if [[ -n "${TREXPAND_BIN:-}" && -x "${TREXPAND_BIN}" ]]; then
    echo "${TREXPAND_BIN}"
    return 0
  fi
  local app_binary="${HOME}/.local/Trexpand.app/Contents/MacOS/trexpand"
  if [[ -x "$app_binary" ]]; then
    echo "$app_binary"
    return 0
  fi
  local installed="${HOME}/.local/bin/trexpand"
  if [[ -x "$installed" ]]; then
    echo "$installed"
    return 0
  fi
  local release="${PROJECT_DIR}/.build/release/trexpand"
  if [[ -x "$release" ]]; then
    echo "$release"
    return 0
  fi
  local debug="${PROJECT_DIR}/.build/debug/trexpand"
  if [[ -x "$debug" ]]; then
    echo "$debug"
    return 0
  fi
  return 1
}

ensure_binary() {
  if resolve_trexpand_binary >/dev/null; then
    return 0
  fi
  echo "Building trexpand (debug)..."
  swift build --package-path "$PROJECT_DIR" -q
  "${PROJECT_DIR}/scripts/bundle-trexpand-app.sh" "${PROJECT_DIR}/.build/debug/trexpand"
}

ensure_snippets() {
  if [[ ! -f "$SNIPPETS" ]]; then
    "${PROJECT_DIR}/scripts/sync-expander.sh"
  fi
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
  echo "  ${HOME}/.local/Trexpand.app"
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
  binary="$(resolve_trexpand_binary)"
  if needs_plist_refresh "$binary"; then
    write_plist "$binary"
  fi
}

cmd="${1:-start}"

case "$cmd" in
  install)
    ensure_binary
    ensure_snippets
    write_plist "$(resolve_trexpand_binary)"
    load_agent
    echo "trexpand installed and started"
    echo "log: $LOG_FILE"
    ;;

  uninstall)
    if is_loaded; then
      unload_agent
    fi
    rm -f "$PLIST"
    echo "trexpand uninstalled"
    ;;

  start)
    ensure_binary
    ensure_snippets
    ensure_plist
    if is_loaded; then
      echo "trexpand already loaded"
    else
      load_agent
      echo "trexpand started"
    fi
    echo "log: $LOG_FILE"
    ;;

  stop)
    if is_loaded; then
      unload_agent
      echo "trexpand stopped (plist kept; will restart on next login)"
    else
      echo "trexpand not loaded"
    fi
    ;;

  restart)
    if is_loaded; then
      unload_agent
    fi
    ensure_binary
    ensure_snippets
    write_plist "$(resolve_trexpand_binary)"
    load_agent
    echo "trexpand restarted"
    echo "log: $LOG_FILE"
    ;;

  status)
    if is_loaded; then
      BINARY="$(resolve_trexpand_binary)"
      PID="$(pgrep -f "${BINARY} run --snippets" 2>/dev/null | head -1 || true)"
      echo "running${PID:+ (pid $PID)}"
      echo "binary: ${BINARY}"
    else
      echo "not running"
      exit 1
    fi
    ;;

  *)
    echo "Usage: $0 {start|stop|restart|status|install|uninstall}"
    exit 1
    ;;
esac
