---
kind: scout-brief
subject: issue-36
role: product-discovery
---

# Scout brief — issue #36

## Must-bes (patterns nearly every credible source agrees on)

- **Problem before solution.** JTBD (job performer, job, circumstance,
  desired outcome) and OST both structurally forbid naming a solution
  before the opportunity/need is named. Already partially present in
  this repo's one-pager lens; not yet a hard requirement.
- **A structured, four-part discovery artifact, not free prose.** OST's
  four components — outcome, opportunities, solutions, assumption
  tests — recur across every source describing it (ProdPad, Product
  Talk, ProductPlan, Amplitude). This role already owns
  `docs/reports/opportunity-tree.md` by name but has no requirement
  that it actually contain these four typed layers.
- **Evidence from interviews/behavior, not stated preference.** JTBD
  and Continuous Discovery Habits both require interview-derived,
  past-behavior evidence over hypothetical/opinion signal — consistent
  with this repo's existing Mom-Test framing in `directive.sh`.
- **A named, numeric prioritization method when choosing among
  opportunities/solutions.** RICE (Reach x Impact x Confidence /
  Effort) and ICE (Impact x Confidence x Ease) are the two dominant,
  well-documented scoring conventions; RICE is preferred where the
  ranking needs to be defensible to stakeholders (adds Reach, divides
  by Effort), ICE where speed of early triage matters more than
  rigor.
- **PRD/brief-style artifacts need an explicit scope boundary.**
  Every PRD-template source surveyed (airfocus, monday.com, Pendo,
  Product Compass) converges on: problem/goal statement, success
  metrics, user/use-case definition, and an explicit out-of-scope /
  open-questions section — the last of which this repo's current
  directive does not name.

## Performance axes (where sources trade off, not just agree)

- **Rigor vs. speed**: RICE > ICE > pure "gut" prioritization in
  rigor/defensibility; the reverse in speed. WSJF sits alongside RICE
  for portfolio-level, cross-team framing (from the prior SWPD-roles
  survey) but is heavier still.
- **Document weight**: full PRD (durable, better for
  complex/regulated work, criticized for going stale) vs. lightweight
  brief/prototype-as-spec (Cagan: "the prototype serves as the spec
  for delivery") vs. PR/FAQ (narrative, executive-gated). This repo's
  existing one-pager already sits at the light end; no need to import
  a heavier PRD format wholesale.

## Adopt

- OST's four-layer structure as the *required* shape of
  `docs/reports/opportunity-tree.md` and as a required section of the
  phase-1 current-state survey when opportunities are being compared.
- JTBD-style problem framing (performer / job / circumstance / desired
  outcome) as a required subsection of the "problem stated without a
  solution attached" lens already named in `directive.sh`.
- RICE as the required prioritization method whenever a proposal
  ranks more than one opportunity or solution candidate (matches this
  repo's existing preference for defensible, numeric pre-registration
  over vibes — same philosophy as the existing hypothesis-package
  requirement). ICE permitted as an explicitly-flagged fast-triage
  substitute only when reach data is genuinely unavailable.
- An explicit interview-evidence citation format (count of interviews,
  approximate dates, and a one-line paraphrase per cited data point —
  not full transcripts) as the required evidence format for phase-1
  proposals, closing the "citation/evidence format is under-specified"
  gap noted in current-state.md.

## Skip

- Full PRD adoption (all ten-section template weight) — contradicts
  this repo's existing lightweight one-pager/hypothesis-package
  philosophy and the well-documented "PRDs go stale" critique; only
  borrow its out-of-scope/open-questions section, not the whole shape.
- PR/FAQ and Shape Up pitch formats — these are executive/betting-table
  gate artifacts for a different organizational context (single-PM or
  small-team discovery loop here has no betting table); not adopted.
- WSJF — portfolio/cross-team scope, heavier than this single-role
  rulebook needs; RICE/ICE cover the required case.

## Gap vs. current state

Confirms `current-state.md`: the hypothesis-testing/validation stage is
already well encoded; JTBD-style problem framing, the OST's four-layer
structure as an enforced shape, and a named prioritization method (RICE/
ICE) are the concrete gaps this proposal should fill. A record-fields
structural gate (vs. directive-prose-only enforcement) is the
plugin-reflection gap.

## Sources

- https://www.producttalk.org/opportunity-solution-trees/
- https://www.prodpad.com/glossary/opportunity-solution-tree/
- https://amplitude.com/blog/opportunity-solution-tree
- https://www.productplan.com/glossary/opportunity-solution-tree
- https://www.mindtheproduct.com/continuous-discovery-habits/
- https://strategyn.com/jobs-to-be-done/
- https://jobs-to-be-done.com/what-is-jobs-to-be-done-fea59c8e39eb
- https://agileseekers.com/blog/applying-jobs-to-be-done-jtbd-framework-to-tech-product-discovery
- https://airfocus.com/templates/product-requirements-document/
- https://www.pendo.io/product-led/artifacts/product-requirements-document-prd-template/
- https://www.productcompass.pm/p/prd-template
- https://kayako.com/blog/rice-prioritization/
- https://www.kaizenko.com/scoring-frameworks-ice-rice-and-weighted-scoring-for-product-prioritization/
- https://www.fygurs.com/blog/product-prioritization-frameworks-compared
- docs/reports/research/2026-07-25-swpd-roles/product-discovery.md (this
  repo's own prior SWPD-roles survey, consulted for OST/PR-FAQ/Shape
  Up/RICE/WSJF/dual-track background)
