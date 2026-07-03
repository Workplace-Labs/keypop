---
name: keypop
description: >-
  Manage, use, and share AI prompts via keyboard shortcuts on Mac and iOS.
  Use when the user wants to save or update prompt shortcuts, import or export
  prompt kits (.snippets.json), share prompts with a team, expand prompts in
  Cursor, Warp, VS Code, or terminals, or manage general text replacements
  (email signatures, contact info, boilerplate). Always mutate shortcuts via
  keypop CLI (create/update/delete/import) — never edit snippets.json directly.
  After a fresh install, guide the user through conversational post-install
  onboarding. Also covers the keypop daemon and expansion troubleshooting.
metadata:
  version: "1.7"
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

## For agents — CLI only, never edit JSON

**All shortcut changes go through `keypop` CLI commands.** Do not open, read-and-patch, or write `~/.config/keypop/snippets.json`. Do not hand-edit kit files to update the user's live library.

| Goal | Do this | Never do this |
|------|---------|---------------|
| Add a shortcut | `keypop create --shortcut '…' --phrase '…'` | Edit `snippets.json` |
| Change prompt text | `keypop update --shortcut '…' --phrase '…'` | Edit `snippets.json` |
| Remove a shortcut | `keypop delete --shortcut '…'` | Edit `snippets.json` |
| See what's installed | `keypop list` or `keypop get --shortcut '…'` | Read JSON to plan a manual edit |
| Add many from a kit | `keypop import <kit> --apply` | Merge kit JSON into `snippets.json` |

`snippets.json` is **CLI-managed output** — `create`/`update`/`delete`/`import` write it and sync to Apple Text Replacements. Hand-edits skip that sync, can race with the daemon's file watcher, and break iOS parity.

Kit files in `kits/` are import **sources** — still run `keypop import`, not a direct copy into `snippets.json`.

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
- **You handle the CLI.** Run `keypop create`/`update`/`delete`/`import`/`list` yourself in the background — never edit `snippets.json` or kit files on disk. Don't hand the user terminal commands to type unless it's genuinely theirs to run.
- **The user does the human parts.** Typing a shortcut into an app, clicking two permission toggles once, telling you a phrase they say all the time. That's the whole ask.
- **One step at a time.** Wait for a real signal (they saw it expand, they told you the phrase, they reacted) before moving on.
- **Warm, short, a little personality.** Guide a friend through a good party trick, not a manual.
- **Adapt.** If a kit's already imported or permissions already granted, skip straight ahead.
- **Deeper reference:** `docs/user-guide.md` for conventions, team sharing, and troubleshooting.

### Step 1 — Watch it work

**You do first, silently:** confirm the daemon is running and import `kits/prompts-core.snippets.json` (`--apply --on-conflict skip`). If the daemon isn't running or permissions look missing, go to Step 2 first instead of saying anything yet.

**Then say something like:**
> I just loaded your starter kit — prompts-core, with proofread, summarize, and a few contact shortcuts — so you've got something to try right away.
>
> Open whatever AI chat app you use most — ChatGPT, Claude, Cursor, Warp, anywhere you paste prompts — click into the message box, and type `;pproof` then hit space.

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
> I just added Workplace Labs' shared prompt kit — five prompts under `;wl` that people reach for most. That's just their naming; any team can brand a kit the same way.
>
> Next time you start a chat with AI, try `;wlask` — it makes the AI interview you before answering instead of guessing. Or `;wlredteam` when you want your idea stress-tested instead of just agreed with.
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
> Five for five — seriously nice work. You watched a prompt appear out of thin air, made one your own, borrowed sharper ones from the team, and packaged something up to share. That's the whole loop: **use it, make it yours, pass it on.** You're basically a KeyPop power user already.
>
> Bonus: it all works on your iPhone too, through Text Replacements — no extra app needed there.

