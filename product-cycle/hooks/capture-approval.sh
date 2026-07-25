#!/usr/bin/env bash
# UserPromptSubmit hook: mints a single-use approval token from an
# unambiguous approval found in the user's OWN turn — never from a file,
# issue, PR, comment, or tool result.
#
# product-cycle has exactly one gated transition:
#   hypothesis-registered -> measuring
# (docs/specs/state-machine.md). This hook only ever mints a token for
# that one (from, to) pair, bound to the specific specification file the
# approval concerns.
#
# This hook never blocks. Malformed/unreadable input, no project root, no
# candidate specification file, or an ambiguous/absent approval all mean:
# emit nothing, exit 0. Denial is state-gate.sh's job, not this hook's.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -euo pipefail

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || exit 0

root="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -d "$root" ] || exit 0
root="$(cd "$root" 2>/dev/null && pwd -P)" || exit 0

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

# Must be well-formed JSON with a non-empty string prompt field.
echo "$payload" | python3 -c 'import json,sys; json.loads(sys.stdin.read())' >/dev/null 2>&1 || exit 0

PRODUCT_ROOT="$root" PRODUCT_PAYLOAD="$payload" python3 <<'PY'
import json
import os
import re
import sys

root = os.environ["PRODUCT_ROOT"]
try:
    event = json.loads(os.environ.get("PRODUCT_PAYLOAD", ""))
except ValueError:
    sys.exit(0)
if not isinstance(event, dict):
    sys.exit(0)

prompt = event.get("prompt")
if not isinstance(prompt, str) or not prompt.strip():
    sys.exit(0)

# Reject vague assent outright, even if a keyword coincidentally appears.
if re.match(r'^\s*(ok|okay|sure|sounds good|yep|yes|k|👍|fine)\s*[.!]?\s*$', prompt.strip(), re.I):
    sys.exit(0)

# An approval must explicitly reference moving into measurement / approving
# the registered hypothesis package — not a bare "approved" with no object.
APPROVE_RE = re.compile(
    r'\b(approve|approving|approved)\b.{0,80}\b(hypothesis|metric|threshold|decision rule|measur\w*)\b'
    r'|\b(start|begin|move (in)?to|go (ahead )?(with |to )?)\b.{0,40}\bmeasur\w*\b'
    r'|\b(hypothesis|metric|threshold|decision rule)\b.{0,80}\b(approve|approving|approved|looks good|lgtm)\b',
    re.I,
)
if not APPROVE_RE.search(prompt):
    sys.exit(0)

proposals_dir = os.path.join(root, "docs", "proposals")
if not os.path.isdir(proposals_dir):
    sys.exit(0)

FRONTMATTER_RE = re.compile(r'^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*\r?\n?', re.M | re.S)
STATUS_RE = re.compile(r'^status:\s*(.*?)\s*(?:#.*)?$', re.M)
METRIC_RE = re.compile(r'^metric:\s*(.*?)\s*(?:#.*)?$', re.M)
THRESHOLD_RE = re.compile(r'^threshold:\s*(.*?)\s*(?:#.*)?$', re.M)
RULE_RE = re.compile(r'^decision_rule:\s*(.*?)\s*(?:#.*)?$', re.M)

candidates = []
try:
    names = sorted(os.listdir(proposals_dir))
except OSError:
    sys.exit(0)

for name in names:
    if not name.endswith(".md") or name == "README.md":
        continue
    path = os.path.join(proposals_dir, name)
    try:
        with open(path, encoding="utf-8-sig") as fh:
            text = fh.read(1 << 20)
    except OSError:
        continue
    m = FRONTMATTER_RE.match(text)
    if not m:
        continue
    block = m.group(1)
    status_m = STATUS_RE.search(block)
    if not status_m or status_m.group(1).strip() != "hypothesis-registered":
        continue
    metric_m = METRIC_RE.search(block)
    threshold_m = THRESHOLD_RE.search(block)
    rule_m = RULE_RE.search(block)
    if not (metric_m and metric_m.group(1).strip()):
        continue
    if not (threshold_m and threshold_m.group(1).strip()):
        continue
    if not (rule_m and rule_m.group(1).strip()):
        continue
    candidates.append("docs/proposals/" + name)

# Ambiguous — more than one file sits in hypothesis-registered with a full
# package — or no candidate at all: mint nothing. Never guess which file
# the approval concerns.
if len(candidates) != 1:
    sys.exit(0)

rel_path = candidates[0]

tokens_dir = os.path.join(root, ".product-cycle", "tokens")
os.makedirs(tokens_dir, exist_ok=True)
tokens_dir_real = os.path.realpath(tokens_dir)

phrase = prompt.strip().replace("\r", "")[:300]

# Refuse to mint on anything credential/secret/internal-URL shaped.
if re.search(
    r'(api[_-]?key|secret|password|passwd|token=|bearer |authorization:|-----BEGIN '
    r'|https?://[^ ]*@|https?://(localhost|127\.|10\.|192\.168\.|internal[.-]|intranet[.-]))',
    phrase, re.I,
):
    sys.exit(0)

token_name = re.sub(r'[^A-Za-z0-9_.-]', '_', os.path.basename(rel_path)) + ".token"
token_file = os.path.join(tokens_dir, token_name)
token_file_real = os.path.join(tokens_dir_real, token_name)
if os.path.dirname(os.path.realpath(token_file)) != tokens_dir_real:
    sys.exit(0)

esc = phrase.replace("'", "''")
tmp = token_file + ".tmp"
with open(tmp, "w") as fh:
    fh.write("file: %s\n" % rel_path)
    fh.write("transition: hypothesis-registered -> measuring\n")
    fh.write("phrase: '%s'\n" % esc)
os.replace(tmp, token_file)
PY

exit 0
