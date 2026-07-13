# Architecture Notes

Evidence gathered on macOS 26.5.1 shows that Apple Text Replacements still have a KeyboardServices implementation, but the framework binary is not materialized as a normal file on disk. The framework directory contains resources and a symlink named `KeyboardServices`; tools such as `dyld_info` can resolve it through the dyld shared cache, while `nm` reports that the path does not exist.

## Current Components

- Private framework bundle: `/System/Library/PrivateFrameworks/KeyboardServices.framework`
- Framework identifier: `com.apple.textInput.KeyboardServices`
- Local database: `~/Library/KeyboardServices/TextReplacements.db`
- Core Data model resource: `_KSTextReplacementModel.mom`
- Legacy model resource: `UserDictionary.mom`

The local database is SQLite and contains these observed tables:

- `ZTEXTREPLACEMENTENTRY`
- `ZTRCLOUDKITSYNCSTATE`
- `Z_METADATA`
- `Z_MODELCACHE`
- `Z_PRIMARYKEY`

The primary entry schema includes:

- `ZSHORTCUT`
- `ZPHRASE`
- `ZUNIQUENAME`
- `ZTIMESTAMP`
- `ZNEEDSSAVETOCLOUD`
- `ZWASDELETED`
- `ZREMOTERECORDINFO`

`KeyboardServices` imports Core Data, CloudKit, NSXPC, preferences, notify, and xpc activity symbols. That supports the working model that local changes are persisted through Core Data/SQLite and then synchronized through a private CloudKit-backed path, not a plain plist.

## API Shape

The old `rodionovd/shortcuts` project used private Objective-C classes:

- `_KSTextReplacementClientStore`
- `_KSTextReplacementEntry`
- `_KSTextReplacementHelper`

Those classes still export on this system. Newer related classes also export:

- `_KSTextReplacementCoreDataStore`
- `_KSTextReplacementCKStore`
- `_KSTextReplacementManager`
- `_KSTextReplacementServer`
- `_KSTextReplacementServerConnection`
- `_KSTextReplacementManagedObject`
- `_KSCKSyncStateManagedObject`

The current prototype loads KeyboardServices with `dlopen`, creates private objects dynamically, and communicates through Objective-C runtime selectors. Direct database writes are avoided because they could bypass CloudKit sync metadata, tombstones, validation, and notifications.

## Prototype Results

Proven on macOS 26.5.1:

- `create`: `_KSTextReplacementClientStore addEntries:removeEntries:withCompletionHandler:`
- `update`: `_KSTextReplacementClientStore modifyEntry:toEntry:withCompletionHandler:`
- `delete`: `_KSTextReplacementClientStore addEntries:removeEntries:withCompletionHandler:`

The old `performTransaction:completionHandler:` route is not viable as-is on this OS. It raises an exception because it sends `textReplaceEntryFromTIDictionaryValue:` to `_KSTextReplacementClientStore`, while runtime method inspection shows that selector on `_KSTextReplacementHelper`. The final CRUD path avoids that drift and uses `addEntries:removeEntries:withCompletionHandler:` for create/delete because that route produced verified database changes without compatibility shims.

Read behavior:

- `_KSTextReplacementClientStore textReplacementEntries` returns zero entries.
- `_KSTextReplacementClientStore queryTextReplacementsWithCallback:` returns zero entries.
- `_KSTextReplacementCoreDataStore textReplacementEntriesWithLimit:` returns the active replacements and is now the preferred read source.
- `NSUserDictionaryReplacementItems` still mirrors the active user-visible replacements and is kept only as a last-resort fallback.

That means modern private read and mutation are both viable through KeyboardServices, with a narrower open question around whether the XPC server connection is a better long-term API boundary than local Core Data store access.

## keypop run (Mac runtime)

`keypop run` is a headless LaunchAgent (not a menu-bar app). It expands snippets in apps where Apple Text Replacements do not fire (Warp, VS Code, Cursor, many terminals).

```
keypop mutation
    → stableReplacements() read (KeyboardServices lag handled)
    → RuntimeExport.write → ~/.config/keypop/snippets.json (atomic)
    → SnippetFileWatcher (parent directory; atomic replace safe)
    → ExpanderEngine.reload()
```

| Piece | Role |
|-------|------|
| `ExpanderEngine` | `CGEventTap` listen-only + `ClipboardInjector` backspace/paste |
| `SnippetFileWatcher` | Directory vnode watch; file-only watch breaks after atomic export |
| `TapHealthMonitor` | Re-enable tap on timeout; light periodic health checks |
| `KeyPop.app` | Minimal signed bundle at `~/Applications/KeyPop.app` for stable LaunchAgent TCC |
| LaunchAgent | `io.keypop.daemon` in `~/Library/LaunchAgents/` |

**TCC pitfall:** macOS grants Input Monitoring to bare CLI binaries when launched from Terminal, but `launchd`-spawned binaries need a `.app` bundle identity. The System Settings toggle on a black **exec** `keypop` entry does not apply to the LaunchAgent. Re-signing with a new identity (ad-hoc or new cert) orphans TCC grants — use `./scripts/create-keypop-signing-cert.sh` (`KeyPop Dev`) for stable grants across rebuilds.

**Operator flow:** `./scripts/create-keypop-signing-cert.sh` (once) → `./scripts/install-full.sh` → grant Input Monitoring + Accessibility to `KeyPop.app` → `./scripts/launch-keypop.sh restart`. `keypop` emits `keypop_hint|` when sync succeeds but no daemon process is running.
