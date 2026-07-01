# Open-Source Text Expander Research (macOS Tahoe)

Research date: 2026-06-30  
Target OS: macOS 26.x (Tahoe), build 25F80 observed on dev machine  
Goal: Replace Raycast Snippets runtime dependency with a local-first expander

Related: [`architecture.md`](../architecture.md), [`kits.md`](../kits.md)

---

## 1. Executive Summary

Raycast is only the **runtime expander** for apps where Apple Text Replacements do not fire (Warp, VS Code, Cursor, many Chromium inputs). `keypop` already owns storage and CRUD.

Every viable open-source macOS expander uses the same core pattern:

1. **Listen** — `CGEventTap` (Input Monitoring / Accessibility TCC)
2. **Match** — rolling keystroke buffer + trie or hash map
3. **Inject** — backspace trigger, then clipboard paste or simulated keystrokes

The hardest problems are not matching logic. They are **TCC permission stability on Tahoe**, **per-app injection quirks**, and **coexistence with Apple's native layer**.

**Recommendation:** Build a small Swift menu-bar daemon (`keypop` or similar) in this repo, using Espanso and Poof as reference implementations. Poof is the closest architectural peer (Swift, Raycast import, TOML/dotfiles). Espanso is the most battle-tested injection layer.

---

## 2. Open-Source Projects (macOS-Relevant)

### Tier 1 — Primary references

