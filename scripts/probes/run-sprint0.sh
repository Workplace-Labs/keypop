#!/usr/bin/env bash
# Sprint 0 spike runner — writes docs/spike-results.generated.md
#
# Usage: ./scripts/probes/run-sprint0.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROBE="${PROJECT_DIR}/.build/debug/trexpand-probe"
RESULTS="${PROJECT_DIR}/docs/spike-results.generated.md"

if [[ ! -x "$PROBE" ]]; then
  echo "Building trexpand-probe..."
  swift build --package-path "$PROJECT_DIR" -q
fi

mkdir -p "${PROJECT_DIR}/docs"
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
OS_INFO="$(sw_vers | tr '\n' ' ')"

PERMS="$("$PROBE" permissions 2>/dev/null || echo '{"error":"probe failed"}')"
BRIDGE="$("$PROBE" bridge 2>/dev/null || echo '{"ok":false}')"

cat > "$RESULTS" <<EOF
# Sprint 0 Spike Results

Auto-generated: ${TS}  
Environment: ${OS_INFO}

## Automated probes

### R1 / R6 — Permissions + live tap

\`\`\`json
${PERMS}
\`\`\`

Interpretation:

- \`readyForListen\` → R1 event tap viability
- \`readyForInject\` → R2/R3 injection preflight
- \`staleAxCacheSuspected\` → R6 TCC stale cache

### R4 — Bridge read from probe process

\`\`\`json
${BRIDGE}
\`\`\`

## Manual matrix (fill after testing)

| Spike | App | Pass? | Notes |
|-------|-----|-------|-------|
| S0.2 clipboard inject | Warp | | Focus field, run: \`trexpand-probe inject --text 'probe'\` |
| S0.2 | VS Code | | |
| S0.2 | Cursor | | |
| S0.2 | Chrome | | |
| S0.5 dual-layer | Slack | | Apple + daemon same keyword |
| S0.7 long prompt | Warp | | \`;pcr\` length |
| S0.8 clipboard placeholder | Warp | | |
| S0.10 Poof fallback | n/a | skipped | trexpand shipped |

## Listen smoke test

\`\`\`sh
trexpand-probe listen --seconds 5
# Type keys in TextEdit; expect keydown lines on stderr
\`\`\`

## Go / no-go

| Decision | Choice | Date |
|----------|--------|------|
| Custom daemon vs Poof | | |
| Clipboard-only vs dual inject | | |
| Live DB vs export watch | | |

EOF

echo "Wrote ${RESULTS}"
echo "Manual matrix lives in docs/spike-results.md (not overwritten)."
echo ""
echo "Permissions:"
echo "$PERMS" | jq '{readyForListen, readyForInject, staleAxCacheSuspected}' 2>/dev/null || echo "$PERMS"
