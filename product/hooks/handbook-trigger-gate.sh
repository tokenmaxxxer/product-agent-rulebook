#!/usr/bin/env bash
# Fail-closed trap (must be the FIRST executable statement, above set/source):
# any abnormal termination — a failed source, a set -euo abort, an unbound
# var, a syntax path — exits non-2; PreToolUse treats non-2 as NON-BLOCKING
# (fail-OPEN). Force any exit that is neither 0 (allow) nor 2 (deny) to 2 (DENY).
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "product-cycle: fail-closed — gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse hook (Bash matching 'git commit'): enforces contract §21's
# handbook half. When a commit's changed-file set touches an operational
# surface (env-example, dependency manifest, Dockerfile, migration dir,
# CI/deploy workflow, run/setup/deploy script) but does NOT also touch a
# docs/handbooks/<component>.md, the commit is refused.
#
# Needs the whole staged changed-file set, so it fires at commit time, not on
# a single Write. Peer to state-gate.sh; never edits/replaces it.
#
# Fail-closed on every malformed/missing-input branch: unparseable payload,
# no command, indeterminate root, or a failed `git diff --cached` are all
# DENY. A commit that is not a git-commit invocation is allowed (not our
# concern); a commit touching no operational surface is allowed.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -euo pipefail

deny() { echo "product-cycle: refused — $1" >&2; exit 2; }

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "handbook-trigger-gate.sh requires python3, which is not on PATH; denying rather than guessing."
command -v git >/dev/null 2>&1 || deny "handbook-trigger-gate.sh requires git, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the handbook-trigger gate (fail-closed)."

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
    deny("the tool-use payload is not valid JSON; the handbook-trigger gate cannot judge a commit it cannot parse (fail-closed).")
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

# Only concern ourselves with git-commit invocations.
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

OP_SURFACE = [
    (re.compile(r'(^|/)package\.json$'), "dependency manifest (package.json)"),
    (re.compile(r'(^|/)pyproject\.toml$'), "dependency manifest (pyproject.toml)"),
    (re.compile(r'(^|/)requirements[^/]*\.txt$'), "dependency manifest (requirements.txt)"),
    (re.compile(r'(^|/)Gemfile$'), "dependency manifest (Gemfile)"),
    (re.compile(r'(^|/)go\.mod$'), "dependency manifest (go.mod)"),
    (re.compile(r'(^|/)Cargo\.toml$'), "dependency manifest (Cargo.toml)"),
    (re.compile(r'(^|/)Dockerfile$'), "container build (Dockerfile)"),
    (re.compile(r'(^|/)docker-compose[^/]*\.ya?ml$'), "container orchestration (docker-compose)"),
    (re.compile(r'\.env(\.example|\.sample|\.template)?$'), "environment variable surface (.env)"),
    (re.compile(r'(^|/)migrations?/'), "database migration"),
    (re.compile(r'(^|/)\.github/workflows/'), "CI/deploy workflow"),
    (re.compile(r'(^|/)(deploy|setup|install|run)[^/]*\.sh$'), "run/setup/deploy script"),
]

hits = []
for f in changed:
    for rx, label in OP_SURFACE:
        if rx.search(f):
            hits.append((f, label))
            break

if not hits:
    allow()

touches_handbook = any(f.replace("\\", "/").startswith("docs/handbooks/") and f.endswith(".md")
                       for f in changed)
if touches_handbook:
    allow()

first_path, first_kind = hits[0]
deny(
    "this commit changes %s (operational surface: %s) but does not touch any "
    "docs/handbooks/<component>.md. Per contract §21, the component's handbook must be "
    "created or updated in the same unit of work (same-turn-sync)." % (first_path, first_kind)
)
PY
if [ "$_gate_rc" -ne 0 ] && [ "$_gate_rc" -ne 2 ]; then
  echo "product-cycle: refused — fail-closed: internal error (gate judge exited $_gate_rc)" >&2
  exit 2
fi
exit "$_gate_rc"
