#!/usr/bin/env bash
# Gate tests for product-hypothesis-testing's methodology-gate.sh.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../product-hypothesis-testing/hooks"

# The gate sources gate-lib.sh via CLAUDE_PLUGIN_ROOT_CORE; resolve it the
# same way the real runtime does, per accessibility-rulebook's precedent.
if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ]; then
  for cand in "$HOME/tokenmaxxxer/tokenmaxxxer-core/core" \
              "$HOME/.claude/plugins/marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core"; do
    if [ -f "$cand/hooks/lib/gate-lib.sh" ]; then export CLAUDE_PLUGIN_ROOT_CORE="$cand"; break; fi
  done
fi
if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ] || [ ! -f "$CLAUDE_PLUGIN_ROOT_CORE/hooks/lib/gate-lib.sh" ]; then
  echo "product-hypothesis-testing-gate-tests: cannot locate core's gate-lib.sh — set CLAUDE_PLUGIN_ROOT_CORE to the installed core plugin root" >&2
  exit 1
fi

pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-38s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-38s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

PROPOSAL=docs/issue-7/proposals/2026-07-28-product-discovery.md
RECORD=docs/issue-7/reports/product-discovery.md
CURRENT_STATE=docs/issue-7/reports/product-discovery/current-state.md

jesc() { python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1"; }

# run want name file content [with_current_state]
run() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/$(dirname "$3")"
  if [ "${5:-yes}" = "yes" ]; then
    mkdir -p "$td/$(dirname "$CURRENT_STATE")"
    printf 'current state survey\n' > "$td/$CURRENT_STATE"
  fi
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$3" "$(jesc "$4")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

# run_raw want name payload_json [env...]
run_raw() {
  local want="$1" name="$2" payload="$3"; shift 3
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/$(dirname "$CURRENT_STATE")"
  printf 'current state survey\n' > "$td/$CURRENT_STATE"
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" "$@" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$want" "$got" "$name"
}

FULL='## Hypothesis
We believe onboarding completion improves. Metric: activation rate.
Threshold: crosses 40%. Decision rule: go if it crosses, kill otherwise.
ITWWS: if this works we should roll it out to all cohorts.'

run allow full-package "$PROPOSAL" "$FULL" yes
run deny  no-current-state "$PROPOSAL" "$FULL" no

NO_DIGIT='We believe onboarding improves activation. Decision rule: go if the metric
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

# Malformed stdin: 3 sub-cases.
run_raw deny malformed-not-json 'not json at all'
run_raw deny malformed-truncated '{"tool_name":"Write","tool_input":{'
run_raw deny malformed-non-object '"just a string"'
run_raw deny malformed-empty ''

# Unrelated path passes through.
run allow unrelated-path "docs/issue-7/reports/product.md" "anything" yes

# Kill switch: on-spelling disables.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$PROPOSAL" "$(jesc "nothing at all")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" PRODUCT_HYPOTHESIS_TESTING_GATE_OFF=1 /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" kill-switch-on

# Kill switch: unrecognized value stays active (must deny incomplete content).
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$CURRENT_STATE")"; printf 'x\n' > "$td/$CURRENT_STATE"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$PROPOSAL" "$(jesc "nothing at all")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" PRODUCT_HYPOTHESIS_TESTING_GATE_OFF=banana /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" kill-switch-unrecognized-stays-active

# Edit reconstruction failure: old_string not present in (nonexistent) file.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$CURRENT_STATE")"; printf 'x\n' > "$td/$CURRENT_STATE"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"nope","new_string":"x"},"cwd":"%s"}' \
  "$PROPOSAL" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" edit-reconstruction-failure

# Edit with replace_all: true against a multiply-occurring old_string.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$CURRENT_STATE")"; printf 'current state survey\n' > "$td/$CURRENT_STATE"
mkdir -p "$td/$(dirname "$PROPOSAL")"
cat > "$td/$PROPOSAL" <<'EOF'
Metric: activation rate. Threshold: crosses 40%.
X X X
ITWWS: if this works we should roll it out.
EOF
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"X","new_string":"Decision rule: go if it crosses, kill otherwise.","replace_all":true},"cwd":"%s"}' \
  "$PROPOSAL" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" edit-replace-all-true

