#!/usr/bin/env bash
# Reset and re-prompt for KeyPop TCC permissions (Input Monitoring + Accessibility).
#
# Usage: ./scripts/fix-keypop-tcc.sh [--rebundle]
#   --rebundle  Re-sign KeyPop.app only (no full install / LaunchAgent changes)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP="${HOME}/.local/KeyPop.app"
BUNDLE_ID="io.keypop.app"
REBUNDLE=false

for arg in "$@"; do
  case "$arg" in
    --rebundle) REBUNDLE=true ;;
    -h|--help)
      echo "Usage: $0 [--rebundle]"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ "$REBUNDLE" == true ]]; then
  BIN="${HOME}/.local/bin/keypop"
  if [[ ! -x "$BIN" ]]; then
    echo "error: $BIN not found; run ./scripts/install.sh first" >&2
    exit 1
  fi
  echo "Re-signing KeyPop.app..."
  "${PROJECT_DIR}/scripts/bundle-keypop-app.sh" "$BIN"
else
  echo "Tip: pass --rebundle after install.sh to refresh the app signature without reinstalling."
fi

echo "Resetting TCC for ${BUNDLE_ID}..."
tccutil reset ListenEvent "${BUNDLE_ID}" 2>/dev/null || true
tccutil reset PostEvent "${BUNDLE_ID}" 2>/dev/null || true
tccutil reset Accessibility "${BUNDLE_ID}" 2>/dev/null || true

echo ""
echo "Opening System Settings. Grant BOTH permissions to KeyPop.app:"
echo "  ${APP}"
echo ""
echo "  1. Privacy & Security → Input Monitoring  (required for Warp)"
echo "  2. Privacy & Security → Accessibility       (required for injection)"
echo ""
echo "Use + → Cmd+Shift+G → paste the path above for each pane."
echo ""

open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" 2>/dev/null || true
open "${APP}" --args probe permissions --request 2>/dev/null || true

echo "After granting both, run:"
echo "  ./scripts/launch-keypop.sh restart"
echo "  ~/.local/KeyPop.app/Contents/MacOS/keypop probe permissions"
echo ""
echo "Probe must show liveTapCreates=true and readyForListen=true."
echo "If still stuck after re-granting, restart macOS to flush TCC cache."
