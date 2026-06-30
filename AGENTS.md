# Agent Context (macos-text-replacements)

This project researches and prototypes a Swift wrapper around modern macOS private APIs for Apple Text Replacements.

## Goal

Determine and preserve a practical developer-tool path for:

- reading Apple Text Replacements
- creating replacements
- updating replacements
- deleting replacements

without UI automation, login items, background daemons, or Accessibility permission.

The current answer is yes on macOS 26.5.1: read/create/update/delete work through `KeyboardServices.framework` private APIs.

## Project Shape

- SwiftPM package.
- CLI target: `Sources/trctl`.
- Objective-C runtime bridge target: `Sources/KSPrivateBridge`.
- Tests: `Tests/KSPrivateBridgeTests`.
- Research notes: `docs/`.
- Repeatable probes: `scripts/inspect-system.sh`, `scripts/validate-crud.sh`, `scripts/sync-raycast.sh`.

Keep this project isolated under `projects/macos-text-replacements/`. Do not wire it into the root pnpm workspace.

## Known Working API Routes

Read:

- Preferred: `_KSTextReplacementCoreDataStore textReplacementEntriesWithLimit:`.
- Last-resort fallback: `NSUserDictionaryReplacementItems`.

Mutation:

- Create: `_KSTextReplacementClientStore addEntries:removeEntries:withCompletionHandler:`.
- Update: `_KSTextReplacementClientStore modifyEntry:toEntry:withCompletionHandler:`.
- Delete: `_KSTextReplacementClientStore addEntries:removeEntries:withCompletionHandler:`.

Avoid reviving `performTransaction:completionHandler:` as the primary path. On macOS 26.5.1 it raises because `textReplaceEntryFromTIDictionaryValue:` is no longer owned by `_KSTextReplacementClientStore`.

## Safety Rules

- Do not write directly to `~/Library/KeyboardServices/TextReplacements.db`.
- Do not print real replacement contents unless the command explicitly exists to list replacements.
- Prefer count/schema/source probes for diagnostics.
- Mutation validation must use a unique disposable shortcut and must clean it up.
- Keep `scripts/validate-crud.sh` passing; it is the safest end-to-end mutation check.
- Bulk import must require either `--dry-run` or `--apply`; never make apply implicit.
- Keep import backups enabled before bulk mutation.
- Prefix-scoped work should use `--prefix <prefix>`, not a separate group abstraction.
- When `import --prefix <prefix>` is used, reject rows outside that prefix.
- Kit interchange uses Raycast snippet JSON (`name`, `keyword`, `text`); `export` is Raycast-importable.
- `import` accepts Raycast snippet JSON only (`name`, `keyword`, `text`).
- Treat private API behavior as OS-version-specific. Capture `sw_vers` evidence when changing API assumptions.
- Do not add Accessibility/UI automation unless private APIs become nonviable and docs explain why.
- This cannot be positioned as Mac App Store-safe software.

## Snippet Sync Workflow

Maintain the same keywords in both systems:

| Layer | Tool | Covers |
|-------|------|--------|
| Apple Text Replacements | `trctl` | iOS, Notes, Mail, Slack, Safari |
| Raycast Snippets | `sync-raycast.sh` | Warp, VS Code, Cursor, Chrome |

Raycast setting: **Override System Snippets ON** (Settings → Snippets). Required when keywords overlap — with it OFF, Raycast defers to macOS and Warp gets nothing.

After adding or changing replacements:

```sh
./scripts/sync-raycast.sh
```

Exports to `exports/raycast-sync.json`, copies to `~/Desktop/raycast-sync.json`, opens Raycast Import Snippets. Click the Desktop file in the picker.

## Validation

Run from this directory:

```sh
swift build
swift test
.build/debug/trctl inspect
.build/debug/trctl read-sources
.build/debug/trctl list
.build/debug/trctl list --prefix ';wl'
scripts/validate-crud.sh
```

Expected current shape:

- `inspect` loads KeyboardServices and finds the key private classes.
- `read-sources` uses `_KSTextReplacementCoreDataStore`.
- `validate-crud.sh` prints:
  - `after-create|1`
  - `after-update|1`
  - `after-delete|0`

Before finishing work that touches mutation, also verify no probe rows remain:

```sh
sqlite3 "$HOME/Library/KeyboardServices/TextReplacements.db" \
  "select count(*) from ZTEXTREPLACEMENTENTRY where ZSHORTCUT like ';trctlprobe%';"
```

Expected output: `0`.

## Development Guidance

- Prefer dynamic Objective-C runtime calls over private headers.
- Keep bridge errors explicit and user-readable.
- Keep CLI output JSON for machine-readable commands.
- Keep tests non-mutating by default.
- If adding mutating tests, make them opt-in and cleanup-safe.
- Keep docs synchronized with observed OS behavior.
- If investigating newer APIs, prefer `dyld_info`, runtime method inspection, and controlled probes before changing the wrapper path.
