# Independent Codex review in CI

`.github/workflows/codex-review.yml` is a reusable workflow. It runs Codex on one
pull request with a brief and posts the report back to that pull request as a
comment. It replaces running Codex by hand on a laptop and pasting the report
back and forth. It is the "review by a different model" step in
[qa-process.md](qa-process.md).

## What it does

1. Checks out the pull request's head with full history, plus the base branch.
2. Before Codex starts, fetches everything it will need into `.codex-context/`:
   the brief, every issue the brief names (`#378` or `owner/repo#378`), and any
   WordPress core versions the caller asks for.
3. Runs `openai/codex-action@v1` with the `:workspace` permission profile. That
   profile gives no network access, drops sudo, and keeps the API key in the
   action's proxy, so Codex can't read it.
4. A separate job with write access posts the final message as a comment,
   headed "Independent Codex review" with the commit and a link to the run. It
   then removes the `codex-review` label, so adding the label again starts a
   fresh review.

Codex gets no builder session, chat history or write token. Its prompt is the
brief plus a fixed preamble: claims in the pull request are not evidence, rank
findings, say what wasn't checked, and end with a verdict.

## Wiring it into a repository

```yaml
# .github/workflows/codex-review.yml in the plugin repository
name: Codex review
on:
  issue_comment:
    types: [created]
  pull_request_target:
    types: [labeled]
jobs:
  codex:
    if: >-
      (github.event_name == 'issue_comment' && github.event.issue.pull_request &&
       startsWith(github.event.comment.body, '/codex-review') &&
       github.event.comment.user.login == github.repository_owner) ||
      (github.event_name == 'pull_request_target' &&
       github.event.label.name == 'codex-review' &&
       github.event.sender.login == github.repository_owner)
    uses: dknauss/agent-skills/.github/workflows/codex-review.yml@trunk
    with:
      pr-number: ${{ github.event.issue.number || github.event.pull_request.number }}
      brief: ${{ github.event.comment.body }}
      wordpress-versions: "6.4 7.1"
    secrets:
      OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

Only the repository owner can start a review, by commenting `/codex-review`
followed by the brief or by adding the `codex-review` label. The agent machine
account has Write access, but it can't start one. Cloud agent sessions act as
the owner, so a coordinator thread can post a brief for its reviewer this way.
The builder thread must not post one: the QA process forbids the builder from
writing the reviewer's brief.

## One-time setup

- Add an OpenAI API key as the repository secret `OPENAI_API_KEY` (Settings →
  Secrets and variables → Actions). Usage is billed to that API account,
  separately from a ChatGPT subscription.
- Create the `codex-review` label if you want to use the label trigger.

## Limits

- No network while Codex runs. Anything it needs has to come in through
  `.codex-context/`, or already be in the repository.
- A brief that asks for a live lab (WordPress Studio, MariaDB) can't be run
  here. Codex says which checks it couldn't run.
- `issue_comment` and `pull_request_target` workflows run from the default
  branch, so the caller workflow works only after it has merged.
