# Sprint Plan: Replace Raycast Runtime (macOS Tahoe)

Target: macOS 26.x (Tahoe), Apple Silicon  
Prerequisite: `trctl` CRUD validated on 26.5.1  
Companion research: [`open-source-expander-research.md`](open-source-expander-research.md)

---

## Goal

Remove Raycast as the Mac runtime expander for Warp, VS Code, Cursor, and Chromium inputs while keeping:

- `trctl` + Apple Text Replacements for iOS sync and native apps
- Kit JSON (`name`, `keyword`, `text`) as interchange format
- Same `;wl*`, `;p*` keyword conventions

Success = type `;wle` in Warp and VS Code without Raycast installed; no manual import step after `trctl` changes.

---

## Strategy

Build a **Swift menu-bar daemon** in this repo (working name: `trexpand`), reusing `KSPrivateBridge` for snippet source and `TrctlKit` for kit parsing. Espanso and Poof are reference implementations, not dependencies.

Fallback if spikes fail: adopt **Poof** (MIT, Swift, Raycast import) via `brew install mikker/tap/poof` and a `sync-poof.sh` script until custom daemon is ready.

---

## Risky Assumptions (Test Early)

These are ordered by kill potential. **Sprint 0 exists only to validate or falsify them.**

| ID | Assumption | If false | Spike |
|----|------------|----------|-------|
| R1 | Signed `.app` gets stable `CGEventTap` callbacks on Tahoe 26.5 | Cannot build custom daemon | S0.1 |
| R2 | Clipboard inject (Cmd+V) works in Warp, VS Code, Cursor | Need keystroke inject or per-app hacks | S0.2 |
| R3 | Keystroke inject works as fallback for at least one target app | Clipboard-only daemon | S0.3 |
| R4 | `KSPrivateBridge` read is callable from GUI/daemon process without extra entitlements | Export-file sync only | S0.4 |
| R5 | Custom expander can win over Apple native for shared keywords without double expansion | Must disable Apple on Mac or accept Raycast-style override tap | S0.5 |
| R6 | TCC stale-cache detection via live tap probe is sufficient on Tahoe | Users stuck in silent failure | S0.6 |
| R7 | Long prompts (2k–8k chars) expand reliably via clipboard | Chunk inject or truncate | S0.7 |
| R8 | `{clipboard}` resolution is feasible for `;pcr` prompt kit | Strip placeholders; Raycast-only prompts | S0.8 |
| R9 | Expansion latency under 100ms feels instant for short snippets | Tune delays; document tradeoffs | S0.9 |
| R10 | Poof/Espanso-free daily driver is acceptable with one-time TCC setup | Keep Raycast as fallback longer | S0.10 |

---

## Sprint 0 — Spikes (3–5 days)

**Exit criteria:** Written spike report in `docs/spike-results.md` with pass/fail per assumption. Go/no-go on custom daemon.

### S0.1 — Event tap viability

**Task:** Minimal Swift target `trexpand-probe` with `CGEvent.tapCreate(.cgSessionEventTap, .listenOnly, .keyDown)`.

**Pass:** Callbacks fire in TextEdit after signed `.app` launch from `/Applications`.

**Fail actions:** Try `.headInsertEventTap` active tap; compare `swift run` vs signed app; log `CGEvent.tapIsEnabled`.

```sh
# After building signed probe app:
log stream --predicate 'subsystem == "com.apple.TCC"' --level debug
```

### S0.2 — Clipboard inject matrix

**Task:** Probe app: on hotkey, save pasteboard → set test string → post Cmd+V → restore after 100ms.

| App | Test string | Pass? |
|-----|-------------|-------|
| Warp | `;trctlprobe-clip` | |
| VS Code | same | |
| Cursor | same | |
| Chrome (textarea) | same | |
| TextEdit | same | |

### S0.3 — Keystroke inject matrix

**Task:** Same probe with `CGEventKeyboardSetUnicodeString` in 20-char chunks (Espanso pattern).

Run only for apps where S0.2 fails.

### S0.4 — Bridge read from app process

**Task:** Call existing `_KSTextReplacementCoreDataStore` read from a GUI app target (not CLI).

**Pass:** Entry count matches `trctl list | jq length`.

