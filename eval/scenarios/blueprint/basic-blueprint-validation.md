# Basic Blueprint Validation

Skill: blueprint

WordPress Playground Blueprints should remain trusted JSON declarations that follow the documented schema and keep execution steps explicit.

## Valid minimal Blueprint shape

**Given** a user asks for help creating or reviewing a WordPress Playground Blueprint JSON file
**When** the `blueprint` skill is selected
**Then** it should validate top-level Blueprint keys against the documented schema and steer the user toward explicit `steps` when execution order matters

### Examples

Pass:
```json
{
  "$schema": "https://playground.wordpress.net/blueprint-schema.json",
  "landingPage": "/wp-admin/",
  "preferredVersions": {
    "php": "8.2",
    "wp": "latest"
  },
  "steps": [
    {
      "step": "login",
      "username": "admin",
      "password": "password"
    }
  ]
}
```

Fail:
```json
{
  "$schema": "https://playground.wordpress.net/blueprint-schema.json",
  "landingPage": "/wp-admin/",
  "preferredVersions": {
    "php": "8.2",
    "wp": "latest"
  },
  "login": true,
  "unsupportedFlag": "invented-property"
}
```
This invents unsupported top-level properties and avoids the explicit `steps` array that the skill should recommend when order and behavior must be clear.
