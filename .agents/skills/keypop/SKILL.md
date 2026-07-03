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
  version: "1.4"
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
- **Use** — type `;pproof` (or any keyword) and get the full prompt pasted in your AI chat app, Notes, Mail, Slack, Cursor, Warp, VS Code, Terminal, and more
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
- **You handle the CLI.** Run status checks, imports, and shortcut creation yourself in the background — don't hand the user terminal commands to type. They should never see a command unless it's genuinely theirs to run (there isn't one in this flow).
- **The user does the human parts.** Typing a shortcut into an app, clicking two permission toggles once, telling you a phrase they say all the time. That's the whole ask.
- **One step at a time.** Wait for a real signal (they saw it expand, they told you the phrase, they reacted) before moving on.
- **Warm, short, a little personality.** Guide a friend through a good party trick, not a manual.
- **Adapt.** If a kit's already imported or permissions already granted, skip straight ahead.
- **Deeper reference:** `docs/user-guide.md` for conventions, team sharing, and troubleshooting.

### Step 1 — Watch it work

**You do first, silently:** confirm the daemon is running and import `kits/prompts-core.snippets.json` (`--apply --on-conflict skip`). If the daemon isn't running or permissions look missing, go to Step 2 first instead of saying anything yet.

**Then say something like:**
> You're set up. Open whatever AI chat app you use most — ChatGPT, Claude, Cursor, Warp, anywhere you paste prompts — click into the message box, and type `;pproof` then hit space.

**Done when:** the full prompt appears out of nowhere. That's the entire pitch in one keystroke — an AI prompt library at your fingertips, everywhere you type.

**If nothing happened:** almost always permissions — go to Step 2.

---

### Step 2 — The one-time permission click (only if needed)

**Skip this step entirely if Step 1 already worked.**

**You do:** open the two System Settings panes for them (Input Monitoring, Accessibility).

**Say something like:**
> One-time thing — I've opened System Settings. Add **KeyPop** to both **Input Monitoring** and **Accessibility**: click **+**, press **Cmd+Shift+G**, paste `~/Applications/KeyPop.app`, hit Open. Same permission category as any snippet or clipboard tool — KeyPop just needs to see when you type a shortcut.

**You do after they confirm:** restart the daemon, verify the tap is live.

**Done when:** back to Step 1 — `;pproof` expands.

---

### Step 3 — Make one shortcut yours

**Say something like:**
> Now the good part. What's a prompt you use all the time — or something else you type often, like your email sign-off or a LinkedIn link?
>
> Quick convention: we recommend starting your own favorite prompts with `;p` (that's what `;pproof` was) — keeps them easy to spot and separate from prompt kits you import later.

**You do:** take whatever they say and save it as a shortcut — `;p` + a short name for a personal prompt, something sensible for anything else. Confirm the wording with them if it's ambiguous, otherwise just create it.

**Then say something like:**
> Done — go type `;whatever` and watch it fill in.

**Done when:** they've seen their own shortcut expand.

---

### Step 4 — Borrow the team's best prompts

**You do:** import `kits/workplace-labs-top5.snippets.json` (`--apply --on-conflict skip`).

**Say something like:**
> Here's where it gets genuinely useful. Workplace Labs publishes a shared prompt kit under `;wl` — that's just their naming; any team can brand a kit the same way. Next time you start a chat with AI, try `;wlask` — it makes the AI interview you before answering instead of guessing. Or `;wlredteam` when you want your idea stress-tested instead of just agreed with.
>
> These are prompts other people already refined. You get them for free, and they update if the team improves them.

**Done when:** they've tried one `;wl` prompt or clearly get why it's useful.

---

### Step 5 — Pass it on

**Say something like:**
> Last one. Prompts are only as good as how easily you can hand them to someone else. If a teammate should have your shortcuts, I can package them into a file they import in one command — or if something from *this* conversation was worth keeping, tell me and I'll turn it into a shortcut right now.

**You do:** whichever they pick — export a prefix to a kit file, or create a shortcut from something in the conversation.

**Done when:** they've exported a kit, saved something from the chat, or clearly see the idea.

---

### Graduation

**Say something like:**
> Five for five. You watched a prompt appear out of thin air, made one your own, borrowed sharper ones from the team, and packaged something up to share. That's the whole loop: **use it, make it yours, pass it on.**
>
> Bonus: it all works on your iPhone too, through Text Replacements — no extra app needed there.
>
> Ping me anytime for more — new prompt ideas, cleaning out old shortcuts, whatever. Happy expanding. 🧪

**Do not** re-run onboarding unless they ask to start over.

## How it works

Two layers, one keyword library:

| Layer | Command | Where prompts expand |
|-------|---------|----------------------|
| Apple Text Replacements | `keypop list/create/...` | iOS, Notes, Mail, Messages, Safari, Slack |
| Mac expander (daemon) | `keypop run` | Warp, VS Code, Cursor, Terminal |

Mutations auto-export to `~/.config/keypop/snippets.json`. The daemon watches that file (~200ms debounce) and reloads automatically.

**Kits** are the sharing format: JSON arrays of `{ "name", "keyword", "text" }` files (`.snippets.json`). Repo kits live in `kits/`; team or personal kits can live in `private/kits/`.

Shipped prompt kits (import with `--prefix` as needed). `;p` is the recommended convention for personal favorite prompts; `;wl` is Workplace Labs' own branded kit prefix — an example of how any team can package and prefix their prompts:

| Kit | Prefix zone | Examples |
|-----|-------------|----------|
| `kits/prompts-core.snippets.json` | `;p` | `;pproof`, `;psum` |
| `kits/workplace-labs-top5.snippets.json` | `;wl` (Workplace Labs example) | `;wlask`, `;wlredteam`, `;wlx` |
| `kits/workplace-labs-thinking.snippets.json` | `;wl` (Workplace Labs example) | `;wlpremortem`, `;wloptions` |
| `kits/workplace-labs-dev.snippets.json` | `;wl` (Workplace Labs example) | dev-focused prompts |
| `kits/workplace-labs-hr.snippets.json` | `;wl` (Workplace Labs example) | HR/coaching prompts |

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
- **Prefix zones:** we recommend `;p` for your own favorite prompts and `;my` for contact/boilerplate. `;wl` is Workplace Labs' example shared kit — any team can brand a kit the same way with its own prefix. Pick zones and stick to them
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
