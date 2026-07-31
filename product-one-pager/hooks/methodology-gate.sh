#!/usr/bin/env bash
# product-one-pager methodology gate: fires only on the current-state
# survey write (docs/issue-<n>/reports/product-discovery/current-state.md)
# and checks the JTBD problem-without-solution facet — see
# docs/issue-42/proposals/2026-07-31-methodology-gate-machine.md section 1.
set -uo pipefail

deny() {
  printf '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 2
}

# Kill switch — independently toggleable per plugin.
if [ "${PRODUCT_ONE_PAGER_GATE_OFF:-}" = "1" ]; then
  exit 0
fi

trap 'deny "product-one-pager: internal error in methodology-gate.sh"' ERR

command -v python3 >/dev/null 2>&1 || deny "product-one-pager: refused — python3 unavailable"

payload="$(cat)"
[ -n "$payload" ] || deny "product-one-pager: refused — cannot parse tool call"

parsed="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    obj = json.load(sys.stdin)
except Exception:
    sys.exit(1)
if not isinstance(obj, dict):
    sys.exit(1)
ti = obj.get("tool_input")
if not isinstance(ti, dict):
    sys.exit(1)
print(json.dumps(obj))
' 2>/dev/null)"
[ -n "$parsed" ] || deny "product-one-pager: refused — cannot parse tool call"

get_field() {
  printf '%s' "$parsed" | python3 -c "
import json, sys
obj = json.load(sys.stdin)
val = obj
for key in sys.argv[1:]:
    if isinstance(val, dict) and key in val:
        val = val[key]
    else:
        print('')
        sys.exit(0)
if isinstance(val, (dict, list)):
    print(json.dumps(val))
elif val is None:
    print('')
else:
    print(val)
" "$@"
}

tool_name="$(get_field tool_name)"
file_path="$(get_field tool_input file_path)"
cwd="$(get_field cwd)"

[ -n "$file_path" ] || exit 0

