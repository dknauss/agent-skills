---
name: cs-philosophy-review
description: "Use for a deeper design or implementation critique grounded in enduring programming wisdom: simplicity first, clarity over cleverness, abstraction restraint, deletion when possible, and explicit tradeoffs."
compatibility: "Platform-agnostic. Works in any repository or language. Best as a design review, refactor review, architecture critique, or post-implementation simplicity pass."
---

# CS Philosophy Review

Use this skill for a first-principles critique of code or design. Apply durable engineering judgment rather than style nitpicks.

## Core questions

Ask these questions explicitly:

1. Is this the simplest solution?
2. Should any code be deleted instead of added?
3. Is the abstraction earning its cost?
4. Did we generalize too early?
5. Would a plainer data structure or control flow solve this better?
6. Is the code easier to explain than the obvious alternative?
7. Does this optimize for clarity over cleverness?

## Review lens

- Prefer obvious code to surprising code.
- Prefer local clarity to framework theater.
- Prefer data shape clarity before abstraction growth.
- Prefer reversible decisions over ornate structure.
- Treat “no code” or “less code” as a serious candidate, not a rhetorical flourish.

## Output

Give a concise review with:

1. **What is good** — the parts that show good taste or restraint
2. **What is too complex** — unnecessary abstraction, indirection, or ceremony
3. **What should change** — the simplest credible improvement
4. **What should maybe be deleted** — any code that may not need to exist

## Tone

- Calm, senior, and unsentimental
- Avoid hero worship and avoid empty aphorisms
- Use programming wisdom as a decision aid, not as ornament
