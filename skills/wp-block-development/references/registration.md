# Registration patterns (PHP-first)

Use this file when you need to register blocks robustly across repo types (plugin/theme/site).

## Prefer metadata registration

Prefer:

- `register_block_type_from_metadata( $path_to_block_dir, $args = [] )`

Why:

- keeps metadata authoritative (`block.json`)
- supports dynamic render (`render`) and other metadata-driven fields
- enables cleaner asset handling

Upstream reference:

- https://developer.wordpress.org/reference/functions/register_block_type_from_metadata/

## Where to register

- Plugins: register on `init` in the main plugin bootstrap or a dedicated loader.
- Themes: register on `init` (or `after_setup_theme` if you need theme supports first), but keep it predictable.

## Dynamic render mapping

If `block.json` includes `render`, ensure the file exists relative to the block root.
Inside the render file, use `get_block_wrapper_attributes()` for wrapper attributes.


## PHP-only registration (WordPress 7.0+)

WordPress 7.0 can register a block from PHP alone: no `block.json`, no JS build.
Core generates the editor UI when the block opts in with `supports.autoRegister`.

```php
add_action( 'init', function () {
	register_block_type( 'acme/notice', [
		'title'           => __( 'Notice', 'acme' ),
		'attributes'      => [
			'message' => [ 'type' => 'string', 'default' => '' ],
			'tone'    => [ 'type' => 'string', 'enum' => [ 'info', 'warning' ], 'default' => 'info' ],
			'postId'  => [ 'type' => 'integer', 'role' => 'local' ], // stored, no control
		],
		'supports'        => [
			'autoRegister' => true, // required — without it nothing appears in the editor
			'align'        => true,
			'color'        => [ 'background' => true, 'text' => true ],
		],
		'style'           => 'acme-notice',        // editor + front end
		'editor_style'    => 'acme-notice-editor', // editor only, loads after `style`
		'view_script'     => 'acme-notice-view',   // front end, only when the block is present
		'render_callback' => function ( $attributes ) {
			return sprintf(
				'<div %s>%s</div>',
				get_block_wrapper_attributes( [ 'class' => 'is-' . esc_attr( $attributes['tone'] ) ] ),
				esc_html( $attributes['message'] )
			);
		},
	] );
} );
```

Attribute → generated control: `string` → text, `number`/`integer` → number,
`boolean` → checkbox, `enum` → select (labels equal stored values; no keyed
arrays). `'role' => 'local'` stores a value without a control.

When it fits: porting shortcodes, widgets, and template tags into block themes;
server-rendered, settings-driven output. When it doesn't: anything needing rich
text, media, date pickers, keyed dropdowns, or interactive editor JS — use
`block.json` + a build.

Preview gotchas (the editor preview is a `/wp/v2/block-renderer/` REST request,
re-fetched on every control change):

- `is_admin()` is false inside it. Detect it with `wp_is_rest_endpoint()` and the
  `rest_route` query var, not `is_admin()`.
- There is no post context: `get_the_ID()` and post meta are unreliable. If the
  output depends on the post, capture the ID into a `role: local` attribute.
- The preview renders saved data, not unsaved edits.
- Editor-side JS attached to the markup breaks when the preview re-renders.

Source: https://css-tricks.com/wordpress-php-block-registration/
