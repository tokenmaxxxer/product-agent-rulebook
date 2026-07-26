#!/usr/bin/env bash
# PreToolUse hook (Write|Edit|MultiEdit|NotebookEdit|Bash): enforces contract
# §19's front-record side. A write that moves product's front record
# docs/reports/records/<subject>/product.md into loop_state: scope-approved is
# refused unless an UNCONSUMED human-placed approval token exists for that
# subject — mirroring qa-cycle's capture-verdict.sh human-token mechanism (a
# token minted only from the human's own in-conversation turn). The gate never
# PERFORMS the approval: no token, no transition. On a legal transition the
# token is consumed (deleted) so it cannot be replayed.
#
# Peer to state-gate.sh; never edits/replaces it. state-gate.sh checks the
# scope-proposed -> scope-approved row is legal in principle (actor: user);
# this gate checks a human actually signaled it this conversation.
#
# Bash coverage (docs/proposals/2026-07-26-scope-record-gate-bash-bypass.md):
# this gate used to fire only on Write/Edit/MultiEdit/NotebookEdit, so a
# Bash-authored write to the front record (redirect, heredoc, tee, sed -i,
# `Path(...).write_text(...)`, `open(...).write(...)`) could land
# scope-approved with zero human token. hooks.json now also routes Bash here,
# and the Bash branch below judges a write by its RESOLVED TARGET PATH and,
# where extractable, its LITERAL resulting content — never by which tool
# performed the write. Fail-closed per the frozen contract: any Bash write
# that reaches (or may reach, given an unresolvable target/content) the front
# record is refused unless both its target and resulting content are
# literally determined and shown not to set scope-approved (or a valid token
# covers the transition). This never mints or infers a token — only refusal.
#
# Fail-closed on every malformed/missing-input branch: unparseable payload,
# missing tool_input/path, indeterminate project root, unreadable on-disk file
# for an Edit, or an unresolvable Edit are all DENY.
#
# Tool-agnostic default-deny (docs/proposals/2026-07-26-scope-record-gate-tool-agnostic.md):
# the Write/Edit/MultiEdit dispatch below used to end in `else: allow()`, so
# NotebookEdit (or any other/future tool) landed the front record at
# scope-approved with zero token check. The terminal branch now instead tries
# to extract a literal resulting text from the call's payload (covers
# NotebookEdit's new_source/cells today) and judges it exactly like a Write's
# content; if no content-bearing field can be found, the call is refused
# rather than allowed. There is no tool name for which this gate silently
# allows an indeterminate write to the front record.
#
# Kill switch: export PRODUCT_CYCLE_OFF=1
set -euo pipefail

deny() { echo "product-cycle: refused — $1" >&2; exit 2; }

case "${PRODUCT_CYCLE_OFF:-}" in
  ""|0|false|no|off) ;;
  *) exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "scope-record-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the scope-record gate (fail-closed)."

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
    deny("the tool-use payload is not valid JSON; the scope-record gate cannot judge a write it cannot parse (fail-closed).")
if not isinstance(event, dict):
    deny("the tool-use payload is not a JSON object (fail-closed).")

tool = event.get("tool_name")
tool_input = event.get("tool_input")
if not isinstance(tool, str) or not tool:
    deny("payload has no tool_name (fail-closed).")
if not isinstance(tool_input, dict):
    deny("payload has no tool_input object (fail-closed).")

# Read-only-tool passthrough (docs/proposals/2026-07-26-scope-record-gate-deny-on-ambiguity.md
# regression fix): this gate only governs transitions that MUTATE the front
# record's loop_state to scope-approved. A tool that cannot write at all —
# Read, Grep, Glob, LS, or any other tool whose payload carries no
# content/write intent — is never a scope-approved transition, so it is
# never this gate's concern regardless of which path (e.g. the catch-all
# `.*` PreToolUse matcher) routed it here. This is a tool-identity
# passthrough, not a content-shape default-allow: the tool-agnostic
# default-deny below still applies to every tool NOT in this fixed
# known-read-only set, including any future/unknown tool name.
if tool in ("Read", "Grep", "Glob", "LS"):
    allow()

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

