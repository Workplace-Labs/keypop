# Changelog

## [Unreleased]

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
