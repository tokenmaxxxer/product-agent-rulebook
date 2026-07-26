#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|NotebookEdit|Bash): enforces product-cycle's
# state machine, and (per docs/specs/role-handoff-contract.md v2) the
# handoff contract's write-side rules, against the RESOLVED TARGET PATH
# being written, never against which tool performs the write or a literal
# filename appearing in a command string — a write made through
# `echo ... > file`, `tee`, or `sed -i` is judged the same as a
# Write/Edit tool call landing on the same path.
#
# This gate answers up to four questions:
#   1. Does this write reach product/state.md (by resolved target path)?
#      If so: is the resulting `stage` transition present as a row in
#      transition-rules.md? Present -> allow. Absent -> deny.
#   2. Does this write reach a path under product's four owned kinds
#      (contract §11: hypothesis, product-record, one-pager,
#      opportunity-tree) or a path structurally owned by another role
#      (a `docs/proposals/<date>-build-<slug>.md` slot, or a
#      `docs/reports/records/<subject>/<other-role>.md` record)? A write
#      landing on a foreign-owned path is refused and reported as a
#      conflict, never silently overwritten or merged — contract §11.
#   3. If the write is a `product-record` (`docs/reports/records/<subject>/product.md`):
#      does it carry a non-empty pointer to its governing `hypothesis`?
#      This is the one DEPENDS-ON relationship contract §4 assigns
#      product (`product` depends on `feasibility-record`... but the
#      mechanically checkable case here is the `product-record`'s own
#      pointer field back to the hypothesis it elaborates). Missing ->
#      deny. Per contract §14, this check is intentionally shallow: it
#      confirms the pointer field is present and non-empty, not that the
#      dependency's substance is correct — kind is self-declared and
#      unverified, and path ownership is a table, not a full gate, beyond
#      what is checked here.
#   4. Anything else is allowed through without comment.
#
# READ is broad by design: this gate has never parsed a record's `kind:`
# field for read-refusal purposes (there is no kind-based read-refusal
# logic anywhere in this file, and grepping this repo for `kind:` finds
# no such logic to remove) — it was already READ-broad by omission before
# the v2 contract, and v2 makes that the contract-required stance, not
# merely an accident of what was never built.
#
# It does NOT consult approval tokens or any token directory — that model
# was removed; see docs/reports/2026-07-26-hunt-conversational-state-machine.md.
#
# Denial reasons are kept textually distinct, on purpose:
#   - "the transition rules could not be loaded" (transition-rules.md or
#     product/state.md itself could not be read/parsed, or the hook input
#     was malformed)
#   - "this transition is not in the table" (both loaded fine; the specific
#     from -> to pair just isn't a listed row)
#   - "path ownership conflict" (a write reaches a path this repo's
#     product role does not own, per contract §11)
#   - "missing governing-hypothesis pointer" (a product-record write has
#     no non-empty pointer back to its hypothesis, per contract §4)
#
# Fail-closed: anything this hook cannot parse or resolve is a DENY, never
# an allow. Malformed hook input is denied with the rules-could-not-be-loaded
# message, never a silent exit 0.
#
# A Bash command whose write target cannot be determined statically (a
# variable, expansion, command substitution, glob, `eval`, or a heredoc
# into a computed name) is treated as reaching product/state.md ONLY when
# it is write-shaped toward product/state.md's directory; otherwise it is
# NOT globally denied — it is simply outside this gate's concern, same as
# any other unrelated write.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -uo pipefail

deny() {
  echo "product-cycle: refused — $1" >&2
  exit 2
}

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "the transition rules could not be loaded — python3 is required to evaluate the gate and is not on PATH."

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P)" || deny "the transition rules could not be loaded — cannot resolve this hook's own directory."
rules_path="$script_dir/transition-rules.md"

# Root is the repository being worked in: CLAUDE_PROJECT_DIR when the harness
# sets it, otherwise the process cwd, anchored on that directory's git root so
# an invocation from a subdirectory still resolves to the project root.
#
# It is deliberately NOT the nearest `.git` above this hook's own location.
# That coincides with the project only while the rulebook is vendored into it.
# Loaded as a plugin from its own checkout — which is how an orchestrator
# swaps rulebooks per role — it resolves to the RULEBOOK's repo, and the gate
# then guards a repository nobody is working in: every write in the real
# project falls outside its owned paths, so it allows all of them and says
# nothing. Measured 2026-07-26: a `scoped -> verdict` jump skipping `probing`
# was permitted with exit 0.
root="${CLAUDE_PROJECT_DIR:-$PWD}"
if top="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null)" && [ -n "$top" ]; then
  root="$top"
