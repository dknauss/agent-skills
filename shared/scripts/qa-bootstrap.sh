#!/usr/bin/env bash
# qa-bootstrap.sh: set up a repository for the QA and AI-testing process.
#
# Does the parts an agent can't (and shouldn't be able to) do for itself:
#   1. A ruleset on the default branch with an EMPTY bypass list: pull request
#      required, required status checks, no force pushes, no deletion.
#   2. The agent machine account as a Write collaborator (never Admin).
#   3. A tag ruleset on v* that only admins can bypass, so an agent with Write
#      can't push a release tag. If a workflow deploys through a GitHub
#      Environment (e.g. wordpress-org), checks that it has a required reviewer.
#   4. Head-branch auto-delete on merge.
#   5. Optionally, copies the lab-probes guard (workflow, checker, its test and
#      the probes README) from Keel into a local clone, for a pull request.
#
# See docs/qa-process.md. Run it from YOUR OWN login (gh signed in as the
# repository owner or an org admin), never from an agent session: the point is
# that agents don't hold the keys this needs.
#
# Dry run by default: it reads the repository and prints what it would change.
# Pass --apply to make the changes. Safe to re-run: an existing ruleset with the
# same name is updated, an existing collaborator is left alone, and files that
# already exist in the clone are never overwritten.
#
# Forks (e.g. a wordpress-develop fork) get a lighter branch ruleset: only no
# deletion and no force push on the default branch, so "Sync fork" keeps working,
# no pull-request or check requirement, and no guard files.
#
# Usage:
#   qa-bootstrap.sh OWNER/REPO [--bot LOGIN] [--checks "Check A,Check B"]
#                   [--files /path/to/local/clone] [--apply]
#
#   --bot     machine account to add as a Write collaborator
#   --checks  required status check names; default: the checks the current
#             branch protection requires, plus "Tester probes came first" and
#             "Guardrail changes reviewed" when the repo has
#             .github/workflows/lab-probes.yml
#   --files   local clone to copy the lab-probes guard into (then open a PR)
#   --apply   make the changes (default is a dry run)
#
# Needs: gh (signed in), jq.

set -euo pipefail

RULESET_NAME="QA process: protect default branch"
TAG_RULESET_NAME="QA process: release tags"
GUARD_SOURCE="dknauss/Keel"
GUARD_FILES=(
	".github/workflows/lab-probes.yml"
	"bin/check-lab-probes"
	"tests/lab-probes-check.php"
	"docs/review/probes/README.md"
)

repo=""
bot=""
checks=""
files_dir=""
apply=0

die() { echo "qa-bootstrap: $*" >&2; exit 1; }
say() { echo "$*"; }
plan() { if [ "$apply" -eq 1 ]; then echo "APPLY: $*"; else echo "WOULD: $*"; fi; }

while [ $# -gt 0 ]; do
	case "$1" in
		--bot) bot="${2:?--bot needs a login}"; shift 2 ;;
		--checks) checks="${2:?--checks needs a comma-separated list}"; shift 2 ;;
		--files) files_dir="${2:?--files needs a directory}"; shift 2 ;;
		--apply) apply=1; shift ;;
		-h|--help) sed -n '2,35p' "$0"; exit 0 ;;
		-*) die "unknown option $1" ;;
		*) [ -z "$repo" ] || die "one repository at a time"; repo="$1"; shift ;;
	esac
done

[ -n "$repo" ] || die "usage: qa-bootstrap.sh OWNER/REPO [--bot LOGIN] [--checks ...] [--files DIR] [--apply]"
[[ "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die "expected OWNER/REPO, got $repo"
command -v gh >/dev/null || die "gh is not installed"
command -v jq >/dev/null || die "jq is not installed"

me="$(gh api user --jq .login)" || die "gh is not signed in"
info="$(gh api "repos/$repo")" || die "can't read $repo as $me"
is_admin="$(jq -r '.permissions.admin // false' <<<"$info")"
private="$(jq -r '.private' <<<"$info")"
owner_type="$(jq -r '.owner.type' <<<"$info")"
default_branch="$(jq -r '.default_branch' <<<"$info")"
is_fork="$(jq -r '.fork' <<<"$info")"

say "Repository: $repo (default branch $default_branch, private=$private, fork=$is_fork, owner is a $owner_type)"
say "Signed in as: $me"
[ "$apply" -eq 1 ] || say "Dry run. Nothing will change; pass --apply to make these changes."
[ "$is_admin" = "true" ] || die "$me is not an admin of $repo. Run this from the owner's login."
if [ -n "$bot" ] && [ "$me" = "$bot" ]; then
	die "you are signed in as the agent account. Run this from your own login."
fi
say

# --- 1. Ruleset ------------------------------------------------------------
if [ -z "$checks" ]; then
	checks="$(gh api "repos/$repo/branches/$default_branch/protection" \
		--jq '[.required_status_checks.checks[]?.context] | join(",")' 2>/dev/null || true)"
	if gh api "repos/$repo/contents/.github/workflows/lab-probes.yml?ref=$default_branch" >/dev/null 2>&1; then
		for c in "Tester probes came first" "Guardrail changes reviewed"; do
			case ",$checks," in *",$c,"*) ;; *) checks="${checks:+$checks,}$c" ;; esac
		done
	fi
