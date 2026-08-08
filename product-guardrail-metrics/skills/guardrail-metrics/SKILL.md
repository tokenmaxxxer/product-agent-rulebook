---
name: guardrail-metrics
description: >
  Use this skill while the product role is in `hypothesis-registered`,
  before the transition to `measuring`, to name guardrail metrics that
  must not move adversarially, distinct from the primary metric. Trigger
  it alongside metric/threshold/decision-rule registration, and read it
  again once `measuring` starts so guardrail breaches are checked against
  what was named here. Do NOT use it to change the primary metric or
  threshold — those belong to the hypothesis-testing skill.
---

# Guardrail metrics for `hypothesis-registered` / `measuring`

**Belongs to state:** `hypothesis-registered` (written); read again at
`measuring` (not written there).

**What it asks the user for:** which metrics must NOT move adversarially
while the experiment runs — distinct from the primary metric (the one the
experiment is trying to move) and from secondary metrics (which explain
why the primary moved). Per
`docs/reports/research/2026-07-27-role-practice/product.md`: practitioners
separate three metric tiers, and an experiment that wins on the primary
metric but breaches a guardrail is treated as reduced-trust or stopped
outright, regardless of the primary-metric result.

**What it produces:** a non-empty guardrail-metrics list, each entry
naming the metric and the direction/threshold that counts as a breach.
This list *is* this rulebook's `critical_success_factors`
(`product-discovery.spec.json`'s field for "what must hold, or the result
doesn't count"): a guardrail named non-empty at hypothesis-registration
time and checked at measurement time is exactly a critical success
factor stated in the vocabulary this plugin already uses — no separate
field or artifact is needed to satisfy `critical_success_factors`.

**Where it is written:** the same spec/state artifact's guardrail-metrics
field — write it alongside `metric`, `threshold`, and `decision_rule` in
`product/state.md`'s companion hypothesis fields (wherever this repo's
`hypothesis-testing` skill already writes those three; guardrail metrics
join them as a fourth required field on the same artifact). This does not
change which file is the gated state file — `product/state.md` remains
the only gated write; the guardrail field lives in the hypothesis record
alongside metric/threshold/decision_rule.

**Field list:**

- Guardrail metric name (one row per guardrail metric; at least one row
  required)
- Adversarial-direction / threshold (what counts as a breach)
- Action on breach (e.g. "stop outright" or "reduced trust, re-examine")

## Precondition this skill enforces

`researching -> hypothesis-registered` (and by extension,
`hypothesis-registered -> measuring`) requires this field non-empty, the
same discipline already applied to `metric`, `threshold`, and
`decision_rule`. Do not let the package move to `hypothesis-registered`
with an empty guardrail list.

## How to run the conversation

1. After the metric/threshold/decision rule are drafted, ask the user:
   "what must not get worse while we run this — what are the guardrail
   metrics?"
2. For each one named, ask what counts as a breach (direction and
   threshold) and what should happen if it breaches (stop outright vs.
   reduced trust).
3. Write all of it into the hypothesis record before reporting
   `hypothesis-registered` complete.
4. At `measuring`, read this list back when checking incoming data — do
   not silently let a guardrail move because the primary metric is
   winning.

## Common mistakes this skill exists to prevent

- Moving to `hypothesis-registered` with metric/threshold/decision_rule
  filled in but no guardrail metrics named.
- Treating a guardrail breach as something to explain away once the
  primary metric shows a win — the whole point of naming it up front is
  that a breach is not a fresh judgment call at read-out time.
