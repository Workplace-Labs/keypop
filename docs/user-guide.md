# Text Replacements: New User Guide

A practical guide to setting up and maintaining Apple Text Replacements on macOS, using conventions we use on this team.

**Who this is for:** anyone onboarding to our text-replacement library, whether you type shortcuts on your Mac/iPhone or manage the library with `trctl`.

**Related docs:** `docs/text-replacement-research.md` (background research), `docs/architecture.md` (how macOS stores replacements).

---

## What text replacements do

Type a short **shortcut** (also called a trigger or abbreviation). macOS replaces it with a longer **phrase** — an email, URL, address, or canned reply.

Example: type `;cal` and it expands to your Cal.com booking link.

Replacements sync across Apple devices on the same iCloud account (Mac, iPhone, iPad). No extra app required.

---

## Quick start

### Add a replacement in System Settings

1. Open **System Settings → Keyboard → Text Replacements**
2. Click **+**
3. **Replace:** your shortcut (use our conventions below — start with `;`)
4. **With:** the full text or URL
5. Test in Mail, Messages, or Notes before relying on it elsewhere

### List what is already configured (developers)

```sh
cd projects/macos-text-replacements
swift build
.build/debug/trctl list
.build/debug/trctl list --prefix ';wl'
```

`--prefix` filters to shortcuts that **start with** the given string. Use it to inspect one org zone without dumping personal entries.

### Export or share a library snapshot

Kit files use the **Raycast snippet JSON format** (`name`, `keyword`, `text`). See [`docs/kits.md`](kits.md) for import/export workflows and limitations.

Full library:

```sh
.build/debug/trctl export --output kits/full.raycast.json
```

Team-only export (recommended for sharing):

```sh
.build/debug/trctl export --prefix ';wl' --output kits/wl-team.raycast.json
```

Prompt kit:

```sh
.build/debug/trctl import kits/prompts-core.raycast.json --prefix ';p' --dry-run
.build/debug/trctl import kits/prompts-core.raycast.json --prefix ';p' --apply --on-conflict skip
```

Contact team kit:

```sh
.build/debug/trctl import kits/wl-team.raycast.json --prefix ';wl' --dry-run
.build/debug/trctl import kits/wl-team.raycast.json --prefix ';wl' --apply --on-conflict skip
```

After any `trctl import --apply` or manual create/update/delete, sync Raycast:

```sh
./scripts/sync-raycast.sh
```

Raycast: **Override System Snippets ON** (Settings → Snippets, one-time). Same keywords in both systems — Apple for iOS, Raycast for Warp/VS Code/Cursor.

Exports are Raycast-importable JSON. Raycast exports can be applied with `trctl import`.

Import requires exactly one of `--dry-run` or `--apply`:

When `--prefix` is set on import:

- Every row in the JSON **must** start with that prefix (import fails otherwise).
- Creates/updates are compared only against existing shortcuts in that prefix zone.
- The pre-apply backup contains only the prefix-scoped rows that would be affected.

`import --apply` writes a timestamped backup under `backups/` before making changes.

---

## Our core convention: the semicolon (`;`)

**Every new shortcut should start with `;`.**

Why semicolon?

- It is rare in normal English typing, so expansions almost never fire by accident.
- It is easy to reach on Mac keyboards.
- It creates a clear namespace: if it starts with `;`, it is a text replacement.

```
Good:  ;github   ;homep   ;wle
Risky: github    homep    wle        ← can collide with real words
```

### Dot grouping vs letter-only (Mac vs iOS)

Many text-expander guides use a **dot grouping** convention — org namespace, dot, then role:

```
;wl.email    ;bl.email    ;sj.main
```

On a **Mac keyboard**, this is ideal:

- Reads like `group.item` (same mental model as `trctl --prefix ';wl.'`)
- Clear visual hierarchy when browsing a long list
- Easy to type: `;` and `.` are both on the main keyboard layer

We **do not use dot grouping** in this library because replacements **sync to iPhone and iPad** via iCloud.