# MultiEdit with mixed replace_all true/false edits in one call.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$CURRENT_STATE")"; printf 'current state survey\n' > "$td/$CURRENT_STATE"
mkdir -p "$td/$(dirname "$PROPOSAL")"
cat > "$td/$PROPOSAL" <<'EOF'
PLACEHOLDER1
Y Y Y
PLACEHOLDER2
EOF
printf '{"tool_name":"MultiEdit","tool_input":{"file_path":"%s","edits":[{"old_string":"PLACEHOLDER1","new_string":"Metric: activation rate. Threshold: crosses 40%%.","replace_all":false},{"old_string":"Y","new_string":"Decision rule: go if it crosses, kill otherwise.","replace_all":true},{"old_string":"PLACEHOLDER2","new_string":"ITWWS: if this works we should roll it out.","replace_all":false}]},"cwd":"%s"}' \
  "$PROPOSAL" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" multiedit-mixed-replace-all

# Absolute file_path matching proposal scope.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$CURRENT_STATE")"; printf 'current state survey\n' > "$td/$CURRENT_STATE"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s/%s","content":%s},"cwd":"%s"}' \
  "$td" "$PROPOSAL" "$(jesc "$FULL")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" absolute-path-proposal

# ./-prefixed file_path variant.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$CURRENT_STATE")"; printf 'current state survey\n' > "$td/$CURRENT_STATE"
printf '{"tool_name":"Write","tool_input":{"file_path":"./%s","content":%s},"cwd":"%s"}' \
  "$PROPOSAL" "$(jesc "$FULL")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" dot-prefixed-path-proposal

# Bash command writing to the proposal path -> deny.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$CURRENT_STATE")"; printf 'current state survey\n' > "$td/$CURRENT_STATE"
printf '{"tool_name":"Bash","tool_input":{"command":"echo hi >> %s"},"cwd":"%s"}' \
  "$PROPOSAL" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" bash-write-to-proposal

# Bash command writing to the record path -> deny.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$CURRENT_STATE")"; printf 'current state survey\n' > "$td/$CURRENT_STATE"
printf '{"tool_name":"Bash","tool_input":{"command":"cat notes.txt > %s"},"cwd":"%s"}' \
  "$RECORD" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" bash-write-to-record

# Unrelated Bash command -> allow.
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Bash","tool_input":{"command":"ls -la docs/issue-7/reports"},"cwd":"%s"}' \
  "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" bash-unrelated-command

# Semantic-upgrade regression pair: decision-rule anchoring.
FALSE_POS_DECISION='Metric: activation rate. Threshold: crosses 40%.
Let'"'"'s go review the interview notes before we kill the meeting early, then pivot to lunch.
ITWWS: if this works we should roll it out.'
run deny  decision-rule-false-positive-regression "$PROPOSAL" "$FALSE_POS_DECISION" yes

WELL_FORMED_DECISION='Metric: activation rate. Threshold: crosses 40%.
Decision rule: go if it crosses, kill otherwise.
ITWWS: if this works we should roll it out.'
run allow decision-rule-well-formed-label "$PROPOSAL" "$WELL_FORMED_DECISION" yes

# missing-core: CLAUDE_PLUGIN_ROOT_CORE points nowhere -> guarded source
# must deny (exit 2) before any payload is even read, not silently allow
# (issue-75 fix).
run_raw deny missing-core-denies \
  "$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s}}' "$PROPOSAL" "$(jesc "$FULL")")" \
  CLAUDE_PLUGIN_ROOT_CORE=/no-such-core

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
