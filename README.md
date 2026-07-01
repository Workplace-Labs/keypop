# keypop

Imagine your favorite prompts available everywhere — Mac and iPhone — one short keystroke away.

You type `;psuper` and it expands to:

> I am a `{{ your role }}` and I am working on `{{ goal or problem }}`. What persona should you assume to help me? Assume this persona and start by asking me questions.

Works in Notes, Mail, Slack. Works on your iPhone. **No extra app required.**

Here's the thing: this is already built into macOS and iOS. System Settings → Keyboard → Text Replacements. Apple has had it for years. It syncs over iCloud to every device on your account automatically.

The problem is two-fold:

1. **The built-in UI is painful.** One entry at a time, no search, no bulk import. Managing a library of prompts in System Settings is miserable.
2. **It doesn't work everywhere.** Warp, VS Code, Cursor, and most terminals have custom input handling that bypasses native text replacement.

keypop fixes both.

## The solution

**Problem 1 — management:** `keypop` is a CLI that reads and writes Apple Text Replacements directly. Import a whole prompt kit in one command. CRUD individual snippets. Export to share with teammates. Everything stays in sync with iOS automatically.

**Problem 2 — app coverage:** `keypop run` is a background daemon that listens for your shortcuts and injects expansions at the OS level, reaching Warp, VS Code, Cursor, and any terminal that Apple's layer misses.

Same shortcuts. Same library. Works everywhere.

```
kits/*.snippets.json  ──keypop import──►  Apple Text Replacements (iOS + native apps)
                              │
                              └──auto-export──►  ~/.config/keypop/snippets.json
                                                        │
                                                   keypop run (Warp, editors, terminals)
```

| Command | Role |
|---------|------|
| `keypop` (CRUD) | Manage your library — syncs to iOS via iCloud |
| `keypop run` | Mac daemon — covers Warp, VS Code, Cursor, terminals |
| `keypop probe` | Diagnostics for TCC permissions and injection |

## Requirements

- macOS 14+ (validated on macOS 26, Apple Silicon)
- Swift toolchain
- Uses private `KeyboardServices` APIs — not Mac App Store safe
- `keypop run` requires **Input Monitoring** + **Accessibility** granted to **`~/.local/KeyPop.app`** (not Terminal)

## Install

```sh
git clone git@github.com:Workplace-Labs/keypop.git
cd keypop
./scripts/install.sh
```

Installs `keypop` to `~/.local/bin`, bundles `~/.local/KeyPop.app`, and registers a LaunchAgent.

## Quick start

```sh
keypop inspect                                                          # verify setup
keypop import kits/prompts-core.snippets.json --prefix ';p' --dry-run  # preview the starter kit
keypop import kits/prompts-core.snippets.json --prefix ';p' --apply    # import it

# Grant TCC permissions to ~/.local/KeyPop.app, then:
./scripts/launch-keypop.sh restart
```

Type `;pcr` in Warp to verify. See [User Guide](docs/user-guide.md) for full setup and permissions.

## CLI examples

```sh
# Add a snippet
keypop create --shortcut ';wle' --phrase 'you@example.com'

# Update a prompt in place
keypop update --shortcut ';pcr' --phrase 'Review this diff for bugs and suggest fixes.'

# Browse your library
keypop list
keypop list --prefix ';p'

# Export a shareable team kit
keypop export --prefix ';wl' --output kits/wl-team.snippets.json
```

## Documentation

- [User Guide](docs/user-guide.md)
- [Kits](docs/kits.md)
- [Architecture](docs/architecture.md) (contributors)

Research (spikes, expander landscape, private API notes): [`docs/research/`](docs/research/)
