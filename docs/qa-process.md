# QA and AI-testing process

This is the testing process for the WordPress plugins Dan Knauss maintains with
coding agents: [Keel](https://github.com/dknauss/Keel), Agency Experience (AX,
a private sibling of Keel) and [Better by Default](https://github.com/WPYEG/Better-by-Default)
(BBD). It lives here because it leans on the
[wp-lab-pass](../skills/wp-lab-pass/SKILL.md) skill, and each plugin's
contributing guide points to this file instead of carrying its own copy.

Every change is tested at a depth that matches its risk, by someone other than
its author, against checks the author can't quietly change.

## Principles

1. **Evidence, not claims.** A result counts only with an artifact behind it: a
   log, a status code, a stored value, a screenshot. What wasn't checked is
   written down as NOT RUN, never rounded up.
2. **Nobody grades their own work.** The agent that builds a change doesn't
   write the checks it's graded on, and doesn't sign off on its own pass.
   Different model where we can, a human where it matters.
3. **A check binds only if the agent can't switch it off.** If the agent can
   edit a check, skip it, or forge its answer with the access it holds, the
   check is a default, not a boundary. Defaults are fine; call them that.
4. **Coverage comes from the promise, not from memory.** What gets tested is
   derived from what the plugin says it supports and promises users, so a gap
   shows up as an empty cell instead of depending on someone remembering it.

## Risk tiers

Every pull request names its tier in the description, and the tier sets the
minimum. The implementer proposes it. A reviewer or Dan can raise it; nobody
lowers it without saying why.

| Tier | What it covers | Minimum before merge |
| --- | --- | --- |
| 0 Docs | Copy, docs, comments, translations | Repository CI green |
| 1 Routine | UI, styling, settings with no security or data effect, refactors with full unit coverage | Tier 0, plus unit tests seen to fail first, plus a review by a different model |
| 2 Behaviour | New defaults, list tables, notices, Site Health checks, anything a site owner can see change | Tier 1, plus a lab pass with the coverage matrix filled in |
| 3 Sensitive | Authorization and capabilities, login and passwords, secrets, personal data, outbound mail or HTTP, destructive or bulk operations, multisite policy | Tier 2, plus separate-tester probes committed before any code, plus every probe resolved (PASS, a FAIL that was fixed, or a DISPUTED that Dan decided) |
| 4 Release | Release candidates and anything going to WordPress.org | Tier 3 for the changes in it, plus an adversarial review of the candidate, plus an independent re-test of every fix |

A Tier 3 change ported between Keel and AX gets probes in both repositories.
The code paths differ, and a pre-release review has found AX-only siblings of a
Keel finding that Keel's probes would never have reached.

## The standard pass

Each pass is written into an evidence record that ships with the pull request.

- **Unit tests must be able to fail.** Break the thing, watch the test go red,
  then trust it. Stubs only prove what their author believed, so a unit test
  never stands in for a lab at Tier 2 and up.
- **CI gates.** Lint, PHP compatibility to the declared floor, static analysis
  where it exists, the compatibility matrix, and the Keel/AX counterpart check.
  A flaky gate is re-run once. A second failure is investigated. Known flakes
  are listed in each repository, so nobody re-runs a real failure into green.
- **A lab pass (Tier 2 and up).** The wp-lab-pass procedure on a real,
  throwaway WordPress site, with its evidence template.
- **The coverage matrix.** Rows come from what the code declares: database
  engine and driver, oldest and newest supported WordPress and PHP, single site
  and multisite, persistent object cache, browser or HTTP runner. Every cell is
  PASS, FAIL, NOT RUN or N/A.
- **Review by a different model.** Claude's pull requests get a Codex review,
  and the other way round. The reviewer reads the diff and the evidence record,
  and says whether the record supports the claims, not only whether the code
  looks right.

## Separate tester (Tier 3 and up)

The method is in [separate-tester.md](../skills/wp-lab-pass/references/separate-tester.md).
This process adds three rules to it.

1. **The builder never writes the tester's brief.** The brief decides what the
   tester reads and which probes it favours, so a builder that writes it still
   frames its own exam. A coordinating session writes it from the issue, or Dan
   does. Dan writes it himself for anything touching login or personal data.
2. **The tester works from what the plugin promises, never from the change.**
   Its inputs are the issue, the decided roadmap rule, the readme and docs, the
   declared support surface and WordPress core source. Never the branch, the
   diff, the builder's plan or its notes.
3. **A second session spot-checks the results.** The tester doesn't run
   anything; the builder runs the probes and reports. At Tier 3 the tester or a
   fresh session re-runs, from the record's own commands, every probe that
   failed and was fixed, plus two or three passing probes it picks.

At least half the probes should aim at what authors skip: the accounts that
must not be flagged, edge cases and collisions, who may see a result, scale and
cost, and every database engine in the matrix.

The limits stay on the record. The tester and implementer lines are
declarations any agent could type. Two models from different companies share
much of their training and often share blind spots. Git proves the order of
commits, not the honesty of the results.

## Adversarial review and re-test (Tier 4)

1. **Attack.** A session that didn't build the release reads `main` as an
   attacker: role boundaries, multisite policy, stored secrets, shared budgets,
   input handling. Proofs of concept run in an offline lab. Reports stay
   private, as each repository's `SECURITY.md` requires.
2. **Fix.** Ordinary Tier 3 pull requests, with probes built from each finding.
3. **Re-test.** A fresh session, which wrote neither the report nor the fixes,
   re-runs every original proof as a bypass attempt against the merged commit,
   in every plugin the finding applies to. It confirms the tested commit is the
   one that will be tagged.
4. **Release.** Only after the re-test passes. Gaps the re-test couldn't cover
   go into the release record.

Outside testers are welcome on these terms: Keel is public, so anyone can run
checks against it and file GitHub issues. We don't install their tooling, share
private repositories, or promise an endorsement. A finding that holds up counts
as independent evidence, and it becomes a probe so it stays caught.

## Labs

A lab is built fresh for each pass from a seed script, snapshotted before
anything destructive, and torn down at the end.

| Where | Use it for | Limits |
| --- | --- | --- |
| The agent's sandbox: WordPress with MariaDB (first choice) | Server-side probes, multisite, scale runs, offline security proofs, browser probes | Can't always reach WordPress Playground or wordpress.org downloads |
| CI matrix | MySQL 8, Redis object cache, the oldest supported WordPress and PHP | Runs only what is committed; not a place to explore |
| SQLite | The SQLite row of the matrix | Never the only engine: one check passed on SQLite and failed on MySQL |
| WordPress Playground | Demos and reviewer walk-throughs from blueprints | SQLite only |
| A local Studio site | Only when Dan asks | Dan prunes these himself |

- **Seed, don't restore.** A versioned seed script builds users for each role,
  content, and the plugin's settings, saved through the plugin's own sanitizer.
  Never force stored data into a shape the plugin doesn't write.
- **Snapshot before destructive steps.** Take a database dump or a copy of the
  SQLite file before uninstall, migration, bulk or race probes, so a failed run
  rewinds instead of rebuilding.
- **Leave no secrets.** Generated passwords live in memory only. Mail captures
  keep pass or fail metadata, not message bodies, cookies or nonces.
- **Name the blind spots.** Anything the lab couldn't see goes into the matrix
  as NOT RUN, with the reason.

## Guarding the guardrails

A check defined in the repository the agent edits can be weakened in the same
pull request it grades, and agents that act as the repository owner inherit
the owner's exemptions. The setup for one maintainer working with agents:

1. **Only a human merge moves code.** Agents push to their own branches and
   open draft pull requests. They never merge, tag, or push to the default
   branch on their own.
2. **Judge the pull request by the default branch's rule.** Guardrail checks
   run from the default branch's copy of the checker (a `pull_request_target`
   job that checks out the base branch and reads only the pull request's commit
   list, never running its code). A branch can propose a weaker check, but it
   isn't graded by it.
