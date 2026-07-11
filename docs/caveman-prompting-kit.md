# Caveman Prompting Kit

This kit turns Julius Brussee's [`juliusbrussee/caveman`](https://github.com/juliusbrussee/caveman) idea into seven KeyPop shortcuts under `;cm`.

The goal is shorter assistant output, not weaker task context. Keep the problem, files, commands, identifiers, numbers, and acceptance criteria intact. Make the assistant's mouth smaller, not its brain.

Import it:

```sh
keypop import kits/caveman-prompting.snippets.json --apply --on-conflict skip
```

Start with `;cm`.

## When To Use It

Use this kit when answers are getting bloated:

- status updates
- debug reports
- review findings
- verification summaries
- handoffs
- prompt cleanup

Do not use it to strip important context from a task. Newer prompt-compression research suggests output compression can help, but aggressive input compression can make models compensate with longer or worse answers.

## Shortcuts

| Keyword | Name | Use it for |
|---------|------|------------|
| `;cm` | Caveman / Concise | Default high-signal response mode. |
| `;cmtask` | Caveman / Task | Goal, context, constraints, plan, verification. |
| `;cmcompress` | Caveman / Compress | Shorten a prompt without losing commands or acceptance criteria. |
| `;cmdebug` | Caveman / Debug | Symptom, cause, evidence, fix, verify. |
| `;cmreview` | Caveman / Review | Defect-only review findings. |
| `;cmverify` | Caveman / Verify | Short proof of completion. |
| `;cmhandoff` | Caveman / Handoff | Compact session or agent handoff. |

## Suggested Flow

For everyday use:

1. `;cm`

For coding tasks:

1. `;cmtask`
2. `;cmverify`

For debugging:

1. `;cmdebug`
2. `;cmverify`

For reviews:

1. `;cmreview`

## Design Notes

This kit deliberately dropped Lite, Full, and Ultra modes. Three compression personalities are more to remember and rarely better in practice.

The useful pattern is simple: preserve exact technical content, cut filler, and make evidence easy to scan.
