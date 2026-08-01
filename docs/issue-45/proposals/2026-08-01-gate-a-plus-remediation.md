# Proposal — gate A+ remediation (issue #45)

Phase 1 proposal only. No code changes in this PR. Full defect basis:
`docs/issue-45/reports/product-discovery/current-state.md`. Canon basis:
`docs/issue-45/reports/product-discovery/scout-brief.md` (core issue #72,
landed).

## Scope

All 5 `product-*/hooks/methodology-gate.sh` gates, `tests/run-gate-
tests.sh`, `tests/product-*-gate-tests.sh` (5 files), `README.md`.

## 1. Adopt `gate-lib.sh` / `gate-lib.py` by reference, not copy

Each gate script sources `gate-lib.sh` per the canon's own usage
comment:

    . "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"
    gate_trap_fail_closed
    set -uo pipefail
    gate_kill_switch_active "${<PLUGIN>_GATE_OFF:-}" || { trap - EXIT; exit 0; }
    ...
    gate_deny "<plugin>" "reason"   # or gate_allow

Each gate's Python heredoc imports `gate-lib.py` via
`importlib.util.spec_from_file_location` against `os.environ["GATE_LIB_
PY"]` (exported by `gate-lib.sh`), then calls:
- `gate_lib.gate_parse_json_or_deny(raw, deny)` in place of the current
  per-gate hand-rolled `json.load` + `except` shape.
- `gate_lib.gate_normalize_path(root, path)` in place of each gate's own
  `case "$abs_path" in "$root"/*) ...` shell-level strip.
- `gate_lib.gate_reconstruct_write(tool, tool_input, current_content)`
  in place of each gate's own `apply_edit`/heredoc reconstruction —
  this also gains NotebookEdit cell-source coverage for free, closing a
  gap no gate has today.

`CLAUDE_PLUGIN_ROOT_CORE` resolution: fall back to `$CLAUDE_PLUGIN_ROOT/
../core` when unset, matching the pattern already used for
`CLAUDE_PROJECT_DIR` resolution in these gates today — exact fallback
chain to be finalized during execution against however core's own
gates resolve it, not invented fresh here.

Never vendor a copy of either file. Execution-phase test additions
(§4) must include a `compliance-check.sh`-style check (or literally
invoke core's own, per gate-house-standard.md's invocation snippet) so
a future drift back to a hand-rolled kill switch or reconstruct is
caught, not just fixed once.

## 2. Deny-JSON escaping — explicit decision

The 5 gates currently return a JSON `hookSpecificOutput.
permissionDecisionReason` body over stdout (exit 2), not `gate_deny`'s
plain-stderr-only shape. Canon's `gate_deny` does not itself construct
this JSON body. Decision: **keep the structured JSON body** (Claude
Code's PreToolUse protocol reads it for a richer denial UI than plain
stderr), but replace every gate's unescaped
`printf '...":"%s"}}\n' "$1"` with the `json.dumps`-escaped shape
`product-guardrail-metrics/hooks/methodology-gate.sh:13-17` already
uses correctly — i.e. this repo standardizes internally on its
own-already-correct pattern for the 4 gates that lack it, while still
adopting `gate_deny`'s message-construction discipline (name-prefixed
reason text) as the convention for what goes inside that escaped
string. This is not a deviation from core: `gate_deny` governs message
delivery, not the JSON-vs-stderr framing choice, which is out of
gate-lib's stated scope.

## 3. Semantic check upgrade: substring → section/adjacency/structure

Applies to all 5 gates' facet checks, using
`product-one-pager/hooks/methodology-gate.sh`'s JTBD check as the
template case (current-state.md §3). Replace bare `.search()` keyword
presence with:

