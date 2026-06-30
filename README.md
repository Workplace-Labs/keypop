# Modern macOS Text Replacement Research

Research and prototype workspace for determining whether current macOS still exposes private APIs that can manage Apple Text Replacements without UI automation.

Current evidence was gathered on:

- macOS 26.5.1, build 25F80
- Darwin 25.5.0
- Apple Silicon arm64

## Quick Start

```sh
swift build
.build/debug/trctl list
.build/debug/trctl list --prefix ';wl'
.build/debug/trctl export --output kits/full.raycast.json
.build/debug/trctl export --prefix ';wl' --output kits/wl-team.raycast.json
.build/debug/trctl get --shortcut ';pcr'
```

`list` and `export` use the **Raycast snippet JSON format** (`name`, `keyword`, `text`). Exported files can be imported directly in Raycast via **Import Snippets**. See [`docs/kits.md`](docs/kits.md).

Mutation commands operate on your real Apple Text Replacements:

```sh
.build/debug/trctl create --shortcut ';demo' --phrase 'Demo phrase'
.build/debug/trctl update --shortcut ';demo' --phrase 'Updated demo phrase'
.build/debug/trctl delete --shortcut ';demo'
```

Bulk import requires exactly one of `--dry-run` or `--apply`:

```sh
.build/debug/trctl import kits/prompts-core.raycast.json --prefix ';p' --dry-run
.build/debug/trctl import kits/prompts-core.raycast.json --prefix ';p' --apply --on-conflict skip
.build/debug/trctl import kits/wl-team.raycast.json --prefix ';wl' --dry-run
```

For a safe disposable end-to-end validation:

```sh
scripts/validate-crud.sh
```

After changing replacements, sync to Raycast (Warp, VS Code, Cursor, etc.):

```sh
scripts/sync-raycast.sh
```

Raycast: **Override System Snippets ON**. See [`AGENTS.md`](AGENTS.md) for the full sync workflow.

These commands use private framework classes and are not suitable for Mac App Store software.

Validated on macOS 26.5.1:

- create via KeyboardServices private API
- update via KeyboardServices private API
- delete via KeyboardServices private API
- no Accessibility permission prompt observed

Read behavior is also private-framework backed: `list` prefers `_KSTextReplacementCoreDataStore`. The older client-store read selectors still return empty on this OS, so the defaults mirror remains a last-resort fallback.

## New User Guide

Start here for naming conventions, team sharing, and onboarding:

- [`docs/user-guide.md`](docs/user-guide.md)
- [`docs/kits.md`](docs/kits.md) — Raycast JSON kit format and limitations

## Project Layout

- `Sources/trctl`: Swift command-line interface.
- `Sources/TrctlKit`: Raycast kit parse/export helpers.
- `Sources/KSPrivateBridge`: Objective-C runtime bridge for private KeyboardServices calls.
- `kits/`: Shareable Raycast-format JSON kits (e.g. `prompts-core.raycast.json`).
- `scripts/inspect-system.sh`: repeatable framework, symbol, and database inspection.
- `scripts/validate-crud.sh`: disposable create/update/delete validation with cleanup.
- `scripts/sync-raycast.sh`: export replacements to Raycast-importable JSON.
- `docs/architecture.md`: current architecture notes.
- `docs/symbols.md`: discovered classes, symbols, and old-project comparison.
- `docs/recommendation.md`: current recommendation and open validation items.

## Safety Notes

- `db-summary` reports schema and counts only. It does not print actual user replacements.
- `read-sources` reports counts only and shows which read source `list` will use.
- `list` and `export` output Raycast snippet JSON (`name`, `keyword`, `text`); see `docs/kits.md`.
- `import` accepts Raycast snippet JSON only (`name`, `keyword`, `text`).
- `--prefix <prefix>` scopes `list`, `export`, and `import` to shortcut naming conventions such as `;wl` (matches `;wle`, `;wlw`, …).
- `import --apply` writes a timestamped JSON backup under `backups/` before changing replacements.
- Writes go through KeyboardServices private APIs, not direct SQLite mutation.
- Direct database writes are deliberately not implemented.
