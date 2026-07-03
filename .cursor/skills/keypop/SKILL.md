---
name: keypop
description: >-
  Manage, use, and share AI prompts via keyboard shortcuts on Mac and iOS.
  Use when the user wants to save or update prompt shortcuts, import or export
  prompt kits (.snippets.json), share prompts with a team, expand prompts in
  Cursor, Warp, VS Code, or terminals, or manage general text replacements
  (email signatures, contact info, boilerplate). Also covers the keypop daemon
  and expansion troubleshooting.
metadata:
  version: "1.1"
  project: keypop
  repo: https://github.com/Workplace-Labs/keypop
---

# keypop — AI Prompts & Text Replacements

> This file is canonical. `.agents/skills/keypop/SKILL.md` and
> `wl-agent-toolkit/skills/keypop/SKILL.md` are generated copies (real
> files, not symlinks, so raw GitHub fetches and Windows checkouts still
> resolve correctly) — edit this file, then run
> `./scripts/sync-keypop-skill.sh` (or just commit; the pre-commit hook
> does it for you, see AGENTS.md).

## What KeyPop is for

**Primary:** turn reusable AI prompts into shortcuts you can type anywhere.

- **Manage** — create, update, organize, and prune prompt shortcuts
- **Use** — type `;pproof` (or any keyword) and get the full prompt pasted in Cursor, Warp, VS Code, Terminal, Notes, Mail, Slack, and more
- **Share** — ship prompts as versioned **kits** (`.snippets.json`) your team can import

**Also great for:** email signatures, contact info, follow-up boilerplate, and other text you paste often. Same mechanism, same shortcuts.

