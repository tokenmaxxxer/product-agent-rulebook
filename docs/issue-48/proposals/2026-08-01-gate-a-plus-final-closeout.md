# Proposal — gate A+ final closeout (issue #48, re-audit B+)

Phase 1 proposal only. No code changes in this PR. Full defect basis:
`docs/issue-48/reports/product-discovery/current-state.md`. Upstream
prerequisite basis: `tokenmaxxxer-core` commit `f61d52f` (issue #75,
landed) and `on-the-record` commit `e50fe08` (issue #182, landed).

## Scope

All 5 `product-*/hooks/methodology-gate.sh`, all 5 `product-*/hooks/
hooks.json`, `product-hypothesis-testing/hooks/methodology-gate.sh`'s
decision-rule/ITWWS check specifically, `tests/parse-check.sh`, all 5
`tests/product-*-gate-tests.sh`. README/manifest: verification only, no
edit (survey §6 — already clean).

## 1. `||`-guard the `gate-lib.sh` source line, all 5 gates

Apply core #75's exact landed shape verbatim, per gate:

    . "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh" || { echo "<plugin>: cannot source gate-lib.sh" >&2; exit 2; }

`<plugin>` is each gate's own name prefix (matches its existing `deny()`
message-prefix convention). No other line on the source-and-guard
statement changes — same `CLAUDE_PLUGIN_ROOT_CORE` fallback chain as
today, only the failure path changes from silent-continue (undefined
function, fail-open) to `exit 2` (fail-closed).

## 2. Wire the matcher to the code that already ships

Per gate, `hooks.json`'s `PreToolUse.matcher` becomes
`"Write|Edit|MultiEdit|Bash"` for all 5 (Bash-write-target coverage is
universal), plus `|NotebookEdit` for the 3 gates that handle it
(`product-one-pager`, `product-opportunity-solution-tree`,
`product-hypothesis-testing`). No gate code changes — this closes the
shipped-but-unwired gap (survey §2) by matching `hooks.json` to what each
gate's own `tool_name` branch already accepts, nothing more.

## 3. Section/adjacency fix for the `진행`/`actioned|진행함` substring checks

`product-hypothesis-testing/hooks/methodology-gate.sh`'s
`has_decision_rule` (line 187) and the `actioned` check (line 244) both
lose their bare `.search(r'진행|중단|피벗', t)` / `.search(r'actioned|
진행함', text)` fallback. Applying issue #45's own precedent (explicit
label line first, else section-anchored paragraph match — never bare
keyword-anywhere):

- `has_decision_rule`: the existing explicit-label branch
  (`^\s*(decision[\s-]?rule)\s*:\s*\S.*\b(go|kill|pivot)\b`) and the
  existing section+threshold-co-occurrence branch (heading matching
  `decision|verdict|rule|hypothesis`, paragraph containing
  `go|kill|pivot` AND `threshold|metric|기준`) already exist in this same
  function and are structurally sound — the fix is deleting the bare
  `진행|중단|피벗` fallback between them, not adding new matching logic.
  A Korean-language decision rule must satisfy the same
  section+co-occurrence discipline as an English one; it never gets a
  separate, weaker bare-substring path.
- `actioned`/ITWWS-actioned check: replace `re.search(r'actioned|진행함',
  text, re.IGNORECASE)` with the same "co-occurs with `ITWWS` inside one
  paragraph" adjacency shape `has_itwws` itself already uses one function
  up — an "actioned" claim only counts when it appears inside the
  ITWWS-labeled section/paragraph, not anywhere in the document.

## 4. `parse-check.sh` default path

Decision: drop the dead default entirely rather than repoint it at a
guessed aggregate. `dir="${1:-...}"` becomes a required positional
argument (`[ $# -ge 1 ] || { echo "parse-check: usage: parse-check.sh
<hooks-dir>" >&2; exit 2; }`), removing the `/../product/hooks` fallback.
Rationale: this file is distributed verbatim to every rulebook in the
`tokenmaxxxer` org per its own header comment ("distributed to every
rulebook the way deny-only-check.sh is") — a per-repo-correct default
would need per-repo customization on every distribution, defeating the
verbatim-copy contract; every documented call site (README's "Run the
checks") already passes an explicit path, so no real usage regresses.

## 5. Mandatory missing-core case, all 5 `tests/product-*-gate-tests.sh`

Per core #75's `run-gate-lib-tests.sh` group-7 shape, add one case per
plugin: `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path, no valid
relative fallback reachable → gate must exit 2 (deny), not 0 (allow).
This is the regression test that would have caught item 1 before this
issue existed, and is what `compliance-check.sh`'s new detector
(core #75) checks statically — the dynamic case here checks the runtime
behavior the static detector predicts.

## Non-goals

- No change to what each gate's methodology facet actually requires
  (JTBD tuple, OST vocabulary, evidence citations, hypothesis fields,
  guardrail non-emptiness) — issue #48 requirement #1 explicitly scopes
  common items to core #75's confirmed guard/rules applied by reference,
  not a facet redesign.
- No README/manifest edit — survey §6 confirms zero residue against
  issue #48 requirement #4; the PR carries the confirming grep output in
  the record, not a no-op diff.
- No change to `gate-lib.sh`/`gate-lib.py` themselves — those are core's
  own files, referenced not vendored, already fixed upstream.

## Pre-registered hypothesis

Metric: `tests/run-gate-tests.sh` pass count (all 5 plugin suites plus
`compliance-check.sh` against each of the 5 `hooks/` dirs) plus the new
missing-core case group present in all 5 suites.
Threshold: 100% pass rate, 0 failures, 0 skipped mandatory case groups,
`compliance-check.sh` clean 5/5 (in particular its issue-75-landed
unguarded-source detector), `parse-check.sh` clean 5/5 under its new
required-argument contract.
Decision rule: go (execute and land as proposed) if the threshold is met
by direct, unreduced suite run at delivery; kill/revise this proposal's
approach — not the underlying requirement — if any of the 5
`hooks.json` matcher changes breaks an existing passing case (regression
signal that the matcher scope is broader than the survey's tool_name
read established) or if the `진행`/`actioned` fix (item 3) cannot be made
section-anchored without breaking an existing well-formed fixture that
relied on the bare substring.
ITWWS: if applying core #75's landed guard shape by reference (rather
than re-deriving a local fix) works cleanly here, we should expect this
same by-reference-adoption pattern to be the default move whenever a
future core-canon fix lands after a rulebook's own remediation already
shipped — pre-committed for the execution-phase record to action or
explicitly defer with a reason.

## Guardrails

Guardrail: no regression in any of the 118 previously-passing cases
across the 5 suites (issue #45's landed baseline) — status is stated
explicitly, not implied, at record time (measured value adjacent to
this threshold, per the hypothesis-testing facet's own requirement).
Guardrail: no gate begins denying a `Write`/`Edit`/`MultiEdit` case that
passed before this closeout (the matcher widening in item 2 only adds
`Bash`/`NotebookEdit` coverage; it must not change any already-matched
event's outcome).

## Approval

Phase 1 stops here. Execution (landing items 1-5, running the full
suite including the new missing-core cases, confirming README/manifest
stay clean) begins only after an approvers.md account's Approve on this
PR, per contract v3 s19.
</content>
