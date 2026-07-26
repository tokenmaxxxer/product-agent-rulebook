#!/usr/bin/env bash
# Test harness for product-cycle/hooks/state-gate.sh.
# Each case sets up a scratch "project root" with its own product/state.md,
# feeds hook-shaped JSON on stdin to the gate, and asserts the exit code
# (0 = allow, non-zero = deny). Prints PASS/FAIL per case; exits non-zero
# if any case fails.
set -uo pipefail

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)"
gate="$hook_dir/state-gate.sh"
repo_root="$(cd "$hook_dir/../.." >/dev/null 2>&1 && pwd -P)"
contract_src="$repo_root/docs/specs/role-handoff-contract.md"

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
  mkdir -p "$dir/product" "$dir/docs/specs"
  cp "$contract_src" "$dir/docs/specs/role-handoff-contract.md"
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

# --- (g) existing state file with `stage: (none)` -> DENY, rules-could-not-be-loaded
root_g="$work/g"
rm -rf "$root_g"; mkdir -p "$root_g/product" "$root_g/docs/specs"; cp "$contract_src" "$root_g/docs/specs/role-handoff-contract.md"
cat > "$root_g/product/state.md" <<'EOF'
---
stage: (none)
metric: 7-day activation rate
threshold: >= 20%
---
EOF
payload_g="$(json_write "$root_g" "idle")"
run_gate "$root_g" "$payload_g"
code_g=$?
if [ "$code_g" -ne 0 ] && printf '%s' "$GATE_OUT" | grep -q "rules could not be loaded"; then
  pass "(g) existing state file with stage: (none) is denied with rules-could-not-be-loaded"
else
  fail "(g) existing state file with stage: (none) was NOT denied properly (exit $code_g): $GATE_OUT"
fi

# --- (h) existing state file with empty stage value -> DENY likewise -----
root_h="$work/h"
rm -rf "$root_h"; mkdir -p "$root_h/product" "$root_h/docs/specs"; cp "$contract_src" "$root_h/docs/specs/role-handoff-contract.md"
cat > "$root_h/product/state.md" <<'EOF'
---
stage:
metric: 7-day activation rate
threshold: >= 20%
---
EOF
payload_h="$(json_write "$root_h" "idle")"
run_gate "$root_h" "$payload_h"
code_h=$?
if [ "$code_h" -ne 0 ] && printf '%s' "$GATE_OUT" | grep -q "rules could not be loaded"; then
  pass "(h) existing state file with empty stage value is denied with rules-could-not-be-loaded"
else
  fail "(h) existing state file with empty stage value was NOT denied properly (exit $code_h): $GATE_OUT"
fi

# --- (i) existing state file with out-of-set stage value -> DENY likewise
root_i="$work/i"
setup_root "$root_i" "totally-made-up-stage"
payload_i="$(json_write "$root_i" "idle")"
run_gate "$root_i" "$payload_i"
code_i=$?
if [ "$code_i" -ne 0 ] && printf '%s' "$GATE_OUT" | grep -q "rules could not be loaded"; then
  pass "(i) existing state file with out-of-set stage value is denied with rules-could-not-be-loaded"
else
  fail "(i) existing state file with out-of-set stage value was NOT denied properly (exit $code_i): $GATE_OUT"
fi

# --- (j) existing state file with valid value + trailing whitespace/CRLF -> treated as that valid state
root_j="$work/j"
rm -rf "$root_j"; mkdir -p "$root_j/product" "$root_j/docs/specs"; cp "$contract_src" "$root_j/docs/specs/role-handoff-contract.md"
printf -- '---\r\nstage: idle   \r\nmetric: 7-day activation rate\r\nthreshold: >= 20%%\r\n---\r\n' > "$root_j/product/state.md"
payload_j="$(json_write "$root_j" "scoping")"
run_gate "$root_j" "$payload_j"
code_j=$?
if [ "$code_j" -eq 0 ]; then
  pass "(j) existing state file with trailing whitespace/CRLF on a valid value is treated as that valid state"
else
  fail "(j) existing state file with trailing whitespace/CRLF on a valid value was DENIED (exit $code_j): $GATE_OUT"
fi

