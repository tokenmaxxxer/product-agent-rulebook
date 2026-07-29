# Issue #24 — coding record

upstream: docs/issue-24/proposals/2026-07-30-strip-wakes-on-routing.md (PR #26, approved via issue comment `APPROVE issue-24/coding`, single-account mode, contract v3 §19)

loop_state: phase-2-complete

## What was done
Applying the approved proposal exactly: replacing the routing-naming
sentences in `product/hooks/directive.sh`'s "YOUR RECORD IS THE BOARD"
section (lines 57-64) with a pointer to docs/specs/wake-routing.md,
per operator decision 2026-07-30 and tokenmaxxxer-core#36. Keeping the
record path, "first act of phase 2" rule, and loop_state-update
requirement, which describe this role's own record and are not routing
statements.

## Why
No alternative was weighed here — this executes an already-approved,
already-scoped proposal verbatim (contract v3 §19 phase-2 execution).
The wording mirrors the proposal's own drafted replacement text so the
edit matches what was reviewed and approved.

## closed_checks
- wakes-grep-scope (code_sha: pre-edit, product/hooks/directive.sh) —
  confirmed via survey.md that this file is the only in-scope live
  rulebook hit; docs/proposals/2026-07-26-contract-v2-conformance.md is
  historical, out of scope.

## What did not work
(none yet — will append at time of failure if any occurs)

## Next steps
Apply the edit, verify with `grep -rn -i wake product/hooks/directive.sh`,
commit, push, update loop_state to phase-2-complete.

## Resolution path
No open findings against this record. If verify or another role raises
one, it will be logged here as resolved_findings once addressed and the
finder re-clears, per the blocking-finding gate.
