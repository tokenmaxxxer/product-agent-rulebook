#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|NotebookEdit|Bash): enforces product-cycle's
# state machine against the RESOLVED TARGET PATH being written, never
# against which tool performs the write or a literal filename appearing in
# a command string — a write made through `echo ... > file`, `tee`, or
# `sed -i` is judged the same as a Write/Edit tool call landing on the same
# path.
#
# This gate answers exactly two questions:
#   1. Does this write reach product/state.md (by resolved target path)?
#      Everything else is allowed through without comment.
#   2. If it reaches product/state.md: is the resulting `stage` transition
#      present as a row in transition-rules.md? Present -> allow.
#      Absent -> deny.
#
# It does NOT consult approval tokens or any token directory — that model
# was removed; see docs/reports/2026-07-26-hunt-conversational-state-machine.md.
#
# Two denial reasons are kept textually distinct, on purpose:
#   - "the transition rules could not be loaded" (transition-rules.md or
#     product/state.md itself could not be read/parsed, or the hook input
#     was malformed)
#   - "this transition is not in the table" (both loaded fine; the specific
#     from -> to pair just isn't a listed row)
#
# Fail-closed: anything this hook cannot parse or resolve is a DENY, never
# an allow. Malformed hook input is denied with the rules-could-not-be-loaded
# message, never a silent exit 0.
#
# A Bash command whose write target cannot be determined statically (a
# variable, expansion, command substitution, glob, `eval`, or a heredoc
# into a computed name) is treated as reaching product/state.md ONLY when
# it is write-shaped toward product/state.md's directory; otherwise it is
# NOT globally denied — it is simply outside this gate's concern, same as
# any other unrelated write.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -uo pipefail

deny() {
  echo "product-cycle: refused — $1" >&2
  exit 2
}

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "the transition rules could not be loaded — python3 is required to evaluate the gate and is not on PATH."

root="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$root" ] || deny "the transition rules could not be loaded — cannot resolve the project root (CLAUDE_PROJECT_DIR unset and cwd is not a directory)."
root="$(cd "$root" 2>/dev/null && pwd -P)" || deny "the transition rules could not be loaded — cannot resolve the project root to a real path."

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)" || deny "the transition rules could not be loaded — cannot resolve this hook's own directory."
rules_path="$script_dir/transition-rules.md"

payload="$(cat 2>/dev/null)"
[ -n "$payload" ] || deny "the transition rules could not be loaded — empty tool-use payload on stdin; cannot evaluate the state gate."

PRODUCT_ROOT="$root" PRODUCT_PAYLOAD="$payload" PRODUCT_RULES_PATH="$rules_path" python3 <<'PY'
import json
import os
import posixpath
import re
import sys

def deny(msg):
    sys.stderr.write("product-cycle: refused — %s\n" % msg)
    sys.exit(2)

def allow():
    sys.exit(0)

root = os.environ["PRODUCT_ROOT"]
rules_path = os.environ["PRODUCT_RULES_PATH"]
raw = os.environ.get("PRODUCT_PAYLOAD", "")

# --- malformed input: always denied with the rules-could-not-be-loaded ---
try:
    event = json.loads(raw)
except ValueError:
    deny("the transition rules could not be loaded — the tool-use payload is not valid JSON.")
if not isinstance(event, dict):
    deny("the transition rules could not be loaded — the tool-use payload is not a JSON object.")

tool = event.get("tool_name")
tool_input = event.get("tool_input")
if not isinstance(tool, str) or not tool:
    deny("the transition rules could not be loaded — payload has no tool_name.")
if not isinstance(tool_input, dict):
    deny("the transition rules could not be loaded — payload has no tool_input object.")

STATE_REL = "product/state.md"
STAGE_RE = re.compile(r'^stage:\s*(.*?)\s*$', re.M)

def parse_stage(text):
    """Return (stage_or_None, error_or_None)."""
    matches = STAGE_RE.findall(text or "")
    if len(matches) == 0:
        return None, "no `stage:` field"
    if len(matches) > 1:
        return None, "%d `stage:` fields (must be exactly one)" % len(matches)
    val = matches[0].strip()
    if not val:
        return None, "`stage:` field is empty"
    return val, None

