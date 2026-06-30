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

Full library:

```sh
.build/debug/trctl export --output replacements.json
```

Team-only export (recommended for sharing):

```sh
.build/debug/trctl export --prefix ';wl' --output wl-replacements.json
```

Import is dry-run by default until you pass `--apply`:

```sh
.build/debug/trctl import wl-replacements.json --prefix ';wl' --dry-run
.build/debug/trctl import wl-replacements.json --prefix ';wl' --apply --on-conflict skip
```

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

## Team sharing

macOS Text Replacements have no built-in team permissions. We share **prefix-scoped JSON** plus this guide.

The Workplace Labs zone is **`;wl*`** — shortcuts starting with `;wl` (`;wle`, `;wlw`, `;wla`, `;wlp`).

### Maintainer workflow

```sh
.build/debug/trctl export --prefix ';wl' --output wl-replacements.json
```

Share via a secure channel (not public Git if it contains contact info). Every row in the file must start with `;wl`.

### Onboarding

1. Read this guide.
2. Receive `wl-replacements.json`.
3. Preview: `trctl import wl-replacements.json --prefix ';wl' --dry-run`
4. Apply: `trctl import wl-replacements.json --prefix ';wl' --apply --on-conflict skip`
5. Personal shortcuts (`;homep`, `;github`, `;ble`, …) are unaffected.

### Prefix zones

| Zone | Prefix | Shared JSON? | Examples |
|------|--------|--------------|----------|
| Workplace Labs | `;wl` | Yes | `;wle`, `;wlw`, `;wla`, `;wlp` |
| Blue Label | `;bl` | No | `;ble` |
| Simple Joy | `;sj` | No | `;sj`, `;sjm` |
| Personal | `;` | No | `;homep`, `;github`, `;cal` |

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
☐ Team WL entries start with ;wl and go in wl-replacements.json

ORG ZONES (; + org + role)
──────────────────────────
Blue Label email   ;ble
Simple Joy name    ;sj
Simple Joy email   ;sjm
WL email           ;wle
WL website         ;wlw
WL address         ;wla
WL phone           ;wlp

PERSONAL
────────
Phone              ;homep
Address            ;homea
Email              ;proton  ;gmail
Link               ;github  ;cal  ;linkedin

TRCTL
─────
trctl list --prefix ';wl'
trctl export --prefix ';wl' --output wl-replacements.json
trctl import wl-replacements.json --prefix ';wl' --dry-run
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

Then export: `trctl export --prefix ';wl' --output wl-replacements.json`

---

## Troubleshooting

**Shortcut does not expand** — check System Settings or `trctl list`; some apps (VS Code, Terminal) ignore macOS replacements.

**Wrong phrase expands** — check for shortcuts where one is a prefix of another.

**iCloud sync stale** — open Text Replacements on another device; see `docs/text-replacement-research.md` §7.

**Import prefix error** — every JSON row must match `--prefix` (e.g. all start with `;wl`).

---

## Developer reference (`trctl`)

| Command | Purpose |
|---------|---------|
| `trctl list` | All replacements |
| `trctl list --prefix ';wl'` | WL zone only |
| `trctl export --prefix ';wl' --output wl.json` | Team export |
| `trctl import wl.json --prefix ';wl' --dry-run` | Preview merge |
| `trctl import wl.json --prefix ';wl' --apply --on-conflict skip` | Apply team library |
| `trctl create --shortcut ';wlc' --phrase '...'` | Add one entry |

---

## Summary

1. **`;` on everything new** — one symbols switch on iOS, then letters.
2. **No dots** in shortcuts — use `;wle` not `;wl.email`.
3. **Org pattern:** `;` + 2-letter org + 1-letter role (`;ble`, `;sjm`, `;wle`).
4. **Team sharing:** `export` / `import` with `--prefix ';wl'`.
5. **Keep it small** — static strings you type daily, not passwords or templates.

When in doubt, ask before adding to `wl-replacements.json`.
