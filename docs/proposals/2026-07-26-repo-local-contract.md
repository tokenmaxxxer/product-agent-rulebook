---
status: landed
files:
  - README.md
  - product-cycle/hooks/state-gate.sh
---

## Intent

The handoff contract holds only within a single git repository. This rulebook is a plugin: it will be installed into and pointed at a real work repo, and today's sibling-directory layout under `tokenmaxxxer/` is only the development setup, not a structural fact the gate may rely on. Any gate logic that reaches outside its own repo — walking up parent directories, referencing the root `tokenmaxxxer` checkout, comparing against another repo's git history — is structurally wrong. That is exactly what broke the SHA-pin check added in commit 9eec5ab (and siblings cfd2fc8/7096485/5ca4f59/f07a6da across the other rulebooks): in this repo it silently no-ops rather than actually enforcing anything, which is worse than doing nothing because it reads as a passing gate. This proposal replaces that check with a rule the gate can honor from a standalone clone.

## Constraints

- The gate may resolve exactly one root: the git root of the session's current working directory.
- It may read only `docs/specs/role-handoff-contract.md` inside that root.
- No parent-directory walk, no reference to `tokenmaxxxer`, no comparison to another repo's git history or SHA.
- Absence of the contract file is an honest failure, not a silent pass.

## What will be done

- `product-cycle/hooks/state-gate.sh`: delete the SHA-pin check and any parent/sibling-repo lookup added in the previous round. Replace with: resolve the current repo's git root, check for `docs/specs/role-handoff-contract.md` there, and if absent, refuse handoff-protocol actions with the message "this repo has no collaboration contract yet" rather than proceeding.
- `README.md`: rewrite the "Handoff protocol" excerpt to drop the pinned-SHA header line. State instead that the authoritative contract is the work repo's own `docs/specs/role-handoff-contract.md`, and that this section describes only how the product role behaves against whatever contract the work repo carries.

## Out of scope

- The other five rulebooks (coding, qa, feasibility, ops, review).
- The root `tokenmaxxxer` repo itself.
- The `warrant` and `doctrine` plugins.

## How you'll know it worked

`grep -r "tokenmaxxxer" product-agent-rulebook/product-cycle/hooks/` returns nothing, and running `state-gate.sh` from a standalone clone of `product-agent-rulebook` (outside the `tokenmaxxxer` sibling layout) behaves identically to running it from the nested layout: same pass/fail outcome given the same presence/absence of `docs/specs/role-handoff-contract.md`.

## What did not work

`product-cycle/hooks/run-gate-tests.sh` (out of this proposal's write set, not modified) now fails 7 of its 13 cases after the build: every case that exercises a state.md transition in this checkout, because this repo has no `docs/specs/role-handoff-contract.md` of its own, so the new repo-local contract check correctly denies those handoff-protocol writes per rule 2. This is the frozen rule working as specified, not a regression introduced by this build — but it does mean product-cycle's state machine is non-functional in this dev checkout until a `docs/specs/role-handoff-contract.md` is added here, which is out of scope for this proposal (write set is exactly `README.md` and `product-cycle/hooks/state-gate.sh`).