3. **Flag guardrail edits loudly.** That base-run check labels and summarizes
   any pull request that touches the workflow files, the checkers, their tests
   and fixtures, or an existing probe file. It warns rather than blocks, because
   point 2 already keeps a weakened checker from grading its own pull request.
   Dan reads those diffs before merging. Agents put guardrail changes in their
   own pull request, never bundled with a feature.
4. **Protect the tests, not only the workflow.** Weakening a fixture weakens
   the check just as surely.
5. **Make the checks required, with no admin bypass.** Otherwise a failing
   check is a warning, and the owner's exemption is the agent's exemption.

### The access problem underneath

Every rule above binds only an actor who can't change the rules. Today agents
often act as Dan: the GitHub tools open and merge pull requests under his
account, and a local agent can run `gh` signed in as him, with admin rights on
the repository. An admin token can edit branch protection, rulesets and
required checks, so "no admin bypass" stops a merge but not an agent that
switches the protection off first. Root on the machine reaches the same token
and any unlocked signing key. Until agents stop holding the owner's
credentials, the guardrails here are defaults, not boundaries.

What already holds in cloud sessions: the git proxy only lets an agent push to
its own branch, and it refuses tag pushes, branch deletes and repository
settings changes. Merges through the GitHub tools are not refused, so the rule
that only Dan's explicit go merges is still a promise.

