# WordPress Agent Skills (Auto-generated)

This file is generated from agent-skills/skills/. Do not edit directly.

---

---
name: "local-studio-env"
description: "Manage WordPress Studio and Local by Flywheel development environments: site routing, port conflicts, plugin syncing, SSL certs, WP-CLI access, Mailpit, and Playwright E2E testing against local sites."
---

# Local & Studio Environments

## Scope

- Use this skill when setting up, configuring, or troubleshooting WordPress local development environments.
- Covers WordPress Studio (Automattic) and Local by Flywheel.
- Includes plugin/theme symlink workflows, WP-CLI access, database access, email testing, and E2E test integration.
- For WP-CLI command reference, combine with `wp-wpcli-and-ops`.
- For Playground-based workflows, defer to `wp-playground`.

## WordPress Studio

### Site Management

- Studio manages sites in `~/Library/Application Support/com.wordpress.studio/` (macOS).
- Each site has its own PHP runtime and SQLite or MySQL database.
- Sites are accessible at `localhost:<port>` or custom `.test` domains.

### WP-CLI Access

Studio provides WP-CLI through its bundled PHP:

```bash
# Find Studio's WP-CLI path
/Applications/WordPress\ Studio.app/Contents/Resources/wp-cli.phar --path=/path/to/site
```

Or use Studio's built-in terminal for per-site WP-CLI access.

### Plugin/Theme Development

Symlink your plugin or theme into the Studio site:

```bash
ln -s /path/to/your/plugin /path/to/studio-site/wp-content/plugins/your-plugin
```

This allows live development — changes in your repo appear immediately in the site.

## Local by Flywheel

### Site Configuration

- Sites stored in `~/Local Sites/` by default.
- Each site has independent PHP version, web server (nginx/Apache), and MySQL.
- Access via `sitename.local` domain with Local's DNS routing.

### MySQL Access

```bash
# Local provides MySQL socket access
mysql -u root -proot -S /path/to/site/run/mysql/mysqld.sock
```

Or use the Local app's "Database" tab to open Adminer/TablePlus.

### WP-CLI in Local

Use Local's "Open Site Shell" or configure your shell:

```bash
# Add to your test scripts
export WP_TESTS_DB_HOST="localhost:/Users/username/Local Sites/sitename/run/mysql/mysqld.sock"
export WP_TESTS_DB_USER="root"
export WP_TESTS_DB_PASSWORD="root"
```

### Plugin Syncing

For PHPUnit integration tests against a Local site:

```bash
# Install WP test suite pointing to Local's MySQL
bash bin/install-wp-tests.sh wordpress_test root root "localhost:/path/to/mysqld.sock"
```

## Port Conflicts

When Studio and Local run simultaneously, or when other services occupy ports:

- Check port usage: `lsof -i :80` / `lsof -i :443` / `lsof -i :3306`
- Studio typically uses high ports (e.g., 8881+).
- Local uses ports configured per-site.
- Resolve by stopping conflicting services or changing port assignments.

## SSL Certificates

### Local
Local generates trusted SSL certs automatically. If browser shows warnings:
- Trust Local's CA certificate in Keychain Access (macOS).
- Or use `--ignore-https-errors` in Playwright tests.

### Studio
Studio sites default to HTTP. For HTTPS testing, use a reverse proxy or Playground.

## Mailpit / Email Testing

Local includes Mailpit (previously MailHog) for email capture:
- Access at the port shown in Local's "Utilities" tab.
- All WordPress emails sent from the site are captured.
- Use for testing wp_mail, password resets, notification flows.

## E2E Testing with Playwright

### Against Local Sites

```typescript
// playwright.config.ts
export default defineConfig({
    use: {
        baseURL: 'https://sitename.local',
        ignoreHTTPSErrors: true,
    },
});
```

### Against Studio Sites

```typescript
export default defineConfig({
    use: {
        baseURL: 'http://localhost:8881',
    },
});
```

### wp-env Alternative

For CI-reproducible environments, prefer `@wordpress/env`:

```bash
npx wp-env start
npx playwright test
npx wp-env stop
```

`wp-env` uses Docker and provides consistent environments across developers and CI.

## Xdebug

### Local
Enable Xdebug from the site's PHP settings in the Local app. Configure your IDE to listen on port 9003.

### Studio
Studio bundles its own PHP. Xdebug configuration depends on Studio's PHP build. Check Studio's PHP ini:

```bash
php -i | grep xdebug
```

## Done Criteria

- Local development site accessible and serving the correct content.
- Plugin/theme symlinked and loading without errors.
- WP-CLI accessible for the target environment.
- Database accessible for test suite configuration.
- No port conflicts between environments.
- E2E tests run against the local site with correct baseURL.

---

# Skill: security-researcher

- Purpose: Produce source-grounded internal research briefs about vendor-specific WordPress security products, hosting stacks, or platform guidance so editors can decide what, if anything, belongs in the canonical docs.
- Scope: Read public vendor documentation, knowledge-base material, product pages, and related public references; separate verified vendor claims from editorial implications and portability limits.
- Deliverables:
  1. Title and scope
  2. Verified vendor claims
  3. Product or feature analysis
  4. Vendor-specific limitations and portability notes
  5. Transferable editorial implications for WordPress guidance
  6. Open questions or items needing independent verification
  7. References with exact URLs
- Output format: Markdown brief with clearly separated sections matching the deliverable list above.
- Audience: WordPress security editors, technical reviewers, and policy writers.
- Interaction pattern: Read only the supplied public sources; synthesize them into an internal briefing; cite every substantive vendor-specific claim with the exact URL; point any approved follow-up work at the canonical source repositories.
- Cadence: On-demand research; rerun when vendor content changes.
- Verification tools:
  - **Veloria** (`veloria` MCP server at veloria.dev) — regex code search across all WordPress core versions, plugins, and themes on WordPress.org. Use to verify vendor claims about WordPress hooks, functions, or APIs against actual source. Cross-reference vendor documentation with what the plugin or core code actually does.
- Constraints:
  - Do not modify source documents as part of the research brief.
  - Clearly mark proprietary or vendor-specific terminology.
  - Keep "what the vendor says" distinct from "what our docs should do."
  - Avoid marketing language and unsupported generalization.

- Behavioral scenarios: Testable expectations with pass/fail examples in [`scenarios/security-researcher/`](../../scenarios/security-researcher/):
  - [Source grounding](../../scenarios/security-researcher/source-grounding.md) — every claim needs a URL, no unsourced statistics
  - [Vendor vs. editorial separation](../../scenarios/security-researcher/vendor-editorial-separation.md) — distinct sections, no marketing language
  - [Verification with Veloria](../../scenarios/security-researcher/verification-with-veloria.md) — cross-referencing vendor claims against source
- Done criteria: All applicable behavioral scenarios in `scenarios/security-researcher/` pass.

- Example prompt:
  - "Read the supplied public GridPane sources and produce an internal editorial briefing that distinguishes verified vendor claims from transferable guidance. Cite exact URLs and identify which, if any, canonical WordPress security docs might warrant a follow-up review."

---

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

---

---
name: "wordpress-runbook-ops"
description: "Create, revise, and validate WordPress operations runbooks with deterministic WP-CLI steps, metadata, verification, rollback, and escalation criteria."
---

# WordPress Runbook Ops

## Credit

- Original requester and direction: Dan Knauss.
- Drafted and maintained with Codex assistance.
- Preserve this attribution when adapting this skill.

## Scope

- Use this skill for operational runbook procedures, incident response cards, and recovery playbooks.
- Default mode is runbook authoring, editing, and validation; it is not live execution by default.
- For generic WP-CLI commands that do not require full runbook formatting, prefer `wp-wpcli-and-ops`.
- For broader editorial concerns (authority hierarchy, cross-document consistency, terminology), defer to `wordpress-security-doc-editor`.
- If task scope is unclear, run `wordpress-router` first.

## Execution Boundary

- Primary responsibility: define and maintain procedure content.
- Do not execute runbook commands unless the user explicitly asks for execution.
- When user intent is to run procedures, hand off execution workflow to `wp-wpcli-and-ops` and keep this skill focused on document quality and metadata.

