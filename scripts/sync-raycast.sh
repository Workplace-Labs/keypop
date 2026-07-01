#!/usr/bin/env bash
# Sync Apple Text Replacements to Raycast Snippets.
#
# Usage: ./scripts/sync-raycast.sh
#
# Raycast: Override System Snippets ON (Settings → Snippets).
# Import: click raycast-sync.json on Desktop in the file picker.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

resolve_trctl() {
  if command -v trctl >/dev/null 2>&1; then
    command -v trctl
    return
  fi
  local built="${PROJECT_DIR}/.build/release/trctl"
  if [[ -x "$built" ]]; then
    echo "$built"
    return
  fi
  built="${PROJECT_DIR}/.build/debug/trctl"
  if [[ -x "$built" ]]; then
    echo "$built"
    return
  fi
  echo "Building trctl..."
  swift build --package-path "$PROJECT_DIR" -q
  echo "${PROJECT_DIR}/.build/debug/trctl"
}

TRCTL="$(resolve_trctl)"
EXPORT="${PROJECT_DIR}/exports/raycast-sync.json"
DESKTOP="${HOME}/Desktop/raycast-sync.json"

mkdir -p "${PROJECT_DIR}/exports"
"$TRCTL" export --output "$EXPORT"
cp "$EXPORT" "$DESKTOP"

open -R "$DESKTOP"
open "raycast://extensions/raycast/snippets/import-snippets"

echo "Exported to: $EXPORT"
echo "Copied to:   $DESKTOP"
echo ""
echo "In Raycast's import dialog, click raycast-sync.json on your Desktop."
echo "Raycast skips duplicates, so re-importing is always safe."
