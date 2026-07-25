#!/usr/bin/env bash
# Test harness for product-cycle/hooks/state-gate.sh.
# Each case sets up a scratch "project root" with its own product/state.md,
# feeds hook-shaped JSON on stdin to the gate, and asserts the exit code
# (0 = allow, non-zero = deny). Prints PASS/FAIL per case; exits non-zero
# if any case fails.
set -uo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)"
gate="$hook_dir/state-gate.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

fail_count=0
pass_count=0

pass() { echo "PASS: $1"; pass_count=$((pass_count + 1)); }
fail() { echo "FAIL: $1"; fail_count=$((fail_count + 1)); }

# run_gate <project_root> <json_payload>
# Returns exit code in $? and sets GATE_OUT.
run_gate() {
  local root="$1" payload="$2"
  GATE_OUT="$(printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$root" "$gate" 2>&1)"
  return $?
}

setup_root() {
  local dir="$1" stage="$2"
  rm -rf "$dir"
  mkdir -p "$dir/product"
  if [ -n "$stage" ]; then
    cat > "$dir/product/state.md" <<EOF
---
stage: $stage
metric: 7-day activation rate
threshold: >= 20%
---
EOF
  fi
}

json_write() {
  # $1 root (unused, for readability), $2 stage-to-write, $3 extra content lines
  python3 -c '
import json, sys
stage = sys.argv[1]
extra = sys.argv[2] if len(sys.argv) > 2 else ""
content = "---\nstage: %s\nmetric: 7-day activation rate\nthreshold: >= 20%%\n%s---\n" % (stage, extra)
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": "product/state.md", "content": content}}))
' "$2" "${3:-}"
}

# --- (a) same-state write on a state with NO self-loop row -> DENY ------
root_a="$work/a"
setup_root "$root_a" "hypothesis-registered"
payload_a="$(json_write "$root_a" "hypothesis-registered" "collected_note: still gathering\n")"
run_gate "$root_a" "$payload_a"
code_a=$?
if [ "$code_a" -ne 0 ]; then
  pass "(a) same-state write on state with no self-loop row is denied (exit $code_a)"
else
  fail "(a) same-state write on state with no self-loop row was ALLOWED (exit 0): $GATE_OUT"
fi

# --- (b) measuring | measuring same-state write -> ALLOW -----------------
root_b="$work/b"
setup_root "$root_b" "measuring"
payload_b="$(json_write "$root_b" "measuring" "collected_data: 12% so far\n")"
run_gate "$root_b" "$payload_b"
code_b=$?
if [ "$code_b" -eq 0 ]; then
  pass "(b) measuring | measuring same-state write is allowed"
else
  fail "(b) measuring | measuring same-state write was DENIED (exit $code_b): $GATE_OUT"
fi

# --- (c) normal table-legal transition -> ALLOW ---------------------------
root_c="$work/c"
setup_root "$root_c" "hypothesis-registered"
payload_c="$(json_write "$root_c" "measuring")"
run_gate "$root_c" "$payload_c"
code_c=$?
if [ "$code_c" -eq 0 ]; then
  pass "(c) hypothesis-registered -> measuring (table-legal) is allowed"
else
  fail "(c) hypothesis-registered -> measuring (table-legal) was DENIED (exit $code_c): $GATE_OUT"
fi

# --- (d) transition absent from the table -> DENY -------------------------
root_d="$work/d"
setup_root "$root_d" "idle"
payload_d="$(json_write "$root_d" "decided")"
run_gate "$root_d" "$payload_d"
code_d=$?
if [ "$code_d" -ne 0 ]; then
  pass "(d) idle -> decided (absent from table) is denied (exit $code_d)"
else
  fail "(d) idle -> decided (absent from table) was ALLOWED (exit 0): $GATE_OUT"
fi

# --- (e) Bash-shaped write resolving to the state file, judged same as Write
root_e="$work/e"
setup_root "$root_e" "idle"
# Use a Bash command that literally targets product/state.md via a heredoc
# redirect — statically resolvable, so the gate must parse and judge it
# exactly like the Write-shaped case in (d): idle -> decided is illegal.
bash_cmd='cat > product/state.md <<EOF
---
stage: decided
metric: 7-day activation rate
threshold: >= 20%
---
EOF'
payload_e="$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}}))
' "$bash_cmd")"
run_gate "$root_e" "$payload_e"
code_e=$?
if [ "$code_e" -ne 0 ]; then
  pass "(e) Bash-shaped write resolving to state file is judged (denied) same as Write"
else
  fail "(e) Bash-shaped write resolving to state file was ALLOWED (exit 0): $GATE_OUT"
fi

# Also confirm a Bash write that does NOT reach the state file's directory
# at all is left alone (not blanket-denied) — proves the gate targets the
# resolved path, not the Bash tool name.
root_e2="$work/e2"
setup_root "$root_e2" "hypothesis-registered"
bash_cmd2='cat > /tmp/unrelated-scratch-file.md <<EOF
some unrelated artifact content, not the state file
EOF'
payload_e2="$(python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}}))
' "$bash_cmd2")"
run_gate "$root_e2" "$payload_e2"
code_e2=$?
if [ "$code_e2" -eq 0 ]; then
  pass "(e2) Bash write to an unrelated path is left ungated (allowed)"
else
  fail "(e2) Bash write to an unrelated path was DENIED (exit $code_e2): $GATE_OUT"
fi

# --- (f) malformed hook JSON -> DENY with visible output, never silent 0 -
root_f="$work/f"
setup_root "$root_f" "idle"
GATE_OUT="$(printf '%s' 'not json at all {{{' | CLAUDE_PROJECT_DIR="$root_f" "$gate" 2>&1)"
code_f=$?
if [ "$code_f" -ne 0 ] && [ -n "$GATE_OUT" ]; then
  pass "(f) malformed hook JSON is denied with visible output (exit $code_f)"
else
  fail "(f) malformed hook JSON was NOT denied with output (exit $code_f, out='$GATE_OUT')"
fi

echo
echo "== $pass_count passed, $fail_count failed =="
[ "$fail_count" -eq 0 ]
