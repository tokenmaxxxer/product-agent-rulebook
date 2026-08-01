# Record — issue #45 (gate A+ remediation)

loop_state: decided
hypothesis: docs/issue-45/proposals/2026-08-01-gate-a-plus-remediation.md

## Outcome

Outcome: gate reliability restored to A+ across all 5 `product-*` gates.
Disposition: promoted — every remediation item in the approved proposal
landed and verified; nothing pruned.

## What was done

Executed the approved proposal in full against all 5
`product-*/hooks/methodology-gate.sh` gates:

1. **gate-lib adoption by reference** — every gate now sources
   `core/hooks/lib/gate-lib.sh` and imports `gate-lib.py` via
   `os.environ["GATE_LIB_PY"]` (core issue #72 canon), replacing each
   gate's own hand-rolled kill switch, JSON parse, path normalization, and
   Write/Edit/MultiEdit reconstruction. No vendored copy of either file
   exists in this tree.
2. **Confirmed defects fixed**: `product-opportunity-solution-tree`'s
   fail-open kill switch (unrecognized value used to disable the gate,
   now stays active via `gate_kill_switch_active`); the dead
   `and False` ternary in `product-one-pager`; unescaped deny JSON in
   `product-one-pager`/`product-opportunity-solution-tree`/
   `product-assumption-mapping` (now `json.dumps`-escaped, uniform across
   all 5); `record-fields-gate.sh`/`trailer-gate.sh` references in
   `tests/run-gate-tests.sh` (files that never existed in this tree) —
   rewritten to dispatch the 5 real plugin suites.
3. **New coverage, all 5 gates**: `replace_all` now honored per-edit via
   `gate_reconstruct_write` (was silently first-occurrence-only in 3 of
   5 gates); NotebookEdit reconstruction (previously absent everywhere);
   Bash-tool write-target coverage via `gate_bash_write_targets` (a Bash
   redirect into a gate's own scope now fails closed instead of passing
   through unseen).
4. **Semantic check upgrade** — every facet check (JTBD tuple, OST
   vocabulary, evidence citations, decision rule, guardrail
   non-emptiness) moved from bare keyword-anywhere-in-document matching
   to a section/adjacency/structure discipline: an explicit
   `label: value` line first, else a marker word required to co-occur
   with its value inside a paragraph under a heading that itself names
   the facet. Each gate carries a regression pair proving the change:
   a false-positive fixture that would have wrongly ALLOWed under the
   old substring check now DENYs, and a well-formed labeled fixture
   still ALLOWs.
5. **Mandatory test cases, all 5 gates**: Edit `replace_all: true`
   against a multiply-occurring string; MultiEdit with mixed
   `replace_all`; 3 malformed-JSON sub-cases (truncated, non-object,
   empty); kill switch set to an unrecognized value (regression-tests
   the exact fail-open bug the OST gate had); absolute and
   `./`-prefixed path matching; a Bash-tool write reaching the same
   target a Write call would.
6. **README.md** rewritten to describe this repo's actual shape (5
   `product-*` plugins, no `product` role, kill-switch table, real test
   commands) — every ghost reference (`product-agent-rulebook`,
   `PRODUCT_CYCLE_OFF`, `record-fields-gate.sh`, `trailer-gate.sh`,
   `handbook-trigger-gate.sh`) removed.

## Why

The proposal's own decisions carried through unchanged: deny stays a
JSON `hookSpecificOutput` body (richer denial UI) with `gate_deny`'s
message-construction discipline, not a straight swap to plain-stderr;
`gate-lib.sh`/`gate-lib.py` referenced, never copied; no new gates, no
change to what each facet requires — only how it is checked.

## Decision rule and threshold

Decision rule: go if `tests/run-gate-tests.sh` (all 5 plugin suites plus
core's `compliance-check.sh`) is 100% green with no skipped mandatory
case group; kill/revise otherwise.
Threshold: 100% pass rate, 0 failures, all 6 mandatory case groups plus
the semantic-upgrade regression pair present per gate.
Measured: threshold met — 118/118 total cases passed (19 + 22 + 25 + 27
+ 25 across the 5 suites), `compliance-check.sh` clean 5/5, both
`parse-check.sh` clean 5/5. Decision: go — landed.
ITWWS: if this pattern (gate-lib-by-reference + section/adjacency
semantic checks) works cleanly here, we should expect every other
rulebook's own A+ remediation issue to follow the same shape rather than
re-deriving it — actioned already, since this migration reused the
sibling-rulebook precedent (`wcag-em-gate`) verbatim for the
`CLAUDE_PLUGIN_ROOT_CORE` resolution and test-harness auto-detection.

## Guardrails

Guardrail: no regression in previously-passing gate behavior across the
5 suites. Status: not breached — every case that passed before this
migration still passes after it (verified by running each suite's full,
unreduced case list, not just the new additions).
Guardrail: `compliance-check.sh` clean on all 5 plugins post-migration.
Status: not breached — clean on all 5.

## Verification

`bash tests/run-gate-tests.sh` — all 5 plugin suites green (19+22+25+27+25
= 118 cases passed, 0 failed) — plus core's `compliance-check.sh` run
against each of the 5 plugins' `hooks/` directories, all clean:

    compliance-check: ok — product-one-pager/hooks/methodology-gate.sh
    compliance-check: ok — product-opportunity-solution-tree/hooks/methodology-gate.sh
    compliance-check: ok — product-assumption-mapping/hooks/methodology-gate.sh
    compliance-check: ok — product-hypothesis-testing/hooks/methodology-gate.sh
    compliance-check: ok — product-guardrail-metrics/hooks/methodology-gate.sh

`tests/parse-check.sh` (bash 3.2 parse) passes on all 5 plugins' `hooks/`
directories. `tests/deny-only-check.sh` passes its no-`permissionDecision:
allow` scan on all 5; its substance probe (targeting a generic
`docs/issue-<n>/reports/product.md` path) is a pre-existing no-op in this
repo — no gate here claims that generic path, each fires only on its own
proposal/survey/record scope — not a regression from this work and out of
this issue's scope (proposal's non-goals: no change to what each gate's
facet requires).

## Next steps

None — this record is terminal (`decided`). No further action is planned
against this issue; a future rulebook-wide drift back to a hand-rolled
kill switch or reconstruct is what `compliance-check.sh`, now wired into
`tests/run-gate-tests.sh`, exists to catch, not a next step here.

## Open findings

None outstanding against the approved proposal's scope. Open-finding
resolution path: not applicable — there are no open findings to resolve.
