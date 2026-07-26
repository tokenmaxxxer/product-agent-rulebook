#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit): enforces contract §19's front-record
# side. A write that moves product's front record
# docs/reports/records/<subject>/product.md into loop_state: scope-approved is
# refused unless an UNCONSUMED human-placed approval token exists for that
# subject — mirroring qa-cycle's capture-verdict.sh human-token mechanism (a
# token minted only from the human's own in-conversation turn). The gate never
# PERFORMS the approval: no token, no transition. On a legal transition the
# token is consumed (deleted) so it cannot be replayed.
#
# Peer to state-gate.sh; never edits/replaces it. state-gate.sh checks the
# scope-proposed -> scope-approved row is legal in principle (actor: user);
# this gate checks a human actually signaled it this conversation.
#
# Fail-closed on every malformed/missing-input branch: unparseable payload,
# missing tool_input/path, indeterminate project root, unreadable on-disk file
# for an Edit, or an unresolvable Edit are all DENY.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -euo pipefail

deny() { echo "product-cycle: refused — $1" >&2; exit 2; }

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "scope-record-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the scope-record gate (fail-closed)."

PRODUCT_PAYLOAD="$payload" python3 <<'PY'
import json, os, posixpath, re, subprocess, sys

def deny(msg):
    sys.stderr.write("product-cycle: refused — %s\n" % msg)
    sys.exit(2)

def allow():
    sys.exit(0)

raw = os.environ.get("PRODUCT_PAYLOAD", "")
try:
    event = json.loads(raw)
except ValueError:
    deny("the tool-use payload is not valid JSON; the scope-record gate cannot judge a write it cannot parse (fail-closed).")
if not isinstance(event, dict):
    deny("the tool-use payload is not a JSON object (fail-closed).")

tool = event.get("tool_name")
tool_input = event.get("tool_input")
if not isinstance(tool, str) or not tool:
    deny("payload has no tool_name (fail-closed).")
if not isinstance(tool_input, dict):
    deny("payload has no tool_input object (fail-closed).")

target = tool_input.get("file_path") or tool_input.get("notebook_path")
if not isinstance(target, str) or not target:
    deny("tool call has no usable file_path/notebook_path (fail-closed).")

