---
kind: proposal
subject: issue-36
role: product-discovery
---

# Product-discovery methodology and deliverable norms — issue #36

Full findings backing this proposal:
`docs/issue-36/reports/product-discovery/current-state.md` and
`docs/issue-36/reports/product-discovery/scout-brief.md`.

Phase 1 only — this document proposes norms; no plugin code is
changed here, and this document contains no approval of any kind.
Phase 2 (encoding these norms into `product/hooks/directive.sh` and a
record-fields gate) requires an Approve per contract v3 s19 from an
account listed in `docs/specs/approvers.md`.

## (a) Phase-1 proposal norms

**Methodology**: JTBD-style problem framing plus assumption-mapped,
pre-registered hypothesis testing (the latter already encoded; this
proposal adds the former as a required upstream step). Concretely:
every phase-1 current-state survey must state the problem as a
(job performer, job, circumstance, desired outcome) tuple *before* any
solution is named, per JTBD's four-element framework — restating the
issue's own words if the issue text already embeds a solution.

**Required sections** for a phase-1 document under
`docs/issue-<n>/reports/<role>/` and `docs/issue-<n>/proposals/`:

1. Problem framing (JTBD tuple), solution-free.
2. Opportunity Solution Tree excerpt or update — outcome, the specific
   opportunity/opportunities under consideration, candidate solutions,
   and the assumption test(s) that will discriminate between them
   (OST's four canonical layers). Only the relevant branch needs to be
   shown, not the whole standing tree.
3. Evidence citations (see format below).
4. When more than one opportunity or solution candidate is compared: a
   RICE score per candidate (Reach, Impact, Confidence, Effort, and
   the resulting score), or, only when reach data is genuinely
   unavailable, an explicitly-flagged ICE score as substitute.
5. The pre-registered hypothesis package (already required by the
   existing directive: named metric, numeric threshold, decision rule,
   guardrails, ITWWS) — unchanged by this proposal.
6. Open questions / explicitly out-of-scope items (borrowed narrowly
   from PRD convention, not the full PRD shape).

**Evidence/citation format**: for each cited data point, one line
giving interview/observation count, approximate date range, and a
short paraphrase — e.g. "3 interviews, 2026-07, users described
manually re-exporting the report weekly." Full transcripts or raw
notes stay in a separate research log if one exists; the proposal
itself carries only the paraphrase-plus-provenance line. Stated
preference or hypothetical ("would you use X") response is not
admissible evidence, consistent with the existing Mom-Test framing in
`directive.sh`.

## (b) Phase-2 deliverable norms

**Methodology**: the phase-2 record is the mechanical verdict against
the phase-1 pre-registered rule (already the case) plus an updated
Opportunity Solution Tree reflecting the outcome of the assumption
test(s) that were run (pruned branch on kill, promoted branch on
go/pivot).

**Required components** of `docs/issue-<n>/reports/product.md`
(this role's existing record path, per `directive.sh`):

1. `kind` and `loop_state` fields (already required).
2. The verdict, stated as the mechanical application of the
   pre-registered decision rule to the measured metric value — the
   metric's measured value must be quoted next to the threshold it is
   compared against.
3. Guardrail-metric status at the same measurement moment (already
   required by the directive's guardrail language; this proposal adds
   that the record must state it explicitly, not just imply it).
4. The Opportunity Solution Tree update: which branch was pruned or
   promoted, in the same four-layer vocabulary as the phase-1
   artifact.
5. The pre-committed ITWWS follow-up, either actioned or explicitly
   deferred with a reason.

## (c) Rationale per adoption choice

- **JTBD problem framing**: adopted because it is the most
  standardized, citable way to enforce "problem before solution,"
  which the current directive already gestures at ("PROBLEM STATED
  WITHOUT ANY SOLUTION ATTACHED") but does not operationalize into a
  checkable shape. JTBD's four-element tuple gives that shape without
  requiring new tooling — it is a writing discipline, not a new
  artifact type.
- **OST four-layer structure as a required shape**: adopted because
  this role already *names* `docs/reports/opportunity-tree.md` as a
  standing document it owns (per the existing directive), but nothing
  currently requires that file, or a proposal excerpt from it, to
  actually be structured as outcome/opportunities/solutions/tests.
  Requiring the shape closes a gap between what the directive already
  claims this role does and what is actually enforced — the value is
  intended already; this is enforcement catching up to intent.
- **RICE over ICE as the default prioritization method**: adopted
  because this repo's existing hypothesis-package requirement already
  commits to defensible, numeric pre-registration over informal
  judgment (named metric, numeric threshold — not "we think this is
  important"). RICE is the prioritization-framework analogue of that
  same value: a numeric, stakeholder-defensible score rather than an
  ICE-style quick gut-check. ICE is kept as an explicitly-flagged
  fallback rather than dropped entirely, because reach data is
  sometimes genuinely unavailable at very early discovery and refusing
  any scoring in that case would regress behind current (score-free)
  practice.
- **Interview-evidence citation format (count + date + paraphrase)**:
  adopted because the current directive requires "customer signal...
  never opinion" but supplies no way to check compliance from the
  document alone. A minimal, non-transcript citation line makes the
  requirement auditable without imposing the overhead of a full
  research-log format on every proposal.
- **PRD scope-boundary section only (not full PRD)**: adopted narrowly
  because the "out of scope / open questions" section is the one part
  of PRD convention this repo's existing one-pager lens does not
  cover, and it is cheap to add. The rest of the ten-section PRD
  template is explicitly not adopted (see scout-brief.md "Skip") —
  it would contradict the repo's existing lightweight-document
  philosophy and the well-documented staleness critique of full PRDs.
- **PR/FAQ and Shape Up pitch: not adopted**: both are gate artifacts
  built for an organizational shape (executive review panel, betting
  table) this single-role rulebook does not have; adopting either
  would import a governance structure this repo has no counterpart
  for, rather than a methodology this role can apply solo.
- **WSJF: not adopted**: portfolio/cross-team scope; RICE already
  covers the single-role, single-backlog prioritization case this
  rulebook needs.

## (d) Plugin-reflection plan

Target files (phase 2, not touched by this proposal):
`product/hooks/directive.sh`, and a new `product/hooks/` gate (or an
extension of core's `record-fields-gate.sh` via
`RECORD_FIELDS_TERMINAL_STATES`-style env configuration, following the
pattern already used elsewhere in this repo per
`docs/issue-37/proposals/2026-07-31-core-canon-reference-migration.md`).

1. **`directive.sh` — `use_when` block**: add the JTBD tuple
   requirement and the OST four-layer requirement to the existing
   `CURRENT-STATE SURVEY` paragraph, alongside the existing "problem
   stated without a solution attached" line.
2. **`directive.sh` — `produces` block**: add the RICE/ICE
   prioritization requirement and the evidence-citation format
   (count/date/paraphrase) to the existing `PROPOSAL` paragraph,
   alongside the existing hypothesis-package requirement.
3. **`directive.sh` — `hand_off` block**: add the OST-update
   requirement (pruned/promoted branch) and the explicit
   guardrail-status-statement requirement to the existing
   `EXECUTION JUDGMENT` paragraph.
4. **Record-fields gate**: this repo currently has no
   `record-fields-gate.sh` of its own (confirmed absent in
   current-state.md) and phase-2 record enforcement rests entirely on
   directive prose. Phase 2 should evaluate whether to source core's
   canon `record-fields-gate.sh` (matching the pattern issue #37
   already established for this repo's sibling `implementation` role)
   with `RECORD_FIELDS_TERMINAL_STATES` set to this role's terminal
   `loop_state` vocabulary (`decided`, `scope-proposed`), rather than
   inventing a new bespoke gate. This is a structural fix, not new
   content — it converts an already-stated intent ("YOUR RECORD do not
   skip this") into an enforced field check, closing the gap this
   proposal's current-state survey identified.
5. **No change to `hooks.json`** is anticipated beyond whatever the
   record-fields gate wiring in (4) requires — this proposal does not
   touch trigger/matcher scope.

Phase 2 requires an Approve per contract v3 s19 from an account in
`docs/specs/approvers.md` before any of the above is executed.
