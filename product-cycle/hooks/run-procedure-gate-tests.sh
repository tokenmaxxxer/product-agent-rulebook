#!/usr/bin/env bash
# Tests for the procedure-enforcing gates added by
# docs/proposals/2026-07-26-implement-procedure-hooks-all-rulebooks.md.
# Each gate gets a REFUSE case (crafted violation) and a PASS case (compliant).
set -uo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)"
repo_root="$(cd "$hook_dir/../.." >/dev/null 2>&1 && pwd -P)"
contract_src="$repo_root/docs/specs/role-handoff-contract.md"

pass_count=0; fail_count=0
pass() { echo "PASS: $1"; pass_count=$((pass_count+1)); }
fail() { echo "FAIL: $1"; fail_count=$((fail_count+1)); }

# make a scratch project root that looks like a real repo
new_root() {
  local d; d="$(mktemp -d)"
  ( cd "$d" && git init -q )
  mkdir -p "$d/docs/specs"
  cp "$contract_src" "$d/docs/specs/role-handoff-contract.md"
  echo "$d"
}

run() { # run <gate> <root> <json>  -> exit code in $?, output in OUT
  OUT="$(printf '%s' "$3" | CLAUDE_PROJECT_DIR="$2" "$hook_dir/$1" 2>&1)"; return $?
}

json_write() { # <abs_or_rel_path> <content>
  python3 -c 'import json,sys;print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$1" "$2"
}
json_bash() { python3 -c 'import json,sys;print(json.dumps({"tool_name":"Bash","tool_input":{"command":sys.argv[1]}}))' "$1"; }

echo "== record-fields-gate =="
R="$(new_root)"; mkdir -p "$R/docs/reports/records/subj-a"
bad='---
kind: product-record
subject: subj-a
loop_state: measuring
---
just a note, no required sections'
run record-fields-gate.sh "$R" "$(json_write "$R/docs/reports/records/subj-a/product.md" "$bad")"
[ $? -ne 0 ] && pass "record-fields refuses a product-record missing §20 sections" || fail "record-fields ALLOWED a bare record: $OUT"
good='---
kind: product-record
subject: subj-a
upstream: docs/proposals/2026-07-26-idea.md
loop_state: measuring
hypothesis: docs/proposals/2026-07-26-idea.md
---
## What was done
Registered the activation hypothesis and started measuring.
## Why
Chose 7-day activation over signups; signups over-counts drive-by traffic.
## Next steps
Collect two more weeks of data, then apply the decision rule.
## Open finding resolution path
No open findings; if the guardrail trips, owner is product to re-scope.'
run record-fields-gate.sh "$R" "$(json_write "$R/docs/reports/records/subj-a/product.md" "$good")"
[ $? -eq 0 ] && pass "record-fields allows a compliant §20 record" || fail "record-fields DENIED a compliant record: $OUT"
rm -rf "$R"

echo "== path-ownership-gate =="
R="$(new_root)"; mkdir -p "$R/docs/reports/records/subj-b"
run path-ownership-gate.sh "$R" "$(json_write "$R/docs/reports/records/subj-b/coding.md" "x")"
[ $? -ne 0 ] && pass "path-ownership refuses a write to coding's record (foreign §11)" || fail "path-ownership ALLOWED a foreign record write: $OUT"
run path-ownership-gate.sh "$R" "$(json_write "$R/docs/reports/records/subj-b/product.md" "x")"
[ $? -eq 0 ] && pass "path-ownership allows product's own record write" || fail "path-ownership DENIED product's own record: $OUT"
rm -rf "$R"

echo "== doc-bucket-gate =="
R="$(new_root)"
run doc-bucket-gate.sh "$R" "$(json_write "$R/docs/random/note.md" "x")"
[ $? -ne 0 ] && pass "doc-bucket refuses a doc outside the six buckets" || fail "doc-bucket ALLOWED docs/random/: $OUT"
run doc-bucket-gate.sh "$R" "$(json_write "$R/docs/reports/2026-07-26-obs.md" "x")"
[ $? -eq 0 ] && pass "doc-bucket allows a doc inside reports/ bucket" || fail "doc-bucket DENIED docs/reports/: $OUT"
rm -rf "$R"

