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
