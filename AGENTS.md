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

Scripts: `install.sh`, `bundle-keypop-app.sh`, `launch-keypop.sh`, `sync-keypop.sh`, `probes/run-sprint0.sh`

**TCC:** LaunchAgent runs `~/.local/KeyPop.app/Contents/MacOS/keypop run`. Grant **Input Monitoring** + **Accessibility** to **`~/.local/KeyPop.app`**, not Terminal. Re-grant after `install.sh` rebuilds the bundle. Sign with `./scripts/create-keypop-signing-cert.sh` (`KeyPop Dev` self-signed cert — not client Apple Dev accounts).

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
- `import --apply` must write backups under `private/backups/` first
- `private/` is gitignored — personal user guide, snippet mirrors, import backups
- Not Mac App Store safe
