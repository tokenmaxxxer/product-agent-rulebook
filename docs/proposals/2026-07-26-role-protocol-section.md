---
status: landed
files:
  - README.md
  - product-cycle/hooks/state-gate.sh
---

# Role protocol section for product

## Intent

A product session today has to read the full shared
`docs/specs/role-handoff-contract.md` to find its one accepted input kind
and its three output kinds among six roles' worth of rows. This proposal
adds a "Handoff protocol" section to `README.md` carrying only product's
rows, so the session reads one page scoped to its own role.

## Constraints that change what gets built

- Excerpt only, from `docs/specs/role-handoff-contract.md` at
  `2affe5db7dfb285abaa2860d3004edb3f97c9aec` (root `tokenmaxxxer` repo) —
  product's rows from sections 2, 3, and 7, plus its reading of sections 1,
  4, and 5 (subject minting, since product is the role most often first to
  open a chain).
- The section header pins that SHA; `product-cycle/hooks/state-gate.sh`,
  which already gates product-cycle state transitions, gains a check that
  refuses to proceed when the pinned SHA no longer matches the contract's
  current SHA.
- Per-role path ownership (section 7) is enforced by this same gate, since
  warrant's write-set gate deliberately does not constrain writes under
  `docs/` and section 7 assigns that enforcement to each rulebook. This
  matters concretely for product because it shares `docs/proposals/` with
  coding (section 7's filename-tag disambiguation:
  `<date>-<slug>.md` for product vs `<date>-build-<slug>.md` for coding).

## What will be done

Add "Handoff protocol" to `README.md` with four parts:

1. **ACCEPTS** — `feasibility-record` (to react to a verdict on a prior
   hypothesis); refuses `build-proposal`, `qa-state`, `review-record`,
   `ops-state`.
2. **WHERE UPSTREAM LIVES** —
   `docs/reports/records/<subject>/feasibility.md` for `feasibility-record`.
3. **PRODUCES** — `hypothesis` at `docs/proposals/<date>-<slug>.md`,
   required fields: role status
   (`idle,scoping,researching,hypothesis-registered,measuring,decided`),
   plus the common header including `handoff_status`; `one-pager` at
   `product/one-pager.md`, required fields: Background/Context, Problem
   Statement, Candidate Hypotheses, Known Risks, Goals/Success Metrics (all
   non-empty); `opportunity-tree` at `product/opportunity-tree.md`,
   continuous interview log, no fixed state field.
4. **STOPS** — upstream stale at role entry (recorded `sha` for the
   `feasibility-record` path against its current `sha`); an existing
   record already at a path product does not own under
   `docs/reports/records/` or `docs/proposals/` (refuse, report, never
   overwrite — including checking the `<date>-build-<slug>.md` filename
   tag before assuming a slot in `docs/proposals/` is free); input carrying
   `handoff_status: provisional` when product is not permitted to treat it
   as final baseline.

Also add the SHA-pin check to `product-cycle/hooks/state-gate.sh`.

## Out of scope

Changing `docs/specs/role-handoff-contract.md`. Changing warrant's
`scope-gate.sh` (not present in this repo). The other five rulebook repos.
Starting any product-cycle build work.

## How you will know it worked

A product session can answer, from `README.md` alone, what kind it
accepts, where to find it, what it produces and where (all three kinds),
and its three stop conditions. `state-gate.sh` refuses to proceed when the
pinned SHA no longer matches the contract's current SHA, and refuses a
write to a path product does not own.
