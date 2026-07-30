---
kind: coding-record
subject: issue-33
role: coding
loop_state: done
code_under_review: 0b9daa8
---

# Coding record — issue #33

## What was done
Appended the two proposed sentences to the `YOUR RECORD` block's closing
sentence in `product/hooks/directive.sh`, byte-for-byte per the
proposal. No other line changed.

## Why
Issue #33 asks to raise the `YOUR RECORD` section's wording in
`product/hooks/directive.sh` to the strong form already used by sibling
rulebooks (ux-design-rulebook reference), per the approved proposal.

## Upstream basis
- Proposal: `docs/issue-33/proposals/2026-07-30-strengthen-record-enforcement-wording.md`
- Approval: PR #34 comment by JiwonJung94 (approvers.md member): `APPROVE issue-33/coding`

## Scope
Append the enforcement clause + measured-evidence citation to the
`YOUR RECORD` block's closing sentence in `product/hooks/directive.sh`.
Single-file, wording-only change; no other section touched.

## closed_checks
- syntax: `bash -n product/hooks/directive.sh` passes, code_sha 0b9daa8
- grep: both required strings present, code_sha 0b9daa8
- diff-scope: `git diff` shows only the two added sentences, no other line changed, code_sha 0b9daa8

## What did not work
(none yet)

## Open findings
(none yet)

## Next steps
Apply the edit, verify with `bash -n` and the grep check from the
proposal's "How it'll know it worked" section, then update loop_state to
done and commit.

## Open-finding resolution path
No open findings currently block this work; none pending.
