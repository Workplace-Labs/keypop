# Changelog

## [Unreleased]

## [0.2.3] - 2026-07-13

### Added

- A 30-minute, metadata-only diagnostic session for intermittent expansion failures: `./scripts/launch-keypop.sh debug`, then `diagnostics` for a redacted report.

### Fixed

- Full installs now restart the Mac expander, so a rebuilt KeyPop.app is the daemon actually running.
- Runtime logs no longer include shortcut or expanded prompt text.

### Changed

- Install paths are named plainly: root `install.sh` is the curl-friendly CLI-only bootstrap; `scripts/install-full.sh` installs the Mac expander.

## [0.2.2] - 2026-07-03

### Added

- Runtime usage stats — `keypop stats`, prefix filtering, and reset commands backed by local `~/.config/keypop/usage.json`.
- Xcode Command Line Tools guidance — install docs and a fast failure when `swift` is missing.

### Fixed

- Prefix-colliding shortcuts are now detected before they can shadow each other in the Mac runtime.
- Workplace Labs dev kit renamed `;wlexplain` to `;wldoc` so it does not block `;wle`.

## [0.2.1] - 2026-07-03

### Fixed

- Mac runtime expansion — CGEventTap-only listen, stable `KeyPop Dev` signing, and clearer TCC diagnostics when grants go stale after rebuilds.
- Daemon exits when the event tap cannot be restored (no more zombie processes after permission loss).
- App bundle installs to `~/Applications/KeyPop.app` with orbit-tilt icon.

### Changed

- `fix-keypop-tcc.sh` does a full rebuild + TCC reset by default; install paths centralized in `keypop-paths.sh`.

## [0.2.0] - 2026-07-01

### Added

- **Snippet kits** — prompts that travel with you, one keystroke away:
  - `prompts-core` — starter templates (`;pproof`, `;pcr`, `;psum`)
  - `workplace-labs-top5` — the five you'd actually reach for daily
  - `workplace-labs-thinking` — premortems, tradeoffs, decision summaries
  - `workplace-labs-hr` — retention, focus groups, AI rollout risks
  - `lab-rats` — adoption prompts with questionable metaphors about cheese and sleeping cats
- **`[prefix]-list` on import** — type `;wl-list` and get a compact cheat sheet of everything you just imported. No more "wait, what was that shortcut again?"

### Changed

- README — friendlier story, agent skill install, and a security nudge before you hand over Accessibility permissions
- Docs — Lab Rats (`;lab`) and `;wl` prompt zone conventions

## [0.1.0] - 2026-07-01

First release. KeyPop exists.

- Unified CLI: manage Apple Text Replacements + run a background expander for Warp, VS Code, Cursor, terminals
- Private KeyboardServices bridge — reads and writes replacements without touching the database by hand
- Auto-sync to `~/.config/keypop/snippets.json` with atomic import backups
- `keypop inspect`, `keypop probe`, GitHub Actions CI on macOS