def resolve_root_no_target():
    cpd = os.environ.get("CLAUDE_PROJECT_DIR")
    if cpd and plausible(cpd):
        return posixpath.normpath(os.path.realpath(cpd).replace("\\", "/"))
    g = git_top(os.getcwd())
    if g:
        return g
    return None

FRONT_RECORD_RE = re.compile(r'^docs/reports/records/([^/]+)/product\.md$')

def loop_state_of(text):
    mm = re.search(r'(?mi)^\s*loop_state\s*:\s*([A-Za-z0-9\-]+)', text or "")
    return mm.group(1).strip() if mm else None

def token_valid(root, subject, path):
    if not os.path.isfile(path):
        return False
    try:
        with open(path, encoding="utf-8-sig") as fh:
            body = fh.read(1 << 16)
    except OSError:
        return False
    if not re.search(r'(?mi)^\s*subject:\s*' + re.escape(subject) + r'\s*$', body):
        return False
    if not re.search(r'(?mi)^\s*transition:\s*scope-proposed\s*->\s*scope-approved\s*$', body):
        return False
    return True

def require_token_and_consume(root, subject):
    """Shared §19 enforcement for the scope-proposed -> scope-approved
    transition, used identically by the Write/Edit/MultiEdit path and the
    Bash path below — one rule, two entry points."""
    if not re.match(r'^[A-Za-z0-9][A-Za-z0-9_-]{0,127}$', subject):
        deny("the front record's subject id %r is not a safe token; refusing to resolve an approval "
             "token path from it (fail-closed)." % subject)
    tokens_dir = posixpath.join(root, "docs", "reports", "records", subject, "tokens")
    token_file = posixpath.join(tokens_dir, subject + ".scope-approved.token")
    if not token_valid(root, subject, token_file):
        deny(
            "scope-proposed -> scope-approved for subject '%s' requires a human-placed approval "
            "token (an unconsumed %s bound to this subject and transition), and none was found. "
            "This state may not be set unilaterally, per contract §19 — the human moves it from "
            "scope-proposed to scope-approved via the WAKES-ON approval edge, regardless of which "
            "tool authors the write. See scope-approval-token.sh (modeled on qa-cycle's "
            "capture-verdict.sh) for how the human signal is captured." % (
                subject, posixpath.relpath(token_file, root))
        )
    try:
        os.remove(token_file)
    except OSError:
        deny("the approval token for subject '%s' could not be consumed (removed); refusing rather "
             "than leaving a replayable token in place (fail-closed)." % subject)

