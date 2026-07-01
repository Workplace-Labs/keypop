# Agent Context (trctl)

Swift CLI for Apple Text Replacements via private `KeyboardServices` APIs. Standalone SwiftPM package — not part of the root pnpm workspace.

## Goal

Developer-tool path for reading, creating, updating, and deleting Apple Text Replacements without UI automation, daemons, or Accessibility permission. Validated on macOS 26.5.1.

## Project Shape

- CLI: `Sources/trctl`
- Bridge: `Sources/KSPrivateBridge`
- Kit helpers: `Sources/TrctlKit`
- Tests: `Tests/KSPrivateBridgeTests`, `Tests/TrctlKitTests`
- User docs: `README.md`, `docs/user-guide.md`, `docs/kits.md`
- Contributor docs: `docs/architecture.md`, `docs/open-source-expander-research.md`, `docs/sprint-plan-expander-runtime.md`
- Archived notes: `docs/archive/` (personal guide, research — not linked from README)

## Known Working API Routes

Read: `_KSTextReplacementCoreDataStore textReplacementEntriesWithLimit:` (fallback: `NSUserDictionaryReplacementItems`)

Mutation via `_KSTextReplacementClientStore`:

- Create/delete: `addEntries:removeEntries:withCompletionHandler:`
- Update: `modifyEntry:toEntry:withCompletionHandler:`

Do not use `performTransaction:completionHandler:` as primary path on macOS 26.5.1.

## Safety Rules

- Never write directly to `~/Library/KeyboardServices/TextReplacements.db`
- Bulk import requires `--dry-run` or `--apply` (never implicit apply)
- `import --apply` must write backups under `backups/` first
- `--prefix` rejects out-of-scope rows on import
- Kit format: Raycast JSON only (`name`, `keyword`, `text`)
- Not Mac App Store safe

## Snippet Sync Workflow

| Layer | Tool | Covers |
|-------|------|--------|
| Apple Text Replacements | `trctl` | iOS, Notes, Mail, Slack, Safari |
| Raycast Snippets | `sync-raycast.sh` | Warp, VS Code, Cursor |

Raycast: **Override System Snippets ON**. After changes: `./scripts/sync-raycast.sh`

## Validation

```sh
swift build && swift test
trctl inspect
trctl read-sources
scripts/validate-crud.sh
```

Probe cleanup check:

```sh
sqlite3 "$HOME/Library/KeyboardServices/TextReplacements.db" \
  "select count(*) from ZTEXTREPLACEMENTENTRY where ZSHORTCUT like ';trctlprobe%';"
```

Expected: `0`.

## Development Guidance

- Dynamic Objective-C runtime calls over private headers
- CLI outputs JSON for machine-readable commands
- Tests non-mutating by default
- Personal conventions live in `docs/archive/user-guide.personal.md` only
