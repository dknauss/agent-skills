# QA and AI-testing process

How Dan Knauss tests the WordPress plugins he maintains with coding agents:
[Keel](https://github.com/dknauss/Keel), Agency Experience (AX, private) and
[Better by Default](https://github.com/WPYEG/Better-by-Default) (BBD). Each
plugin's contributing guide points here.

Every change is tested at a depth that matches its risk, by someone other than
its author. A result counts only with evidence behind it (a log, a status code,
a stored value, a screenshot); anything not checked is written down as NOT RUN.

## Four rules

1. **Dan presses merge. Nobody else does.** Agents push to their own branches
   and open pull requests. They never merge, tag or release, and no agent
   account holds Write. Dan reads every change before merging, including
   changes to workflows and tests.
2. **CI must pass.** Each repository's ruleset requires a pull request and the
   status checks, pinned to GitHub Actions so nobody can fake one with a commit
   status, with no bypass, no force pushes and no branch deletion. Only Dan
   can create `v*` tags.
3. **Secrets live only in release environments, and Dan approves each run.**
   A repository-level secret can be read by any workflow on any branch the
   moment that branch is pushed, before any pull request exists. Agent sessions
   can push workflow files, so the wordpress.org SVN login lives in the
   `wordpress-org` environment: only `v*` tags can deploy, and Dan approves
   every run. Releases are immutable once published.
4. **A second model reviews only what's risky.** For login, permissions, secrets
   and releases, Dan runs one command on his Mac, `codex-review OWNER/REPO PR
   high`. Everything else gets CI and the automatic review a pull request
   already gets.

## How much testing

| Change | Before Dan merges |
| --- | --- |
| Docs, copy, translations | CI green |
| UI, settings, refactors | CI green, plus unit tests seen to fail first |
| Anything a site owner sees change | The above, plus a lab pass ([wp-lab-pass](../skills/wp-lab-pass/SKILL.md)) on a real throwaway site, with the coverage matrix filled in (database engine, oldest and newest WordPress and PHP, single site and multisite) |
| Login, permissions, secrets, personal data, outbound mail or HTTP, destructive or multisite policy | The above, plus tester probes written before the code, and a Codex review |
| A release | The above for every change in it, plus an attack-minded review of the candidate and a fresh re-test of every fix |

**Tester probes.** A separate session, ideally on another model, writes the
checks from the issue, the readme and WordPress core, never from the branch or
the diff. It commits them to `docs/review/probes/` before any code. The
"Tester probes came first" check fails a pull request whose probes arrived late
or changed afterwards. The builder never writes the tester's brief; the
coordinator or Dan does. Method:
[separate-tester.md](../skills/wp-lab-pass/references/separate-tester.md).

**Labs.** Build fresh from a seed script, snapshot before anything destructive,
keep no secrets, and list what the lab couldn't see as NOT RUN. Use the agent's
sandbox with MariaDB first, the CI matrix for MySQL 8, Redis and the oldest
supported versions, and SQLite or Playground only alongside a real database.

## Setting up a repository

Run [`shared/scripts/qa-bootstrap.sh`](../shared/scripts/qa-bootstrap.sh) from
Dan's own login, never from an agent session. It is a dry run until `--apply`,
and safe to re-run. It sets the branch and tag rulesets, limits deploy
environments to `v*` tags with Dan as reviewer, turns on immutable releases and
auto-delete of merged branches, lists repository-level secrets to move, and
lists anyone else who can push or merge.

```sh
qa-bootstrap.sh dknauss/Keel            # read what it would change
qa-bootstrap.sh dknauss/Keel --apply
```

## What this doesn't stop

Cloud agent sessions act as Dan through the Claude GitHub App, so GitHub can't
tell their merge from his. Rule 1 holds for them by instruction only, and
they also open pull requests as Dan, which is why a required approving review
would block every one of them. What does hold: the cloud git proxy lets a
session push only to its own branch, and refuses tags, branch deletes and
settings changes; a session can't read a secret held in an environment.

Probe files say who the tester was, and git can't prove it. A builder session
could also post its own reviewer's brief, since every session is Dan on
GitHub. Both are covered by Dan reading the pull request before he merges.

## Where this came from

Replies to [A lab is supposed to disagree with you](https://badsector.blog/a-lab-is-supposed-to-disagree-with-you/),
[Don't let your agent grade its own homework](https://badsector.blog/dont-let-your-agent-grade-its-own-homework/)
and [A guardrail your agent can bypass isn't a guardrail](https://badsector.blog/guardrail-agent-can-bypass/)
on Bad Sector. A red-team pass on 2026-11-14 found that an agent account
could approve its own guardrail changes with a label, and that branch
workflows could read the release secrets. Labels and the agent account went;
the four rules above replaced them.
