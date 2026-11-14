#!/usr/bin/env bash
# Tests for shared/scripts/qa-bootstrap.sh against a fake gh.
#
# The fake behaves like the real gh on an error: it writes the error's JSON
# body to stdout, "gh: <message> (HTTP <code>)" to stderr, and exits 1. That
# stdout body is what once became three required check names on Keel.
#
# Run: bash shared/scripts/tests/qa-bootstrap.test.sh

set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
script="$here/../qa-bootstrap.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail=0
cases=0

mkdir -p "$work/bin"
cat > "$work/bin/gh" <<'FAKE'
#!/usr/bin/env bash
# Scenario knobs: FAKE_PROTECTION (json|404|500), FAKE_RULESETS (json|500),
# FAKE_RULESET (json for GET rulesets/<id>), FAKE_PROBES (200|404).
log="$FAKE_DIR/calls.log"
method=GET; prev=""; jqexpr=""; input=""
for a in "$@"; do
	case "$prev" in -X) method=$a ;; --jq) jqexpr=$a ;; --input) input=$a ;; esac
	prev=$a
done
path=""
for a in "$@"; do case "$a" in repos/*|user|users/*) path=$a; break ;; esac; done
if [ "$method" != GET ]; then
	body=""
	[ "$input" = "-" ] && body="$(jq -c . 2>/dev/null)"
	printf '%s %s %s\n' "$method" "$path" "$body" >> "$log"
	echo '{}'
	exit 0
fi
echo "GET $path" >> "$log"
err() { printf '{"message":"%s","documentation_url":"https://docs.github.com/rest","status":"%s"}\n' "$2" "$1"; echo "gh: $2 (HTTP $1)" >&2; exit 1; }
ok() { if [ -n "$jqexpr" ]; then jq -r "$jqexpr" <<<"$1"; else echo "$1"; fi; }
case "$path" in
	user) ok '{"login":"owner","id":1}' ;;
	repos/o/r) ok '{"permissions":{"admin":true},"private":false,"owner":{"type":"User"},"default_branch":"main","fork":false,"delete_branch_on_merge":true}' ;;
	repos/o/r/branches/main/protection)
		case "$FAKE_PROTECTION" in 404) err 404 "Branch not protected" ;; 500) err 500 "Server Error" ;; *) ok "$FAKE_PROTECTION" ;; esac ;;
	repos/o/r/rulesets)
		case "$FAKE_RULESETS" in 500) err 500 "Server Error" ;; *) ok "$FAKE_RULESETS" ;; esac ;;
	repos/o/r/rulesets/*) ok "$FAKE_RULESET" ;;
	repos/o/r/contents/.github/workflows/lab-probes.yml*)
		case "$FAKE_PROBES" in 404) err 404 "Not Found" ;; *) ok '{}' ;; esac ;;
	repos/o/r/contents/.github/workflows*) ok '[]' ;;
	*) err 404 "Not Found" ;;
esac
FAKE
chmod +x "$work/bin/gh"

# run NAME EXPECT_EXIT(0|nonzero) [script args...]
run() {
	local name="$1" expect="$2"; shift 2
	cases=$((cases + 1))
	: > "$work/calls.log"
	out="$(PATH="$work/bin:$PATH" FAKE_DIR="$work" bash "$script" o/r "$@" 2>&1 </dev/null)"
	code=$?
	if { [ "$expect" = 0 ] && [ "$code" -ne 0 ]; } || { [ "$expect" != 0 ] && [ "$code" -eq 0 ]; }; then
		echo "FAIL $name: exit $code, expected $expect"; echo "$out" | sed 's/^/    /'; fail=$((fail + 1))
	fi
}
expect_out() { if ! grep -qF -- "$2" <<<"$out"; then echo "FAIL $1: output lacks: $2"; echo "$out" | sed 's/^/    /'; fail=$((fail + 1)); fi; }
expect_no_write() { if grep -qE '^(PUT|POST|PATCH|DELETE) ' "$work/calls.log"; then echo "FAIL $1: wrote to GitHub:"; sed 's/^/    /' "$work/calls.log"; fail=$((fail + 1)); fi; }
put_checks() { grep '^PUT repos/o/r/rulesets/11 ' "$work/calls.log" | sed 's/^PUT [^ ]* //' | jq -c '[.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context]'; }
put_apps() { grep '^PUT repos/o/r/rulesets/11 ' "$work/calls.log" | sed 's/^PUT [^ ]* //' | jq -c '[.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].integration_id] | unique'; }

four='["Lint and unit tests","Counterpart recorded","Tester probes came first","Guardrail changes reviewed"]'
existing='[{"id":11,"name":"QA process: protect default branch"},{"id":12,"name":"QA process: release tags"}]'
existing_full='{"id":11,"rules":[{"type":"deletion"},{"type":"required_status_checks","parameters":{"required_status_checks":[{"context":"Lint and unit tests"},{"context":"Counterpart recorded"},{"context":"Tester probes came first"},{"context":"Guardrail changes reviewed"}]}}]}'
export FAKE_PROBES=200 FAKE_RULESET="$existing_full"

# 1. The Keel incident: re-run after classic protection was removed.
FAKE_PROTECTION=404 FAKE_RULESETS="$existing" run "re-run with protection 404" 0 --apply
got="$(put_checks)"
[ "$got" = "$four" ] || { echo "FAIL re-run with protection 404: PUT checks $got, expected $four"; fail=$((fail + 1)); }
# Every required check is pinned to GitHub Actions, so a commit status posted
# with a repo-scoped token can't stand in for one.
got="$(put_apps)"
[ "$got" = "[15368]" ] || { echo "FAIL checks pinned to GitHub Actions: integration_id $got, expected [15368]"; fail=$((fail + 1)); }

# 2. First run: classic protection supplies two checks, lab-probes adds two.
FAKE_PROTECTION='{"required_status_checks":{"checks":[{"context":"Lint and unit tests"},{"context":"Counterpart recorded"}]}}' FAKE_RULESETS='[]' run "first run" 0
expect_out "first run" "Required checks: Lint and unit tests, Counterpart recorded, Tester probes came first, Guardrail changes reviewed"
expect_no_write "first run (dry run)"

# 3. Any other error reading protection aborts before writing anything.
FAKE_PROTECTION=500 FAKE_RULESETS="$existing" run "protection 500 aborts" nonzero --apply
expect_out "protection 500 aborts" "nothing was changed"
expect_no_write "protection 500 aborts"

# 4. Can't list rulesets on a public repo: abort.
FAKE_PROTECTION=404 FAKE_RULESETS=500 run "rulesets 500 aborts" nonzero --apply
expect_no_write "rulesets 500 aborts"

# 5. A check name that is really an error body is refused.
FAKE_PROTECTION=404 FAKE_RULESETS='[]' run "error text as --checks refused" nonzero --apply --checks '{"message":"Branch not protected",Lint'
expect_out "error text as --checks refused" "refusing these required check names"
expect_no_write "error text as --checks refused"

# 6. No lab-probes workflow (404) is fine: no guard checks added.
FAKE_PROTECTION='{"required_status_checks":{"checks":[{"context":"lint"}]}}' FAKE_RULESETS='[]' FAKE_PROBES=404 run "no lab-probes" 0
expect_out "no lab-probes" "Required checks: lint"

# 7. --check-app any leaves the source open, and says so.
FAKE_PROTECTION=404 FAKE_RULESETS="$existing" run "--check-app any" 0 --apply --check-app any
got="$(put_apps)"
[ "$got" = "[null]" ] || { echo "FAIL --check-app any: integration_id $got, expected [null]"; fail=$((fail + 1)); }
expect_out "--check-app any" "a token with repo scope could fake one"

# 8. A bad --check-app is refused before anything is written.
FAKE_PROTECTION=404 FAKE_RULESETS="$existing" run "bad --check-app refused" nonzero --apply --check-app actions
expect_no_write "bad --check-app refused"

if [ "$fail" -gt 0 ]; then
	echo "$fail qa-bootstrap assertion(s) failed."
	exit 1
fi
echo "qa-bootstrap: $cases cases passed."
