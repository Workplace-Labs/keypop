# Impeccable: Fighting Design Slop in AI Code

This guide outlines the philosophy and workflow for using the Impeccable kit. Its purpose is not just to generate code, but to enforce *taste*—it is the definitive guardrail against the common visual clichés, or "design slop," that plague AI-assisted UI.

## 🛠️ The Philosophy: From Correct to Tasted

Most AI tools focus on generating *correct* code. Impeccable focuses on generating *thoughtful* code. 🧠

The core philosophy here is about **taste and anti-repetition**. AI models have powerful "reflex" patterns: Inter-style components, gradient text, and predictable card layouts. Impeccable overrides these by forcing the model to run internal "AI slop tests." It challenges the model to look past "is it functional?" to answer: *"Does this design feel generic SaaS?"*

## 🏗️ Core Concepts

1.  **Context is King**: The kit is designed to capture your project's identity (brand lane, audience, anti-references) once. By defining this upfront, every subsequent command inherits your specific design language instead of reinventing a default design every time.
2.  **The "Absolute Bans"**: Impeccable actively bans specific visual patterns (side-stripe borders, glassmorphism-as-default, uppercase eyebrows). If the AI slips, it will be caught.
3.  **Depth of Check**: It doesn't just look at aesthetics; it runs technical audits (Accessibility, contrast ratios, clipping issues) that go far beyond standard linting.

## 🚀 The Impeccable Workflow

For the highest quality results, you must treat these kits as sequential steps, not single prompts. The workflow is a cycle of creation, critique, and refinement.

**Recommended Flow:**

1.  **`ip-build`**: Describe the feature or page you want to build. The command will generate shippable code using your project context.
2.  **`ip-critique`**: Paste or describe the UI you want reviewed. This forces a heuristic-scored design review, surfacing generic "SaaS-like" problems that a regular code review would miss.
3.  **`ip-audit`**: Paste or describe the UI or code you want audited. This runs deterministic checks for performance, contrast, and responsiveness.
4.  **`ip-polish`**: Paste or describe the UI you want to ship. This command consumes the backlog from the `critique` and `audit` runs and explicitly fixes them. **It is the step people skip and regret.**
5.  **`ip-de-slop`**: Paste or describe the UI that feels generic. This command forces a re-evaluation against both first-order (category cliché) and second-order (safe alternative cliché) design traps.

## 💡 Pro-Tips for Master Designers

*   **Don't Trust the First Pass**: The `ip-build` output is a draft. Never skip `ip-polish` and `ip-de-slop`.
*   **The Critique-Polish Loop**: Always run `ip-critique` *before* `ip-polish`. The latter literally reads the critique snapshot as its to-do list, making the flow deterministic.
*   **Set Context First**: Use a project-level context definition (like `PRODUCT.md`) before starting any `ip-build` command to ensure the AI is working within your established visual boundaries.

## ⚙️ Maintenance and Evolution

As the tool evolves, the best practice is to keep this guide updated. Treat this document as living code for the kit. If you find new bugs or emerging design patterns, update this guide to reflect the current best practices for *your* design process.
