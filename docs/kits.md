# Shareable Snippet Kits

Kit files are JSON arrays of `{ "name", "keyword", "text" }`. The shape matches Raycast export format for easy migration, but this project uses **static text only**.

## File format

```json
[
  {
    "name": "Lab Rats / Email",
    "keyword": ";labe",
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
keypop export --prefix ';lab' --output kits/lab-rats.snippets.json
```

### Import into Apple Text Replacements

```sh
keypop import kits/lab-rats.snippets.json --prefix ';lab' --dry-run
keypop import kits/lab-rats.snippets.json --prefix ';lab' --apply --on-conflict skip
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

Team contact kits with PII should stay local or gitignored.

## Naming

Use descriptive `name` values for browsing kits in git:

```
Lab Rats / Email
Prompt / Code review
```
