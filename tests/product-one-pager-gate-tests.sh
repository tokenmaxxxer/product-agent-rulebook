#!/usr/bin/env bash
# Gate tests for product-one-pager's methodology-gate.sh.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../product-one-pager/hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

SURVEY=docs/issue-7/reports/product-discovery/current-state.md

run_write() { # want name file content [extra_env]
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$3")"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$3" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$4")" "$td" \
    | env ${5:-} CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

JTBD='## Current state

Job performer: a support agent.
Job: triage incoming tickets quickly.
Circumstance: during peak-hour ticket floods.
Desired outcome: tickets routed to the right owner within a minute.

No solution named yet.'

run_write allow jtbd-tuple-pass "$SURVEY" "$JTBD"

SOLUTION_FIRST='## Current state

Solution: we will build an AI ticket router.

Job performer: a support agent.
Job: triage incoming tickets quickly.
Circumstance: during peak-hour ticket floods.
Desired outcome: tickets routed to the right owner within a minute.'

run_write deny  solution-before-tuple-deny "$SURVEY" "$SOLUTION_FIRST"

run_write deny  missing-tuple-deny "$SURVEY" "We should probably fix onboarding somehow."

# Malformed stdin: not valid JSON at all.
malformed_stdin_test() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$SURVEY")"
  printf 'not json at all' | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" malformed-stdin-deny
}
malformed_stdin_test

run_write allow unrelated-path-pass "docs/issue-7/reports/verify.md" "anything goes here"

# Kill switch: even malformed/deficient content passes when the gate is off.
killswitch_test() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$SURVEY")"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"no tuple here"},"cwd":"%s"}' \
    "$SURVEY" "$td" \
    | env PRODUCT_ONE_PAGER_GATE_OFF=1 CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" kill-switch-pass
}
killswitch_test

# Edit reconstruction failure: old_string not found in the pre-created file.
edit_recon_failure_test() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$SURVEY")"
  printf 'unrelated pre-existing content\n' > "$td/$SURVEY"
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"this text is not in the file","new_string":"replacement"},"cwd":"%s"}' \
    "$SURVEY" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" edit-reconstruction-failure-deny
}
edit_recon_failure_test

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
