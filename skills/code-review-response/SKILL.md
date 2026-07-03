---
name: code-review-response
description: Use when a pull request has automated code-review comments (Codex, Copilot, or similar) to triage and respond to, when deciding whether and how deeply a PR should be reviewed based on risk, or when a repo tracks canonical metrics (docs/current-metrics.md) that a change may drift. Triggers on Codex/Copilot findings, P1/P2/P3 review alerts, review-response, "merge past reviewer", and metrics-drift.
compatibility: "Any GitHub repo; the metrics section assumes a docs/current-metrics.md convention. gh CLI required."
---

# Code Review Response & Canonical Metrics

Gates enforce; reviewers judge. A merge gate can stop a silent *merge-past*, but *knowing* about a comment — and handling it well — is on the agent.

## Responding to automated code review (Codex, Copilot, etc.)

Before merging **any** pull request:

- **Surface every automated review comment to the user — the user decides significance, not the agent.** Report P3, unlabeled, and "seemingly insignificant" comments too. Never silently triage a comment away as too-trivial-to-mention.
- **Never merge past an unresolved P1 or P2.** Fix it, or reply in-thread with an explicit, reasoned rebuttal. A finding is "handled" only when it is fixed or consciously dismissed with a stated reason — never by silently resolving the thread. P3: acknowledge; fix if cheap, else note why deferred.
- **Re-trigger and confirm.** After pushing fixes, comment `@codex review` (or the bot's equivalent) so it re-evaluates, and confirm the re-review is clean before merge.
- **Do not `--admin`-merge past open review threads.** "Require conversation resolution before merging" is an active gate on these repos; respect it rather than bypassing it.

### Fetching the comments

```bash
# Inline review threads (Codex posts these, with P-badges):
gh api /repos/<OWNER>/<REPO>/pulls/<N>/comments --paginate
# Review summaries:
gh api /repos/<OWNER>/<REPO>/pulls/<N>/reviews --paginate
```

Codex is `chatgpt-codex-connector[bot]`; it posts a `COMMENTED` review with inline `![P1 Badge]` / `![P2 Badge]` / `![P3 Badge]` severity tags. To find PRs merged past unaddressed findings across an owner:

```bash
gh search prs --owner <OWNER> --commenter 'chatgpt-codex-connector[bot]' --updated '>=<date>' \
  --json number,repository,state
# For each: count 'P1 Badge'/'P2 Badge' in the comment bodies; flag any merged with
# no follow-up commit after the review timestamp.
```

## Size review to risk

Not every PR warrants the same scrutiny — assess the diff and route accordingly:

- **High-risk → mandatory deep review** (human or bot; do not merge past its findings): authentication, capabilities/roles, sessions/tokens, access-control gates, new or changed REST / `admin-post` / AJAX endpoints, SQL, deserialization, file writes, cross-site/multisite writes, or large structural diffs. Cover sensitive paths with `CODEOWNERS` so a review is forced.
- **Low-risk → light touch:** docs/typos, comments, test-only tweaks, lockfile-backed dependency bumps.
- State the risk call in the PR description when it is not obvious from the diff.

## Canonical metrics (`docs/current-metrics.md`)

Where a repo keeps `docs/current-metrics.md`:

- It is **hand-verified, not generated** — every number carries a re-derivation command, which guards against *confabulation* but not *drift*.
- **Any change that alters a counted quantity** (tests, assertions, PHP lines, doc sections) **must update `current-metrics.md` in the same commit — on sight.**
- Run the repo's metrics check before pushing (`composer verify:metrics`, or `bash .github/scripts/verify-metrics.sh docs/current-metrics.md`). Make it a **required status check** so drift blocks merge — but note: if the check's workflow is **path-filtered**, it will not run (and a required check that never runs blocks the PR forever), so the workflow must run on every PR (drop the path filter, or use an always-run + conditional-skip pattern) before it can be safely required.

## Prevention checklist (repo config, not just instructions)

Instructions can be skipped; gates cannot. For durable coverage:

- **"Require conversation resolution before merging"** (branch protection or a ruleset with a `pull_request` rule `required_review_thread_resolution: true`) on every repo — blocks merge past any open review thread. Rulesets on private repos need GitHub Pro or a public repo.
- **`CODEOWNERS`** on sensitive paths so significant diffs force a review.
- A **required, always-running** metrics/validate check where a canonical-metrics doc exists.
- Optionally a **scheduled sweep** that flags any PR with unaddressed P1–P3 as a backstop.