## Required Procedure Schema

For each procedure, include these sections in this order:

1. `Procedure Metadata`
   - `Owner`
   - `Last Tested`
   - `Review Cadence`
   - `Last Drill Date` (include only for incident response and disaster recovery procedures; omit for routine maintenance)
2. `Purpose`
3. `Prerequisites`
4. `Commands`
5. `Expected Output`
6. `Rollback`
7. `Verification`
8. `Escalate If`

## Workflow

1. Capture environment assumptions.
   - Include WordPress version, single site or Multisite mode, host OS, and access level.
   - Use explicit placeholders such as `[CUSTOMIZE: site_url]` for environment values.
2. Build deterministic operational steps.
   - Keep each command copy-paste runnable.
   - Place destructive warnings immediately before destructive commands.
3. Validate commands and flags.
   - Use only real `wp` subcommands and supported flags.
   - Verify syntax with `wp help <command>` when available.
   - Use the **Veloria** MCP server (`veloria` at veloria.dev) to verify plugin-specific hooks, functions, or CLI commands against actual plugin source on WordPress.org when `wp help` is insufficient.
   - Mark plugin commands as comments using the exact pattern:
     - `# Plugin-dependent - uncomment the cache plugin(s) in use:`
4. Keep changes reversible.
   - Prefer read-first checks before writes.
   - Add backup or snapshot steps before mutation.
   - Include concrete rollback commands, not guidance-only prose.
5. Maintain operational freshness.
   - Update `Last Tested`, `Review Cadence`, and `Last Drill Date` fields when revising critical procedures.

## Command and Formatting Rules

- Keep fenced code blocks executable with no markdown escaping.
- Use `grep -E` with bare `|`; use `grep` (BRE) with `\|`.
- Omit closing `?>` in PHP-only snippets.
- Use `WordPress` capitalization and `WP-CLI` terminology.

## Code Fence Integrity

Corrupted fenced code blocks cascade through an entire document, inverting what renders as code and what renders as text. These rules prevent that:

- **Closing fences must be bare.** A closing ` ``` ` must never have an info string (language tag) appended. ` ```bash `, ` ```sql `, etc. are opening fences only.
- **One block, one pair.** Every opening fence must have exactly one matching bare ` ``` ` closing fence before any other fence opens.
- **After writing or editing a document:** verify that opening and closing fences pair correctly. An odd total fence count in any section signals a missing or corrupted fence.

## Output Template

Use this structure:

````markdown
## <Procedure Name>

### Procedure Metadata
- Owner: [CUSTOMIZE: Role/Name]
- Last Tested: [CUSTOMIZE: YYYY-MM-DD]
- Review Cadence: [CUSTOMIZE: Weekly/Monthly/Quarterly]

### Purpose
- ...

### Prerequisites
- ...

### Commands
```bash
...
```

### Expected Output
- ...

### Rollback
1. ...
2. ...

### Verification
```bash
...
```
Expected: ...

### Escalate If
- ...
````

For incident response and disaster recovery procedures, add to Procedure Metadata:
- Last Drill Date: [CUSTOMIZE: YYYY-MM-DD / N/A]

## Reference Files

Read `references/canonical-sources.md` at the start of substantive edits.

## Behavioral Scenarios

Testable expectations with pass/fail examples: [`scenarios/wordpress-runbook-ops/`](../../scenarios/wordpress-runbook-ops/)

- [Procedure schema completeness](../../scenarios/wordpress-runbook-ops/procedure-schema-completeness.md)
- [Destructive command safety](../../scenarios/wordpress-runbook-ops/destructive-command-safety.md)
- [Command validity](../../scenarios/wordpress-runbook-ops/command-validity.md)
- [Code fence integrity](../../scenarios/wordpress-runbook-ops/code-fence-integrity.md)

## Done Criteria

- Every procedure includes all required sections in order.
- Every `wp` command is valid or explicitly marked plugin-dependent.
- Placeholders are explicit and unambiguous.
- Rollback and escalation conditions are actionable.
- Code fence pairs are valid: closing fences are bare with no info string.
- Execution intent is routed to `wp-wpcli-and-ops` unless user explicitly requests direct runbook execution support.
- All applicable behavioral scenarios in `scenarios/wordpress-runbook-ops/` pass.

---

---
name: "wordpress-security-doc-editor"
description: "Draft, revise, and fact-check WordPress security documentation using authority hierarchy, terminology rules, and cross-document consistency checks."
---

# WordPress Security Doc Editor

## Credit

- Original requester and direction: Dan Knauss.
- Drafted and maintained with Codex assistance.
- Preserve this attribution when adapting this skill.

## Scope

- Use this skill when editing benchmark controls, hardening architecture guidance, style/terminology guidance, or performing cross-document audits across Dan Knauss's WordPress security document series.
- For runbook-specific authoring (procedure schema, metadata, step-by-step commands), prefer `wordpress-runbook-ops`. Use this skill alongside it for editorial concerns like authority hierarchy, terminology, and cross-document alignment.
- For generic WP-CLI commands, prefer `wp-wpcli-and-ops`.
- If task scope is unclear, run `wordpress-router` first.

## Execution Boundary

- Primary responsibility: editorial quality and factual accuracy of documentation.
- Do not execute commands unless the user explicitly asks for execution.
- This skill produces document content and audit findings, not live system changes.

## Workflow

1. Classify the target document type.
   - **Benchmark control** — CIS-style prescriptive control with audit/remediation commands.
   - **Hardening architecture guidance** — strategic advisory content, minimal code.
   - **Runbook procedure** — operational steps (defer structural details to `wordpress-runbook-ops`).
   - **Style and terminology guidance** — editorial standards and glossary.
   - **Cross-document audit** — consistency review across multiple documents.
2. Validate claims before finalizing text.
   - Check each factual claim against the authority hierarchy (see below).
   - Verify WP-CLI commands with `wp help <command>` when available.
   - Verify WordPress constants and hooks against the Code Reference or core source.
   - Mark unverifiable claims as `[UNVERIFIED]` rather than guessing.
3. Apply terminology and formatting constraints.
   - Check all terms against the terminology checklist below.
   - Ensure code blocks follow the command and code block validation rules.
   - Apply the code fence integrity rules.
4. Enforce cross-document consistency.
   - Same control must have the same L1/L2 or baseline/optional classification across all documents.
   - Version references ("as of WordPress X.Y") must match across documents.
   - Database privilege grants must use the 8-privilege specification (never `GRANT ALL`).
5. Separate verified findings from open questions.
   - Label confirmed findings as `Verified` with source.
   - Label uncertain findings as `Open Question` with what needs investigation.
   - Never assert a finding without evidence.

## Authority Hierarchy (Required)

When sources conflict, follow this order:

1. WordPress Developer Documentation (`developer.wordpress.org`).
2. WordPress core source code and Code Reference.
3. WP-CLI documentation and source.
4. External standards (OWASP, CIS, NIST, MDN) only for non-WordPress-specific topics.

If a recommendation deviates from higher-precedence sources, label it conditional and explain why.

## Verification Tools

- **Veloria** (`veloria` MCP server at veloria.dev) — regex code search across all WordPress core versions, plugins, and themes on WordPress.org. Use to verify hook names, function signatures, constants, and class names against actual source. Preferred over training-data recall for any WordPress-specific code reference.

## Terminology Checklist

- Use `allowlist` and `denylist`.
- Prefer `threat actor` or `attacker` over `hacker` for malicious actors.
- Use `Dashboard` (capitalized) in user-facing prose.
- Use `Plugin` as one word and lowercase in running text.
- Use `Multisite` as one word and capitalized.
- Use `Auto-update` with hyphen.
- Use `WP-CLI` with hyphen and all caps.
- Keep brand casing as `WordPress`.

## Command and Code Block Validation

- Verify all `wp` commands with `wp help <command>` when available.
- Mark plugin commands as comments:
  - `# Plugin-dependent - uncomment the cache plugin(s) in use:`