# --- (k) state file genuinely absent -> (none) -> X bootstrap row still ALLOWED
root_k="$work/k"
rm -rf "$root_k"; mkdir -p "$root_k/product" "$root_k/docs/specs"; cp "$contract_src" "$root_k/docs/specs/role-handoff-contract.md"
payload_k="$(json_write "$root_k" "idle")"
run_gate "$root_k" "$payload_k"
code_k=$?
if [ "$code_k" -eq 0 ]; then
  pass "(k) genuinely absent state file: (none) -> idle bootstrap row is still allowed"
else
  fail "(k) genuinely absent state file: (none) -> idle bootstrap row was DENIED (exit $code_k): $GATE_OUT"
fi

# --- (l) CLAUDE_PROJECT_DIR unset: git-toplevel fallback -------------------
# Per docs/proposals/2026-07-26-gate-root-from-project-dir.md §2(b): with
# CLAUDE_PROJECT_DIR unset, root falls back to the git top-level of the
# PreToolUse target path, else the git top-level of cwd.
repo_root="$(cd "$hook_dir/../.." && pwd -P)"
outside_dir="$(mktemp -d)"
payload_l='{"tool_name":"Write","tool_input":{"file_path":"product/state.md","content":"---\nstage: idle\nmetric: 7-day activation rate\nthreshold: >= 20%\n---\n"}}'
out_in="$(cd "$repo_root" && env -u CLAUDE_PROJECT_DIR bash -c 'printf "%s" "$1" | "$2"' _ "$payload_l" "$gate" 2>&1)"
code_in=$?
if [ "$code_in" -eq 0 ]; then
  pass "(l1) CLAUDE_PROJECT_DIR unset, invoked inside this repo — falls back to this repo's own git top-level and enforces normally (exit 0)"
else
  fail "(l1) CLAUDE_PROJECT_DIR unset, invoked inside this repo — expected exit 0 via git-toplevel fallback, got exit $code_in. Output: $out_in"
fi

# (l2) CLAUDE_PROJECT_DIR unset, cwd AND target both outside any git
# work-tree -> root is indeterminate -> refused (never silently allowed).
out_out="$(cd "$outside_dir" && env -u CLAUDE_PROJECT_DIR bash -c 'printf "%s" "$1" | "$2"' _ "$payload_l" "$gate" 2>&1)"
code_out=$?
rm -rf "$outside_dir"
if [ "$code_out" -ne 0 ]; then
  pass "(l2) CLAUDE_PROJECT_DIR unset, cwd/target both outside any git work-tree — indeterminate root refused (exit $code_out)"
else
  fail "(l2) CLAUDE_PROJECT_DIR unset, cwd/target both outside any git work-tree — expected refused (non-zero), got exit 0. Output: $out_out"
fi

# --- (q) target-repo-governance: CLAUDE_PROJECT_DIR pointed at an
# unrelated, empty (but plausible-looking, git-initialized) directory, and
# the Write targets an owned-tree path that is ALSO not inside any git
# work-tree -> root is genuinely indeterminate -> default-deny per §2(c),
# not silently allowed.
unrelated_dir="$(mktemp -d)"
git init -q "$unrelated_dir" >/dev/null 2>&1
non_git_target_dir="$(mktemp -d)"
scratch_subject_q="gateroot-unrelated-projectdir-test"
mkdir -p "$non_git_target_dir/docs/reports/records/$scratch_subject_q"
payload_q="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$non_git_target_dir/docs/reports/records/$scratch_subject_q/product.md\",\"content\":\"status: idle\\n\"}}"
out_q="$(cd "$non_git_target_dir" && env CLAUDE_PROJECT_DIR="$unrelated_dir" bash -c 'printf "%s" "$1" | "$2"' _ "$payload_q" "$gate" 2>&1)"
rc_q=$?
rm -rf "$unrelated_dir" "$non_git_target_dir"
if [ "$rc_q" -ne 0 ]; then
  pass "(q) CLAUDE_PROJECT_DIR pointed at an unrelated empty dir, target's owned-tree write has no resolvable git root either — indeterminate root default-denied (exit $rc_q), not silently allowed"
else
  fail "(q) CLAUDE_PROJECT_DIR pointed at an unrelated empty dir, target has no resolvable git root — expected refused (default-deny), got exit 0 (silently allowed). Output: $out_q"
fi