| Project | Lang | Stars | License | Why study it |
|---------|------|-------|---------|--------------|
| [Espanso](https://github.com/espanso/espanso) | Rust | ~12k | GPL-3.0 | Production-grade detect/inject split; clipboard vs keystroke backends; extensive Tahoe TCC issue history |
| [Poof](https://github.com/mikker/poof) | Swift | ~100 | MIT | Native Swift expander; TOML config; **built-in Raycast JSON import**; delimiter + immediate modes; notarized release pipeline |
| [VaulType](https://github.com/vaultype/VaulType) | Swift | — | — | Excellent `TEXT_INJECTION.md`: clipboard vs `CGEvent` tradeoffs, per-app routing |

### Tier 2 — Swift peers (simpler, newer)

| Project | Lang | Notes |
|---------|------|-------|
| [GenSnippets](https://github.com/jaynguyen-vn/gen-snippets) | Swift/SwiftUI | Trie-based matching; `CGEvent` monitoring; UserDefaults storage; MIT |
| [Expandly](https://github.com/afomera/expandly) | Swift | Menu-bar app; `{{date}}`, `{{clipboard}}`; auto-disables in apps with own autocomplete (Slack, Messages) |
| [PromptPanel](https://github.com/tytsxai/PromptPanel) | Swift | Different UX (hotkey search panel, not trigger expansion); useful if we add picker fallback |
| [Parrot](https://github.com/digimata/parrot) | Swift CLI | Dictation daemon; minimal `CGEventTap` + `CGEvent` inject reference |

### Tier 3 — Cross-platform / different OS

| Project | Platform | Notes |
|---------|----------|-------|
| [MuttonText](https://github.com/Muminur/MuttonText) | macOS + Linux | Rust/Tauri; Beeftext import; app exclusions |
| [Beeftext](https://github.com/xmichelo/Beeftext) | Windows | C++/Qt; maintenance mode; best **matching-mode** documentation (strict vs loose suffix match) |
| [AutoKey](https://github.com/autokey/autokey) | Linux X11 | Python automation; clipboard + synthetic input; Wayland limitations are a cautionary tale |
| [Hammerspoon](https://github.com/Hammerspoon/hammerspoon) + [HammerText](https://gist.github.com/maxandersen/d09ebef333b0c7b7f947420e2a7bbbf5) | macOS | Lua `hs.eventtap`; educational but reports of taps stopping silently |

### Not open source but architecturally relevant

| Tool | Mechanism |
|------|-----------|
| Raycast Snippets | `CGEventTap` + inject; Accessibility required; Override System Snippets |
| Alfred Snippets | Same class of solution |
| TextExpander / Typinator | Mature inject + fill-in UI; closed source |

---

## 3. Common Architecture (Reverse-Engineered)

```
┌──────────────────────────────────────────────────────────────┐
│  Menu bar / login-item process (single persistent identity)  │
├──────────────────────────────────────────────────────────────┤
│  Event tap (CGEvent.tapCreate)                               │
│    • .cgSessionEventTap + .listenOnly → Input Monitoring     │
│    • Active tap (consume events) → needs Accessibility too   │
├──────────────────────────────────────────────────────────────┤
│  Keystroke buffer (ring buffer or trie walk)                 │
│    • Reset on navigation keys, app switch, max length        │
│    • Delimiter-triggered vs immediate expansion              │
├──────────────────────────────────────────────────────────────┤
│  Matcher                                                     │
│    • Exact keyword (our `;wl*`, `;p*` convention)            │
│    • Optional: suffix/loose match (Beeftext model)           │
├──────────────────────────────────────────────────────────────┤
│  Expander pipeline                                           │
│    1. Resolve template vars ({date}, {clipboard})            │
│    2. Simulate N × Delete/Backspace for trigger length       │
│    3. Inject phrase                                          │
├──────────────────────────────────────────────────────────────┤
│  Injection backend (pick per app or auto)                    │
│    A. Clipboard: save → set pasteboard → Cmd+V → restore     │
│    B. Keystroke: CGEventKeyboardSetUnicodeString (20-char    │
│       chunks on macOS)                                       │
│    C. Sandbox fallback: NSAppleScript → System Events paste │
└──────────────────────────────────────────────────────────────┘
```

### Espanso crate split (best documented)

| Crate | Role |
|-------|------|
| `espanso-detect` | `CocoaSource` — `CGEventTap` listen-only on macOS |
| `espanso-inject` | `native.mm` — Unicode keystroke chunks + clipboard paste |
| `espanso-engine` | Match resolution, vars, filters |
| `espanso-modulo` | Search UI (selector); slow cold-start on Tahoe 26.5 |

Source: [espanso-detect macOS](https://github.com/espanso/espanso/tree/dev/espanso-detect), [espanso-inject macOS](https://github.com/espanso/espanso/blob/dev/espanso-inject/src/mac/native.mm)

### Poof (closest Swift peer)

- Swift app, TOML in dotfiles directory
- Delimiter mode and immediate mode
- Template tokens: `{{date}}`, `{{clipboard}}`, `{{cursor}}`, `{{uuid}}`
- `just import-raycast` for Raycast JSON migration
- Notarized + Sparkle update pipeline (reference for distribution)

### Beeftext matching insight (portable)

Beeftext documents the universal limitation: expanders only see keystrokes, not cursor position. Matching is always against a **search string** built from recent printable keys. Strict match (whole buffer equals keyword) vs loose match (buffer ends with keyword) trades false positives against flexibility.

Source: [Beeftext matching mode wiki](https://github.com/xmichelo/Beeftext/wiki/Matching-mode)

---

## 4. Tahoe-Specific Pitfalls and Mitigations

macOS 26 (Tahoe) introduces or amplifies failure modes that look like "expander stopped working" with no crash.

### 4.1 TCC permission failures

| Pitfall | Symptom | Mitigation |
|---------|---------|------------|
| `AXIsProcessTrusted()` cache lies after OS update or re-sign | Toggle ON in Settings; real AX/`CGEvent.post` calls fail | Probe live TCC via `CGEvent.tapCreate(.listenOnly)`; do not trust cached boolean alone |
| Stale TCC entry after certificate / Team ID change | Endless permission prompt loop; tap installs but no callbacks | User must **remove** app with `-` button, not just disable; document in onboarding |
| CLI binary vs `.app` bundle identity mismatch | `brew` shim granted; worker binary not | Single signed `.app` bundle; spawn worker from bundle; stable `CFBundleIdentifier` |
| ListenEvent vs Accessibility vs PostEvent split | Tap works but inject silent | Request correct service per operation; `CGPreflightPostEventAccess` for injection |
| Re-sign during dev breaks tap silently | `tapCreate` non-nil, `tapIsEnabled` true, zero callbacks | Health check `CGEvent.tapIsEnabled`; reinstall tap; compare direct exec vs `open` launch |

Sources:

- [Espanso #2562 — remove old Accessibility entry before upgrade](https://github.com/espanso/espanso/issues/2562)
- [Espanso #2576 — stale Team ID in TCC](https://github.com/espanso/espanso/issues/2576)
- [Espanso #2530 — Tahoe install failures](https://github.com/espanso/espanso/issues/2530)
- [Fazm — AXIsProcessTrusted stale cache on Tahoe](https://fazm.ai/t/macos-accessibility-automation)
- [Daniel Raffel — CGEvent tap silent disable after re-sign](https://danielraffel.me/til/2026/02/19/cgevent-taps-and-code-signing-the-silent-disable-race/)
- [Apple Developer Forums — sandbox tap vs post](https://developer.apple.com/forums/thread/789896)

### 4.2 Injection failures

| Pitfall | Symptom | Mitigation |
|---------|---------|------------|
| `CGEventKeyboardSetUnicodeString` 20-char limit | Truncated long snippets | Chunk injection (Espanso pattern) or prefer clipboard backend |
| Clipboard race | Literal `v` pasted instead of snippet | `backend: Inject` or increase `pre_paste_delay`; restore clipboard after delay |
| Fast inject in terminals | Garbled or partial text | Per-app config: clipboard + delay for Warp, VS Code, Cursor |
| Unicode / emoji | Mojibake with keystroke inject | Clipboard backend for non-ASCII |
| Secure text fields | Password leaked into expander | Skip when AX role is secure / `AXIsEnabled` false on field |
| Shift held during inject | Wrong casing | Release shift before inject (Espanso #279) |

Sources: [Espanso inject native.mm](https://github.com/espanso/espanso/blob/dev/espanso-inject/src/mac/native.mm), [Espanso #1288](https://github.com/espanso/espanso/issues/1288), [VaulType TEXT_INJECTION.md](https://github.com/vaultype/VaulType/blob/main/docs/features/TEXT_INJECTION.md)

### 4.3 Coexistence with Apple Text Replacements

| Pitfall | Symptom | Mitigation |
|---------|---------|------------|
| Same keyword in Apple + custom expander | Double expansion or race | Custom expander runs with higher priority; consume trigger keys; or disable Apple layer on Mac |
| Raycast still installed | Unpredictable winner | Remove Raycast from workflow once validated; check for competing expanders |
| Native works in Slack but not Warp | User confusion about which layer | Document app matrix; single runtime on Mac |

Our current Raycast setting **Override System Snippets ON** is the model: custom expander must expand even when Apple has the same keyword.

### 4.4 Operational / UX pitfalls

| Pitfall | Symptom | Mitigation |
|---------|---------|------------|
| Manual Raycast import | Drift between `keypop` and Raycast | File watch on `keypop export` output; auto-reload snippet map |
| `name` field in kits | Lost in Apple DB | Keep in sidecar JSON for daemon; Apple stores shortcut+phrase only |
| `{clipboard}` in kits imported to Apple | Literal `{clipboard}` text on iOS | Strip or resolve at daemon layer only |
| Long prompts on iOS | Apple size limit | Mark long prompts Mac-only in kit `name` |
| Espanso selector on 26.5 | Multi-second beachball | Skip search UI for v1; trigger-only expansion |
| KeepassXC / other automation tools | Blocks inject | Document conflict; test with security tools running |

Source: [Espanso #2689 — SearchUI beachball on 26.5](https://github.com/espanso/espanso/issues/2689)

---

## 5. Feature Scope vs Implementation Cost

| Capability | Espanso | Poof | Custom Swift daemon | Needed for Raycast replacement? |
|------------|---------|------|---------------------|--------------------------------|
| Static `;keyword` → text | Yes | Yes | Easy | **Yes** |
| Multi-line phrases | Yes | Yes | Easy (clipboard) | **Yes** |
| Delimiter vs immediate | Yes | Yes | Medium | Nice to have |
| `{date}` / `{clipboard}` | Yes | Yes | Medium | Yes for `;p*` prompts |
| `{cursor}` placement | Yes | Yes | Hard | Later |
| App exclusions | Yes | Partial | Medium | Yes (disable in password managers) |
| Search/picker UI | Yes | No | Hard | No (v1) |
| Raycast JSON import | Via convert | Built-in | Trivial (`KeypopKit`) | **Yes** |
| Read from Apple DB live | No | No | **Already have bridge** | **Yes — differentiator** |
| iOS sync | No | No | Via Apple layer only | Keep dual-layer |
| Notarization | Yes | Yes | Medium | For daily driver |

---

## 6. Build vs Adopt Decision Matrix

| Option | Time to drop Raycast | Maintenance | Fits repo |
|--------|---------------------|-------------|-----------|
| **A. Adopt Espanso** (`sync-espanso.sh`) | 1–2 days | Low (upstream) | Partial — Rust/YAML parallel to Swift |
| **B. Adopt Poof** | 1 day | Low | Good — Swift, Raycast import exists |
| **C. Custom Swift daemon** | 3–5 weeks to daily-driver | You own it | **Best** — reuses `KSPrivateBridge`, single toolchain |
| **D. Hammerspoon config** | Hours | Fragile | Poor — tap reliability reports |

**Suggested path:** Phase 0 spikes on Tahoe → Phase 1 custom Swift daemon OR Poof fork if spikes fail → keep `keypop` as source of truth.

Poof is a strong **stopgap** if we want to drop Raycast this week without building inject from scratch. Custom daemon is the long-term fit because we can read Apple Text Replacements directly and eliminate export/import sync.

---

## 7. Tahoe Permission Checklist (for any expander)

Onboarding and troubleshooting script for users:

1. Install as signed `.app` in `/Applications` (not raw `swift run` for daily use)
2. Grant **Input Monitoring** and **Accessibility** (verify both in System Settings)
3. If tap silent: remove entry with `-`, not toggle off
4. Reset if needed: `tccutil reset ListenEvent <bundle-id>` and `tccutil reset Accessibility <bundle-id>`
5. Confirm no competing expander (Raycast, Espanso, TextExpander, Karabiner text features)
6. Restart app after macOS point updates

Daemon health loop (production):

```
every N seconds:
  if AXIsProcessTrusted() != liveTapProbe():
    show "Permission stale — quit and reopen"
  if tap != nil && !CGEvent.tapIsEnabled(tap):
    reinstall tap
```

---

## 8. App Compatibility Matrix (test targets)

Priority apps from [`kits.md`](../kits.md):

| App | Apple native | Raycast today | Spike priority |
|-----|--------------|---------------|----------------|
| Warp | No | Yes | P0 |
| VS Code | No | Yes | P0 |
| Cursor | No | Yes | P0 |
| Chrome | Inconsistent | Yes | P1 |
| Slack | Often yes | Yes | P1 (avoid double expand) |
| Terminal.app / iTerm | No | Yes | P1 |
| Notes / Mail | Yes | N/A | P2 (ensure no double) |
| Password manager fields | Must never expand | — | P0 security |

---

## 9. Sources

### Open-source repos

- [espanso/espanso](https://github.com/espanso/espanso)
- [mikker/poof](https://github.com/mikker/poof)
- [jaynguyen-vn/gen-snippets](https://github.com/jaynguyen-vn/gen-snippets)
- [afomera/expandly](https://github.com/afomera/expandly)
- [Muminur/MuttonText](https://github.com/Muminur/MuttonText)
- [xmichelo/Beeftext](https://github.com/xmichelo/Beeftext)
- [autokey/autokey](https://github.com/autokey/autokey)
- [Hammerspoon/hammerspoon#1042](https://github.com/Hammerspoon/hammerspoon/issues/1042)
- [vaultype/VaulType TEXT_INJECTION.md](https://github.com/vaultype/VaulType/blob/main/docs/features/TEXT_INJECTION.md)
- [digimata/parrot](https://github.com/digimata/parrot)

### Tahoe / TCC

- [Espanso #2402, #2530, #2562, #2576, #2689](https://github.com/espanso/espanso/issues)
- [Apple Developer Forums — sandbox CGEventTap](https://developer.apple.com/forums/thread/789896)
- [DEV — sandbox paste via System Events](https://dev.to/quicopy/shipping-global-keyboard-shortcuts-on-macos-sandbox-the-part-apple-doesnt-document-57no)

### Internal

- [`docs/architecture.md`](../architecture.md) — KeyboardServices / Apple layer
- [`docs/kits.md`](../kits.md) — Raycast JSON interchange, app gaps
