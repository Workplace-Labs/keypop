# Text Replacement Tools: Research Notes

Research date: 2026-06-30  
Machine context: macOS 26.5.1, Apple Silicon  
Research method: web synthesis (Perplexity not available in workspace; sources cited inline)

This document summarizes current best practices, use cases, and conventions for text replacement / text expansion tools, with emphasis on macOS and developer-oriented tooling like `trctl`.

**For onboarding and team conventions, see [`user-guide.md`](user-guide.md).**

---

## 1. Executive Summary

Text replacement tools sit on a spectrum from **system-native shortcuts** (Apple Text Replacements) to **power-user expanders** (TextExpander, Typinator, Raycast Snippets) to **config-as-code** systems (Espanso). The industry consensus in 2025–2026:

1. **Design the library first** — unstructured snippet collections become hard to recall, collide, and maintain.
2. **Use deliberate trigger prefixes** — semicolons, double letters, group codes, or special characters to avoid accidental expansion.
3. **Match tool to capability tier** — static contact info vs. multi-line templates vs. dynamic fill-ins vs. app-specific behavior.
4. **Prefer local-first for PII** — cloud sync is convenient but increases exposure; never store secrets in snippets.
5. **Version-control when possible** — Git-backed YAML/JSON is the developer norm; Apple native sync is opaque and occasionally unreliable.

For this project, Apple native replacements remain the right **cross-device baseline** (iPhone/iPad sync via iCloud), while `trctl` fills the gap for **programmatic CRUD, backup, audit, and dotfiles-style management** on macOS.

---

## 2. Tool Landscape

### 2.1 Categories

| Category | Examples | Strengths | Limits |
|----------|----------|-----------|--------|
| **OS-native** | macOS Text Replacements, iOS Keyboard settings | Zero install, iCloud sync across Apple devices, works in many native apps | Plain text, no fill-ins, inconsistent in Electron/terminal, weak management UI, programmatic access blocked on recent macOS |
| **Mac-native commercial** | TextExpander, Typinator, aText, TypeFire | Rich text, fill-ins, team sharing, mature UX | Subscription or license cost, cloud dependency for teams |
| **Launcher-integrated** | Raycast Snippets, Alfred Snippets | Keyboard-first discovery, tags, import/export, clipboard integration | macOS-only, not a full team governance platform |
| **OSS / config-as-code** | Espanso, Beeftext (Windows) | Git-friendly YAML, cross-platform, scriptable, local-first | No GUI (Espanso), setup friction, limited team RBAC |
| **IDE-scoped** | VS Code snippets, JetBrains live templates | Project/repo versioning, language-aware tab stops | Does not follow you to Slack, browser, Mail, terminal |
| **Automation suites** | Keyboard Maestro, Text Blaze (browser) | Macros, conditionals, broader automation | Heavier than pure text expansion |

### 2.2 Feature Comparison (Typical Tiers)

| Capability | Native macOS | Raycast / Typinator | TextExpander | Espanso |
|------------|--------------|---------------------|--------------|---------|
| Static replacement | Yes | Yes | Yes | Yes |
| Multi-line | Yes (stored; UI limits) | Yes | Yes | Yes |
| Rich text / links | No | Limited | Yes | Via packages/scripts |
| Dynamic date/time | No | `{date}`, `{time}` | `%date%` macros | Variables, shell |
| Clipboard injection | No | `{clipboard}` | Yes | Yes |
| Cursor placement | No | `{cursor}` | Yes | Yes |
| Fill-in forms | No | Limited | `%filltext%`, popups | Forms in YAML |
| App-specific rules | No | Partial | Yes | `filter_exec`, includes |
| Team sharing | No | Raycast for Teams | Org groups | Git repo |
| Regex triggers | No | Some | Yes | Yes |
| Version control | Manual export | Export/import | Cloud + export | Native (YAML) |

