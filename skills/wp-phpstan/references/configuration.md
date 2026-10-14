# PHPStan configuration (WordPress)

This reference documents a minimal, WordPress-friendly PHPStan setup and baseline workflow.

## Minimal `phpstan.neon` template

Use the repo’s existing layout. The example below is intentionally conservative and should be adapted to the project’s actual directories.

```neon
# Include the baseline only if the file exists.
includes:
    - phpstan-baseline.neon

parameters:
    level: 5
    paths:
        - src/
        - includes/

    excludePaths:
        - vendor/
        - vendor-prefixed/
        - node_modules/
        - tests/

    ignoreErrors:
        # Add targeted exceptions only when necessary.
```

Guidelines:

- Prefer analyzing first-party code only.
- Exclude anything generated or vendored.
- Keep `ignoreErrors` patterns narrow and grouped by dependency.

## Baseline workflow

Baselines help you adopt PHPStan in legacy code without accepting new regressions.

```bash
# Generate a baseline (explicit filename)
vendor/bin/phpstan analyse --generate-baseline phpstan-baseline.neon

# Update an existing baseline (defaults)
vendor/bin/phpstan analyse --generate-baseline
```

Best practices:

- Avoid adding new errors to the baseline; fix the new code instead.
- Treat baseline changes like code changes: review in PRs.
- Chip away at the baseline gradually (remove entries as you fix root causes).

## PHPStan 2.3 notes (October 2026)

- **Upgrade**: 2.3 analyses WordPress core ~3× faster than 2.1 with no config
  changes; a `^2.1` constraint already allows it. Projects still on `^1.x` (and
  `szepeviktor/phpstan-wordpress` `^1.x`) should move to 2.x first.
- **Result cache survives dependency updates**: it is invalidated only by a
  PHPStan upgrade or config change. Persist it in CI between runs:

```yaml
- uses: actions/cache@v4
  with:
    path: /tmp/phpstan   # match parameters.tmpDir if set
    key: phpstan-${{ hashFiles('composer.lock', 'phpstan.neon*') }}
    restore-keys: phpstan-
```

- **Turbo** (optional native extension shipped inside `phpstan/phpstan`) gives a
  further ~2.5× speedup; PHPStan restarts itself with the needed `php -d` flags.
- **Bleeding edge** (`includes: - phar://phpstan.phar/conf/bleedingEdge.neon`) adds
  unused-code rules: `variable.unused`, `assign.unused`, `foreach.unusedValue`,
  `closure.unusedUse`, `function.unusedParameter`, `method.unusedParameter`
  (private methods). WordPress hook callbacks often must accept parameters they
  ignore — prefer a narrow `ignoreErrors` by identifier and path over renaming
  args or deleting them. Expect to regenerate the baseline when enabling it.

Source: https://phpstan.org/blog/phpstan-2-3-leap-in-performance