On **iOS**, each `.` usually means another trip to the symbols keyboard (you already switch once for `;`). That friction adds up on shortcuts you type daily.

| Style | Mac | iOS (synced) | Our choice |
|-------|-----|--------------|------------|
| Dot grouping (`;wl.email`) | Ideal | Poor | Avoid |
| Letter-only (`;wle`) | Good | **Better** | **Use this** |

**Rule for this team:** use **letters only after `;`**. Map dotted names to letter codes in your head (`;wl.email` → `;wle`).

```
Avoid:  ;wl.email   ;bl.email   ;sj.main     ← great on Mac, tedious on iOS
Use:    ;wle        ;ble        ;sjm         ← one ; switch, then all letters
```

If you ever maintain a **Mac-only** library with no iCloud sync, dot grouping is a reasonable alternative. For cross-device Apple replacements, prefer letter-only.

### Legacy shortcuts without `;`

Only `omw` remains as a legacy bare-word phrase. **Do not add new shortcuts without `;`.**

---

## Org zones: `;` + org + role (letters only)

Pattern for company-specific entries:

```
; + <2-letter org> + <1-letter role>
```

### Role letters

| Letter | Meaning | Example |
|--------|---------|---------|
| `e` | email | `;wle`, `;ble` |
| `m` | main (primary email) | `;sjm` |
| `w` | website | `;wlw` |
| `a` | address | `;wla` |
| `p` | phone | `;wlp` |
| `g` | GitHub (future) | `;wlg` |
| `c` | calendar / booking (future) | `;wlc` |

### Org codes

| Code | Company | Examples |
|------|---------|----------|
| `bl` | Blue Label | `;ble` |
| `sj` | Simple Joy | `;sj` (name), `;sjm` (email) |
| `wl` | Workplace Labs | `;wle`, `;wlw`, `;wla`, `;wlp` |

### Current library

| Shortcut | What it is |
|----------|------------|
| `;ble` | Blue Label email |
| `;sj` | “Simple Joy Solutions” (company name) |
| `;sjm` | Simple Joy email |
| `;wle` | Workplace Labs email |
| `;wlw` | Workplace Labs website |
| `;wla` | Workplace Labs office address |
| `;wlp` | Workplace Labs phone |
| `;proton` | Personal Proton email |
| `;gmail` | Personal Gmail |
| `;homep` | Home phone |
| `;homea` | Home address |
| `;github`, `;cal`, … | Personal links |

**`trctl` scoping:**

| Zone | Filter |
|------|--------|
| Workplace Labs | `--prefix ';wl'` |
| Blue Label | `--prefix ';bl'` |
| Simple Joy | `--prefix ';sj'` (includes `;sj` and `;sjm`) |

---

## How to name a shortcut

**Personal contact / links:**

```
; + [context or service mnemonic]
```

Examples: `;homep`, `;github`, `;portfolio`

**Org entries:**

```
; + <org> + <role letter>
```

Examples: `;ble`, `;sjm`, `;wle`

Keep shortcuts **short**, **memorable**, and **unique**. The phrase can be long; the shortcut should not.

### Personal contact suffixes

| Suffix | Meaning | Example |
|--------|---------|---------|
| `p` | phone | `;homep` |
| `a` | address | `;homea` |
| *(service name)* | email or link | `;proton`, `;gmail` |

### Link mnemonics (personal)

Use the **service or purpose name**, not the URL:

| Shortcut | Typical phrase |
|----------|----------------|
| `;github` | GitHub profile |
| `;linkedin` | LinkedIn profile |
| `;cal` | Cal.com booking |
| `;portfolio` | personal site |
| `;bolt`, `;lov` | referral URLs |

**Team links** use the org pattern: `;wlw` (website), future `;wlg` (GitHub), `;wlc` (booking).

**Rules:**

1. Name the destination, not the URL (`;github`, not `;https`).
2. Store full `https://` in the phrase.
3. No dots in the shortcut string.
4. Avoid prefix collisions (`;git` vs `;github`).

---

## Prompt shortcuts (`;p` + task)

