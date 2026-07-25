#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|NotebookEdit|Bash): enforces product-cycle's
# state machine (docs/specs/state-machine.md) against the RESOLVED TARGET
# PATH being written, never against which tool performs the write — a
# write made through `echo ... > file`, `tee`, or `sed -i` is judged the
# same as a Write/Edit tool call that lands on the same path.
#
# Unlike coding-agent-rulebook/warrant and qa-agent-rulebook/signoff, this
# gate does NOT fail open on malformed input. Anything this hook cannot
# parse or resolve is a DENY, never an allow — see docs/specs/state-machine.md
# "Fail-closed" for the reasoning.
#
# Enforced rules:
#   1. hypothesis-registered -> measuring is refused unless metric,
#      threshold, and decision_rule are all non-empty in the file AND a
#      matching approval token (minted by capture-approval.sh from the
#      user's own turn) is present.
#   2. While status is measuring, edits to the threshold field are refused.
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

command -v python3 >/dev/null 2>&1 || deny "python3 is required to evaluate the state gate and is not on PATH; refusing rather than allowing an unverified write."

root="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$root" ] || deny "cannot resolve the project root (CLAUDE_PROJECT_DIR unset and cwd is not a directory)."
root="$(cd "$root" 2>/dev/null && pwd -P)" || deny "cannot resolve the project root to a real path."

payload="$(cat 2>/dev/null)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the state gate."

PRODUCT_ROOT="$root" PRODUCT_PAYLOAD="$payload" python3 <<'PY'
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
raw = os.environ.get("PRODUCT_PAYLOAD", "")
try:
    event = json.loads(raw)
except ValueError:
    deny("the tool-use payload is not valid JSON.")
if not isinstance(event, dict):
    deny("the tool-use payload is not a JSON object.")

tool = event.get("tool_name")
tool_input = event.get("tool_input")
if not isinstance(tool, str) or not tool:
    deny("payload has no tool_name.")
if not isinstance(tool_input, dict):
    deny("payload has no tool_input object.")

FRONTMATTER_RE = re.compile(r'^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*\r?\n?', re.M | re.S)
STATUS_RE = re.compile(r'^status:\s*(.*?)\s*(?:#.*)?$', re.M)
METRIC_RE = re.compile(r'^metric:\s*(.*?)\s*(?:#.*)?$', re.M)
THRESHOLD_RE = re.compile(r'^threshold:\s*(.*?)\s*(?:#.*)?$', re.M)
RULE_RE = re.compile(r'^decision_rule:\s*(.*?)\s*(?:#.*)?$', re.M)

def parse(text):
    m = FRONTMATTER_RE.match(text or "")
    if not m:
        return {"status": "", "metric": "", "threshold": "", "decision_rule": ""}
    block = m.group(1)
    def get(rx):
        mm = rx.search(block)
        return mm.group(1).strip() if mm else ""
    return {
        "status": get(STATUS_RE),
        "metric": get(METRIC_RE),
        "threshold": get(THRESHOLD_RE),
        "decision_rule": get(RULE_RE),
    }

# --- resolve which real filesystem path this tool call targets ----------
BASH_TARGET_RE = re.compile(
    r'(?:>{1,2}|\btee\b(?:\s+-a)?|\b(?:sed|perl|ruby)\b[^|;&]*\s-i\b[A-Za-z0-9_.\-]*)\s*([^\s;&|<>]+)'
)

target_rel = None   # path relative to root, product-cycle's concern only
target_kind = None  # "write_tool" | "bash" (bash targets can't be content-computed)

if tool in ("Write", "Edit", "NotebookEdit"):
    path = tool_input.get("file_path") or tool_input.get("notebook_path")
    if not isinstance(path, str) or not path:
        deny("%s call has no usable file_path/notebook_path." % tool)
    norm = path.replace("\\", "/")
    absolute = posixpath.normpath(norm if posixpath.isabs(norm) else posixpath.join(root, norm))
    real_root = posixpath.normpath(os.path.realpath(root).replace("\\", "/"))
    resolved = posixpath.normpath(os.path.realpath(absolute).replace("\\", "/"))
    if resolved != real_root and not resolved.startswith(real_root + "/"):
        # Outside the repo entirely (or a symlink escaping it) — not this
        # gate's concern; the repo-scope question belongs to another gate.
        allow()
    target_rel = resolved[len(real_root) + 1:]
    target_kind = "write_tool"
elif tool == "Bash":
    command = tool_input.get("command")
    if not isinstance(command, str) or not command.strip():
        deny("Bash call has no usable command string.")
    m = BASH_TARGET_RE.search(command)
    if m:
        cand = m.group(1).strip("'\"")
        norm = cand.replace("\\", "/")
        absolute = posixpath.normpath(norm if posixpath.isabs(norm) else posixpath.join(root, norm))
        real_root = posixpath.normpath(os.path.realpath(root).replace("\\", "/"))
        resolved = posixpath.normpath(os.path.realpath(absolute).replace("\\", "/"))
        if resolved == real_root or resolved.startswith(real_root + "/"):
            target_rel = resolved[len(real_root) + 1:]
            target_kind = "bash"
    if target_rel is None:
        # No redirection/tee/in-place-edit target detected against a path
        # inside the repo — this Bash call is not writing a file we can
        # identify, so it is outside this gate's concern.
        allow()