### S0.5 — Dual-layer conflict

**Task:** Create `;trctlprobe-dual` in Apple via `trctl create`. Expand in Warp with only custom daemon (no Raycast).

**Pass:** Exactly one expansion, correct phrase, no duplicated keyword text.

### S0.6 — TCC stale probe

**Task:** Implement `AXIsProcessTrusted()` + live `CGEvent.tapCreate` probe side by side. Simulate re-sign if feasible.

**Pass:** Probe detects mismatch scenario documented in research doc.

### S0.7 — Long phrase

**Task:** Expand `kits/prompts-core.raycast.json` longest `;p*` entry via clipboard in Warp.

### S0.8 — `{clipboard}` placeholder

**Task:** Copy known string, expand snippet with `{clipboard}` or `{{clipboard}}`, verify substitution.

### S0.9 — Latency

**Task:** Timestamp keydown → injection complete for `;wle`-sized snippet. Target p95 < 100ms.

### S0.10 — Poof fallback smoke test

**Task:** `brew install mikker/tap/poof`, `just import-raycast` equivalent with `trctl export` output, test in Warp.

**Purpose:** Establishes floor if S0.1–S0.3 fail partially.

### Sprint 0 deliverables

- [ ] `docs/spike-results.md` (pass/fail table)
- [ ] `scripts/probes/README.md` with copy-paste commands (optional shell wrappers)
- [ ] Go/no-go decision recorded in spike doc

---

## Sprint 1 — MVP daemon (5–8 days)

**Depends on:** S0.1 + S0.2 pass (or S0.3 partial pass with clipboard-primary design).

### Scope

- Menu-bar app `trexpand` (no dock icon)
- Load snippets from exported JSON (`trctl export`) with file watcher
- Immediate expansion on keyword match (semicolon triggers, no delimiter required for v1)
- Clipboard injection backend only
- Enable / disable toggle
- TCC onboarding screen

### Out of scope

- Dynamic placeholders (except literal passthrough)
- Search UI
- iOS

### Tasks

| # | Task | Estimate |
|---|------|----------|
| 1.1 | SPM target `trexpand` + `Info.plist` permissions strings | 0.5d |
| 1.2 | `SnippetStore`: load `TrctlKit` JSON, in-memory `keyword → text` map | 0.5d |
| 1.3 | `EventTapEngine`: listen-only tap, ring buffer, prefix trie for `;` keywords | 1.5d |
| 1.4 | `ClipboardInjector`: save/set/paste/restore | 1d |
| 1.5 | Expansion pipeline: delete trigger chars + inject | 1d |
| 1.6 | Menu bar: status, reload, quit, permissions link | 0.5d |
| 1.7 | Manual test script for P0 apps | 0.5d |

### Exit criteria

- [ ] `trctl export -o ~/.config/trexpand/snippets.json` → edit shortcut → file watch reloads
- [ ] `;trctlprobe` works in Warp + VS Code + Cursor
- [ ] Raycast not required for P0 apps

---

## Sprint 2 — `trctl` integration (3–5 days)

### Scope

- `trctl export --watch` or `trexpand` reads directly via `KSPrivateBridge` (if S0.4 passed)
- Replace `sync-raycast.sh` with `scripts/sync-expander.sh`
- Login item helper (SMAppService or `launchctl` user agent)
- Rename path: neutral `*.snippets.json` alias (keep Raycast-compatible schema)

### Tasks

| # | Task | Estimate |
|---|------|----------|
| 2.1 | `trexpand reload` via UNIX socket or DistributedNotification | 1d |
| 2.2 | `trctl export` triggers reload after `--apply` import | 0.5d |
| 2.3 | Optional: live DB read in daemon (poll or notify) | 1–2d |
| 2.4 | Update `docs/kits.md`, `AGENTS.md`, `user-guide.md` Raycast sections | 0.5d |
| 2.5 | Deprecation notice on `sync-raycast.sh` | 0.25d |

### Exit criteria

- [ ] `trctl import ... --apply` → expansion updated without manual export click
- [ ] Documented workflow has zero Raycast steps

---

## Sprint 3 — Hardening (5–8 days)

### Scope

