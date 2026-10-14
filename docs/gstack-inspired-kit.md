# gstack Inspired Kit

This kit distills the useful part of [gstack](https://github.com/garrytan/gstack) into five KeyPop shortcuts under `;gs`.

gstack is a large Claude Code skill suite with browser QA, design tooling, and safety hooks. This kit keeps the part that is a prompt: staged roles that hand off a named artifact and refuse to redo the previous job. It is inspired by that project and is not affiliated with it.

Import it:

```sh
keypop import kits/gstack-inspired.snippets.json --apply --on-conflict skip
```

Start with `;gsoh`.

## When To Use It

Use this kit when a feature needs a product decision before code, and a named gate before a pull request:

- a new product idea
- a scope fight between "bigger" and "smaller"
- an implementation plan that should not reopen product scope
- a diff review that must end in a clear gate
- a pull request that should not ship past a blocked review

Use `;ce` when you want a general product-engineering loop. Use `;ak` when you want inspect, implement, and verify cycles. Use `;ip` when the problem is visual design. This kit does not replace those.

## Shortcuts

| Keyword | Name | Use it for |
|---------|------|------------|
| `;gsoh` | Office Hours | Six forcing questions, then a design brief. No implementation plan. |
| `;gsceo` | CEO Review | Recommend Expand, Selective, or Hold, then wait. Write the product decision only after you choose. |
| `;gslock` | Eng Lock | Turn the product decision into an implementation lock. Reuse what exists. Do not reopen scope. |
| `;gsreview` | Review Gate | Review the diff and end on DONE, DONE_WITH_CONCERNS, BLOCKED, or NEEDS_CONTEXT. No edits. |
| `;gsship` | Ship | Write the PR from an accepted gate. Stop on BLOCKED, missing context, or unaccepted concerns. |

## Suggested Flow

1. `;gsoh`
2. `;gsceo`
3. `;gslock`
4. Implement only after you accept the lock.
5. `;gsreview`
6. `;gsship`

You can start at `;gsreview` on an existing diff. The prompt will say which earlier artifacts are missing and review with what it has.

## What This Kit Leaves Out

gstack's compiled browser, design image generation, security-officer scan, and hook-enforced safety skills are not prompts. Installing gstack is a separate decision. This kit will not drive a browser or block a tool call.

## Design Notes

Each shortcut names the artifact it consumes and the artifact it produces: design brief, product decision, implementation lock, review gate, then the PR note.

The review prompt lists informational findings and does not apply them. Editing during review blurs the gate. Say "fix the informational ones" if you want those changes.