# ---------------------------------------------------------------------------
# Bash path: judged by resolved target path and, where extractable, literal
# resulting content — mirrors state-gate.sh's Bash-idiom recognition, kept
# self-contained here (no cross-file import) per the per-repo-independence
# constraint.
# ---------------------------------------------------------------------------
if tool == "Bash":
    command = tool_input.get("command")
    if not isinstance(command, str) or not command.strip():
        deny("Bash call has no usable command string (fail-closed).")

    root = resolve_root_no_target()
    if not root:
        deny("no project root could be determined for this Bash call (fail-closed).")

    def repo_rel(tgt):
        norm = tgt.replace("\\", "/")
        absu = posixpath.normpath(norm if posixpath.isabs(norm) else posixpath.join(root, norm))
        resolved = posixpath.normpath(os.path.realpath(absu).replace("\\", "/"))
        if resolved == root or not resolved.startswith(root + "/"):
            return None
        return resolved[len(root) + 1:]

    LITERAL_TOKEN_RE = re.compile(r'^[A-Za-z0-9_./\-]+$')

    def literal_target_or_none(raw_token):
        if not raw_token:
            return None
        tok = raw_token
        if len(tok) >= 2 and tok[0] == tok[-1] and tok[0] in "\"'":
            inner = tok[1:-1]
            return inner if LITERAL_TOKEN_RE.match(inner) else None
        if LITERAL_TOKEN_RE.match(tok):
            return tok
        return None

    TREE_HINT = "docs/reports/records/"

    # --- (a) fully-determined writes: literal target AND literal content ---
    determined = []  # (subject, abs_path, new_text)
    determined_rels = set()  # repo-relative targets already fully resolved above,
                              # so the coarser OTHER_WRITE_RES redirect pattern below
                              # (which also matches a heredoc's own `>`/`>>`) does not
                              # re-flag the SAME write as ambiguous.

    # A heredoc's redirect target and its `<<MARKER` introducer may appear in
    # either order on the header line (`cat > f <<'EOF'` or
    # `cat <<'EOF' > f`) — match the whole header line first, then pull the
    # redirect target out of it independently of ordering.
    HEREDOC_HEADER_RE = re.compile(
        r"(?m)^([^\n]*<<-?\s*(['\"]?)(\w+)\2[^\n]*)\n(.*?)\n[ \t]*\3\b", re.S)
    HEREDOC_TARGET_RE = re.compile(r'(?:^|[\s;&|])\d?>{1,2}(?!\&)\s*([^\s;&|<>]+)')
    # Deny-on-ambiguity (docs/proposals/2026-07-26-scope-record-gate-deny-on-ambiguity.md):
    # an UNQUOTED heredoc marker (`<<EOF`, not `<<'EOF'`/`<<"EOF"`) means the
    # real shell performs parameter/command expansion on the body before it
    # is written to disk. If that body contains ANY expansion marker ($,
    # backtick, $(...), ${...}), this gate cannot prove the unexpanded text
    # it sees is what actually lands on disk — a `$VAR` could resolve to
    # `scope-approved` at runtime. Such a body is never treated as a literal;
    # a heredoc write whose literal target reaches (or, if unresolvable,
    # might reach) the front record with a non-provable body is refused.
    # A QUOTED heredoc marker disables shell expansion entirely, so its body
    # is still provably literal even if it happens to contain a `$`.
    SHELL_EXPANSION_RE = re.compile(r'\$|`')
    ambiguous_tree_hit = False
    for hm in HEREDOC_HEADER_RE.finditer(command):
        header, quote, content = hm.group(1), hm.group(2), hm.group(4)
        tm = HEREDOC_TARGET_RE.search(header)
        cand = literal_target_or_none(tm.group(1)) if tm else None
        rel = repo_rel(cand) if cand else None
        m = FRONT_RECORD_RE.match(rel) if rel else None
        if not m:
            continue
        if quote == "" and SHELL_EXPANSION_RE.search(content):
            ambiguous_tree_hit = True
            continue
        determined.append((m.group(1), posixpath.join(root, rel), content))
        determined_rels.add(rel)

    WT_CONTENT_RE = re.compile(
        r"(['\"])([^'\"]*)\1\s*\)\s*\.\s*write_(?:text|bytes)\s*\(\s*"
        r"(?:'''(.*?)'''|\"\"\"(.*?)\"\"\"|'([^']*)'|\"([^\"]*)\")", re.S)
    for wm in WT_CONTENT_RE.finditer(command):
        cand = literal_target_or_none(wm.group(2))
        if cand is None:
            continue
        rel = repo_rel(cand)
        if rel is None:
            continue
        m = FRONT_RECORD_RE.match(rel)
        if m:
            content = next((g for g in wm.groups()[2:] if g is not None), "")
            determined.append((m.group(1), posixpath.join(root, rel), content))

    OPEN_CONTENT_RE = re.compile(
        r"open\s*\(\s*(['\"])([^'\"]*)\1\s*,\s*['\"][wxa][^'\"]*['\"]\s*\)\s*\.\s*write\s*\(\s*"
        r"(?:'''(.*?)'''|\"\"\"(.*?)\"\"\"|'([^']*)'|\"([^\"]*)\")", re.S)
    for om in OPEN_CONTENT_RE.finditer(command):
        cand = literal_target_or_none(om.group(2))
        if cand is None:
            continue
        rel = repo_rel(cand)
        if rel is None:
            continue
        m = FRONT_RECORD_RE.match(rel)
        if m:
            content = next((g for g in om.groups()[2:] if g is not None), "")
            determined.append((m.group(1), posixpath.join(root, rel), content))

    # --- (b) any other write-shaped idiom: ambiguous if it targets, or might
    # target (unresolved target while the command names the owned tree), the
    # front record — deny rather than allow, since content/target here is not
    # literally pinned. ---
    OTHER_WRITE_RES = [
        re.compile(r'(?:^|[\s;&|])\d?>{1,2}(?!\&)\s*([^\s;&|<>]+)'),
        re.compile(r'\btee\b(?:\s+-a)?\s+([^\s;&|<>]+)'),
        re.compile(r'\b(?:sed|perl|ruby)\b[^|;&\n]*\s-i\b[A-Za-z0-9_.\-]*\s+([^\s;&|<>]+)'),
        re.compile(r'\bcp\b\s+.*?([^\s;&|<>]+)\s*(?:[;&|\n]|$)'),
        re.compile(r'\bmv\b\s+.*?([^\s;&|<>]+)\s*(?:[;&|\n]|$)'),
        re.compile(r'\bdd\b[^|;&\n]*\bof=([^\s;&|<>]+)'),
        re.compile(r'\binstall\b\s+.*?([^\s;&|<>]+)\s*(?:[;&|\n]|$)'),
    ]
    any_write_op = bool(HEREDOC_HEADER_RE.search(command)) or bool(WT_CONTENT_RE.search(command)) or bool(OPEN_CONTENT_RE.search(command))
    for rgx in OTHER_WRITE_RES:
        for m in rgx.finditer(command):
            any_write_op = True
            raw_tgt = m.group(1)
            cand = literal_target_or_none(raw_tgt)
            hit = False
            if cand is not None:
                rel = repo_rel(cand)
                if rel is not None and FRONT_RECORD_RE.match(rel) and rel not in determined_rels:
                    hit = True
            elif TREE_HINT in command:
                hit = True
            if hit:
                ambiguous_tree_hit = True
    if re.search(r"\.\s*write_(?:text|bytes)\s*\(", command) and not WT_CONTENT_RE.search(command):
        any_write_op = True
        if TREE_HINT in command:
            ambiguous_tree_hit = True
    if re.search(r"\bopen\s*\([^)]*,\s*['\"][wxa][^'\"]*['\"]\s*\)", command) and not OPEN_CONTENT_RE.search(command):
        any_write_op = True
        if TREE_HINT in command:
            ambiguous_tree_hit = True

    if not any_write_op:
        allow()  # no recognized write idiom at all — not this gate's concern

    if ambiguous_tree_hit:
        deny(
            "a Bash write reaches (or may reach, given an unresolvable target or content) the "
            "owned front-record path docs/reports/records/<subject>/product.md, and this gate "
            "could not literally determine both the target and the resulting content. Per the "
            "frozen fail-closed contract "
            "(docs/proposals/2026-07-26-scope-record-gate-bash-bypass.md), an indeterminate Bash "
            "write into the front record is refused rather than allowed through — use Write/Edit, "
            "or make the target and content fully literal."
        )

    for subject, abs_path, new_text in determined:
        new_state = loop_state_of(new_text)
        if new_state != "scope-approved":
            continue
        try:
            with open(abs_path, encoding="utf-8-sig") as fh:
                disk = fh.read(1 << 20)
        except OSError:
            disk = None
        old_state = loop_state_of(disk)
        if old_state == "scope-approved":
            continue  # already approved; idempotent rewrite, no new human signal needed
        require_token_and_consume(root, subject)

    allow()

