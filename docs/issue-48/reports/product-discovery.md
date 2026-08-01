# Record — issue #48 (gate A+ final closeout, re-audit B+)

kind: execution-record
loop_state: decided
hypothesis: docs/issue-48/proposals/2026-08-01-gate-a-plus-final-closeout.md

## Outcome

Outcome: gate A+ final closeout landed — every re-audit residual named in
issue #48 is fixed.
Opportunity-solution tree: the branch that was pruned by issue #45's own
record (`decided`, no open findings) got a re-audit that found new
residuals; this closeout promotes that same branch back to `decided` with
those residuals fixed — no new opportunity or candidate solution opened.
Disposition: promoted — every item in the approved proposal landed and
verified; nothing pruned, nothing deferred.

## What was done

1. **`||`-guarded the `gate-lib.sh` source line, all 5 gates**
   (`product-one-pager`, `product-opportunity-solution-tree`,
   `product-assumption-mapping`, `product-hypothesis-testing`,
   `product-guardrail-metrics`). Applied core #75's landed shape verbatim:
   `. ".../gate-lib.sh" || { echo "<plugin>: cannot source gate-lib.sh" >&2; exit 2; }`.
   Failure path changed from silent-continue (undefined `gate_*`
   functions, fail-open) to `exit 2` (fail-closed) when
   `CLAUDE_PLUGIN_ROOT_CORE` is unreachable.
2. **Matcher wired to the code that already ships, all 5 `hooks.json`**:
   `PreToolUse.matcher` is now `Write|Edit|MultiEdit|Bash` on all 5, plus
   `|NotebookEdit` on the 3 gates whose `tool_name` branches already
   handle it (`product-one-pager`, `product-opportunity-solution-tree`,
   `product-hypothesis-testing`). No gate code changed — this only closed
   the shipped-but-unwired gap.
3. **`진행`/`actioned` bare-substring fallbacks removed**, in
   `product-hypothesis-testing/hooks/methodology-gate.sh`:
   `has_decision_rule`'s bare `re.search(r'진행|중단|피벗', t)` fallback
   deleted (the explicit-label and section+threshold-co-occurrence
   branches around it already carry the discipline); the `actioned`
   ITWWS-follow-up check no longer matches `actioned|진행함` anywhere in
   the document — it now requires the match to co-occur with an
   ITWWS-labeled marker inside the same paragraph (the same adjacency
   shape `has_itwws` is built on), via `paragraphs(text)` +
   `has_itwws(para)`.
