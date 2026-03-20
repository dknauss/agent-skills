---
name: "wpds"
description: "Build UI with the WordPress Design System (WPDS): components, design tokens, patterns, and theming."
---

# WordPress Design System (WPDS)

## Scope

- Use this skill when building UI that should follow WordPress Design System conventions.
- Covers WPDS components, design tokens, patterns, and theming.
- For block theme development, defer to `wp-block-themes`.
- If task scope is unclear, run `wordpress-router` first.

## Components

Use `@wordpress/components` for admin UI:

```js
import { Button, TextControl, Panel, PanelBody } from '@wordpress/components';
```

### Key Components

- **Button**: Primary, secondary, tertiary, link variants. Use `variant` prop.
- **TextControl / TextareaControl**: Form inputs with label and help text.
- **Panel / PanelBody**: Collapsible sections for inspector controls.
- **Modal**: Overlay dialogs.
- **Notice**: Informational/warning/error messages.
- **Spinner**: Loading indicator.
- **ToggleControl / CheckboxControl**: Boolean inputs.
- **SelectControl / ComboboxControl**: Dropdown selections.

## Design Tokens

WordPress uses CSS custom properties as design tokens:

```css
/* Colors */
var(--wp-admin-theme-color)
var(--wp-admin-theme-color-darker-10)
var(--wp-admin-theme-color-darker-20)

/* Typography */
font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen-Sans, Ubuntu, Cantarell, "Helvetica Neue", sans-serif;

/* Spacing */
/* Use 4px/8px grid system */
```

## Patterns

- Follow existing WordPress admin UI patterns for consistency.
- Settings pages: use `Panel` with `PanelBody` sections.
- List views: use table or card patterns matching wp-admin conventions.
- Forms: group related fields, use help text, validate inline.

## Done Criteria

- UI uses `@wordpress/components` instead of custom implementations where equivalent components exist.
- Design tokens used for colors and spacing.
- UI patterns match WordPress admin conventions.
- Accessibility: all interactive elements keyboard-accessible with proper ARIA attributes.
