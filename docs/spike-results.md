# Sprint 0 Spike Results

Auto-generated: 2026-07-01T00:42:06Z  
Environment: ProductName:		macOS ProductVersion:		26.5.1 BuildVersion:		25F80 

## Automated probes

### R1 / R6 — Permissions + live tap

```json
{
  "axIsProcessTrusted" : true,
  "listenEventPreflight" : true,
  "liveTapCreates" : true,
  "liveTapEnabled" : true,
  "postEventPreflight" : true,
  "readyForInject" : true,
  "readyForListen" : true,
  "staleAxCacheSuspected" : false
}
```

Interpretation:

- `readyForListen` → R1 event tap viability
- `readyForInject` → R2/R3 injection preflight
- `staleAxCacheSuspected` → R6 TCC stale cache

### R4 — Bridge read from probe process

```json
{
  "count" : 22,
  "ok" : true,
  "source" : "KSTextReplacementList"
}
```

## Manual matrix (fill after testing)

| Spike | App | Pass? | Notes |
|-------|-----|-------|-------|
| S0.2 clipboard inject | Warp | **PASS** | `keypop probe inject` |
| S1 keyword expand | Warp | **PASS** | `keypop run` → `;wle` expanded 20 chars |
| S0.2 | VS Code | | |
| S0.2 | Cursor | | |
| S0.2 | Chrome | | |
| S0.5 dual-layer | Slack | | Apple + daemon same keyword |
| S0.7 long prompt | Warp | | `;pcr` length |
| S0.8 clipboard placeholder | Warp | | |
| S0.10 Poof fallback | n/a | skipped | keypop shipped (no Poof) |

## Listen smoke test

```sh
keypop probe listen --seconds 5
# Type keys in TextEdit; expect keydown lines on stderr
```

## Go / no-go

| Decision | Choice | Date |
|----------|--------|------|
| Custom daemon vs Poof | **Lean custom** | 2026-07-01 |
| Clipboard-only vs dual inject | **Clipboard-first** | 2026-07-01 |
| Live DB vs export watch | **Export watch for S1** | 2026-07-01 |

