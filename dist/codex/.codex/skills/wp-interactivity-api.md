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
