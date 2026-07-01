# keypop

Manage Apple Text Replacements from the terminal and expand them system-wide on Mac.

| Command | Role |
|---------|------|
| `keypop` (CRUD) | Apple Text Replacements — iOS sync via iCloud |
| `keypop run` | Mac runtime — Warp, VS Code, Cursor, terminals |
| `keypop probe` | TCC / inject / bridge diagnostics |

Same shortcuts everywhere. Plain static text only (no `{clipboard}` placeholders) so iOS and Mac stay aligned.

## How it works

```
kits/*.snippets.json  ──keypop import──►  Apple Text Replacements (iOS + native apps)
                              │
                              └──auto-export──►  ~/.config/keypop/snippets.json
                                                        │
                                                   keypop run (Warp, editors)
```

## Requirements

- macOS 14+ (validated on macOS 26.5.1, Apple Silicon)
- Swift toolchain
- Uses private `KeyboardServices` APIs (not Mac App Store safe)
- `keypop run` requires **Input Monitoring** + **Accessibility** for **`~/.local/KeyPop.app`** (not Terminal). See [User Guide](docs/user-guide.md#permissions).

## Install

```sh
./scripts/install.sh
```

Installs `keypop` to `~/.local/bin`, bundles `~/.local/KeyPop.app`, and installs a LaunchAgent.

## Quick start

```sh
keypop inspect
keypop import kits/prompts-core.snippets.json --prefix ';p' --dry-run
keypop import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip

# Grant TCC to ~/.local/KeyPop.app, then:
./scripts/launch-keypop.sh restart
```

Mutations auto-export snippets for `keypop run` (reloads within ~200ms when the daemon is running). Opt out: `--no-sync`.

## CLI examples

### Snippets (CRUD)

```sh
keypop create --shortcut ';wle' --phrase 'you@example.com'
keypop update --shortcut ';pcr' --phrase 'Review this diff for bugs and suggest fixes.'
keypop get --shortcut ';pcr'
keypop delete --shortcut ';test'
keypop list
keypop list --prefix ';p'
```

### Kits (import / export)

```sh
keypop import kits/prompts-core.snippets.json --prefix ';p' --dry-run
keypop import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip
keypop export --prefix ';wl' --output kits/wl-team.snippets.json
keypop import kits/foo.snippets.json --apply --no-sync
```

### Daemon

```sh
./scripts/launch-keypop.sh status
./scripts/launch-keypop.sh restart
tail -f ~/.local/log/keypop.log

keypop probe permissions
keypop probe inject --text 'probe'
```

### Diagnostics

```sh
keypop inspect
scripts/validate-crud.sh
scripts/probes/run-sprint0.sh
keypop probe permissions
```

## Repository

```sh
git clone git@github.com:Workplace-Labs/keypop.git
cd keypop
./scripts/install.sh
```

## Documentation

- [User Guide](docs/user-guide.md)
- [Kits](docs/kits.md)
- [Architecture](docs/architecture.md) (contributors)
- [Spike results](docs/spike-results.md)