fi
root="$(cd "$root" 2>/dev/null && pwd -P)" || root=""
[ -n "$root" ] || deny "the transition rules could not be loaded — could not resolve the project root being worked in (CLAUDE_PROJECT_DIR/cwd)."

payload="$(cat 2>/dev/null)"
[ -n "$payload" ] || deny "the transition rules could not be loaded — empty tool-use payload on stdin; cannot evaluate the state gate."

PRODUCT_ROOT="$root" PRODUCT_PAYLOAD="$payload" PRODUCT_RULES_PATH="$rules_path" python3 <<'PY'
import json
import os
import posixpath
import re
import sys

def deny(msg):
    sys.stderr.write("product-cycle: refused — %s\n" % msg)
    sys.exit(2)

def allow():
    sys.exit(0)

root = os.environ["PRODUCT_ROOT"]
rules_path = os.environ["PRODUCT_RULES_PATH"]
raw = os.environ.get("PRODUCT_PAYLOAD", "")

# --- malformed input: always denied with the rules-could-not-be-loaded ---
try:
    event = json.loads(raw)
except ValueError:
    deny("the transition rules could not be loaded — the tool-use payload is not valid JSON.")
if not isinstance(event, dict):
    deny("the transition rules could not be loaded — the tool-use payload is not a JSON object.")

tool = event.get("tool_name")
tool_input = event.get("tool_input")
if not isinstance(tool, str) or not tool:
    deny("the transition rules could not be loaded — payload has no tool_name.")
if not isinstance(tool_input, dict):
    deny("the transition rules could not be loaded — payload has no tool_input object.")

STATE_REL = "product/state.md"
STAGE_RE = re.compile(r'^stage:\s*(.*?)\s*$', re.M)

# Single source of truth for which tools this gate recognizes as capable of
# writing product/state.md — used by BOTH the "does this reach the state
# file" dispatch and the "compute resulting content" dispatch below, so the
# two cannot drift apart the way Edit/MultiEdit did. A tool name outside this
# set that nonetheless reaches this script (e.g. because hooks.json's
# matcher and this list disagree, or a fake tool name) is a DENY, not a
# pass-through allow: unknown input fails closed.
RECOGNIZED_WRITE_TOOLS = ("Write", "Edit", "MultiEdit", "NotebookEdit")

# --- contract §2 kind: parsing (comment-tolerant) -------------------------
# Contract §2 requires `kind` parsing to tolerate a trailing comment on the
# same line (`kind: build-proposal  # re-scoped` must parse as
# `build-proposal`); a regex anchored to end-of-line with no comment
# tolerance is a gate defect, not a violation by the record's author. This
# is intentionally NOT `r'^kind:\s*(\S+)\s*$'` — that form fails on a
# trailing comment because `\S+` stops at the space but `$` then fails to
# match the comment text. Strip an unquoted trailing `#...` comment first,
# mirroring how YAML frontmatter parsers conventionally handle inline
# comments, then take the remaining token.
KIND_LINE_RE = re.compile(r'^kind:\s*(.*)$', re.M)

def parse_kind(text):
    """Return the self-declared `kind:` value from record text, or None if
    absent/unparseable. Self-declared and unverified per contract §14 —
    this function only extracts it, callers decide what to do with it."""
    m = KIND_LINE_RE.search(text or "")
    if not m:
        return None
    rest = m.group(1)
    # Strip a trailing unquoted `#...` comment (and surrounding whitespace).
    rest = re.split(r'\s+#', rest, maxsplit=1)[0].strip()
    return rest or None

# --- contract §11 owned-path classification --------------------------------
# product's four owned kinds, plus recognition of paths structurally owned
# by another role so a conflicting write can be refused-and-reported
# rather than silently overwritten or merged (contract §11).
PRODUCT_HYPOTHESIS_RE = re.compile(r'^docs/proposals/(\d{4}-\d{2}-\d{2})-(?!build-)([A-Za-z0-9][A-Za-z0-9\-]*)\.md$')
FOREIGN_BUILD_PROPOSAL_RE = re.compile(r'^docs/proposals/(\d{4}-\d{2}-\d{2})-build-([A-Za-z0-9][A-Za-z0-9\-]*)\.md$')
RECORDS_RE = re.compile(r'^docs/reports/records/([^/]+)/([A-Za-z0-9\-]+)\.md$')

