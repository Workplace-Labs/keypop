# Karpathy Agentic Coding Kit

This kit turns agentic coding habits into ten shortcuts under `;ak`.

It is based on Andrej Karpathy's Sequoia Ascent 2026 talk, [`From Vibe Coding to Agentic Engineering`](https://www.youtube.com/watch?v=96jN2OCOfLs). There is not a single official "Karpathy method" repo; this kit adapts the useful parts for serious agentic coding: clear specs, verification loops, agent orchestration, diff review, reusable workflow context, and human judgment.

Import it:

```sh
keypop import kits/karpathy-agentic-coding.snippets.json --apply --on-conflict skip
```

Start with `;akloop`.

## When To Use It

Use this kit when you want an AI coding agent to do more than answer a question:

- inspect the repo before editing
- turn vague intent into acceptance criteria
- work in small implementation loops
- debug from evidence
- improve against a metric
- steer work back on course
- simplify after implementation
- checkpoint long sessions
- review diffs instead of blindly accepting output
- review for drift
- prove the result with checks

This kit is not a replacement for product judgment. It is best when the goal is clear enough that the agent can inspect, implement, test, and report back.

Two ideas from the talk shape the prompts:

- LLMs automate what you can verify. Strong specs and eval loops matter because models are jagged: they can refactor a large codebase and still miss something obvious outside their training or reward circuits.
- Some code should not exist in the Software 3.0 version. Before adding machinery, ask whether the work belongs in deterministic code, an agent instruction, a tool call, or direct model processing.

## Shortcuts

| Keyword | Name | Use it for |
|---------|------|------------|
| `;akinspect` | Inspect (Karpathy) | Map the repo and ask what code really needs to exist. |
| `;akspec` | Spec (Karpathy) | Convert a request into goal, constraints, acceptance criteria, and evals. |
| `;akloop` | Loop (Karpathy) | Run an autonomous inspect-implement-test-review loop. |
| `;akdebug` | Debug (Karpathy) | Find root cause from symptoms, reproduction, and evidence. |
| `;akratchet` | Ratchet (Karpathy) | Improve one verifiable signal at a time. |
| `;aksteer` | Steer (Karpathy) | Re-anchor drift, hidden architecture choices, and old-paradigm code. |
| `;aksimplify` | Simplify (Karpathy) | Remove generated bloat, awkward abstractions, and avoidable code. |
| `;akcheckpoint` | Checkpoint (Karpathy) | Summarize state, decisions, evals, failures, reusable context, and next step. |
| `;akreview` | Review (Karpathy) | Catch drift, generated-code mistakes, security/data issues, and missing evals. |
| `;akverify` | Verify (Karpathy) | Report proof: acceptance criteria, diff review, checks, results, and residual risk. |

## Suggested Flow

For a feature:

1. `;akinspect`
2. `;akspec`
3. `;akloop`
4. `;aksimplify`
5. `;akreview`
6. `;akverify`

For a bug:

1. `;akdebug`
2. `;akloop`
3. `;akverify`

For optimization:

1. `;akratchet`
2. `;akreview`
3. `;akverify`

For a long run:

1. `;aksteer`
2. `;akcheckpoint`
3. `;akverify`

## Design Notes

The kit still avoids many narrow commands. Agentic coding works best when the prompt defines the loop and evidence standard, then lets the agent use the codebase's own structure.

The 2026 agentic engineering framing changes the posture from "trust the output" to "orchestrate and verify." The prompts treat the model as stochastic and uneven: useful enough to delegate implementation, but not reliable enough to skip specs, evals, diff review, or human judgment.

The strongest guardrail is `;akverify`: no claim of completion without acceptance criteria, checks, and a final diff review.
