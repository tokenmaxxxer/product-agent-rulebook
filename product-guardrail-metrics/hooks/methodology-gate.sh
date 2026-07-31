#!/usr/bin/env bash
# PreToolUse gate for product-guardrail-metrics: guardrail non-emptiness at
# registration (phase 1) and guardrail status tracking at measurement time
# (phase 2). Fires on the phase-1 PROPOSAL write
# (docs/issue-<n>/proposals/*product-discovery*.md) and the phase-2 RECORD
# (docs/issue-<n>/reports/product-discovery.md). Fails closed.
set -uo pipefail

if [ "${PRODUCT_GUARDRAIL_METRICS_GATE_OFF:-}" = "1" ]; then
  exit 0
fi

deny() {
  printf '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1" 2>/dev/null || echo '"product-guardrail-metrics: refused"')"
  exit 2
}

trap 'deny "product-guardrail-metrics: refused — gate failed closed on an internal error."' ERR

command -v python3 >/dev/null 2>&1 || deny "product-guardrail-metrics: refused — python3 is not available; failing closed."

payload="$(cat)"
[ -n "$payload" ] || deny "product-guardrail-metrics: refused — empty stdin payload."

# Resolve project root: CLAUDE_PROJECT_DIR (validated) -> git toplevel -> cwd.
root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR:-}" ]; then
  cand="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
  cwd_json="$(printf '%s' "$payload" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get("cwd","") if isinstance(d,dict) else "")
