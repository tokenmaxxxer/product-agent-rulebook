---
kind: survey
subject: issue-27
role: coding
---

# Current-state survey — issue #27

## Scout skip record
Skip condition: pure textual/vocabulary edit inside a single already-known
file, spec literally leaves no open design decision (the issue names the
exact phrases to remove and the exact substance to preserve). Scouting
skipped for this reason.

## Write set
Single file: `product/hooks/directive.sh` (the `product` role's rulebook
directive, this repo's only rulebook source).

## Findings

A repo-wide sweep for routing vocabulary (`WAKES-ON`, `wake-routing`,
`board-as-routing`, `downstream role`, `the board`, `routing is canon`,
`wake`/`waking`/`woken`) across all tracked files, excluding
`docs/issue-*/reports` and `docs/issue-*/proposals` (historical, out of
scope per the issue), turned up exactly one hit outside those excluded
trees:

- `product/hooks/directive.sh:57-63` — the "YOUR RECORD IS THE BOARD"
  block. It currently:
  - Names the record path and phase-2-first-act / loop_state-update
    obligations (record-format substance — keep).
  - Also says "Wake routing (which record wakes which role, and on what
    state) is canon at on-the-record docs/specs/wake-routing.md — this
    rulebook does not restate it" (routing pointer — issue says this
    must go too, not just be repointed).
  - Also says "Ending phase 2 without your record committed on the
    branch means the board never saw your work" (board-as-routing-device
    framing — must go).
  - Heading itself, "YOUR RECORD IS THE BOARD", asserts the record IS a
    routing device — must be reworded to a neutral heading.

No other file in the repo (specs, skills, gate hook comments, plugin
manifest/description files, tests) contains any of the swept terms
outside the historical issue-24 trees. `docs/specs/wake-routing.md` is
not present in this repo (it lives in on-the-record's repo, per the
issue text) — nothing to touch there.

## Prior related work
Issue #24 (commits `f7024ce`→revert→`0df2f36`→`61603e0`) previously
touched this exact block, but only repointed the routing sentence to
`docs/specs/wake-routing.md` rather than removing the routing framing
outright. Issue #27 supersedes that outcome: the routing pointer itself
must be dropped, restating obligations purely in record-format terms
(path, kind, loop_state vocabulary, required fields, write-first-in-
phase-2, update-on-every-transition, commit-on-branch) with no mention
of wake, board, or downstream readers.
