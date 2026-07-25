#!/usr/bin/env bash
# UserPromptSubmit hook: injects the current product-cycle state and the
# legal transitions out of it, read from transition-rules.md and
# product/state.md (frontmatter field `stage`).
#
# THE CRITICAL RULE this hook exists to satisfy: it must NEVER exit with no
# stdout output. If the rules file or the state file is missing, unreadable,
# empty, or unparseable, it still emits a block — one that says plainly
# that the rules could not be loaded and why, and that no transition may be
# made until that is fixed. A silent exit here is the exact defect recorded
# in docs/reports/2026-07-26-hunt-conversational-state-machine.md.
#
# This hook never blocks the prompt: it always exits 0.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -uo pipefail

fallback() {
  cat <<EOF
product-cycle: transition rules could not be loaded — $1
No transition of product/state.md's \`stage\` field may be made until this is fixed.
EOF
  exit 0
}

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

# Consume stdin so the harness doesn't see a broken pipe; content unused.
cat >/dev/null 2>&1 || true

command -v python3 >/dev/null 2>&1 || fallback "python3 is not on PATH and is required to parse transition-rules.md and product/state.md."

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)" || fallback "cannot resolve this hook's own directory to find transition-rules.md."
rules_path="$script_dir/transition-rules.md"

root="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$root" ] || fallback "cannot resolve the project root (CLAUDE_PROJECT_DIR unset and cwd is not a directory)."
root="$(cd "$root" 2>/dev/null && pwd -P)" || fallback "cannot resolve the project root to a real path."
state_path="$root/product/state.md"

PRODUCT_RULES_PATH="$rules_path" PRODUCT_STATE_PATH="$state_path" python3 <<'PY'
import os
import re
import sys

rules_path = os.environ["PRODUCT_RULES_PATH"]
state_path = os.environ["PRODUCT_STATE_PATH"]

def fail(reason):
    print("product-cycle: transition rules could not be loaded — %s" % reason)
    print("No transition of product/state.md's `stage` field may be made until this is fixed.")
    sys.exit(0)

# --- load transition-rules.md -------------------------------------------
try:
    with open(rules_path, encoding="utf-8-sig") as fh:
        rules_text = fh.read(1 << 20)
except OSError as exc:
    fail("transition-rules.md is missing or unreadable at %s (%s)." % (rules_path, exc))

if not rules_text.strip():
    fail("transition-rules.md at %s is empty." % rules_path)

def parse_rows(text):
    rows = []
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cols = [c.strip() for c in line.strip("|").split("|")]
        if len(cols) != 4:
            continue
        frm, to, actor, precond = cols
        if frm.lower() == "from" and to.lower() == "to":
            continue  # header row
        if re.fullmatch(r'[-: ]+', frm or "-"):
            continue  # separator row
        if not frm or not to:
            continue
        rows.append({"from": frm, "to": to, "actor": actor, "precondition": precond})
    return rows

rows = parse_rows(rules_text)
if not rows:
    fail("transition-rules.md at %s has no parseable `from | to | actor | precondition` rows." % rules_path)

NONE_STATE = "(none)"
known_states = set()
for r in rows:
    if r["from"] != NONE_STATE:
        known_states.add(r["from"])
    if r["to"] != NONE_STATE:
        known_states.add(r["to"])

# --- load product/state.md ------------------------------------------------
# "No state file" is derived from file existence alone, as a separate
# boolean, NEVER by comparing the parsed value against the `(none)` string.
# Only a genuinely absent state file yields the synthetic bootstrap state
# `(none)`.
#
# If the state file exists, its value must be a member of known_states.
# `(none)`, empty, missing, or out-of-set are all a broken input for the
# injector exactly as for the gate: emit the existing failure block instead
# of rendering the broken value as if it were the current state.
if not os.path.exists(state_path):
    current_stage = "(none)"
else:
    try:
        with open(state_path, encoding="utf-8-sig") as fh:
            state_text = fh.read(1 << 20)
    except OSError as exc:
        fail("product/state.md is missing or unreadable at %s (%s)." % (state_path, exc))

    stage_matches = re.findall(r'^stage:\s*(.*?)\s*$', state_text, re.M)
    if len(stage_matches) == 0:
        fail("product/state.md has no `stage:` field.")
    if len(stage_matches) > 1:
        fail("product/state.md has %d `stage:` fields; it must have exactly one." % len(stage_matches))
    current_stage = stage_matches[0].strip()
    if not current_stage:
        fail("product/state.md's `stage:` field is present but empty.")
    if current_stage not in known_states:
        fail("product/state.md's `stage:` value %r is not a known state." % current_stage)

# --- emit the block --------------------------------------------------------
applicable = [r for r in rows if r["from"] == current_stage]

print("product-cycle: current state — stage: %s" % current_stage)
if not applicable:
    print("No legal transitions are listed out of `%s` in transition-rules.md." % current_stage)
else:
    print("Legal transitions out of `%s`:" % current_stage)
    print("| condition (precondition) | allowed transition | actor |")
    print("|---|---|---|")
    for r in applicable:
        print("| %s | %s -> %s | %s |" % (r["precondition"], r["from"], r["to"], r["actor"]))
print(
    "A row with actor `user` may only be taken if the user has actually said the "
    "corresponding thing in this conversation — the model must not self-approve it — "
    "and the model must append one line to product/state.md naming the user utterance "
    "it read as the basis for the transition."
)
PY
exit 0
