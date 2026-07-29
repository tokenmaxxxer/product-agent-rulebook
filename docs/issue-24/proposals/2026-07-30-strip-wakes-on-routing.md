# Proposal: strip WAKES-ON routing restatement, repoint to on-the-record

files: product/hooks/directive.sh (lines 57-64, "YOUR RECORD IS THE BOARD" section)

## Request (paraphrased)
Wake-routing ownership migration step 3: this rulebook must contain
nothing about which role wakes next on which state. Audit every
WAKES-ON/wake mention in the repo's rulebook files (excluding
docs/issue-*), keep this role's own record-state/format language, strip
or repoint anything that names which role a state summons to
docs/specs/wake-routing.md (the on-the-record canon as of operator
decision 2026-07-30; core contract §3's routing table was removed via
tokenmaxxxer-core#36).

## Constraints
- Only the "YOUR RECORD IS THE BOARD" section in
  product/hooks/directive.sh is in scope (see survey.md — the other
  grep hit is a merged historical proposal record, not live rulebook).
- Keep: record path (docs/issue-<n>/reports/product.md), "write it as
  your FIRST act of phase 2" rule, loop_state-update-at-every-transition
  requirement — these describe this role's own record, not routing.
- Strip/repoint: "WAKES-ON reads ... ONLY" and "no downstream role can
  ever be woken by it" — these name which role a state summons.
- No other file changes; no behavior/gate changes; text-only edit.

## What will be done
Replace the routing-naming sentences with a pointer to
docs/specs/wake-routing.md, preserving the record-format guidance,
mirroring the wording already reviewed (and functionally accepted, sans
process) in PR #25's diff for this same section elsewhere in the repo:

```
YOUR RECORD IS THE BOARD (do not skip this): docs/issue-<n>/reports/product.md
is this role's execution-surface record; research files, surveys, and
proposals are not. Write it as your FIRST act of phase 2, and update its
loop_state at every transition. Wake routing (which record wakes which
role, and on what state) is canon at on-the-record docs/specs/wake-routing.md
— this rulebook does not restate it. Ending phase 2 without your record
committed on the branch means the board never saw your work.
```

(Note: `product/hooks/directive.sh` is the *product* role's directive,
not coding's own — issue #24 was filed against this repo's rulebook as a
whole and this is the only in-scope routing restatement found. If a
parallel issue targets coding's own directive text, that is out of scope
here since no WAKES-ON/wake mention exists in coding's own hook.)

## Out of scope
- docs/proposals/2026-07-26-contract-v2-conformance.md (historical,
  merged, quotes the old contract for record purposes only).
- Any execution (the actual file edit) — this proposal is phase-1 only
  and waits for human APPROVE per contract v3 §19.

## How you'll know it worked
- `grep -rn -i wake product/hooks/directive.sh` no longer matches
  "WAKES-ON" or "wake up"/"woken by" — only the repoint sentence
  mentioning docs/specs/wake-routing.md remains.
- Record-format guidance (path, first-act rule, loop_state update)
  still present, unchanged in substance.