fi

if [ "$is_fork" = "true" ]; then
	checks=""
fi
checks_json="$(jq -cn --arg c "$checks" '$c | split(",") | map(gsub("^\\s+|\\s+$"; "")) | map(select(length > 0)) | map({context: .})')"

ruleset="$(jq -n --arg name "$RULESET_NAME" --argjson checks "$checks_json" --argjson fork "$is_fork" '{
	name: $name,
	target: "branch",
	enforcement: "active",
	bypass_actors: [],
	conditions: { ref_name: { include: ["~DEFAULT_BRANCH"], exclude: [] } },
	rules: ([
		{ type: "deletion" },
		{ type: "non_fast_forward" }
	] + (if $fork then [] else [{ type: "pull_request", parameters: {
			required_approving_review_count: 0,
			dismiss_stale_reviews_on_push: false,
			require_code_owner_review: false,
			require_last_push_approval: false,
			required_review_thread_resolution: false
		} }] end) + (if ($checks | length) > 0 then [{ type: "required_status_checks", parameters: {
			strict_required_status_checks_policy: false,
			required_status_checks: $checks
		} }] else [] end))
}')"

say "1. Ruleset \"$RULESET_NAME\" with an empty bypass list"
if [ "$is_fork" = "true" ]; then
	say "   Fork: only deletion and force pushes are blocked, so Sync fork still works. Work happens"
	say "   on topic branches and goes upstream; upstream CI and review are the checks."
fi
if [ "$checks_json" = "[]" ] && [ "$is_fork" != "true" ]; then
	say "   No required checks found. Pass --checks to require some; until then the ruleset only"
	say "   requires a pull request and blocks force pushes and deletion."
elif [ "$checks_json" != "[]" ]; then
	say "   Required checks: $(jq -r 'map(.context) | join(", ")' <<<"$checks_json")"
fi
if [ "$private" = "true" ] && [ "$owner_type" = "User" ]; then
	say "   Note: rulesets on a private repository owned by a personal account need GitHub Pro."
	say "   Without it GitHub refuses or doesn't enforce them; steps 2 to 4 still help."
fi

existing_id="$(gh api "repos/$repo/rulesets" --jq ".[] | select(.name == \"$RULESET_NAME\") | .id" 2>/dev/null | head -n1 || true)"
if [ -n "$existing_id" ]; then
	plan "update ruleset $existing_id"
	if [ "$apply" -eq 1 ]; then
		gh api -X PUT "repos/$repo/rulesets/$existing_id" --input - <<<"$ruleset" >/dev/null && say "   Updated."
	fi
else
	plan "create the ruleset"
	if [ "$apply" -eq 1 ]; then
		if gh api -X POST "repos/$repo/rulesets" --input - <<<"$ruleset" >/dev/null; then
			say "   Created."
		else
			say "   GitHub refused the ruleset (see the error above). On a private personal repo this means GitHub Pro is needed."
		fi
	fi
fi
if gh api "repos/$repo/branches/$default_branch/protection" >/dev/null 2>&1; then
	say "   Classic branch protection is also on. Once the ruleset shows Active, remove it by hand at"
	say "   https://github.com/$repo/settings/branches so there is one source of truth."
fi
say

# --- 2. Release tags and deploy approval ---------------------------------
say "2. Release tags and deploy approval"
tag_ruleset="$(jq -n --arg name "$TAG_RULESET_NAME" '{
	name: $name,
	target: "tag",
	enforcement: "active",
	bypass_actors: [ { actor_id: 5, actor_type: "RepositoryRole", bypass_mode: "always" } ],
	conditions: { ref_name: { include: ["refs/tags/v*"], exclude: [] } },
	rules: [ { type: "creation" }, { type: "update" }, { type: "deletion" } ]
}')"
if [ "$is_fork" = "true" ]; then
	say "   Fork: skipped (no releases are cut here)."