def parse_rules(text):
    rows = []
    for line in (text or "").splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cols = [c.strip() for c in line.strip("|").split("|")]
        if len(cols) != 4:
            continue
        frm, to, actor, precond = cols
        if frm.lower() == "from" and to.lower() == "to":
            continue
        if re.fullmatch(r'[-: ]+', frm or "-"):
            continue
        if not frm or not to:
            continue
        rows.append((frm, to))
    return rows

# --- resolve which real filesystem path this tool call targets ----------
LITERAL_TOKEN_RE = re.compile(r'^[A-Za-z0-9_./\-]+$')

def literal_target_or_none(raw_token):
    tok = raw_token
    if len(tok) >= 2 and tok[0] == "'" and tok[-1] == "'":
        inner = tok[1:-1]
        return inner if LITERAL_TOKEN_RE.match(inner) else None
    if LITERAL_TOKEN_RE.match(tok):
        return tok
    return None

def looks_state_shaped(token):
    """Heuristic: does this unresolvable token/text look like it targets
    product/state.md (or product/'s directory), even though it cannot be
    resolved to a concrete literal path? Used ONLY to decide whether an
    unresolvable Bash write reaches the state file — never to deny
    globally for targets that plainly aren't state-shaped."""
    t = token.lower()
    return "state.md" in t or re.search(r'(^|/)product(/|$)', t) is not None

BASH_WRITE_OPS = [
    re.compile(r'>{1,2}\s*([^\s;&|<>]+)'),
    re.compile(r'\btee\b(?:\s+-a)?\s+([^\s;&|<>]+)'),
    re.compile(r'\b(?:sed|perl|ruby)\b[^|;&\n]*\s-i\b[A-Za-z0-9_.\-]*\s+([^\s;&|<>]+)'),
    re.compile(r'\bcp\b\s+.*?([^\s;&|<>]+)\s*(?:[;&|\n]|$)'),
    re.compile(r'\bmv\b\s+.*?([^\s;&|<>]+)\s*(?:[;&|\n]|$)'),
    re.compile(r'\bdd\b[^|;&\n]*\bof=([^\s;&|<>]+)'),
    re.compile(r'\binstall\b\s+.*?([^\s;&|<>]+)\s*(?:[;&|\n]|$)'),
]

real_root = posixpath.normpath(os.path.realpath(root).replace("\\", "/"))
state_abs_target = posixpath.normpath(posixpath.join(real_root, STATE_REL))

def resolves_to_state_file(literal_path):
    norm = literal_path.replace("\\", "/")
    absolute = posixpath.normpath(norm if posixpath.isabs(norm) else posixpath.join(root, norm))
    resolved = posixpath.normpath(os.path.realpath(absolute).replace("\\", "/"))
    return resolved == state_abs_target, resolved

reaches_state = False
unresolved_bash = False  # reaches state file via an unresolvable Bash target

if tool in ("Write", "Edit", "NotebookEdit"):
    path = tool_input.get("file_path") or tool_input.get("notebook_path")
    if not isinstance(path, str) or not path:
        deny("the transition rules could not be loaded — %s call has no usable file_path/notebook_path." % tool)
    is_state, resolved = resolves_to_state_file(path)
    if not is_state:
        allow()
    reaches_state = True

elif tool == "Bash":
    command = tool_input.get("command")
    if not isinstance(command, str) or not command.strip():
        deny("the transition rules could not be loaded — Bash call has no usable command string.")

    if re.search(r'(?:^|[\s;&|(])eval\b', command):
        if looks_state_shaped(command):
            reaches_state = True
            unresolved_bash = True
        else:
            allow()
    else:
        found_op = False
        for op_re in BASH_WRITE_OPS:
            for m in op_re.finditer(command):
                found_op = True
                raw_token = m.group(1)
                cand = literal_target_or_none(raw_token)
                if cand is None:
                    if looks_state_shaped(raw_token) or looks_state_shaped(command):
                        reaches_state = True
                        unresolved_bash = True
                    # else: not write-shaped toward product/state.md's
                    # directory — do not deny globally; keep scanning other
                    # ops in the same command line.
                    continue
                is_state, resolved = resolves_to_state_file(cand)
                if is_state:
                    reaches_state = True

        if not found_op:
            allow()
        if not reaches_state:
            allow()