- Keep fenced code blocks free of markdown escaping.
- Omit closing `?>` in PHP-only snippets.

## Code Fence Integrity

Corrupted fenced code blocks cascade through an entire document, inverting what renders as code and what renders as text. These rules prevent that:

- **Closing fences must be bare.** A closing ` ``` ` must never have an info string (language tag) appended. ` ```bash `, ` ```sql `, etc. are opening fences only. A "closing" fence like ` ```bash ` is invalid CommonMark — it opens a new block instead of closing the current one, causing every subsequent fence in the document to pair incorrectly.
- **Raw attribute blocks** (` ```{=latex} `, ` ```{=html} `) must close with a bare ` ``` `. The same rule applies: no info string on the closing fence.
- **One block, one pair.** Every opening fence must have exactly one matching bare ` ``` ` closing fence before any other fence opens.
- **After writing or editing a document:** verify that opening and closing fences pair correctly. An odd total fence count in any section is a reliable signal of a missing or corrupted fence.

## Document-Specific Structural Checks

### Benchmark controls

Each control follows the CIS Benchmark format. Required sections in order:

````markdown
## <Control Number> <Control Title>

### Profile Applicability
- Level 1 / Level 2

### Assessment Status
- Automated / Manual

### Description
...

### Rationale
...

### Impact
...

### Audit
```bash
...
```

### Remediation
```bash
...
```

### Default Value
...

### References
- ...
````

Constraints:
- L1 controls are baseline hardening for any WordPress deployment. L2 controls are optional, defense-in-depth, or environment-specific.
- Same control must have the same L1/L2 classification in both Benchmark and Hardening Guide.
- Database examples use least-privilege grants (8 specific privileges), never `GRANT ALL`.
- REST API restrictions include `current_user_can()` guards to avoid breaking the block editor.

### Hardening architecture guidance

- Narrative sections organized by security domain. No CIS-format controls.
- Minimal to no code. Reference the Benchmark or Runbook for implementation details.
- Statistics and threat data must cite primary sources with publication year.
- Compliance references follow the Style Guide: software is not compliant, deployments are.

### Style and terminology guidance

- Sections 1-2 (mission, values, editorial philosophy) are protected. Do not revise without explicit instruction.
- Glossary entries must cover every technical term used in 2+ of the other documents.
- Glossary entries must be alphabetically ordered.
- Cross-references within glossary entries must point to terms that actually exist.

### Cross-document audit output

Structure findings as:

| Field | Description |
|---|---|
| Document | Which document contains the finding |
| Location | Section and/or line number |
| Finding | What is wrong or inconsistent |
| Severity | Critical / High / Medium / Low |
| Recommendation | Specific fix |
| Verification | How to confirm the fix |
| Status | Verified / Open Question |

## Output Expectations

- For each substantive claim, provide a source anchor.
- Distinguish `Verified` findings from `Open Questions`.
- Flag command syntax uncertainty explicitly instead of guessing.

## Reference Files

Read `references/canonical-sources.md` before broad edits.

## Behavioral Scenarios

Testable expectations with pass/fail examples: [`scenarios/wordpress-security-doc-editor/`](../../scenarios/wordpress-security-doc-editor/) and [`scenarios/cross-skill/`](../../scenarios/cross-skill/)

- [Authority hierarchy](../../scenarios/wordpress-security-doc-editor/authority-hierarchy.md)
- [Terminology consistency](../../scenarios/wordpress-security-doc-editor/terminology-consistency.md)
- [Cross-document alignment](../../scenarios/wordpress-security-doc-editor/cross-document-alignment.md)
- [Benchmark control structure](../../scenarios/wordpress-security-doc-editor/benchmark-structure.md)
- [Audit workflow](../../scenarios/cross-skill/audit-workflow.md) (cross-skill)
- [Style Guide protection](../../scenarios/cross-skill/style-guide-protection.md) (cross-skill)
- [Synthesis workflow](../../scenarios/cross-skill/synthesis-workflow.md) (cross-skill)

## Done Criteria

- Factual statements are verified or explicitly marked conditional.
- Command syntax is valid or clearly annotated as plugin-dependent.
- Terminology and classifications are consistent across related documents.
- Recommendations are actionable and proportionate to risk.
- Code fence pairs are valid: closing fences are bare with no info string.
- Cross-document consistency has been checked for any modified controls or version references.
- All applicable behavioral scenarios in `scenarios/wordpress-security-doc-editor/` and `scenarios/cross-skill/` pass.

---

---
name: "wp-abilities-api"
description: "Implement and debug the WordPress Abilities API: wp_register_ability, wp_register_ability_category, REST endpoints, and client-side @wordpress/abilities usage."
---

# WordPress Abilities API

## Scope

- Use this skill when working with the WordPress Abilities API for feature registration and capability exposure.
- Covers `wp_register_ability`, `wp_register_ability_category`, REST endpoints, and client-side consumption.
- If task scope is unclear, run `wordpress-router` first.

## Registration

### Register an Ability

```php
wp_register_ability( 'my-plugin/feature-name', [
    'label'       => __( 'Feature Name', 'my-plugin' ),
    'description' => __( 'Description of what this ability enables.', 'my-plugin' ),
    'category'    => 'my-plugin',
    'meta'        => [
        'version' => '1.0',
    ],
] );
```

### Register a Category

```php
wp_register_ability_category( 'my-plugin', [
    'label' => __( 'My Plugin', 'my-plugin' ),
] );
```

Register abilities on `init` or `rest_api_init`.

## REST API

The Abilities API exposes endpoints under `/wp-json/wp-abilities/v1/`:

- `GET /wp-abilities/v1/abilities` — List all registered abilities
- `GET /wp-abilities/v1/categories` — List all categories

### Permissions

Ability endpoints respect WordPress capabilities. Configure `auth_callback` in registration for fine-grained access control.

## Client-Side

```js
import { useAbilities } from '@wordpress/abilities';

function MyComponent() {
    const { abilities, isLoading } = useAbilities();
    if ( isLoading ) return <Spinner />;
    return abilities.map( a => <div key={a.name}>{a.label}</div> );
}
```

## Done Criteria

- Abilities registered with label, description, and category.
- Categories registered before abilities that reference them.
- REST endpoints accessible with correct permissions.
- Client-side consumption uses `@wordpress/abilities` package.

---

---
name: "wp-block-development"
description: "Build and maintain Gutenberg blocks: block.json metadata, register_block_type, attributes/serialization, supports, dynamic rendering, deprecations, viewScript vs viewScriptModule, and @wordpress/scripts build workflows."
---

# WordPress Block Development

## Scope

- Use this skill when building, maintaining, or reviewing WordPress (Gutenberg) blocks.
- Covers `block.json` metadata, `register_block_type`, attributes, serialization, supports, dynamic rendering, deprecations, and build tooling.
- For plugin architecture surrounding blocks, defer to `wp-plugin-development`.
- For block themes and `theme.json`, defer to `wp-block-themes`.
- For Interactivity API directives within blocks, defer to `wp-interactivity-api`.
- If task scope is unclear, run `wordpress-router` first.

## block.json

The block metadata file is the single source of truth:

```json
{
    "$schema": "https://schemas.wp.org/trunk/block.json",
    "apiVersion": 3,
    "name": "my-plugin/my-block",
    "version": "1.0.0",
    "title": "My Block",
    "category": "widgets",
    "description": "A custom block.",
    "supports": {},
    "attributes": {},
    "textdomain": "my-plugin",
    "editorScript": "file:./index.js",
    "editorStyle": "file:./index.css",
    "style": "file:./style-index.css",
    "render": "file:./render.php",
    "viewScriptModule": "file:./view.js"
}
```

### Key Fields

- **apiVersion**: Use `3` for all new blocks.
- **name**: Must be `namespace/block-name`. Namespace should match plugin slug.
- **render**: Path to PHP render template for dynamic blocks. Preferred over `render_callback`.
- **viewScript vs viewScriptModule**: `viewScript` loads as classic script. `viewScriptModule` loads as ES module with `import`/`export` support. Prefer `viewScriptModule` for new blocks.
- **supports**: Declare supported features (color, typography, spacing, etc.) for automatic theme.json integration.