echo "== scope-record-gate (+ token minting) =="
R="$(new_root)"; mkdir -p "$R/docs/reports/records/subj-c"
printf -- '---\nkind: product-record\nsubject: subj-c\nloop_state: scope-proposed\n---\n' > "$R/docs/reports/records/subj-c/product.md"
approve='---
kind: product-record
subject: subj-c
loop_state: scope-approved
---
scope approved'
# REFUSE: no human token yet
run scope-record-gate.sh "$R" "$(json_write "$R/docs/reports/records/subj-c/product.md" "$approve")"
[ $? -ne 0 ] && pass "scope-record refuses scope-approved with no human token" || fail "scope-record ALLOWED scope-approved w/o token: $OUT"
# mint a token from a human turn via the UserPromptSubmit hook
mintjson="$(python3 -c 'import json;print(json.dumps({"prompt":"I approve the scope for subject subj-c; scope looks good."}))')"
printf '%s' "$mintjson" | CLAUDE_PROJECT_DIR="$R" "$hook_dir/scope-approval-token.sh" >/dev/null 2>&1
if [ -f "$R/docs/reports/records/subj-c/tokens/subj-c.scope-approved.token" ]; then
  pass "scope-approval-token minted a token from the human's approval turn"
else
  fail "scope-approval-token did NOT mint a token"
fi
# PASS: now token exists
run scope-record-gate.sh "$R" "$(json_write "$R/docs/reports/records/subj-c/product.md" "$approve")"
[ $? -eq 0 ] && pass "scope-record allows scope-approved once a human token is present" || fail "scope-record DENIED with token present: $OUT"
# token consumed
[ ! -f "$R/docs/reports/records/subj-c/tokens/subj-c.scope-approved.token" ] && pass "scope-record consumed the single-use token" || fail "token was not consumed"
rm -rf "$R"

echo "== handbook-trigger-gate =="
R="$(new_root)"
( cd "$R" && git config user.email t@t && git config user.name t
  echo '{"name":"x"}' > package.json && git add package.json )
run handbook-trigger-gate.sh "$R" "$(json_bash 'git commit -m "add dep"')"
[ $? -ne 0 ] && pass "handbook-trigger refuses op-surface commit with no handbook" || fail "handbook-trigger ALLOWED op-surface w/o handbook: $OUT"
( cd "$R" && mkdir -p docs/handbooks && echo 'x' > docs/handbooks/x.md && git add docs/handbooks/x.md )
run handbook-trigger-gate.sh "$R" "$(json_bash 'git commit -m "add dep + handbook"')"
[ $? -eq 0 ] && pass "handbook-trigger allows op-surface commit that also updates a handbook" || fail "handbook-trigger DENIED with handbook present: $OUT"
rm -rf "$R"

echo "== trailer-gate =="
R="$(new_root)"
( cd "$R" && git config user.email t@t && git config user.name t
  mkdir -p docs/reports/records/subj-d && echo 'x' > docs/reports/records/subj-d/product.md
  git add docs/reports/records/subj-d/product.md )
run trailer-gate.sh "$R" "$(json_bash 'git commit -m "land product record"')"
[ $? -ne 0 ] && pass "trailer-gate refuses a product-unit commit lacking Subject:/Kind: trailer" || fail "trailer-gate ALLOWED untrailed product-unit commit: $OUT"
run trailer-gate.sh "$R" "$(json_bash 'git commit -m "land product record

Subject: subj-d
Kind: product-record"')"
[ $? -eq 0 ] && pass "trailer-gate allows a product-unit commit with the trailer" || fail "trailer-gate DENIED a trailered commit: $OUT"
rm -rf "$R"
# non-product commit is unaffected (fresh repo: only a source file staged)
R="$(new_root)"
( cd "$R" && git config user.email t@t && git config user.name t
  echo y > src.txt && git add src.txt )
run trailer-gate.sh "$R" "$(json_bash 'git commit -m "unrelated"')"
[ $? -eq 0 ] && pass "trailer-gate allows a commit that stages no product unit" || fail "trailer-gate DENIED a non-product commit: $OUT"
rm -rf "$R"

echo
echo "== $pass_count passed, $fail_count failed =="
[ "$fail_count" -eq 0 ]