4. **`tests/parse-check.sh` default path dropped.** `dir` is now a
   required positional argument (`[ $# -ge 1 ] || { usage; exit 2; }`);
   the dead `../product/hooks` fallback (this repo has no `product`
   plugin) is gone. Every documented call site (`README.md`'s "Run the
   checks") already passes an explicit path, so no real usage regressed.
5. **Mandatory missing-core case added to all 5
   `tests/product-*-gate-tests.sh`**: `CLAUDE_PLUGIN_ROOT_CORE` pointed at
   a nonexistent path, no valid relative fallback reachable → gate must
   exit 2 (deny), not 0 (allow). This is the regression test that would
   have caught item 1 before this issue existed, and is the dynamic
   counterpart to `compliance-check.sh`'s static unguarded-source
   detector (core #75).

README/manifest: verification only, no edit — re-confirmed 0 residue
against issue #48 requirement #4 (see Verification below); the only hit
for the old gate names is `docs/handbooks/tests.md`'s own historical note
explaining that `record-fields-gate.sh`/`trailer-gate.sh` never existed
in this tree and were removed by issue #45 — not a live reference.

## Why

Common items applied core #75's confirmed guard/rule by reference, not
re-derived locally, per issue #48 requirement #1 and the proposal's own
non-goals (no facet redesign, no `gate-lib.sh`/`gate-lib.py` edits — those
are core's files). The `진행`/`actioned` fix reused issue #45's own
precedent (explicit label first, else section-anchored paragraph
co-occurrence) rather than adding a second, weaker matching path for
Korean text.

## Decision rule and threshold

Decision rule: go (execute and land as proposed) if `tests/run-gate-tests.sh`
pass count (all 5 plugin suites plus `compliance-check.sh` against each of
the 5 `hooks/` dirs) hits the threshold by direct, unreduced suite run;
kill/revise the approach (not the underlying requirement) if any
`hooks.json` matcher change broke an existing passing case, or if the
`진행`/`actioned` fix could not be made section-anchored without breaking
an existing well-formed fixture.
Threshold: 100% pass rate, 0 failures, 0 skipped mandatory case groups,
`compliance-check.sh` clean 5/5, `parse-check.sh` clean 5/5 under its new
required-argument contract.
Measured: threshold met — 123/123 total cases passed across the 5 suites
(20 + 23 + 26 + 28 + 26), 0 failed, all 5 suites carry the new
`missing-core-denies` case (`ok ... deny`), `compliance-check.sh` clean
5/5, `parse-check.sh` clean 5/5 (all 5 explicit `<hooks-dir>` invocations
pass; the no-arg invocation now correctly exits 2 with a usage message
instead of silently resolving a dead default). Decision: go — landed.
ITWWS: applying core #75's landed guard shape by reference (rather than
re-deriving a local fix) worked cleanly here — actioned already: this
record itself is the instance of that pattern (item 1 above is a verbatim
adoption, not a local re-derivation), confirming by-reference-adoption
should stay the default move whenever a future core-canon fix lands after
a rulebook's own remediation already shipped.

## Guardrails

Guardrail: no regression in any of the 118 previously-passing cases
across the 5 suites (issue #45's landed baseline). Status: not breached —
all 118 original cases still pass; the count grew to 123 by the addition
of the 5 new `missing-core-denies` cases only.
Guardrail: no gate begins denying a `Write`/`Edit`/`MultiEdit` case that
passed before this closeout. Status: not breached — the matcher widening
only added `Bash`/`NotebookEdit` coverage; every previously-matched
`Write`/`Edit`/`MultiEdit` case's outcome is unchanged (confirmed by the
guardrail above: 0 regressions among the 118 original cases).

## Verification

`bash tests/run-gate-tests.sh` — all 5 plugin suites green (20+23+26+28+26
= 123 cases passed, 0 failed) — plus core's `compliance-check.sh` run
against each of the 5 plugins' `hooks/` directories, all clean:

    compliance-check: ok — product-one-pager/hooks/methodology-gate.sh
    compliance-check: ok — product-opportunity-solution-tree/hooks/methodology-gate.sh
    compliance-check: ok — product-assumption-mapping/hooks/methodology-gate.sh
    compliance-check: ok — product-hypothesis-testing/hooks/methodology-gate.sh
    compliance-check: ok — product-guardrail-metrics/hooks/methodology-gate.sh

    run-gate-tests: all 5 plugin suites + compliance-check.sh passed

`bash tests/parse-check.sh <dir>` clean on all 5 plugins' `hooks/`
directories (each: `ok methodology-gate.sh`, `2 file(s)` under `/bin/bash`
bash-3.2 parse); `bash tests/parse-check.sh` with no argument now exits 2
with `parse-check: usage: parse-check.sh <hooks-dir>` (new required-arg
contract, item 4).

README/manifest re-audit: `grep -n "record-fields-gate\|trailer-gate\|product/hooks"
README.md` — zero hits; the same grep across `docs/` finds only
`docs/handbooks/tests.md`'s historical note (quoted above) describing a
fix already landed in issue #45, not a live ghost reference. Issue #48
requirement #4 (README/manifest: 0 residue, old names hard-error) holds.

## Next steps

None — this record is terminal (`decided`). A future rulebook-wide drift
back to an unguarded `gate-lib.sh` source, an unwired `hooks.json`
matcher, or a bare-substring Korean fallback is what
`compliance-check.sh` (wired into `tests/run-gate-tests.sh`) and this
record's own regression cases exist to catch, not a next step here.

## Open findings

None outstanding against the approved proposal's scope. Open-finding
resolution path: not applicable — there are no open findings to resolve.
