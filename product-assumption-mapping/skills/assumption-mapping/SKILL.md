---
name: assumption-mapping
description: >
  Use this skill when the product role is in the `researching` state and
  needs to decompose a candidate solution into testable assumptions before
  a hypothesis can be registered. Trigger it right after `scoping ->
  researching`. It also injects the Mom Test's three interview rules any
  time the agent is about to draft interview questions while in this
  state. Do NOT use it to write the hypothesis statement itself — that is
  the last step of `researching`, done once a top-quadrant assumption has
  enough evidence.
---

# Assumption mapping for `researching`

**Belongs to state:** `researching`.

**What it asks the user for** (or derives from interview evidence already
on file): candidate assumptions underlying the idea, across Teresa
Torres's five categories (per
`docs/reports/research/2026-07-27-role-practice/product.md`):

1. **Desirability** — do customers actually want this?
2. **Viability** — does the business benefit?
3. **Feasibility** — can it be built?
4. **Usability** — can customers use it?
5. **Ethical** — could it cause harm?

For each assumption gathered, ask (or infer from evidence on file) two
ratings:

- **Evidence strength**: weak -> strong.
- **Importance**: less critical -> critical.

**What it produces:** an assumption map — a 2x2 grid (evidence strength ×
importance) with each assumption plotted as a point. Assumptions landing in
the critical + weak-evidence quadrant become the priority test list, each
tagged with which of the four assumption-test types will be used to test
it: prototype test, one-question survey, data mining, or engineering
spike.

**Where it is written:** `product/assumption-map.md` — a plain artifact
write, not the state file. Never gated by `state-gate.sh`.

**Field list**, per assumption row:

- Assumption text
- Category (desirability / viability / feasibility / usability / ethical)
- Evidence strength (weak / medium / strong)
- Importance (less critical / critical)
- Quadrant (derived: critical+weak = priority)
- Assumption-test type chosen, if in the priority quadrant (prototype
  test / one-question survey / data mining / engineering spike)

## `evidence_log`

Every one-line evidence citation this skill already writes (interview/
observation count, date, paraphrase) *is* `product-discovery.spec.json`'s
`evidence_log` field — no separate log or artifact is needed. Each
citation resolves to a concrete source: a file path, a commit sha, or a
named interview record — never a bare claim with nothing behind it. This
repository already follows a `reference_resolution` rule as an unwritten
convention (no orphan references: a citation that cannot be traced to a
path/sha/source is not written into the assumption map); this section
makes that rule explicit so `evidence_log` and reference resolution are
documented, not just practiced.

## Standing directive: the Mom Test

Any time this skill (or the agent generally, while in `researching`) is
about to draft interview questions, inject these three rules before
drafting them, regardless of interview format (continuous discovery or
JTBD switch interview):

1. Ask about the customer's life and past behavior, not their opinion of
   your idea.
2. Ask about specifics that already happened, not hypotheticals about the
   future.
3. The interviewer should talk no more than roughly 20% of the time —
   let the customer carry the conversation.

Treat three kinds of answers as unreliable and discard them rather than
recording them as evidence: compliments, hypothetical "I would..."
statements, and feature wishlists.

## How to run the conversation

1. Ask the user to name candidate assumptions, one category at a time
   (desirability, then viability, then feasibility, then usability, then
   ethical) — or pull them from interview notes already on file if the
   user points you at them.
2. For each assumption, ask for (or propose, from evidence) its evidence
   strength and importance rating.
3. Write each assumption as a row in `product/assumption-map.md` as you go
   — do not batch all of it into one write at the end.
4. Once assumptions are plotted, tell the user which ones fall in the
   critical + weak-evidence quadrant and propose which to test first, and
   with which of the four test types.
5. When enough evidence exists on the priority assumption(s), move to
   drafting the hypothesis statement ("We believe / we will know" — see
   the existing `hypothesis-testing` skill) and hand off to
   `guardrail-metrics` before `researching -> hypothesis-registered`.

## Common mistakes this skill exists to prevent

- Treating a compliment, an "I would use that," or a feature request as
  evidence for an assumption's strength.
- Skipping straight to a hypothesis before any assumption has been mapped.
- Letting the agent talk more than the customer when drafting or running
  interview questions in this state.