else
	say "   Tag ruleset \"$TAG_RULESET_NAME\": only repository admins can create, move or delete v* tags."
	tag_id="$(gh api "repos/$repo/rulesets" --jq ".[] | select(.name == \"$TAG_RULESET_NAME\") | .id" 2>/dev/null | head -n1 || true)"
	if [ -n "$tag_id" ]; then
		plan "update tag ruleset $tag_id"
		[ "$apply" -eq 1 ] && gh api -X PUT "repos/$repo/rulesets/$tag_id" --input - <<<"$tag_ruleset" >/dev/null && say "   Updated."
	else
		plan "create the tag ruleset"
		if [ "$apply" -eq 1 ]; then
			gh api -X POST "repos/$repo/rulesets" --input - <<<"$tag_ruleset" >/dev/null && say "   Created." \
				|| say "   GitHub refused the tag ruleset (see above)."
		fi
	fi
	envs="$(gh api "repos/$repo/contents/.github/workflows?ref=$default_branch" --jq '.[].path' 2>/dev/null \
		| while read -r wf; do gh api -H "Accept: application/vnd.github.raw" "repos/$repo/contents/$wf?ref=$default_branch" 2>/dev/null; done \
		| sed -n 's/^[[:space:]]*environment:[[:space:]]*\([A-Za-z0-9_.-]*\)[[:space:]]*$/\1/p' | sort -u || true)"
	if [ -z "$envs" ]; then
		say "   No workflow deploys through an environment."
	fi
	for env in $envs; do
		reviewers="$(gh api "repos/$repo/environments/$env" --jq '[.protection_rules[]? | select(.type == "required_reviewers") | .reviewers[]?.reviewer.login] | join(",")' 2>/dev/null || true)"
		if [ -n "$reviewers" ]; then
			say "   Environment $env requires approval from: $reviewers"
		else
			me_id="$(gh api user --jq .id)"
			plan "make $me approve every deploy through environment $env"
			if [ "$apply" -eq 1 ]; then
				jq -n --argjson id "$me_id" '{reviewers: [{type: "User", id: $id}], prevent_self_review: false}' \
					| gh api -X PUT "repos/$repo/environments/$env" --input - >/dev/null && say "   Done."
			fi
		fi
	done
fi
say

# --- 3. Agent account ------------------------------------------------------
say "3. Agent machine account"
if [ -z "$bot" ]; then
	say "   Skipped (no --bot)."
else
	perm="$(gh api "repos/$repo/collaborators/$bot/permission" --jq .permission 2>/dev/null || echo none)"
	case "$perm" in
		admin|maintain)
			say "   $bot has $perm. That's more than an agent should hold: lower it to Write at"
			say "   https://github.com/$repo/settings/access" ;;
		write)
			say "   $bot already has Write. Nothing to do." ;;
		*)
			plan "invite $bot with Write (it must accept the invite while signed in as $bot)"
			if [ "$apply" -eq 1 ]; then
				gh api -X PUT "repos/$repo/collaborators/$bot" -f permission=push >/dev/null && say "   Invited."
			fi ;;
	esac
fi
say

# --- 4. Auto-delete merged branches ---------------------------------------
say "4. Delete head branches on merge"
if [ "$(jq -r '.delete_branch_on_merge' <<<"$info")" = "true" ]; then
	say "   Already on."
else
	plan "turn on automatic head-branch deletion"
	if [ "$apply" -eq 1 ]; then
		gh api -X PATCH "repos/$repo" -F delete_branch_on_merge=true >/dev/null && say "   On."
	fi
fi
say

# --- 5. Lab-probes guard files --------------------------------------------
say "5. Lab-probes guard files"
if [ "$is_fork" = "true" ]; then
	say "   Fork: skipped. Its files belong to upstream."
elif [ -z "$files_dir" ]; then
	say "   Skipped (no --files). An agent can add them in a pull request instead."
else
	[ -d "$files_dir/.git" ] || die "$files_dir is not a git clone"
	for f in "${GUARD_FILES[@]}"; do
		if [ -e "$files_dir/$f" ]; then
			say "   $f exists; left alone."
			continue
		fi
		plan "copy $f from $GUARD_SOURCE"
		if [ "$apply" -eq 1 ]; then
			mkdir -p "$files_dir/$(dirname "$f")"
			gh api -H "Accept: application/vnd.github.raw" "repos/$GUARD_SOURCE/contents/$f" >"$files_dir/$f"
			[ "$f" = "bin/check-lab-probes" ] && chmod +x "$files_dir/$f"
		fi
	done
	say "   Then commit them on a branch, adjust any Keel-specific wording, and open a pull request."
fi
if [ "$is_fork" != "true" ]; then
	for label in guardrail-reviewed tier-3; do
		if gh api "repos/$repo/labels/$label" >/dev/null 2>&1; then
			say "   Label $label exists."
		else
			plan "create label $label"
			[ "$apply" -eq 1 ] && gh api -X POST "repos/$repo/labels" -f name="$label" -f color=5319e7 >/dev/null && say "   Created."
		fi
	done
fi
say

say "Not done by this script (see docs/qa-process.md):"
say " - Create the machine account and its classic token with the repo scope only (never workflow)."
say " - Run local agents with only that token: see 'Isolating local agents' in docs/qa-process.md."
say " - Add a 'Testing process' pointer to the repo's CONTRIBUTING or README."
