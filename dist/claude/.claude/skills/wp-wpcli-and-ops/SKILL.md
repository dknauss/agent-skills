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
