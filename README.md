# Modern macOS Text Replacement Research

Research and prototype workspace for determining whether current macOS still exposes private APIs that can manage Apple Text Replacements without UI automation.

Current evidence was gathered on:

- macOS 26.5.1, build 25F80
- Darwin 25.5.0
- Apple Silicon arm64

## Quick Start

```sh
swift build
.build/debug/trctl inspect
.build/debug/trctl read-sources
.build/debug/trctl db-summary
.build/debug/trctl private-list
```

Mutation commands are intentionally explicit:

```sh
scripts/validate-crud.sh
```

These commands use private framework classes and are not suitable for Mac App Store software.

Validated on macOS 26.5.1:

- create via KeyboardServices private API
- update via KeyboardServices private API
- delete via KeyboardServices private API
- no Accessibility permission prompt observed

Read behavior is also private-framework backed: `private-list` prefers `_KSTextReplacementCoreDataStore`. The older client-store read selectors still return empty on this OS, so the defaults mirror remains a last-resort fallback.

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
- `read-sources` reports counts only and shows which read source `private-list` will use.
- `private-list` prints actual replacements because that is required to inspect read capability. It prefers private framework reads and falls back to `NSUserDictionaryReplacementItems` only if private reads fail or return empty.
- Writes go through KeyboardServices private APIs, not direct SQLite mutation.
- Direct database writes are deliberately not implemented.
