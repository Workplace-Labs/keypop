---
name: keypop
description: >-
  Manage, use, and share AI prompts via keyboard shortcuts on Mac and iOS.
  Use when the user wants to save or update prompt shortcuts, import or export
  prompt kits (.snippets.json), share prompts with a team, expand prompts in
  Cursor, Warp, VS Code, or terminals, or manage general text replacements
  (email signatures, contact info, boilerplate). After a fresh install, guide
  the user through conversational post-install onboarding. Also covers the
  keypop daemon and expansion troubleshooting.
metadata:
  version: "1.2"
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

**Just finished installing?** Start [Post-install onboarding](#post-install-onboarding) — do not dump the whole guide at once.

## Post-install onboarding

**When to run:** install just completed (`install.sh`, `keypop-install.sh`), user says they're new, or they ask how to get started.

**How to guide (agents):**
- **One step at a time.** Present a single step, then stop and wait for the user to try it (or say they're stuck / ready for the next one).
- **Conversational and warm.** Short sentences. Celebrate small wins. A little personality is good — you're a friendly lab mate, not a manual.
- **Adapt.** Skip steps they've already done. If expansion fails at step 3, troubleshoot before advancing (daemon status, TCC, log lines — see Daemon section).
- **Five steps, then graduate.** Walk through all five below. On completion, deliver the graduation message and invite them to ask for more tips anytime.
- **Deeper reference:** `docs/user-guide.md` for conventions, team sharing, and troubleshooting.

### Step 1 — Make sure the lab is open

**Goal:** confirm the CLI and daemon are alive before we load prompts.

**Say something like:**
> KeyPop's installed — nice. First thing: let's make sure the background expander is actually running. Can you run this and tell me what you get?
>
> `./scripts/launch-keypop.sh status`
>
> You want to see **running** and a path to `~/Applications/KeyPop.app`. If it's not running, `./scripts/launch-keypop.sh restart` usually fixes it.

**Optional if curious:** `keypop inspect` — confirms the CLI can talk to Apple's Text Replacements layer.

**Done when:** status shows running (or user restarted and it does).

---

### Step 2 — Load your first prompt kit

**Goal:** import the starter prompts so there's something to expand.

**Say something like:**
> Time to stock the shelves. This imports a handful of useful prompts (`;pproof`, `;psum`, plus contact boilerplate like `;myemail`):
>
> `keypop import kits/prompts-core.snippets.json --apply --on-conflict skip`
>
> Run that, then `keypop list --prefix ';p'` — you should see your new `;p` prompts. (Contact shortcuts like `;myemail` land too; we'll personalize those in a minute.)

**Done when:** import succeeds and `keypop list --prefix ';p'` shows shortcuts.

---

### Step 3 — The magic moment

**Goal:** feel expansion work in a real app.

**Say something like:**
> This is the fun part. Open **Cursor**, **Warp**, or **VS Code** — somewhere you actually chat with AI — click into a text field, and type:
>
> `;pproof`
>
> …then keep typing or hit space. The full proofread prompt should appear like you pasted it. Did it work?

**If no:** check `./scripts/launch-keypop.sh status`, then `tail -5 ~/.local/log/keypop.log` for `listen_ready|tap_installed`. Missing? TCC grants to `~/Applications/KeyPop.app` — both Input Monitoring and Accessibility. `./scripts/fix-keypop-tcc.sh` is the nuclear option.

**Bonus:** try the same shortcut in **Notes** — that's Apple's layer (syncs to iPhone via iCloud). Warp/Cursor need the KeyPop daemon; Notes doesn't.

**Done when:** `;pproof` expands in at least one app.

---

### Step 4 — Make one shortcut yours

**Goal:** personalize a placeholder or save a prompt they'll actually use.

**Say something like:**
> You've got the kit — now make it yours. Pick one:
>
> **A)** Swap the placeholder email: `keypop update --shortcut ';myemail' --phrase 'you@yourdomain.com'`
>
> **B)** Save a prompt you reach for often: `keypop create --shortcut ';pmy' --phrase 'Your go-to prompt here…'`
>
> Which one sounds useful? Run it, then try typing your shortcut in an app.

**Tip:** shortcuts start with `;` so you don't accidentally fire them mid-word (`;pproof` good, `proof` risky).

**Done when:** they've updated or created one shortcut and confirmed it expands.

---

### Step 5 — Meet the team prompts (or bottle your first)

**Goal:** show kits scale beyond the starter set — import WL favorites or save from the current chat.

**Say something like:**
> Last step — the good stuff. Workplace Labs ships a "top 5" prompt kit. Import it:
>
> `keypop import kits/workplace-labs-top5.snippets.json --apply --on-conflict skip`
>
> Then try `;wlask` in a chat — it tells the AI to interview you before answering. Or `;wlredteam` to stress-test an idea.
>
> **Or**, if something in *this* conversation already worked well: let's bottle it. Give me the prompt text and a shortcut name (like `;pstandup`) and I'll help you save it — that's the `;wlx` energy without the middleman.

**Done when:** they've imported the WL kit and tried one `;wl` shortcut, **or** saved a custom prompt from the session.

---

### Graduation

**Say something like (after all 5 steps):**
> You did it — five for five. You imported kits, fired a prompt in Cursor/Warp, made a shortcut yours, and leveled up with team prompts. That's the whole loop: **manage, use, share.**
>
> Your prompts also sync to iPhone/iPad through Apple Text Replacements (System Settings → Keyboard → Text Replacements) — same keywords, no extra app on iOS.
>
> Whenever you want more — prefix zones, sharing kits with teammates, troubleshooting, or bottling prompts from a great chat — just ask. Happy expanding. 🧪

**Do not** re-run onboarding unless they ask to start over.

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
