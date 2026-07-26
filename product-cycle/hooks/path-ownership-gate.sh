#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit): enforces contract §11
# path-ownership. Generalizes warrant/scope-gate.sh's write-set shape to the
# STATIC, role-permanent §11 owned-path table: a write whose resolved target
# falls in another role's exclusive space is refused-and-reported rather than
# overwritten or merged. Product's own owned paths, §21-grant paths it may
# author, and the component-scoped handbook shared-write are allowed.
#
# Peer to state-gate.sh; never edits/replaces it. Fires on the same content
# matcher; only the target PATH matters here, so no content is computed.
#
# Fail-closed on every malformed/missing-input branch: unparseable payload,
# missing tool_input/path, indeterminate project root are all DENY.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -euo pipefail

deny() { echo "product-cycle: refused — $1" >&2; exit 2; }

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "path-ownership-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the path-ownership gate (fail-closed)."

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
    deny("the tool-use payload is not valid JSON; the path-ownership gate cannot judge a write it cannot parse (fail-closed).")
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

# --- §11 ownership classification -------------------------------------
# Roles whose record space is exclusively theirs (product is NOT foreign).
FOREIGN_ROLES = ("coding", "qa", "feasibility", "ux-design", "review", "ops", "verify", "reflect")

# A build-proposal is coding's (disambiguated by the -build- tag).
if re.match(r'^docs/proposals/\d{4}-\d{2}-\d{2}-build-[A-Za-z0-9][A-Za-z0-9\-]*\.md$', rel):
    deny(
        "path ownership conflict — %s is coding's `build-proposal` slot (the -build- filename tag) "
        "per contract §11, not product's. Report the conflict; do not overwrite or merge into "
        "another role's proposal." % rel
    )

# Records tree: docs/reports/records/<subject>/<rest>
m = re.match(r'^docs/reports/records/([^/]+)/(.+)$', rel)
if m:
    subject, rest = m.group(1), m.group(2)
    # product's own record is the only thing product owns in a subject dir.
    if rest == "product.md":
        allow()
    # Any other role's record file or their sub-trees are foreign.
    owner = None
    top = rest.split("/")[0]
    if rest in [r + ".md" for r in FOREIGN_ROLES]:
        owner = top[:-3] if top.endswith(".md") else top
    elif top in ("qa", "spikes", "postmortems"):
        owner = {"qa": "qa", "spikes": "feasibility", "postmortems": "ops"}[top]
    else:
        # Unknown structure inside another subject's record tree: fail-closed,
        # product does not own it, refuse rather than assume it is product's.
        owner = "another role"
    deny(
        "path ownership conflict — %s falls in role '%s''s exclusive record space per "
        "contract §11, not product's. product refuses to write there rather than overwriting "
        "or merging into it silently; report this conflict to the user." % (rel, owner)
    )

# Everything else (product's own owned paths, §21-grant files product authors,
# handbooks shared-write, and non-doc source paths) is not a §11 foreign write.
allow()
PY
