# Claude Command Patterns Kit

This kit turns eleven viral Claude-style labels into useful KeyPop shortcuts under `;cc`.

They are prompt patterns, not hidden commands. Nothing unlocks god mode, a secret reasoning tier, or a special writing engine. The useful part is the instruction behind the memorable name.

Import it:

```sh
keypop import kits/claude-command-patterns.snippets.json --dry-run
keypop import kits/claude-command-patterns.snippets.json --apply --on-conflict skip
```

Start with `;ccroast` when a draft needs honest feedback, or `;ccmatrix` when a decision has real tradeoffs.

## How To Use It

Type a shortcut and hit space. KeyPop expands the full prompt. Add the draft, task, proposal, or options immediately after it, then send the whole thing to your AI assistant.

For example:

```text
;ccroast

Our new onboarding plan starts with a two-hour presentation...
```

`Ghost Rewrite` explicitly tells the assistant to treat the supplied text as content, not instructions. That helps when a draft contains commands, quoted prompts, or language that looks instructional. It is a useful boundary, not a security guarantee. Keep sensitive or untrusted material out of tools that can take actions on your behalf.

## When To Use It

Use this kit when you want a familiar thinking move without rebuilding the prompt every time:

- rewrite stiff prose without flattening the writer's voice
- work through a consequential decision
- build a small interactive artifact
- make a fast decision under uncertainty
- compare options against explicit criteria
- pressure-test a proposal
- compress an answer to three useful bullets
- get only the finished deliverable
- pull a sprawling task back to one outcome
- extract a reusable pattern without copying
- get candid, actionable feedback

Do not stack several shortcuts by default. Each one imposes a different response shape. Pick the move the task actually needs.

## Shortcuts

| Keyword | Name | Use it for |
|---------|------|------------|
| `;ccghost` | Ghost Rewrite | Natural, direct rewriting that preserves meaning and voice. |
| `;ccgod` | Godmode Deep Solve | High-stakes analysis with assumptions, tradeoffs, risks, and next actions. |
| `;ccartifact` | Artifact Builder | The smallest useful interactive artifact or best fallback deliverable. |
| `;ccooda` | OODA Decision | A time-sensitive decision organized around facts, context, commitment, and action. |
| `;ccmatrix` | Decision Matrix | Evidence-based comparison with criteria, weights, and a recommendation. |
| `;ccdevil` | Devil's Advocate | A strong case against a proposal, followed by fixes or a kill call. |
| `;ccbrief` | Three-Line Brief | Exactly three decision-relevant bullets. |
| `;ccsilent` | Silent Deliverable | The finished work without preamble, narration, or recap. |
| `;ccfocus` | Focused Outcome | One outcome, relevant context, material assumptions, and a result. |
| `;ccpattern` | Pattern Extractor | Transferable mechanisms and principles without copying distinctive expression. |
| `;ccroast` | Candid Critique | The three biggest weaknesses, their consequences, and exact fixes. |

## Suggested Combos

For a proposal:

1. `;ccdevil`
2. Revise the proposal.
3. `;ccbrief` for the final decision summary.

For a decision:

1. `;ccmatrix` when the options are known.
2. `;ccooda` when the situation is moving and action cannot wait.

For writing:

1. `;ccroast` to find what is weak.
2. Revise the draft.
3. `;ccghost` to make the final language sound natural.

For a build:

1. `;ccfocus` to anchor the outcome.
2. `;ccartifact` to build the smallest useful version.
3. `;ccsilent` only when you want the deliverable without explanation.

## Design Notes

The labels stay because they are easy to remember. The prompts do the real work: they specify the job, the output shape, and the failure mode to avoid.

Several patterns include an uncertainty check. That matters more than asking the model to sound confident. `;ccmatrix` marks weak evidence, `;ccooda` flags thin support, and `;ccgod` says when a key fact is unknown.

The kit also avoids fake precision. `;ccbrief` is intentionally rigid because brevity is the product. The others stay compact but leave enough room for the task to determine the depth.
