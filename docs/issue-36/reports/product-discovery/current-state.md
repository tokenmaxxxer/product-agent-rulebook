---
kind: report
subject: issue-36
role: product-discovery
---

# Current-state survey — issue #36

Scope: what this repo's `product` rulebook already encodes about
discovery methodology and deliverable norms, and what is thin, missing,
or contested, ahead of a phase-1 proposal.

## What already exists

- `product/hooks/directive.sh` (role directive, sourced from core canon
  via `core_role_directive`) already names: assumption-mapping across
  desirability/viability/feasibility/usability/ethical categories on a
  critical-x-weak-evidence 2x2; a one-pager lens for the phase-1 current
  state (problem stated without a solution attached); a pre-registered
  hypothesis package (named metric, numeric threshold, decision rule,
  non-empty guardrails, pre-committed ITWWS) as the phase-1 proposal
  shape; and a phase-2 verdict defined as mechanical application of the
  registered rule, with must-meet criteria as binary knockouts. This is
  already close to Torres/hypothesis-testing orthodoxy for the
  *validation* stage.
- Skills shipped: `hypothesis-testing`, `assumption-mapping`,
  `one-pager`, `opportunity-solution-tree`, `guardrail-metrics`
  (`product/skills/*/SKILL.md`).
- `docs/README.md` documents that `docs/proposals/` doubles as both
  this repo's own change-proposal directory and the carrier for
  `product-cycle` hypothesis-state specs (`status: idle -> ... ->
  decided`, distinguished from proposals by the presence of
  `metric`/`threshold`/`decision_rule` fields).
- `docs/reports/research/2026-07-25-swpd-roles/product-discovery.md`
  is a broad SWPD-roles survey (PM/PO/BA/PMM/Growth-PM boundaries,
  artifacts, handoffs, gates) that already touches OST, PR/FAQ, Shape
  Up, RICE/WSJF/Kano, and dual-track agile at a role-comparison level,
  but was written to map *roles and handoffs*, not to prescribe this
  rulebook's own required proposal/deliverable structure.

## What is thin, missing, or contested

- **No named methodology for the phase-1 "current-state survey"
  itself** beyond "one-pager lens." No explicit tie to JTBD (job
  performer / job / circumstance / desired outcome) or to a Kano-style
  need classification — both are common vocabulary for framing the
  *opportunity* half of discovery, upstream of the hypothesis package.
- **No explicit Opportunity Solution Tree artifact requirement.**
  `docs/reports/opportunity-tree.md` is named in the directive as a
  standing doc this role owns, but no proposal/record norm requires
  citing or updating it, nor specifies its required components
  (outcome / opportunities / solutions / assumption tests).
- **No prioritization-scoring requirement.** Neither RICE nor ICE nor
  any explicit scoring method is referenced anywhere in `product/` or
  `docs/`, despite this being one of the most standardized, citable
  parts of product-discovery practice (used to justify *why this
  opportunity/solution over others*, which the current directive does
  not ask for).
- **Citation/evidence format is under-specified.** The directive says
  "evidence means customer signal... never opinion" but does not
  specify what counts as a citable record of that evidence in a
  proposal document (interview count, quote attribution, date, method)
  — contested territory since JTBD/Mom-Test practice and Lean
  Startup/Torres practice diverge somewhat on how much interview
  method detail belongs in the artifact itself vs. a separate research
  log.
- **No record-fields gate/required-fields document was found in this
  repo** (`find . -iname "record-fields*"` returned nothing) — unlike
  `docs/issue-37/`'s companion `implementation` role, which has core
  canon gates (`record-fields-gate.sh`) referenced explicitly. This
  role's phase-2 record enforcement currently rests entirely on prose
  in `directive.sh` ("YOUR RECORD... do not skip this"), not a
  structural gate, which is a plugin-reflection gap this proposal's
  part (d) must address.
- **No explicit "problem without a solution attached" enforcement
  mechanism** beyond directive prose — this is exactly the kind of
  drift issue-33's "strengthen record enforcement wording" pattern
  (see `docs/issue-33/proposals/`) suggests should eventually become a
  gate rather than a directive-only ask.

## Implication for phase 1

The existing directive is strong on the *validation* stage (hypothesis
package, guardrails, mechanical verdict) but thin on the *discovery/
opportunity-framing* stage (JTBD-style problem framing, OST as a
required, structured artifact, and a citable evidence/prioritization
format). The phase-1 proposal should therefore focus on filling that
opportunity-framing gap without duplicating or contradicting the
hypothesis-testing discipline already encoded.