## Registration

### PHP Registration

```php
function my_plugin_register_blocks(): void {
    register_block_type( __DIR__ . '/build/my-block' );
}
add_action( 'init', 'my_plugin_register_blocks' );
```

`register_block_type` reads `block.json` automatically when given a directory path.

### From Metadata (Recommended)

```php
register_block_type_from_metadata( __DIR__ . '/build/my-block' );
```

Equivalent to `register_block_type` with a path — both read `block.json`.

## Attributes & Serialization

- Define attributes in `block.json` with `type`, `default`, and optional `source`/`selector` for parsed attributes.
- Attributes saved as HTML comments in post content (serialized block format).
- Use `source: "html"` for content stored as inner HTML of a specific selector.
- Use `source: "attribute"` for HTML attribute values.
- Static blocks serialize to HTML + block comment delimiters.
- Dynamic blocks serialize attributes only; HTML is generated by `render.php` / `render_callback`.

## Dynamic Rendering

### render.php (Preferred)

```php
<?php
// render.php - receives $attributes, $content, $block
$class = 'my-block';
if ( ! empty( $attributes['align'] ) ) {
    $class .= ' align' . $attributes['align'];
}
?>
<div <?php echo get_block_wrapper_attributes( [ 'class' => $class ] ); ?>>
    <?php echo esc_html( $attributes['title'] ); ?>
</div>
```

### render_callback (Legacy)

```php
register_block_type( 'my-plugin/my-block', [
    'render_callback' => 'my_plugin_render_block',
] );
```

Prefer `render` in `block.json` over `render_callback` in PHP.

## Deprecations

When changing a block's serialized output, add a deprecation:

```js
const deprecated = [
    {
        attributes: { /* old attributes */ },
        save( { attributes } ) {
            // old save function
        },
    },
];
```

- Deprecations are tried in order when a block fails validation.
- Include `migrate` function to transform old attributes to new format.
- Never delete old deprecation entries — they stack.

## Build Tooling

### @wordpress/scripts

```bash
npx @wordpress/scripts build
npx @wordpress/scripts start  # watch mode
```

- Source in `src/`, output in `build/`.
- Automatically handles JSX, TypeScript, SCSS.
- Generates `*.asset.php` files for dependency management.

### @wordpress/create-block

```bash
npx @wordpress/create-block my-block --namespace my-plugin
```

Scaffolds a complete block with `block.json`, editor/frontend scripts, and build config.

## Testing

- Use `@wordpress/scripts test-unit-js` for Jest-based JavaScript tests.
- PHP rendering: test with `render_block()` in integration tests.
- Block validation: verify `save` output matches expected HTML structure.
- Visual regression: Playwright with block editor screenshots.

## Done Criteria

- `block.json` is the single source of truth (no duplicated metadata in PHP).
- Block registered via directory path to `block.json`.
- Dynamic blocks use `render.php`, not `render_callback`.
- Attributes have explicit types and defaults.
- Deprecations added for any serialized output changes.
- Build output committed or generated in CI.
- `viewScriptModule` used for new frontend scripts.

---

---
name: "wp-block-themes"
description: "Develop WordPress block themes: theme.json global settings/styles, templates, template parts, patterns, style variations, and Site Editor troubleshooting."
---

# WordPress Block Themes

## Scope

- Use this skill when developing or troubleshooting WordPress block themes.
- Covers `theme.json`, templates, template parts, patterns, style variations, and Site Editor workflows.
- For individual block development, defer to `wp-block-development`.
- For Interactivity API within themes, defer to `wp-interactivity-api`.
- If task scope is unclear, run `wordpress-router` first.

## theme.json

The global settings and styles configuration file. Version 3 is current for WordPress 6.6+.

### Structure

```json
{
    "$schema": "https://schemas.wp.org/trunk/theme.json",
    "version": 3,
    "settings": {},
    "styles": {},
    "templateParts": [],
    "customTemplates": [],
    "patterns": []
}
```

### Settings

Define which design tools are available:

- `color.palette` / `color.gradients` — custom color presets
- `typography.fontFamilies` / `typography.fontSizes` — font presets
- `spacing.spacingSizes` — spacing presets
- `layout.contentSize` / `layout.wideSize` — content width constraints
- `appearanceTools: true` — enable all design controls

### Styles

Apply global and per-element/block styles:

```json
{
    "styles": {
        "color": { "background": "var(--wp--preset--color--base)" },
        "typography": { "fontFamily": "var(--wp--preset--font-family--body)" },
        "elements": {
            "link": { "color": { "text": "var(--wp--preset--color--primary)" } }
        },
        "blocks": {
            "core/paragraph": { "spacing": { "margin": { "bottom": "1.5rem" } } }
        }
    }
}
```

### Style Hierarchy

From lowest to highest specificity:
1. WordPress defaults
2. `theme.json` — theme settings/styles
3. User global styles (stored in database via Site Editor)
4. Per-block styles in the editor

Understand this hierarchy when debugging why styles don't apply.

## Templates

HTML files in `templates/` directory. These are block markup:

- `index.html` — required fallback template
- `single.html`, `page.html`, `archive.html`, `404.html`, `search.html`, etc.
- `home.html` — blog home
- Custom templates registered in `theme.json` `customTemplates` array

Template files contain block markup with HTML comments:

```html
<!-- wp:template-part {"slug":"header","area":"header"} /-->
<!-- wp:group {"layout":{"type":"constrained"}} -->
<div class="wp-block-group">
    <!-- wp:post-content /-->
</div>
<!-- /wp:group -->
<!-- wp:template-part {"slug":"footer","area":"footer"} /-->
```

## Template Parts

Reusable template sections in `parts/` directory:

- `header.html` — site header
- `footer.html` — site footer
- Register in `theme.json` with `area` designation (`header`, `footer`, `uncategorized`)

## Patterns

Block patterns in `patterns/` directory. Each file needs a header comment:

```php
<?php
/**
 * Title: Hero Section
 * Slug: my-theme/hero
 * Categories: featured
 * Keywords: hero, banner
 */
?>
<!-- wp:cover {"url":"..."} -->
...
<!-- /wp:cover -->
```

Patterns are auto-registered from the `patterns/` directory.

## Style Variations

Alternate `theme.json` files in `styles/` directory. Each provides a complete design variation:

```
styles/
  blue.json
  warm.json
```

Users switch between variations in the Site Editor.

## Caching

Site Editor changes are stored in the database (as a `wp_global_styles` CPT). When debugging:

- Clear browser cache
- Check for user-level overrides in Site Editor → Styles
- Use `wp_get_global_settings()` / `wp_get_global_styles()` to inspect resolved values
- Template customizations in the database override theme files

## Done Criteria

- `theme.json` version 3 with explicit schema reference.
- `index.html` template exists as fallback.
- Template parts registered with correct `area` in `theme.json`.
- Patterns have valid header comments with Title, Slug, and Categories.
- CSS custom properties use `var(--wp--preset--*)` syntax from theme.json presets.
- Style hierarchy understood — user overrides documented when relevant.

---

---
name: "wp-interactivity-api"
description: "Build and debug WordPress Interactivity API features: data-wp-* directives, @wordpress/interactivity store/state/actions, block viewScriptModule integration, and hydration."
---

# WordPress Interactivity API

## Scope

- Use this skill when building or debugging Interactivity API features in blocks or themes.
- Covers `data-wp-*` directives, `@wordpress/interactivity` store/state/actions, `viewScriptModule` integration, and server-side rendering/hydration.
- For block registration and metadata, defer to `wp-block-development`.
- If task scope is unclear, run `wordpress-router` first.

## Store Definition

```js
import { store, getContext } from '@wordpress/interactivity';

const { state } = store( 'my-plugin', {
    state: {
        get isOpen() {
            return getContext().isOpen;
        },
    },
    actions: {
        toggle() {
            const ctx = getContext();
            ctx.isOpen = ! ctx.isOpen;
        },
    },
    callbacks: {
        logState() {
            console.log( 'Open:', state.isOpen );
        },
    },
} );
```