def classify_path(rel_path):
    """Classify a repo-relative path against contract §11's ownership
    table. Returns (category, subject_or_None) where category is one of:
      "hypothesis", "product-record", "one-pager", "opportunity-tree"
        -> a path product owns.
      "foreign"
        -> a path structurally owned by a different role (a
           `<date>-build-<slug>.md` proposal, or a
           `docs/reports/records/<subject>/<other>.md` record where
           <other> is not "product").
      None
        -> outside this gate's owned-path/foreign-path concern entirely.
    """
    rel = rel_path.replace("\\", "/")
    if rel == "product/one-pager.md":
        return "one-pager", None
    if rel == "product/opportunity-tree.md":
        return "opportunity-tree", None
    if FOREIGN_BUILD_PROPOSAL_RE.match(rel):
        return "foreign", None
    if PRODUCT_HYPOTHESIS_RE.match(rel):
        return "hypothesis", None
    m = RECORDS_RE.match(rel)
    if m:
        subject, record_name = m.group(1), m.group(2)
        if record_name == "product":
            return "product-record", subject
        return "foreign", subject
    return None, None

def parse_stage(text):
    """Return (stage_or_None, error_or_None)."""
    matches = STAGE_RE.findall(text or "")
    if len(matches) == 0:
        return None, "no `stage:` field"
    if len(matches) > 1:
        return None, "%d `stage:` fields (must be exactly one)" % len(matches)
    val = matches[0].strip()
    if not val:
        return None, "`stage:` field is empty"
    return val, None

def parse_rules(text):
    rows = []
    for line in (text or "").splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cols = [c.strip() for c in line.strip("|").split("|")]
        if len(cols) != 4:
            continue
        frm, to, actor, precond = cols
        if frm.lower() == "from" and to.lower() == "to":
            continue
        if re.fullmatch(r'[-: ]+', frm or "-"):
            continue
        if not frm or not to:
            continue
        rows.append((frm, to))
    return rows

# --- resolve which real filesystem path this tool call targets ----------
LITERAL_TOKEN_RE = re.compile(r'^[A-Za-z0-9_./\-]+$')

def literal_target_or_none(raw_token):
    if not raw_token:
        return None
    tok = raw_token
    if len(tok) >= 2 and tok[0] == "'" and tok[-1] == "'":
        inner = tok[1:-1]
        return inner if LITERAL_TOKEN_RE.match(inner) else None
    if LITERAL_TOKEN_RE.match(tok):
        return tok
    return None

def looks_state_shaped(token):
    """Heuristic: does this unresolvable token/text look like it targets
    product/state.md (or product/'s directory), even though it cannot be
    resolved to a concrete literal path? Used ONLY to decide whether an
    unresolvable Bash write reaches the state file — never to deny
    globally for targets that plainly aren't state-shaped."""
    t = token.lower()
    return "state.md" in t or re.search(r'(^|/)product(/|$)', t) is not None

BASH_WRITE_OPS = [
    re.compile(r'>{1,2}\s*([^\s;&|<>]+)'),
    re.compile(r'\btee\b(?:\s+-a)?\s+([^\s;&|<>]+)'),
    re.compile(r'\b(?:sed|perl|ruby)\b[^|;&\n]*\s-i\b[A-Za-z0-9_.\-]*\s+([^\s;&|<>]+)'),
    re.compile(r'\bcp\b\s+.*?([^\s;&|<>]+)\s*(?:[;&|\n]|$)'),
    re.compile(r'\bmv\b\s+.*?([^\s;&|<>]+)\s*(?:[;&|\n]|$)'),
    re.compile(r'\bdd\b[^|;&\n]*\bof=([^\s;&|<>]+)'),
    re.compile(r'\binstall\b\s+.*?([^\s;&|<>]+)\s*(?:[;&|\n]|$)'),
]

# write-through-another-tool: e.g. `python3 -c "open(path,
# 'w').write(...)"`. Judged by RESOLVED TARGET PATH like every other idiom
# above, not by which tool performs the write. Handled separately from
# BASH_WRITE_OPS (rather than folded into it) because a python open() call's
# target may be a clean literal, OR built from concatenation/a variable — in
# which case it is write-shaped (PY_OPEN_WRITE_RE matches) but has no
# extractable literal (PY_OPEN_LITERAL_RE does not match), and must be
# treated as an indeterminate target, never silently skipped.
PY_OPEN_WRITE_RE = re.compile(r"\bopen\s*\([^)]*,\s*['\"][wxa][^'\"]*['\"]")
PY_OPEN_LITERAL_RE = re.compile(r"\bopen\s*\(\s*['\"]([^'\"]*)['\"]\s*,\s*['\"][wxa]")

