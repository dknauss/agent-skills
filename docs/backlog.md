# Backlog — Candidate Tools & Integrations

External tools and integration ideas worth evaluating for the WordPress agent skills.
Not yet acted on; each entry notes why it matters, where it could plug in, and a next step.

## Block Runner — generated HTML → native Gutenberg blocks + validity gate

- **What:** [`humanmade/block-runner`](https://github.com/humanmade/block-runner) (npm
  `block-runner`, GPL-2.0-or-later, Node 20+). Converts generated/design HTML into real,
  nested, **native** Gutenberg blocks (`wp:cover > wp:columns > wp:buttons`), and validates
  every result against Gutenberg's own `@wordpress/blocks` + `@wordpress/block-library` run
  headless in **jsdom** — no browser, no wp-env, deterministic and CI-friendly. Also exposes
  `validate` and `fix`. Media resolution via a map, WP-CLI, or REST; theme-preset (token)
  mapping with a fidelity ceiling.
- **Why it matters:** the classic failure mode of AI/agent-generated block markup is landing
  as a frozen "Custom HTML" blob or triggering "Attempt Block Recovery" when attribute order,
  classes, nesting, or presets aren't byte-perfect. Their published benchmark: raw LLMs
  hand-writing block markup score 35–73; the same models (GPT-5.5, Opus) *through* block-runner
  score 93–99, across simple and complex sections.
- **Where it could plug in (this repo):**
  - `skills/wp-block-themes` and `skills/wp-block-development` — reference block-runner as the
    recommended path for "generated HTML → valid native blocks," and as a standalone CI/quality
    gate (`block-runner validate "patterns/**/*.html" --strict --json`) instead of hand-authoring
    the block-comment schema (attribute order, `wp-block-*` classes, `var:preset|spacing|40`).
  - Relevant to the **create-a-wp-site** marketplace skill (separate repo): its
    description→block-theme generation emits pattern/template markup that block-runner could
    convert and prove editor-valid — likely the biggest quality unlock.
- **Caveats:** early (v0.5.0); one-directional (HTML→blocks); full media resolution to real
  attachment IDs needs a WP instance (WP-CLI/REST), though the validity gate is standalone;
  jsdom is a validity check, not a pixel render; the "hand the hardest layouts to an LLM" path
  is flagged experimental.
- **Next step if pursued:** run `block-runner convert` on a couple of generated patterns,
  confirm the jsdom validity gate slots into CI, then decide whether to (a) add a reference in
  the block skills, and/or (b) propose it into the create-a-wp-site generation pipeline.

*Noted 2026-08-02 (surfaced while reviewing a local `block-runner-main.zip`).*
