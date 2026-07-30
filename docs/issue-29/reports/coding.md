---
subject: issue-29
role: coding
loop_state: scope-proposed
---

upstream: docs/issue-29/proposals/2026-07-30-scope-proposed-terminal.md

## What was done

Implemented the approved proposal (PR #30, MERGED) verbatim:
- `README.md`: rewrote the `## Record vocabulary` paragraph so the
  front-record terminal is `decided` / `scope-proposed`, and added a
  sentence stating `scope-approved` is the human-only accept state the
  external pre-approval gate raises a `scope-proposed` record to, never
  written by this role.
- `product/hooks/record-fields-gate.sh`: changed
  `TERMINAL = {"decided", "scope-approved"}` to
  `TERMINAL = {"decided", "scope-proposed"}`.
- `tests/run-gate-tests.sh`: added `record-scope-proposed`, asserting a
  well-formed `loop_state: scope-proposed` record is allowed without a
  backlog/resolution-path section.

Ran `bash tests/run-gate-tests.sh`: 8 passed, 0 failed (new case included).

## Why

Matches the pre-approval gate's actual watched state (on-the-record
`wake-routing.md`, `wakes.py`), per the approved proposal; no
alternative considered since the proposal already fixed the design.

## What did not work

Nothing — proposal's write set applied without deviation.

## Closed checks

- `record-scope-proposed` gate-test case: confirmed the new terminal
  value is allow'd without an open-work backlog, on this record's own
  code_sha.

## Next steps

None — write set from the approved proposal is complete.

## Open finding resolution path

None open.
