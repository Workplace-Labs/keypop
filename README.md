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

```sh
git clone git@github.com:Workplace-Labs/keypop.git
cd keypop
./scripts/install.sh
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
./scripts/install.sh

# Grant TCC permissions to ~/Applications/KeyPop.app, then:
./scripts/launch-keypop.sh restart
```

Type `;pproof` in Warp to verify. See [User Guide](docs/user-guide.md) for full setup and permissions.

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

New to prompt kits? Start with **one** kit, not all of them:

- `prompts-core` for everyday writing and summary prompts
- `karpathy-agentic-coding` for production-minded agent coding: spec, eval, implement, review, verify
- `compound-engineering` for product-engineering work: strategy, options, plan, build, capture learning
- `caveman-prompting` for shorter assistant output while preserving exact task context

| Kit | Prefix | What's in it |
|-----|--------|-------------|
| `kits/prompts-core.snippets.json` | `;p` | Everyday prompts for proofreading, summarizing, contact info, and email drafts |
| `kits/workplace-labs-top5.snippets.json` | `;wl` | Workplace Labs' highest-use prompts for interviewing, red teaming, rewriting, and summarizing |
| `kits/workplace-labs-thinking.snippets.json` | `;wl` | Structured thinking prompts for premortems, tradeoffs, assumptions, options, and decisions |
| `kits/workplace-labs-hr.snippets.json` | `;wl` | People-ops prompts for retention, focus groups, manager coaching, and AI rollout risk |
| `kits/workplace-labs-dev.snippets.json` | `;wl` | Developer prompts for code review, TDD, explanation, debugging, feature starts, and security review |
| `kits/lab-rats.snippets.json` | `;lab` | Workplace Labs adoption prompts for coaching, rollout planning, stakeholder updates, and behavior change |
| `kits/karpathy-agentic-coding.snippets.json` | `;ak` | Agentic engineering prompts for specs, eval loops, implementation, steering, simplification, diff review, and verification |
| `kits/caveman-prompting.snippets.json` | `;cm` | Output-compression prompts for concise tasks, debugging, review, verification, handoff, and safe prompt shortening |
| `kits/compound-engineering.snippets.json` | `;ce` | Product-engineering prompts for strategy, ideation, requirements, planning, execution, review, simplification, and reusable lessons |

`;wl` and `;lab` are just Workplace Labs' own prefixes for the kits it publishes — pick whatever prefix makes sense when you build and share your own.

Credit where it's due: the `;ak` kit is based on Andrej Karpathy's Sequoia Ascent 2026 talk, [`From Vibe Coding to Agentic Engineering`](https://www.youtube.com/watch?v=96jN2OCOfLs). The `;ce` kit is based on Every Inc's Compound Engineering plugin, and the `;cm` kit is based on Julius Brussee's `juliusbrussee/caveman` project.

Import any kit:

```sh
keypop import kits/workplace-labs-top5.snippets.json --apply
```

## Documentation

- [User Guide](docs/user-guide.md)
- [Kits](docs/kits.md)
- [Architecture](docs/architecture.md) (contributors)

Research: [`docs/research/`](docs/research/)
