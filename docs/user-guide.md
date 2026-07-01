# Text Replacements User Guide

How to set up and maintain Apple Text Replacements with `trctl` — conventions, kits, and optional Raycast sync.

**Prerequisites:** `trctl` installed (see [README](../README.md)).

**Related:** [Kits format](kits.md) · [Architecture](architecture.md) (contributors)

---

## 5-minute setup

1. **Verify the CLI**

```sh
trctl inspect
trctl list
```

2. **Preview a starter prompt kit**

```sh
trctl import kits/prompts-core.raycast.json --prefix ';p' --dry-run
```

3. **Apply when ready** (writes a backup under `backups/` first)

```sh
trctl import kits/prompts-core.raycast.json --prefix ';p' --apply --on-conflict skip
```

4. **Optional — Raycast for Warp / VS Code / Cursor**

```sh
./scripts/sync-raycast.sh
```

In Raycast: **Settings → Snippets → Override System Snippets ON** (one-time).

You can also add replacements in **System Settings → Keyboard → Text Replacements**; they sync to iPhone/iPad via iCloud.

---

## What text replacements do

Type a short **shortcut** (trigger). macOS replaces it with a longer **phrase** — email, URL, address, or canned reply.

Example: `;cal` → your booking link.

Replacements sync across Apple devices on the same iCloud account. No extra app required on iOS.

---

## Conventions

### Start every shortcut with `;`

Semicolon is rare in normal typing, easy to reach, and creates a clear namespace.

```
Good:  ;github   ;phone   ;ace
Risky: github    phone    ace     ← can collide with real words
```

### Letters only after `;` (no dots)

Dot grouping (`;ac.email`) reads well on Mac but is tedious on iPhone — each `.` often needs the symbols keyboard. Use compact letter codes instead: `;ace` (Acme email), `;acw` (Acme website).

### Org zones: `;` + org + role

Pattern for company-specific entries:

```
; + <2-letter org> + <1-letter role>
```

| Role letter | Meaning | Example |
|-------------|---------|---------|
| `e` | email | `;ace` |
| `w` | website | `;acw` |
| `a` | address | `;aca` |
| `p` | phone | `;acp` |

Fictional Acme Corp zone (`;ac*`):

| Shortcut | Phrase |
|----------|--------|
| `;ace` | `team@example.com` |
| `;acw` | `https://www.example.com` |
| `;aca` | `123 Main St, Example City` |

Scope with `trctl list --prefix ';ac'` or `trctl export --prefix ';ac'`.

### Personal shortcuts

Use a service mnemonic, not the URL:

| Shortcut | Typical phrase |
|----------|----------------|
| `;github` | `https://github.com/yourhandle` |
| `;linkedin` | LinkedIn profile URL |
| `;cal` | Cal.com or booking link |
| `;email` | your primary email |

Rules: store full `https://` in the phrase; keep shortcuts unique; avoid prefix collisions (`;git` vs `;github`).

### AI prompts: `;p` + task

| Pattern | Scope | Examples |
|---------|-------|----------|
| `;p` + task | personal | `;pcr`, `;psum`, `;pfx` |
| `;p` + org + task | team | `;pacr`, `;pacsum` |

| Code | Task |
|------|------|
| `cr` | code / PR review |
| `sum` | summarize |
| `fx` | debug / fix |
| `em` | email draft |

Starter kit: `kits/prompts-core.raycast.json`. Long prompts or `{clipboard}` placeholders work better in Raycast than in Apple-synced replacements (iOS size limits). See [kits.md](kits.md).

---

## Team sharing

macOS has no built-in team permissions. Share **prefix-scoped JSON kits** via git or a secure channel.

**Maintainer:**

```sh
trctl export --prefix ';ac' --output kits/acme-team.raycast.json
./scripts/sync-raycast.sh
```

Keep real contact kits out of public repos (gitignore them). Every row in a team kit must share the same prefix.

**Onboarding:**

1. Receive the kit JSON from a maintainer.
2. `trctl import kits/acme-team.raycast.json --prefix ';ac' --dry-run`
3. `trctl import kits/acme-team.raycast.json --prefix ';ac' --apply --on-conflict skip`
4. `./scripts/sync-raycast.sh` if you use Raycast.

Personal shortcuts outside the prefix are untouched.

Import rules when `--prefix` is set:

- Every JSON row must start with that prefix.
- Conflicts are resolved only within that zone.
- `import --apply` backs up affected rows under `backups/` first.

---

## App compatibility

| Reliability | Apps |
|-------------|------|
| **Usually works** | Notes, Mail, Messages, Safari, Slack |
| **Usually does not** | Warp, Terminal.app, iTerm2, VS Code, Cursor |
| **Varies** | Chrome, JetBrains, Obsidian, Notion, Discord |

If a shortcut works in Notes but not Warp, the replacement is fine — use Raycast for that app.

---

## Troubleshooting

**No expansion in Warp / VS Code / Cursor** — run `./scripts/sync-raycast.sh`; confirm Raycast **Override System Snippets ON**.

**No expansion in Notes / Mail** — check `trctl list` or System Settings; test in Notes first.

**Wrong phrase** — look for shortcuts where one is a prefix of another.

**iCloud sync stale** — open Text Replacements on another device; wait a few minutes.

**Import prefix error** — every row must match `--prefix` (e.g. all start with `;ac`).

---

## Command reference

| Command | Purpose |
|---------|---------|
| `trctl list` | All entries (Raycast JSON) |
| `trctl list --prefix ';ac'` | Prefix zone only |
| `trctl export --prefix ';ac' --output kits/acme-team.raycast.json` | Shareable kit |
| `trctl import <kit> --prefix ';p' --dry-run` | Preview merge |
| `trctl import <kit> --prefix ';p' --apply --on-conflict skip` | Apply kit |
| `trctl create / update / delete` | Single-entry CRUD |
| `trctl inspect` | Health check (KeyboardServices) |
| `./scripts/sync-raycast.sh` | Push all replacements to Raycast |

Run `trctl --help` for the full command list.
