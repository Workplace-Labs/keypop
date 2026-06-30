# Shareable Kits (Raycast JSON)

Kit files under `kits/` use the **Raycast snippet import/export JSON format**. This is the interchange standard for sharing libraries between Raycast, `trctl`, and teammates.

## File format

A kit is a JSON **array** of objects:

```json
[
  {
    "name": "WL / Email",
    "keyword": ";wle",
    "text": "jon@workplacelabs.io"
  }
]
```

| Field | Required | Stored in Apple Text Replacements? |
|-------|----------|-------------------------------------|
| `name` | Recommended | No — label for Raycast search and kit docs only |
| `keyword` | Yes | Yes — maps to the macOS **shortcut** |
| `text` | Yes | Yes — maps to the macOS **phrase** |

Raycast documentation: [Import & Export](https://manual.raycast.com/import-export), [Snippets](https://manual.raycast.com/snippets).

## Workflows

### Export from your Mac → share or import into Raycast

```sh
swift build
.build/debug/trctl export --output kits/my-kit.raycast.json
.build/debug/trctl export --prefix ';wl' --output kits/wl-team.raycast.json

# Sync all replacements to Raycast after changes:
./scripts/sync-raycast.sh
```

`sync-raycast.sh` exports everything, copies to `~/Desktop/raycast-sync.json`, and opens Raycast Import Snippets.

### Import a kit into Apple Text Replacements (`trctl`)

```sh
.build/debug/trctl import kits/wl-team.raycast.json --prefix ';wl' --dry-run
.build/debug/trctl import kits/wl-team.raycast.json --prefix ';wl' --apply --on-conflict skip
```

`trctl import` accepts **Raycast format only** (`name`, `keyword`, `text`).

### Import from Raycast → edit → apply with `trctl`

1. In Raycast: **Export Snippets** → save JSON
2. Optionally edit `name` / `keyword` / `text` in the file
3. `trctl import <file> --dry-run` then `--apply`

## Limitations

### Apple Text Replacements (`trctl` target)

| Feature | Raycast kit | Apple via `trctl` |
|---------|-------------|-------------------|
| Plain text | Yes | Yes |
| `name` field | Yes | Ignored (not stored in KeyboardServices) |
| Multi-line text | Yes | Yes |
| `{clipboard}`, `{date}`, `{cursor}` | Yes | **No** — imported as literal text unless you strip them |
| Snippets over ~2,000 characters | Yes | **Risky on iOS** — Apple Text Replacement limit |
| Tags | Raycast UI only | **Not in JSON** — use `name` prefixes like `WL / Email` |

### Raycast-specific

- **Team shared snippets:** Raycast may not sync `keyword` across org members — each person sets their own keyword after import. Kits should document the intended `keyword` values.
- **Dual expanders:** Keep the same keywords in both Apple Text Replacements (iOS sync) and Raycast (Warp, VS Code, etc.). Set Raycast **Override System Snippets ON** — with it OFF, Raycast skips conflicting keywords and Warp gets nothing because Apple replacements don't work there. With it ON, Raycast expands on Mac even when Apple has the same keyword.
- **App compatibility:** macOS Text Replacements hook into standard system text fields. They work in most **native** apps (Notes, Mail, Messages, Safari) and in some **Electron** apps (e.g. **Slack**). They often **do not expand** in:
  - **Terminals:** Warp, Terminal.app, iTerm2
  - **Code editors:** VS Code, Cursor
  - **Inconsistent elsewhere:** Chrome and other Chromium browsers (many web inputs), JetBrains in-editor, Obsidian, Notion, Discord — depends on whether the app enables macOS text substitution
  For terminals and editors, run `./scripts/sync-raycast.sh` and set Raycast **Override System Snippets ON**.

### Prompt kits (`;p*` shortcuts)

- Use `;pcr`, `;psum`, etc. (`;p` + task code). See `docs/user-guide.md`.
- Long prompts: fine in Raycast; keep Apple-synced prompts under the iOS size limit or mark Raycast-only in `name`.

## Kit inventory

| File | Prefix | Purpose |
|------|--------|---------|
| `kits/wl-team.raycast.json` | `;wl` | Workplace Labs team contact snippets |
| `kits/prompts-core.raycast.json` | `;p` | Core AI prompts (e.g. `;pcr` code review) |

## Naming kits

Use descriptive `name` values — they are the human label when browsing in Raycast:

```
WL / Email
WL / Website
Prompt / Code review
Prompt / Summarize
```

Keep `keyword` values aligned with `docs/user-guide.md` (letter-only, no dots).
