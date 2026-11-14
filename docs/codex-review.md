# Independent Codex review

One command runs an independent Codex review of a pull request on Dan's Mac
and posts the report to the pull request. Nothing is pasted between Claude and
Codex. It is the "review by a different model" step in
[qa-process.md](qa-process.md), for Tier 3 changes and releases.

```sh
codex-review dknauss/Keel 380 high --wp "6.4 7.1"
```

## Install on the Mac (once)

```sh
mkdir -p ~/bin
curl -fsSL https://raw.githubusercontent.com/dknauss/agent-skills/trunk/shared/scripts/codex-review.sh -o ~/bin/codex-review
chmod +x ~/bin/codex-review
```

`~/bin` must be on your `PATH`. It needs `gh` logged in as you, and `codex`
logged in with ChatGPT (`codex login`). Runs use your ChatGPT plan, not an API
key. Run the `curl` line again to update.

## Giving it a brief

The brief comes from the coordinator, never from the builder. Two ways:

- The coordinator (or you) posts a comment on the pull request that starts
  with `/codex-brief`, followed by the brief. The script uses the newest such
  comment written by the repository owner or by you.
- Or pass a file: `codex-review dknauss/Keel 380 high --brief brief.md`.

With no brief, Codex does a general review of the diff for bugs, security
problems and vacuous tests.

## What it does

1. Clones the repository into a throwaway folder and checks out the pull
   request's head, plus the base branch. It stops if the pull request moves
   while it fetches.
2. Before Codex starts, saves into `.codex-context/` the brief, every issue
   the brief names (`#378` or `owner/repo#378`), and the WordPress versions
   given with `--wp` (downloads are cached in `~/.cache/codex-review/`).
3. Runs `codex exec` in that folder with the `workspace-write` sandbox (writes
   only inside the throwaway clone, no network), `--ignore-user-config`,
   `--ignore-rules` and `--ephemeral`, so your own Codex config, rules and
   session history stay out of it. The prompt is the brief plus a fixed
   preamble: claims in the pull request are not evidence, rank findings, say
   what wasn't checked, end with a verdict.
4. After Codex exits, posts its final message as a comment headed
   "Independent Codex review" with the commit and effort, then deletes the
   clone. Codex itself never talks to GitHub.

Options: `low|medium|high` effort (default `low`), `--wp "6.4 7.1"`,
`--model NAME`, `--no-post` to print instead of commenting, `--keep` to keep
the clone for a look afterwards. `codex-review --help` lists them.

Limits: no network while Codex runs, so anything it needs comes in through
`.codex-context/` or the repository. A brief that asks for a live lab (Studio,
MariaDB) can't be run inside the sandbox; Codex says which checks it couldn't
run. The sandbox stops writes outside the clone and all network, but Codex can
still read files your user can read, so run it from your own login, not a
shared one.

## When to use it

Only on purpose, and only once per request: Tier 3 changes (login,
capabilities, secrets, personal data and the like) and release candidates,
with a brief. Routine pull requests don't need it. CI and the automatic review
a pull request already gets when it opens are enough. Use `high` for Tier 3
and releases, `low` for a quick second look.

## Fallback: the same review in GitHub Actions

`.github/workflows/codex-review.yml` is a reusable workflow. It runs Codex on one
pull request with a brief and posts the report back to that pull request as a
comment. Use it only when the Mac
isn't available: it bills an OpenAI API key, while the local command uses your
ChatGPT plan. It does the same review as `codex-review` above.

### What the workflow does

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

### Wiring it into a repository

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
    # A caller can only narrow token permissions, so grant what the shared
    # workflow's jobs use.
    permissions:
      contents: read
      issues: write
      pull-requests: write
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

Effort defaults to `low`, and the prompt keeps Codex to the diff. Raise the
effort for a hard review by putting it on the first line, for example
`/codex-review high`, then the brief on the following lines.

### One-time setup

- Add an OpenAI API key as the repository secret `OPENAI_API_KEY` (Settings →
  Secrets and variables → Actions). Usage is billed to that API account,
  separately from a ChatGPT subscription.
- Create the `codex-review` label if you want to use the label trigger.

### Limits

- No network while Codex runs. Anything it needs has to come in through
  `.codex-context/`, or already be in the repository.
- A brief that asks for a live lab (WordPress Studio, MariaDB) can't be run
  here. Codex says which checks it couldn't run.
- `issue_comment` and `pull_request_target` workflows run from the default
  branch, so the caller workflow works only after it has merged.
