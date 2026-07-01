# Agent Context (trctl + trexpand)

Swift package for Apple Text Replacements management and Mac system-wide expansion. Not part of the root pnpm workspace.

**Branch:** `feat/trexpand-sprint0`

## Components

| Target | Purpose |
|--------|---------|
| `trctl` | CLI — CRUD via private KeyboardServices APIs (no Accessibility) |
| `trexpand` | Mac expander daemon — CGEventTap + clipboard inject |
| `trexpand-probe` | TCC / inject / bridge diagnostics |
| `TrctlKit` | Snippet kit format, `ExpanderExport` |
| `TrexpandKit` | Engine, permissions, tap health, `SnippetFileWatcher` |
| `KSPrivateBridge` | Objective-C runtime bridge |

## Design constraints

- **Plain text only** in kits — no `{clipboard}` or dynamic placeholders (iOS + Mac parity)
- **trctl does not depend on TrexpandKit** — sync via `TrctlKit.ExpanderExport`
- Kit JSON: `name`, `keyword`, `text` (`.snippets.json` convention)

## Snippet workflow

| Layer | Tool | Covers |
|-------|------|--------|
| Apple Text Replacements | `trctl` | iOS, native Mac apps |
| Mac runtime | `trexpand` | Warp, VS Code, Cursor, terminals |

`trctl` mutations auto-export to `~/.config/trexpand/snippets.json` unless `--no-sync-expander`. Running trexpand reloads from that file via directory watch (~200ms debounce).

Scripts: `install.sh`, `bundle-trexpand-app.sh`, `launch-trexpand.sh`, `sync-expander.sh`, `probes/run-sprint0.sh`

**TCC:** LaunchAgent runs `~/.local/Trexpand.app/Contents/MacOS/trexpand`. Grant Input Monitoring + Accessibility to the **app bundle** (`~/.local/Trexpand.app`), not Terminal and not the bare `~/.local/bin/trexpand` exec. Re-grant after `install.sh` rebuilds the bundle.

`trctl` prints `trexpand_hint|` on stderr when sync succeeds but the daemon process is not running.

## Validation

```sh
swift build && swift test
./scripts/install.sh
./scripts/launch-trexpand.sh status
trctl inspect
scripts/validate-crud.sh
```

## Safety

- Never write directly to `~/Library/KeyboardServices/TextReplacements.db`
- `import --apply` must write backups under `backups/` first
- Not Mac App Store safe
