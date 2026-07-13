#!/usr/bin/env bash
# Reset and re-prompt for KeyPop TCC permissions (Input Monitoring + Accessibility).
#
# Usage: ./scripts/fix-keypop-tcc.sh [--rebundle-only]
#   --rebundle-only  Re-sign KeyPop.app only (skip full rebuild)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=keypop-paths.sh
source "${SCRIPT_DIR}/keypop-paths.sh"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP="${KEYPOP_APP}"
BUNDLE_ID="io.keypop.app"
REBUNDLE_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --rebundle-only) REBUNDLE_ONLY=true ;;
    -h|--help)
      echo "Usage: $0 [--rebundle-only]"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

echo "Stopping any running keypop daemons..."
pkill -f "keypop run --snippets" 2>/dev/null || true
sleep 1

if [[ "$REBUNDLE_ONLY" == true ]]; then
  if [[ ! -x "${KEYPOP_CLI}" ]]; then
    echo "error: ${KEYPOP_CLI} not found; run ./scripts/install-full.sh first" >&2
    exit 1
  fi
  echo "Re-signing KeyPop.app..."
  "${PROJECT_DIR}/scripts/bundle-keypop-app.sh" "${KEYPOP_CLI}"
else
  echo "Rebuilding and re-signing KeyPop.app..."
  "${PROJECT_DIR}/scripts/install-full.sh"
fi

remove_legacy_app_bundle

echo "Resetting TCC for ${BUNDLE_ID}..."
tccutil reset ListenEvent "${BUNDLE_ID}" 2>/dev/null || true
tccutil reset PostEvent "${BUNDLE_ID}" 2>/dev/null || true
tccutil reset Accessibility "${BUNDLE_ID}" 2>/dev/null || true

echo ""
echo "IMPORTANT: In System Settings, REMOVE any old keypop entries first:"
echo "  - black exec icon labeled 'keypop'"
echo "  - ~/.local/KeyPop.app (legacy path)"
echo "  - Terminal or Cursor (if accidentally granted)"
echo ""
echo "Then ADD this app in BOTH panes (use - not just toggle):"
echo "  ${APP}"
echo ""
echo "  1. Privacy & Security → Input Monitoring"
echo "  2. Privacy & Security → Accessibility"
echo "  Use + → Cmd+Shift+G → paste path above for each pane."
echo ""

open -R "${APP}" 2>/dev/null || true
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" 2>/dev/null || true
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" 2>/dev/null || true
open -n -a "${APP}" --args probe permissions --request 2>/dev/null || true

echo "After granting BOTH, run:"
echo "  ./scripts/launch-keypop.sh restart"
echo "  tail -f ~/.local/log/keypop.log    # expect: listen_ready|tap_installed"
echo ""
echo "Note: probe from Terminal may show listen=false even when the daemon works."
echo "Trust the daemon log (listen_ready|tap_installed) and expanded| lines in Warp."