real_root = posixpath.normpath(os.path.realpath(root).replace("\\", "/"))
state_abs_target = posixpath.normpath(posixpath.join(real_root, STATE_REL))

def resolves_to_state_file(literal_path):
    norm = literal_path.replace("\\", "/")
    absolute = posixpath.normpath(norm if posixpath.isabs(norm) else posixpath.join(root, norm))
    resolved = posixpath.normpath(os.path.realpath(absolute).replace("\\", "/"))
    return resolved == state_abs_target, resolved

def repo_relative_or_none(literal_path):
    """Resolve a literal path to a repo-relative posix path (for §11
    owned-path classification), or None if it resolves outside root."""
    norm = literal_path.replace("\\", "/")
    absolute = posixpath.normpath(norm if posixpath.isabs(norm) else posixpath.join(root, norm))
    resolved = posixpath.normpath(os.path.realpath(absolute).replace("\\", "/"))
    if resolved == real_root or not resolved.startswith(real_root + "/"):
        return None
    return resolved[len(real_root) + 1:]

CONTRACT_REL = "docs/specs/role-handoff-contract.md"

def require_contract():
    # The handoff contract holds only within this single repo. This gate
    # resolves exactly one root (the git root resolved above, by walking
    # from CLAUDE_PROJECT_DIR/cwd) and checks for
    # docs/specs/role-handoff-contract.md inside THAT root only — no
    # parent/sibling-repo lookup, no SHA pin, no comparison to any other
    # repo's git history. If the contract file is absent, this
    # handoff-protocol action is refused with an honest message rather
    # than silently passing. Runs ahead of BOTH the state.md
    # stage-transition check and the §11 owned-path checks below, since
    # both are handoff-protocol actions.
    if not os.path.isfile(os.path.join(root, CONTRACT_REL)):
        deny(
            "this repo has no collaboration contract yet — %s was not found at %s. "
            "Handoff-protocol actions cannot proceed until this repo carries its own contract."
            % (CONTRACT_REL, root)
        )

def check_owned_path_write(rel_path, new_text):
    """Enforce contract §11 (owned-path write refusal) and the
    mechanically-checkable half of contract §4's DEPENDS-ON
    (product-record must point at its governing hypothesis). Denies on
    violation; returns normally (falls through to allow()) otherwise."""
    category, subject = classify_path(rel_path)
    if category is None:
        return
    require_contract()
    if category == "foreign":
        deny(
            "path ownership conflict — %s falls in another role's owned space per "
            "docs/specs/role-handoff-contract.md §11. product refuses to write there "
            "rather than overwriting or merging into it silently; report this conflict "
            "to the user." % rel_path
        )
    kind = parse_kind(new_text)
    if kind is not None and kind != category:
        deny(
            "path ownership conflict — %s is product's `%s` slot per contract §11, but the "
            "content self-declares `kind: %s`. Refusing rather than writing a mismatched "
            "kind into an owned path." % (rel_path, category, kind)
        )
    if category == "product-record":
        # Mechanically checkable half of contract §4's DEPENDS-ON: the
        # product-record must carry a non-empty pointer back to the
        # governing hypothesis it elaborates. This does NOT verify the
        # pointer resolves to a real, correct hypothesis — per contract
        # §14, kind is self-declared and unverified, and this check only
        # confirms the field is present and non-empty.
        m = re.search(r'^(?:governing_hypothesis|hypothesis):\s*(.+?)\s*$', new_text or "", re.M)
        if not m or not m.group(1).strip():
            deny(
                "missing governing-hypothesis pointer — %s (a product-record) has no "
                "non-empty `hypothesis:` (or `governing_hypothesis:`) field pointing at the "
                "hypothesis it elaborates, per contract §4's DEPENDS-ON relationship." % rel_path
            )

reaches_state = False
unresolved_bash = False  # reaches state file via an unresolvable Bash target