# ---------------------------------------------------------------------------
# Write/Edit/MultiEdit/NotebookEdit path (unchanged from before this fix).
# ---------------------------------------------------------------------------
target = tool_input.get("file_path") or tool_input.get("notebook_path")
if not isinstance(target, str) or not target:
    deny("tool call has no usable file_path/notebook_path (fail-closed).")

root = resolve_root(target)
if not root:
    deny("no project root could be determined (fail-closed).")

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

m = FRONT_RECORD_RE.match(rel)
if not m:
    allow()
subject = m.group(1)

abs_path = posixpath.join(root, rel)

def read_disk():
    try:
        with open(abs_path, encoding="utf-8-sig") as fh:
            return fh.read(1 << 20)
    except OSError:
        return None

if tool == "Write":
    content = tool_input.get("content")
    if not isinstance(content, str):
        deny("Write call on the front record has no string content (fail-closed).")
    new_text = content
elif tool == "Edit":
    old_string = tool_input.get("old_string")
    new_string = tool_input.get("new_string")
    if not isinstance(old_string, str) or not isinstance(new_string, str):
        deny("Edit call on the front record is missing old_string/new_string (fail-closed).")
    disk = read_disk()
    if old_string == "":
        new_text = new_string
    else:
        if disk is None:
            deny("Edit call on the front record but the on-disk file could not be read (fail-closed).")
        if old_string not in disk:
            deny("Edit call's old_string was not found verbatim in the front record (fail-closed).")
        new_text = disk.replace(old_string, new_string,
                                (10**9 if tool_input.get("replace_all") is True else 1))