## Directives

Applied as HTML attributes in block markup (render.php or save function):

| Directive | Purpose |
|---|---|
| `data-wp-interactive="my-plugin"` | Scope element to a store namespace |
| `data-wp-context='{"isOpen":false}'` | Initialize local context |
| `data-wp-bind--hidden="!state.isOpen"` | Bind attribute to state |
| `data-wp-on--click="actions.toggle"` | Bind event handler |
| `data-wp-text="state.label"` | Set text content from state |
| `data-wp-class--active="state.isActive"` | Toggle CSS class |
| `data-wp-style--color="state.color"` | Set inline style |
| `data-wp-watch="callbacks.logState"` | Run effect on state change |
| `data-wp-init="callbacks.init"` | Run once on mount |
| `data-wp-each="state.items"` | Iterate over array |

## Server-Side Rendering

The PHP render template outputs the initial HTML with directives. The Interactivity API hydrates it client-side:

```php
<?php
// render.php
wp_interactivity_state( 'my-plugin', [ 'count' => 0 ] );
?>
<div
    <?php echo get_block_wrapper_attributes(); ?>
    data-wp-interactive="my-plugin"
    data-wp-context='<?php echo wp_json_encode( [ 'isOpen' => false ] ); ?>'
>
    <button data-wp-on--click="actions.toggle">Toggle</button>
    <div data-wp-bind--hidden="!context.isOpen">Content</div>
</div>
```

## block.json Integration

Use `viewScriptModule` (not `viewScript`) for Interactivity API blocks:

```json
{
    "viewScriptModule": "file:./view.js"
}
```

The module is loaded as an ES module with automatic dependency on `@wordpress/interactivity`.

## Context vs State

- **Context** (`data-wp-context`): Local to an element and its descendants. Each block instance has its own context. Access with `getContext()`.
- **State** (`state`): Global to the store namespace. Shared across all block instances. Access as `state.property`.

Use context for per-instance data (open/closed, selected item). Use state for shared data (user preferences, fetched data).

## Done Criteria

- Store defined with `store()` using a unique namespace matching the block.
- Directives use `data-wp-interactive` scope on the container element.
- Context initialized in server-rendered HTML for hydration.
- `viewScriptModule` used in `block.json` (not `viewScript`).
- Event handlers use `actions`, side effects use `callbacks`.
- State/context separation follows per-instance vs shared convention.

---

---
name: "wp-performance"
description: "Profile and improve WordPress performance: profiling, query optimization, autoloaded options, object caching, cron, HTTP API calls, and safe verification."
---

# WordPress Performance

## Scope

- Use this skill when investigating or improving WordPress backend performance.
- Covers profiling, database/query optimization, autoloaded options, object caching, cron, and HTTP API calls.
- This is a backend-only skill. For frontend performance (Core Web Vitals, asset loading), additional tooling applies.
- For WP-CLI profiling commands, combine with `wp-wpcli-and-ops`.
- If task scope is unclear, run `wordpress-router` first.

## Measurement First

Never optimize without measuring. Establish baselines before making changes.

### Profiling Tools

| Tool | Use Case | Command/Access |
|---|---|---|
| `wp profile` | Hook-by-hook execution time | `wp profile stage --all --spotlight` |
| `wp doctor` | Health checks and diagnostics | `wp doctor check --all` |
| Query Monitor | Database queries, hooks, HTTP API | REST header: `X-QM-*` |
| Server-Timing | Per-request timing breakdown | Response header inspection |

### Key Metrics

- **Time to First Byte (TTFB)**: Total server response time.
- **Database query count**: Number of queries per request.
- **Database query time**: Total SQL execution time.
- **Peak memory**: `memory_get_peak_usage()`.
- **Autoloaded options size**: `wp db query "SELECT SUM(LENGTH(option_value)) FROM wp_options WHERE autoload = 'yes';"`.

## Database Optimization

### Query Patterns

- Use `WP_Query` and `WP_User_Query` instead of raw SQL when possible.
- Set `'no_found_rows' => true` when you don't need pagination totals.
- Set `'update_post_meta_cache' => false` and `'update_post_term_cache' => false` when you don't need meta/terms.
- Limit `'posts_per_page'` — never use `-1` in production.
- Use `'fields' => 'ids'` when you only need post IDs.

### Custom Queries

- Always index columns used in `WHERE`, `ORDER BY`, and `JOIN`.
- Use `$wpdb->prepare()` for all queries with variable input.
- Avoid `LIKE '%term%'` — it cannot use indexes. Prefer full-text search or application-level filtering.
- Use `EXPLAIN` to analyze slow queries.

### Autoloaded Options

Oversized autoloaded options are a top performance issue:

```bash
wp db query "SELECT option_name, LENGTH(option_value) AS size FROM wp_options WHERE autoload = 'yes' ORDER BY size DESC LIMIT 20;"
```

- Options loaded on every request should be small and frequently needed.
- Large, rarely-used options should be non-autoloaded: `update_option( 'key', $value, false )`.
- Transients stored in options (without object cache) autoload by default — use object cache to avoid this.

## Object Caching

### wp_cache API

```php
wp_cache_get( $key, $group );
wp_cache_set( $key, $data, $group, $expiration );
wp_cache_delete( $key, $group );
```

- Use cache groups to namespace keys by plugin/feature.
- Set expiration on volatile data. Use `0` (no expiration) only for data that's explicitly invalidated.
- Use `wp_cache_get_multiple()` for batch lookups.

### Transients vs Object Cache

- Transients (`get_transient` / `set_transient`) are the portable API — they use object cache when available, database otherwise.
- Direct `wp_cache_*` calls are faster but data is lost without a persistent object cache backend.
- For plugin distribution, prefer transients. For site-specific performance work, direct cache API is fine.

### Cache Invalidation

- Invalidate on the write path, not the read path.
- Hook into `save_post`, `updated_option`, `delete_post`, etc. to bust relevant caches.
- Use cache groups with `wp_cache_flush_group()` (WordPress 6.1+) for bulk invalidation.

## Cron Optimization

- Review scheduled events: `wp cron event list`.
- Consolidate hooks that run at the same interval.
- For high-traffic sites, disable `wp-cron.php` and use system cron: `define( 'DISABLE_WP_CRON', true );`.
- Long-running cron jobs should use `wp_schedule_single_event` for batched processing.

## HTTP API

- Cache external API responses with transients.
- Set reasonable timeouts: `'timeout' => 5` (default 5 seconds).
- Use `wp_remote_get` / `wp_remote_post` — never raw cURL.
- For multiple requests, consider `WP_Http::request()` with async patterns.

## Verification

After any performance change, verify:

1. **Measure again** with the same tool used for the baseline.
2. **Compare metrics** — query count, query time, TTFB, memory.
3. **Test functionality** — performance fixes must not break features.
4. **Test under load** — single-request improvements may not hold under concurrency.

## Done Criteria

- Baseline metrics captured before optimization.
- Changes target measured bottlenecks, not assumptions.
- Query count and/or time reduced with verification.
- No functionality regressions introduced.
- Autoloaded options reviewed and right-sized.
- Cache invalidation is explicit and correct.

---

---
name: "wp-phpstan"
description: "Configure, run, and fix PHPStan static analysis in WordPress projects: phpstan.neon setup, baselines, WordPress-specific typing, and handling third-party plugin classes."
---

# WordPress PHPStan

## Scope

- Use this skill when configuring, running, or resolving PHPStan issues in WordPress plugins, themes, or sites.
- Covers `phpstan.neon` configuration, baseline management, WordPress-specific type stubs, and incremental strictness.
- For broader plugin architecture concerns, defer to `wp-plugin-development`.
- If task scope is unclear, run `wordpress-router` first.

## Configuration

### phpstan.neon.dist

