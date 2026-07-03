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
  project: keypop
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

**Signing:** `./scripts/create-keypop-signing-cert.sh` once, then `install.sh` signs with `KeyPop Dev` so TCC survives rebuilds.

**Troubleshooting Warp / no expansion:**
```sh
./scripts/launch-keypop.sh status
~/.local/KeyPop.app/Contents/MacOS/keypop probe permissions   # readyForListen must be true
./scripts/fix-keypop-tcc.sh --rebundle   # after rebuild if grants went stale
tail -f ~/.local/log/keypop.log          # expanded| lines confirm matches
```

**stderr signals:**
- `keypop_sync|<path>|<count>` — export succeeded
- `keypop_hint|daemon not running` — run `./scripts/launch-keypop.sh restart`

## Safety

- Never write directly to `~/Library/KeyboardServices/TextReplacements.db`
- Always `--dry-run` before `import --apply`

## Personal workspace (`private/`)

Gitignored folder for machine-local content. Scaffold it when the user wants a personal or team user guide, private kits, or a snippet mirror for diffing.

```
private/
  user-guide.md     # personal/team conventions and onboarding notes
  snippets.json     # optional mirror (see below)
  backups/          # import --apply backups (auto-created)
  kits/             # optional personal team kits (*.snippets.json)
```

**Where snippets actually live**

| Path | Role |
|------|------|
| `~/.config/keypop/snippets.json` | **Canonical runtime file** — daemon reads this; `keypop` mutations auto-export here |
| `private/snippets.json` | Optional workspace mirror for review, diff, or agent context |

Refresh the mirror:

```sh
mkdir -p private
keypop export --output private/snippets.json
keypop export --prefix ';ac' --output private/kits/acme-team.snippets.json
```

### Create a personal user guide

When the user asks to set up personal docs or team conventions:

1. `mkdir -p private`
2. If `private/user-guide.md` is missing, create it from the outline below (adapt to their org/prefixes).
3. Point them at `docs/user-guide.md` for public setup steps; keep team-specific rules in `private/`.

**Suggested outline for `private/user-guide.md`:**

```markdown
# Text Replacements: Personal User Guide

> Gitignored at private/user-guide.md. Public guide: docs/user-guide.md.

## Who this is for
## Shortcut conventions (prefix zones, naming patterns)
## Org/team patterns (e.g. ;ac, ;wl)
## Prompt shortcuts (;p…)
## Kits we maintain (paths under private/kits/ or kits/)
## Import/export workflows
## App compatibility notes (which apps need keypop run)
## Troubleshooting (team-specific)
```

Fill in their actual prefix zones, example shortcuts, and kit paths. Do not commit `private/` — it stays local.

## Key paths

| Path | Purpose |
|------|---------|
| `~/.config/keypop/snippets.json` | live runtime snippets (installed app / daemon) |
| `~/.local/KeyPop.app` | app bundle (TCC target) |
| `kits/` | shareable snippet kits (repo) |
| `private/` | gitignored personal guide, mirrors, backups, private kits |
| `private/backups/` | pre-apply import backups |
