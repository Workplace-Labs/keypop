# trctl + trexpand

Manage Apple Text Replacements from the terminal and expand them system-wide on Mac.

| Tool | Role |
|------|------|
| **trctl** | CRUD for Apple Text Replacements (iOS sync via iCloud) |
| **trexpand** | Mac runtime expander for Warp, VS Code, Cursor, terminals |

Same shortcuts everywhere. Plain static text only (no `{clipboard}` placeholders) so iOS and Mac stay aligned.

## How it works

```
kits/*.snippets.json  ──trctl import──►  Apple Text Replacements (iOS + native apps)
                              │
                              └──auto-export──►  ~/.config/trexpand/snippets.json
                                                        │
                                                   trexpand (Warp, editors)
```

## Requirements

- macOS 14+ (validated on macOS 26.5.1, Apple Silicon)
- Swift toolchain
- `trctl` uses private `KeyboardServices` APIs (not Mac App Store safe)
- `trexpand` requires **Input Monitoring** + **Accessibility** for **`~/.local/Trexpand.app`** (not the bare CLI binary, not Terminal). See [User Guide](docs/user-guide.md#permissions).

## Install

```sh
./scripts/install.sh
```

Installs `trctl`, `trexpand`, and `trexpand-probe` to `~/.local/bin`, bundles `~/.local/Trexpand.app`, and installs a LaunchAgent.

## Quick start

```sh
trctl inspect
trctl import kits/prompts-core.snippets.json --prefix ';p' --dry-run
trctl import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip

# Grant TCC to ~/.local/Trexpand.app, then:
./scripts/launch-trexpand.sh restart
```

`trctl create` / `update` / `delete` / `import --apply` auto-export snippets for trexpand (reloads within ~200ms when the daemon is running). Opt out: `--no-sync-expander`.

## CLI examples

### Snippets (CRUD)

```sh
# Add a shortcut (syncs to trexpand automatically)
trctl create --shortcut ';wle' --phrase 'jon@workplacelabs.io'

# Update prompt text
trctl update --shortcut ';pcr' --phrase 'Review this diff for bugs and suggest fixes.'

# Look up one entry
trctl get --shortcut ';pcr'

# Remove
trctl delete --shortcut ';test'

# List all, or filter by prefix
trctl list
trctl list --prefix ';p'
```

### Kits (import / export)

```sh
# Preview starter prompts (;pcr, ;psum, …)
trctl import kits/prompts-core.snippets.json --prefix ';p' --dry-run

# Apply (backs up affected rows first)
trctl import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip

# Export your ;wl contact zone to share
trctl export --prefix ';wl' --output kits/wl-team.snippets.json

# Import without touching trexpand (rare)
trctl import kits/foo.snippets.json --apply --no-sync-expander
```

### trexpand (daemon)

```sh
./scripts/launch-trexpand.sh status
./scripts/launch-trexpand.sh restart
tail -f ~/.local/log/trexpand.log          # expanded|;pcr|… or reloaded|23 snippets

trexpand-probe permissions                 # TCC check
trexpand-probe inject --text 'probe'       # paste test in focused field
```

### Diagnostics

```sh
trctl inspect
scripts/validate-crud.sh
scripts/probes/run-sprint0.sh
trexpand-probe permissions
```

## Documentation

- [User Guide](docs/user-guide.md)
- [Kits](docs/kits.md)
- [Architecture](docs/architecture.md) (contributors)
- [Spike results](docs/spike-results.md)
