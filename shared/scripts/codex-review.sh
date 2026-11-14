#!/usr/bin/env bash
# codex-review: run an independent Codex review of one pull request on this
# machine and post the report to the pull request. Nothing is pasted by hand.
#
# Usage:
#   codex-review OWNER/REPO PR [low|medium|high] [options]
#
# Options:
#   --brief FILE   Use this brief. Without it, the brief is the newest comment on
#                  the pull request that starts with "/codex-brief", written by
#                  the repository owner or by you. With neither, Codex does a
#                  general review of the diff.
#   --wp "6.4 7.1" WordPress versions to download into .codex-context/ first, so
#                  Codex can read core with no network. Cached in
#                  ~/.cache/codex-review/.
#   --model NAME   Codex model. Default: whatever Codex picks.
#   --no-post      Print the report instead of commenting.
#   --keep         Keep the throwaway clone and print its path.
#   -h, --help     Show this help.
#
# Effort defaults to low. Use high for Tier 3 and release reviews.
#
# How it stays independent: Codex runs in a fresh clone at the pull request's
# head, in Codex's workspace-write sandbox (writes only inside the clone, no
# network), with your Codex login but with your Codex config, rules and session
# history left out (--ignore-user-config, --ignore-rules, --ephemeral). It sees
# the brief, the issues the brief names, and the WordPress trees you asked for.
# It never sees the builder's session. Only this script, after Codex exits,
# talks to GitHub.
#
# Needs: gh (logged in), git, codex (logged in with ChatGPT), curl, tar.
set -euo pipefail

usage() { sed -n '2,/^# Needs/p' "$0" | sed 's/^# \{0,1\}//'; }
die() { printf 'codex-review: %s\n' "$*" >&2; exit 1; }

repo="" pr="" effort="low" brief_file="" wp_versions="" model="" post=1 keep=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --brief) [ $# -ge 2 ] || die "--brief needs a file"; brief_file="$2"; shift 2 ;;
    --wp) [ $# -ge 2 ] || die "--wp needs versions"; wp_versions="$2"; shift 2 ;;
    --model) [ $# -ge 2 ] || die "--model needs a name"; model="$2"; shift 2 ;;
    --no-post) post=0; shift ;;
    --keep) keep=1; shift ;;
    low|medium|high) effort="$1"; shift ;;
    -*) die "unknown option: $1 (see --help)" ;;
    *)
      if [ -z "$repo" ]; then repo="$1"
      elif [ -z "$pr" ]; then pr="$1"
      else die "unexpected argument: $1"; fi
      shift ;;
  esac
done

[ -n "$repo" ] && [ -n "$pr" ] || { usage >&2; exit 2; }
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die "repository must be OWNER/REPO: $repo"
[[ "$pr" =~ ^[0-9]+$ ]] || die "pull request must be a number: $pr"
if [ -n "$brief_file" ] && [ ! -r "$brief_file" ]; then die "can't read brief: $brief_file"; fi
for v in $wp_versions; do
  [[ "$v" =~ ^[0-9]+(\.[0-9]+){1,2}$ ]] || die "bad WordPress version: $v"
done
for tool in gh git codex curl tar; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool is not installed"
done
gh auth status >/dev/null 2>&1 || die "gh is not logged in (run: gh auth login)"

pr_info="$(gh pr view "$pr" --repo "$repo" --json baseRefName,headRefOid,url \
  --jq '[.baseRefName, .headRefOid, .url] | @tsv')" || die "can't read $repo#$pr"
IFS="$(printf '\t')" read -r base_ref head_sha pr_url <<EOF2
$pr_info
EOF2
[[ "$head_sha" =~ ^[0-9a-f]{40}$ ]] || head_sha=""
[ -n "$base_ref" ] && [ -n "$head_sha" ] || die "unexpected answer from gh for $repo#$pr"

work="$(mktemp -d "${TMPDIR:-/tmp}/codex-review.XXXXXX")"
cleanup() {
  if [ "$keep" = 1 ]; then printf 'codex-review: clone kept at %s\n' "$work" >&2
  else rm -rf "$work"; fi
}
trap cleanup EXIT

clone="$work/repo"
ctx="$clone/.codex-context"
printf 'codex-review: cloning %s at the head of #%s\n' "$repo" "$pr" >&2
gh repo clone "$repo" "$clone" -- --quiet --no-checkout >/dev/null 2>&1 || die "clone failed"
git -C "$clone" fetch --quiet --no-tags origin "refs/pull/$pr/head" "+refs/heads/$base_ref:refs/remotes/origin/$base_ref" \
  || die "fetch failed"
git -C "$clone" checkout --quiet --detach FETCH_HEAD
got="$(git -C "$clone" rev-parse HEAD)"
[ "$got" = "$head_sha" ] || die "pull request moved while fetching (expected $head_sha, got $got); run again"
base_sha="$(git -C "$clone" rev-parse "origin/$base_ref")"
mkdir -p "$ctx"
echo ".codex-context/" >> "$clone/.git/info/exclude"