```neon
includes:
    - vendor/szepeviktor/phpstan-wordpress/extension.neon
parameters:
    level: max
    paths:
        - plugin.php
        - inc/
    excludePaths:
        - vendor/
        - tests/
    bootstrapFiles:
        - phpstan-bootstrap.php
```

### Key Parameters

- **level**: Start at the level matching your codebase maturity. Use `max` for new projects and greenfield code. Use a lower level with a baseline for legacy code.
- **paths**: Include only your source code. Exclude vendor, tests, and generated files.
- **bootstrapFiles**: Define constants, stubs, and conditional types that PHPStan needs at analysis time.
- **WordPress extension**: Always include `szepeviktor/phpstan-wordpress` for WordPress function signatures, hook types, and global variable types.

### Bootstrap File

Create `phpstan-bootstrap.php` for:
- Plugin version constants: `define( 'MY_PLUGIN_VERSION', '1.0.0' );`
- WordPress constants not available at analysis time.
- Conditional class stubs for optional dependencies.

## Baseline Management

### Creating a Baseline

```bash
vendor/bin/phpstan analyse --generate-baseline
```

This creates `phpstan-baseline.neon` with all current errors suppressed, letting you enforce zero new errors going forward.

### Include in Config

```neon
includes:
    - phpstan-baseline.neon
    - vendor/szepeviktor/phpstan-wordpress/extension.neon
```

### Ratcheting Policy

- Never add to the baseline. Only reduce it.
- When fixing errors, regenerate the baseline to lock in progress.
- CI should fail if the baseline grows.
- Track baseline error count in project metrics.

## Common WordPress Issues

### Hook Callbacks

PHPStan cannot infer types through `add_action`/`add_filter`. Use `@param` and `@return` PHPDoc on all hook callbacks:

```php
/**
 * @param string $content Post content.
 * @return string Modified content.
 */
function my_plugin_filter_content( string $content ): string {
    return $content . '<p>Appended.</p>';
}
add_filter( 'the_content', 'my_plugin_filter_content' );
```

### Global Variables

WordPress globals (`$wpdb`, `$wp_query`, `$post`) are typed by the WordPress extension. Access them with `global $wpdb;` — PHPStan will resolve the type.

### Dynamic Properties

WordPress objects use dynamic properties. If PHPStan reports undefined property errors on `WP_Post`, `WP_User`, etc., these are typically false positives handled by the extension. For custom classes, declare properties explicitly.

### Third-Party Plugin Classes

When your plugin integrates with other plugins (Co-Authors Plus, WooCommerce, etc.):

1. Check if the plugin provides PHPStan stubs.
2. If not, create a stub file and reference it in `bootstrapFiles`:

```php
// phpstan-stubs/coauthors-plus.php
class CoAuthors_Plus {
    /** @return array<int, WP_User> */
    public function get_coauthors( int $post_id ): array {}
}
```

### Mixed Types from Database

`get_option`, `get_post_meta`, and `$wpdb->get_results` return `mixed`. Use type assertions or PHPDoc to narrow:

```php
/** @var array{key: string, value: int} $settings */
$settings = get_option( 'my_plugin_settings', [] );
```

## CI Integration

### Composer Script

```json
{
    "scripts": {
        "analyse:phpstan": "phpstan analyse --memory-limit=1G"
    }
}
```

### GitHub Actions

```yaml
- name: PHPStan
  run: composer analyse:phpstan
```

PHPStan should be a blocking check in CI. Psalm can run as advisory alongside it.

## Upgrading PHPStan

When upgrading major versions (1.x to 2.x):
1. Read the upgrade guide.
2. Regenerate the baseline at the new version.
3. Fix any new errors introduced by improved analysis.
4. Update CI and local tooling simultaneously.

## Done Criteria

- `phpstan.neon.dist` committed with explicit level, paths, and WordPress extension.
- Baseline exists and is committed (for legacy code) or analysis passes at target level (for new code).
- Bootstrap file defines all constants and stubs needed for analysis.
- CI runs PHPStan as a blocking check.
- All hook callbacks have PHPDoc type annotations.
- Baseline error count does not grow between PRs.

---

---
name: "wp-playground"
description: "WordPress Playground workflows: fast disposable WP instances in the browser or locally via @wp-playground/cli, blueprints, auto-mounting plugins/themes, and switching WP/PHP versions."
---

# WordPress Playground

## Scope

- Use this skill for WordPress Playground-based workflows: quick testing, demos, blueprints, and disposable instances.
- Covers browser Playground, `@wp-playground/cli`, and blueprint authoring.
- For persistent local development, defer to `local-studio-env`.
- If task scope is unclear, run `wordpress-router` first.

## Browser Playground

Access at `playground.wordpress.net`. Instant WordPress instance in the browser via WebAssembly.

### URL Parameters

```
https://playground.wordpress.net/?php=8.2&wp=6.7&plugin=akismet&theme=twentytwentyfive
```

### Blueprint URL

```
https://playground.wordpress.net/?blueprint-url=https://example.com/blueprint.json
```

## Blueprints

JSON configuration for reproducible Playground instances:

```json
{
    "landingPage": "/wp-admin/",
    "phpVersion": "8.2",
    "wpVersion": "6.7",
    "steps": [
        { "step": "login", "username": "admin", "password": "password" },
        {
            "step": "installPlugin",
            "pluginData": { "resource": "wordpress.org/plugins", "slug": "akismet" }
        },
        {
            "step": "installTheme",
            "themeData": { "resource": "wordpress.org/themes", "slug": "twentytwentyfive" }
        },
        {
            "step": "setSiteOptions",
            "options": { "blogname": "Test Site" }
        }
    ]
}
```

### Blueprint Steps

| Step | Purpose |
|---|---|
| `login` | Auto-login as user |
| `installPlugin` | Install from wp.org, URL, or inline |
| `installTheme` | Install theme |
| `setSiteOptions` | Set wp_options values |
| `importWxr` | Import content from WXR file |
| `runPHP` | Execute arbitrary PHP |
| `writeFile` | Write a file to the virtual filesystem |
| `enableMultisite` | Enable WordPress Multisite |

## @wp-playground/cli

Local Playground via Node.js:

```bash
npx @wp-playground/cli server --php=8.2 --wp=6.7 --mount=./my-plugin:/wordpress/wp-content/plugins/my-plugin
```

### Commands

- `server` — Start a local Playground server
- `run-blueprint` — Execute a blueprint file
- `build-snapshot` — Create a reusable snapshot

### Mount Plugin for Development

```bash
npx @wp-playground/cli server \
    --mount=./:/wordpress/wp-content/plugins/my-plugin \
    --blueprint=blueprint.json
```

Changes in your local directory are reflected immediately.

## CI Integration

Use Playground in GitHub Actions for PR previews:

```yaml
- name: Playground Preview
  run: |
    echo "Preview: https://playground.wordpress.net/?blueprint-url=$BLUEPRINT_URL"
```

## Done Criteria

- Blueprint is valid JSON with correct step syntax.
- PHP and WordPress versions specified explicitly.
- Plugins/themes mounted or installed as needed.
- Blueprint tested by loading in Playground.

---

---
name: "wp-plugin-development"
description: "Build WordPress plugins: architecture, hooks, activation/deactivation/uninstall, admin UI, Settings API, data storage, cron, security (nonces/capabilities/sanitization/escaping), and release packaging."
---

# WordPress Plugin Development

## Scope

- Use this skill when building, maintaining, or reviewing WordPress plugins.
- Covers plugin architecture, lifecycle hooks, admin UI, data storage, background tasks, security, and packaging.
- For static analysis concerns, defer to `wp-phpstan`.
- For REST API routes/controllers, defer to `wp-rest-api`.
- For block development within a plugin, defer to `wp-block-development`.
- If task scope is unclear, run `wordpress-router` first.

## Architecture

### Entry Point

- Single main plugin file with plugin header comment.
- Guard against direct access: `defined( 'ABSPATH' ) || exit;`.
- Define plugin version constant. Keep version in sync across: plugin header, constant, `readme.txt` Stable tag.
- Use Composer autoloading (PSR-4) for class organization. Namespace root should match plugin name.

