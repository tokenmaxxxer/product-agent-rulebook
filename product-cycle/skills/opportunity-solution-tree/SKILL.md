---
name: opportunity-solution-tree
description: >
  Use this skill whenever the `scoping -> scoping` self-loop fires — i.e.
  whenever opportunity/outcome framing is drafted or re-affirmed with the
  user — to update the living Opportunity Solution Tree. This is
  cross-cutting: it runs on its own cadence, independent of any single
  hypothesis's state, and its artifact is never the product-cycle state
  file. Do NOT use it to register a hypothesis or to gate any transition —
  it has no gate.
---

# Opportunity Solution Tree maintenance

**Belongs to:** the `scoping -> scoping` self-loop (cross-cutting; not a
one-time step of any single state). Teresa Torres's practice treats this as
continuous, weekly-cadence maintenance, not a phase that starts and ends —
see `docs/reports/research/2026-07-27-role-practice/product.md`.

**What it asks the user for:** which opportunity or solution the tree
should be updated with this cycle, sourced back to specific customer
interview evidence where available.

**What it produces:** the Opportunity Solution Tree, four layers, top to
bottom:

1. **Desired outcome** — one node, a business metric.
2. **Opportunities** — customer needs/pains/desires (can nest).
3. **Candidate solutions** — per opportunity.
4. **Assumption tests** — per solution, at the leaves.

**Where it is written:** `product/opportunity-tree.md`.

**This artifact is explicitly outside the gate.** It is not
`product/state.md`, and no row in `transition-rules.md` binds to it —
`state-gate.sh` does not check writes to this file at all. Update it as
often as new interview evidence arrives; do not wait for a state
transition to justify writing to it.

## How to run the conversation

1. When the `scoping -> scoping` affirmation moment comes up, ask the user
   which opportunity or solution should be added or updated in the tree
   this cycle.
2. Confirm which desired outcome node it hangs under (create one if none
   exists yet).
3. Ask whether new interview evidence supports it, and if so, record the
   evidence source (which customer conversation) alongside the
   opportunity/solution node — per the interaction research's rule that a
   vague, unsourced claim should not be written into the tree as if it
   were evidence.
4. Write/update `product/opportunity-tree.md` with the four-layer
   structure above.

## Common mistakes this skill exists to prevent

- Treating this as a one-time artifact instead of a living document
  updated on an ongoing cadence.
- Recording a stakeholder's unsourced opinion as if it were customer
  evidence in the tree.
- Gating any state transition on this file — it has none; it stays
  outside `product/state.md` and outside `state-gate.sh` entirely.
