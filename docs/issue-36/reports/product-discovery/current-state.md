---
kind: survey
subject: issue-36
role: product-discovery
---

# Current-state survey — issue #36

## Scope of this survey

Issue #36 asks this repo (the `product` rulebook, contract v3) to mature
its own phase-1 proposal norms and phase-2 deliverable norms for the
"product-discovery" domain — i.e. the RESEARCH / CURRENT-STATE SURVEY /
PROPOSAL / EXECUTION-JUDGMENT content this rulebook's `directive.sh`
already encodes for its subject issues, and the skills that back it. The
question is whether that content is grounded in real, citable discovery
methodology or asserted by convention, and where it is thin, missing, or
internally contested.

## What already exists

**Directive (`product/hooks/directive.sh`)** — a core-canon stub
(migrated under issue #37) sourcing four role-specific blocks:
- `you_decide`: value risk + business-viability risk (Cagan's four-risks
  framing), deliverable is a spec or a pre-registered kill record.
- `use_when`: RESEARCH names assumption-mapping (Teresa Torres's five
  categories: desirability/viability/feasibility/usability/ethical) on a
  critical-x-weak-evidence 2x2, plus the Mom Test's interview rules.
  CURRENT-STATE SURVEY names the one-pager lens (background, problem
  stated without a solution, candidate hypotheses, risks, goals/metrics).
- `produces`: PROPOSAL requires a pre-registered hypothesis package —
  named metric, numeric threshold, decision rule, guardrail metrics,
  ITWWS follow-up — fixed before any data collection.
- `hand_off`: EXECUTION JUDGMENT requires mechanical rule application,
  immutable threshold, binary must-meet knockouts vs. weighted
  should-meets, plus the record-enforcement clause (strengthened under
  issue #33).

**Skills (`product/skills/*/SKILL.md`)**, each state-scoped:
- `one-pager` (`scoping`): five-field sequence — background/context,
  problem statement (solution-free by construction), candidate
  hypotheses, known risks, goals/success metrics. Cites
  `docs/reports/research/2026-07-27-role-practice/product.md` for the
  Reforge/Lenny's shape.
- `assumption-mapping` (`researching`): five Torres categories, 2x2
  evidence-strength x importance plot, four assumption-test types
  (prototype test, one-question survey, data mining, engineering
  spike), plus the Mom Test's three interview rules as a standing
  directive.
- `hypothesis-testing` (`researching -> hypothesis-registered ->
  measuring -> decided`): pre-registration discipline — metric,
  threshold, decision rule fixed before data, threshold immutable once
  measuring starts, mechanical verdict application.
- `guardrail-metrics` (`hypothesis-registered`/`measuring`): a fourth
  required field alongside metric/threshold/decision_rule — metrics
  that must not move adversarially, with breach action named up front.
- `opportunity-solution-tree` (cross-cutting, `scoping -> scoping`
  self-loop): four-layer tree (desired outcome, opportunities, candidate
  solutions, assumption tests) maintained continuously, sourced to
  interview evidence, explicitly outside the state gate.

**Standing docs**: `product/one-pager.md`, `product/assumption-map.md`,
`product/opportunity-tree.md` — plain artifact writes, ungated.
`docs/specs/one-pager.md` and `docs/reports/opportunity-tree.md` are
named in the directive as continuously-owned standing docs (off the
issue cycle).

**Prior research already in-repo**,
`docs/reports/research/2026-07-25-swpd-roles/product-discovery.md`
(2026-07-25): a broad, sourced survey of PM/PO/BA/PMM/Growth-PM roles,
artifacts (PRD, product brief, OST, PR/FAQ, Shape Up pitch, user story
map, backlog items, roadmap, prototype-as-spec), handoff points
(dual-track "two tracks not two teams," discovery/delivery handoff
breakdowns), and gates (Definition of Ready, Shape Up betting table,
PR/FAQ review, prioritization frameworks named but only lightly sourced
— RICE formula flagged `[unsourced-primary]` in that pass, WSJF/Kano
noted but not adopted anywhere in this rulebook's directive or skills).
This file is available as prior grounding but its findings have not yet
been folded into `directive.sh` or any skill.

**Role-practice research**,
`docs/reports/research/2026-07-27-role-practice/product.md` and
`docs/reports/research/2026-07-27-role-interaction/product.md`: cited as
the basis for the one-pager field order, the three metric tiers
(primary/secondary/guardrail), and the "vague affirmation -> ask for
evidentiary source" interaction rule. Not re-read verbatim here since
their content is already load-bearing in the skills above; described,
not duplicated.

## What's thin, missing, or contested

- **Prioritization is absent from the directive/skills entirely.** The
  in-repo research names RICE, WSJF, and Kano as informal-gate
  frameworks, but nothing in `directive.sh` or any skill tells the role
  how to rank multiple candidate opportunities/solutions against each
  other once the OST has more than one live branch. The current
  pipeline goes straight from opportunity to hypothesis without a named
  prioritization step.
- **No Jobs-to-be-Done framing anywhere.** The Mom Test governs
  interview *conduct* (how to ask), but nothing governs interview
  *structure* for surfacing a job/switch story — JTBD's switch-interview
  method (push/pull/anxiety/habit forces) is a different, complementary
  layer this rulebook does not currently encode, even though
  assumption-mapping's "desirability" category is exactly the place a
  JTBD framing would slot in.
- **PRD/discovery-brief section norms are only partially represented.**
  The one-pager's five fields cover background, problem, hypotheses,
  risks, goals — but industry PRD/brief conventions commonly also carry
  target-audience/persona sections that are folded loosely into
  "goals/success metrics" here rather than broken out. Not necessarily
  wrong for this role's scope (a B2B/dev-tooling rulebook proposing
  specs, not writing full PRDs), but the current five-field list has
  not previously been checked against that broader standard.
- **Dual-track "two tracks, not two teams" discipline is implicit, not
  stated.** The directive's phase split (RESEARCH/SURVEY in phase 1,
  EXECUTION-JUDGMENT in phase 2) is itself a track split. The in-repo
  research explicitly flags this pattern as where handoffs break down
  when discovery and delivery are staffed as separate teams — this
  rulebook's phase-1/phase-2 human-approval gate is a different kind of
  split (same role, sequential phases, not separate teams), but nothing
  in the directive says so explicitly.
- **Design-thinking / Lean Startup are name-adjacent but not cited.**
  The assumption-mapping skill's four test types (prototype test,
  one-question survey, data mining, engineering spike) resemble Lean
  Startup's build-measure-learn and IDEO/d.school's prototype-and-test
  loop, but neither is cited as the source — the skill cites Torres's
  own five-category breakdown instead. A citation gap even where the
  practice itself looks sound.
