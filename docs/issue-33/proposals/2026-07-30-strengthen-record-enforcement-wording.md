---
kind: proposal
subject: issue-33
role: coding
---

# Build proposal — issue #33

files: `product/hooks/directive.sh`

## Request (paraphrased intent)
The `YOUR RECORD` section in this repo's `product` role directive states
the commit-on-branch requirement but lacks the strong enforcement clause
and measured-evidence citation that sibling rulebooks (referenced:
ux-design-rulebook's directive, post issue-12) already carry. Add both,
verbatim per the issue, without changing any existing role-specific
record fields (path, `kind`, `loop_state`, required-fields language).

## Constraints
- Only `product/hooks/directive.sh` is in scope.
- Existing record-format substance (path, first-act-of-phase-2 timing,
  loop_state-update-on-every-transition, commit-on-branch requirement)
  stays unchanged — this is a wording-strength addition, not a format
  change.
- Add exactly the two clauses named in the issue, adapted only to refer
  to "the record" generically (matching this section's existing style,
  which already says "it" rather than naming a specific role noun):
  1. Enforcement clause: "Ending phase 2 without your record committed
     on the branch means the record was never written."
  2. Evidence citation: "(Measured: a phase-1-only issue left the record
     empty.)"
- Phase 1 only: this proposal stops here; no code edit lands until a
  human APPROVE.

## What will be done
Replace the closing sentence of the `YOUR RECORD` block
(`product/hooks/directive.sh:61-63`, currently "Write it as your FIRST
act of phase 2, update its loop_state at every transition, and end phase
2 only once it is committed on the branch.") with:

"Write it as your FIRST act of phase 2, update its loop_state at every
transition, and end phase 2 only once it is committed on the branch.
Ending phase 2 without your record committed on the branch means the
record was never written. (Measured: a phase-1-only issue left the
record empty.)"

All other sentences in the block are left byte-for-byte unchanged.

## Out of scope
- Any other section of `product/hooks/directive.sh`.
- Any change to the record's required fields, `loop_state` vocabulary,
  or file path.
- Any file outside `product/hooks/directive.sh`.

## How it'll know it worked
- `grep -n "the record was never written\|Measured: a phase-1-only issue" product/hooks/directive.sh` returns both lines.
- `bash -n product/hooks/directive.sh` still passes.
- `git diff` shows only the two added sentences appended to the existing
  closing sentence — no other line changed.
