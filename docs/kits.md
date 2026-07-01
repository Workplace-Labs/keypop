# Shareable Snippet Kits

Kit files are JSON arrays of `{ "name", "keyword", "text" }`. The shape matches Raycast export format for easy migration, but this project uses **static text only**.

## File format

```json
[
  {
    "name": "Acme / Email",
    "keyword": ";ace",
    "text": "team@example.com"
  }
]
```

| Field | Required | Apple Text Replacements |
|-------|----------|-------------------------|
| `name` | Recommended | Not stored (label for humans) |
| `keyword` | Yes | Shortcut |
| `text` | Yes | Phrase (plain text only) |

## Workflows

### Export and share

```sh
keypop export --output kits/my-kit.snippets.json
keypop export --prefix ';ac' --output kits/acme-team.snippets.json
```

### Import into Apple Text Replacements

```sh
keypop import kits/acme-team.snippets.json --prefix ';ac' --dry-run
keypop import kits/acme-team.snippets.json --prefix ';ac' --apply --on-conflict skip
```

Requires exactly one of `--dry-run` or `--apply`. `import --apply` backs up affected rows under `private/backups/` first.

### Mac expander

```sh
./scripts/launch-keypop.sh install   # first time
./scripts/launch-keypop.sh restart   # after keypop CRUD changes if hints appear
```

Mutations via `keypop` auto-export to `~/.config/keypop/snippets.json`; `keypop run` watches the directory and reloads automatically (no restart needed when the daemon is healthy).

## Limitations

| Feature | Supported |
|---------|-----------|
| Plain / multi-line text | Yes |
| `{clipboard}`, `{date}`, `{cursor}` | **No** — breaks iOS/keypop parity |
| Snippets over ~2,000 characters | Risky on iOS |
| Rich text | No |

## Kit in this repo

| File | Prefix | Purpose |
|------|--------|---------|
| `kits/prompts-core.snippets.json` | `;p` | Starter AI prompt templates |

Team contact kits (e.g. `kits/acme-team.snippets.json`) should stay local or gitignored.

## Naming

Use descriptive `name` values for browsing kits in git:

```
Acme / Email
Prompt / Code review
```
