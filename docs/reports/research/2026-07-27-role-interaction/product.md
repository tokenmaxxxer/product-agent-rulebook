# When and How a Product Practitioner Involves Another Human

Research date: 2026-07-27

This is a companion to `docs/reports/research/2026-07-27-role-practice/product.md`,
which answered "what does the work produce and how is it judged" (artifacts,
field lists, numeric gates). That research is not restated here. This one
answers a narrower question: at which recurring moments does a product
practitioner stop and involve another human, what do they carry into that
moment, who do they bring it to, and what do they leave with. The target
consumer is an agent state machine's human-in-the-loop transitions, so the
emphasis is on the moment and its shape, not on the full body of practice.

## Moments that call for a human

**1. Opportunity/problem selection sign-off.**
- *Trigger*: the trio has enough interview evidence to name a candidate
  opportunity (or has updated the opportunity solution tree) and wants to
  commit real work to pursuing it.
- *Brings*: the opportunity solution tree itself, plus the underlying
  interview evidence sourced back to specific customer conversations —
  Torres's stakeholder-alignment sequence explicitly starts by "aligning on
  the desired outcome at the top of your Opportunity Solution Tree" before
  discussing any opportunity or solution.
  (https://www.mindtheproduct.com/justify-your-product-decisions-and-get-stakeholder-buy-in-by-teresa-torres/)
- *Brought to*: functional stakeholders and partner-team leads, not a single
  named approver — Torres frames this as co-creation ("show your work early,
  leverage stakeholder expertise") rather than a single sign-off gate.
  (https://maze.co/blog/making-better-product-decisions-with-teresa-torres/)
- *Leaves with*: shared framing of the outcome and, ideally, stakeholder
  contributions folded into the tree — not a formal go/no-go, since Torres's
  model treats this as continuous alignment rather than a discrete
  authorization event. Where a discrete authorization *is* required (see
  betting/stage-gate below), problem framing is a precondition submitted
  alongside the pitch, not sought separately.

**2. Funding or betting decisions (Shape Up betting table, stage-gate
reviews, quarterly planning).**
- *Trigger*: a fixed calendar point — end of a Shape Up cooldown period
  (before each six-week cycle) or a stage-gate boundary between NPD phases.
  Not triggered by the practitioner's readiness; triggered by the calendar/
  the stage completing its deliverables.
  (https://basecamp.com/shapeup/2.2-chapter-08,
  https://www.stage-gate.com/blog/the-stage-gate-model-an-overview/)
- *Brings*: in Shape Up, a **shaped pitch** — problem statement, appetite
  (fixed time budget), a rough solution sketch, named rabbit holes, and
  explicit out-of-bounds items — never an open-ended proposal.
  (https://basecamp.com/shapeup/2.2-chapter-08) In stage-gate, a **stage
  deliverable package** scored against a gate scorecard with must-meet
  (checklist, pass/fail) and should-meet (weighted, scored) criteria.
  (https://planisware.com/glossary/phase-gate-or-stage-gate,
  https://athena.ecs.csus.edu/~buckley/CSc233/Stage_Gate_Project.pdf)
- *Brought to*: Shape Up — a small fixed group ("a few senior employees,"
  in Basecamp's own case "the CEO ... CTO, a senior programmer, and a
  product strategist," typically capped near four people).
  (https://basecamp.com/shapeup/2.2-chapter-08) Stage-gate — a "gatekeeper"
  panel of senior cross-functional leaders (not the practitioner's own
  team) making a resourcing call.
  (https://www.stage-gate.com/blog/the-stage-gate-model-an-overview/)
- *Leaves with*: a bet/no-bet or go/kill/hold/recycle/conditional-go
  decision, plus (if funded) team assignment and capacity allocation for the
  next cycle or stage. In Shape Up this is explicitly final at the meeting —
  "there's no step two to validate the plan" and no one may reopen it
  afterward. (https://basecamp.com/shapeup/2.2-chapter-08)
  Stage-gate's five-way outcome set (go / kill / hold / recycle / conditional
  go) is broader than Shape Up's binary bet/no-bet.
  (https://planisware.com/glossary/phase-gate-or-stage-gate)

**3. Hypothesis approval before an experiment runs.**
- *Trigger*: hypothesis statement is drafted (metric, direction, threshold
  named) and the practitioner wants to commit engineering/data-science time
  to building and running the test.
- *Brings*: the hypothesis/experiment brief's "The Why" and "The Plan"
  sections — problem statement, hypothesis, learning objective, supporting
  evidence, experiment design (randomization unit, eligibility, sample-size/
  runtime calculation), and the pre-committed "If This Works We Should"
  follow-up. (https://www.fishmanafnewsletter.com/p/experiment-document-template,
  see also companion practice report)
- *Brought to*: co-owners named on the brief — PM, data scientist, engineer,
  designer — this is a cross-functional co-sign rather than a single
  external approver; some organizations additionally route it through a
  platform-enforced reviewer if the experiment surface requires one (see
  Spotify Confidence example below).
- *Leaves with*: an "alignment reached" checkbox on the brief's checklist
  (part of the canonical field list: proposal complete → alignment reached
  → plan built → broader feedback gathered → ...), i.e. a recorded step in
  the document, not necessarily a separate meeting artifact.
  (https://www.fishmanafnewsletter.com/p/experiment-document-template)

**4. Experiment read-out and ship/kill.**
- *Trigger*: pre-registered runtime/sample size reached, or a guardrail
  trips early.
- *Brings*: "The Results" section — outcome determination, winner and lift
  magnitude, analysis narrative, metric-tradeoff read (did a guardrail
  move), and a recommendation grounded in the decision rule fixed at
  registration time. (https://www.fishmanafnewsletter.com/p/experiment-document-template)
- *Brought to*: the same cross-functional owners, plus downstream
  stakeholders (support/sales/marketing) who are notified of the outcome —
  the brief's checklist names an explicit "stakeholders notified" step
  distinct from the analysis step itself.
  (https://www.fishmanafnewsletter.com/p/experiment-document-template)
- *Leaves with*: a recorded ship/kill/iterate call and the follow-up action
  — which, because it was pre-committed as ITWWS before the data existed,
  is meant to be read off the rule rather than re-litigated in light of the
  result.

**5. Killing or pivoting a bet mid-flight.**
- *Trigger in Shape Up*: the cycle's six-week boundary arrives and the hill
  chart shows unresolved uphill (unknown) work — not a discretionary
  practitioner judgment call, but a fixed calendar trigger ("the circuit
  breaker"). (search result: Shape Up circuit breaker / no-extensions policy)
- *Brings*: the hill chart's current state and a judgment on whether the
  remaining work is "downhill" (known, can be shipped as-is, scope cut) or
  still "uphill" (unresolved, should not be extended).
- *Brought to*: in Basecamp's practice this is largely team-adjudicated —
  the team decides to ship what exists or let the project die; it does not
  automatically escalate to the betting-table group, though a fundamentally
  broken shape may return to shaping and get re-pitched at the next betting
  table. (https://basecamp.com/shapeup/2.2-chapter-08 and circuit-breaker
  search result) *Stage-gate contrast*: mid-stage kill decisions do escalate
  formally to the same gatekeeper panel that funded the stage, since the
  gate model routes every kill/hold/recycle through the gate meeting rather
  than leaving it to the team.
  (https://planisware.com/glossary/phase-gate-or-stage-gate) This is a
  recorded disagreement in how much practitioners escalate a mid-flight
  kill, not a resolved consensus — see the ambiguity flagged in section 3.
- *Leaves with*: either a shipped (possibly descoped) increment, or an
  explicit kill with no extension granted — the "no extensions" rule is the
  load-bearing mechanism preventing indefinite drift.

**6. Escalation when data and stakeholder opinion conflict (the HiPPO
problem).**
- *Trigger*: a senior stakeholder's opinion contradicts what interview
  evidence, experiment results, or the opportunity solution tree indicate —
  named in practitioner literature as the "HiPPO effect" (Highest Paid
  Person's Opinion), coined by Avinash Kaushik.
  (https://pablok.medium.com/dealing-with-the-hippo-in-product-management-d77d90f12ddc,
  https://uxcam.com/blog/using-data-to-challenge-highest-paid-persons-opinion/)
- *Brings*: the underlying evidence trail — sourced customer quotes,
  experiment guardrail data, or the tree itself — practitioners are advised
  to make the *evidence* visible rather than argue the conclusion directly.
  (https://www.mindtheproduct.com/justify-your-product-decisions-and-get-stakeholder-buy-in-by-teresa-torres/)
- *Brought to*: the disagreeing stakeholder directly, sometimes with a
  broader cross-functional review pulled in as a structural counterweight —
  practitioner advice explicitly recommends "cross-functional teams with
  representatives from all relevant departments that have the authority to
  make collaborative decisions" as a structural fix, rather than a one-on-one
  argument. (https://dovetail.com/product-development/how-to-manage-the-hippo-effect-in-product-management/)
- *Leaves with*: no universally agreed resolution mechanism was found in
  this pass — sources converge on "lean on data and organizational goals to
  make the case" as the tactic but do not specify a forcing decision rule
  for when the senior stakeholder still disagrees after seeing the evidence.
  `[unsourced]` for the terminal step: what happens if the HiPPO overrules
  the evidence anyway is not addressed by the sources found here.

## The shape of the exchange

- **Opportunity sign-off (moment 1)**: async and iterative, not a single
  meeting — informal one-on-ones plus a "group review among all key
  stakeholders" once the practitioner has gatekeeper-level alignment
  already. Reading material is the tree itself (a diagram, not prose), kept
  intentionally light so stakeholders can scan it quickly. Recorded in the
  living OST, not a separate minutes document.
  (https://www.mindtheproduct.com/justify-your-product-decisions-and-get-stakeholder-buy-in-by-teresa-torres/,
  https://johnpcutler.github.io/lenny_behaviors_and_rituals/)

- **Betting table (moment 2, Shape Up)**: a synchronous, small-group,
  timeboxed meeting — "rarely goes longer than an hour or two." Reading
  material is a handful of shaped pitches (each capped in scope by design:
  problem, appetite, sketch, rabbit holes, no-gos), reviewed independently
  beforehand by each attendee plus informal pre-meeting conversations. The
  decision (cycle plan: which bets, which teams) is recorded implicitly by
  being communicated via a kickoff message to the teams — the source does
  not describe a separate written minutes artifact.
  (https://basecamp.com/shapeup/2.2-chapter-08)

- **Stage-gate review (moment 2, stage-gate)**: a formal, scheduled gate
  meeting with a scorecard artifact — deliverables plus must-meet/
  should-meet criteria scored in advance of the meeting. This is explicitly
  more document-heavy and more formally recorded (a scorecard is itself the
  record) than the betting table.
  (https://athena.ecs.csus.edu/~buckley/CSc233/Stage_Gate_Project.pdf,
  https://planisware.com/glossary/phase-gate-or-stage-gate)

- **Hypothesis approval (moment 3)**: async, document-centric — a shared
  brief with a literal checklist field ("alignment reached") rather than a
  standalone meeting; the co-owners named on the brief read and check off
  sections rather than convene. Recorded directly in the brief.
  (https://www.fishmanafnewsletter.com/p/experiment-document-template)
  Where a platform enforces required reviewers (e.g., Spotify's Confidence
  experimentation platform), the approval is a structured in-tool review
  gate: the experiment cannot launch until each required reviewer approves,
  and any material change to the design (flag, variants, audience,
  allocation) resets all approvals, forcing re-review.
  (https://confidence.spotify.com/docs/experiments/reviews)

- **Experiment read-out (moment 4)**: also document-centric — "The
  Results" section of the same brief, with an explicit "stakeholders
  notified" checklist step distinct from the analysis itself, implying a
  broadcast (async, one-to-many) rather than a discussion meeting for the
  notification step specifically. (https://www.fishmanafnewsletter.com/p/experiment-document-template)

- **Mid-flight kill (moment 5)**: no meeting at all in Shape Up's model —
  the circuit breaker is a calendar deadline, not a called meeting; the
  team's own hill-chart read is the operative signal, and the "decision" is
  the default of not extending. Stage-gate's mid-stage kill, by contrast, is
  the same formal gate-meeting shape as moment 2. This is a genuine
  structural difference between the two practitioner traditions, not just a
  documentation gap.

- **HiPPO escalation (moment 6)**: unstructured by design — practitioner
  sources describe it as a conversation backed by evidence artifacts (data
  visualizations, sourced quotes) rather than a named ritual with a fixed
  duration or recorded outcome format. `[unsourced]` for duration/recording
  norms specifically.

## When the answer is ambiguous

- **Trace feedback back to its evidence source before acting on it.**
  Torres's explicit practitioner move when a stakeholder gives vague or
  opinion-only feedback on the opportunity solution tree: ask "where did
  these customer insights come from? Did we hear that from talking to a
  customer? ... Did it come from a stakeholder? A customer service
  conversation?" — the point is to convert an ambiguous assertion into either
  traceable evidence (act on it) or an untraceable opinion (treat with much
  lower weight, do not treat as ground truth).
  (https://www.mindtheproduct.com/reversing-teresa-torres-opportunity-solution-tree-to-find-the-why-behind-solutions/)
  This is the single most directly transferable rule for an agent: **a
  vague response is a prompt to re-ask for its evidentiary source, not a
  green light.**

- **Pre-registration removes ambiguity from the read-out step by
  construction.** Because the hypothesis brief fixes "we will know we're
  right/wrong when we see [metric, threshold]" *before* the experiment
  starts, the read-out moment (4) is designed to have no ambiguous case for
  the ship/kill call itself — ambiguity is pushed upstream into whether the
  guardrail tripped or not, which is a numeric check, not a judgment call.
  (https://www.fishmanafnewsletter.com/p/experiment-document-template,
  see companion practice report for the pre-registration mechanism itself)

- **Shape Up resolves scheduling ambiguity with a hard default rather than
  a request for more input**: at the six-week boundary, if the hill chart
  is ambiguous about whether work is done, the default is not to extend —
  the team must decide to ship-as-is or kill, with no third "ask for more
  time" option available. This is a timebox-then-default-proceed pattern,
  not an escalation pattern. (Shape Up circuit-breaker search result)

- **Structural escalation is the named fix for a HiPPO standoff, not
  re-asking the same person.** When data and a senior stakeholder's opinion
  conflict and the stakeholder does not update on evidence, the practitioner
  literature's recommended move is to broaden the room (pull in a
  cross-functional group with decision authority) rather than repeatedly
  re-litigating one-on-one.
  (https://dovetail.com/product-development/how-to-manage-the-hippo-effect-in-product-management/)
  What happens if that broader group also fails to converge is
  `[unsourced]` — no source in this pass specifies a terminal forcing rule
  (e.g., "escalate to the single named decision-maker after N rounds").

- **Approval resets on material change, rather than being assumed to
  survive edits.** The Spotify Confidence platform's rule that changing the
  flag, variants, audience, or allocation invalidates prior reviewer
  approvals is a concrete anti-pattern-guard: an agent should not treat an
  earlier "approved" state as still valid after it has altered the design
  underneath that approval. (https://confidence.spotify.com/docs/experiments/reviews)

## What proceeds without asking

- **Choosing which interview/testing method to run and how many
  interviews.** Continuous discovery's weekly interview cadence, JTBD's
  10–15 switch interviews, and the choice among prototype test / survey /
  data mining / spike are practitioner-level method decisions, not
  escalated per instance. (see companion practice report for the specific
  methods; no source in this pass shows these being individually approved)

- **Relative prioritization scoring (RICE/ICE) within an already-agreed
  scope.** These frameworks are explicitly described as tools the
  practitioner/team applies to sort a backlog, not as artifacts submitted
  for external sign-off; the escalation point is the funding decision that
  follows (moment 2), not the scoring exercise itself.
  (https://www.tempo.io/guides/rice-score-prioritization-framework-product-management,
  https://www.growthmentor.com/blog/prioritization-frameworks — see
  companion practice report)

- **Day-to-day co-creation inside the trio.** Torres's product-trio model
  has the PM, designer, and engineer jointly making discovery decisions
  (which opportunity, which solution to test) as their normal operating
  mode — this is deliberately *not* escalated to stakeholders each time;
  escalation is reserved for outcome-level alignment (moment 1) and funding
  (moment 2). (https://maze.co/blog/making-better-product-decisions-with-teresa-torres/)

- **Stakeholder "yes to everything" is explicitly rejected as the
  practitioner's job.** Cagan frames stakeholder management as *not* a
  service relationship requiring per-request sign-off: "managing
  stakeholders is not about saying yes to everything ... it is about
  understanding their constraints and building solutions that accommodate
  those constraints" — implying many day-to-day stakeholder requests are
  triaged and answered by the practitioner alone, not escalated upward.
  (search result citing Cagan's Empowered; see
  https://www.svpg.com/pledge-to-stakeholders/ for the adjacent "Pledge to
  Stakeholders" framing)

- **Shipping a downhill (known, low-risk) descoped increment at a cycle
  boundary.** In Shape Up, if the hill chart shows the remaining work is
  understood and low-risk, the team can cut scope and ship without
  returning to the betting table — only a fundamentally broken shape
  triggers a return to shaping/re-pitching. (Shape Up circuit-breaker
  search result, https://basecamp.com/shapeup/2.2-chapter-08)

## Draft `user`-actor transitions

*(This section is the report author's synthesis for state-machine design,
not a sourced claim. States used: `idle`, `scoping`, `researching`,
`hypothesis-registered`, `measuring`, `decided`.)*

| from | to | actor | precondition |
|---|---|---|---|
| `scoping` | `scoping` | user | opportunity/outcome framing drafted; user co-creates or affirms the outcome framing (moment 1) — not a hard gate, may loop |
| `researching` | `hypothesis-registered` | user | hypothesis brief's "Why"+"Plan" sections complete; user (co-owner) checks "alignment reached" before experiment build starts (moment 3) |
| `hypothesis-registered` | `measuring` | user | funding/betting decision made (moment 2) — pitch or stage deliverable reviewed and a go/bet decision recorded; only after this may the experiment actually launch |
| `measuring` | `decided` | user | pre-registered runtime/sample size reached or guardrail tripped; user receives read-out and the ship/kill/iterate call is recorded against the pre-committed rule (moment 4) |
| `measuring` | `decided` | user | circuit-breaker/deadline reached with ambiguous (uphill) progress; user (team-level, not necessarily an external approver) makes the ship-as-is-or-kill call with no extension available (moment 5) |
| `decided` | `scoping` | user | HiPPO-style conflict between the recorded decision and a senior stakeholder's opinion escalates; user (broadened stakeholder group) is asked to re-affirm or override — terminal resolution mechanism is `[unsourced]`, so this transition's precondition is weaker than the others |

- **Missing-state note**: moment 6 (data-vs-stakeholder-opinion escalation)
  does not map cleanly onto any existing state — it is not a phase of the
  work but an interrupt that can fire from `measuring` or `decided` and
  loops back to an earlier state or stalls. The existing five working
  states describe *what stage the work is in*, not *whose opinion currently
  has standing*; representing moment 6 faithfully likely needs a
  cross-cutting flag (e.g., "contested") rather than a state, since sources
  here found no clean terminal rule to encode as a transition precondition.
- **Missing-state note**: moment 1 (opportunity sign-off) is described by
  Torres as continuous, iterative co-creation rather than a discrete
  gate — it does not have a clean single precondition the way the betting
  table or hypothesis-approval moments do, so the `scoping → scoping`
  self-loop above is a weaker fit than the others in this table.

## Sources

- https://basecamp.com/shapeup/2.2-chapter-08 (The Betting Table)
- https://basecamp.com/shapeup/4.0-appendix-01
- Shape Up circuit breaker / hill charts (search-aggregated; no single
  canonical chapter URL retrieved in this pass, content cross-corroborated
  across https://www.alci.dev/en/que-es/shape-up,
  https://productmanagementresources.com/shape-up-method/,
  https://nathan.substack.com/p/shape-up-for-startups)
- https://planisware.com/glossary/phase-gate-or-stage-gate
- https://athena.ecs.csus.edu/~buckley/CSc233/Stage_Gate_Project.pdf
- https://www.stage-gate.com/blog/the-stage-gate-model-an-overview/
- https://www.mindtheproduct.com/justify-your-product-decisions-and-get-stakeholder-buy-in-by-teresa-torres/
- https://maze.co/blog/making-better-product-decisions-with-teresa-torres/
- https://www.mindtheproduct.com/reversing-teresa-torres-opportunity-solution-tree-to-find-the-why-behind-solutions/
- https://johnpcutler.github.io/lenny_behaviors_and_rituals/
- https://www.fishmanafnewsletter.com/p/experiment-document-template
- https://confidence.spotify.com/docs/experiments/reviews
- https://pablok.medium.com/dealing-with-the-hippo-in-product-management-d77d90f12ddc
- https://uxcam.com/blog/using-data-to-challenge-highest-paid-persons-opinion/
- https://dovetail.com/product-development/how-to-manage-the-hippo-effect-in-product-management/
- https://www.svpg.com/pledge-to-stakeholders/ (Cagan, "Pledge To Stakeholders")
- Cagan stakeholder-management framing on "not about saying yes to
  everything" (search-aggregated from LinkedIn/summary sources of
  *Empowered*; no single primary URL retrieved verbatim in this pass —
  `[unsourced: primary Cagan text]`, treat as secondary corroboration)
- https://www.tempo.io/guides/rice-score-prioritization-framework-product-management
- https://www.growthmentor.com/blog/prioritization-frameworks
