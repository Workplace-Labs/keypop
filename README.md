# trctl

CLI for Apple Text Replacements — manage shortcuts from the terminal, store kits in git, and sync to Raycast for apps macOS cannot reach.

## The problem

If you maintain dozens of AI prompts, email signatures, and contact snippets, you have probably felt the friction: Raycast on the Mac, Apple Settings for iPhone sync, no version history, no safe bulk import, and no way to share a team library without screenshots.

Apple Text Replacements are the only built-in layer that syncs across Mac, iPhone, and iPad via iCloud. But Apple never shipped a CLI or import format for power users. Terminals and code editors (Warp, VS Code, Cursor) do not expand native replacements anyway.

**`trctl` fills that gap:** programmatic CRUD for Apple Text Replacements, Raycast JSON kits for git-backed libraries, and a sync script for Mac apps Apple cannot reach.

## How it works

| Layer | Tool | Covers |
|-------|------|--------|
| Apple Text Replacements | `trctl` | iOS, Notes, Mail, Slack, Safari |
| Raycast Snippets (optional) | `scripts/sync-raycast.sh` | Warp, VS Code, Cursor |

Same keywords in both systems. Raycast: **Override System Snippets ON** (Settings → Snippets).

## Requirements

- macOS 14+ (validated on macOS 26.5.1, Apple Silicon)
- Xcode / Swift toolchain (for build-from-source)
- Uses private `KeyboardServices` APIs — not suitable for Mac App Store distribution

## Install

```sh
git clone <repo-url> && cd trctl
./scripts/install.sh
```

`install.sh` builds a release binary and copies `trctl` to `~/.local/bin`. Ensure that directory is on your `PATH`.

Contributors can also run `swift build` and use `.build/debug/trctl` directly.

## Quick start

```sh
trctl inspect
trctl list
trctl import kits/prompts-core.raycast.json --prefix ';p' --dry-run
./scripts/sync-raycast.sh    # optional, Raycast users only
```

Safe end-to-end mutation check (creates and deletes a disposable shortcut):

```sh
scripts/validate-crud.sh
```

## Documentation

- [User Guide](docs/user-guide.md) — conventions, team sharing, troubleshooting
- [Kits](docs/kits.md) — Raycast JSON format and limitations
- [AGENTS.md](AGENTS.md) — contributor notes and validation

## Safety

- `import --apply` writes a timestamped JSON backup under `backups/` before changes.
- `list` and `export` output your real replacement text — treat exports as potentially sensitive.
- Writes go through KeyboardServices private APIs, not direct SQLite mutation.

## License

MIT — see [LICENSE](LICENSE).