Sources: [TextExpander tips](https://textexpander.com/blog/textexpander-tips), [Raycast Snippets manual](https://manual.raycast.com/snippets), [Espanso docs](https://espanso.org/docs/configuration/basics/), [TypeFire / TypeSnap comparisons](https://typefire.app/blog/best-text-expander-mac-2026).

---

## 3. Use Case Taxonomy

### 3.1 Personal productivity (high frequency)

| Use case | Example trigger | Notes |
|----------|-----------------|-------|
| Email addresses | `;proton`, `jfb` | Most common first snippets |
| Phone numbers | `;homep`, `;workp` | Keep E.164 or display format consistent |
| Mailing addresses | `;homea`, `;worka` | Multi-line; verify formatting typos |
| Calendar links | `;cal` | Booking URLs |
| Social / portfolio | `;linkedin`, `;github` | URL snippets often use `//` or `;` prefix |
| Common phrases | `omw` → "On my way!" | Apple ships `omw` as a default |
| Typo correction | `teh` → `the` | Abbreviation equals the mistake |

### 3.2 Professional / client communication

- Canned support replies tagged by client or issue type
- Meeting notes templates with date and cursor placeholders
- Email signatures (often better in a dedicated expander with rich text)
- Proposal / follow-up templates with fill-in client name

### 3.3 Developer workflows

| Use case | Where it lives | Why |
|----------|----------------|-----|
| Boilerplate (imports, class skeletons) | IDE snippets or Espanso | Tab stops, language scope |
| CLI one-liners (docker, git, kubectl) | Espanso / Raycast | Needed outside IDE |
| PR / commit templates | Espanso, Raycast, dotfiles | Cross-app (GitHub web, IDE, chat) |
| JSDoc / docstring blocks | IDE + optional system expander | IDE for tab stops; expander for non-IDE |
| AI prompt templates with `{clipboard}` | Raycast, PhraseVault, Espanso | Inject selection into prompt |
| License headers | Repo-scoped VS Code snippets | PR-reviewable, per-project |

Key insight from PhraseVault and Raycast docs: **IDE snippets and system expanders are complementary**, not competing. Developers who only use IDE snippets re-type the same content in terminal, browser, and chat.

Sources: [Raycast for engineers](https://www.pixelmatters.com/insights/raycast-for-software-engineers), [PhraseVault developers guide](https://phrasevault.app/help/text-expander-developers), [TextExpander snippet managers](https://textexpander.com/blog/best-snippet-managers).

### 3.4 Team / organizational

- Shared snippet groups with documented prefixes and labels
- "Official" org snippets plus personal aliases for muscle memory
- Fill-in fields for transitory data (patient name, ticket ID) rather than storing PHI/PII in the library
- PR-reviewed YAML repos (Espanso) or TextExpander org groups for governance

### 3.5 What not to put in expanders

Industry agreement across TextExpander HIPAA guidance, Lightning Assist security notes, and MPU community:

- Passwords and API keys (use 1Password / env vars)
- SSN, credit cards, bank details
- Patient PHI in stored snippets (use fill-ins at expansion time)
- Long secrets split across snippets ("security through obscurity")

---

## 4. Naming and Organization Conventions

### 4.1 Core rules (cross-tool consensus)

1. **Short, memorable, hard to trigger accidentally**
2. **Never use bare English words** (`thanks`, `addr`) without a prefix
3. **Avoid prefix collisions** — do not define `;sig` and `;signup` if one is a prefix of the other
4. **Label ≠ trigger** — human-readable labels power search; triggers are for muscle memory
5. **Document the scheme** — README, group notes, or `CONVENTIONS.md` in shared repos

Sources: [TextExpander abbreviation prefixes](https://textexpander.com/blog/the-abbreviation-prefixes-textexpander-experts-use), [TextExpander organizing snippets](https://textexpander.com/learn/using/organize), [Chronoid 2026 guide](https://www.chronoid.app/blog/text-expander-mac).

### 4.2 Prefix strategies

| Strategy | Pattern | Example | Used by |
|----------|---------|---------|---------|
| Semicolon namespace | `;` + mnemonic | `;cal`, `;github` | TextExpander experts, this project's library |
| Group dot notation | `grp.item` | `em.thanks`, `cal.zoom` | TextExpander group prefixes |
| Double first letter | `ddate`, `aaddr` | Reduces word collisions | TypeSnap, community tips |
| Leading `z` | `zaddr` | Rare letter on keyboard | TextExpander community |
| URL slash | `//github` | Mnemonic for links | TextExpander experts |
| Hash search | `#hbs` | HubSpot search shortcuts | Community |
| Numeric favorites | `;1` … `;9` | Top nine snippets | Power users |
| Regex hierarchy | `cd py pr` | Category subcategory action | Espanso advanced |

### 4.3 Category taxonomy (recommended groups)

Align files or snippet groups to purpose, not app:

```
contact/     emails, phones, addresses
links/       URLs, social, booking
work/        employer-specific blocks
personal/    home, family
dev/         git, docker, PR templates
support/     canned replies (team)
typos/       autocorrect replacements
```

Espanso convention: one YAML file per category under `match/`, with `_prefix.yml` for app-specific includes. Dotfiles repos (e.g. `jimbrig/dotfiles-espanso`) split `emails.yml`, `phones.yml`, `links.yml`, `dev.yml`.

### 4.4 This project's current library (observed)

The live system already follows several best practices:

- **Semicolon prefix** for most shortcuts (`;jonb`, `;worka`, `;cal`) — matches TextExpander expert guidance
- **Mnemonic suffixes** (`homep`, `workp`, `portfolio`, `linkedin`)
- **Mixed legacy triggers** without `;` (`jonw`, `jfb`, `omw`, `2arb`) — acceptable for muscle-memory staples but higher collision risk

Gaps to consider:

- No visible labels/descriptions (native macOS has no label field)
- `;wlabsw` contains typo `htttps` — library hygiene issue
- No documented convention file for future additions

---

## 5. Dynamic and Template Conventions

### 5.1 Placeholder syntax (varies by tool)

| Concept | Raycast | TextExpander | CodeExpander |
|---------|---------|--------------|--------------|
| Cursor | `{cursor}` | cursor macro / fill | `%c%` |
| Clipboard | `{clipboard}` | clipboard macro | `%cv%` |
| Date | `{date format="yyyy-MM-dd"}` | `%date%` | `%date&format=...%` |
| Nested snippet | `{snippet name="..."}` | nested abbrev | `%s:abbr%` |
| Fill-in text | limited | `%filltext:name=...%` | `%filltext%` |
| Optional block | — | `%fillpart%` | — |

Native macOS Text Replacements support **none** of these.

### 5.2 Template design patterns

- **Cursor placement** — put `{cursor}` where typing resumes (function args, greeting name)
- **Fill-ins for transitory data** — client name, ticket ID, date of meeting; not stored in library
- **Clipboard + AI prompts** — "Review this code: `{clipboard}`" pattern for Cursor/ChatGPT workflows
- **Nested snippets** — small building blocks (`sig-name`, `sig-title`) composed into `;sig`
- **Same fill-in name** — syncs values across fields in one expansion (TextExpander behavior)

---

## 6. Security and Privacy

### 6.1 Data classification for snippets

| Tier | Examples | Storage guidance |
|------|----------|------------------|
| **Public** | Company URL, public GitHub, generic thank-you | Any tool |
| **Personal contact** | Email, phone, home address | Local or E2E encrypted sync; acceptable in native macOS for many users |
| **Sensitive** | API keys, passwords, tokens | Never in expander; use 1Password, env vars |
| **Regulated** | HIPAA PHI, financial account numbers | Fill-ins only; org policies; audit access |

### 6.2 Architectural preferences

1. **Local-first expansion** — Espanso, Typinator local mode, native macOS
2. **Encrypted cloud** — TextExpander at-rest encryption; still avoid secrets in snippets
3. **Client-side redaction** — tools like PII Shield for clipboard before AI paste
4. **Audit trail** — Git history for YAML configs; org admin logs for TextExpander teams
5. **Complex triggers** — reduces accidental expansion of contact data in wrong context

Sources: [Lightning Assist security](https://www.lightning-assist.com/blog/security-best-practices), [TextExpander HIPAA tips](https://textexpander.com/learn/accounts/security/tips-for-configuring-textexpander-for-hipaa), [PII Shield](https://github.com/swissprismia/pii-shield).

---

## 7. Sync, Backup, and Portability

### 7.1 Apple native sync

- Stored in `~/Library/KeyboardServices/TextReplacements.db` (SQLite/Core Data)
- Synced via iCloud across Apple devices signed into same Apple ID
- Legacy mirror: `NSUserDictionaryReplacementItems` in `NSGlobalDomain` (unreliable for writes on recent macOS)
- Apple documents export via plist for backup/share
- Community reports: sync can be delayed, one device can overwrite another, DB corruption may require delete-and-resync

Sources: [Apple Support backup guide](https://support.apple.com/guide/mac-help/back-up-and-share-text-replacements-on-mac-mchl2a7bd795/mac), [Apple Stack Exchange programmatic access](https://apple.stackexchange.com/questions/481528/how-can-i-set-text-replacements-programmatically-in-recent-versions-of-macos).

### 7.2 Developer backup patterns

| Pattern | Mechanism | Best for |
|---------|-----------|----------|
| **Git dotfiles** | Symlink `~/.config/espanso` via Stow/Dotbot | Espanso users, multi-machine devs |
| **Export/import** | CSV, TextExpander format, Raycast export | Migration between tools |
| **JSON snapshot** | `trctl private-list` output in repo | Apple native library audit (careful: contains PII) |
| **1Password inject** | Template files with `op://` refs at build time | Secrets adjacent to but not in snippets |

### 7.3 Import/export matrix

Raycast imports: CSV, TextExpander, aText, Espanso, PhraseExpress.  
TypeSnap imports TextExpander libraries including fill-ins and date macros.  
Espanso has no universal import GUI; migration is often manual or scripted.

---

## 8. macOS Native: Implications for `trctl`

### 8.1 What native replacements are good for

- 5–25 **static, frequently used** strings (email, phone, address, URLs)
- **Cross-device parity** with iPhone/iPad keyboard
- **Zero background process** — no daemon, no Accessibility permission
- **Typo fixes** and ultra-short phrases (`omw`)

### 8.2 What native replacements are bad for

- Formatted email signatures
- Templates with variable fields
- Reliable expansion in VS Code, Terminal, Chrome (varies by app and input field; Slack and native apps generally work)
- Programmatic bulk management via `defaults write` (broken on Sequoia/Tahoe for persistence)
- Team sharing with governance

### 8.3 Where `trctl` fits

| Capability | System Settings | `trctl` |
|------------|-----------------|---------|
| List all replacements | Tedious UI | `private-list` JSON |
| Bulk export | Manual | `private-list` → file |
| Scriptable create/update/delete | No | `private-create/update/delete` |
| CI / dotfiles integration | No | Shell + JSON |
| Read source transparency | No | `read-sources` |
| Schema inspection | No | `db-summary` |
| App Store safe | Yes | No (private API) |

**Recommended positioning:** `trctl` as a **developer harness** for managing the Apple-native layer — backup, bootstrap new machines, lint library conventions, migrate to/from Espanso — not as a consumer-facing expander runtime.

### 8.4 Hybrid workflow (pragmatic)

Run **both** native Apple Text Replacements and Raycast with the **same keywords**:

- **Apple Text Replacements** (`trctl`): iOS sync, Notes, Mail, Slack, Safari
- **Raycast Snippets** (`sync-raycast.sh`): Warp, VS Code, Cursor, Chrome

Raycast **Override System Snippets ON** — Raycast expands on Mac even when Apple has the same keyword. With it OFF, Raycast defers to macOS and Warp gets nothing.

Avoid *different* keywords across layers for the same phrase; duplicate keywords across Apple + Raycast is intentional.

---

## 9. Team Conventions Checklist

When sharing a snippet library (org or open-source dotfiles):

- [ ] Published prefix scheme (e.g. all work snippets start with `;w`)
- [ ] Group README explaining when to use each file/category
- [ ] Labels with searchable keywords (for tools that support them)
- [ ] No secrets in committed files; use private overlay or secret injection
- [ ] Fill-ins for per-instance data, not stored PHI
- [ ] Alias pattern for "official" vs personal trigger preference
- [ ] Regular audit: remove stale URLs, fix typos, dedupe
- [ ] Test expansions in top 5 target apps after changes

---

## 10. Recommendations for This Project

### 10.1 Near-term `trctl` enhancements (aligned with research)

1. **`private-list --format table|json|csv`** — portability toward Raycast/Espanso migration
2. **`private-import` / `private-export`** — JSON round-trip for Git-backed dotfiles
3. **`lint` command** — check prefix conventions, detect prefix collisions, flag http typos, bare-word triggers
4. **`diff`** — compare file snapshot to live system
5. **Redacted export mode** — export structure with masked phrases for sharing convention docs

### 10.2 Suggested convention file for this repo

```yaml
# text-replacements-conventions.yaml (future)
prefix:
  contact: ";"
  links: ";"
  legacy_no_prefix: ["jfb", "jonw", "jons", "omw", "2arb"]
rules:
  - prefer_semicolon_prefix_for_new_entries
  - mnemonic_suffix_over_abbreviation
  - no_bare_english_words
  - shortcut_max_length: 12
groups:
  contact: [email, phone, address]
  links: [url, social, booking]
  work: [acme, exampleco]
```

### 10.3 Research-backed library hygiene for current system

1. Fix `;wlabsw` typo (`htttps` → `https`)
2. Standardize new entries on `;` prefix
3. Consider migrating `2arb` / `;homea` to consistent address format
4. Snapshot library to version control (private repo — contains PII)

---

## 11. Sources

### Official / primary

- [Apple — Back up and share text replacements](https://support.apple.com/guide/mac-help/back-up-and-share-text-replacements-on-mac-mchl2a7bd795/mac)
- [Espanso — Configuration basics](https://espanso.org/docs/configuration/basics/)
- [Espanso — Organizing matches](https://espanso.org/docs/matches/organizing-matches/)
- [Espanso — App-specific configurations](https://espanso.org/docs/configuration/app-specific-configurations/)
- [Raycast — Snippets manual](https://manual.raycast.com/snippets)
- [Raycast — Dynamic placeholders](https://manual.raycast.com/dynamic-placeholders)
- [TextExpander — Abbreviation prefixes experts use](https://textexpander.com/blog/the-abbreviation-prefixes-textexpander-experts-use)
- [TextExpander — 40 tips](https://textexpander.com/blog/textexpander-tips)
- [TextExpander — Organizing snippets](https://textexpander.com/learn/using/organize)
- [TextExpander — HIPAA configuration](https://textexpander.com/learn/accounts/security/tips-for-configuring-textexpander-for-hipaa)
- [TextExpander — Best snippet managers 2026](https://textexpander.com/blog/best-snippet-managers)

### Community / comparative

- [Apple Stack Exchange — programmatic text replacements](https://apple.stackexchange.com/questions/481528/how-can-i-set-text-replacements-programmatically-in-recent-versions-of-macos)
- [Chronoid — Text expander Mac 2026](https://www.chronoid.app/blog/text-expander-mac)
- [PhraseVault — text expander for developers](https://phrasevault.app/help/text-expander-developers)
- [Pixelmatters — Raycast for software engineers](https://www.pixelmatters.com/insights/raycast-for-software-engineers)
- [Lightning Assist — security best practices](https://www.lightning-assist.com/blog/security-best-practices)
- [jimbrig/dotfiles-espanso](https://github.com/jimbrig/dotfiles-espanso) — file-based organization example

### Internal

- `docs/architecture.md` — KeyboardServices / Core Data storage model
- `docs/recommendation.md` — private API viability on macOS 26.5.1

---

## 12. Open Questions

1. **XPC server vs Core Data for reads** — cleaner API boundary vs current working path (`_KSTextReplacementCoreDataStore`)
2. **Export format** — JSON schema stable enough for dotfiles merge workflows?
3. **iOS parity** — can iPhone exports be ingested, or is Mac-only management sufficient?
4. **Conflict resolution** — strategy when iCloud push races with `trctl` bulk import
5. **Lint rules** — which conventions are universal vs personal preference?
