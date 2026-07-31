#!/usr/bin/env bash
# product-assumption-mapping gate: evidence-citation format + RICE/ICE
# prioritization, fired only on product-discovery proposal writes.
set -uo pipefail

payload="$(cat)"

[ "${PRODUCT_ASSUMPTION_MAPPING_GATE_OFF:-}" = "1" ] && exit 0

deny() {
  printf '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 2
}

on_err() {
  echo '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"product-assumption-mapping: refused — gate crashed, failing closed."}}'
  exit 2
}
trap on_err ERR

command -v python3 >/dev/null 2>&1 || deny "product-assumption-mapping: refused — python3 not available, failing closed."

[ -n "$payload" ] || deny "product-assumption-mapping: refused — empty stdin payload."

parsed="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    print("__PARSE_ERROR__")
    sys.exit(0)
if not isinstance(data, dict):
    print("__PARSE_ERROR__")
    sys.exit(0)
tool_input = data.get("tool_input")
if not isinstance(tool_input, dict):
    print("__PARSE_ERROR__")
    sys.exit(0)
tool_name = data.get("tool_name", "")
file_path = tool_input.get("file_path", "")
cwd = data.get("cwd", "")
print("__OK__")
print(tool_name)
print(file_path)
print(cwd)
' 2>/dev/null)"

first_line="$(printf '%s\n' "$parsed" | sed -n '1p')"
[ "$first_line" = "__OK__" ] || deny "product-assumption-mapping: refused — malformed or non-dict tool_input."

tool_name="$(printf '%s\n' "$parsed" | sed -n '2p')"
file_path="$(printf '%s\n' "$parsed" | sed -n '3p')"
cwd="$(printf '%s\n' "$parsed" | sed -n '4p')"

# --- resolve project root --------------------------------------------------
_plausible() { [ -n "${1:-}" ] && [ -d "$1" ]; }

root=""
if _plausible "${CLAUDE_PROJECT_DIR:-}"; then
  root="$CLAUDE_PROJECT_DIR"
elif root="$(git -C "${cwd:-.}" rev-parse --show-toplevel 2>/dev/null)"; then
  :
else
  root="${cwd:-$(pwd -P)}"
fi