AI prompts use **`;p`** plus a small task code. Org/team prompts add the org code before the task.

### Suggested convention

| Pattern | Scope | Examples |
|---------|-------|----------|
| `;p` + `<task>` | personal prompts | `;pcr`, `;psum`, `;pfx` |
| `;p` + `<org>` + `<task>` | org/team prompts | `;pwlcr`, `;pblsum`, `;psjfx` |

Read these aloud once when onboarding:

| Code | Say | Task |
|------|-----|------|
| `cr` | review | code / PR review |
| `sum` | sum | summarize |
| `fx` | fix | debug |
| `gn` | gen | generate |
| `em` | email | email draft |
| `rv` | rev | PR description |
| `ou` | outline | outline / structure |

Examples:

| Shortcut | Meaning |
|----------|---------|
| `;pcr` | personal code / PR review prompt |
| `;pwlcr` | Workplace Labs code / PR review prompt |
| `;pblsum` | Blue Label summarize prompt |
| `;psjfx` | Simple Joy debug/fix prompt |

Prompt kits live in `kits/prompts-core.raycast.json` (Raycast format). Import:

```sh
.build/debug/trctl import kits/prompts-core.raycast.json --prefix ';p' --apply --on-conflict skip
```

Long prompts or `{clipboard}` placeholders: prefer **Raycast** on Mac; Apple Text Replacement sync is best for shorter prompts under the iOS size limit. In Warp and Terminal, use Raycast Snippets (`./scripts/sync-raycast.sh`, Override System Snippets ON). Details in [`docs/kits.md`](kits.md) and **App compatibility** below.

---

## Team sharing

macOS Text Replacements have no built-in team permissions. We share **prefix-scoped JSON** plus this guide.

The Workplace Labs zone is **`;wl*`** — shortcuts starting with `;wl` (`;wle`, `;wlw`, `;wla`, `;wlp`).

### Maintainer workflow

```sh
.build/debug/trctl export --prefix ';wl' --output kits/wl-team.raycast.json
./scripts/sync-raycast.sh   # after applying changes to your own Mac
```

Share via a secure channel. `kits/wl-team.raycast.json` is gitignored when it contains contact info. Every row must start with `;wl`.

### Onboarding

1. Read this guide and [`docs/kits.md`](kits.md).
2. Receive `kits/wl-team.raycast.json` from a maintainer.
3. Preview: `trctl import kits/wl-team.raycast.json --prefix ';wl' --dry-run`
4. Apply: `trctl import kits/wl-team.raycast.json --prefix ';wl' --apply --on-conflict skip`
5. Sync Raycast: `./scripts/sync-raycast.sh` (Override System Snippets ON).
6. Personal shortcuts (`;homep`, `;github`, `;ble`, …) are unaffected.

### Prefix zones

| Zone | Prefix | Shared JSON? | Examples |
|------|--------|--------------|----------|
| Workplace Labs | `;wl` | Yes | `;wle`, `;wlw`, `;wla`, `;wlp` |
| Blue Label | `;bl` | No | `;ble` |
| Simple Joy | `;sj` | No | `;sj`, `;sjm` |
| Prompts | `;p` | Kit in repo | `;pcr` |

---

## Cheat sheet

```
NEW SHORTCUT CHECKLIST
──────────────────────
☐ Starts with ;
☐ Letters only after ; (no dots — iOS friendly)
☐ Short and mnemonic
☐ Not a prefix of another shortcut
☐ Phrase complete (full https:// for URLs)
☐ Synced Raycast after changes → ./scripts/sync-raycast.sh
☐ Raycast Override System Snippets ON (one-time)

ORG ZONES (; + org + role)
──────────────────────────
Blue Label email   ;ble
Simple Joy name    ;sj
Simple Joy email   ;sjm
WL email           ;wle
WL website         ;wlw
WL address         ;wla
WL phone           ;wlp

PROMPTS (;p + task, or ;p + org + task)
────────────────────────────────────────
Code review        ;pcr
Summarize          ;psum
Fix/debug          ;pfx
WL code review     ;pwlcr
BL summarize       ;pblsum
SJ fix/debug       ;psjfx

PERSONAL
────────
Phone              ;homep
Address            ;homea
Email              ;proton  ;gmail
Link               ;github  ;cal  ;linkedin

KITS & RAYCAST SYNC
───────────────────
trctl export --prefix ';wl' --output kits/wl-team.raycast.json
trctl import kits/prompts-core.raycast.json --prefix ';p' --dry-run
./scripts/sync-raycast.sh          # after any trctl change
```

