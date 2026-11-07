# Lab evidence record

- Date, source revision, resolved runtime source path or package checksum.
- Local target, runner, WordPress/PHP/database versions, single/multisite,
  activation scope, pre-existing running state.
- Observable claim and intercepted side effect; permitted control proving capture.
- Per-case role, resolved capabilities, request method, nonce condition, expected
  and observed status, response shape and scoped before/after state.
- Session origin: actual login or minted WordPress session; never retain tokens.
- Fixture effects: HTTP/mail interception, capability overrides, disabled jobs.
- Findings, fixes, failing-before/passing-after evidence, artifact location.
- Coverage matrix (below), filled in before the pass is called complete.
- Unperformed checks and limits, including any transport or filesystem interception.
- Cleanup: restored options/scopes, removed users/sessions/fixtures, source mapping,
  and final runner state. Never include credentials or real payloads.

## Coverage matrix

The environment line above records what ran. It cannot show what did not. Build
the rows from what the code **claims to support**, not from what this pass happened
to run on, so an environment nobody thought of still appears as a hole.

Take the rows from the declared support surface: the plugin header and readme
(`Requires at least`, `Tested up to`, `Requires PHP`), the CI matrix, and the
project's own compatibility notes. Include every axis the change could plausibly
depend on:

| Axis | Typical rows |
| --- | --- |
| Database engine and driver | MySQL (`mysqli`), MariaDB, SQLite integration (state the build: Studio, Playground, plugin version) |
| WordPress | oldest supported, latest stable, any beta/RC the project targets |
| PHP | oldest supported, newest supported |
| Topology | single site, multisite network-activated, multisite site-only |
| Object cache | none, persistent (Redis/Memcached) |
| Runner | Studio, wp-env, Playground, hosted (Jurassic Ninja), CI |

Mark every cell with exactly one of:

- **PASS**: an artefact from this pass or a named run shows it passing.
- **FAIL**: it failed; link the finding.
- **NOT RUN**: no evidence for this cell. Say why (no runner available, out of
  scope, deferred to CI) and where it will be covered, if anywhere.
- **N/A**: the change cannot depend on this axis; give the one-line reason.

Example:

| Cell | Result | Evidence or reason |
| --- | --- | --- |
| SQLite (Studio, sqlite-database-integration 2.2.x), WP 7.1, PHP 8.4, single | PASS | lab run 2026-10-23, 15/15 |
| MySQL 8, WP 6.4, PHP 7.4, multisite + Redis | NOT RUN | no MySQL runner locally; covered by CI database matrix |
| MariaDB 10.11, WP 7.1, PHP 8.3, multisite + Redis | NOT RUN | same |

Rules:

- A cell counts as PASS only with an artefact. "Same code path" is a reason for
  N/A, never for PASS.
- A pass on one database engine is no evidence about another. Drivers differ in
  which features, properties and transaction semantics they expose, and a check
  that fails closed on one engine can look identical to a passing check.
- If any cell is NOT RUN, the record's summary says so in its first lines. A
  record whose only PASS cells share one engine, runner or topology must not be
  summarised as "passed" without that qualifier.
