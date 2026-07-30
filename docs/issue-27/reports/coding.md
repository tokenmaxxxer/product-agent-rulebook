# Issue #27 — coding record

upstream: docs/issue-27/proposals/2026-07-30-strip-routing-vocabulary.md (PR #28, approved via issue comment `APPROVE issue-27/coding`, single-account mode, contract v3 §19)

loop_state: phase-2-complete

## What was done
Applying the approved proposal exactly: replacing `product/hooks/directive.sh:57-63`'s
"YOUR RECORD IS THE BOARD" block with a pure record-format restatement —
record path, first-act-of-phase-2 timing, loop_state-update-on-every-
transition, commit-on-branch requirement — dropping the "board" heading
framing, the wake-routing.md pointer sentence, and the "board never saw
your work" consequence framing. No other file in the repo carries the
swept routing terms outside historical `docs/issue-24/**`, per the
phase-1 survey.

## Why
No alternative was weighed here — this executes an already-approved,
already-scoped proposal verbatim (contract v3 §19 phase-2 execution).

## closed_checks
- routing-vocab-grep-scope (code_sha: pre-edit, product/hooks/directive.sh) —
  confirmed via survey.md that this file is the only in-scope live
  rulebook hit; `docs/issue-24/**` is historical, out of scope.

## What did not work
(none yet — will append at time of failure if any occurs)

## Next steps
Apply the edit, verify with `grep -rn 'WAKES-ON|wake-routing|board-as-routing|downstream role|the board|routing is canon|\bwake\b|\bwoken\b' product/hooks/directive.sh` returns nothing, `bash -n product/hooks/directive.sh`, commit, push, update loop_state to phase-2-complete.

## Resolution path
No open findings against this record. If verify or another role raises
one, it will be logged here as resolved_findings once addressed and the
finder re-clears, per the blocking-finding gate.
