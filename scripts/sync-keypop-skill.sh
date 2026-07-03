#!/usr/bin/env bash
# Sync the canonical keypop SKILL.md to the wl-agent-toolkit copy.
#
# Canonical source: .cursor/skills/keypop/SKILL.md (edit this one).
# .agents/skills/keypop/SKILL.md is a symlink to it, so it never drifts.
# The only real generated copy is the sibling toolkit repo:
#   ../../wl-agent-toolkit/skills/keypop/SKILL.md
#
# Run manually, or let the pre-commit hook call this automatically
# (see scripts/hooks/pre-commit + AGENTS.md).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE="${REPO_ROOT}/.cursor/skills/keypop/SKILL.md"
TOOLKIT_PATH="${KEYPOP_TOOLKIT_PATH:-${REPO_ROOT}/../../wl-agent-toolkit}"
TOOLKIT_COPY="${TOOLKIT_PATH}/skills/keypop/SKILL.md"

if [[ ! -f "$SOURCE" ]]; then
  echo "sync-keypop-skill: canonical file missing: ${SOURCE}" >&2
  exit 1
fi

if [[ ! -d "$TOOLKIT_PATH/.git" ]]; then
  echo "sync-keypop-skill: wl-agent-toolkit not found at ${TOOLKIT_PATH} (set KEYPOP_TOOLKIT_PATH to override) — skipping"
  exit 0
fi

if [[ -f "$TOOLKIT_COPY" ]] && cmp -s "$SOURCE" "$TOOLKIT_COPY"; then
  echo "sync-keypop-skill: already in sync."
  exit 0
fi

mkdir -p "$(dirname "$TOOLKIT_COPY")"
cp "$SOURCE" "$TOOLKIT_COPY"
echo "sync-keypop-skill: updated wl-agent-toolkit/skills/keypop/SKILL.md — commit it there separately."
