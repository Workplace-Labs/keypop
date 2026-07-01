# Shareable Kits (Raycast JSON)

Kit files use the **Raycast snippet import/export JSON format** — the interchange standard between Raycast, `trctl`, and teammates.

## File format

A kit is a JSON **array** of objects:

```json
[
  {
    "name": "Acme / Email",
    "keyword": ";ace",
    "text": "team@example.com"
  }
]
```

| Field | Required | Stored in Apple Text Replacements? |
|-------|----------|-------------------------------------|
| `name` | Recommended | No — label for Raycast search only |
| `keyword` | Yes | Yes — maps to the macOS **shortcut** |
| `text` | Yes | Yes — maps to the macOS **phrase** |

Raycast docs: [Import & Export](https://manual.raycast.com/import-export), [Snippets](https://manual.raycast.com/snippets).

## Workflows

### Export from your Mac

```sh
trctl export --output kits/my-kit.raycast.json
trctl export --prefix ';ac' --output kits/acme-team.raycast.json
./scripts/sync-raycast.sh
```

`sync-raycast.sh` exports everything, copies to `~/Desktop/raycast-sync.json`, and opens Raycast Import Snippets.

### Import into Apple Text Replacements

```sh
trctl import kits/acme-team.raycast.json --prefix ';ac' --dry-run
trctl import kits/acme-team.raycast.json --prefix ';ac' --apply --on-conflict skip
```

`trctl import` accepts **Raycast format only** (`name`, `keyword`, `text`). Requires exactly one of `--dry-run` or `--apply`.

### Import from Raycast

1. Raycast → **Export Snippets** → save JSON
2. Edit `name` / `keyword` / `text` if needed
3. `trctl import <file> --dry-run` then `--apply`

## Limitations

### Apple Text Replacements

| Feature | Raycast kit | Apple via `trctl` |
|---------|-------------|-------------------|
| Plain text | Yes | Yes |
| `name` field | Yes | Ignored |
| Multi-line text | Yes | Yes |
| `{clipboard}`, `{date}`, `{cursor}` | Yes | **No** — literal text unless stripped |
| Snippets over ~2,000 characters | Yes | **Risky on iOS** |
| Tags | Raycast UI only | Use `name` prefixes like `Acme / Email` |

### Raycast-specific

- **Override System Snippets ON** when keywords overlap with Apple replacements — otherwise Raycast defers to macOS and Warp gets nothing.
- Terminals and editors: use `./scripts/sync-raycast.sh` after `trctl` changes.

### Prompt kits (`;p*`)

See [user-guide.md](user-guide.md). Keep Apple-synced prompts short; use Raycast for long prompts.

## Kit in this repo

| File | Prefix | Purpose |
|------|--------|---------|
| `kits/prompts-core.raycast.json` | `;p` | Starter AI prompt templates |

Team contact kits (e.g. `kits/acme-team.raycast.json`) should stay local or gitignored — they contain PII.

## Naming kits

Use descriptive `name` values for Raycast search:

```
Acme / Email
Acme / Website
Prompt / Code review
```

Keep `keyword` values letter-only after `;` — see [user-guide.md](user-guide.md).
