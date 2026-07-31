#!/usr/bin/env bash
# Gate tests for product-guardrail-metrics: guardrail non-emptiness at
# registration (proposal path) and guardrail status tracking at measurement
# time (record path). Same harness shape as tests/run-gate-tests.sh.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../product-guardrail-metrics/hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

PROPOSAL=docs/issue-7/proposals/2026-07-28-product-discovery.md
RECORD=docs/issue-7/reports/product-discovery.md

run() { # want name gate file content [with_current_state]
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/$(dirname "$4")"
  if [ "${6:-1}" = "1" ]; then
    mkdir -p "$td/docs/issue-7/reports/product-discovery"
    echo "current state" > "$td/docs/issue-7/reports/product-discovery/current-state.md"
  fi
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$4" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$5")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/$3" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

# --- proposal path -----------------------------------------------------
run deny order-constraint-missing methodology-gate.sh "$PROPOSAL" 'Guardrail: signup-error-rate must stay under 2%.' 0
run allow order-constraint-present methodology-gate.sh "$PROPOSAL" 'Guardrail: signup-error-rate must stay under 2%.' 1
run allow guardrail-present methodology-gate.sh "$PROPOSAL" 'Guardrail metric: p95 latency must stay under 200ms.' 1
run deny  guardrail-absent methodology-gate.sh "$PROPOSAL" 'We believe X; we will know when conversion crosses 5%.' 1
run deny  guardrail-none-suffixed methodology-gate.sh "$PROPOSAL" 'Guardrail metrics: none.' 1
run deny  guardrail-tbd-suffixed methodology-gate.sh "$PROPOSAL" 'Guardrail: TBD' 1

# --- record path ---------------------------------------------------------
run allow status-word-present methodology-gate.sh "$RECORD" 'Measured value 6% vs threshold 5%.

Guardrail: signup-error-rate held at 1.2%, not breached.' 1
run deny  status-missing methodology-gate.sh "$RECORD" 'Measured value 6% vs threshold 5%.

Guardrail: signup-error-rate.' 1
run deny  status-guardrail-absent methodology-gate.sh "$RECORD" 'Measured value 6% vs threshold 5%. Kill per rule.' 1

# --- shared mechanics ------------------------------------------------------
malformed() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  printf 'not json' | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" malformed-stdin
}
malformed

run allow unrelated-path methodology-gate.sh "docs/issue-7/reports/verify.md" "x" 1

killswitch() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/docs/issue-7/proposals"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"no guardrail here"},"cwd":"%s"}' \
    "$PROPOSAL" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" PRODUCT_GUARDRAIL_METRICS_GATE_OFF=1 /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" kill-switch
}
killswitch

editfail() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/docs/issue-7/proposals" "$td/docs/issue-7/reports/product-discovery"
  echo "current state" > "$td/docs/issue-7/reports/product-discovery/current-state.md"
  echo "existing content" > "$td/$PROPOSAL"
  printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"nonexistent-text","new_string":"Guardrail: x"},"cwd":"%s"}' \
    "$PROPOSAL" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" edit-reconstruction-fail
}
editfail

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
