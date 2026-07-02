# keypop User Guide

Get your snippet library running on Mac and iPhone, including Warp, VS Code, and Cursor.

**Prerequisites:** `keypop` installed — see [README](../README.md) for install steps.

**Related:** [Kits](kits.md) · [Architecture](architecture.md)

---

## 5-minute setup

1. **Verify the CLI**

```sh
keypop inspect
keypop list
```

2. **Preview the starter prompt kit**

```sh
keypop import kits/prompts-core.snippets.json --prefix ';p' --dry-run
```

3. **Apply** (writes a backup under `private/backups/` first)

```sh
keypop import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip
```

4. **Start the Mac expander**

```sh
./scripts/install.sh                  # or: ./scripts/launch-keypop.sh install
```

### Permissions

Grant **Input Monitoring** and **Accessibility** to **`~/.local/KeyPop.app`** (the app bundle, not Terminal and not the bare `keypop` exec):

1. System Settings → Privacy & Security → Input Monitoring (and Accessibility)
2. Click **+** → **Cmd+Shift+G** → paste: `~/.local/KeyPop.app`
3. Remove any old **keypop** bare-exec entry with a black icon if present

Then restart:

```sh
./scripts/launch-keypop.sh restart
./scripts/launch-keypop.sh status     # expect: running + KeyPop.app path
```

Type `;pcr` in Warp to verify.

Replacements also sync to iPhone/iPad via iCloud (System Settings → Keyboard → Text Replacements).

---

## Two layers, one library

| Layer | Command | Where it works |
|-------|---------|----------------|
| Apple Text Replacements | `keypop` (CRUD) | iOS, Notes, Mail, Messages, Safari, Slack |
| Mac runtime | `keypop run` | Warp, VS Code, Cursor, Terminal |

Use the **same keywords** in both layers. `keypop` mutations auto-export to `~/.config/keypop/snippets.json`; `keypop run` watches that file.

---

## Conventions

### Start shortcuts with `;`

```
Good:  ;github   ;phone   ;labe
Risky: github    phone         ← can collide with real words
```

### Letters only after `;` (no dots)

Use `;labe` not `;lab.email` — dots are tedious on iOS.

### Org zones: `;` + org + role

Example team: **Lab Rats** (`;lab`)

| Role | Letter | Example |
|------|--------|---------|
| email | `e` | `;labe` |
| website | `w` | `;labw` |
| address | `a` | `;laba` |
| phone | `p` | `;labp` |

### AI prompts: `;p` + task

| Code | Task |
|------|------|
| `cr` | code review |
| `sum` | summarize |
| `fx` | debug / fix |

Starter kit: `kits/prompts-core.snippets.json`. Keep prompts as **plain static text** (no `{clipboard}`) so iOS and Mac stay in sync.

---

## Team sharing

Export prefix-scoped kits:

```sh
keypop export --prefix ';lab' --output kits/lab-rats.snippets.json
```

Onboarding:

```sh
keypop import kits/lab-rats.snippets.json --prefix ';lab' --dry-run
keypop import kits/lab-rats.snippets.json --prefix ';lab' --apply --on-conflict skip
./scripts/launch-keypop.sh install
```

Keep PII kits out of public repos (gitignored).

---

## App compatibility

| Layer | Usually works | Usually does not |
|-------|---------------|------------------|
| Apple | Notes, Mail, Messages, Safari, Slack | Warp, VS Code, Cursor |
| keypop run | Warp, VS Code, Cursor, Terminal | N/A (Mac only) |

---

## Troubleshooting

**No expansion in Warp / VS Code / Cursor**

```sh
./scripts/launch-keypop.sh status   # is keypop run loaded?
./scripts/sync-keypop.sh            # re-export snippets
tail -f ~/.local/log/keypop.log     # expansion / tap health logs
```

**No expansion on iPhone** — check System Settings → Keyboard → Text Replacements; wait for iCloud sync.

**Double expansion in Slack** — rare; both Apple Text Replacements and `keypop run` may fire. Test in Notes vs Warp to isolate.

**Daemon stopped after sleep** — check log for `tap_health` lines; restart: `./scripts/launch-keypop.sh restart`

**TCC not working after rebuild** — re-grant permissions to `~/.local/KeyPop.app` (rebuild re-signs the bundle), remove stale exec entries, then `./scripts/launch-keypop.sh restart`.

**`keypop` synced but Warp unchanged** — check stderr for `keypop_hint|` lines; confirm `keypop run` is loaded and log shows `reloaded|N snippets` after mutations.

---

## CLI examples

### Everyday snippets

```sh
# TDD workflow prompt
keypop create --shortcut ';ptdd' \
  --phrase 'Add a failing test, run it, verify it fails, fix the issue, verify the test passes'

# Pre-PR hardening prompt (from prompts-core kit)
keypop import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip

# Change one prompt in place
keypop update --shortcut ';pcr' --phrase 'Great work on this! Now reflect on…'

# Inspect before deleting
keypop get --shortcut ';ptdd'
keypop delete --shortcut ';ptdd'
```

After each mutation, stderr should include `keypop_sync|…`. If you see `keypop_hint|daemon not running`, run `./scripts/launch-keypop.sh restart`.

### Prefix zones

```sh
keypop list --prefix ';lab'    # Lab Rats contacts
keypop list --prefix ';p'     # prompt kit

keypop export --prefix ';lab' --output kits/lab-rats.snippets.json
keypop export --output kits/full.snippets.json
```

### Import strategies

```sh
# Preview only
keypop import kits/lab-rats.snippets.json --prefix ';lab' --dry-run

# Skip rows that already exist
keypop import kits/lab-rats.snippets.json --prefix ';lab' --apply --on-conflict skip

# Overwrite conflicts
keypop import kits/lab-rats.snippets.json --prefix ';lab' --apply --on-conflict overwrite
```

### Daemon commands

```sh
./scripts/install.sh                       # build, bundle KeyPop.app, install LaunchAgent
./scripts/launch-keypop.sh install       # plist only (after manual build)
./scripts/launch-keypop.sh status        # running? which binary path?
./scripts/launch-keypop.sh restart       # after TCC grant or rebuild
./scripts/sync-keypop.sh                 # force re-export from keypop

# Foreground debug (uses Terminal TCC, not LaunchAgent)
keypop run --snippets ~/.config/keypop/snippets.json
```

### Verify expansion

1. `./scripts/launch-keypop.sh status` → `running`
2. Type `;pcr` in Warp → full prompt appears
3. Log: `tail -f ~/.local/log/keypop.log` → `expanded|;pcr|…`

---

## Command reference

| Command | Example |
|---------|---------|
| List all | `keypop list` |
| List prefix | `keypop list --prefix ';lab'` |
| Get one | `keypop get --shortcut ';pcr'` |
| Create | `keypop create --shortcut ';labe' --phrase 'you@example.com'` |
| Update | `keypop update --shortcut ';pcr' --phrase 'New prompt text…'` |
| Delete | `keypop delete --shortcut ';test'` |
| Export kit | `keypop export --prefix ';lab' --output kits/lab-rats.snippets.json` |
| Import preview | `keypop import kits/prompts-core.snippets.json --prefix ';p' --dry-run` |
| Import apply | `keypop import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip` |
| Install daemon | `./scripts/launch-keypop.sh install` |
| Restart daemon | `./scripts/launch-keypop.sh restart` |
| Re-export | `./scripts/sync-keypop.sh` |
| TCC probe | `keypop probe permissions` |
| Inject probe | `keypop probe inject --text 'hello'` |
