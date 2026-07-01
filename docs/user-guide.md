# Text Replacements User Guide

Set up Apple Text Replacements with `trctl` and expand them in Warp, editors, and terminals with `trexpand`.

**Prerequisites:** `trctl` and `trexpand` installed ([README](../README.md)).

**Related:** [Kits](kits.md) · [Architecture](architecture.md)

---

## 5-minute setup

1. **Verify the CLI**

```sh
trctl inspect
trctl list
```

2. **Preview the starter prompt kit**

```sh
trctl import kits/prompts-core.snippets.json --prefix ';p' --dry-run
```

3. **Apply** (writes a backup under `backups/` first)

```sh
trctl import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip
```

4. **Start the Mac expander**

```sh
./scripts/install.sh                  # or: ./scripts/launch-trexpand.sh install
```

### Permissions

Grant **Input Monitoring** and **Accessibility** to **`~/.local/Trexpand.app`** (the app bundle, not Terminal and not the bare `trexpand` exec):

1. System Settings → Privacy & Security → Input Monitoring (and Accessibility)
2. Click **+** → **Cmd+Shift+G** → paste: `~/.local/Trexpand.app`
3. Remove any old **trexpand** entry with a black exec icon if present

Then restart:

```sh
./scripts/launch-trexpand.sh restart
./scripts/launch-trexpand.sh status     # expect: running + Trexpand.app path
```

Type `;pcr` in Warp to verify.

Replacements also sync to iPhone/iPad via iCloud (System Settings → Keyboard → Text Replacements).

---

## Two layers, one library

| Layer | Tool | Where it works |
|-------|------|----------------|
| Apple Text Replacements | `trctl` | iOS, Notes, Mail, Messages, Safari, Slack |
| Mac expander | `trexpand` | Warp, VS Code, Cursor, Terminal |

Use the **same keywords** in both layers. `trctl` mutations auto-export to `~/.config/trexpand/snippets.json`; trexpand watches that file.

---

## Conventions

### Start shortcuts with `;`

```
Good:  ;github   ;phone   ;ace
Risky: github    phone         ← can collide with real words
```

### Letters only after `;` (no dots)

Use `;ace` not `;ac.email` — dots are tedious on iOS.

### Org zones: `;` + org + role

| Role | Letter | Example |
|------|--------|---------|
| email | `e` | `;ace` |
| website | `w` | `;acw` |
| address | `a` | `;aca` |
| phone | `p` | `;acp` |

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
trctl export --prefix ';ac' --output kits/acme-team.snippets.json
```

Onboarding:

```sh
trctl import kits/acme-team.snippets.json --prefix ';ac' --dry-run
trctl import kits/acme-team.snippets.json --prefix ';ac' --apply --on-conflict skip
./scripts/launch-trexpand.sh install
```

Keep PII kits out of public repos (gitignored).

---

## App compatibility

| Layer | Usually works | Usually does not |
|-------|---------------|------------------|
| Apple | Notes, Mail, Messages, Safari, Slack | Warp, VS Code, Cursor |
| trexpand | Warp, VS Code, Cursor, Terminal | N/A (Mac only) |

---

## Troubleshooting

**No expansion in Warp / VS Code / Cursor**

```sh
./scripts/launch-trexpand.sh status   # is trexpand running?
./scripts/sync-expander.sh            # re-export snippets
tail -f ~/.local/log/trexpand.log     # expansion / tap health logs
```

**No expansion on iPhone** — check System Settings → Keyboard → Text Replacements; wait for iCloud sync.

**Double expansion in Slack** — rare; both Apple and trexpand may fire. Test in Notes vs Warp to isolate.

**trexpand stopped after sleep** — check log for `tap_health` lines; restart: `./scripts/launch-trexpand.sh restart`

**TCC not working after rebuild** — re-grant permissions to `~/.local/Trexpand.app` (rebuild re-signs the bundle), remove stale exec entries, then `./scripts/launch-trexpand.sh restart`.

**`trctl` synced but Warp unchanged** — check stderr for `trexpand_hint|` lines; confirm daemon is running and log shows `reloaded|N snippets` after mutations.

---

## CLI examples

### Everyday snippets

```sh
# TDD workflow prompt
trctl create --shortcut ';ptdd' \
  --phrase 'Add a failing test, run it, verify it fails, fix the issue, verify the test passes'

# Pre-PR hardening prompt (from prompts-core kit)
trctl import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip

# Change one prompt in place
trctl update --shortcut ';pcr' --phrase 'Great work on this! Now reflect on…'

# Inspect before deleting
trctl get --shortcut ';ptdd'
trctl delete --shortcut ';ptdd'
```

After each mutation, stderr should include `trexpand_sync|…`. If you see `trexpand_hint|daemon not running`, run `./scripts/launch-trexpand.sh restart`.

### Prefix zones

```sh
trctl list --prefix ';wl'    # Workplace Labs contacts
trctl list --prefix ';p'     # prompt kit

trctl export --prefix ';wl' --output kits/wl-team.snippets.json
trctl export --output kits/full.snippets.json
```

### Import strategies

```sh
# Preview only
trctl import kits/acme-team.snippets.json --prefix ';ac' --dry-run

# Skip rows that already exist
trctl import kits/acme-team.snippets.json --prefix ';ac' --apply --on-conflict skip

# Overwrite conflicts
trctl import kits/acme-team.snippets.json --prefix ';ac' --apply --on-conflict overwrite
```

### trexpand operator commands

```sh
./scripts/install.sh                       # build, bundle Trexpand.app, install LaunchAgent
./scripts/launch-trexpand.sh install       # plist only (after manual build)
./scripts/launch-trexpand.sh status        # running? which binary path?
./scripts/launch-trexpand.sh restart       # after TCC grant or rebuild
./scripts/sync-expander.sh                 # force re-export from trctl

# Foreground debug (uses Terminal TCC, not LaunchAgent)
trexpand run --snippets ~/.config/trexpand/snippets.json
```

### Verify expansion

1. `./scripts/launch-trexpand.sh status` → `running`
2. Type `;pcr` in Warp → full prompt appears
3. Log: `tail -f ~/.local/log/trexpand.log` → `expanded|;pcr|…`

---

## Command reference

| Command | Example |
|---------|---------|
| List all | `trctl list` |
| List prefix | `trctl list --prefix ';wl'` |
| Get one | `trctl get --shortcut ';pcr'` |
| Create | `trctl create --shortcut ';wle' --phrase 'you@example.com'` |
| Update | `trctl update --shortcut ';pcr' --phrase 'New prompt text…'` |
| Delete | `trctl delete --shortcut ';test'` |
| Export kit | `trctl export --prefix ';wl' --output kits/wl-team.snippets.json` |
| Import preview | `trctl import kits/prompts-core.snippets.json --prefix ';p' --dry-run` |
| Import apply | `trctl import kits/prompts-core.snippets.json --prefix ';p' --apply --on-conflict skip` |
| Install daemon | `./scripts/launch-trexpand.sh install` |
| Restart daemon | `./scripts/launch-trexpand.sh restart` |
| Re-export | `./scripts/sync-expander.sh` |
| TCC probe | `trexpand-probe permissions` |
| Inject probe | `trexpand-probe inject --text 'hello'` |
