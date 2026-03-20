---
name: "wp-project-triage"
description: "Produce deterministic WordPress repository triage reports: classify repo type, detect tooling/tests/version indicators, and output structured JSON for workflow routing."
---

# WordPress Project Triage

## Scope

- Use this skill when inspecting a WordPress repository to understand its type, tooling, and health before choosing a workflow.
- Produces a structured report used by other skills and agents to make informed decisions.
- This is an inspection-only skill — it does not modify code.

## Triage Procedure

### 1. Classify Repository Type

Check for these indicators in order:

| Indicator | Classification |
|---|---|
| Plugin header in a PHP file | Plugin |
| `style.css` with `Theme Name:` header | Theme |
| `theme.json` without plugin header | Block theme |
| `block.json` in a standalone directory | Standalone block |
| `wp-config.php` or `wp-settings.php` | WordPress core / site |
| `gutenberg` in repo name or package.json | Gutenberg contributor |
| Multiple plugins in subdirectories | Monorepo / site repo |

### 2. Detect Tooling

| Check | Files |
|---|---|
| PHP dependencies | `composer.json`, `composer.lock` |
| JS dependencies | `package.json`, `package-lock.json` |
| PHP tests | `phpunit.xml*`, `tests/` |
| JS tests | `jest.config*`, `tests/js/`, `*.test.ts` |
| E2E tests | `playwright.config*`, `cypress.config*` |
| Static analysis | `phpstan.neon*`, `psalm.xml` |
| Code standards | `phpcs.xml*`, `.eslintrc*` |
| CI/CD | `.github/workflows/`, `.travis.yml`, `.circleci/` |
| Build system | `webpack.config*`, `@wordpress/scripts` in package.json |
| Agent files | `AGENTS.md`, `CLAUDE.md`, `.claude/` |

### 3. Version Indicators

- PHP version: `composer.json` `require.php`, plugin header `Requires PHP:`
- WordPress version: plugin header `Requires at least:`, `Tested up to:`
- Node version: `.nvmrc`, `package.json` `engines`

### 4. Health Indicators

- Git status: clean/dirty, branch, remote tracking
- Lock file freshness: do lock files exist and are they committed?
- CI status: workflows present and recently passing?
- Test coverage: thresholds configured?
- Baseline files: PHPStan/Psalm baselines committed?

## Output Format

```json
{
    "type": "plugin",
    "name": "my-plugin",
    "php_version": ">=8.0",
    "wp_version": ">=6.2",
    "node_version": "20",
    "tooling": {
        "composer": true,
        "npm": true,
        "phpunit": true,
        "jest": false,
        "playwright": true,
        "phpstan": { "level": "max", "baseline": true },
        "phpcs": "WordPress-Extra",
        "ci": "github-actions"
    },
    "agent_files": ["AGENTS.md", "CLAUDE.md", ".claude/settings.local.json"],
    "health": {
        "git_clean": true,
        "lock_files": true,
        "ci_present": true,
        "coverage_threshold": "63%"
    },
    "route_to": ["wp-plugin-development", "wp-phpstan"]
}
```

## Done Criteria

- Repository type correctly classified.
- All tooling detected and reported.
- Version requirements extracted.
- Health indicators assessed.
- Routing recommendation provided.
