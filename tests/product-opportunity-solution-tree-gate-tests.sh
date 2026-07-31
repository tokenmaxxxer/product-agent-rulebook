#!/usr/bin/env bash
# Gate tests for product-opportunity-solution-tree/hooks/methodology-gate.sh
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../product-opportunity-solution-tree/hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

SURVEY=docs/issue-7/reports/product-discovery/current-state.md
PROPOSAL=docs/issue-7/proposals/2026-07-31-product-discovery.md
RECORD=docs/issue-7/reports/product-discovery.md

run() { # want name file content [precreate-current-state:0/1]
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/docs/issue-7/reports/product-discovery" "$td/docs/issue-7/proposals"
  if [ "${5:-0}" = "1" ]; then
    printf 'placeholder current-state\n' > "$td/$SURVEY"
  fi
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$3" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$4")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

SURVEY_OK='Background/context.
JTBD: performer=PM, job=..., circumstance=..., desired outcome=...
Where this sits in the opportunity-solution tree: Opportunity: reduce churn.
Candidate hypotheses ...'
run allow survey-ost-vocab-pass "$SURVEY" "$SURVEY_OK"

SURVEY_BAD='Background/context.
We think users want a dashboard because it would be nice.'
run deny survey-ost-vocab-missing "$SURVEY" "$SURVEY_BAD"

PROPOSAL_OK='Hypothesis package: named metric X, threshold 10, decision rule go/kill.'
run allow proposal-order-pass "$PROPOSAL" "$PROPOSAL_OK" 1
run deny  proposal-order-deny "$PROPOSAL" "$PROPOSAL_OK" 0

RECORD_OK='Verdict: metric 12 vs threshold 10, go.
OST update: Opportunity branch promoted (go).'
run allow record-disposition-pass "$RECORD" "$RECORD_OK"

RECORD_BAD='Verdict: metric 12 vs threshold 10, go.
No mention of the tree here.'
run deny record-disposition-deny "$RECORD" "$RECORD_BAD"

# malformed stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf 'not json' | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-stdin

# unrelated path pass-through
run allow unrelated-path "docs/issue-7/reports/other.md" "hello"

# kill switch
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/reports/product-discovery"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"nothing"},"cwd":"%s"}' "$SURVEY" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" PRODUCT_OPPORTUNITY_SOLUTION_TREE_GATE_OFF=1 /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" kill-switch

# Edit reconstruction failure (old_string not present in current file)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/docs/issue-7/reports"
printf 'existing content\n' > "$td/$RECORD"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"not present here","new_string":"x"},"cwd":"%s"}' "$RECORD" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" edit-reconstruction-fail

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