### Hook Registration

- Register hooks in the main plugin file or a dedicated bootstrap function.
- Prefix all hook names, function names, option names, and meta keys with the plugin slug.
- Use `add_action` / `add_filter` with explicit priority only when order matters.
- Prefer class methods over closures for hook callbacks (testability).

### Activation / Deactivation / Uninstall

- `register_activation_hook`: create database tables, set default options, flush rewrite rules.
- `register_deactivation_hook`: clean up scheduled events (`wp_clear_scheduled_hook`), flush rewrite rules.
- `uninstall.php` (preferred) or `register_uninstall_hook`: remove all plugin data — options, transients, custom tables, user meta, post meta, taxonomies, roles/capabilities.
- Never delete data on deactivation. Only on uninstall.

## Security

### Nonces

- Every form and AJAX action must include a nonce: `wp_nonce_field` / `wp_create_nonce`.
- Verify with `wp_verify_nonce` or `check_ajax_referer` before processing.
- Use specific nonce actions: `plugin_slug_action_context`, not generic strings.

### Capabilities

- Check `current_user_can()` before any privileged operation.
- Use WordPress built-in capabilities where possible.
- Register custom capabilities on activation; remove on uninstall.

### Input Handling

- Sanitize all input: `sanitize_text_field`, `absint`, `sanitize_email`, `wp_kses_post`, etc.
- Escape all output: `esc_html`, `esc_attr`, `esc_url`, `wp_kses_post`.
- Use `$wpdb->prepare()` for all database queries with user input. Never interpolate.

### File Operations

- Validate file types against an allowlist.
- Use `wp_handle_upload` for file uploads, never raw PHP upload handling.
- Store files in `wp_upload_dir()`, never in the plugin directory.

## Data Storage

### Options API

- Use `get_option` / `update_option` for plugin settings.
- Store related settings in a single serialized array, not scattered options.
- Register settings with `register_setting` for Settings API integration.
- Mark high-read options as autoloaded; mark rarely-used options as non-autoloaded.

### Custom Tables

- Create tables in activation hook using `dbDelta()`.
- Include `$wpdb->prefix` for table names.
- Store schema version in options for upgrade migrations.
- Include proper indexes for query patterns.

### Post Meta / User Meta / Term Meta

- Register meta with `register_meta` or `register_post_meta` for REST API exposure.
- Use `sanitize_callback` and `auth_callback` in registration.

## Admin UI

- Register admin pages with `add_menu_page` / `add_submenu_page`.
- Use `admin_enqueue_scripts` with page hook check to load assets only where needed.
- Implement Settings API (`register_setting`, `add_settings_section`, `add_settings_field`) for options pages.
- Add admin notices with `admin_notices` hook; use `is_dismissible` class for non-critical messages.

## Background Tasks

- Register cron events with `wp_schedule_event` in activation hook.
- Clear with `wp_clear_scheduled_hook` in deactivation hook.
- Use custom cron intervals via `cron_schedules` filter when needed.
- For one-time deferred tasks, use `wp_schedule_single_event`.

## Testing

- PHPUnit with `WP_UnitTestCase` for integration tests.
- Brain\Monkey + Mockery for fast unit tests that mock WordPress functions.
- Maintain coverage thresholds; ratchet upward, never down.
- Run PHPCS with WordPress-Extra or WordPress-VIP standards.

## Packaging

- `.distignore` file listing development-only files excluded from distribution.
- Build step to generate clean distribution directory.
- Tag releases in git; use GitHub Actions for automated WordPress.org deployment when applicable.
- Include `readme.txt` in WordPress.org format for directory submissions.

## Done Criteria

- Plugin activates and deactivates cleanly with no errors or warnings.
- All hooks are prefixed with the plugin slug.
- Security: nonces on all forms/AJAX, capability checks on privileged operations, input sanitized, output escaped.
- Uninstall removes all plugin data.
- No direct database queries without `$wpdb->prepare()`.
- Assets load only on relevant admin pages.
- All applicable behavioral scenarios pass.

---

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

---

---
name: "wp-rest-api"
description: "Build, extend, and debug WordPress REST API endpoints: register_rest_route, WP_REST_Controller, schema/argument validation, permission_callback, response shaping, and exposing CPTs via show_in_rest."
---

# WordPress REST API

## Scope

- Use this skill when building, extending, or debugging WordPress REST API routes and controllers.
- Covers `register_rest_route`, `WP_REST_Controller`, schema, validation, authentication, and response shaping.
- For plugin architecture surrounding REST endpoints, defer to `wp-plugin-development`.
- For static analysis of REST code, defer to `wp-phpstan`.
- If task scope is unclear, run `wordpress-router` first.

## Route Registration

### Basic Pattern

```php
add_action( 'rest_api_init', function () {
    register_rest_route( 'my-plugin/v1', '/items', [
        'methods'             => WP_REST_Server::READABLE,
        'callback'            => 'my_plugin_get_items',
        'permission_callback' => 'my_plugin_items_permissions_check',
        'args'                => my_plugin_get_items_args(),
    ] );
} );
```

### Rules

- Always include a `permission_callback`. Use `'__return_true'` only for intentionally public endpoints.
- Namespace with `plugin-slug/v1`. Never register under `wp/v2` unless extending core.
- Use `WP_REST_Server` constants: `READABLE`, `CREATABLE`, `EDITABLE`, `DELETABLE`.
- Register on `rest_api_init` — never earlier.

## Controller Pattern

For endpoints with CRUD operations, extend `WP_REST_Controller`:

```php
class My_Plugin_Items_Controller extends WP_REST_Controller {
    protected $namespace = 'my-plugin/v1';
    protected $rest_base = 'items';

    public function register_routes() { /* ... */ }
    public function get_items( $request ) { /* ... */ }
    public function get_item( $request ) { /* ... */ }
    public function create_item( $request ) { /* ... */ }
    public function update_item( $request ) { /* ... */ }
    public function delete_item( $request ) { /* ... */ }
    public function get_item_schema() { /* ... */ }
    public function get_item_permissions_check( $request ) { /* ... */ }
}
```

Instantiate and register in `rest_api_init`:

```php
add_action( 'rest_api_init', function () {
    $controller = new My_Plugin_Items_Controller();
    $controller->register_routes();
} );
```

## Schema & Validation

### Argument Schema

Define args with `type`, `description`, `required`, `default`, `validate_callback`, and `sanitize_callback`:

```php
function my_plugin_get_items_args(): array {
    return [
        'per_page' => [
            'type'              => 'integer',
            'default'           => 10,
            'minimum'           => 1,
            'maximum'           => 100,
            'sanitize_callback' => 'absint',
        ],
        'search' => [
            'type'              => 'string',
            'sanitize_callback' => 'sanitize_text_field',
        ],
    ];
}
```

### Item Schema

Return JSON Schema from `get_item_schema()`. WordPress uses this for:
- Automatic response validation.
- Autodiscovery via OPTIONS requests.
- Documentation.

```php
public function get_item_schema(): array {
    return [
        '$schema'    => 'http://json-schema.org/draft-04/schema#',
        'title'      => 'item',
        'type'       => 'object',
        'properties' => [
            'id'   => [ 'type' => 'integer', 'readonly' => true ],
            'name' => [ 'type' => 'string', 'required' => true ],
        ],
    ];
}
```

## Permission Callbacks

- Return `true` to allow, `false` to deny (403), or `WP_Error` for custom error.
- Check capabilities: `current_user_can( 'edit_posts' )`.
- For per-item permissions, load the item and check ownership or capability.
- Permission callback runs before the main callback. Never duplicate checks.

```php
public function get_item_permissions_check( $request ): bool|WP_Error {
    $item = $this->get_item_from_request( $request );
    if ( is_wp_error( $item ) ) {
        return $item;
    }
    if ( ! current_user_can( 'edit_post', $item->ID ) ) {
        return new WP_Error( 'rest_forbidden', 'You cannot view this item.', [ 'status' => 403 ] );
    }
    return true;
}
```

## Response Shaping