- Password / secure field skip (AX role check best-effort)
- App exclusion list (password managers, Slack if double-expanding)
- Keystroke inject fallback backend (auto: clipboard for long/unicode, inject for short)
- Tap health monitor + reinstall
- TCC stale detection + user alert
- Delimiter mode (optional: expand on space after keyword)

### Tasks

| # | Task | Estimate |
|---|------|----------|
| 3.1 | `InjectionBackend` protocol + auto selection | 1.5d |
| 3.2 | `PermissionMonitor` (AX cache vs live tap probe) | 1d |
| 3.3 | `AppFilter` exec path exclusions | 1d |
| 3.4 | Secure field guard | 1d |
| 3.5 | Regression harness: P0 + P1 app matrix | 1d |
| 3.6 | Unit tests: trie matcher, template strip | 1d |

### Exit criteria

- [ ] 24h soak test without tap death
- [ ] No expansion in 1Password / Keychain Access secure fields (best effort)
- [ ] Spike doc assumptions R5–R9 re-validated

---

## Sprint 4 — Dynamic placeholders + polish (5–8 days)

### Scope

- `{date}`, `{time}`, `{datetime}`, `{clipboard}` (Raycast syntax)
- `{cursor}` deferred if hard
- `trctl lint` for unknown placeholders in Apple-bound imports
- Code signing + notarization for personal distribution

### Exit criteria

- [ ] `;pcr` prompt kit works in Warp with clipboard selection injected
- [ ] Signed `.app` installable on clean Tahoe machine

---

## Sprint 5 — Team rollout (3–5 days)

### Scope

- Update team onboarding in `user-guide.md`
- Kit distribution unchanged (JSON in repo)
- Troubleshooting runbook (TCC reset commands)
- Remove Raycast from recommended stack

### Exit criteria

- [ ] Another machine onboarded without Raycast
- [ ] `sync-raycast.sh` archived

---

## Timeline Summary

| Sprint | Duration | Cumulative | Milestone |
|--------|----------|------------|-----------|
| S0 Spikes | 3–5d | 1w | Go/no-go |
| S1 MVP | 5–8d | 2–3w | Raycast optional for dev |
| S2 Integration | 3–5d | 3–4w | Raycast removed from workflow |
| S3 Hardening | 5–8d | 5–6w | Daily driver stable |
| S4 Placeholders | 5–8d | 7–8w | Prompt kits fully working |
| S5 Rollout | 3–5d | 8–9w | Team docs updated |

**Aggressive path (Poof fallback):** S0.10 only → S2 export sync → S3 hardening on Poof = Raycast removed in ~1 week, custom daemon in parallel.

---

## Test Plan (Continuous)

### Automated

```sh
swift build && swift test
scripts/validate-crud.sh
# Future:
# scripts/test-expander-matrix.sh  — drives probe snippets, asserts clipboard output
```

### Manual matrix (run after S1, S3, S5)

| Case | Steps | Expected |
|------|-------|----------|
| Short contact | `;wle` in Warp | Email inserted |
| Multi-line | `;homea` in VS Code | Address with newlines |
| Long prompt | `;pcr` in Cursor | Full prompt, no truncate |
| No false positive | type `;w` only | No expansion |
| iOS unchanged | `;wle` on iPhone | Apple layer still works |
| Permissions revoked | Remove Accessibility | Daemon shows alert, no silent fail |
| Import apply | `trctl import kit --apply` | New keyword works in <5s |
| Competing expander | Raycast enabled | Document conflict or detect |

### Tahoe version pinning

Record on every test run:

```sh
sw_vers
uname -m
```

Store in `docs/spike-results.md` and future report metadata (same pattern as `local_model_eval` harness).

---

## Decision Log (fill during S0)

| Date | Decision | Rationale |
|------|----------|-----------|
| | Custom daemon vs Poof vs Espanso | |
| | Clipboard-only vs dual backend | |
| | Live DB read vs export file watch | |
| | Disable Apple layer on Mac? | |

---

## References

- [`open-source-expander-research.md`](open-source-expander-research.md)
- [`architecture.md`](architecture.md)
- [`kits.md`](kits.md)
- [Poof](https://github.com/mikker/poof) — Swift reference + Raycast import
- [Espanso macOS inject](https://github.com/espanso/espanso/blob/dev/espanso-inject/src/mac/native.mm)