else:
    # Unknown tool this hook was not registered for defensively; nothing to
    # evaluate.
    allow()

# Only docs/proposals/*.md files carry product-cycle state.
parts = target_rel.split("/")
if len(parts) != 3 or parts[0] != "docs" or parts[1] != "proposals" or not parts[2].endswith(".md") or parts[2] == "README.md":
    allow()

abs_path = os.path.join(root, target_rel)
old_text = ""
if os.path.exists(abs_path):
    try:
        with open(abs_path, encoding="utf-8-sig") as fh:
            old_text = fh.read(1 << 20)
    except OSError:
        deny("cannot read the current contents of %s to evaluate the transition." % target_rel)

old = parse(old_text)

if target_kind == "bash":
    # A Bash-driven write to a state file's content cannot be computed by
    # this hook without executing the command — and this gate never
    # verifies-after-the-fact. If the file is anywhere in a state the
    # rules below govern, refuse outright; edits to the carrying file must
    # go through Write/Edit so the resulting content can be checked before
    # it lands.
    if old["status"] in ("hypothesis-registered", "measuring"):
        deny(
            "%s is in status `%s`; edits to it while gated must be made with the Write or Edit "
            "tool (not a shell redirect/tee/in-place edit) so this gate can verify the resulting "
            "content before it lands." % (target_rel, old["status"])
        )
    allow()

# target_kind == "write_tool": compute the resulting content.
if tool == "NotebookEdit":
    # Not a markdown frontmatter file in any real use of this repo; nothing
    # to parse reliably. Refuse rather than silently accept an unverifiable
    # change to what is nominally a state file path.
    deny("%s is a NotebookEdit target under docs/proposals/; this gate cannot verify notebook cell edits against frontmatter, so it refuses." % target_rel)

if tool == "Write":
    new_text = tool_input.get("content")
    if not isinstance(new_text, str):
        deny("Write call on %s has no string content." % target_rel)
elif tool == "Edit":
    old_string = tool_input.get("old_string")
    new_string = tool_input.get("new_string")
    if not isinstance(old_string, str) or not isinstance(new_string, str):
        deny("Edit call on %s is missing old_string/new_string." % target_rel)
    if old_string == "":
        # A brand-new file created via an empty old_string; treat new_string as the file.
        new_text = new_string
    else:
        if old_string not in old_text:
            deny("Edit call's old_string was not found verbatim in %s; refusing rather than guessing the resulting content." % target_rel)
        replace_all = tool_input.get("replace_all") is True
        if replace_all:
            new_text = old_text.replace(old_string, new_string)
        else:
            new_text = old_text.replace(old_string, new_string, 1)
else:
    deny("unrecognized tool %s targeting a state file." % tool)

new = parse(new_text)

# --- Rule: threshold is frozen once status is measuring -----------------
if old["status"] == "measuring" and new["threshold"] != old["threshold"]:
    deny(
        "%s has status: measuring; the threshold field is frozen once measurement starts and this "
        "write changes it (`%s` -> `%s`)." % (target_rel, old["threshold"], new["threshold"])
    )

# --- Rule: hypothesis-registered -> measuring is gated -------------------
if old["status"] == "hypothesis-registered" and new["status"] == "measuring":
    missing = [f for f in ("metric", "threshold", "decision_rule") if not new[f]]
    if missing:
        deny(
            "%s: cannot enter status: measuring — missing field(s): %s. The metric, threshold, and "
            "decision rule must all be registered first." % (target_rel, ", ".join(missing))
        )

    token_name = re.sub(r'[^A-Za-z0-9_.-]', '_', os.path.basename(target_rel)) + ".token"
    tokens_dir = os.path.join(root, ".product-cycle", "tokens")
    token_path = os.path.join(tokens_dir, token_name)

    if not os.path.isfile(token_path):
        deny(
            "%s: cannot enter status: measuring — no approval token found at .product-cycle/tokens/%s. "
            "Content is not consent: the metric/threshold/decision_rule fields being filled in does not "
            "by itself authorize this transition. State the approval in your own turn first." % (target_rel, token_name)
        )

    try:
        with open(token_path, encoding="utf-8-sig") as fh:
            token_text = fh.read(1 << 16)
    except OSError:
        deny("%s: the approval token file exists but could not be read." % target_rel)

    tok_file_m = re.search(r'^file:\s*(.*?)\s*$', token_text, re.M)
    tok_trans_m = re.search(r'^transition:\s*(.*?)\s*$', token_text, re.M)
    if not tok_file_m or not tok_trans_m:
        deny("%s: the approval token file is malformed (missing file/transition fields)." % target_rel)

    if tok_file_m.group(1).strip() != target_rel:
        deny(
            "%s: the approval token on disk is bound to a different file (`%s`); it does not "
            "authorize this transition." % (target_rel, tok_file_m.group(1).strip())
        )
    if tok_trans_m.group(1).strip() != "hypothesis-registered -> measuring":
        deny(
            "%s: the approval token on disk is bound to a different transition (`%s`)." % (
                target_rel, tok_trans_m.group(1).strip()
            )
        )

    # Single-use: consume the token so a second write cannot ride on the
    # same approval.
    try:
        os.remove(token_path)
    except OSError:
        pass

allow()
PY
status=$?
exit "$status"