- Return `WP_REST_Response` for control over status code and headers.
- Use `rest_ensure_response()` to wrap arrays/objects.
- Add `_links` via `$response->add_links()` for HATEOAS.
- Set pagination headers: `X-WP-Total`, `X-WP-TotalPages`.

```php
$response = rest_ensure_response( $data );
$response->header( 'X-WP-Total', $total );
$response->header( 'X-WP-TotalPages', $total_pages );
return $response;
```

## Exposing Custom Post Types

```php
register_post_type( 'my_item', [
    'show_in_rest' => true,
    'rest_base'    => 'items',
    'rest_controller_class' => 'WP_REST_Posts_Controller', // default
    // ...
] );
```

For custom meta on CPTs:

```php
register_post_meta( 'my_item', 'custom_field', [
    'show_in_rest'  => true,
    'single'        => true,
    'type'          => 'string',
    'auth_callback' => function () {
        return current_user_can( 'edit_posts' );
    },
] );
```

## Testing REST Endpoints

- Use `WP_REST_Request` in PHPUnit integration tests.
- Test permission callbacks separately from main callbacks.
- Test schema validation with invalid input.
- Verify response status codes and headers.

```php
$request = new WP_REST_Request( 'GET', '/my-plugin/v1/items' );
$request->set_param( 'per_page', 5 );
$response = rest_get_server()->dispatch( $request );
$this->assertSame( 200, $response->get_status() );
```

## Done Criteria

- Every endpoint has an explicit `permission_callback`.
- Arguments have `type`, `sanitize_callback`, and validation constraints.
- Item schema is defined and returned from `get_item_schema()`.
- Responses use `WP_REST_Response` with correct status codes.
- Endpoints are tested with `WP_REST_Request` in integration tests.
- Custom post types use `show_in_rest` with explicit `rest_base`.

---

---
name: "wp-wpcli-and-ops"
description: "Use WP-CLI for WordPress operations: safe search-replace, db export/import, plugin/theme/user/content management, cron, cache flushing, multisite, and scripting/automation."
---

# WP-CLI and Operations

## Scope

- Use this skill for WP-CLI command execution, automation, and operational workflows.
- Covers database operations, content management, plugin/theme management, user management, cron, cache, multisite, and scripting.
- For runbook documentation format (procedure metadata, rollback, escalation), defer to `wordpress-runbook-ops`.
- For performance profiling via WP-CLI, combine with `wp-performance`.
- If task scope is unclear, run `wordpress-router` first.

## Command Verification

- Use only real `wp` subcommands and supported flags.
- Verify syntax with `wp help <command>` when uncertain.
- Use the **Veloria** MCP server (`veloria` at veloria.dev) to verify plugin-specific CLI commands against actual source.

## Database Operations

### Export/Import

```bash
wp db export backup-$(date +%Y%m%d-%H%M%S).sql
wp db import backup.sql
```

Always export before any destructive operation.

### Search-Replace

```bash
# Always dry-run first
wp search-replace 'old-domain.com' 'new-domain.com' --dry-run --report-changed-only

# Then execute
wp search-replace 'old-domain.com' 'new-domain.com' --report-changed-only
```

Rules:
- Always `--dry-run` first.
- Use `--report-changed-only` to see what changes.
- For multisite, add `--network` or target specific `--url=`.
- Serialized data is handled automatically by WP-CLI.
- Use `--precise` for partial string matches within larger values.

### Direct Queries

```bash
wp db query "SELECT option_name, LENGTH(option_value) AS size FROM wp_options WHERE autoload = 'yes' ORDER BY size DESC LIMIT 10;"
```

## Plugin/Theme Management

```bash
wp plugin list --status=active --fields=name,version,update
wp plugin install plugin-slug --activate
wp plugin deactivate plugin-slug
wp plugin update --all --dry-run
wp theme list --fields=name,status,version,update
```

- Use `--dry-run` for update commands before executing.
- Use `--skip-plugins` / `--skip-themes` to bypass loading when debugging fatal errors.

## User Management

```bash
wp user list --role=administrator --fields=ID,user_login,user_email
wp user create username user@example.com --role=editor
wp user update <id> --user_pass='[CUSTOMIZE: new_password]'
wp user delete <id> --reassign=<other_id>
```

- Always use `--reassign` when deleting users to preserve content attribution.

## Content Operations

```bash
wp post list --post_type=post --post_status=publish --fields=ID,post_title --posts_per_page=20
wp post delete <id> --force
wp post generate --count=10 --post_type=post
wp comment list --status=spam --fields=comment_ID --format=ids | xargs wp comment delete
```

## Cron

```bash
wp cron event list
wp cron event run <hook>
wp cron schedule list
wp cron test
```

## Cache

```bash
wp cache flush
wp transient delete --all
wp rewrite flush
```

For plugin-specific cache flushing:

```bash
# Plugin-dependent - uncomment the cache plugin(s) in use:
# wp w3-total-cache flush all
# wp wp-super-cache flush
```

## Multisite

```bash
wp site list --fields=blog_id,url
wp site create --slug=newsite
wp network meta list

# Run command across all sites
wp site list --field=url | xargs -I {} wp --url={} plugin list --status=active
```

## Scripting and Automation

### wp-cli.yml

```yaml
path: /var/www/html
color: true
disabled_commands:
  - db drop
```

### Eval

```bash
wp eval 'echo get_option("siteurl");'
wp eval-file script.php
```

### Output Formats

Use `--format` for machine-readable output:

```bash
wp plugin list --format=json
wp user list --format=csv
wp post list --format=ids
```

## Safety Rules

- Export database before destructive operations.
- Use `--dry-run` where available.
- Use `--skip-plugins` / `--skip-themes` when diagnosing fatal errors.
- Destructive commands (`db drop`, `site delete`, `user delete` without `--reassign`) require explicit confirmation.
- In scripts, use `--yes` to skip prompts only after dry-run verification.

## Done Criteria

- Commands use correct subcommands and flags (verifiable with `wp help`).
- Destructive operations preceded by backup/dry-run.
- Multisite operations scope correctly (per-site or `--network`).
- Output format specified for scripted/automated usage.
- Plugin-dependent commands annotated with `# Plugin-dependent` comment.

---

---
name: "wpds"
description: "Build UI with the WordPress Design System (WPDS): components, design tokens, patterns, and theming."
---

# WordPress Design System (WPDS)

## Scope

- Use this skill when building UI that should follow WordPress Design System conventions.
- Covers WPDS components, design tokens, patterns, and theming.
- For block theme development, defer to `wp-block-themes`.
- If task scope is unclear, run `wordpress-router` first.

## Components

Use `@wordpress/components` for admin UI:

```js
import { Button, TextControl, Panel, PanelBody } from '@wordpress/components';
```

### Key Components

- **Button**: Primary, secondary, tertiary, link variants. Use `variant` prop.
- **TextControl / TextareaControl**: Form inputs with label and help text.
- **Panel / PanelBody**: Collapsible sections for inspector controls.
- **Modal**: Overlay dialogs.
- **Notice**: Informational/warning/error messages.
- **Spinner**: Loading indicator.
- **ToggleControl / CheckboxControl**: Boolean inputs.
- **SelectControl / ComboboxControl**: Dropdown selections.

## Design Tokens

WordPress uses CSS custom properties as design tokens:

```css
/* Colors */
var(--wp-admin-theme-color)
var(--wp-admin-theme-color-darker-10)
var(--wp-admin-theme-color-darker-20)

/* Typography */
font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif;

/* Spacing */
/* Use 4px/8px grid system */
```

## Patterns

- Follow existing WordPress admin UI patterns for consistency.
- Settings pages: use `Panel` with `PanelBody` sections.
- List views: use table or card patterns matching wp-admin conventions.
- Forms: group related fields, use help text, validate inline.

## Done Criteria

- UI uses `@wordpress/components` instead of custom implementations where equivalent components exist.
- Design tokens used for colors and spacing.
- UI patterns match WordPress admin conventions.
- Accessibility: all interactive elements keyboard-accessible with proper ARIA attributes.

