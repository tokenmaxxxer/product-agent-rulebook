---
kind: proposal
subject: issue-27
role: coding
---

# Build proposal — issue #27

files: `product/hooks/directive.sh`

## Request (paraphrased intent)
Strip routing-side vocabulary (wake, board-as-routing-device, WAKES-ON,
downstream roles, pointers to `wake-routing.md`) from this rulebook,
restating record obligations purely as record-format requirements: path,
kind, loop_state vocabulary, required fields, write the record first in
phase 2, update loop_state on every transition, commit on branch.
Historical docs untouched.

## Constraints
- Only `product/hooks/directive.sh` is in scope (confirmed by the
  survey's repo-wide sweep — no other current file carries the swept
  terms).
- Keep all record-format substance the current block already states:
  record path, first-act-of-phase-2 timing, loop_state-update-on-every-
  transition, commit-on-branch requirement.
- Remove: the "YOUR RECORD IS THE BOARD" routing framing in the heading,
  the "Wake routing ... is canon at on-the-record docs/specs/wake-
  routing.md" pointer sentence, and the "the board never saw your work"
  consequence framing.
- Do not touch `docs/issue-24/**` or any other historical tree.
- Phase 1 only: this proposal stops here: no code edit lands until a
  human APPROVE.

## What will be done
Replace the block currently at `product/hooks/directive.sh:57-63` with a
version that:
1. Retitles the heading away from "board" framing (e.g. "YOUR RECORD").
2. States the record path and that it is this role's execution-surface
   record (as opposed to research/survey/proposal files).
3. States it must carry a `kind` field and a `loop_state` field using
   this role's defined vocabulary, plus whatever required fields the
   record format specifies.
4. States it is written as the first act of phase 2, and `loop_state` is
   updated at every transition.
5. States the record must be committed on the branch — dropping the
   "board never saw your work" / wake-routing-pointer language entirely,
   with no replacement pointer to any routing doc.

## Out of scope
- Anything under `docs/issue-24/` or other historical issue trees.
- Any change to `docs/specs/`, `product/skills/`, or other hook files —
  the survey found no routing-vocabulary hits there.
- Redefining what `loop_state` values or required record fields actually
  are — this issue only removes routing framing, it does not change the
  record schema.

## How it'll know it worked
- `grep` for `WAKES-ON|wake-routing|board-as-routing|downstream role|the
  board|routing is canon|\bwake\b|\bwoken\b` across the repo (excluding
  historical `docs/issue-*/reports|proposals`) returns no hits.
- `bash -n product/hooks/directive.sh` still passes (valid shell).
- The record-format substance (path, first-act-of-phase-2, loop_state-
  update, commit-on-branch) is still present and legible in the block.
