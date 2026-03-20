# Agent Skills

Machine-readable skill bundles for WordPress development, PHP engineering, and documentation workflows.

## Purpose

Each skill defines constraints, output expectations, authority sources, and done criteria that an LLM needs to produce work matching Dan Knauss's engineering and editorial standards. Skills are platform-agnostic instruction sets stored as `SKILL.md` files.

## Available Skills

### Priority: PHP Development & Engineering

| Skill | Directory | Focus |
|---|---|---|
| `wp-plugin-development` | [`skills/wp-plugin-development/`](skills/wp-plugin-development/SKILL.md) | Plugin architecture, hooks, security, packaging |
| `wp-phpstan` | [`skills/wp-phpstan/`](skills/wp-phpstan/SKILL.md) | PHPStan configuration, baselines, WordPress typing |
| `wp-rest-api` | [`skills/wp-rest-api/`](skills/wp-rest-api/SKILL.md) | REST routes, controllers, schema, authentication |
| `wp-block-development` | [`skills/wp-block-development/`](skills/wp-block-development/SKILL.md) | Gutenberg blocks, block.json, dynamic rendering |
| `wp-performance` | [`skills/wp-performance/`](skills/wp-performance/SKILL.md) | Profiling, query optimization, caching, cron |
| `wp-wpcli-and-ops` | [`skills/wp-wpcli-and-ops/`](skills/wp-wpcli-and-ops/SKILL.md) | WP-CLI operations, automation, multisite |

### WordPress Theming & Frontend

| Skill | Directory | Focus |
|---|---|---|
| `wp-block-themes` | [`skills/wp-block-themes/`](skills/wp-block-themes/SKILL.md) | theme.json, templates, patterns, Site Editor |
| `wp-interactivity-api` | [`skills/wp-interactivity-api/`](skills/wp-interactivity-api/SKILL.md) | data-wp-* directives, stores, hydration |
| `wpds` | [`skills/wpds/`](skills/wpds/SKILL.md) | WordPress Design System components and tokens |

### Routing & Triage

| Skill | Directory | Focus |
|---|---|---|
| `wordpress-router` | [`skills/wordpress-router/`](skills/wordpress-router/SKILL.md) | Classify repos and route to correct skill |
| `wp-project-triage` | [`skills/wp-project-triage/`](skills/wp-project-triage/SKILL.md) | Deterministic repository inspection reports |

### Documentation & Operations

| Skill | Directory | Focus |
|---|---|---|
| `wordpress-runbook-ops` | [`skills/wordpress-runbook-ops/`](skills/wordpress-runbook-ops/SKILL.md) | Operational runbooks with WP-CLI procedures |
| `wordpress-security-doc-editor` | [`skills/wordpress-security-doc-editor/`](skills/wordpress-security-doc-editor/SKILL.md) | Security documentation with authority hierarchy |
| `security-researcher` | [`skills/security-researcher/`](skills/security-researcher/SKILL.md) | Vendor research briefs with source grounding |

### Specialized APIs

| Skill | Directory | Focus |
|---|---|---|
| `wp-abilities-api` | [`skills/wp-abilities-api/`](skills/wp-abilities-api/SKILL.md) | WordPress Abilities API registration and REST |
| `wp-playground` | [`skills/wp-playground/`](skills/wp-playground/SKILL.md) | WordPress Playground blueprints and local dev |

## Skill Structure

Each skill bundle contains:

```
<skill-name>/
  SKILL.md                       # Authoritative skill definition
  agents/
    claude.yaml                  # Claude Code agent config stub
    openai.yaml                  # OpenAI Codex agent config stub
  references/
    canonical-sources.md         # Source documents this skill references
```

## Eval Harness

The `eval/` directory contains behavioral scenarios (Given/When/Then) that test whether agent output meets skill standards. See [`eval/README.md`](eval/README.md).

## Distribution

The `dist/` directory packages skills for specific editors:

```
dist/
  claude/.claude/skills/         # Claude Code skill format
  codex/.codex/                  # OpenAI Codex format
  cursor/.cursor/                # Cursor rules format
  vscode/.github/                # VS Code Copilot format
```

Run `shared/scripts/build-dist.sh` to generate distribution packages from source skills.

## Usage

### Claude Code
Reference a skill by reading its `SKILL.md` or including it as project context.

### OpenAI Codex
Use the `agents/openai.yaml` config. The `SKILL.md` provides system instructions.

### Other LLMs
The `SKILL.md` is platform-agnostic. Include it as a system prompt in any workflow.

## License

CC BY-SA 4.0
