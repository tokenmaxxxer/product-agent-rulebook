#!/usr/bin/env bash
# Gate tests for product-hypothesis-testing's methodology-gate.sh.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../product-hypothesis-testing/hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

PROPOSAL=docs/issue-7/proposals/2026-07-28-product-discovery.md
RECORD=docs/issue-7/reports/product-discovery.md
CURRENT_STATE=docs/issue-7/reports/product-discovery/current-state.md

# run want name file content [with_current_state]
run() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/$(dirname "$3")"
  if [ "${5:-yes}" = "yes" ]; then
    mkdir -p "$td/$(dirname "$CURRENT_STATE")"
    printf 'current state survey\n' > "$td/$CURRENT_STATE"
  fi
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$3" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$4")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

FULL='## Hypothesis
We believe onboarding completion improves. Metric: activation rate.
Threshold: crosses 40%. Decision rule: go if it crosses, kill otherwise.
ITWWS: if this works we should roll it out to all cohorts.'

run allow full-package "$PROPOSAL" "$FULL" yes
run deny  no-current-state "$PROPOSAL" "$FULL" no

NO_DIGIT='We believe onboarding improves activation. Decision: go if the metric
crosses the threshold. ITWWS: if this works we should roll it out.'
run deny  no-digit-threshold "$PROPOSAL" "$NO_DIGIT" yes

NO_RULE='Metric: activation rate. Threshold: crosses 40%.
ITWWS: if this works we should roll it out.'
run deny  no-decision-rule "$PROPOSAL" "$NO_RULE" yes

NO_ITWWS='Metric: activation rate. Threshold: crosses 40%.
Decision rule: go if it crosses, kill otherwise.'
run deny  no-itwws "$PROPOSAL" "$NO_ITWWS" yes

ADJ_GOOD='## Verdict
Measured activation rate: 42%. Threshold: 40%. Result: go.
ITWWS: actioned — rolled out to all cohorts.'
run allow verdict-adjacency-pass "$RECORD" "$ADJ_GOOD" yes

ADJ_BAD='## Verdict
We decided to go with the feature based on strong qualitative signal.
No numbers were tracked this cycle.
ITWWS: actioned — rolled out to all cohorts.'
run deny  verdict-adjacency-deny "$RECORD" "$ADJ_BAD" yes

ITWWS_ACTIONED='Measured activation rate: 42%. Threshold: 40%.
ITWWS: actioned — rolled out to all cohorts.'
run allow itwws-actioned "$RECORD" "$ITWWS_ACTIONED" yes

ITWWS_DEFERRED_REASON='Measured activation rate: 42%. Threshold: 40%.
ITWWS: deferred — capacity is tied up on the migration until next quarter.'
run allow itwws-deferred-reason "$RECORD" "$ITWWS_DEFERRED_REASON" yes

ITWWS_DEFERRED_NOREASON='Measured activation rate: 42%. Threshold: 40%.
ITWWS: deferred.'
run deny  itwws-deferred-no-reason "$RECORD" "$ITWWS_DEFERRED_NOREASON" yes

# Malformed stdin.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf 'not json at all' | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-stdin

# Unrelated path passes through.
run allow unrelated-path "docs/issue-7/reports/product.md" "anything" yes

# Kill switch.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$PROPOSAL" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "nothing at all")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" PRODUCT_HYPOTHESIS_TESTING_GATE_OFF=1 /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" kill-switch

# Edit reconstruction failure: old_string not present in (nonexistent) file.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$CURRENT_STATE")"; printf 'x\n' > "$td/$CURRENT_STATE"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"nope","new_string":"x"},"cwd":"%s"}' \
  "$PROPOSAL" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" edit-reconstruction-failure

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