if tool in RECOGNIZED_WRITE_TOOLS:
    path = tool_input.get("file_path") or tool_input.get("notebook_path")
    if not isinstance(path, str) or not path:
        deny("the transition rules could not be loaded — %s call has no usable file_path/notebook_path." % tool)
    is_state, resolved = resolves_to_state_file(path)
    if not is_state:
        rel = repo_relative_or_none(path)
        if rel is not None and tool in ("Write", "Edit"):
            # Compute resulting content for owned-path/kind/DEPENDS-ON
            # checks. NotebookEdit and MultiEdit are out of scope for this
            # check (MultiEdit's own state.md content-computation logic
            # below is state.md-specific; owned-path record files are
            # plain markdown, most commonly edited via Write/Edit).
            if tool == "Write":
                content = tool_input.get("content")
                content = content if isinstance(content, str) else ""
            else:  # Edit
                new_string = tool_input.get("new_string")
                content = new_string if isinstance(new_string, str) else ""
            check_owned_path_write(rel, content)
        allow()
    reaches_state = True

elif tool == "Bash":
    command = tool_input.get("command")
    if not isinstance(command, str) or not command.strip():
        deny("the transition rules could not be loaded — Bash call has no usable command string.")

    if re.search(r'(?:^|[\s;&|(])eval\b', command):
        if looks_state_shaped(command):
            reaches_state = True
            unresolved_bash = True
        else:
            allow()
    else:
        found_op = False
        for op_re in BASH_WRITE_OPS:
            for m in op_re.finditer(command):
                found_op = True
                raw_token = m.group(1)
                cand = literal_target_or_none(raw_token)
                if cand is None:
                    if looks_state_shaped(raw_token) or looks_state_shaped(command):
                        reaches_state = True
                        unresolved_bash = True
                    elif "docs/reports/records/" in command:
                        # §11: a write-capable Bash op whose target cannot
                        # be resolved statically, in a command that names
                        # the owned record tree, is default-denied rather
                        # than allowed through — the target might land on
                        # a foreign record and this gate cannot prove it
                        # doesn't.
                        deny(
                            "a Bash write-capable command's target path could not be "
                            "statically resolved, and the command references the owned "
                            "record tree (docs/reports/records/). Per §11, an indeterminate "
                            "write target within that tree is default-denied rather than "
                            "allowed through."
                        )
                    # else: not write-shaped toward product/state.md's
                    # directory or the owned record tree — do not deny
                    # globally; keep scanning other ops in the same command
                    # line.
                    continue
                is_state, resolved = resolves_to_state_file(cand)
                if is_state:
                    reaches_state = True
                    continue
                rel_cand = repo_relative_or_none(cand)
                if rel_cand is not None:
                    check_owned_path_write(rel_cand, "")

        if PY_OPEN_WRITE_RE.search(command):
            found_op = True
            lit_m = PY_OPEN_LITERAL_RE.search(command)
            lit_cand = literal_target_or_none(lit_m.group(1)) if lit_m else None
            if lit_cand is None:
                if looks_state_shaped(command):
                    reaches_state = True
                    unresolved_bash = True
                elif "docs/reports/records/" in command:
                    deny(
                        "a Bash write-capable python open() call's target path could not "
                        "be statically resolved (built from concatenation or a variable), "
                        "and the command references the owned record tree "
                        "(docs/reports/records/). Per §11, an indeterminate write target "
                        "within that tree is default-denied rather than allowed through."
                    )
            else:
                is_state, resolved = resolves_to_state_file(lit_cand)
                if is_state:
                    reaches_state = True
                else:
                    rel_lit = repo_relative_or_none(lit_cand)
                    if rel_lit is not None:
                        check_owned_path_write(rel_lit, "")

        if not found_op:
            allow()
        if not reaches_state:
            allow()
else:
    deny(
        "an unrecognized tool (%r) reached this gate. This gate's recognized-write-tool "
        "list is %r; a tool name outside that set is treated as a denial, not a pass — "
        "unknown input fails closed rather than being assumed to be a read." % (tool, RECOGNIZED_WRITE_TOOLS)
    )

if not reaches_state:
    allow()

# --- repo-local handoff contract check (state.md path) -------------------
# See require_contract() above for the full rationale; this is the same
# check, re-pointed at the state.md stage-transition path (the owned-path
# writes above already ran it via check_owned_path_write).
require_contract()

if unresolved_bash:
    deny(
        "the transition rules could not be loaded — a Bash command's write target toward %s "
        "cannot be determined statically (variable/expansion/substitution/glob/eval/computed "
        "name), so the resulting `stage` transition cannot be verified; use Write or Edit instead." % STATE_REL
    )

# --- load transition-rules.md -------------------------------------------
try:
    with open(rules_path, encoding="utf-8-sig") as fh:
        rules_text = fh.read(1 << 20)
except OSError as exc:
    deny("the transition rules could not be loaded — transition-rules.md missing or unreadable at %s (%s)." % (rules_path, exc))