# --- (r) target-repo-governance: CLAUDE_PROJECT_DIR correctly set (target
# is under it, and it looks like a project root) -> gate enforced normally
# against that SEPARATE target project, not against this rulebook repo.
target_repo_r="$(mktemp -d)"
mkdir -p "$target_repo_r/docs/specs"
cp "$contract_src" "$target_repo_r/docs/specs/role-handoff-contract.md"
payload_r="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$target_repo_r/product/state.md\",\"content\":\"---\\nstage: measuring\\nmetric: 7-day activation rate\\nthreshold: >= 20%\\n---\\n\"}}"
run_gate "$target_repo_r" "$payload_r"
rc_r=$?
out_r="$GATE_OUT"
rm -rf "$target_repo_r"
if [ "$rc_r" -ne 0 ]; then
  pass "(r) valid CLAUDE_PROJECT_DIR pointed at a separate target project — illegal bootstrap write refused there (exit $rc_r)"
else
  fail "(r) valid CLAUDE_PROJECT_DIR pointed at a separate target project — expected refused, got exit 0. Output: $out_r"
fi

# --- (m) write-detection bypass fix (docs/proposals/2026-07-26-fix-state-gate-writeop-bypass.md)
# Root resolution for this gate is always anchored to the hook's own git
# root (never CLAUDE_PROJECT_DIR), so these three cases operate directly
# against THIS repo's checkout with a scratch subject, cleaned up on exit.
scratch_subject="gatefix-bypass-test"
scratch_dir="$repo_root/docs/reports/records/$scratch_subject"
cleanup_scratch() { rm -rf "$scratch_dir"; }
trap 'cleanup_scratch; rm -rf "$work"' EXIT
cleanup_scratch
mkdir -p "$scratch_dir"

payload_m1='{"tool_name":"Bash","tool_input":{"command":"python3 -c \"open('"'"'docs/reports/records/'"$scratch_subject"'/coding.md'"'"','"'"'w'"'"').write('"'"'x'"'"')\""}}'
out_m1="$(cd "$repo_root" && printf '%s' "$payload_m1" | "$gate" 2>&1)"
code_m1=$?
if [ "$code_m1" -ne 0 ]; then
  pass "(m1) Bash python3-open write to a foreign role's record is refused (exit $code_m1)"
else
  fail "(m1) Bash python3-open write to a foreign role's record was ALLOWED (exit 0): $out_m1"
fi

payload_m2="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"docs/reports/records/$scratch_subject/product.md\",\"content\":\"status: idle\\nhypothesis: docs/proposals/2026-07-26-sample.md\\n\"}}"
out_m2="$(cd "$repo_root" && printf '%s' "$payload_m2" | "$gate" 2>&1)"
code_m2=$?
if [ "$code_m2" -eq 0 ]; then
  pass "(m2) legal write to product's own record slot is allowed (exit 0)"
else
  fail "(m2) legal write to product's own record slot was DENIED (exit $code_m2): $out_m2"
fi

payload_m3='{"tool_name":"Bash","tool_input":{"command":"python3 -c \"import sys; open('"'"'docs/reports/records/'"'"' + sys.argv[1] + '"'"'/coding.md'"'"','"'"'w'"'"').write('"'"'x'"'"')\" '"$scratch_subject"'"}}'
out_m3="$(cd "$repo_root" && printf '%s' "$payload_m3" | "$gate" 2>&1)"
code_m3=$?
if [ "$code_m3" -ne 0 ]; then
  pass "(m3) Bash python3-open write with indeterminate target in the owned record tree is refused (exit $code_m3)"
else
  fail "(m3) Bash python3-open write with indeterminate target in the owned record tree was ALLOWED (exit 0): $out_m3"
fi


# --- path-reference default-deny (docs/proposals/2026-07-26-gate-nested-shell-default-deny.md)
# Each of these targets a FOREIGN role's record slot via a write idiom this
# gate never enumerated by name (write_text/write_bytes/os.write) or via a
# nested shell / command substitution wrapper around a plain write. The
# rule is not "match this idiom" — it is "default-deny any reference into
# the owned record tree this gate cannot prove is read-only" — so all five
# must be refused regardless of the specific idiom used.
payload_p1='{"tool_name":"Bash","tool_input":{"command":"python3 -c \"import pathlib; pathlib.Path('"'"'docs/reports/records/'"$scratch_subject"'/coding.md'"'"').write_text('"'"'x'"'"')\""}}'
out_p1="$(cd "$repo_root" && printf '%s' "$payload_p1" | "$gate" 2>&1)"
code_p1=$?
if [ "$code_p1" -ne 0 ]; then
  pass "(p1) Bash pathlib.Path(...).write_text(...) write to a foreign role's record is refused (exit $code_p1)"
