#!/usr/bin/env bash
# Export keypop snippets from Apple Text Replacements.
#
# Usage: ./scripts/sync-keypop.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SNIPPETS="${HOME}/.config/keypop/snippets.json"

resolve_keypop() {
  if command -v keypop >/dev/null 2>&1; then
    command -v keypop
    return
  fi
  local installed="${HOME}/.local/bin/keypop"
  if [[ -x "$installed" ]]; then
    echo "$installed"
    return
  fi
  local debug="${PROJECT_DIR}/.build/debug/keypop"
  if [[ -x "$debug" ]]; then
    echo "$debug"
    return
  fi
  echo "Building keypop..."
  swift build --package-path "$PROJECT_DIR" -q
  echo "${PROJECT_DIR}/.build/debug/keypop"
}

KEYPOP="$(resolve_keypop)"

mkdir -p "$(dirname "$SNIPPETS")"
"$KEYPOP" export --output "$SNIPPETS"

COUNT="$(jq length "$SNIPPETS")"
echo "Exported ${COUNT} snippets to: ${SNIPPETS}"
echo ""
echo "Restart daemon:"
echo "  ./scripts/launch-keypop.sh restart"
echo ""
echo "Foreground debug:"
echo "  keypop run --snippets \"${SNIPPETS}\""
