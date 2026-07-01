---
name: keypop
description: >-
  Manage Apple Text Replacements and Mac system-wide text expansion using the
  keypop CLI. Use when the user wants to list, add, update, delete, import, or
  export text replacements, manage snippet kits (.snippets.json), run or check
  the keypop daemon, or troubleshoot expansion in Warp, VS Code, Cursor, or
  terminals.
metadata:
  version: "1.0"
  project: macos-text-replacements
---

# keypop — Text Replacements

## Architecture

Two layers, one keyword library:

| Layer | Command | Where it works |
|-------|---------|----------------|
| Apple Text Replacements | `keypop list/create/...` | iOS, Notes, Mail, Messages, Safari, Slack |
| Mac expander | `keypop run` | Warp, VS Code, Cursor, Terminal |

Mutations auto-export to `~/.config/keypop/snippets.json`. `keypop run` watches that file (~200ms debounce) and reloads automatically.

## CLI reference

```sh
keypop list [--prefix <prefix>]
keypop get --shortcut <shortcut>
keypop export [--prefix <prefix>] [--output <path>]
keypop create --shortcut <shortcut> --phrase <phrase>
keypop update --shortcut <shortcut> --phrase <phrase>
keypop delete --shortcut <shortcut>
keypop import <path|-> [--prefix <prefix>] [--dry-run|--apply] [--on-conflict fail|skip|overwrite] [--no-sync]

keypop run [--snippets ~/.config/keypop/snippets.json]

keypop probe permissions|listen|inject|bridge

keypop inspect
keypop read-sources
keypop db-summary
```

Disable runtime sync: `--no-sync` or `KEYPOP_SYNC=0`.

## Workflows

### Add or update a single replacement

1. **Gather:** `keypop get --shortcut '<shortcut>'` (skip if creating)
2. **Act:** `keypop create` or `keypop update`
3. **Verify:** `keypop get --shortcut '<shortcut>'` and confirm `~/.config/keypop/snippets.json` matches

### Import a kit

Always dry-run first:

```sh
keypop import kits/prompts-core.snippets.json --prefix ';p' --dry-run
keypop import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip
```

### Re-sync runtime export

```sh
./scripts/sync-keypop.sh
```

## Conventions

- **Semicolon prefix:** `;github` not `github`
- **Plain text only:** no `{clipboard}`, `{date}`, or dynamic placeholders
- **~2000 char limit:** risky on iOS for long prompts

## Daemon

```sh
./scripts/launch-keypop.sh status
./scripts/launch-keypop.sh restart
./scripts/install.sh
```

**TCC:** Grant Input Monitoring + Accessibility to `~/.local/KeyPop.app`.

**stderr signals:**
- `keypop_sync|<path>|<count>` — export succeeded
- `keypop_hint|daemon not running` — run `./scripts/launch-keypop.sh restart`

## Safety

- Never write directly to `~/Library/KeyboardServices/TextReplacements.db`
- Always `--dry-run` before `import --apply`

## Key paths

| Path | Purpose |
|------|---------|
| `~/.config/keypop/snippets.json` | runtime snippets |
| `~/.local/KeyPop.app` | app bundle (TCC target) |
| `kits/` | shareable snippet kits |
| `backups/` | pre-apply import backups |