# Resolve project root: CLAUDE_PROJECT_DIR hint if plausible, else git
# toplevel from cwd, else cwd itself.
resolve_root() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR:-}" ]; then
    case "$CLAUDE_PROJECT_DIR" in
      /*) printf '%s' "$CLAUDE_PROJECT_DIR"; return 0 ;;
    esac
  fi
  if [ -n "$cwd" ] && [ -d "$cwd" ]; then
    local top
    top="$(cd "$cwd" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)"
    if [ -n "$top" ]; then
      printf '%s' "$top"
      return 0
    fi
    printf '%s' "$cwd"
    return 0
  fi
  pwd -P
}

root="$(resolve_root)"

# Only this plugin's own business: the current-state survey file.
case "$file_path" in
  /*) abs_path="$file_path" ;;
  *) abs_path="$root/$file_path" ;;
esac

# Normalize to a root-relative form for the regex check regardless of
# whether the incoming path was absolute or relative.
rel_path="$abs_path"
case "$abs_path" in
  "$root"/*) rel_path="${abs_path#"$root"/}" ;;
esac

if ! printf '%s' "$rel_path" | grep -qE '(^|/)docs/issue-[0-9]+/reports/product-discovery/current-state\.md$'; then
  exit 0
fi

# Reconstruct the resulting content for Write/Edit/MultiEdit, in a
# single python3 invocation fed the full parsed
# payload on stdin, avoiding intermediate shell temp files.
resulting_content="$(printf '%s' "$parsed" | python3 -c '
import json, sys, os

obj = json.load(sys.stdin)
tool_name = obj.get("tool_name", "")
ti = obj.get("tool_input", {})
abs_path = sys.argv[1]

def read_existing():
    try:
        with open(abs_path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return None

def apply_edit(text, old, new, replace_all):
    if old == "":
        return text + new
    if old not in text:
        return None
    if replace_all:
        return text.replace(old, new)
    return text.replace(old, new, 1)

try:
    if tool_name == "Write":
        content = ti.get("content")
        if content is None:
            print("__RECON_FAIL__")
            sys.exit(0)
        print(content, end="")
        sys.exit(0)

    if tool_name == "Edit":
        existing = read_existing()
        if existing is None:
            print("__RECON_FAIL__")
            sys.exit(0)
        old = ti.get("old_string", "")
        new = ti.get("new_string", "")
        replace_all = bool(ti.get("replace_all", False))
        result = apply_edit(existing, old, new, replace_all)
        if result is None:
            print("__RECON_FAIL__")
            sys.exit(0)
        print(result, end="")
        sys.exit(0)

    if tool_name == "MultiEdit":
        existing = read_existing()
        if existing is None:
            print("__RECON_FAIL__")
            sys.exit(0)
        edits = ti.get("edits")
        if not isinstance(edits, list):
            print("__RECON_FAIL__")
            sys.exit(0)
        text = existing
        for e in edits:
            if not isinstance(e, dict):
                print("__RECON_FAIL__")
                sys.exit(0)
            old = e.get("old_string", "")
            new = e.get("new_string", "")
            replace_all = bool(e.get("replace_all", False))
            result = apply_edit(text, old, new, replace_all)
            if result is None:
                print("__RECON_FAIL__")
                sys.exit(0)
            text = result
        print(text, end="")
        sys.exit(0)

    # Unrecognized tool name for this matcher — nothing to reconstruct.
    print("__RECON_FAIL__")
except Exception:
    print("__RECON_FAIL__")
' "$abs_path")"

if [ "$resulting_content" = "__RECON_FAIL__" ]; then
  deny "product-one-pager: refused — cannot determine resulting content"
fi

# --- facet check ------------------------------------------------------
# Criterion (section 1): the problem must be stated as a JTBD 4-tuple
# (performer, job, circumstance, desired outcome) BEFORE any solution
# name appears.
#
# Heuristic (documented, not a formal parser): find the earliest
# position at which ALL of the JTBD-tuple marker words are present in
# the text (case-insensitive) — "performer" (or "job performer"),
# "circumstance", "desired outcome" (or "outcome") — treating the tuple
# as "stated" once all three marker classes have appeared at least
# once. Compare that against the earliest position of a heuristic
# solution-name marker: lines/phrases that announce a solution rather
# than a problem, e.g. "Solution:", "We will build", "제안:", "우리는".
# If a solution marker occurs strictly before the JTBD tuple is
# complete (or the tuple never completes), deny.
verdict="$(printf '%s' "$resulting_content" | python3 -c '
import re, sys

text = sys.stdin.read()
lower = text.lower()

# JTBD-tuple marker classes.
performer_re = re.compile(r"job performer|performer")
job_re = re.compile(r"\bjob\b")
circumstance_re = re.compile(r"circumstance")
outcome_re = re.compile(r"desired outcome|outcome")
jtbd_label_re = re.compile(r"jtbd")

def first(pat):
    m = pat.search(lower)
    return m.start() if m else None

p_pos = first(performer_re)
j_pos = first(job_re)
c_pos = first(circumstance_re)
o_pos = first(outcome_re)
jtbd_pos = first(jtbd_label_re)

missing = []
if p_pos is None:
    missing.append("job-performer")
if c_pos is None:
    missing.append("circumstance")
if o_pos is None:
    missing.append("desired-outcome")

if missing:
    print("DENY:missing:" + ",".join(missing))
    sys.exit(0)

tuple_positions = [x for x in [p_pos, c_pos, o_pos] if x is not None]
tuple_complete_pos = max(tuple_positions)
if jtbd_pos is not None:
    tuple_complete_pos = min(tuple_complete_pos, jtbd_pos)

# Heuristic solution-name markers: obvious solution-announcing phrases.
solution_markers = [
    re.compile(r"^\s*solution\s*:", re.MULTILINE),
    re.compile(r"we will build"),
    re.compile(r"we are building"),
    re.compile(r"제안\s*:"),
    re.compile(r"우리는\s*[^\n]*?(만든다|만듭니다|구축한다|구축합니다)"),
]

earliest_solution_pos = None
for pat in solution_markers:
    m = pat.search(lower if pat.flags & re.MULTILINE == 0 and False else text.lower())
    if m:
        if earliest_solution_pos is None or m.start() < earliest_solution_pos:
            earliest_solution_pos = m.start()

if earliest_solution_pos is not None and earliest_solution_pos < tuple_complete_pos:
    print("DENY:solution-before-tuple")
    sys.exit(0)

print("OK")
')"

case "$verdict" in
  OK)
    exit 0
    ;;
  DENY:missing:*)
    missing="${verdict#DENY:missing:}"
    deny "product-one-pager: refused — JTBD tuple element(s) missing: ${missing}. Per docs/issue-36/..., the problem must be stated as a JTBD 4-tuple (performer, job, circumstance, desired outcome) before any solution name appears."
    ;;
  DENY:solution-before-tuple)
    deny "product-one-pager: refused — a solution name appears before the JTBD tuple is stated. Per docs/issue-36/..., the JTBD tuple (performer, job, circumstance, desired outcome) must be stated before any solution name appears."
    ;;
  *)
    deny "product-one-pager: refused — cannot evaluate JTBD facet"
    ;;
esac
