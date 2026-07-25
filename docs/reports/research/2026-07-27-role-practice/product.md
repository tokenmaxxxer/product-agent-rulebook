# What Product Discovery / Product Management Practitioners Actually Do

Research date: 2026-07-27

This is a companion to `docs/reports/research/2026-07-25-swpd-roles/product-discovery.md`,
which mapped roles, boundaries, and handoffs. That research answered "who does
what and where the handoffs are." This one answers "what does the work
itself look like" — at the granularity of individual practices, artifact
field lists, numeric gates, and named failure modes — concrete enough that a
`product-agent-rulebook` skill could be written directly from it. It also
reads against the bar set in `docs/reports/2026-07-26-review-coding-agent-rulebook.md`
and `docs/reports/2026-07-26-review-qa-agent-rulebook.md`: mechanical,
file-checkable gates, not vibes.

## What the work actually is

- **Continuous customer interviewing (weekly cadence).** Teresa Torres's core
  practice: the product trio (PM, designer, engineer) conducts at least one
  customer interview per week, together, on an ongoing basis rather than in a
  time-boxed "discovery phase." The purpose is generative — collecting
  customer stories to discover *opportunities* (needs, pains, desires), not
  validating a proposed solution. Produces: interview snapshots (short
  written summaries) that feed the opportunity solution tree. Read by: the
  trio itself, and at lower fidelity by stakeholders for visibility. The
  documented practical failure: most teams that attempt this cadence lapse
  within 8–12 weeks because of recruiting and scheduling friction; the fix
  practitioners report is automating recruitment, not relaxing the cadence.
  (https://www.lennysnewsletter.com/p/teresa-torres-on-how-to-interview,
  https://www.mindtheproduct.com/getting-to-a-team-based-approach-to-continuous-discovery-by-teresa-torres/)

- **Opportunity Solution Tree (OST) construction and maintenance.** A living
  visual map, not a one-time artifact: outcome at the root, customer
  opportunities as the next layer, candidate solutions under each
  opportunity, and assumption tests at the leaves. Built and continuously
  updated by the trio as new interview evidence arrives — described by
  practitioners as a "living layer," updated on the same weekly cadence as
  the interviews rather than rebuilt per quarter. Produces: the tree itself,
  used by the trio to decide which opportunity to pursue next and which
  solution to test. (https://www.producttalk.org/opportunity-solution-trees/,
  https://getperspective.ai/blog/opportunity-solution-tree-2026-practical-guide-continuous-discovery)

- **Assumption mapping.** For any candidate solution, the trio decomposes it
  into assumptions across five categories — desirability (do customers want
  it), viability (does the business benefit), feasibility (can it be built),
  usability (can customers use it), and ethical (could it cause harm) — per
  Teresa Torres's framework. David Bland's assumption-map 2x2 then plots each
  assumption on evidence strength (weak → strong) versus importance (less
  critical → critical); the top-left quadrant (critical + weak evidence) is
  the priority test list. Produces: an assumption map/list feeding which
  assumption tests get run next. Takes: an hour-scale team exercise per
  solution, ongoing. (https://www.producttalk.org/assumption-testing/)

- **Assumption testing (pre-launch, distinct from A/B testing).** Four
  recurring test types practitioners use before writing code for real:
  prototype tests (simulate the scenario, observe behavior), one-question
  surveys (single behavioral question, past/current behavior only), data
  mining (mine existing usage data for a proxy signal), and engineering
  research spikes (time-boxed technical feasibility investigation). These are
  explicitly framed as discovery-stage, cheaper and faster than a full
  post-launch controlled experiment. (https://www.producttalk.org/assumption-testing/)

- **JTBD / "switch" interviewing.** A structured interview format (Bob
  Moesta, Rewired Group) anchored on a specific past switching event, not
  general opinion-gathering. Canonical opening question: "Why did you buy
  <product> and where were you when you bought it?" The interviewer then
  reconstructs a timeline from first thought to purchase and probes four
  forces: Push (dissatisfaction with the old way), Pull (attraction to the
  new), Anxiety (concerns about switching), Habit (inertia/resistance).
  Practitioners report 10–15 switch interviews typically reveal the majority
  of actionable patterns in a customer base — this is a much smaller-N claim
  than continuous discovery's ongoing cadence, and the two methods answer
  different questions (JTBD: why did this specific behavior happen; continuous
  discovery: what should we build next). (https://www.june.so/blog/how-to-run-a-jtbd-interview-like-the-co-creator-of-the-framework,
  https://commoncog.com/putting-jtbd-interview-to-practice/)

- **Interview discipline against self-deception ("the Mom Test").** Rob
  Fitzpatrick's three rules, treated by practitioners as the baseline
  hygiene for any of the above interview formats: (1) talk about the
  customer's life/past, not your idea; (2) ask about specifics in the past,
  not hypotheticals about the future; (3) talk less, listen more — customer
  should carry roughly 80% of the talk time. Three categories of data are
  named as unreliable and to be discarded: compliments, hypothetical
  "I would" statements, and feature wishlists.
  (https://mtlynch.io/book-reports/the-mom-test/, https://www.koji.so/blog/mom-test-customer-interviews-2026)

- **Hypothesis registration before data collection.** Practitioners write a
  falsifiable hypothesis statement before running an experiment, in a fixed
  template (see Artifacts section) that names the metric, the direction, and
  the threshold, explicitly to prevent post-hoc reinterpretation of
  ambiguous results. (https://www.fishmanafnewsletter.com/p/experiment-document-template,
  https://herbig.co/wp-content/uploads/2019/02/Lean-UX-Hypothesis-Template-by-Tim-Herbig.pdf)

- **Experiment execution and readout.** Once a hypothesis is registered, the
  work becomes: compute sample size / runtime, launch, monitor guardrails,
  and write a readout that states outcome, lift, and a pre-committed
  follow-up action ("If This Works We Should…", ITWWS) — decided at
  design time, not after seeing results. (https://www.fishmanafnewsletter.com/p/experiment-document-template)

## Artifacts and their shapes

This is the most load-bearing section — these are candidate state-file
contents.

- **Opportunity Solution Tree.** Four layers, top to bottom: (1) desired
  outcome (one node, business metric), (2) opportunities (customer needs/
  pains/desires, can nest), (3) solutions (candidate approaches to an
  opportunity), (4) assumption tests (leaves under a solution). Maintained
  continuously; consumed by the trio for prioritization and by leadership at
  low resolution for visibility. (https://www.producttalk.org/opportunity-solution-trees/)

- **Assumption map.** A 2x2 grid: x-axis evidence strength (weak → strong),
  y-axis importance (less critical → critical). Each assumption (desirability
  / viability / feasibility / usability / ethical) is a plotted point;
  points in the critical+weak-evidence quadrant are the priority queue for
  assumption testing. (https://www.producttalk.org/assumption-testing/)

- **Hypothesis / experiment brief — canonical field list**, synthesized from
  the Lean UX hypothesis template and Adam Fishman's experiment document
  (both widely cited by practitioners):
  - *Hypothesis statement*: "We believe [doing X for persona Y] will result
    in [outcome], because [evidence]. We will know we're right/wrong when we
    see [specific metric change, with a number]."
  - *The Why*: summary, owners (PM/DS/eng/design), problem statement,
    hypothesis, learning objectives, supporting evidence.
  - *The Plan*: experiment design (randomization unit, platform, eligibility,
    assignment mechanism, response metrics), variant descriptions, runtime/
    sample-size calculation, risk assessment, and "If This Works We Should"
    (pre-committed follow-up).
  - *The Results*: outcome determination, winner + lift magnitude, analysis
    of what happened, recommendation, follow-ups, metric-tradeoff assessment
    (did a guardrail move).
  - *The Checklist*: proposal complete, alignment reached, plan built,
    broader feedback gathered, implementation validated, stakeholders
    notified, launched, live-notification sent, analyzed, code cleaned up.
  Read by: PM, engineer, data scientist, designer, plus downstream
  stakeholders (support/sales/marketing) who need to know what's running and
  why. (https://www.fishmanafnewsletter.com/p/experiment-document-template,
  https://herbig.co/wp-content/uploads/2019/02/Lean-UX-Hypothesis-Template-by-Tim-Herbig.pdf)

- **One-pager (Reforge/Lenny's-style, PRD alternative).** Single page:
  background/context, problem statement (kept separate from solution),
  hypotheses, risks, goals/success metrics. Explicitly designed to force
  problem-solution separation and drive cross-functional alignment before
  a full spec is written; several named templates (Intercom's, Asana's,
  Kevin Yien's staged version, Lenny's) share this shape, differing mainly in
  how much solution detail is allowed on the same page.
  (https://www.reforge.com/artifacts/c/product-development/one-pager,
  https://blog.logrocket.com/product-management/what-is-a-one-pager-examples-rules-template/)

- **PR/FAQ, Shape Up pitch, user story map, PRD, backlog item** — canonical
  field lists for these were already captured in the prior research
  (`2026-07-25-swpd-roles/product-discovery.md`, "Artifacts produced"
  section) and are not restated here to avoid duplication; they remain the
  reference for those five formats.

## Decision criteria and gates

- **RICE** = (Reach × Impact × Confidence) / Effort. Reach: number of users
  affected per period. Impact: typically scored on a discrete scale (e.g.
  0.25 to 5). Confidence: a percentage (0.8 = 80%). Effort: person-months.
  RICE is explicitly a *relative-ranking* tool, not an absolute threshold —
  practitioners sort the backlog by score and compare top items to each
  other (a score of 800 is twice as urgent as 400), rather than reading any
  single score as "must build." One numeric rule of thumb that is stated
  as a threshold: a confidence score below 50% should be treated as a
  "moonshot" and excluded from near-term prioritization.
  (https://www.tempo.io/guides/rice-score-prioritization-framework-product-management,
  https://www.productplan.com/glossary/rice-scoring-model)

- **ICE** = Impact × Confidence × Ease, each typically scored 1–10.
  Popularized by Sean Ellis for growth teams; faster and rougher than RICE,
  used for triaging a long list of small experiments rather than defending a
  roadmap decision. (https://www.growthmentor.com/blog/prioritization-frameworks)

- **Sample size / minimum detectable effect.** A commonly cited rule of
  thumb for a two-sample A/B test at 95% confidence / 80% power is
  n ≈ 16σ²/Δ², where Δ is the minimum detectable effect and σ² the metric
  variance — used by practitioners to decide runtime before launching, not
  after. (https://medium.com/@yashgupta96/beginners-guide-to-trustworthy-a-b-test-i-e-controlled-experiments-b501997275db)
  [Note: this formula is widely repeated in secondary practitioner sources;
  it traces to standard two-sample test power calculations rather than to a
  single named canonical source found in this pass — flagged as
  cross-corroborated but not independently primary-sourced here.]

- **Guardrail metrics as a hard trip-wire, distinct from the primary metric
  (OEC).** Practitioners separate three metric tiers: the primary metric you
  are trying to move, secondary metrics that explain *why* it moved, and
  guardrail metrics that must not move adversarially. An experiment that
  wins on the primary metric but breaches a guardrail is treated as reduced-
  trust or is stopped outright, regardless of the primary-metric result.
  (https://medium.com/@yashgupta96/beginners-guide-to-trustworthy-a-b-test-i-e-controlled-experiments-b501997275db)

- **Hypothesis pre-registration as the actual gate.** The concrete mechanism
  practitioners use to prevent post-hoc rationalization is fixing the metric,
  the threshold, and the decision rule (what "right" and "wrong" look like
  numerically) *before* the experiment starts, in the hypothesis statement
  itself ("We will know we're right/wrong when we see..."). This is the same
  discipline named in `docs/specs/agent-roles.md`'s `hypothesis-registered`
  state and in the `hypothesis-testing` skill; it is a practitioner norm
  documented across multiple experiment-brief templates, not one team's
  idiosyncrasy. (https://www.fishmanafnewsletter.com/p/experiment-document-template)

- **HiPPO override as the thing these gates exist to defeat.** "Highest Paid
  Person's Opinion" is the named failure practitioners contrast against
  metric-gated decisions — reliance on seniority/instinct instead of a
  pre-registered test result. The documented countermeasure is not a social
  process fix but the mechanical one above: fix the rule before anyone senior
  sees the data. (https://medium.com/@edurany/enric-durany-blog-how-to-deal-with-an-hippo-highest-paid-person-opinion-ab-testing-to-the-1ac36591cdb)

## Failure modes

- **Feature factory (Melissa Perri).** Teams measured by shipped output
  (features, story points, velocity) rather than outcomes (value created).
  Symptoms named: teams spend all their time in solution space, don't build
  from a product strategy, and ship features that may not create value.
  Countermeasure practitioners state: change what is measured, from output
  counts to outcome metrics tied to the desired business result — not a
  process change but a measurement change. (https://www.producttalk.org/glossary-discovery-feature-factory/,
  https://medium.com/@shampa.swe/escaping-the-build-trap-how-effective-product-management-creates-real-value-by-melissa-perri-11ad16d1ed74)

- **Confirmation-biased / solution-first interviewing.** Named failure: most
  customer interviews fail because questions are designed (consciously or
  not) to elicit validation rather than truth; three bad-data patterns are
  named — compliments, hypothetical "I would" statements, and wishlists.
  Countermeasure: the Mom Test's three rules (talk about their life not your
  idea; past specifics not future hypotheticals; interviewer talks ≤20% of
  the time). (https://mtlynch.io/book-reports/the-mom-test/)

- **HiPPO decision override.** See above — decisions made by seniority
  rather than by a pre-registered metric result. Countermeasure: fix the
  decision rule before the data exists, so there is nothing left to
  override by opinion once results land. (https://medium.com/@edurany/enric-durany-blog-how-to-deal-with-an-hippo-highest-paid-person-opinion-ab-testing-to-the-1ac36591cdb)

- **Handoff/telephone-game distortion** and **agency/outsourced discovery-
  delivery split** — already documented in
  `2026-07-25-swpd-roles/product-discovery.md` ("Handoff points" section);
  not restated here, but noted as the organizational-level analog of the
  individual-practice failure modes above: both are cases where a decision
  gets made without the evidence that produced it staying attached.

- **Vanity metrics.** [unsourced in this pass — this term (engagement/
  downloads/pageviews as a substitute for retention/revenue impact) is
  extremely common in PM literature but no primary source was fetched
  defining it rigorously in this research pass; treat as a named but
  not-independently-sourced-here failure mode, distinct from feature
  factory, which concerns output-vs-outcome rather than metric choice
  specifically.]

- **Recruiting/scheduling attrition on continuous discovery.** Distinct from
  the "big" named failure modes above but empirically the most commonly
  reported reason continuous interviewing cadences fail in practice: teams
  lapse within 8–12 weeks without an automated recruiting pipeline.
  Countermeasure practitioners state: automate recruitment, not relax the
  weekly cadence. (https://www.lennysnewsletter.com/p/teresa-torres-on-how-to-interview)

## Tooling and automation

- **Already tool-supported / substantially automatable:**
  - Interview transcription and thematic synthesis — Dovetail and similar
    tools use NLP to auto-tag themes, surface quotes, and build an insight
    repository; practitioners report going from "we talked to 20 users" to
    "here are five patterns" in under an hour, versus days manually; one
    source cites an LLM synthesizing 10 interview transcripts in ~4 minutes
    versus roughly half a day by hand.
    (https://cleverx.com/blog/best-ai-tools-for-product-managers-in-2026/,
    https://www.chatprd.ai/learn/ai-for-product-managers)
  - Recruiting-pipeline automation for continuous interviewing (the
    documented fix for the attrition failure mode above).
    (https://www.lennysnewsletter.com/p/teresa-torres-on-how-to-interview)
  - Backlog/feedback prioritization and PRD drafting — tools named across
    2026 sources (Productboard, Jira Product Discovery, ChatPRD, Aha!) offer
    AI-assisted drafting and scoring, though these sources are largely vendor
    self-description and should be weighted accordingly.
    (https://www.institutepm.com/knowledge-hub/ai-use-in-product-management)
  - Sample-size/runtime calculation and guardrail-metric monitoring —
    mechanical once the metric and MDE are chosen.

- **Irreducibly human judgment (per the practitioner sources gathered):**
  - Choosing which opportunity/assumption is *critical* enough to test next
    (the assumption-map placement itself is a judgment call about risk, not
    a computable output).
  - Deciding whether an interview subject's story is representative or an
    outlier — pattern recognition across qualitative narrative, which the
    sources describe tools as *accelerating synthesis of*, not replacing the
    judgment of which pattern matters.
  - The go/no-go/pivot call itself when a guardrail metric moves ambiguously
    (reduced trust vs. outright stop) — described as requiring judgment
    about the experiment's integrity, not a pure threshold check.
  - Writing the hypothesis's causal "because" clause — connecting a
    qualitative insight to a quantitative prediction is the step every
    source treats as the core PM skill, not an automatable one.

## Candidates for rulebook encoding

Marked as this document's own synthesis, not a direct claim from a
practitioner source. Mapped against `product`'s existing states
(`idle/scoping/researching/hypothesis-registered/measuring/decided` from
`docs/specs/agent-roles.md`).

- **`scoping` → skill: one-pager drafting.** The Reforge/Lenny's one-pager
  field list (background, problem statement kept separate from solution,
  hypotheses, risks, goals) maps directly onto what `scoping` should produce
  before evidence-gathering begins — this could be the concrete output
  artifact for the `idle -> scoping` transition, rather than leaving
  `scoping` as an unstructured free-text state.

- **`researching` → skill: assumption mapping + interview discipline.** The
  five-category assumption breakdown (desirability/viability/feasibility/
  usability/ethical) plus the critical×weak-evidence 2x2 quadrant gives
  `researching` a concrete internal structure: enumerate assumptions, plot
  them, and only escalate to `hypothesis-registered` once the top-quadrant
  assumptions have been tested (via the four assumption-test types:
  prototype test, one-question survey, data mining, research spike). The
  Mom Test's three interview rules could become an injected directive any
  time the agent drafts interview questions in this state, since it is a
  format-agnostic hygiene rule applicable regardless of which interview
  structure (continuous discovery vs. JTBD switch interview) is used.

- **`hypothesis-registered` → gate check: the "We believe / we will know"
  template as the literal field format.** The existing spec already requires
  metric/threshold/decision-rule fields be non-empty plus semantic user
  approval; this research supplies the actual sentence-level template
  practitioners use to fill those fields, which could become a skill that
  drafts the hypothesis statement and refuses to mark the fields complete
  unless the statement contains a numeric threshold and a named metric (not
  just prose).

- **`measuring` → gate check: guardrail-metric declaration before data
  collection starts.** The spec currently locks the threshold field once
  `measuring` begins. This research suggests the guardrail-metric list
  (metrics that must not move adversarially, separate from the primary
  metric) should be part of what gets locked at the same transition — a
  missing state, arguably: `hypothesis-registered -> measuring` could gate
  on a non-empty guardrails field the same way it gates on metric/threshold/
  decision-rule, since guardrail breach is the documented reason
  practitioners override an otherwise-winning result.

- **`decided` → mechanical-application check.** The spec already forbids a
  "fresh judgment" verdict in `decided`; the ITWWS ("If This Works We
  Should") field from the experiment-brief template is the natural
  encoding of "the follow-up action was pre-committed, not invented after
  seeing results" — could be a required non-empty field checked at
  `hypothesis-registered` time and then read back, not written, at
  `decided` time.

- **Missing state, stated plainly: nothing in
  `idle/scoping/researching/hypothesis-registered/measuring/decided` covers
  the *continuous* re-interviewing loop.** Every named practice here
  (weekly interviews, OST maintenance, assumption-map updates) is explicitly
  ongoing and cyclical, not a one-shot pipeline from idea to verdict. The
  current state machine models a single hypothesis's lifecycle correctly but
  has no state for "this opportunity/tree is still being fed evidence weekly
  even though no single hypothesis is currently `measuring`." Whether that
  gap should be closed with a recurring state, a separate artifact (the OST
  file, updated independently of the per-hypothesis state file), or left as
  out of scope for a single-hypothesis rulebook is not decided here — but it
  is the one place this research finds the existing state machine and the
  observed practice describe genuinely different shapes of work, not just
  different levels of detail.

## Sources

- https://www.lennysnewsletter.com/p/teresa-torres-on-how-to-interview
- https://www.mindtheproduct.com/getting-to-a-team-based-approach-to-continuous-discovery-by-teresa-torres/
- https://www.producttalk.org/opportunity-solution-trees/
- https://getperspective.ai/blog/opportunity-solution-tree-2026-practical-guide-continuous-discovery
- https://www.producttalk.org/assumption-testing/
- https://www.june.so/blog/how-to-run-a-jtbd-interview-like-the-co-creator-of-the-framework
- https://commoncog.com/putting-jtbd-interview-to-practice/
- https://mtlynch.io/book-reports/the-mom-test/
- https://www.koji.so/blog/mom-test-customer-interviews-2026
- https://www.fishmanafnewsletter.com/p/experiment-document-template
- https://herbig.co/wp-content/uploads/2019/02/Lean-UX-Hypothesis-Template-by-Tim-Herbig.pdf
- https://www.reforge.com/artifacts/c/product-development/one-pager
- https://blog.logrocket.com/product-management/what-is-a-one-pager-examples-rules-template/
- https://www.tempo.io/guides/rice-score-prioritization-framework-product-management
- https://www.productplan.com/glossary/rice-scoring-model
- https://www.growthmentor.com/blog/prioritization-frameworks
- https://medium.com/@yashgupta96/beginners-guide-to-trustworthy-a-b-test-i-e-controlled-experiments-b501997275db
- https://medium.com/@edurany/enric-durany-blog-how-to-deal-with-an-hippo-highest-paid-person-opinion-ab-testing-to-the-1ac36591cdb
- https://www.producttalk.org/glossary-discovery-feature-factory/
- https://medium.com/@shampa.swe/escaping-the-build-trap-how-effective-product-management-creates-real-value-by-melissa-perri-11ad16d1ed74
- https://cleverx.com/blog/best-ai-tools-for-product-managers-in-2026/
- https://www.chatprd.ai/learn/ai-for-product-managers
- https://www.institutepm.com/knowledge-hub/ai-use-in-product-management
- docs/reports/research/2026-07-25-swpd-roles/product-discovery.md (prior research, cited for artifacts not restated here)
- docs/specs/agent-roles.md (existing `product` role state machine)