Canonical repo: [Workplace-Labs/keypop](https://github.com/Workplace-Labs/keypop). After install, `keypop` is at `~/.local/bin/keypop` and KeyPop.app at `~/Applications/KeyPop.app`.

**macOS only** for the Mac expander. Prompt shortcuts sync to **iOS** via Apple Text Replacements. Requires **Xcode Command Line Tools** (`xcode-select --install` — not the full Xcode app) and Input Monitoring + Accessibility TCC grants to the app bundle.

## Install

If `keypop` is not installed yet:

- **From this repo:** `./scripts/create-keypop-signing-cert.sh` once (stable local signing — skip this and `install.sh` falls back to ad-hoc signing, which breaks TCC grants on every rebuild), then `./scripts/install.sh`
- **From the wl-agent-toolkit**, without a local checkout: `scripts/keypop-install.sh` — clones (or updates) the repo, then runs both of the above in order automatically. Accepts `--repo <path>` / `$KEYPOP_REPO_PATH`, and `--yes` to skip the interactive TCC pause for scripted/agent runs.

Either path builds, signs, installs the LaunchAgent, and walks through the Input Monitoring + Accessibility TCC grants.

If `keypop` is already installed, use the daemon commands below rather than re-running an installer.

## How it works

Two layers, one keyword library:

| Layer | Command | Where prompts expand |
|-------|---------|----------------------|
| Apple Text Replacements | `keypop list/create/...` | iOS, Notes, Mail, Messages, Safari, Slack |
| Mac expander (daemon) | `keypop run` | Warp, VS Code, Cursor, Terminal |

Mutations auto-export to `~/.config/keypop/snippets.json`. The daemon watches that file (~200ms debounce) and reloads automatically.

**Kits** are the sharing format: JSON arrays of `{ "name", "keyword", "text" }` files (`.snippets.json`). Repo kits live in `kits/`; team or personal kits can live in `private/kits/`.

Shipped prompt kits (import with `--prefix` as needed):

| Kit | Prefix zone | Examples |
|-----|-------------|----------|
| `kits/prompts-core.snippets.json` | `;p` | `;pproof`, `;psum` |
| `kits/workplace-labs-top5.snippets.json` | `;wl` | `;wlask`, `;wlredteam`, `;wlx` |
| `kits/workplace-labs-thinking.snippets.json` | `;wl` | `;wlpremortem`, `;wloptions` |
| `kits/workplace-labs-dev.snippets.json` | `;wl` | dev-focused prompts |
| `kits/workplace-labs-hr.snippets.json` | `;wl` | HR/coaching prompts |

## Workflows

### Save a new prompt shortcut

1. **Gather:** `keypop get --shortcut ';pmyshort'` (skip if creating)
2. **Act:** `keypop create --shortcut ';pmyshort' --phrase 'Your full prompt text here…'`
3. **Verify:** `keypop get --shortcut ';pmyshort'` and confirm `~/.config/keypop/snippets.json` matches

Use a descriptive `name` when building kits; keep `text` clean and pasteable (no personality in the prompt body).

### Import a prompt kit

Always dry-run first:

```sh
keypop import kits/prompts-core.snippets.json --prefix ';p' --dry-run
keypop import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip
keypop import kits/workplace-labs-top5.snippets.json --prefix ';wl' --apply --on-conflict skip
```

### Share prompts with a team

Export a prefix zone to a kit file, commit it, or hand it to teammates:

```sh
keypop export --prefix ';wl' --output private/kits/wl-team.snippets.json
keypop export --prefix ';p' --output my-prompts.snippets.json
```

Teammates import with `keypop import <file> --apply --on-conflict skip`.

### Bottle a prompt from a conversation

When a chat produced a great reusable prompt, save it as a shortcut (or suggest `;wlx` / "Bottle That Prompt" if the user already has that kit). Match the structure of their existing prompts: lead with the instruction, keep placeholders like `[goal]` where the user fills in context.

### General text replacement

Same commands — signatures, contact info, boilerplate:

```sh
keypop create --shortcut ';mysig' --phrase 'Best,\nYour Name\n…'
keypop update --shortcut ';myemail' --phrase 'you@example.com'
```

### Re-sync runtime export

```sh
./scripts/sync-keypop.sh
```

### Find unused prompts

```sh
keypop stats --prefix ';p'    # usage counts from the Mac daemon
```

## Conventions

- **Semicolon prefix:** `;pproof` not `pproof` — avoids accidental expansion while typing
- **Prefix zones:** `;p` personal/general prompts, `;wl` Workplace Labs team prompts, `;my` contact/boilerplate — pick zones and stick to them
- **Plain text only:** no `{clipboard}`, `{date}`, or dynamic placeholders (iOS + Mac parity)
- **~2000 char limit:** long prompts are risky on iOS; keep prompt `text` focused
- **Prompt `text` stays pasteable:** playful names are fine (`"Bottle That Prompt"`); the expanded text should read like something you'd paste into any AI chat

## CLI reference

```sh
keypop list [--prefix <prefix>]
keypop get --shortcut <shortcut>
keypop export [--prefix <prefix>] [--output <path>]
keypop create --shortcut <shortcut> --phrase <phrase>
keypop update --shortcut <shortcut> --phrase <phrase>
keypop delete --shortcut <shortcut>
keypop import <path|-> [--prefix <prefix>] [--dry-run|--apply] [--on-conflict fail|skip|overwrite] [--no-sync]

keypop stats [--prefix <prefix>]
keypop stats reset [--shortcut <shortcut>|--all]

keypop run [--snippets ~/.config/keypop/snippets.json]

keypop probe permissions|listen|inject|bridge

keypop inspect
keypop read-sources
keypop db-summary
```

Disable runtime sync: `--no-sync` or `KEYPOP_SYNC=0`.

## Daemon

```sh
./scripts/launch-keypop.sh status
./scripts/launch-keypop.sh restart
./scripts/fix-keypop-tcc.sh          # rebuild + reset TCC + open System Settings
tail -f ~/.local/log/keypop.log      # listen_ready|tap_installed, expanded|…
```

**TCC:** Grant Input Monitoring + Accessibility to `~/Applications/KeyPop.app` (the `.app` bundle — not Terminal, not the bare `keypop` binary). Use **+** → **Cmd+Shift+G** in each pane.

**If expansion stops working:**
- Trust the **daemon log** over `keypop probe permissions` from Terminal — shell context can show `listen=false` while the LaunchAgent tap works.
- `listen_ready|tap_installed` = tap OK. `expanded|keyword|…` = match fired. `tap_reinstall_failed|…` = re-grant TCC (`fix-keypop-tcc.sh`) + restart.

**stderr signals:**
- `keypop_sync|<path>|<count>` — export succeeded
- `keypop_hint|daemon not running` — run `./scripts/launch-keypop.sh restart`

## Safety

- Never write directly to `~/Library/KeyboardServices/TextReplacements.db`
- Always `--dry-run` before `import --apply`

## Personal workspace (`private/`)

Gitignored folder in the keypop repo for machine-local prompt kits, mirrors, and team conventions.

```
private/
  user-guide.md     # personal/team prompt zones and onboarding notes
  snippets.json     # optional mirror of all shortcuts
  backups/          # import --apply backups (auto-created)
  kits/             # personal or team prompt kits (*.snippets.json)
```

**Where snippets actually live**

| Path | Role |
|------|------|
| `~/.config/keypop/snippets.json` | **Canonical runtime file** — daemon reads this; `keypop` mutations auto-export here |
| `private/snippets.json` | Optional workspace mirror for review, diff, or agent context |
| `kits/` | Shareable prompt kits in the repo |

Refresh the mirror:

```sh
mkdir -p private
keypop export --output private/snippets.json
keypop export --prefix ';wl' --output private/kits/wl-team.snippets.json
```

### Create a personal prompt guide

When the user asks to set up personal docs or team prompt conventions:

1. `mkdir -p private`
2. If `private/user-guide.md` is missing, create it from the outline below (adapt to their org/prefixes).
3. Point them at `docs/user-guide.md` for public setup steps; keep team-specific prompt zones in `private/`.

**Suggested outline for `private/user-guide.md`:**

```markdown
# AI Prompts: Personal User Guide

> Gitignored at private/user-guide.md. Public guide: docs/user-guide.md.

## Who this is for
## Prompt zones (prefix conventions: ;p, ;wl, ;my, …)
## Favorite prompt shortcuts
## Kits we maintain (paths under private/kits/ or kits/)
## Import/export workflows
## Which apps need the keypop daemon vs native Apple expansion
## Troubleshooting (team-specific)
```

Fill in their actual prefix zones, example shortcuts, and kit paths. Do not commit `private/` — it stays local.

## Key paths

| Path | Purpose |
|------|---------|
| `~/.config/keypop/snippets.json` | live runtime snippets (installed app / daemon) |
| `~/Applications/KeyPop.app` | app bundle (TCC target) |
| `kits/` | shareable prompt kits (in keypop repo) |
| `private/` | gitignored personal guide, mirrors, backups, private kits |
| `private/backups/` | pre-apply import backups |
