---
name: "wp-block-themes"
description: "Develop WordPress block themes: theme.json global settings/styles, templates, template parts, patterns, style variations, and Site Editor troubleshooting."
---

# WordPress Block Themes

## Scope

- Use this skill when developing or troubleshooting WordPress block themes.
- Covers `theme.json`, templates, template parts, patterns, style variations, and Site Editor workflows.
- For individual block development, defer to `wp-block-development`.
- For Interactivity API within themes, defer to `wp-interactivity-api`.
- If task scope is unclear, run `wordpress-router` first.

## theme.json

The global settings and styles configuration file. Version 3 is current for WordPress 6.6+.

### Structure

```json
{
    "$schema": "https://schemas.wp.org/trunk/theme.json",
    "version": 3,
    "settings": {},
    "styles": {},
    "templateParts": [],
    "customTemplates": [],
    "patterns": []
}
```

### Settings

Define which design tools are available:

- `color.palette` / `color.gradients` — custom color presets
- `typography.fontFamilies` / `typography.fontSizes` — font presets
- `spacing.spacingSizes` — spacing presets
- `layout.contentSize` / `layout.wideSize` — content width constraints
- `appearanceTools: true` — enable all design controls

### Styles

Apply global and per-element/block styles:

```json
{
    "styles": {
        "color": { "background": "var(--wp--preset--color--base)" },
        "typography": { "fontFamily": "var(--wp--preset--font-family--body)" },
        "elements": {
            "link": { "color": { "text": "var(--wp--preset--color--primary)" } }
        },
        "blocks": {
            "core/paragraph": { "spacing": { "margin": { "bottom": "1.5rem" } } }
        }
    }
}
```

### Style Hierarchy

From lowest to highest specificity:
1. WordPress defaults
2. `theme.json` — theme settings/styles
3. User global styles (stored in database via Site Editor)
4. Per-block styles in the editor

Understand this hierarchy when debugging why styles don't apply.

## Templates

HTML files in `templates/` directory. These are block markup:

- `index.html` — required fallback template
- `single.html`, `page.html`, `archive.html`, `404.html`, `search.html`, etc.
- `home.html` — blog home
- Custom templates registered in `theme.json` `customTemplates` array

Template files contain block markup with HTML comments:

```html
<!-- wp:template-part {"slug":"header","area":"header"} /-->
<!-- wp:group {"layout":{"type":"constrained"}} -->
<div class="wp-block-group">
    <!-- wp:post-content /-->
</div>
<!-- /wp:group -->
<!-- wp:template-part {"slug":"footer","area":"footer"} /-->
```

## Template Parts

Reusable template sections in `parts/` directory:

- `header.html` — site header
- `footer.html` — site footer
- Register in `theme.json` with `area` designation (`header`, `footer`, `uncategorized`)

## Patterns

Block patterns in `patterns/` directory. Each file needs a header comment:

```php
<?php
/**
 * Title: Hero Section
 * Slug: my-theme/hero
 * Categories: featured
 * Keywords: hero, banner
 */
?>
<!-- wp:cover {"url":"..."} -->
...
<!-- /wp:cover -->
```

Patterns are auto-registered from the `patterns/` directory.

## Style Variations

Alternate `theme.json` files in `styles/` directory. Each provides a complete design variation:

```
styles/
  blue.json
  warm.json
```

Users switch between variations in the Site Editor.

## Caching

Site Editor changes are stored in the database (as a `wp_global_styles` CPT). When debugging:

- Clear browser cache
- Check for user-level overrides in Site Editor → Styles
- Use `wp_get_global_settings()` / `wp_get_global_styles()` to inspect resolved values
- Template customizations in the database override theme files

## Done Criteria

- `theme.json` version 3 with explicit schema reference.
- `index.html` template exists as fallback.
- Template parts registered with correct `area` in `theme.json`.
- Patterns have valid header comments with Title, Slug, and Categories.
- CSS custom properties use `var(--wp--preset--*)` syntax from theme.json presets.
- Style hierarchy understood — user overrides documented when relevant.
