# Admin asset prefetch (WordPress 7.2)

Committed to core as r64120 (wordpress-develop PR #13084, Trac #57548), targeted
at WordPress 7.2. Part of the effort to retire admin script/style concatenation.

## What core does

- `wp_prefetch_admin_assets()` runs on `login_footer` (priority 21) and
  `admin_head`, printing `<link rel="prefetch">` tags for the render-blocking CSS
  (and, from login, `jquery`/`utils`) of the screen the user is likely to open
  next. A small inline `fetch()` fallback covers Safari and is printed through
  `wp_print_inline_script_tag()`, so it respects CSP nonces.
- No output when concatenation is enabled, when `redirect_to` points off-site,
  or when the user lacks `edit_posts`.
- Reported gains with concatenation off + prefetch: dashboard LCP 26% faster on
  Fast 4G, 46% on Slow 4G.

## Extending it

```php
add_filter( 'wp_prefetch_admin_assets', function ( $resources, $target_url ) {
	if ( str_contains( $target_url, 'post-new.php' ) || str_contains( $target_url, 'post.php' ) ) {
		$src = wp_styles()->get_src( 'acme-editor' );
		if ( $src ) {
			$resources[] = [ 'href' => $src, 'as' => 'style' ];
		}
	}
	return $resources;
}, 10, 2 );
```

- The filter mirrors `wp_preload_resources`: an array of attribute arrays plus
  the target screen URL. Core runs each `href` through `esc_url()` (http/https
  only) and de-duplicates.
- New helpers `WP_Scripts::get_src()`, `WP_Styles::get_src()` and
  `WP_Styles::get_rtl_src()` return the filtered, unescaped URL for a handle.
  Side effect: a non-string return from `style_loader_src` now yields `''`.
- Only prefetch assets the next screen will really load; prefetch is
  low-priority but still costs bandwidth.

## Don't rely on

- `wp_should_concatenate_admin_scripts()` and its same-named filter: slated for
  removal before 7.2-beta1. Use the `$concatenate_scripts` global (or
  `CONCATENATE_SCRIPTS`) to control concatenation.

## Verify

- Load `wp-login.php` / `edit.php` with concatenation off and inspect the
  `<head>` for prefetch links; confirm your handle appears only for the intended
  target, and that the next navigation serves it from the prefetch cache
  (DevTools Network → "prefetch cache").

Source: https://github.com/WordPress/wordpress-develop/pull/13084
