#!/usr/bin/env bash
# UserPromptSubmit hook: mints a single-use scope-approval token ONLY from an
# unambiguous human approval found in the user's own turn — never from a file,
# record, PR, comment, or tool result. This is the human-signal capture half of
# contract §19's scope-proposed -> scope-approved edge, modeled directly on
# qa-cycle's capture-verdict.sh. scope-record-gate.sh consumes the token.
#
# This hook NEVER blocks. Malformed/unreadable input, no root, no identifiable
# subject, or an absent/ambiguous approval all mean: emit nothing, exit 0. The
# gate — not this hook — is what refuses an unsignaled transition.
#
# The human must name the subject explicitly ("subject <id>") and state an
# explicit scope approval, so the minted token binds to that subject and the
# exact scope-proposed -> scope-approved transition.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -euo pipefail

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || exit 0

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

PRODUCT_PAYLOAD="$payload" python3 <<'PY'
import json, os, posixpath, re, subprocess, sys, tempfile

def bail():
    sys.exit(0)

raw = os.environ.get("PRODUCT_PAYLOAD", "")
try:
    event = json.loads(raw)
except ValueError:
    bail()
if not isinstance(event, dict):
    bail()

prompt = event.get("prompt")
if not isinstance(prompt, str) or not prompt.strip():
    bail()

# --- identify the subject this turn concerns (required, explicit) ------
sm = re.search(r'(?i)\bsubject[\s:]+([A-Za-z0-9][A-Za-z0-9_-]{0,127})', prompt)
if not sm:
    bail()
subject = sm.group(1)
if not re.match(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$', subject):
    bail()

# --- unambiguous scope-approval detection ------------------------------
# Require an explicit approval keyword tied to scope, not bare assent.
#
# `\bscope-?approved\b` used to be a third alternative here, and it was a hole
# straight through §19: it matches the NAME OF THE STATE, so any sentence that
# merely mentions the transition minted a token for it. Measured 2026-07-27,
# all three of these produced a valid, consumable token for a real subject:
#
#   "subject <id> 의 scope-approved 게이트에 닿으면 멈춰라. 대신 승인하지 마라."
#   "§19 는 subject <id> 의 loop_state 를 scope-approved 로 올리는 …"   (quoting
#                                                                       the contract)
#   "subject <id> 의 scope 를 approve 한다."                            (the real thing)
#
# The first is a REFUSAL to approve, and the token it minted carried that
# refusal verbatim in its own `phrase:` field. The second is the contract's own
# text. A gate the contract calls "human-owned, never self-certified" was
# trippable by an agent explaining that it must not approve.
#
# Naming a transition is not performing it. Approval now requires an approval
# VERB bound to the scope — including a Korean form, so that dropping the
# state-name alternative does not leave a Korean-speaking human with no way to
# approve at all.
#
# The state name is blanked out first. Dropping the third alternative was not
# enough on its own: `\bscope\b[^.\n]*\bapproved\b` also spans the literal
# `scope-approved`, because the hyphen is a word boundary. So "이 subject 는
# 아직 scope-approved 가 아니다" — a statement that it is NOT approved — still
# minted a token. `scope-approved` is an identifier; it is never a speech act.
speech = re.sub(r'(?i)\bscope[-_ ]?approved\b', ' <state> ', prompt)
approves = re.search(
    r'(?i)\b(approve|approved|approving)\b[^.\n]*\bscope\b'
    r'|\bscope\b[^.\n]*\b(approved|is approved|looks good to approve|approve)\b'
    r'|(?:scope|스코프|범위)[^.\n]*승인(?!\s*(?:하지|말|안))',
    speech)
if not approves:
    bail()
# An approval verb inside a negation is not an approval. The window covers the
# clause before the match, which is where English negation sits ("do not
# approve the scope"); Korean negation trails the verb and is handled by the
# lookahead above.
NEGATED = re.compile(r'(?i)\b(do not|don\'?t|never|must not|cannot|can\'?t|'
                     r'without|refus|decline|instead of)\b'
                     r'|하지\s*마|하지\s*말|말고|말라|않는다|없이|금지')
if NEGATED.search(speech[max(0, approves.start() - 60):approves.end() + 30]):
    bail()
# Reject bare assent even if a keyword coincidentally appears.
if re.match(r'^\s*(ok|okay|sure|sounds good|yep|yes|k|fine)\s*[.!]?\s*$', prompt, re.I):
    bail()

# --- resolve project root (no root -> nothing to do) -------------------
def git_top(p):
    try:
        out = subprocess.run(["git", "-C", p, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True)
        if out.returncode == 0 and out.stdout.strip():
            return posixpath.normpath(os.path.realpath(out.stdout.strip()).replace("\\", "/"))
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
    bail()

# Token dir under the subject's record area. Resolve, then containment-check.
records_root = posixpath.join(root, "docs", "reports", "records")
tokens_dir = posixpath.join(records_root, subject, "tokens")
try:
    os.makedirs(tokens_dir, exist_ok=True)
except OSError:
    bail()
tokens_real = posixpath.normpath(os.path.realpath(tokens_dir).replace("\\", "/"))
expected = posixpath.normpath(posixpath.join(records_root, subject, "tokens"))
if tokens_real != posixpath.normpath(os.path.realpath(expected).replace("\\", "/")):
    bail()
if not tokens_real.startswith(posixpath.normpath(os.path.realpath(records_root).replace("\\", "/")) + "/"):
    bail()

token_file = posixpath.join(tokens_real, subject + ".scope-approved.token")
if posixpath.dirname(token_file) != tokens_real:
    bail()

# Redact anything credential/secret/internal-URL shaped from the recorded phrase.
phrase = prompt.strip().replace("\r", "")[:300]
if re.search(r'(?i)(api[_-]?key|secret|password|passwd|token=|bearer |authorization:|-----BEGIN |https?://[^ ]*@)', phrase):
    phrase = "(approval wording redacted: looked credential/secret-shaped)"

try:
    fd, tmp = tempfile.mkstemp(dir=tokens_real, prefix=".token.")
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write("subject: %s\n" % subject)
        fh.write("transition: scope-proposed -> scope-approved\n")
        fh.write("actor: user\n")
        fh.write("phrase: %s\n" % phrase.replace("\n", " "))
    os.replace(tmp, token_file)
except OSError:
    bail()

sys.exit(0)
PY
