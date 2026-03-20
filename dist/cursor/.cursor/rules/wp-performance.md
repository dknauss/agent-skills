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