- **No adoption record explaining *why* Torres/Cagan/Mom-Test/
  pre-registration were chosen over PR/FAQ, Shape Up, or a traditional
  PRD gate.** The in-repo research surveys multiple artifact families
  without recommending one — the current directive already picked
  continuous-discovery + dual-track + pre-registered hypothesis testing,
  but no proposal on file states the reasoning for that choice against
  the alternatives it did not pick. That reasoning is exactly what
  issue #36 asks the phase-1 proposal to supply.
- **No structural gate for evidence/format discipline.** `find . -iname
  "record-fields*"` under this repo's own tree returns nothing local
  (the gate now lives in core canon per issue #37's migration); this
  role's phase-2 record enforcement rests on `directive.sh` prose plus
  core's generic `record-fields-gate.sh`, not on any product-discovery-
  specific structural check — a plugin-reflection gap this proposal's
  part (d) should address.

## Constraints noted (per issue #36 and this task's own scope)

- warrant-hunter: not present in this repo (confirmed absent, consistent
  with issue #37's survey finding); nothing to reference here.
- Record discipline / documentation-obligation wording strengthened
  under issue #33 stays as-is; this survey does not propose touching it.
- Canon scripts (`core_role_directive`, the gate scripts under
  `core/hooks/`) are reference-only for this survey — described by
  behavior above, not quoted verbatim, per this task's own constraint.

## Implication for phase 1

The existing directive/skills are already close to orthodox practice for
the *validation* stage (hypothesis package, guardrails, mechanical
verdict). They are thinner on the *opportunity-framing and
prioritization* stage: no JTBD-style job framing, no required OST
citation/structure in the proposal artifact itself, and no named
scoring method for choosing among candidate opportunities/solutions. The
phase-1 proposal should focus on filling that gap without duplicating or
contradicting the hypothesis-testing discipline already encoded.