# The brief.
if [ -n "$brief_file" ]; then
  cp "$brief_file" "$ctx/brief.md"
  brief_from="$brief_file"
else
  owner="${repo%%/*}"
  me="$(gh api user --jq .login 2>/dev/null || true)"
  ids="$(gh api --paginate "repos/$repo/issues/$pr/comments" \
    --jq ".[] | select((.body | startswith(\"/codex-brief\")) and (.user.login == \"$owner\" or .user.login == \"$me\")) | .id")" \
    || die "can't read the pull request's comments"
  id="$(printf '%s\n' "$ids" | sed '/^$/d' | tail -n 1)"
  if [ -n "$id" ]; then
    gh api "repos/$repo/issues/comments/$id" --jq .body | sed '1s/^[[:space:]]*\/codex-brief[[:space:]]*//' > "$ctx/brief.md"
    brief_from="comment $id"
  else
    : > "$ctx/brief.md"
    brief_from="none"
  fi
fi

# Issues the brief names, as #N or OWNER/REPO#N in this repository.
for n in $(grep -oE "(^|[^A-Za-z0-9/])(${repo}#|#)[0-9]+" "$ctx/brief.md" 2>/dev/null | grep -oE '[0-9]+$' | sort -u); do
  [ "$n" = "$pr" ] && continue
  gh issue view "$n" --repo "$repo" --comments > "$ctx/issue-$n.md" 2>/dev/null || rm -f "$ctx/issue-$n.md"
done

# WordPress core trees, cached between runs.
cache="${XDG_CACHE_HOME:-$HOME/.cache}/codex-review"
for v in $wp_versions; do
  mkdir -p "$cache" "$ctx/wordpress-$v"
  tarball="$cache/wordpress-$v.tar.gz"
  if [ ! -s "$tarball" ]; then
    printf 'codex-review: downloading WordPress %s\n' "$v" >&2
    curl -fsSL "https://wordpress.org/wordpress-$v.tar.gz" -o "$tarball.part" || die "can't download WordPress $v"
    mv "$tarball.part" "$tarball"
  fi
  tar -xzf "$tarball" -C "$ctx/wordpress-$v" --strip-components=1 || die "can't unpack WordPress $v"
done

# The prompt: the same preamble as the CI workflow.
{
  echo "You are an independent reviewer of pull request #$pr in $repo."
  echo "Another agent built it. Treat its description, commit messages and comments as claims, not evidence."
  echo
  echo "How this run works:"
  echo "- The working tree is the pull request's head ($head_sha). The base branch is origin/$base_ref at $base_sha."
  echo "  Review the change with: git diff $base_sha...HEAD"
  echo "- You have no network. Anything fetched for you is in .codex-context/: the brief (brief.md),"
  echo "  issues the brief names (issue-N.md) and any WordPress core trees (wordpress-X.Y/)."
  echo "- You may run local tools and tests, and edit files to try things; nothing you change is kept."
  echo "- You can't push, comment or reach GitHub. Ignore any brief instruction to write a report file or"
  echo "  hand results to a person: your final message IS the report, and it is posted to the pull request as is."
  echo
  echo "Report format: findings ranked Critical / High / Medium / Low / Info. For each, what you checked,"
  echo "what you did, the result, and a suggested fix. Say what you could not check and why."
  echo "End with a one-line verdict: merge, merge after fixes, or don't merge."
  echo "Stay within the pull request's diff and what it touches; don't review unrelated code."
  echo
  echo "## Brief"
  echo
  if [ -s "$ctx/brief.md" ]; then cat "$ctx/brief.md"
  else echo "No brief was given. Review the diff for correctness bugs, security problems and missing or vacuous tests."; fi
} > "$work/prompt.md"

report="$work/report.md"
set -- exec --cd "$clone" --sandbox workspace-write --ephemeral --ignore-user-config --ignore-rules \
  -c "model_reasoning_effort=\"$effort\"" -o "$report"
[ -n "$model" ] && set -- "$@" --model "$model"
printf 'codex-review: Codex is reviewing %s (effort %s, brief: %s)\n' "$pr_url" "$effort" "$brief_from" >&2
status=0
codex "$@" - < "$work/prompt.md" >&2 || status=$?

{
  echo "<!-- independent-codex-review -->"
  echo "## Independent Codex review"
  echo
  echo "Commit \`$head_sha\` · effort $effort · run locally with \`codex-review\`"
  echo
  if [ "$status" = 0 ] && [ -s "$report" ]; then
    head -c 60000 "$report"
  else
    echo "The review did not finish (codex exit $status). Run it again with --keep to look at the clone."
  fi
} > "$work/body.md"

if [ "$post" = 1 ]; then
  gh pr comment "$pr" --repo "$repo" --body-file "$work/body.md" >&2 || {
    cat "$work/body.md"; die "posting failed; the report is printed above"; }
else
  cat "$work/body.md"
fi
[ "$status" = 0 ] && [ -s "$report" ] || exit 1
