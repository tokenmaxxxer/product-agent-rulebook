---
kind: survey
subject: issue-33
role: coding
---

# Current-state survey — issue #33

## Scout skip record
Skip condition: pure textual/wording-strength edit inside a single
already-known file, spec literally leaves no open design decision (the
issue names the exact two sentences to add, verbatim, and the exact
section to leave otherwise unchanged). Scouting skipped for this reason.

## Write set
Single file: `product/hooks/directive.sh` — the `YOUR RECORD` section
(lines 57-63), this repo's only rulebook directive source.

## Findings
Current text (`product/hooks/directive.sh:57-63`):

```
YOUR RECORD (do not skip this): docs/issue-<n>/reports/product.md is this
role's execution-surface record; research files, surveys, and proposals
are not. It carries a `kind` field and a `loop_state` field using this
role's defined vocabulary, plus whatever required fields the record
format specifies. Write it as your FIRST act of phase 2, update its
loop_state at every transition, and end phase 2 only once it is
committed on the branch.
```

The section already states the commit-on-branch requirement but stops
short of the strong-form enforcement + evidence-citation pattern the
issue asks for. Confirmed no such enforcement clause or measured-evidence
citation currently exists anywhere in this file (`grep -n "never written\|Measured:" product/hooks/directive.sh` returns nothing).

This session's own `coding` role directive (a different rulebook, not in
this repo) already carries the target strong form as reference: "Ending
phase 2 without your record committed on the branch means the obligation
is unmet. (Measured: a phase-1-only issue left no record committed.)" —
confirming the pattern issue #33 asks to port in is a real, already-used
idiom, just with wording specific to this repo's `product` role per the
issue body's exact quotes.

`docs/specs/wake-routing.md` / the referenced `ux-design-rulebook` repo
are not present in this repo and are not needed — the issue supplies the
exact two sentences to add verbatim.

## Prior related work
Issues #24 and #27 previously edited this same section (stripping
"board"/routing framing). Issue #33 is unrelated in direction — it adds
enforcement-strength wording, not routing — and does not conflict with
either prior edit's outcome.
