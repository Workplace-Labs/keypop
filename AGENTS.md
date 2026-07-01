# Agent Context (keypop)

Swift package for Apple Text Replacements management and Mac system-wide expansion.

**Repository:** [Workplace-Labs/keypop](https://github.com/Workplace-Labs/keypop)

## Components

| Target | Purpose |
|--------|---------|
| `keypop` | CLI — CRUD, daemon (`run`), diagnostics (`probe`) |
| `KeypopKit` | Snippet kit format, `RuntimeExport`, engine, file watcher |
| `KSPrivateBridge` | Objective-C runtime bridge to KeyboardServices |

## Design constraints

- **Plain text only** in kits — no `{clipboard}` or dynamic placeholders (iOS + Mac parity)
- Kit JSON: `name`, `keyword`, `text` (`.snippets.json` convention)

## Snippet workflow

| Layer | Command | Covers |
|-------|---------|--------|
| Apple Text Replacements | `keypop create/update/...` | iOS, native Mac apps |
| Mac runtime | `keypop run` | Warp, VS Code, Cursor, terminals |

Mutations auto-export to `~/.config/keypop/snippets.json` unless `--no-sync`. Running `keypop run` reloads from that file via directory watch (~200ms debounce).

Scripts: `install.sh`, `bundle-keypop-app.sh`, `launch-keypop.sh`, `sync-keypop.sh`, `probes/run-sprint0.sh`

**TCC:** LaunchAgent runs `~/.local/KeyPop.app/Contents/MacOS/keypop run`. Grant Input Monitoring + Accessibility to **`~/.local/KeyPop.app`**, not Terminal. Re-grant after `install.sh` rebuilds the bundle.

`keypop` prints `keypop_hint|` on stderr when sync succeeds but the daemon is not running.

## Validation

```sh
swift build && swift test
./scripts/install.sh
./scripts/launch-keypop.sh status
keypop inspect
scripts/validate-crud.sh
```

## Safety

- Never write directly to `~/Library/KeyboardServices/TextReplacements.db`
- `import --apply` must write backups under `backups/` first
- Not Mac App Store safe
