---
name: "wordpress-router"
description: "Classify WordPress repositories and route tasks to the correct specialist skill based on repo type, file indicators, and task intent."
---

# WordPress Router

## Scope

- Use this skill first when the correct WordPress specialist skill is not obvious.
- Inspects the repository for indicators and routes to the appropriate skill(s).
- Does not perform the actual work — it identifies and hands off.

## Classification Signals

| Signal | Repo Type | Route To |
|---|---|---|
| Plugin header in PHP file | Plugin | `wp-plugin-development` |
| `block.json` | Block plugin/standalone block | `wp-block-development` |
| `theme.json` | Block theme | `wp-block-themes` |
| `style.css` with Theme header | Classic/block theme | `wp-block-themes` |
| `register_rest_route` / `WP_REST_Controller` | REST API | `wp-rest-api` |
| `phpstan.neon` / PHPStan references | Static analysis | `wp-phpstan` |
| WP-CLI commands in scripts/docs | Operations | `wp-wpcli-and-ops` |
| Runbook procedures / `## Procedure Metadata` | Runbook | `wordpress-runbook-ops` |
| `data-wp-*` directives / `@wordpress/interactivity` | Interactivity API | `wp-interactivity-api` |
| `wp_register_ability` | Abilities API | `wp-abilities-api` |
| WordPress Playground blueprint | Playground | `wp-playground` |
| Performance profiling / query optimization | Performance | `wp-performance` |
| Security documentation / CIS controls | Security docs | `wordpress-security-doc-editor` |
| Vendor research / product analysis | Research | `security-researcher` |

## Multi-Signal Repos

Most WordPress plugins will match multiple signals. Route to the primary skill for the current task, not every matching signal.

Example: A plugin repo with `block.json`, REST routes, and `phpstan.neon`:
- Task is "add a new block" → `wp-block-development`
- Task is "fix PHPStan errors" → `wp-phpstan`
- Task is "add a REST endpoint" → `wp-rest-api`

## Routing Rules

1. Match the task description to a skill, not just the repo type.
2. Use the smallest set of skills needed.
3. Announce which skill(s) you are using and why in one short line.
4. If no skill matches, proceed with general WordPress knowledge and state that no specialist skill was invoked.

## Done Criteria

- Correct skill identified and stated.
- Task handed off without performing the work in this skill.