if not rules_text.strip():
    deny("the transition rules could not be loaded — transition-rules.md at %s is empty." % rules_path)

rows = parse_rules(rules_text)
if not rows:
    deny("the transition rules could not be loaded — transition-rules.md at %s has no parseable rows." % rules_path)

NONE_STATE = "(none)"
known_states = set()
for frm, to in rows:
    if frm != NONE_STATE:
        known_states.add(frm)
    if to != NONE_STATE:
        known_states.add(to)

# --- read current on-disk stage ------------------------------------------
# "No state file" is derived from file existence alone, as a separate
# boolean, NEVER by comparing a parsed value against the `(none)` string.
# Only a genuinely absent state file yields the synthetic `(none)` old
# state used for bootstrap-row matching.
#
# If the state file exists, its value must be a member of known_states.
# `(none)` as the on-disk value, an empty value, a missing field, or any
# value outside known_states are all the same case: the gate cannot
# establish its own input, so it denies with the rules-could-not-be-loaded
# message — never "transition not in the table".
abs_state_path = os.path.join(root, STATE_REL)
file_exists = os.path.exists(abs_state_path)
if not file_exists:
    old_stage = NONE_STATE
else:
    try:
        with open(abs_state_path, encoding="utf-8-sig") as fh:
            old_text = fh.read(1 << 20)
    except OSError as exc:
        deny("the transition rules could not be loaded — cannot read current %s (%s)." % (STATE_REL, exc))
    old_stage, old_err = parse_stage(old_text)
    if old_err:
        deny("the transition rules could not be loaded — %s: %s." % (STATE_REL, old_err))
    if old_stage not in known_states:
        deny("the transition rules could not be loaded — %s's `stage:` value %r is not a known state." % (STATE_REL, old_stage))

# --- compute resulting content -------------------------------------------
if tool == "NotebookEdit":
    deny("the transition rules could not be loaded — %s is a NotebookEdit target; this gate cannot verify notebook cell edits against frontmatter." % STATE_REL)

if tool == "Write":
    new_text = tool_input.get("content")
    if not isinstance(new_text, str):
        deny("the transition rules could not be loaded — Write call on %s has no string content." % STATE_REL)
elif tool == "Edit":
    old_string = tool_input.get("old_string")
    new_string = tool_input.get("new_string")
    if not isinstance(old_string, str) or not isinstance(new_string, str):
        deny("the transition rules could not be loaded — Edit call on %s is missing old_string/new_string." % STATE_REL)
    if old_string == "":
        new_text = new_string
    else:
        if old_string not in old_text:
            deny("the transition rules could not be loaded — Edit call's old_string was not found verbatim in %s." % STATE_REL)
        replace_all = tool_input.get("replace_all") is True
        if replace_all:
            new_text = old_text.replace(old_string, new_string)
        else:
            new_text = old_text.replace(old_string, new_string, 1)
elif tool == "MultiEdit":
    edits = tool_input.get("edits")
    if not isinstance(edits, list) or not edits:
        deny("the transition rules could not be loaded — MultiEdit call on %s has no usable edits list." % STATE_REL)
    text = old_text
    for e in edits:
        if not isinstance(e, dict):
            deny("the transition rules could not be loaded — MultiEdit call on %s has a non-object edit entry." % STATE_REL)
        old_string = e.get("old_string")
        new_string = e.get("new_string")
        if not isinstance(old_string, str) or not isinstance(new_string, str):
            deny("the transition rules could not be loaded — MultiEdit call on %s has an edit missing old_string/new_string." % STATE_REL)
        if old_string == "":
            text = new_string
            continue
        if old_string not in text:
            deny("the transition rules could not be loaded — MultiEdit call's old_string was not found verbatim in %s at the point it is applied." % STATE_REL)
        replace_all = e.get("replace_all") is True
        if replace_all:
            text = text.replace(old_string, new_string)
        else:
            text = text.replace(old_string, new_string, 1)
    new_text = text
else:
    deny("the transition rules could not be loaded — unrecognized tool %s targeting %s." % (tool, STATE_REL))

new_stage, new_err = parse_stage(new_text)
if new_err:
    deny("the transition rules could not be loaded — resulting %s would have %s." % (STATE_REL, new_err))

if (old_stage, new_stage) in rows:
    allow()

deny(
    "this transition is not in the table — `%s -> %s` is not a listed row in transition-rules.md "
    "for %s." % (old_stage, new_stage, STATE_REL)
)
PY
status=$?
exit "$status"
