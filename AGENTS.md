# Agent Context (keypop)

Swift package for Apple Text Replacements management and Mac system-wide expansion.

## Voice and tone

KeyPop is a practical tool with a little personality. When writing prose (README, changelog, docs):

- **Direct and conversational** — write like you're telling a friend, not filing a spec. "Three problems though:" not "The following problems have been identified."
- **"KeyPop" in prose, `keypop` in code** — the product is KeyPop, the binary is `keypop`.
- **Short > long** — cut filler, don't hedge. Favor punchy sentences. Earn every word.
- **Personality lives in names and framing, not in prompt text** — snippet `name` fields can be playful ("Bottle That Prompt", "No Sugarcoat", "Monday Morning Cheese"), prompt `text` stays clean and pasteable.
- **One tasteful reference, not a theme park** — a single lab-rat metaphor or a "wait, what was that shortcut again?" line lands. Repeating the bit kills it.
- **Behavioral science and people-first framing** — KeyPop is a Workplace Labs project. Prompts that ship with it reflect that: interviewing before drafting, stress-testing assumptions, coaching over just producing output.
- **Honest about the weird stuff** — KeyPop uses private APIs and needs sensitive permissions. Say so plainly and suggest a security check before users grant them. This builds trust; burying it loses it.

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

Scripts: `install.sh`, `bundle-keypop-app.sh`, `launch-keypop.sh`, `sync-keypop.sh`, `fix-keypop-tcc.sh`, `generate-app-icon.sh`, `keypop-paths.sh`, `sync-keypop-skill.sh`

**Install layout:** CLI → `~/.local/bin/keypop`. App bundle → `~/Applications/KeyPop.app`. Override app path: `KEYPOP_APP=... ./scripts/install.sh`.

**TCC:** LaunchAgent runs `~/Applications/KeyPop.app/Contents/MacOS/keypop run`. Grant **Input Monitoring** + **Accessibility** to **`~/Applications/KeyPop.app`**, not Terminal or Cursor. Both panes need the `.app` bundle (use **+** → **Cmd+Shift+G**). Sign with `./scripts/create-keypop-signing-cert.sh` once (`KeyPop Dev` self-signed cert — not client Apple Dev accounts). Re-grant after rebuilds that change the signature.

**TCC troubleshooting (agents):**
- `./scripts/fix-keypop-tcc.sh` — full rebuild, reset TCC, open System Settings. Use when grants go stale or after moving the app bundle.
- Trust the **daemon log** over `keypop probe permissions` from Terminal for Input Monitoring — Terminal context can show `listen=false` while the LaunchAgent daemon has a working tap.
- Log lines: `listen_ready|tap_installed` (tap OK), `expanded|keyword|…` (match fired), `tap_reinstall_failed|…` (re-grant TCC + restart).
- Kill zombie daemons: `pkill -f "keypop run --snippets"` then `./scripts/launch-keypop.sh restart`. Stale processes from legacy `~/.local/KeyPop.app` block expansion even when new grants look correct.
- Remove old TCC entries (black `keypop` exec, legacy `~/.local/KeyPop.app`, accidental Terminal/Cursor grants) before re-adding `~/Applications/KeyPop.app`.

**Icon:** Source SVG `assets/icons/keypop-icon-orbit-tilt.svg` → `./scripts/generate-app-icon.sh` → `assets/AppIcon.icns` (bundled on install).

`keypop` prints `keypop_hint|` on stderr when sync succeeds but the daemon is not running.

## Skill docs

`.cursor/skills/keypop/SKILL.md` is canonical. `.agents/skills/keypop/SKILL.md` and `wl-agent-toolkit/skills/keypop/SKILL.md` (sibling repo) are generated copies — never edit them directly. Kept as real files rather than symlinks: symlinks don't resolve over raw GitHub fetches (`raw.githubusercontent.com`, the Contents API), zip downloads, or Windows checkouts without symlink support enabled.

One-time setup: `git config core.hooksPath scripts/hooks` — the pre-commit hook runs `scripts/sync-keypop-skill.sh` automatically when the canonical file changes and stages the in-repo copy. The toolkit copy is updated on disk but lives in a separate repo, so commit it there yourself.

## Validation

Requires Xcode Command Line Tools (`xcode-select --install`) — not the full Xcode app. `install.sh` fails fast with that instruction if `swift` is missing.

```sh
swift build && swift test
./scripts/install.sh
./scripts/launch-keypop.sh status
keypop inspect
scripts/validate-crud.sh
```

## Safety

- Never write directly to `~/Library/KeyboardServices/TextReplacements.db`
- `import --apply` must write backups under `private/backups/` first
- `private/` is gitignored — personal user guide, snippet mirrors, import backups
- Not Mac App Store safe