else:
    allow()

if not reaches_state:
    allow()

if unresolved_bash:
    deny(
        "the transition rules could not be loaded — a Bash command's write target toward %s "
        "cannot be determined statically (variable/expansion/substitution/glob/eval/computed "
        "name), so the resulting `stage` transition cannot be verified; use Write or Edit instead." % STATE_REL
    )

# --- load transition-rules.md -------------------------------------------
try:
    with open(rules_path, encoding="utf-8-sig") as fh:
        rules_text = fh.read(1 << 20)
except OSError as exc:
    deny("the transition rules could not be loaded — transition-rules.md missing or unreadable at %s (%s)." % (rules_path, exc))

if not rules_text.strip():
    deny("the transition rules could not be loaded — transition-rules.md at %s is empty." % rules_path)

rows = parse_rules(rules_text)
if not rows:
    deny("the transition rules could not be loaded — transition-rules.md at %s has no parseable rows." % rules_path)

NONE_STATE = "(none)"
known_states = set()
for frm, to in rows:
    if frm != NONE_STATE:
        known_states.add(frm)
    if to != NONE_STATE:
        known_states.add(to)

# --- read current on-disk stage ------------------------------------------
# "No state file" is derived from file existence alone, as a separate
# boolean, NEVER by comparing a parsed value against the `(none)` string.
# Only a genuinely absent state file yields the synthetic `(none)` old
# state used for bootstrap-row matching.
#
# If the state file exists, its value must be a member of known_states.
# `(none)` as the on-disk value, an empty value, a missing field, or any
# value outside known_states are all the same case: the gate cannot
# establish its own input, so it denies with the rules-could-not-be-loaded
# message — never "transition not in the table".
abs_state_path = os.path.join(root, STATE_REL)
file_exists = os.path.exists(abs_state_path)
if not file_exists:
    old_stage = NONE_STATE
else:
    try:
        with open(abs_state_path, encoding="utf-8-sig") as fh:
            old_text = fh.read(1 << 20)
    except OSError as exc:
        deny("the transition rules could not be loaded — cannot read current %s (%s)." % (STATE_REL, exc))
    old_stage, old_err = parse_stage(old_text)
    if old_err:
        deny("the transition rules could not be loaded — %s: %s." % (STATE_REL, old_err))
    if old_stage not in known_states:
        deny("the transition rules could not be loaded — %s's `stage:` value %r is not a known state." % (STATE_REL, old_stage))

# --- compute resulting content -------------------------------------------
if tool == "NotebookEdit":
    deny("the transition rules could not be loaded — %s is a NotebookEdit target; this gate cannot verify notebook cell edits against frontmatter." % STATE_REL)

if tool == "Write":
    new_text = tool_input.get("content")
    if not isinstance(new_text, str):
        deny("the transition rules could not be loaded — Write call on %s has no string content." % STATE_REL)
elif tool == "Edit":
    old_string = tool_input.get("old_string")
    new_string = tool_input.get("new_string")
    if not isinstance(old_string, str) or not isinstance(new_string, str):
        deny("the transition rules could not be loaded — Edit call on %s is missing old_string/new_string." % STATE_REL)
    if old_string == "":
        new_text = new_string
    else:
        if old_string not in old_text:
            deny("the transition rules could not be loaded — Edit call's old_string was not found verbatim in %s." % STATE_REL)
        replace_all = tool_input.get("replace_all") is True
        if replace_all:
            new_text = old_text.replace(old_string, new_string)
        else:
            new_text = old_text.replace(old_string, new_string, 1)
else:
    deny("the transition rules could not be loaded — unrecognized tool %s targeting %s." % (tool, STATE_REL))

new_stage, new_err = parse_stage(new_text)
if new_err:
    deny("the transition rules could not be loaded — resulting %s would have %s." % (STATE_REL, new_err))

if (old_stage, new_stage) in rows:
    allow()

deny(
    "this transition is not in the table — `%s -> %s` is not a listed row in transition-rules.md "
    "for %s." % (old_stage, new_stage, STATE_REL)
)
PY
status=$?
exit "$status"
