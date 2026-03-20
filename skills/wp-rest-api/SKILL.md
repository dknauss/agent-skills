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
