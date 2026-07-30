#!/usr/bin/env bash
# Fail-closed trap (must be the FIRST executable statement, above set/source):
# any abnormal termination — a failed source, a set -euo abort, an unbound
# var, a syntax path — exits non-2; PreToolUse treats non-2 as NON-BLOCKING
# (fail-OPEN). Force any exit that is neither 0 (allow) nor 2 (deny) to 2 (DENY).
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "product-cycle: fail-closed — gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit): enforces contract §20
# (per-role record minimum content) on writes to product's OWN record path
# docs/issue-<n>/reports/product.md.
#
# Peer to state-gate.sh: reads the SAME resulting content state-gate.sh
# computes for its transition check, validating §20's minimum sections on
# it. It never edits or replaces state-gate.sh.
#
# Fail-closed on EVERY malformed/missing-input branch: unparseable payload,
# missing tool_input/path, indeterminate project root, unreadable on-disk
# file for an Edit/MultiEdit, or an unresolvable Edit are all DENY, never a
# silent pass. Only a genuinely-determined non-product-record target is
# allowed through (this gate has no claim on it).
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -euo pipefail

deny() { echo "product-cycle: refused — $1" >&2; exit 2; }

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "record-fields-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the record-fields gate (fail-closed)."

_gate_rc=0
PRODUCT_PAYLOAD="$payload" python3 <<'PY' || _gate_rc=$?
import json, os, posixpath, re, subprocess, sys

def deny(msg):
    sys.stderr.write("product-cycle: refused — %s\n" % msg)
    sys.exit(2)

def allow():
    sys.exit(0)

# --- fail-closed-on-internal-error (python layer) --------------------------
# Proposal: docs/proposals/2026-07-26-gates-fail-closed-on-internal-error.md
# Any UNCAUGHT exception in the judge body below (most notably
# os.path.realpath / os.path.* raising ValueError on a null-byte or
# undecodable path) would otherwise let Python exit 1 — and a Claude Code
# PreToolUse hook treats every non-2 exit as NON-blocking (fail-OPEN),
# letting the guarded tool call through. Map any such internal error to
# exit 2 (DENY) instead. This changes ONLY the error path; the explicit
# allow()/deny() (SystemExit) verdict paths are unaffected — SystemExit is
# not routed through sys.excepthook.
def _fail_closed_excepthook(_etype, _evalue, _tb):
    try:
        sys.stderr.write(
            "product-cycle: refused — fail-closed: internal error (%s: %s)\n"
            % (getattr(_etype, "__name__", _etype), _evalue))
    except Exception:
        pass
    os._exit(2)

sys.excepthook = _fail_closed_excepthook

raw = os.environ.get("PRODUCT_PAYLOAD", "")
try:
    event = json.loads(raw)
except ValueError:
    deny("the tool-use payload is not valid JSON; the record-fields gate cannot judge a write it cannot parse (fail-closed).")
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
    deny("no project root could be determined (CLAUDE_PROJECT_DIR unset/invalid and no git top-level for target or cwd); refusing rather than silently allowing an indeterminate-root write (fail-closed).")

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

PRODUCT_RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/product\.md$')
m = PRODUCT_RECORD_RE.match(rel)
if not m:
    allow()

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
        deny("Write call on a product-record has no string content (fail-closed).")
    new_text = content
elif tool == "Edit":
    old_string = tool_input.get("old_string")
    new_string = tool_input.get("new_string")
    if not isinstance(old_string, str) or not isinstance(new_string, str):
        deny("Edit call on a product-record is missing old_string/new_string (fail-closed).")
    disk = read_disk()
    if old_string == "":
        new_text = new_string
    else:
        if disk is None:
            deny("Edit call on a product-record but the on-disk file could not be read to compute the result (fail-closed).")
        if old_string not in disk:
            deny("Edit call's old_string was not found verbatim in the product-record (fail-closed).")
        if tool_input.get("replace_all") is True:
            new_text = disk.replace(old_string, new_string)
        else:
            new_text = disk.replace(old_string, new_string, 1)
elif tool == "MultiEdit":
    edits = tool_input.get("edits")
    if not isinstance(edits, list) or not edits:
        deny("MultiEdit call on a product-record has no usable edits list (fail-closed).")
    disk = read_disk()
    text = disk if disk is not None else ""
    for e in edits:
        if not isinstance(e, dict):
            deny("MultiEdit call on a product-record has a non-object edit entry (fail-closed).")
        os_ = e.get("old_string")
        ns_ = e.get("new_string")
        if not isinstance(os_, str) or not isinstance(ns_, str):
            deny("MultiEdit edit missing old_string/new_string (fail-closed).")
        if os_ == "":
            text = ns_
            continue
        if os_ not in text:
            deny("MultiEdit old_string not found verbatim at the point it is applied (fail-closed).")
        if e.get("replace_all") is True:
            text = text.replace(os_, ns_)
        else:
            text = text.replace(os_, ns_, 1)
    new_text = text
else:
    deny("a product-record must be a plain-markdown Write/Edit/MultiEdit, not %s; this gate cannot verify its §20 content otherwise (fail-closed)." % tool)

def has_section(text, *keywords):
    for line in text.splitlines():
        s = line.strip().lower()
        if not (s.startswith("#") or s.startswith("**") or s.startswith("-")):
            continue
        for kw in keywords:
            if kw in s:
                return True
    return False

def has_field(text, name):
    return re.search(r'(?mi)^\s*%s\s*:\s*\S' % re.escape(name), text) is not None

missing = []
if not has_section(new_text, "what was done", "what i did", "work done", "summary of work"):
    missing.append("a 'what was done' section")
if not has_section(new_text, "why", "rationale", "alternative", "decision"):
    missing.append("a 'why' section (rationale / alternative considered)")
if not (has_field(new_text, "upstream") or has_field(new_text, "hypothesis")
        or has_field(new_text, "governing_hypothesis")):
    missing.append("the upstream basis (an `upstream:`/`hypothesis:` pointer the next reader continues from)")

loop_m = re.search(r'(?mi)^\s*loop_state\s*:\s*([A-Za-z0-9\-]+)', new_text)
if not loop_m:
    missing.append("this record's own current `loop_state:`")
    loop_state = None
else:
    loop_state = loop_m.group(1).strip()

TERMINAL = {"decided", "scope-proposed"}
if loop_state is not None and loop_state not in TERMINAL:
    if not has_section(new_text, "next step", "next-steps", "backlog", "todo"):
        missing.append("a next-steps backlog (loop_state '%s' leaves work open, per §20)" % loop_state)
    if not has_section(new_text, "resolution path", "open finding", "finding resolution", "resolution:"):
        missing.append("an open-finding resolution path (loop_state '%s' leaves work open, per §20)" % loop_state)

if missing:
    deny(
        "product-record %s is missing required section(s): %s. Per contract §20, every "
        "role record must state what was done, why (when a real choice was made), and the "
        "concrete upstream basis plus its own loop_state; open work additionally requires a "
        "next-steps backlog and an open-finding resolution path." % (rel, "; ".join(missing))
    )

allow()
PY
if [ "$_gate_rc" -ne 0 ] && [ "$_gate_rc" -ne 2 ]; then
  echo "product-cycle: refused — fail-closed: internal error (gate judge exited $_gate_rc)" >&2
  exit 2
fi
exit "$_gate_rc"
