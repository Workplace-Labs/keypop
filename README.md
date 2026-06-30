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
.build/debug/trctl export --output replacements.json
.build/debug/trctl export --prefix ';wl' --output wl-replacements.json
.build/debug/trctl get --shortcut ';demo'
```

Mutation commands operate on your real Apple Text Replacements:

```sh
.build/debug/trctl create --shortcut ';demo' --phrase 'Demo phrase'
.build/debug/trctl update --shortcut ';demo' --phrase 'Updated demo phrase'
.build/debug/trctl delete --shortcut ';demo'
```

Bulk import is dry-run by default in practice because it requires either `--dry-run` or `--apply`:

```sh
.build/debug/trctl import replacements.json --dry-run
.build/debug/trctl import replacements.json --apply --on-conflict overwrite
.build/debug/trctl import wl-replacements.json --prefix ';wl' --dry-run
```

For a safe disposable end-to-end validation:

```sh
scripts/validate-crud.sh
```

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

## Project Layout

- `Sources/trctl`: Swift command-line interface.
- `Sources/KSPrivateBridge`: Objective-C runtime bridge for private KeyboardServices calls.
- `scripts/inspect-system.sh`: repeatable framework, symbol, and database inspection.
- `scripts/validate-crud.sh`: disposable create/update/delete validation with cleanup.
- `docs/architecture.md`: current architecture notes.
- `docs/symbols.md`: discovered classes, symbols, and old-project comparison.
- `docs/recommendation.md`: current recommendation and open validation items.

## Safety Notes

- `db-summary` reports schema and counts only. It does not print actual user replacements.
- `read-sources` reports counts only and shows which read source `list` will use.
- `list` and `export` print actual replacements because that is their purpose.
- `--prefix <prefix>` scopes `list`, `export`, and `import` to shortcut naming conventions such as `;wl` (matches `;wle`, `;wlw`, …).
- `import --apply` writes a timestamped JSON backup under `backups/` before changing replacements.
- Writes go through KeyboardServices private APIs, not direct SQLite mutation.
- Direct database writes are deliberately not implemented.
