# Issue #24 — current-state survey (coding)

## Scope
Audit every WAKES-ON/wake mention in this repo's rulebook files (excluding
docs/issue-*), keep this role's own record-state/format statements, and
strip or repoint anything naming which role a state summons to the
on-the-record canon at docs/specs/wake-routing.md.

## Search
`grep -ril wakes . --exclude-dir=.git` (repo root) →

- `product/hooks/directive.sh` — live rulebook hook, in scope.
- `docs/proposals/2026-07-26-contract-v2-conformance.md` — a dated,
  merged historical proposal record (contract v2 migration). It quotes
  the old contract §3 WAKES-ON table as historical justification for a
  past decision, not a live routing statement enforced today. Per
  contract v3 doc-placement rules, proposals are historical records; out
  of scope for this strip (nothing to repoint — the surrounding routing
  table it references was already removed from the live contract via
  tokenmaxxxer-core#36).

## In-scope write set
- `product/hooks/directive.sh:57-64` — "YOUR RECORD IS THE BOARD" section.
  Currently states verbatim that `WAKES-ON reads docs/issue-<n>/reports/product.md
  ONLY` and that ending phase 2 without the record committed means "no
  downstream role can ever be woken by it" — both restate routing
  ownership (which role/state wakes on this record) that now lives at
  on-the-record `docs/specs/wake-routing.md` per operator decision
  2026-07-30 (core contract §3 table removed, tokenmaxxxer-core#36).

  Statements to KEEP (this role's own record format/state, not routing):
  record path (`docs/issue-<n>/reports/product.md`), "write it as your
  FIRST act of phase 2" rule, and the loop_state-update-at-every-transition
  requirement.

  Statements to STRIP/REPOINT: "WAKES-ON reads ... ONLY" and "no
  downstream role can ever be woken by it" — replace with a pointer to
  docs/specs/wake-routing.md as the routing canon.

## Prior attempt
PR #25 made exactly this edit but was refused because it skipped the
phase-1 propose → human-approve gate (contract v3 §19). This session
reverts that unapproved edit (commit 48585ca reverts f7024ce) and reruns
the issue through phase 1 only, per instruction.

## Scout
Skipped — pure mechanical text-scope-narrowing edit dictated by an
already-made operator decision (2026-07-30) and an already-merged core
contract change (tokenmaxxxer-core#36); no design decision is open.
