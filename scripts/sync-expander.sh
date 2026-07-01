#!/usr/bin/env bash
# Export trctl snippets for trexpand and print run instructions.
#
# Usage: ./scripts/sync-expander.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SNIPPETS="${HOME}/.config/trexpand/snippets.json"

resolve_trctl() {
  if command -v trctl >/dev/null 2>&1; then
    command -v trctl
    return
  fi
  local installed="${HOME}/.local/bin/trctl"
  if [[ -x "$installed" ]]; then
    echo "$installed"
    return
  fi
  local debug="${PROJECT_DIR}/.build/debug/trctl"
  if [[ -x "$debug" ]]; then
    echo "$debug"
    return
  fi
  echo "Building trctl..."
  swift build --package-path "$PROJECT_DIR" -q
  echo "${PROJECT_DIR}/.build/debug/trctl"
}

TRCTL="$(resolve_trctl)"

mkdir -p "$(dirname "$SNIPPETS")"
"$TRCTL" export --output "$SNIPPETS"

COUNT="$(jq length "$SNIPPETS")"
echo "Exported ${COUNT} snippets to: ${SNIPPETS}"
echo ""
echo "Restart expander:"
echo "  ./scripts/launch-trexpand.sh restart"
echo ""
echo "Foreground debug:"
echo "  trexpand run --snippets \"${SNIPPETS}\""
