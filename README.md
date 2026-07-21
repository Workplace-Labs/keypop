# keypop

Your favorite prompts, one keystroke away — on Mac and iPhone.

You type `;pproof` and it expands to:

> Proofread the following text for spelling and grammar, improving clarity and tone:

> [!TIP]
> Shortcuts start with `;` so they don't fire by accident mid-word (`;pproof`, not `proof`). The `p` is a prefix: `;p` is our recommended zone for your own favorite prompts, so they're easy to spot and separate from kits you import. Pick your own prefixes and stick with them — see [Conventions](docs/user-guide.md#conventions).

Works in Notes, Mail, Slack. Works on your iPhone. No extra app required.

Here's the thing — this is already built into macOS and iOS. System Settings → Keyboard → Text Replacements. Apple has had it for years and it syncs over iCloud automatically.

Three problems though:

1. **The UI is painful.** One entry at a time, no search, no bulk import. Managing a library of prompts in System Settings is miserable.
2. **It doesn't work everywhere.** Warp, VS Code, Cursor, and most terminals bypass Apple's text replacement entirely.
3. **No way to share.** Apple gives you no way to import or export kits to share with teammates.

KeyPop fixes all three.

## Use it with your AI assistant

Already using Cursor, Claude, or another AI tool to craft your prompts? Install the KeyPop agent skill and just ask your assistant to add, update, or import snippets for you.

**Cursor:** Copy `.agents/skills/keypop/` into your project's `.agents/skills/` folder. Your agent picks it up automatically.

That's it. Ask things like:

- "Add a snippet `;pfix` that says 'Explain what is wrong and suggest a fix:'"
- "Show me all my prompt shortcuts"
- "Create a kit from my current prompts that start with ';lab'"

## How it works

**`keypop` (CLI / agent skill)** manages your Apple Text Replacements library — import a kit, CRUD individual shortcuts, export to share. Everything syncs to iOS via iCloud automatically.

**`keypop run`** is a background daemon that catches the apps Apple misses — Warp, VS Code, Cursor, and terminals.

**Kits** are plain JSON files you can version, share, and import in one command.

```
kits/*.snippets.json  ──keypop import──►  Apple Text Replacements (iOS + native apps)
                              │
                              └──auto-export──►  ~/.config/keypop/snippets.json
                                                        │
                                                   keypop run (Warp, editors, terminals)
```

## Requirements

- macOS 14+ (validated on macOS 26, Apple Silicon)
- **Xcode Command Line Tools** — not the full Xcode app. Install with `xcode-select --install` (no App Store sign-in, ~1-2GB vs. Xcode's 10GB+). Provides the `swift` toolchain, `clang`, and `codesign` that the build and install scripts need.
- Uses private `KeyboardServices` APIs — not Mac App Store safe
- `keypop run` requires **Input Monitoring** + **Accessibility** permissions

## Install

Pick the install path based on how you want to use KeyPop:

| If you want to... | Install |
| --- | --- |
| Manage snippets from Terminal, scripts, Raycast, or another launcher | CLI only |
| Expand shortcuts as you type in Warp, editors, terminals, and other apps | Full setup |

**CLI-only bootstrap (`install.sh`)** — installs the `keypop` command, with no background app and no permission grants:

```sh
curl -fsSL https://raw.githubusercontent.com/Workplace-Labs/keypop/main/install.sh | sh
```

Builds from source and installs the `keypop` CLI to `~/.local/bin`. This is the right path if you want to call KeyPop from shell scripts, Raycast, Shortcuts, or your own tools. It skips `~/Applications/KeyPop.app` and the LaunchAgent, so `keypop run` does not start expanding text in other apps.

Not a fan of `curl | sh`? Read [`install.sh`](install.sh) first, then run it locally.

**Full macOS setup (`scripts/install-full.sh`)** — installs the CLI plus the system-wide expander:

```sh
git clone git@github.com:Workplace-Labs/keypop.git
cd keypop
./scripts/install-full.sh
```

Installs the `keypop` CLI to `~/.local/bin`, bundles `~/Applications/KeyPop.app`, and registers a LaunchAgent.

**Security note:** KeyPop requires Accessibility and Input Monitoring permissions — sensitive grants that can read everything you type. This is true of any text expander. Before granting permissions, it is good practice to have your AI assistant review the source for anything unexpected. Ask it: "Review this repo for security issues before I grant Accessibility and Input Monitoring permissions."

## Quick start

```sh
keypop inspect
keypop import kits/prompts-core.snippets.json --apply

# Optional: add the Workplace Labs prompt kit or, for something fun, the Lab Rats kit
keypop import kits/workplace-labs-top5.snippets.json --apply
keypop import kits/lab-rats.snippets.json --apply

# One-time: stable code signing so TCC grants survive rebuilds
./scripts/create-keypop-signing-cert.sh
./scripts/install-full.sh

# Grant TCC permissions to ~/Applications/KeyPop.app, then:
./scripts/launch-keypop.sh restart
```

Type `;pproof` in Warp to verify. See [User Guide](docs/user-guide.md) for full setup and permissions.

If expansion ever gets weird, run `./scripts/launch-keypop.sh debug`, reproduce once, then run `./scripts/launch-keypop.sh diagnostics`. The report is metadata-only and auto-expires after 30 minutes.

## CLI examples

```sh
# Add a snippet
keypop create --shortcut ';labe' --phrase 'you@example.com'

# Update a prompt in place
keypop update --shortcut ';pcr' --phrase 'Review this diff for bugs and suggest fixes.'

# Browse your library
keypop list
keypop list --prefix ';p'

# Export a shareable team kit
keypop export --prefix ';lab' --output kits/lab-rats.snippets.json
```

## Available kits

New to prompt kits? Start with **one** kit, not all of them. The full kit guide is in [Kits](docs/kits.md).

| Kit | Prefix | Start here when you want... |
|-----|--------|---------------------------|
| `kits/prompts-core.snippets.json` | `;p` | Everyday writing and summary prompts |
| `kits/workplace-labs-top5.snippets.json` | `;wl` | Workplace Labs' highest-use prompts |
| `kits/workplace-labs-thinking.snippets.json` | `;wl` | Structured thinking and decision prompts |
| `kits/workplace-labs-hr.snippets.json` | `;wl` | HR and people-ops prompts |
| `kits/workplace-labs-dev.snippets.json` | `;wl` | Developer workflow prompts |
| `kits/lab-rats.snippets.json` | `;lab` | Workplace Labs adoption prompts |
| `kits/karpathy-agentic-coding.snippets.json` | `;ak` | Agentic engineering prompts |
| `kits/caveman-prompting.snippets.json` | `;cm` | Shorter assistant output |
| `kits/compound-engineering.snippets.json` | `;ce` | Product-engineering loops |
| `kits/claude-command-patterns.snippets.json` | `;cc` | Memorable prompt patterns without the fake hidden-command mythology |

`;wl` and `;lab` are just Workplace Labs' own prefixes for the kits it publishes — pick whatever prefix makes sense when you build and share your own.

Import any kit:

```sh
keypop import kits/workplace-labs-top5.snippets.json --apply
```

## Documentation

- [User Guide](docs/user-guide.md)
- [Kits](docs/kits.md)
- [Architecture](docs/architecture.md) (contributors)

Research: [`docs/research/`](docs/research/)
