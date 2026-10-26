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
- Unperformed checks and limits, including any transport or filesystem interception.
- Cleanup: restored options/scopes, removed users/sessions/fixtures, source mapping,
  and final runner state. Never include credentials or real payloads.