def git_top(path):
    try:
        d = path if os.path.isdir(path) else (os.path.dirname(path) or ".")
        out = subprocess.run(["git", "-C", d, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True)
        if out.returncode == 0:
            t = out.stdout.strip()
            if t:
                return posixpath.normpath(os.path.realpath(t).replace("\\", "/"))
    except Exception:
        return None
    return None

def plausible(r):
    return bool(r) and os.path.isdir(r) and (
        os.path.exists(os.path.join(r, ".git"))
        or os.path.isfile(os.path.join(r, "docs", "specs", "role-handoff-contract.md")))

def resolve_root(tgt):
    cpd = os.environ.get("CLAUDE_PROJECT_DIR")
    if cpd and plausible(cpd):
        rr = posixpath.normpath(os.path.realpath(cpd).replace("\\", "/"))
        t = tgt if posixpath.isabs(tgt) else posixpath.join(rr, tgt)
        t = posixpath.normpath(os.path.realpath(t).replace("\\", "/"))
        if t == rr or t.startswith(rr + "/"):
            return rr
    abs_tgt = tgt if posixpath.isabs(tgt) else posixpath.join(os.getcwd(), tgt)
    g = git_top(abs_tgt)
    if g:
        return g
    g = git_top(os.getcwd())
    if g:
        return g
    return None

root = resolve_root(target)
if not root:
    deny("no project root could be determined (fail-closed).")

def repo_rel(tgt):
    norm = tgt.replace("\\", "/")
    absu = posixpath.normpath(norm if posixpath.isabs(norm) else posixpath.join(root, norm))
    resolved = posixpath.normpath(os.path.realpath(absu).replace("\\", "/"))
    if resolved == root or not resolved.startswith(root + "/"):
        return None
    return resolved[len(root) + 1:]

rel = repo_rel(target)
if rel is None:
    allow()

m = re.match(r'^docs/reports/records/([^/]+)/product\.md$', rel)
if not m:
    allow()
subject = m.group(1)

abs_path = posixpath.join(root, rel)

def read_disk():
    try:
        with open(abs_path, encoding="utf-8-sig") as fh:
            return fh.read(1 << 20)
    except OSError:
        return None

if tool == "Write":
    content = tool_input.get("content")
    if not isinstance(content, str):
        deny("Write call on the front record has no string content (fail-closed).")
    new_text = content
elif tool == "Edit":
    old_string = tool_input.get("old_string")
    new_string = tool_input.get("new_string")
    if not isinstance(old_string, str) or not isinstance(new_string, str):
        deny("Edit call on the front record is missing old_string/new_string (fail-closed).")
    disk = read_disk()
    if old_string == "":
        new_text = new_string
    else:
        if disk is None:
            deny("Edit call on the front record but the on-disk file could not be read (fail-closed).")
        if old_string not in disk:
            deny("Edit call's old_string was not found verbatim in the front record (fail-closed).")
        new_text = disk.replace(old_string, new_string,
                                (10**9 if tool_input.get("replace_all") is True else 1))
elif tool == "MultiEdit":
    edits = tool_input.get("edits")
    if not isinstance(edits, list) or not edits:
        deny("MultiEdit call on the front record has no usable edits list (fail-closed).")
    disk = read_disk()
    text = disk if disk is not None else ""
    for e in edits:
        if not isinstance(e, dict):
            deny("MultiEdit call has a non-object edit entry (fail-closed).")
        o_ = e.get("old_string"); n_ = e.get("new_string")
        if not isinstance(o_, str) or not isinstance(n_, str):
            deny("MultiEdit edit missing old_string/new_string (fail-closed).")
        if o_ == "":
            text = n_; continue
        if o_ not in text:
            deny("MultiEdit old_string not found verbatim at the point it is applied (fail-closed).")
        text = text.replace(o_, n_, (10**9 if e.get("replace_all") is True else 1))
    new_text = text
else:
    allow()  # NotebookEdit etc. on a record path — not a scope-transition write

def loop_state_of(text):
    mm = re.search(r'(?mi)^\s*loop_state\s*:\s*([A-Za-z0-9\-]+)', text or "")
    return mm.group(1).strip() if mm else None

new_state = loop_state_of(new_text)
if new_state != "scope-approved":
    allow()  # this write does not set scope-approved — not this gate's concern

old_state = loop_state_of(read_disk())
if old_state == "scope-approved":
    allow()  # already approved; idempotent rewrite, no new human signal needed

# --- this write PERFORMS the entry into scope-approved: require a token ---
# subject allow-list before it is ever used in a path.
if not re.match(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$', subject):
    deny("the front record's subject id %r is not a safe token; refusing to resolve an approval "
         "token path from it (fail-closed)." % subject)

tokens_dir = posixpath.join(root, "docs", "reports", "records", subject, "tokens")
token_file = posixpath.join(tokens_dir, subject + ".scope-approved.token")

def token_valid(path):
    if not os.path.isfile(path):
        return False
    try:
        with open(path, encoding="utf-8-sig") as fh:
            body = fh.read(1 << 16)
    except OSError:
        return False
    # Must bind to THIS subject and THIS transition, human-placed.
    if not re.search(r'(?mi)^\s*subject:\s*' + re.escape(subject) + r'\s*$', body):
        return False
    if not re.search(r'(?mi)^\s*transition:\s*scope-proposed\s*->\s*scope-approved\s*$', body):
        return False
    return True

if not token_valid(token_file):
    deny(
        "scope-proposed -> scope-approved for subject '%s' requires a human-placed approval "
        "token (an unconsumed %s bound to this subject and transition), and none was found. "
        "This state may not be set unilaterally, per contract §19 — the human moves it from "
        "scope-proposed to scope-approved via the WAKES-ON approval edge. See scope-approval-token.sh "
        "(modeled on qa-cycle's capture-verdict.sh) for how the human signal is captured." % (
            subject, posixpath.relpath(token_file, root))
    )

# Consume the single-use token so the human signal cannot be replayed.
try:
    os.remove(token_file)
except OSError:
    deny("the approval token for subject '%s' could not be consumed (removed); refusing rather "
         "than leaving a replayable token in place (fail-closed)." % subject)

allow()
PY
