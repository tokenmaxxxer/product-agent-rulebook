---
kind: record
subject: issue-36
role: product-discovery
loop_state: decided
---

# Execution record — issue #36

## Verdict

Mechanical application of the phase-1 proposal
(`docs/issue-36/proposals/product-discovery.md`), approved by
`APPROVE issue-36/product-discovery` (single-account mode, account
`JiwonJung94`, listed in `docs/specs/approvers.md`): adopt all five
norms proposed in (a)/(b) and reflect them into
`product/hooks/directive.sh` per the plan in (d). No threshold-bearing
metric applies to this issue — it is a plugin-reflection task, not a
hypothesis test — so there is no measured-value-vs-threshold pair to
quote; the verdict is "approved proposal content copied into the
directive without wording drift," verified structurally below.

Guardrail-metric status: not applicable — no guardrail metric was
pre-registered for this issue (meta/plugin-reflection scope, not a
product hypothesis run).

## What was done

`product/hooks/directive.sh`, three blocks edited, verbatim from the
approved proposal:

- `use_when` / CURRENT-STATE SURVEY: added the JTBD four-element tuple
  requirement (job performer, job, circumstance, desired outcome) as
  the solution-free problem-framing shape, and required the
  opportunity-solution-tree reference to use OST's four-layer
  vocabulary explicitly rather than free prose.
- `produces` / PROPOSAL: added the RICE-over-ICE prioritization
  requirement (RICE by default when comparing more than one
  opportunity/solution candidate; ICE only as an explicitly-flagged
  fallback when reach data is unavailable), the evidence-citation
  format (count + date range + paraphrase, non-admissibility of
  stated/hypothetical preference), and the open-questions /
  out-of-scope closing section.
- `hand_off` / EXECUTION JUDGMENT: added the explicit
  measured-value-next-to-threshold requirement, the explicit
  guardrail-status-statement requirement, and the OST-update
  requirement (pruned/promoted branch, ITWWS actioned-or-deferred).

No wording changes were made outside what the approved proposal
specified; `you_decide` is untouched (the proposal did not touch it).

`bash -n product/hooks/directive.sh` passes.

## Why

The approved proposal (`docs/issue-36/proposals/product-discovery.md`,
sections (a)-(c)) grounded each addition in a gap between what
`directive.sh` already claimed and what it actually enforced —
JTBD operationalizes the existing "problem stated without a solution"
line into a checkable shape, OST four-layer vocabulary closes the gap
between the directive naming `opportunity-tree.md` as a standing
document and never requiring its actual four-layer structure, RICE
extends the repo's existing numeric pre-registration discipline to
prioritization, the citation format makes the existing "customer
signal, never opinion" requirement auditable, and the record-side
additions make mechanical-verdict and guardrail-status requirements
explicit rather than merely implied. This record's upstream basis is
that approved proposal plus the underlying current-state survey and
scout brief in `docs/issue-36/reports/product-discovery/`.

## Plugin-reflection plan item 4 (record-fields gate) — deferred, not actioned

The proposal's item (d)(4) flagged evaluating whether to source core's
canon `record-fields-gate.sh` with `RECORD_FIELDS_TERMINAL_STATES` set
to this role's terminal states (`decided`, `scope-proposed`). This
repo's `product/hooks/hooks.json` currently registers only the
`SessionStart` → `directive.sh` hook (confirmed unchanged); it does not
vendor a `record-fields-gate.sh` of its own, matching the current-state
survey's finding. Per issue #37's precedent, the actual gate — and the
env-var injection point for `RECORD_FIELDS_TERMINAL_STATES` — lives in
core's own `hooks.json` schema, outside this repo's write surface.
This issue's scope (`product/hooks/directive.sh`, per the approved
proposal's target-files list) does not include that cross-repo change;
it is logged here as an open dependency on core, not silently dropped.
No change was made to `product/hooks/hooks.json`.

## Open findings

- Core-side dependency (above): `RECORD_FIELDS_TERMINAL_STATES`
  injection for this role's terminal states is unresolved pending a
  core-side `hooks.json` schema change; not actionable from this repo.
- Confirmed no-op: warrant-hunter remains core-canon-referenced only,
  never vendored in this repo, per the issue's own constraint.

## Open-finding resolution path

The `RECORD_FIELDS_TERMINAL_STATES` gap resolves once core exposes an
`env`-style field on its `hooks.json` hook entries (or an equivalent
injection mechanism); that is a core-repo change (tracked upstream of
this rulebook, not by an issue number in this repo). Once available,
a follow-up issue in this repo wires
`RECORD_FIELDS_TERMINAL_STATES="decided scope-proposed"` to core's
canon `record-fields-gate.sh` for this role, matching the pattern
issue #37 established for the `implementation` role's sibling gates.
The warrant-hunter item needs no resolution path — it is a confirmed
no-op, not an open item.

## Next steps

- Track the core `hooks.json` env-injection capability upstream; open
  a follow-up issue in this repo once it lands, to finish wiring
  `RECORD_FIELDS_TERMINAL_STATES` for this role's terminal
  `loop_state`s (`decided`, `scope-proposed`).
- No further phase-2 work is expected on `directive.sh` itself unless
  a future issue revisits these norms; this issue's scope ends here.
