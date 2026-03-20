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