**Then ask what's next — offer real options, don't just trail off:**
> What sounds good next?
> - Another tip or trick
> - Explore other kits (there's a few more worth a look)
> - See everything in your library so far
> - Learn more about sharing kits with a team

**You do**, depending on their pick:
- **Another tip:** surface something from Conventions, Common commands, or a kit they haven't tried.
- **Explore other kits:** describe `workplace-labs-thinking`, `workplace-labs-dev`, `workplace-labs-hr`, and `lab-rats` from the Shipped prompt kits table above; import whichever sounds good.
- **See their library:** run `keypop list` and summarize it back to them.
- **Sharing kits:** walk through [Kits (import and export)](#kits-import-and-export).

**Do not** re-run the 5-step onboarding unless they ask to start over. Happy expanding. 🧪

## How it works

Two layers, one keyword library:

| Layer | Command | Where prompts expand |
|-------|---------|----------------------|
| Apple Text Replacements | `keypop list/create/...` | iOS, Notes, Mail, Messages, Safari, Slack |
| Mac expander (daemon) | `keypop run` | Warp, VS Code, Cursor, Terminal |

Mutations auto-export to `~/.config/keypop/snippets.json`. The daemon watches that file (~200ms debounce) and reloads automatically. Agents: that file is output — use CLI commands above, not the editor.

**Kits** are the sharing format: JSON arrays of `{ "name", "keyword", "text" }` files (`.snippets.json`). Repo kits live in `kits/`; team or personal kits can live in `private/kits/`.

Shipped prompt kits (import with `--prefix` as needed). `;p` is the recommended convention for personal favorite prompts; `;wl` is Workplace Labs' own branded kit prefix — an example of how any team can package and prefix their prompts:

| Kit | Prefix zone | Examples |
|-----|-------------|----------|
| `kits/prompts-core.snippets.json` | `;p` | `;pproof`, `;psum` |
| `kits/workplace-labs-top5.snippets.json` | `;wl` (Workplace Labs example) | `;wlask`, `;wlredteam`, `;wlx` |
| `kits/workplace-labs-thinking.snippets.json` | `;wl` (Workplace Labs example) | `;wlpremortem`, `;wloptions` |
| `kits/workplace-labs-dev.snippets.json` | `;wl` (Workplace Labs example) | dev-focused prompts |
| `kits/workplace-labs-hr.snippets.json` | `;wl` (Workplace Labs example) | HR/coaching prompts |

## Common commands

Run these in the shell. They update Apple Text Replacements and auto-export to `~/.config/keypop/snippets.json` (do not edit that file yourself).

### List shortcuts

```sh
keypop list                      # everything
keypop list --prefix ';p'        # personal prompt zone
keypop list --prefix ';wl'       # Workplace Labs kit zone
```

### Create a shortcut

```sh
keypop create --shortcut ';pproof' --phrase 'Proofread the following text for grammar and clarity:'
keypop create --shortcut ';psum' --phrase 'Summarize the following in 3 bullet points:'
keypop create --shortcut ';myemail' --phrase 'you@example.com'
keypop create --shortcut ';mysig' --phrase 'Best,\nYour Name'
```

Fails if the shortcut already exists — use `update` instead.

### Update a shortcut

```sh
keypop update --shortcut ';pproof' --phrase 'Improved proofread prompt text here…'
keypop update --shortcut ';myemail' --phrase 'newemail@example.com'
```

Changes the expanded text only; the shortcut keyword stays the same.

### Delete a shortcut

```sh
keypop delete --shortcut ';poldprompt'
```

### Look up one shortcut

```sh
keypop get --shortcut ';pproof'
```

## Kits (import and export)

**Import** — always dry-run first:

```sh
keypop import kits/prompts-core.snippets.json --prefix ';p' --dry-run
keypop import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip
keypop import kits/workplace-labs-top5.snippets.json --prefix ';wl' --apply --on-conflict skip
```

**Export** — share a prefix zone with teammates:

```sh
keypop export --prefix ';wl' --output wl-team.snippets.json
keypop export --prefix ';p' --output my-prompts.snippets.json
```

Teammates import with `keypop import <file> --apply --on-conflict skip`.

When a chat produced a great reusable prompt, save it with `create` (or suggest `;wlx` / "Bottle That Prompt" if they have that kit). Lead with the instruction; keep placeholders like `[goal]` where they fill in context.

## Conventions

- **Semicolon prefix:** `;pproof` not `pproof` — avoids accidental expansion while typing
- **Prefix zones:** we recommend `;p` for your own favorite prompts and `;my` for contact/boilerplate. `;wl` is Workplace Labs' example shared kit — any team can brand a kit the same way with its own prefix. Pick zones and stick to them
- **Plain text only:** no `{clipboard}`, `{date}`, or dynamic placeholders (iOS + Mac parity)
- **~2000 char limit:** long prompts are risky on iOS; keep prompt `text` focused
- **Prompt `text` stays pasteable:** playful names are fine (`"Bottle That Prompt"`); the expanded text should read like something you'd paste into any AI chat

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

- **Never edit `~/.config/keypop/snippets.json` directly** — use `keypop create`/`update`/`delete`/`import`
- Never write directly to `~/Library/KeyboardServices/TextReplacements.db`
- Always `--dry-run` before `import --apply`

## Key paths

| Path | Purpose |
|------|---------|
| `~/.config/keypop/snippets.json` | CLI-managed runtime export — `keypop list` to read; never edit directly |
| `~/Applications/KeyPop.app` | app bundle (TCC target) |
| `kits/` | shareable prompt kits in the repo |
| `private/` | gitignored local kits, mirrors, import backups |
| `docs/user-guide.md` | full reference for conventions, sharing, troubleshooting |
