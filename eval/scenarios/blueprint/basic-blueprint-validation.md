# Blueprint skill validates a minimal WordPress Playground blueprint

## Given
- a user asks for help creating or reviewing a WordPress Playground Blueprint JSON file
- the Blueprint uses the official Playground schema URL
- the Blueprint sets `landingPage`, `preferredVersions`, and a simple `login` step

## When
- the `blueprint` skill is selected

## Then
- it should validate top-level Blueprint keys against the documented schema
- it should preserve the rule that Blueprints are trusted JSON-only declarations
- it should guide the user toward explicit `steps` when execution order matters
- it should avoid inventing unsupported Blueprint properties