elif tool == "MultiEdit":
    edits = tool_input.get("edits")
    if not isinstance(edits, list) or not edits:
        deny("MultiEdit call on the front record has no usable edits list (fail-closed).")
    disk = read_disk()
    text = disk if disk is not None else ""
    for e in edits:
        if not isinstance(e, dict):
            deny("MultiEdit call has a non-object edit entry (fail-closed).")
        o_ = e.get("old_string"); n_ = e.get("new_string")
        if not isinstance(o_, str) or not isinstance(n_, str):
            deny("MultiEdit edit missing old_string/new_string (fail-closed).")
        if o_ == "":
            text = n_; continue
        if o_ not in text:
            deny("MultiEdit old_string not found verbatim at the point it is applied (fail-closed).")
        text = text.replace(o_, n_, (10**9 if e.get("replace_all") is True else 1))
    new_text = text
else:
    # Tool-agnostic default-deny (docs/proposals/2026-07-26-scope-record-gate-tool-agnostic.md):
    # any tool not named above (NotebookEdit today, anything else tomorrow) is
    # judged by whether its payload exposes a recognizable content-bearing
    # field aimed at the front record — never by tool name. If a literal
    # resulting text can be extracted, it is checked exactly like a Write's
    # content. If it cannot, that is "may set the gated approved state" per
    # the fail-closed rule, and the call is refused outright — there is no
    # remaining branch here that resolves to allow() for an indeterminate
    # write to the front record.
    def _generic_content(ti):
        for key in ("content", "new_source", "text", "data"):
            v = ti.get(key)
            if isinstance(v, str):
                return v
        cells = ti.get("cells")
        if isinstance(cells, list):
            parts = []
            for c in cells:
                if not isinstance(c, dict):
                    continue
                src = c.get("source") if "source" in c else c.get("new_source")
                if isinstance(src, str):
                    parts.append(src)
                elif isinstance(src, list) and all(isinstance(x, str) for x in src):
                    parts.append("".join(src))
            if parts:
                return "\n".join(parts)
        return None

    generic_content = _generic_content(tool_input)
    if generic_content is None:
        deny(
            "tool '%s' targets the front record docs/reports/records/%s/product.md but this "
            "gate cannot literally determine the resulting content from its payload shape "
            "(fail-closed): a tool call whose effect on the gated scope-approved transition "
            "cannot be determined is refused, never allowed by default." % (tool, subject)
        )
    new_text = generic_content

new_state = loop_state_of(new_text)
if new_state != "scope-approved":
    allow()  # this write does not set scope-approved — not this gate's concern

old_state = loop_state_of(read_disk())
if old_state == "scope-approved":
    allow()  # already approved; idempotent rewrite, no new human signal needed

require_token_and_consume(root, subject)
allow()
PY
