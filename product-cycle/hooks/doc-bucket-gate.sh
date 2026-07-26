#!/usr/bin/env bash
# Fail-closed trap (must be the FIRST executable statement, above set/source):
# any abnormal termination — a failed source, a set -euo abort, an unbound
# var, a syntax path — exits non-2; PreToolUse treats non-2 as NON-BLOCKING
# (fail-OPEN). Force any exit that is neither 0 (allow) nor 2 (deny) to 2 (DENY).
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "product-cycle: fail-closed — gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit): enforces contract §21's
# bucket half — a write under docs/ must land in one of the six doctrine
# buckets. Replicates coding's doctrine/placement-gate.sh in shape, but is
# FAIL-CLOSED per this proposal (placement-gate.sh is fail-open; this gate is
# modeled on the fail-closed state-gate.sh reference instead).
#
# Peer to state-gate.sh; never edits/replaces it.
#
# Fail-closed on every malformed/missing-input branch: unparseable payload,
# missing tool_input/path, indeterminate project root are all DENY. A
# genuinely-determined write OUTSIDE docs/ (or outside the repo) is allowed —
# that is not this gate's concern, and is a determined outcome, not a
# parse failure.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
# Escape hatch: export DOCTRINE_ALLOW="docs/site,docs/package.json"
set -euo pipefail

deny() { echo "product-cycle: refused — $1" >&2; exit 2; }

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "doc-bucket-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the doc-bucket gate (fail-closed)."

_gate_rc=0
PRODUCT_PAYLOAD="$payload" python3 <<'PY' || _gate_rc=$?
import json, os, posixpath, subprocess, sys

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

BUCKETS = ("decisions", "handbooks", "reports", "specs", "proposals", "_assets")
SKIP_DIRS = ("node_modules", "vendor", "dist", "build", "target", "out",
             "venv", ".venv", "site-packages", "coverage")

raw = os.environ.get("PRODUCT_PAYLOAD", "")
try:
    event = json.loads(raw)
except ValueError:
    deny("the tool-use payload is not valid JSON; the doc-bucket gate cannot judge a write it cannot parse (fail-closed).")
if not isinstance(event, dict):
    deny("the tool-use payload is not a JSON object (fail-closed).")

tool_input = event.get("tool_input")
if not isinstance(tool_input, dict):
    deny("payload has no tool_input object (fail-closed).")

path = tool_input.get("file_path") or tool_input.get("notebook_path")
if not isinstance(path, str) or not path:
    deny("no usable file_path/notebook_path in tool_input (fail-closed).")

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

root = resolve_root(path)
if not root:
    deny("no project root could be determined (CLAUDE_PROJECT_DIR unset/invalid and no git top-level for target or cwd); refusing rather than silently allowing an indeterminate-root write (fail-closed).")

normalized = path.replace("\\", "/")
absolute = posixpath.normpath(normalized if posixpath.isabs(normalized) else posixpath.join(root, normalized))
resolved = posixpath.normpath(os.path.realpath(absolute).replace("\\", "/"))

# Determined-outside-repo -> allow (not this gate's concern).
if resolved != root and not resolved.startswith(root + "/"):
    allow()

relative = resolved[len(root) + 1:]
segments = [s for s in relative.split("/") if s not in ("", ".")]
if not segments:
    allow()

directories, name = segments[:-1], segments[-1]
if "docs" not in directories:
    allow()

for extra in (os.environ.get("DOCTRINE_ALLOW") or "").split(","):
    extra = extra.strip().strip("/")
    if extra and (extra in directories or relative == extra or relative.startswith(extra + "/")):
        allow()

if directories[-1] == "docs" and name == "README.md":
    allow()

scaffolding = None
for i, directory in enumerate(directories):
    if directory == "docs" or "docs" not in directories[:i]:
        continue
    if directory in BUCKETS:
        allow()
    if directory in SKIP_DIRS or directory.startswith("."):
        if os.path.isdir(posixpath.join(root, *directories[:i + 1])):
            allow()
        scaffolding = "/".join(directories[:i + 1])
    break

buckets = ", ".join(b + "/" for b in BUCKETS)
if scaffolding:
    reason = ("`%s` would create `%s`, a new directory under docs/ that is not one of the six "
              "buckets." % (relative, scaffolding))
else:
    reason = ("`%s` is under docs/ but not in one of the six buckets. Images and attachments go "
              "in _assets/." % relative)
deny(
    "%s Per contract §21's bucket rule, every file under docs/ belongs to a bucket: %s. "
    "Only docs/README.md may sit at the top of docs/; DOCTRINE_ALLOW is the escape hatch." % (reason, buckets)
)
PY
if [ "$_gate_rc" -ne 0 ] && [ "$_gate_rc" -ne 2 ]; then
  echo "product-cycle: refused — fail-closed: internal error (gate judge exited $_gate_rc)" >&2
  exit 2
fi
exit "$_gate_rc"
