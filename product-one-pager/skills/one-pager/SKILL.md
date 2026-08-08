---
name: one-pager
description: >
  Use this skill when the product role is in the `scoping` state and needs
  to turn a handed-in idea into a structured one-pager before evidence
  gathering starts. Trigger it right after `idle -> scoping`. Do NOT use it
  to draft a solution spec — the whole point of this skill is to keep the
  problem statement separate from any proposed solution.
---

# One-pager drafting

**Belongs to state:** `scoping`.

**What it asks the user for**, one at a time, in this order (Reforge/
Lenny's one-pager shape, per
`docs/reports/research/2026-07-27-role-practice/product.md`):

1. **Background/context** — why this idea exists, what prompted it.
2. **Problem statement** — asked explicitly *without* a solution attached.
   If the user's answer already contains a proposed solution, the agent
   asks them to restate just the problem first ("before we get to how —
   what's the problem, in the customer's terms?"). This separation is the
   one-pager's defining discipline; do not let it collapse into a single
   "here's what we should build" paragraph.
3. **Candidate hypotheses** — early guesses at what might address the
   problem, kept labeled as hypotheses, not commitments.
4. **Known risks** — anything that could make the idea wrong or costly if
   pursued.
5. **Goals/success metrics** — a first cut, refined later by
   `hypothesis-registered`, not a final pre-registered metric yet.
6. **Target market** (`target_market`) — who this is for, specifically
   enough to size and to test against.
7. **Market size rationale** (`market_size_rationale`) — the reasoning
   behind the size estimate, not a bare number with no derivation shown.
8. **Competitive alternatives** (`competitive_alternatives`) — what the
   target market does today instead, including "nothing"/"a spreadsheet"
   as valid answers.
9. **Differentiator** (`differentiator`) — why this wins against those
   alternatives.
10. **Timing rationale** (`timing_rationale`) — why now, not a year ago or
    a year from now.
11. **Go-to-market plan** (`go_to_market_plan`) — a first cut at how this
    reaches the target market once built.

These six (`target_market`, `market_size_rationale`,
`competitive_alternatives`, `differentiator`, `timing_rationale`,
`go_to_market_plan`) are this rulebook's mapping of
`product-discovery.spec.json`'s opportunity-framing fields: they describe
the opportunity before any hypothesis is scored or tested, the same
"problem, not solution, not yet tested" moment the original five fields
already own.

**What it produces:** `product/one-pager.md`.

**Where it is written:** `product/one-pager.md`, in this repository's
working tree — a plain artifact write, not the state file. This write is
never gated by `state-gate.sh`; only the record file governed by
`docs/specs/state-machine.md` is.

**Field list** (matches the template headings below, each required
non-empty before the skill reports the one-pager complete):

- Background / Context
- Problem Statement
- Candidate Hypotheses
- Known Risks
- Goals / Success Metrics
- Target Market
- Market Size Rationale
- Competitive Alternatives
- Differentiator
- Timing Rationale
- Go-to-Market Plan

Template: `product-one-pager/skills/one-pager/templates/one-pager-template.md`.

## How to run the conversation

Ask one field at a time, in the order above. Do not batch all eleven
questions into one message — the practice research's field list is a
sequence practitioners fill in that order for a reason (background before
problem, problem before hypotheses, opportunity framing last once the
problem itself is fixed). After each answer, write it into
`product/one-pager.md` under the matching heading before asking the next
question.

Once all eleven fields are non-empty, tell the user the one-pager is
complete and that the next step is affirming the outcome framing (the
`scoping -> scoping` row in `docs/specs/state-machine.md`'s transition
table) before moving to `researching`. If the user's affirmation is vague
("that sounds about right"), do not treat it as a green light — ask where
that read came from ("is that from a customer conversation, or your own
read?"), per the product interaction research's core rule that a vague
response is a prompt to re-ask for its evidentiary source.

## Common mistakes this skill exists to prevent

- Writing a solution into the "Problem Statement" field.
- Treating a partially-filled one-pager as good enough to move to
  `researching` — all eleven fields must be non-empty.
- Accepting silence or a one-word "yes" as the `scoping -> scoping`
  affirmation without asking where the read came from.
- Stating a market size with no rationale, or a differentiator with no
  named competitive alternative to differentiate against.