# --- only this plugin's target surface -------------------------------------
case "$file_path" in
  /*) abs_path="$file_path" ;;
  *) abs_path="$root/$file_path" ;;
esac
rel_path="${abs_path#"$root"/}"

echo "$rel_path" | grep -Eq '^docs/issue-[0-9]+/proposals/.*product-discovery.*\.md$' || exit 0

issue_n="$(printf '%s' "$rel_path" | sed -E 's#^docs/issue-([0-9]+)/proposals/.*#\1#')"

# --- order-constraint precondition (copy-identical across the four plugins)
current_state="$root/docs/issue-$issue_n/reports/product-discovery/current-state.md"
[ -f "$current_state" ] || deny "product-assumption-mapping: refused — proposal write precedes its own current-state survey"

# --- reconstruct resulting text --------------------------------------------
resulting_text="$(python3 -c '
import json, sys

payload = sys.argv[1]
abs_path = sys.argv[2]

try:
    data = json.loads(payload)
except Exception:
    print("__RECON_ERROR__")
    sys.exit(0)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {})

def read_current():
    try:
        with open(abs_path, "r") as f:
            return f.read()
    except Exception:
        return None

if tool_name == "Write":
    content = tool_input.get("content")
    if content is None:
        print("__RECON_ERROR__")
        sys.exit(0)
    print("__RECON_OK__")
    print(content, end="")
    sys.exit(0)

if tool_name == "Edit":
    old_string = tool_input.get("old_string")
    new_string = tool_input.get("new_string")
    if old_string is None or new_string is None:
        print("__RECON_ERROR__")
        sys.exit(0)
    current = read_current()
    if current is None:
        print("__RECON_ERROR__")
        sys.exit(0)
    if old_string not in current:
        print("__RECON_ERROR__")
        sys.exit(0)
    result = current.replace(old_string, new_string, 1)
    print("__RECON_OK__")
    print(result, end="")
    sys.exit(0)

if tool_name == "MultiEdit":
    edits = tool_input.get("edits")
    if not isinstance(edits, list) or not edits:
        print("__RECON_ERROR__")
        sys.exit(0)
    current = read_current()
    if current is None:
        print("__RECON_ERROR__")
        sys.exit(0)
    for e in edits:
        if not isinstance(e, dict):
            print("__RECON_ERROR__")
            sys.exit(0)
        old_string = e.get("old_string")
        new_string = e.get("new_string")
        if old_string is None or new_string is None:
            print("__RECON_ERROR__")
            sys.exit(0)
        if old_string not in current:
            print("__RECON_ERROR__")
            sys.exit(0)
        current = current.replace(old_string, new_string, 1)
    print("__RECON_OK__")
    print(current, end="")
    sys.exit(0)

print("__RECON_ERROR__")
' "$payload" "$abs_path")"

recon_marker="$(printf '%s\n' "$resulting_text" | sed -n '1p')"
[ "$recon_marker" = "__RECON_OK__" ] || deny "product-assumption-mapping: refused — cannot determine resulting content"
body="$(printf '%s\n' "$resulting_text" | tail -n +2)"

# --- facet checks -----------------------------------------------------------
verdict="$(printf '%s' "$body" | python3 -c '
import re, sys

text = sys.stdin.read()

# (a) evidence-citation format ----------------------------------------------
citation_lines = []
for line in text.splitlines():
    if re.search(r"(?i)\b(interview|observation|evidence)\b.{0,40}?\b[0-9]+\b", line):
        citation_lines.append(line)

if citation_lines:
    date_re = re.compile(r"(?:\b(19|20)\d{2}\b|\d{4}-\d{2}(?:-\d{2})?)")
    for line in citation_lines:
        has_date = bool(date_re.search(line))
        # paraphrase: some non-trivial text remains after stripping count/date tokens
        stripped = date_re.sub("", line)
        stripped = re.sub(r"[0-9]+", "", stripped)
        stripped = re.sub(r"[^A-Za-z가-힣]+", " ", stripped).strip()
        has_paraphrase = len(stripped) >= 8
        if not (has_date and has_paraphrase):
            print("DENY_CITATION")
            sys.exit(0)

# (b) RICE / ICE prioritization ---------------------------------------------
candidate_markers = re.findall(r"(?im)^\s*[-*]\s*.*\b(candidate|opportunity)\b", text)
candidate_count = len(set(candidate_markers)) if False else len(candidate_markers)
# also count explicit numbered "N candidates" style mention
explicit = re.search(r"(?i)\b([2-9]|[1-9][0-9]+)\s+(candidates|opportunities)\b", text)
two_plus = candidate_count >= 2 or bool(explicit)

if two_plus:
    reach_unavailable = bool(re.search(r"(?i)reach\s+(data\s+)?unavailable", text))
    has_rice = bool(re.search(r"(?i)\bRICE\b", text)) or bool(
        re.search(r"(?i)reach", text) and re.search(r"(?i)impact", text)
        and re.search(r"(?i)confidence", text) and re.search(r"(?i)effort", text)
    )
    has_ice = bool(re.search(r"(?i)\bICE\b", text))
    flagged_ice = has_ice and reach_unavailable

    if has_rice:
        pass
    elif flagged_ice:
        pass
    elif has_ice and not reach_unavailable:
        print("DENY_UNFLAGGED_ICE")
        sys.exit(0)
    else:
        print("DENY_MISSING_SCORE")
        sys.exit(0)

print("PASS")
')"

case "$verdict" in
  DENY_CITATION)
    deny "product-assumption-mapping: refused — evidence citation missing count/date/paraphrase."
    ;;
  DENY_UNFLAGGED_ICE)
    deny "product-assumption-mapping: refused — unflagged ICE score used where RICE was computable."
    ;;
  DENY_MISSING_SCORE)
    deny "product-assumption-mapping: refused — RICE (or flagged ICE) score missing for compared candidates."
    ;;
esac

exit 0
