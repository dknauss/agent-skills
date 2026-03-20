---
name: "wp-playground"
description: "WordPress Playground workflows: fast disposable WP instances in the browser or locally via @wp-playground/cli, blueprints, auto-mounting plugins/themes, and switching WP/PHP versions."
---

# WordPress Playground

## Scope

- Use this skill for WordPress Playground-based workflows: quick testing, demos, blueprints, and disposable instances.
- Covers browser Playground, `@wp-playground/cli`, and blueprint authoring.
- For persistent local development, defer to `local-studio-env`.
- If task scope is unclear, run `wordpress-router` first.

## Browser Playground

Access at `playground.wordpress.net`. Instant WordPress instance in the browser via WebAssembly.

### URL Parameters

```
https://playground.wordpress.net/?php=8.2&wp=6.7&plugin=akismet&theme=twentytwentyfive
```

### Blueprint URL

```
https://playground.wordpress.net/?blueprint-url=https://example.com/blueprint.json
```

## Blueprints

JSON configuration for reproducible Playground instances:

```json
{
    "landingPage": "/wp-admin/",
    "phpVersion": "8.2",
    "wpVersion": "6.7",
    "steps": [
        { "step": "login", "username": "admin", "password": "password" },
        {
            "step": "installPlugin",
            "pluginData": { "resource": "wordpress.org/plugins", "slug": "akismet" }
        },
        {
            "step": "installTheme",
            "themeData": { "resource": "wordpress.org/themes", "slug": "twentytwentyfive" }
        },
        {
            "step": "setSiteOptions",
            "options": { "blogname": "Test Site" }
        }
    ]
}
```

### Blueprint Steps

| Step | Purpose |
|---|---|
| `login` | Auto-login as user |
| `installPlugin` | Install from wp.org, URL, or inline |
| `installTheme` | Install theme |
| `setSiteOptions` | Set wp_options values |
| `importWxr` | Import content from WXR file |
| `runPHP` | Execute arbitrary PHP |
| `writeFile` | Write a file to the virtual filesystem |
| `enableMultisite` | Enable WordPress Multisite |

## @wp-playground/cli

Local Playground via Node.js:

```bash
npx @wp-playground/cli server --php=8.2 --wp=6.7 --mount=./my-plugin:/wordpress/wp-content/plugins/my-plugin
```

### Commands

- `server` — Start a local Playground server
- `run-blueprint` — Execute a blueprint file
- `build-snapshot` — Create a reusable snapshot

### Mount Plugin for Development

```bash
npx @wp-playground/cli server \
    --mount=./:/wordpress/wp-content/plugins/my-plugin \
    --blueprint=blueprint.json
```

Changes in your local directory are reflected immediately.

## CI Integration

Use Playground in GitHub Actions for PR previews:

```yaml
- name: Playground Preview
  run: |
    echo "Preview: https://playground.wordpress.net/?blueprint-url=$BLUEPRINT_URL"
```

## Done Criteria

- Blueprint is valid JSON with correct step syntax.
- PHP and WordPress versions specified explicitly.
- Plugins/themes mounted or installed as needed.
- Blueprint tested by loading in Playground.
