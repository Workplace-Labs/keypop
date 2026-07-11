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

## Shipped Kits

If you are installing kits for the first time, import one and use it for a day before adding more. The shortcuts are intentionally small, but three agent-workflow kits at once is still a lot of new muscle memory.

| Kit | Prefix | Use it for |
|-----|--------|------------|
| `kits/prompts-core.snippets.json` | `;p` | Starter prompts and common personal snippets |
| `kits/workplace-labs-top5.snippets.json` | `;wl` | Workplace Labs' highest-use AI prompts |
| `kits/workplace-labs-thinking.snippets.json` | `;wl` | Premortems, tradeoffs, assumptions, and decisions |
| `kits/workplace-labs-hr.snippets.json` | `;wl` | HR and people-ops workflows |
| `kits/workplace-labs-dev.snippets.json` | `;wl` | Developer workflows and review prompts |
| `kits/lab-rats.snippets.json` | `;lab` | Adoption prompts with Workplace Labs personality |
| [`kits/karpathy-agentic-coding.snippets.json`](karpathy-agentic-coding-kit.md) | `;ak` | Agentic coding loops with explicit verification |
| [`kits/caveman-prompting.snippets.json`](caveman-prompting-kit.md) | `;cm` | High-signal compressed prompting |
| [`kits/compound-engineering.snippets.json`](compound-engineering-kit.md) | `;ce` | Product-engineering loop from goal to reusable learning |

### Agent Workflow Kits

These three kits are deliberately focused. They are not meant to be imported as one giant "AI best practices" dump.

| Kit | Based on | First shortcut to try | Notes |
|-----|----------|-----------------------|-------|
| `karpathy-agentic-coding` | Andrej Karpathy's Sequoia Ascent 2026 talk, [`From Vibe Coding to Agentic Engineering`](https://www.youtube.com/watch?v=96jN2OCOfLs) | `;akloop` | Best when you want inspect, implement, steer, simplify, checkpoint, and verify in one autonomous loop. |
| `caveman-prompting` | Julius Brussee's `juliusbrussee/caveman` project | `;cm` | Use for shorter assistant output. Do not use it to remove important context from the task. |
| `compound-engineering` | Every Inc's Compound Engineering plugin | `;ceplan` | Best when you want a repeatable engineering cycle: strategy, ideate, plan, work, review, simplify, capture. |

The Caveman kit deserves one extra caveat: newer prompt-compression research suggests output compression is useful, but compressing the user's input too aggressively can make models compensate with longer or worse answers. That is why this kit keeps the task structure intact and mostly asks the assistant to be concise.

## Naming

Use descriptive `name` values for browsing kits in git:

```
Lab Rats / Email
Prompt / Code review
```
