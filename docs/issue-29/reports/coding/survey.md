# Current-state survey — issue #29

Scouting skipped: pure spec/vocabulary alignment bugfix, no product-shaped
design decision open — the target state (`scope-proposed` as board-facing
terminal, `scope-approved` out of vocabulary) is fully specified by the
issue and the external pre-approval gate it must match.

## Write set

- `README.md` — `## Record vocabulary` section (lines 40-46): declares
  `loop_state` values and terminal state.
- `product/hooks/record-fields-gate.sh` — `TERMINAL` set (line 230):
  which `loop_state` values are exempt from the open-work backlog
  requirement.
- `tests/run-gate-tests.sh` — gate test cases exercising `TERMINAL`.

## Findings

- The declared vocabulary (`README.md:42-44`) lists terminal as `decided`
  / `scope-approved`, but no rulebook-driven transition ever produces
  `scope-proposed` — the state the external pre-approval gate
  (on-the-record `wake-routing.md`, `wakes.py`) actually watches for
  before opening coding's first build. `scope-approved` is a human-only
  accept state raised externally from `scope-proposed`; it should never
  appear as rulebook-writable vocabulary.
- `record-fields-gate.sh:230` mirrors the same mismatch: `TERMINAL =
  {"decided", "scope-approved"}`. A record a product session can
  actually write never reaches `scope-approved` (only a human does that,
  outside this role), so that entry provides no real exemption; and
  `scope-proposed` — the state the role should reach and stop at — was
  missing, meaning a `scope-proposed` record was wrongly flagged as
  "leaves work open" (needing a next-steps backlog / resolution path it
  has no reason to carry).
- `hypothesis-testing/SKILL.md`'s `status: decided` is a distinct field
  on the hypothesis file (step 6 of the registration procedure), not the
  front-record `loop_state`; out of scope for this fix.

## Unknowns / left thin

- None — this is a two-file mechanical alignment; no open design
  question remains.
