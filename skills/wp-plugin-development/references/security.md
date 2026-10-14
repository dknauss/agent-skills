# Security guardrails (plugin work)

Use this file when making security fixes or when handling any input/output.

## Nonces + permissions

- Nonces help prevent CSRF, not authorization.
- Always pair nonces with capability checks (`current_user_can()` or a more specific capability).

Upstream reference:

- https://developer.wordpress.org/apis/security/nonces/

## Sanitization and escaping

Golden rule:

- sanitize/validate on input, escape on output.

Practical rules:

- never process the entire `$_POST` / `$_GET` array; read explicit keys
- use `wp_unslash()` before sanitizing when needed
- use prepared statements for SQL; avoid interpolating user input into queries

Common review guidance:

- https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/


## `wp_kses()` on the HTML API (WordPress 7.2/7.3, in progress)

Core is reimplementing `wp_kses()` on the HTML API (Trac #66208). The function
signature and allowed-HTML arrays are unchanged, but **output changes**:

- Markup is normalized: lowercase tag names, double-quoted attributes, no
  self-closing slash on void elements, character references re-encoded.
- A stray `<` in text (`<$500`) is escaped instead of swallowing the rest.
- Disallowed `SCRIPT`/`STYLE` are removed *with their contents*; other
  disallowed elements still lose only their tags.
- Truncated trailing markup is dropped; missing closing tags are still not added.
- Semicolon-less named references (`&sect`) decode in text but not in attributes.

What to do in plugin code and tests:

- Never assert exact kses output strings. Compare semantically with
  `assertEqualHTML()` (WP_UnitTestCase) so tests survive the parser swap.
- Emit well-formed input: write `&amp;`, terminate character references with `;`.
- To compare behaviour, run the suite with the legacy parser forced:
  `add_filter( 'wp_kses_force_legacy_parser', '__return_true' );` — temporary
  only; the legacy parser may be removed as early as 7.2.0.
- Do not depend on kses "repairing" markup or on its exact serialization in
  caches, hashes, or diffs.

Source: https://make.wordpress.org/core/2026/10/07/progress-report-wp_kses/
