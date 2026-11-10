# Separate tester

In a single-agent lab pass, the agent that wrote the change also decides what
to probe. That's a conflict of interest, however careful the agent is. It knows
which paths it handled, and it will drift toward checking those. The coverage
matrix keeps the *environments* honest, because its rows come from the declared
support surface. It does nothing about the *checks* run inside each cell.

A separate tester fixes that. One agent writes the probes before the build,
working only from what the change is supposed to do. A different agent then
writes the change and has to pass probes it never wrote.

## When to use it

Use it for changes that touch authorization, authentication, secrets, personal
data, destructive operations, or anything that sends mail or makes outbound
requests on a user's behalf. Use it for a release candidate. Use it whenever an
earlier lab pass on the same feature found a defect the author's own probes
had missed.

Skip it for copy, styling, docs, and small refactors with unit tests. The
single-agent pass is fine there, and the second run isn't worth it.

## Roles

| | Tester | Implementer |
| --- | --- | --- |
| Goes | First, before any code | Second |
| Sees | Issue text, readme, plugin header, public docs, the declared support surface, existing behaviour on a clean lab | Everything, including the tester's probe file |
| Doesn't see | The diff, the implementer's plan or branch, the implementer's own notes | — |
| Writes | The probe file, in one commit | The change, the lab harness, the evidence record |
| May not | Read or suggest the implementation | Edit or delete the tester's probes |

**Use a different model for each role** if you can, such as Codex testing
Claude's work or the other way round. Two runs of the same model share blind
spots: what one forgets to test, the other forgets to build. If both roles
must run on one model, give them separate sessions with no shared context, and
record that in the probe file.

A human can be the tester. A probe file a person wrote counts the same.

## The probe file

The tester commits one Markdown file per change, at a path the project
chooses (Keel uses `docs/review/probes/<slug>.md`). It is the tester's only
output.

```markdown
# Probes: <change, in plain words>

Tester: <agent and model, or a person>
Implementer: <agent and model, if known>
Saw: <what the tester was given, e.g. "issue #123, readme.txt, a clean lab on 7.1">

| ID | Behaviour to prove | Role | Artefact that proves it | Expected |
| --- | --- | --- | --- | --- |
| P1 | A suppressed environment sends no mail | administrator | mail capture file | 0 records |
| P2 | An editor can't reach the settings action | editor | HTTP status, option unchanged | 403, no write |
| P3 | ... | | | |
```

Write each probe as an observable outcome with the artefact named, exactly as
"Inputs required" asks of any lab pass. A probe that reads "the settings work"
is no probe.

The tester should aim at the edges an author tends to skip: the denied role,
the suppressed environment, the second site on a network, the empty and the
huge input, the request without a nonce, the setting locked in `wp-config.php`.

## The implementer's rules

1. Read the probe file before you write code. The probes are part of the
   spec.
2. Run every tester probe in the lab. Each gets a result in the evidence
   record: PASS, FAIL or NOT RUN, with the artefact or the reason.
3. Add your own probes freely, with IDs starting `I` (I1, I2, ...) so they
   stay distinct from the tester's. They don't go in the probe file.
4. Never edit, reword, weaken or delete a tester probe. If you think one is
   wrong (it tests the wrong thing, or expects behaviour the spec rules out),
   mark it **DISPUTED** in the record with your reason and leave the call to
   a human. A disputed probe is not a pass.
5. A FAIL on a tester probe that you then fix needs failing-before and
   passing-after evidence, the same as any other finding.

## Evidence record additions

Add these to the record from the [evidence template](evidence-template.md):

- The probe file's path and the commit that added it.
- An **Author** column in the results: `tester` or `implementer` for each probe.
- A summary line counting the tester probes: `Tester probes: 7 PASS, 1 FAIL,
  1 DISPUTED, 0 NOT RUN`. The pass can't be summarised as passed while any
  tester probe is FAIL, DISPUTED or NOT RUN.

## Making it checkable

Without enforcement, "the tester went first" is just a claim. Two facts can be
checked mechanically from git, and a project should check them in CI:

1. **The probes came before the build.** The commit that adds the probe file
   touches nothing else, and no earlier commit on the branch touches code.
2. **Nobody changed the probes afterward.** No later commit on the branch
   modifies or deletes the probe file.

Mark the tester's commit with a `Lab-Role: tester` trailer so the check can
find it, and fail if the `Tester:` and `Implementer:` lines name the same
agent.

What git can't prove: that the tester never saw the plan, and that the
trailer and the `Tester:` line are true. Those are declarations. Record them
honestly and say so in the record. The check stops the probes from being moved
after the fact. Keeping the tester's view clean is up to whoever starts the
tester session.

## Failure modes

- **The tester reads the branch.** Then the probes describe the
  implementation, not the requirement. Start the tester from the default
  branch, before the implementer's branch exists, or give it no repository
  access beyond public docs.
- **The probes are all happy paths.** A tester working only from the
  feature's description will mostly write "it works" probes. Tell it to spend
  at least half its probes on denial, suppression, and boundary cases.
- **The implementer rewrites a probe "to clarify" it.** That is editing a
  tester probe. Dispute it instead.
- **Every probe is DISPUTED.** The spec was ambiguous. Stop and ask a human
  before building more on it.
