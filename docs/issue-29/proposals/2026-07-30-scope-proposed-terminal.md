# Proposal — align board-facing terminal loop_state with the pre-approval gate

files: `README.md`, `product/hooks/record-fields-gate.sh`,
`tests/run-gate-tests.sh`

## Request (paraphrased intent)

The pre-approval gate outside this repo opens coding's first build only
when the front product record reaches `scope-approved`, raised by a
human from `scope-proposed`. This rulebook's declared `loop_state`
vocabulary never produces `scope-proposed`, so no record this role
writes can ever open that gate. Make the rulebook's board-facing
terminal state `scope-proposed`; keep `scope-approved` strictly
human-only and out of rulebook vocabulary; make the gate's `TERMINAL`
set match what the record actually writes.

## Constraints

- `scope-approved` must never appear as a state this role writes or is
  told to write.
- `decided` may remain as an internal pre-terminal state (non-front
  records still terminate there); a front record additionally reaches
  `scope-proposed`.
- The `record-fields-gate.sh` open-work check (next-steps backlog +
  resolution path) must not fire on a `scope-proposed` record.

## What will be done

- `README.md`: rewrite the `## Record vocabulary` paragraph so the
  front-record terminal is `decided` / `scope-proposed`; add one
  sentence stating `scope-approved` is the human-only accept state the
  external pre-approval gate raises a `scope-proposed` record to, never
  written by this role, never part of this vocabulary.
- `product/hooks/record-fields-gate.sh`: change
  `TERMINAL = {"decided", "scope-approved"}` to
  `TERMINAL = {"decided", "scope-proposed"}`.
- `tests/run-gate-tests.sh`: add a `record-scope-proposed` case
  asserting a well-formed `loop_state: scope-proposed` record is
  allowed without a backlog/resolution-path section.

## Out of scope

- The external pre-approval gate itself (`wake-routing.md`, `wakes.py`)
  — owned on-the-record, not here.
- Actually raising any record to `scope-approved` — that is a human PR
  act, never performed by this role (Phase 1 of this issue stops after
  the proposal PR; no APPROVE is issued by this session).
- `hypothesis-testing/SKILL.md`'s `status: decided` field — a distinct
  per-hypothesis-file field, not the front-record `loop_state`.

## How you'll know it worked

- `tests/run-gate-tests.sh` passes, including the new
  `record-scope-proposed` allow case.
- `README.md`'s vocabulary section states the terminal as `decided` /
  `scope-proposed` and never lists `scope-approved` as rulebook
  vocabulary.
