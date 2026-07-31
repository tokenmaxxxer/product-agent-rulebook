#!/usr/bin/env bash
# PreToolUse gate for product-hypothesis-testing: pre-registered hypothesis
# discipline. Fires on the phase-1 PROPOSAL write
# (docs/issue-<n>/proposals/*product-discovery*.md) and the phase-2 RECORD
# (docs/issue-<n>/reports/product-discovery.md). Fails closed.
set -uo pipefail

if [ "${PRODUCT_HYPOTHESIS_TESTING_GATE_OFF:-}" = "1" ]; then
  cat >/dev/null 2>&1 || true
  exit 0
fi

deny() {
  printf '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":%s}}\n' \
    "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$1" 2>/dev/null || echo '"product-hypothesis-testing: refused"')"
  exit 2
}

trap 'deny "product-hypothesis-testing: refused — gate failed closed on an internal error."' ERR

command -v python3 >/dev/null 2>&1 || deny "product-hypothesis-testing: refused — python3 is not available; failing closed."

payload="$(cat)"
[ -n "$payload" ] || deny "product-hypothesis-testing: refused — empty stdin payload."

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

pyscript="$(mktemp)"
trap 'rm -f "$pyscript"' EXIT
cat > "$pyscript" <<'PYEOF'
import json, os, re, sys

root = sys.argv[1]

try:
    payload = json.load(sys.stdin)
except Exception:
    print("DENY|product-hypothesis-testing: refused — could not parse the tool-call JSON on stdin.")
    sys.exit(0)

if not isinstance(payload, dict):
    print("DENY|product-hypothesis-testing: refused — malformed tool-call payload.")
    sys.exit(0)

tool_name = payload.get("tool_name", "")
tool_input = payload.get("tool_input", None)
if not isinstance(tool_input, dict):
    print("DENY|product-hypothesis-testing: refused — malformed or missing tool_input.")
    sys.exit(0)

file_path = tool_input.get("file_path", "")
if not file_path:
    print("ALLOW")
    sys.exit(0)

# Resolve absolute path against root for matching relative-to-root regexes.
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

# Reconstruct resulting text for Write / Edit / MultiEdit.
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
        # File may not exist yet; if old_string is empty, treat as create.
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
    print("DENY|product-hypothesis-testing: refused — cannot determine resulting content for this write.")
    sys.exit(0)

text = resulting_text

def has_itwws(t):
    if re.search(r'ITWWS', t, re.IGNORECASE):
        return True
    if re.search(r'if this works we should', t, re.IGNORECASE):
        return True
    if '이게 되면' in t:
        return True
    return False

def has_decision_rule(t):
    if re.search(r'\b(go|kill|pivot)\b', t, re.IGNORECASE):
        return True
    if re.search(r'진행|중단|피벗', t):
        return True
    return False

def has_threshold_digit(t):
    # A digit appearing near a metric/threshold word, or a number followed
    # by % or a comparison word.
    if re.search(r'\d+\s*%', t):
        return True
    if re.search(r'\d+[^\n]{0,40}(threshold|metric|crosses|넘으면|이상|이하)', t, re.IGNORECASE):
        return True
    if re.search(r'(threshold|metric|crosses|넘으면|이상|이하)[^\n]{0,40}\d+', t, re.IGNORECASE):
        return True
    return False

if m_proposal:
    issue_no = m_proposal.group(1)
    current_state = os.path.join(root, "docs", "issue-%s" % issue_no, "reports", "product-discovery", "current-state.md")
    if not os.path.isfile(current_state):
        print("DENY|product-hypothesis-testing: refused — proposal write precedes its own current-state survey")
        sys.exit(0)

    missing = []
    if not has_threshold_digit(text):
        missing.append("threshold-digit")
    if not has_decision_rule(text):
        missing.append("decision-rule")
    if not has_itwws(text):
        missing.append("itwws")

    if missing:
        print("DENY|product-hypothesis-testing: refused — proposal missing required element(s): %s" % ", ".join(missing))
        sys.exit(0)

    print("ALLOW")
    sys.exit(0)

if m_record:
    # Verdict-adjacency: a number and a threshold-word within a 3-line window.
    lines = text.split("\n")
    adjacency_ok = False
    for i in range(len(lines)):
        window = "\n".join(lines[max(0, i - 3):i + 4])
        if re.search(r'\d', window) and re.search(r'(threshold|기준)', window, re.IGNORECASE):
            adjacency_ok = True
            break
    if not adjacency_ok:
        print("DENY|product-hypothesis-testing: refused — record does not state the measured value adjacent to its threshold.")
        sys.exit(0)

    if not has_itwws(text):
        print("DENY|product-hypothesis-testing: refused — ITWWS follow-up is missing, or deferred with no stated reason.")
        sys.exit(0)

    actioned = re.search(r'actioned|진행함', text, re.IGNORECASE)
    deferred_ok = False
    for m in re.finditer(r'deferred', text, re.IGNORECASE):
        # Look at the sentence/line containing "deferred".
        start = text.rfind("\n", 0, m.start()) + 1
        end_candidates = [text.find(c, m.end()) for c in [".", "\n"] if text.find(c, m.end()) != -1]
        end = min(end_candidates) if end_candidates else len(text)
        sentence = text[start:end]
        remainder = sentence.lower().replace("deferred", "", 1).strip(" -—:,")
        if len(remainder) > 8:
            deferred_ok = True
            break

    if not actioned and not deferred_ok:
        print("DENY|product-hypothesis-testing: refused — ITWWS follow-up is missing, or deferred with no stated reason.")
        sys.exit(0)

    print("ALLOW")
    sys.exit(0)

print("ALLOW")
PYEOF

result="$(printf '%s' "$payload" | python3 "$pyscript" "$root")"
rm -f "$pyscript"
trap - EXIT

status="${result%%|*}"
if [ "$status" = "DENY" ]; then
  msg="${result#DENY|}"
  deny "$msg"
fi

exit 0
