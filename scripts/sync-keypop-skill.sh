#!/usr/bin/env bash
# Sync the canonical keypop SKILL.md to its generated copies.
#
# Canonical source: .cursor/skills/keypop/SKILL.md (edit this one).
#
# Generated copies (real files, not symlinks — GitHub raw fetches, the
# Contents API, zip downloads, and Windows checkouts without symlink
# support all fail to resolve a symlink to its real content):
#   - .agents/skills/keypop/SKILL.md                (same repo)
#   - ../../wl-agent-toolkit/skills/keypop/SKILL.md  (sibling repo, if present)
#
# Run manually, or let the pre-commit hook call this automatically
# (see scripts/hooks/pre-commit + AGENTS.md).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${REPO_ROOT}/.cursor/skills/keypop/SKILL.md"
AGENTS_COPY="${REPO_ROOT}/.agents/skills/keypop/SKILL.md"
TOOLKIT_PATH="${KEYPOP_TOOLKIT_PATH:-${REPO_ROOT}/../../wl-agent-toolkit}"
TOOLKIT_COPY="${TOOLKIT_PATH}/skills/keypop/SKILL.md"

if [[ ! -f "$SOURCE" ]]; then
  echo "sync-keypop-skill: canonical file missing: ${SOURCE}" >&2
  exit 1
fi

changed=0

sync_copy() {
  local dest="$1"
  local label="$2"
  if [[ ! -f "$dest" ]] || ! cmp -s "$SOURCE" "$dest"; then
    mkdir -p "$(dirname "$dest")"
    cp "$SOURCE" "$dest"
    echo "sync-keypop-skill: updated ${label}"
    changed=1
  fi
}

sync_copy "$AGENTS_COPY" ".agents/skills/keypop/SKILL.md"

if [[ -d "$TOOLKIT_PATH/.git" ]]; then
  sync_copy "$TOOLKIT_COPY" "wl-agent-toolkit/skills/keypop/SKILL.md"
else
  echo "sync-keypop-skill: wl-agent-toolkit not found at ${TOOLKIT_PATH} (set KEYPOP_TOOLKIT_PATH to override) — skipping"
fi

if [[ "$changed" -eq 1 ]]; then
  echo "sync-keypop-skill: copies updated. If wl-agent-toolkit changed, commit it there separately."
else
  echo "sync-keypop-skill: already in sync."
fi
