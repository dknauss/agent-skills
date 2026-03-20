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