except Exception:
    print("")' 2>/dev/null)"
  if [ -n "$cand" ]; then
    if [ -z "$cwd_json" ] || [ "$cand" = "$cwd_json" ] || [[ "$cwd_json" == "$cand"/* ]]; then
      root="$cand"
    fi
  fi
fi
if [ -z "$root" ]; then
  root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -n "$root" ] || root="$(pwd -P)"

result="$(PGM_PAYLOAD="$payload" PGM_ROOT="$root" python3 <<'PYEOF'
import json, os, re, sys

root = os.environ["PGM_ROOT"]

try:
    payload = json.loads(os.environ.get("PGM_PAYLOAD", ""))
except Exception:
    print("DENY|product-guardrail-metrics: refused — could not parse the tool-call JSON on stdin.")
    sys.exit(0)

if not isinstance(payload, dict):
    print("DENY|product-guardrail-metrics: refused — malformed tool-call payload.")
    sys.exit(0)

tool_name = payload.get("tool_name", "")
tool_input = payload.get("tool_input", None)
if not isinstance(tool_input, dict):
    print("DENY|product-guardrail-metrics: refused — malformed or missing tool_input.")
    sys.exit(0)

file_path = tool_input.get("file_path", "")
if not file_path:
    print("ALLOW")
    sys.exit(0)

abs_path = file_path if os.path.isabs(file_path) else os.path.join(root, file_path)
try:
    rel_path = os.path.relpath(abs_path, root)
except Exception:
    rel_path = file_path
rel_path = rel_path.replace(os.sep, "/")

proposal_re = re.compile(r'^docs/issue-(\d+)/proposals/[^/]*product-discovery[^/]*\.md$')
record_re = re.compile(r'^docs/issue-(\d+)/reports/product-discovery\.md$')

m_proposal = proposal_re.match(rel_path)
m_record = record_re.match(rel_path)

if not m_proposal and not m_record:
    print("ALLOW")
    sys.exit(0)

def read_current(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return None

resulting_text = None
if tool_name == "Write":
    content = tool_input.get("content", None)
    if isinstance(content, str):
        resulting_text = content
elif tool_name == "Edit":
    old_string = tool_input.get("old_string", None)
    new_string = tool_input.get("new_string", None)
    replace_all = tool_input.get("replace_all", False)
    current = read_current(abs_path)
    if current is None:
        if old_string == "":
            current = ""
        else:
            current = None
    if current is not None and isinstance(old_string, str) and isinstance(new_string, str):
        if old_string == "":
            resulting_text = current + new_string
        elif old_string in current:
            if replace_all:
                resulting_text = current.replace(old_string, new_string)
            else:
                resulting_text = current.replace(old_string, new_string, 1)
elif tool_name == "MultiEdit":
    edits = tool_input.get("edits", None)
    current = read_current(abs_path)
    if current is None:
        current = ""
    if isinstance(edits, list):
        ok = True
        text = current
        for e in edits:
            if not isinstance(e, dict):
                ok = False
                break
            old_string = e.get("old_string", None)
            new_string = e.get("new_string", None)
            replace_all = e.get("replace_all", False)
            if not isinstance(old_string, str) or not isinstance(new_string, str):
                ok = False
                break
            if old_string == "":
                text = text + new_string
            elif old_string in text:
                if replace_all:
                    text = text.replace(old_string, new_string)
                else:
                    text = text.replace(old_string, new_string, 1)
            else:
                ok = False
                break
        if ok:
            resulting_text = text

if resulting_text is None:
    print(
        "DENY|product-guardrail-metrics: refused — this write targets %s but the "
        "gate cannot determine the resulting content from the tool input "
        "(tool=%r). Write the full document with Write, or use an Edit/MultiEdit "
        "whose old_string matches, so guardrail fields can be checked." % (rel_path, tool_name)
    )
    sys.exit(0)

text = resulting_text

GUARDRAIL_RE = re.compile(r'guardrail|가드레일', re.IGNORECASE)
EMPTY_MARKERS = ("none", "n/a", "na", "없음", "tbd")

def guardrail_present_nonempty(t):
    """A guardrail keyword exists, and at least one occurrence's phrase/line
    does not reduce to an emptiness marker immediately after the keyword."""
    for m in GUARDRAIL_RE.finditer(t):
        end = m.end()
        end_candidates = [t.find(c, end) for c in [".", "\n"] if t.find(c, end) != -1]
        stop = min(end_candidates) if end_candidates else len(t)
        after = t[end:stop]
        # Strip leading connective words/punctuation to reach the first
        # substantive token after the keyword.
        after_norm = re.sub(r'^[\s:\-–—]*(metrics|metric|are|is)?[\s:\-–—]*', '', after, flags=re.IGNORECASE)
        after_norm = after_norm.strip().lower()
        first_word = re.split(r'[\s,.;]+', after_norm, maxsplit=1)[0] if after_norm else ""
        if first_word in EMPTY_MARKERS:
            continue
        return True
    return False

if m_proposal:
    issue_no = m_proposal.group(1)
    current_state = os.path.join(root, "docs", "issue-%s" % issue_no, "reports", "product-discovery", "current-state.md")
    if not os.path.isfile(current_state):
        print("DENY|product-guardrail-metrics: refused — proposal write precedes its own current-state survey")
        sys.exit(0)

    if not guardrail_present_nonempty(text):
        print(
            "DENY|product-guardrail-metrics: refused — guardrail metric(s) missing or "
            "empty at proposal time; per docs/issue-36/..., guardrails must be named "
            "non-empty at registration."
        )
        sys.exit(0)

    print("ALLOW")
    sys.exit(0)

if m_record:
    STATUS_RE = re.compile(
        r'\b(not breached|breached|unbreached|held)\b|위반|정상', re.IGNORECASE
    )

    status_ok = False
    if GUARDRAIL_RE.search(text):
        # Paragraph = block separated by blank lines.
        paragraphs = re.split(r'\n\s*\n', text)
        for para in paragraphs:
            if GUARDRAIL_RE.search(para) and STATUS_RE.search(para):
                status_ok = True
                break
    else:
        status_ok = False

    if not status_ok:
        print(
            "DENY|product-guardrail-metrics: refused — guardrail status not stated "
            "explicitly at measurement time (silence is not \"assumed fine\")."
        )
        sys.exit(0)

    print("ALLOW")
    sys.exit(0)

print("ALLOW")
PYEOF
)"

status="${result%%|*}"
if [ "$status" = "DENY" ]; then
  msg="${result#DENY|}"
  deny "$msg"
fi

exit 0
