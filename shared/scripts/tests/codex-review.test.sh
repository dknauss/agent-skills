#!/usr/bin/env bash
# Tests for shared/scripts/codex-review.sh with fake gh and codex binaries and a
# real local git remote. Run: bash shared/scripts/tests/codex-review.test.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/../codex-review.sh"
t="$(mktemp -d)"
fails=0
ok() { printf 'ok   %s\n' "$1"; }
bad() { printf 'FAIL %s\n' "$1"; fails=$((fails + 1)); }

# A remote with a base branch and a pull request head under refs/pull/7/head.
git init -q -b trunk "$t/src"
git -C "$t/src" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m base
git -C "$t/src" checkout -q -b feature
echo change > "$t/src/file.txt"
git -C "$t/src" add file.txt
git -C "$t/src" -c user.name=t -c user.email=t@example.invalid commit -q -m head
head_sha="$(git -C "$t/src" rev-parse HEAD)"
git clone -q --bare "$t/src" "$t/remote.git"
git -C "$t/remote.git" update-ref refs/pull/7/head "$head_sha"

mkdir -p "$t/bin"
cat > "$t/bin/gh" <<'GH'
#!/usr/bin/env bash
echo "gh $*" >> "$FAKE_LOG"
case "$1 $2" in
  "auth status") exit 0 ;;
  "pr view") printf 'trunk\t%s\thttps://github.com/o/r/pull/7\n' "$FAKE_HEAD" ;;
  "repo clone") git clone -q --no-checkout "$FAKE_REMOTE" "$4" ;;
  "api user") echo me ;;
  "api --paginate") printf '%s\n' ${FAKE_BRIEF_IDS:-} ;;
  "issue view") echo "issue $3 body" ;;
  "pr comment") cp "$7" "$FAKE_POSTED" ;;
  *)
    if [ "$1" = api ] && [[ "$2" == repos/*/issues/comments/* ]]; then
      printf '/codex-brief\nCheck #12 and o/r#13 but not #7.\n'
    else
      echo "unexpected gh call: $*" >&2; exit 9
    fi ;;
esac
GH
cat > "$t/bin/codex" <<'CX'
#!/usr/bin/env bash
echo "codex $*" >> "$FAKE_LOG"
prompt="$(cat)"
printf '%s' "$prompt" > "$FAKE_PROMPT"
out=""; cd_dir=""
while [ $# -gt 0 ]; do
  case "$1" in -o) out="$2"; shift ;; --cd) cd_dir="$2"; shift ;; esac; shift
done
ls "$cd_dir/.codex-context" > "$FAKE_CTX"
git -C "$cd_dir" rev-parse HEAD > "$FAKE_SEEN_HEAD"
[ "${FAKE_CODEX_FAIL:-0}" = 1 ] && exit 3
printf 'No findings.\nVerdict: merge.\n' > "$out"
CX
chmod +x "$t/bin/gh" "$t/bin/codex"

run() {
  : > "$t/log"; rm -f "$t/posted" "$t/prompt" "$t/ctx"
  PATH="$t/bin:$PATH" FAKE_LOG="$t/log" FAKE_HEAD="$head_sha" FAKE_REMOTE="$t/remote.git" \
    FAKE_POSTED="$t/posted" FAKE_PROMPT="$t/prompt" FAKE_CTX="$t/ctx" FAKE_SEEN_HEAD="$t/seen" \
    XDG_CACHE_HOME="$t/cache" "$@" </dev/null > "$t/out" 2> "$t/err"
}

# 1. Brief from the newest /codex-brief comment; named issues fetched; posted.
if FAKE_BRIEF_IDS="101 102" run bash "$script" o/r 7 high; then ok "run succeeds"; else bad "run succeeds ($(cat "$t/err"))"; fi
grep -q "api repos/o/r/issues/comments/102" "$t/log" && ok "uses newest brief comment" || bad "uses newest brief comment"
grep -q "Check #12" "$t/prompt" && ! grep -q "^/codex-brief" "$t/prompt" && ok "brief in prompt, marker dropped" || bad "brief in prompt"
grep -q "issue-12.md" "$t/ctx" && grep -q "issue-13.md" "$t/ctx" && ! grep -q "issue-7.md" "$t/ctx" && ok "named issues fetched, PR itself skipped" || bad "named issues"
[ "$(cat "$t/seen")" = "$head_sha" ] && ok "Codex sees the PR head" || bad "Codex sees the PR head"
grep -q -- "--sandbox workspace-write" "$t/log" && grep -q -- "--ignore-user-config" "$t/log" && grep -q -- "--ephemeral" "$t/log" && ok "sandboxed, no user config, ephemeral" || bad "codex flags"
grep -q 'model_reasoning_effort="high"' "$t/log" && ok "effort passed" || bad "effort passed"
grep -q "Independent Codex review" "$t/posted" && grep -q "Verdict: merge." "$t/posted" && grep -q "$head_sha" "$t/posted" && ok "report posted with commit" || bad "report posted"

# 2. --no-post prints and never comments; no brief means a general review.
run bash "$script" o/r 7 --no-post || true
! grep -q "pr comment" "$t/log" && grep -q "Verdict: merge." "$t/out" && ok "--no-post prints only" || bad "--no-post"
grep -q "No brief was given" "$t/prompt" && grep -q 'model_reasoning_effort="low"' "$t/log" && ok "no brief: general review at low effort" || bad "no brief default"

# 3. --brief FILE wins over comments.
printf 'Look at #5\n' > "$t/brief.md"
FAKE_BRIEF_IDS="101" run bash "$script" o/r 7 --brief "$t/brief.md" --no-post || true
grep -q "Look at #5" "$t/prompt" && ! grep -q "comments/101" "$t/log" && ok "--brief file used" || bad "--brief file"

# 4. A Codex failure is reported, not posted as a clean review, and exits non-zero.
if FAKE_CODEX_FAIL=1 run bash "$script" o/r 7; then bad "codex failure exits non-zero"; else ok "codex failure exits non-zero"; fi
grep -q "did not finish" "$t/posted" && ok "failure comment says so" || bad "failure comment"

# 5. Bad input is refused before anything runs.
run bash "$script" 'o/r;x' 7 || true
grep -q "OWNER/REPO" "$t/err" && [ ! -s "$t/log" ] && ok "bad repository refused" || bad "bad repository"
run bash "$script" o/r 7 --wp "6.4 latest" || true
grep -q "bad WordPress version" "$t/err" && [ ! -s "$t/log" ] && ok "bad WordPress version refused" || bad "bad WP version"

# 6. A head that moved between pr view and fetch is refused.
FAKE_BRIEF_IDS="" run bash -c 'FAKE_HEAD=0000000000000000000000000000000000000000 bash "$0" o/r 7 --no-post' "$script" || true
grep -q "moved while fetching" "$t/err" && ! grep -q "^codex " "$t/log" && ok "moved head refused before Codex runs" || bad "moved head ($(cat "$t/err"))"

[ "$fails" = 0 ] && echo "all passed" || { echo "$fails failed"; exit 1; }