---

## Examples

**Personal GitHub**

| Replace | With |
|---------|------|
| `;github` | `https://github.com/yourhandle` |

**WL team website**

| Replace | With |
|---------|------|
| `;wlw` | `https://www.workplacelabs.io` |

Then export: `trctl export --prefix ';wl' --output kits/wl-team.raycast.json`

---

## App compatibility

macOS Text Replacements work in most **native** text fields and in some **Electron** apps (e.g. **Slack**). They often **do not expand** in apps with custom shell or editor input:

| Reliability | Apps |
|-------------|------|
| **Usually works** | Notes, Mail, Messages, Safari, Slack |
| **Usually does not** | **Warp**, **Terminal.app**, iTerm2, VS Code, **Cursor** |
| **Varies** | Chrome and other Chromium browsers, JetBrains in-editor, Obsidian, Notion, Discord |

If a shortcut works in Notes or Slack but not in Warp or Cursor, the replacement is fine — that app is the gap.

**Coverage in terminals and editors (Warp, VS Code, Cursor):**

- **Raycast Snippets** — `./scripts/sync-raycast.sh` after changes. **Override System Snippets ON** (Settings → Snippets).

Details: [`docs/kits.md`](kits.md) (Limitations → Raycast-specific).

---

## Troubleshooting

**Shortcut does not expand in Warp / VS Code / Cursor** — run `./scripts/sync-raycast.sh`. Confirm **Override System Snippets ON** in Raycast Settings → Snippets.

**Shortcut does not expand in Notes / Mail** — confirm with `trctl list` or System Settings, then test in **Notes**. If it works there but not in Warp, see **App compatibility** above.

**Wrong phrase expands** — check for shortcuts where one is a prefix of another.

**iCloud sync stale** — open Text Replacements on another device; see `docs/text-replacement-research.md` §7.

**Import prefix error** — every JSON row must match `--prefix` (e.g. all start with `;wl`).

---

## Developer reference (`trctl`)

| Command | Purpose |
|---------|---------|
| `trctl list` | All entries (Raycast JSON) |
| `trctl list --prefix ';wl'` | WL zone only |
| `trctl export --prefix ';wl' --output kits/wl-team.raycast.json` | Team kit (Raycast-importable) |
| `trctl import kits/wl-team.raycast.json --prefix ';wl' --dry-run` | Preview merge |
| `trctl import kits/prompts-core.raycast.json --prefix ';p' --apply` | Apply prompt kit |
| `./scripts/sync-raycast.sh` | Sync all replacements to Raycast Snippets |

---

## Summary

1. **`;` on everything new** — one symbols switch on iOS, then letters.
2. **No dots** in shortcuts — use `;wle` not `;wl.email`.
3. **Org pattern:** `;` + 2-letter org + 1-letter role (`;ble`, `;sjm`, `;wle`).
4. **Prompts:** `;p` + task for personal prompts, `;p` + org + task for team prompts (`;pcr`, `;pwlcr`).
5. **Dual layer:** Apple Text Replacements (iOS) + Raycast Snippets (Mac black-hole apps). Same keywords; Raycast **Override System Snippets ON**. Sync: `./scripts/sync-raycast.sh`.
6. **Kits:** Raycast JSON in `kits/` — `trctl export` / `import` and Raycast use the same format ([`docs/kits.md`](kits.md)).
7. **Team sharing:** `export` / `import` with `--prefix ';wl'`.

When in doubt, ask before adding to shared kits.
