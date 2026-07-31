#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — the opportunity-solution-tree
# (OST) facet of the product-discovery methodology set, on top of (never
# instead of) core canon's generic record-fields-gate.sh.
#
# This plugin fires on two of its own surfaces:
#   (a) survey  — docs/issue-<n>/reports/product-discovery/current-state.md
#                 must name the relevant OST branch in OST's own
#                 four-layer vocabulary (outcome / opportunity / candidate
#                 solutions / discriminating assumption test).
#   (c) record  — docs/issue-<n>/reports/product-discovery.md must state
#                 a disposition (pruned/promoted) in that same vocabulary.
#
# It additionally owns the cross-plugin order-constraint check on its own
# proposal half:
#   (b) proposal — docs/issue-<n>/proposals/*product-discovery*.md must
#                 not be written before the current-state survey exists
#                 on disk. This is the only check this plugin runs on the
#                 proposal surface — no OST-vocabulary check applies
#                 there; that is this plugin's own facet only on (a)/(c).
#
# Kill switch: export PRODUCT_OPPORTUNITY_SOLUTION_TREE_GATE_OFF=1
set -uo pipefail

role="${CLAUDE_ROLE:-product-opportunity-solution-tree}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

case "${PRODUCT_OPPORTUNITY_SOLUTION_TREE_GATE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "methodology-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "methodology-gate: empty tool-use payload on stdin; cannot evaluate the methodology gate."

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    for k in ("file_path","notebook_path"):
        v=ti.get(k)
        if isinstance(v,str) and v: print(v); break
' 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
_under() {
  [ -z "$2" ] && return 0
  python3 -c '
import os,posixpath,sys
r,t=sys.argv[1],sys.argv[2]
try: rr=posixpath.normpath(os.path.realpath(r).replace("\\","/"))
except Exception: sys.exit(1)
n=t.replace("\\","/"); a=n if posixpath.isabs(n) else posixpath.join(rr,n)
a=posixpath.normpath(a); real=posixpath.normpath(os.path.realpath(a).replace("\\","/"))
sys.exit(0 if (real==rr or real.startswith(rr+"/")) else 1)
' "$1" "$2"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR" && _under "$CLAUDE_PROJECT_DIR" "$_target"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (methodology check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("product-opportunity-solution-tree: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge methodology fields on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on methodology.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (methodology).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    SURVEY_RE = re.compile(r'^docs/issue-[0-9]+/reports/product-discovery/current-state\.md$')
    PROPOSAL_RE = re.compile(r'^docs/issue-[0-9]+/proposals/.*product-discovery.*\.md$', re.I)
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/product-discovery\.md$')

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if not r.startswith(root + "/"):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")

    is_survey = bool(SURVEY_RE.match(rel))
    is_proposal = bool(PROPOSAL_RE.match(rel))
    is_record = bool(RECORD_RE.match(rel))

    if not (is_survey or is_proposal or is_record):
        sys.exit(0)  # not an OST methodology write surface — not this gate's business

    # --- proposal path: order-constraint only, no vocabulary check here ---
    if is_proposal:
        # rel like docs/issue-<n>/proposals/...: extract issue segment robustly
        parts = rel.split("/")
        issue_seg = parts[1] if len(parts) > 1 else None
        survey_abs = posixpath.join(root, "docs", issue_seg, "reports", "product-discovery", "current-state.md") if issue_seg else None
        if not survey_abs or not os.path.isfile(survey_abs):
            deny(
                "proposal write precedes its own current-state survey "
                "(missing docs/%s/reports/product-discovery/current-state.md). "
                "Per docs/issue-36/..., the current-state survey must exist before "
                "any product-discovery proposal is written." % (issue_seg or "issue-<n>")
            )
        sys.exit(0)  # order gate satisfied; this plugin has no other proposal obligation

    # --- survey/record paths: reconstruct resulting content ---
    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on methodology." % rel)

    new_text = None
    if tool == "Write":
        c = ti.get("content")
        if isinstance(c, str):
            new_text = c
    elif tool == "Edit":
        o, n = ti.get("old_string"), ti.get("new_string")
        if isinstance(o, str) and isinstance(n, str) and current is not None and o in current:
            new_text = current.replace(o, n, 1)
    elif tool == "MultiEdit":
        edits = ti.get("edits")
        text = current
        if isinstance(edits, list) and text is not None:
            ok = True
            for e in edits:
                if not isinstance(e, dict):
                    ok = False; break
                o, n = e.get("old_string"), e.get("new_string")
                if not isinstance(o, str) or not isinstance(n, str) or o not in text:
                    ok = False; break
                text = text.replace(o, n, 1)
            if ok:
                new_text = text

    if new_text is None:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the methodology fields can be "
            "checked." % (rel, tool)
        )

    low = new_text.lower()

    def has_any(*needles):
        return any(nd in low for nd in needles)

    OST_LAYER_TERMS = ("outcome", "opportunity", "candidate solution", "discriminating assumption test")

    if is_survey:
        ost_context = has_any("ost", "opportunity-solution tree")
        layer_named = has_any(*OST_LAYER_TERMS)
        labeled_branch = bool(re.search(
            r'(outcome|opportunity|candidate solution|discriminating assumption test)\s*:', low
        ))
        if not (layer_named and (ost_context or labeled_branch)):
            deny(
                "OST branch vocabulary missing. Per docs/issue-36/..., the current-state "
                "survey must name the relevant branch (outcome/opportunity/candidate "
                "solutions/discriminating assumption test) in OST's own vocabulary."
            )
        sys.exit(0)

    if is_record:
        layer_named = has_any(*OST_LAYER_TERMS)
        verdict_named = has_any("pruned", "promoted", "kill", "go", "pivot")
        if not (layer_named and verdict_named):
            deny(
                "record is missing an OST branch disposition (pruned/promoted, in OST "
                "vocabulary)."
            )
        sys.exit(0)

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("methodology-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "product-opportunity-solution-tree: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