- **Section anchoring**: marker words must be matched under a heading
  that itself names the facet (e.g. a `## ` or `**`-labeled line
  matching `(?i)circumstance|job\s*performer|desired\s*outcome`),
  not anywhere in free prose. A markdown-heading walk (split on `^#{1,6}
  \s` / bold-label lines, associate each marker match with its nearest
  preceding heading) replaces the flat `lower.search(...)`.
- **Adjacency**: within a matched section, require the marker word and
  its value to co-occur within one paragraph (blank-line-delimited
  block), not merely both appear somewhere in the document — closes the
  "circumstance-notes.md" / "desired outcome of that meeting" false
  positives named in the survey.
- **Structure**: prefer an explicit label:value line shape
  (`^\s*(circumstance|job performer|desired outcome)\s*:` per line)
  as the primary match; fall back to the section-anchored paragraph
  match only when no explicit label line exists, so a well-formed
  survey with clean labels is never penalized relative to today's
  looser check.

Each gate's own facet semantics (JTBD tuple, OST branch vocabulary,
guardrail non-emptiness, hypothesis pre-registration fields — whichever
applies) keeps its own vocabulary; only the matching mechanism
(keyword-anywhere → section+adjacency+structure) changes, uniformly
across all 5.

## 4. Mandatory test cases (execution phase, all 5 gates)

Per gate-house-standard.md's six-case harness, adapted per plugin:
1. `Edit` with `replace_all: true` against a multiply-occurring
   `old_string`.
2. `MultiEdit` with mixed `replace_all: true`/`false` edits in one
   call.
3. Malformed JSON: truncated, non-object top level, empty payload —
   3 sub-cases, deny in all 3.
4. Kill switch set to an unrecognized value (e.g. `"maybe"`) — assert
   gate stays **active** (was previously silently-disabling for the OST
   gate; now must be a green regression test against exactly that
   history, not just a forward-looking case).
5. Absolute `file_path` matching the same scope a relative-path fixture
   already matches, plus a `./`-prefixed variant.
6. A `Bash`-tool command writing to the same target a `Write`-tool call
   would reach (via `gate_bash_write_targets`) — new coverage class, ties
   to survey's open gap ("no Bash-tool write-target coverage exists in
   any of the 5 gates").

Plus, per-gate, a semantic-upgrade regression pair for §3: one case
that must now DENY under the new section/adjacency check but would have
false-positive ALLOWed under the old substring check (the "circumstance-
notes.md" style false positive), and one case confirming a genuinely
well-formed document still ALLOWs.

`tests/run-gate-tests.sh` is rewritten (not patched) to point at the 5
real `product-*/hooks/methodology-gate.sh` paths and drop every
reference to `record-fields-gate.sh`/`trailer-gate.sh`, which do not
exist in this tree (survey §5). Full suite must be green at delivery
(issue requirement #3).

## 5. README realignment

Rewrite `README.md` to describe this repo's actual shape: role
`product-discovery`, 5 `product-*` plugins each owning one
`hooks/methodology-gate.sh`, per-plugin kill switches (table of the 5
`<PLUGIN>_GATE_OFF` names), record at
`docs/issue-<n>/reports/product-discovery.md`, real test commands
(`tests/run-gate-tests.sh` plus each `tests/product-*-gate-tests.sh`).
Drop every reference to the `product` role, `product-agent-rulebook`,
`PRODUCT_CYCLE_OFF`, and the three nonexistent hook files (survey §6).

## Non-goals

- No change to what each gate's methodology facet actually requires
  (JTBD tuple, OST vocabulary, etc.) — only how it is checked and what
  machinery it is checked with.
- No new gates, no new facets.
- No change to `docs/issue-42/proposals/2026-07-31-methodology-gate-
  machine.md`'s design (gate-machine architecture) — this is a hardening
  pass on the existing machine, not a redesign.

## Approval

Phase 1 stops here. Execution (adopting gate-lib, rewriting the 5
gates + test files + README, running the full suite green) begins only
after an approvers.md account's Approve on this PR, per contract v3
s19.
</content>