The fix is to take the keys away. The free route, in order of payoff:

1. **Rulesets on the default branch with an empty bypass list.** Require a pull
   request, require the status checks (including the probe and guardrail
   checks), block force pushes and deletion. Nobody, Dan included, merges red.
   Agents in cloud sessions have no tool that edits rulesets, so this holds
   against them even though they act as Dan. Rulesets are free on public
   repositories; on a private repository owned by a free personal account they
   aren't enforced. Keel and BBD are public, so they're covered free. AX is
   private, so it needs GitHub Pro; without it, AX relies on points 2 to 4.
2. **A free machine account for local agents.** GitHub allows one machine
   account per person at no cost. Add it as a collaborator (Write on a personal
   repository, never Admin) and give local agent sessions its fine-grained
   token, with no Administration or Workflows permission. With that token an
   agent can't change rulesets or edit workflow files.
3. **Keep Dan's own login out of agent sessions.** Local agents use the machine
   account's token through their own `gh` config, don't run as root, and never
   see Dan's signing key unlocked.
4. **Merges, tags and releases stay Dan's acts.** Cloud sessions can still merge
   as Dan through the GitHub tools; the rulesets make sure what they merge is
   green, and the rule that they merge only on Dan's explicit go covers the
   rest.

Required CODEOWNERS review is left out on purpose for now. GitHub won't let an
author approve their own pull request, and cloud agents open pull requests as
Dan, so requiring his review would block every one of them. It becomes useful
if cloud sessions ever run under the machine account too.

## Where this came from

Replies to three posts on [Bad Sector](https://badsector.blog/) shaped this
process: [A lab is supposed to disagree with you](https://badsector.blog/a-lab-is-supposed-to-disagree-with-you/),
[Don't let your agent grade its own homework](https://badsector.blog/dont-let-your-agent-grade-its-own-homework/),
and [A guardrail your agent can bypass isn't a guardrail](https://badsector.blog/guardrail-agent-can-bypass/).

| Question or point | Where it landed |
| --- | --- |
| Does a lab record list the engines it never ran on? | The coverage matrix |
| Does a lab pass ever face a check its author didn't write? | The separate tester |
| The checks should come from what the plugin promises, never from the change | Separate tester rule 2 |
| Wipe the lab or keep a golden seed? Snapshot before each accept | Labs: seed, don't restore; snapshot |
| A required check in the repository's own workflow file can be weakened in the same pull request | Guarding the guardrails 2 to 4 |
| A review only holds if the agent can't rewrite the test it's graded on | Principle 3 |
| Own worktree, no push rights, only a human merge ships | Guarding the guardrails 1 |