else
  fail "(p1) Bash pathlib.Path(...).write_text(...) write to a foreign role's record was ALLOWED (exit 0): $out_p1"
fi

payload_p2='{"tool_name":"Bash","tool_input":{"command":"python3 -c \"import pathlib; pathlib.Path('"'"'docs/reports/records/'"$scratch_subject"'/coding.md'"'"').write_bytes(b'"'"'x'"'"')\""}}'
out_p2="$(cd "$repo_root" && printf '%s' "$payload_p2" | "$gate" 2>&1)"
code_p2=$?
if [ "$code_p2" -ne 0 ]; then
  pass "(p2) Bash pathlib.Path(...).write_bytes(...) write to a foreign role's record is refused (exit $code_p2)"
else
  fail "(p2) Bash pathlib.Path(...).write_bytes(...) write to a foreign role's record was ALLOWED (exit 0): $out_p2"
fi

payload_p3='{"tool_name":"Bash","tool_input":{"command":"python3 -c \"import os; fd = os.open('"'"'docs/reports/records/'"$scratch_subject"'/coding.md'"'"', os.O_WRONLY | os.O_CREAT); os.write(fd, b'"'"'x'"'"')\""}}'
out_p3="$(cd "$repo_root" && printf '%s' "$payload_p3" | "$gate" 2>&1)"
code_p3=$?
if [ "$code_p3" -ne 0 ]; then
  pass "(p3) Bash os.write(...) write to a foreign role's record is refused (exit $code_p3)"
else
  fail "(p3) Bash os.write(...) write to a foreign role's record was ALLOWED (exit 0): $out_p3"
fi

payload_p4='{"tool_name":"Bash","tool_input":{"command":"sh -c \"echo x > docs/reports/records/'"$scratch_subject"'/coding.md\""}}'
out_p4="$(cd "$repo_root" && printf '%s' "$payload_p4" | "$gate" 2>&1)"
code_p4=$?
if [ "$code_p4" -ne 0 ]; then
  pass "(p4) sh -c-wrapped write to a foreign role's record is refused (exit $code_p4)"
else
  fail "(p4) sh -c-wrapped write to a foreign role's record was ALLOWED (exit 0): $out_p4"
fi

payload_p5="{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"echo x > \$(echo docs/reports/records/$scratch_subject/coding.md)\"}}"
out_p5="$(cd "$repo_root" && printf '%s' "$payload_p5" | "$gate" 2>&1)"
code_p5=$?
if [ "$code_p5" -ne 0 ]; then
  pass "(p5) command-substitution-wrapped write to a foreign role's record is refused (exit $code_p5)"
else
  fail "(p5) command-substitution-wrapped write to a foreign role's record was ALLOWED (exit 0): $out_p5"
fi


cleanup_scratch

# --- (s) simulated missing python3 -> DENY, mentioning python3 -----------
# Companion to docs/proposals/2026-07-26-fix-fail-open-persistent-tests.md:
# state-gate.sh's own intake (`command -v python3 || deny ...`) was already
# fail-closed before that proposal, but no persistent case exercised it.
# A minimal PATH stub carries only what runs before the python3 check --
# bash itself, for re-exec -- with python3 deliberately absent.
root_s="$work/s"
setup_root "$root_s" "idle"
payload_s="$(json_write "$root_s" "idle")"
NO_PYTHON3_STUB="$work/no-python3-stub"
mkdir -p "$NO_PYTHON3_STUB"
for _c in bash; do
  _src="$(command -v "$_c" 2>/dev/null)"
  [ -n "$_src" ] && ln -sf "$_src" "$NO_PYTHON3_STUB/$_c"
done
GATE_OUT="$(printf '%s' "$payload_s" | CLAUDE_PROJECT_DIR="$root_s" PATH="$NO_PYTHON3_STUB" "$NO_PYTHON3_STUB/bash" "$gate" 2>&1)"
code_s=$?
if [ "$code_s" -ne 0 ] && printf '%s' "$GATE_OUT" | grep -q "python3"; then
  pass "(s) simulated missing python3 is denied, mentioning python3 (exit $code_s)"
else
  fail "(s) simulated missing python3 was NOT denied properly (exit $code_s): $GATE_OUT"
fi

echo
echo "== $pass_count passed, $fail_count failed =="
[ "$fail_count" -eq 0 ]
