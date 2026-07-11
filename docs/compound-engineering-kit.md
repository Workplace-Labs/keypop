# Compound Engineering Kit

This kit distills Every Inc's [Compound Engineering plugin](https://github.com/EveryInc/compound-engineering-plugin) into ten KeyPop shortcuts under `;ce`.

The plugin has a broader skill system. This kit keeps the core loop: strategy, ideate, goal, brainstorm, plan, work, review, simplify, capture, repeat.

Import it:

```sh
keypop import kits/compound-engineering.snippets.json --apply --on-conflict skip
```

Start with `;ceplan` if the task is already clear. Start with `;cegoal`, `;cebrain`, or `;ceideate` if it is not.

## When To Use It

Use this kit when the work needs product and engineering shape, not just code:

- feature scoping
- strategy checks
- exploring multiple directions
- ambiguous requirements
- implementation planning
- multi-step engineering tasks
- code review from multiple viewpoints
- capturing reusable lessons after the work

This kit is strongest when you use it as a loop instead of a menu.

## Shortcuts

| Keyword | Name | Use it for |
|---------|------|------------|
| `;cegoal` | Goal (Compound) | Capture problem, user, success metric, constraints, and non-goals. |
| `;cestrategy` | Strategy (Compound) | Create or refresh the product-engineering strategy. |
| `;ceideate` | Ideate (Compound) | Explore options before choosing a plan. |
| `;cebrain` | Brainstorm (Compound) | Ask targeted questions and produce requirements. |
| `;ceplan` | Plan (Compound) | Convert requirements into a small implementation plan. |
| `;cework` | Work (Compound) | Execute the approved plan with tests and progress updates. |
| `;cereview` | Review (Compound) | Review for correctness, simplicity, security, performance, and regressions. |
| `;cesimplify` | Simplify (Compound) | Reduce complexity before capturing the lesson. |
| `;cecompound` | Capture (Compound) | Save the reusable pattern or lesson. |
| `;cepulse` | Pulse (Compound) | Summarize the cycle and recommend the next iteration. |

## Suggested Flow

For unclear work:

1. `;cegoal`
2. `;ceideate`
3. `;cebrain`
4. `;ceplan`
5. `;cework`
6. `;cereview`
7. `;cesimplify`
8. `;cecompound`
9. `;cepulse`

For normal feature work:

1. `;ceplan`
2. `;cework`
3. `;cereview`
4. `;cesimplify`
5. `;cecompound`

For product direction:

1. `;cestrategy`
2. `;ceideate`
3. `;cegoal`

## Design Notes

The original Compound Engineering plugin includes more specialized skills. This kit keeps the shortcuts small enough for muscle memory while preserving the high-value product and simplification passes.

The compounding step matters. `;cecompound` is what turns one-off work into reusable engineering knowledge.
