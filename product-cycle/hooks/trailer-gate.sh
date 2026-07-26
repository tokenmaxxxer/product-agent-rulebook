#!/usr/bin/env bash
# PreToolUse hook (Bash matching 'git commit'): enforces contract §13's
# commit-trailer requirement for product. When a commit stages a product
# in-progress unit (product's own record docs/reports/records/<subject>/product.md
# or a product hypothesis docs/proposals/<date>-<slug>.md), the commit message
# must carry product-cycle's declared machine-checkable trailer identifying
# subject and kind: a `Subject:` line AND a `Kind:` line.
#
# Needs the staged changed-file set + the commit message, so it fires at
# commit time. Peer to state-gate.sh; never edits/replaces it.
#
# Fail-closed on every malformed/missing-input branch: unparseable payload,
# no command, indeterminate root, a failed git diff, or a commit that stages a
# product unit but supplies no inspectable message (interactive editor / -F
# file that cannot be read) are all DENY. A non-git-commit Bash call, or a
# commit that stages no product unit, is allowed.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -euo pipefail

deny() { echo "product-cycle: refused — $1" >&2; exit 2; }

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "trailer-gate.sh requires python3, which is not on PATH; denying rather than guessing."
command -v git >/dev/null 2>&1 || deny "trailer-gate.sh requires git, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the trailer gate (fail-closed)."

_gate_rc=0
PRODUCT_PAYLOAD="$payload" python3 <<'PY' || _gate_rc=$?
import json, os, posixpath, re, shlex, subprocess, sys

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
    deny("the tool-use payload is not valid JSON; the trailer gate cannot judge a commit it cannot parse (fail-closed).")
if not isinstance(event, dict):
    deny("the tool-use payload is not a JSON object (fail-closed).")

tool = event.get("tool_name")
tool_input = event.get("tool_input")
if tool != "Bash":
    allow()
if not isinstance(tool_input, dict):
    deny("Bash payload has no tool_input object (fail-closed).")
command = tool_input.get("command")
if not isinstance(command, str) or not command.strip():
    deny("Bash call has no usable command string (fail-closed).")

if not re.search(r'(?:^|[\s;&|(])git\b[^\n;&|]*\bcommit\b', command):
    allow()

def git_top(p):
    try:
        d = p if os.path.isdir(p) else (os.path.dirname(p) or ".")
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

cpd = os.environ.get("CLAUDE_PROJECT_DIR")
root = None
if cpd and plausible(cpd):
    root = posixpath.normpath(os.path.realpath(cpd).replace("\\", "/"))
if root is None:
    root = git_top(os.getcwd())
if not root:
    deny("no project root could be determined for the commit (fail-closed).")

try:
    out = subprocess.run(["git", "-C", root, "diff", "--cached", "--name-only"],
                         capture_output=True, text=True)
except Exception:
    deny("could not run `git diff --cached` to read the staged changed-file set (fail-closed).")
if out.returncode != 0:
    deny("`git diff --cached --name-only` failed; cannot read the staged changed-file set (fail-closed).")

changed = [ln.strip() for ln in out.stdout.splitlines() if ln.strip()]

PRODUCT_RECORD_RE = re.compile(r'^docs/reports/records/[^/]+/product\.md$')
HYPOTHESIS_RE = re.compile(r'^docs/proposals/\d{4}-\d{2}-\d{2}-(?!build-)[A-Za-z0-9][A-Za-z0-9\-]*\.md$')

stages_product_unit = any(
    PRODUCT_RECORD_RE.match(f.replace("\\", "/")) or HYPOTHESIS_RE.match(f.replace("\\", "/"))
    for f in changed
)
if not stages_product_unit:
    allow()  # no product in-progress unit in this commit — §13 trailer not required here

# --- extract the commit message ---------------------------------------
try:
    tokens = shlex.split(command)
except ValueError:
    deny("the git commit command could not be tokenized to locate its message; refusing rather "
         "than allowing a product-unit commit whose trailer cannot be checked (fail-closed).")

msg_parts = []
have_message_source = False
i = 0
while i < len(tokens):
    t = tokens[i]
    if t in ("-m", "--message"):
        if i + 1 < len(tokens):
            msg_parts.append(tokens[i + 1]); have_message_source = True; i += 2; continue
        i += 1; continue
    if t.startswith("--message="):
        msg_parts.append(t.split("=", 1)[1]); have_message_source = True; i += 1; continue
    if t.startswith("-m") and len(t) > 2:
        msg_parts.append(t[2:]); have_message_source = True; i += 1; continue
    if t in ("-F", "--file"):
        if i + 1 < len(tokens):
            fpath = tokens[i + 1]
            ap = fpath if posixpath.isabs(fpath) else posixpath.join(root, fpath)
            try:
                with open(ap, encoding="utf-8-sig") as fh:
                    msg_parts.append(fh.read()); have_message_source = True
            except OSError:
                deny("commit uses -F/--file for its message but that file could not be read to "
                     "verify the §13 trailer on a product-unit commit (fail-closed).")
            i += 2; continue
        i += 1; continue
    if t.startswith("--file="):
        fpath = t.split("=", 1)[1]
        ap = fpath if posixpath.isabs(fpath) else posixpath.join(root, fpath)
        try:
            with open(ap, encoding="utf-8-sig") as fh:
                msg_parts.append(fh.read()); have_message_source = True
        except OSError:
            deny("commit uses --file= for its message but that file could not be read to verify "
                 "the §13 trailer on a product-unit commit (fail-closed).")
        i += 1; continue
    i += 1

if not have_message_source:
    deny("this commit stages a product in-progress unit but supplies no inspectable commit message "
         "(-m/--message/-F/--file); an interactive-editor message cannot be checked for the §13 "
         "trailer, so it is refused (fail-closed).")

message = "\n".join(msg_parts)
has_subject = re.search(r'(?mi)^\s*Subject:\s*\S', message) is not None
has_kind = re.search(r'(?mi)^\s*Kind:\s*\S', message) is not None

if not (has_subject and has_kind):
    missing = []
    if not has_subject:
        missing.append("`Subject:`")
    if not has_kind:
        missing.append("`Kind:`")
    deny(
        "this commit stages a product in-progress unit but its message lacks product-cycle's "
        "declared §13 trailer key(s): %s. Every commit landing a product record or hypothesis must "
        "carry a machine-checkable `Subject:` and `Kind:` trailer identifying the record it belongs "
        "to." % ", ".join(missing)
    )

allow()
PY
if [ "$_gate_rc" -ne 0 ] && [ "$_gate_rc" -ne 2 ]; then
  echo "product-cycle: refused — fail-closed: internal error (gate judge exited $_gate_rc)" >&2
  exit 2
fi
exit "$_gate_rc"
