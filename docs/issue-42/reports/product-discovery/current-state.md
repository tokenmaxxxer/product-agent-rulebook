---
kind: survey
subject: issue-42
role: product-discovery
---

# Current-state survey — issue #42

## Scope of this survey

Issue #42 asks this rulebook to give its own already-adopted methodology
(issue #36's proposal, reflected into `directive.sh` by issue #41/#36's
phase 2) a mechanical enforcement layer at the level of the
`implementation` rulebook's gate machine — not new methodology content.
Four asks: directive deepening (phase 1 and phase 2, per-facet,
no one-line summaries), a methodology gate on `produces`-required
elements (with state tracking if an order constraint exists), gate
tests, and agents/checklists if a repeated procedure is required.

## What already exists

**`product/hooks/directive.sh`** — a `core_role_directive` stub. Its
four blocks (`you_decide`/`use_when`/`produces`/`hand_off`) already carry
issue #36's adopted content: assumption-mapping + Mom Test (RESEARCH),
JTBD tuple + OST branch vocabulary (CURRENT-STATE SURVEY), pre-registered
hypothesis package + RICE/ICE + evidence-citation format (PROPOSAL),
mechanical-verdict + OST-update + guardrail-status (EXECUTION JUDGMENT).
This is prose discipline only — nothing parses or rejects a write that
skips a required element. Issue #42 is asking for exactly that missing
layer, not new prose.

**Record-path defect (load-bearing for the gate design):**
`CLAUDE_ROLE=product-discovery` in this session (confirmed:
`echo "$CLAUDE_ROLE"` → `product-discovery`). `core_role_directive`'s own
closing line therefore emits `RECORD: docs/issue-<n>/reports/
product-discovery.md`. But `directive.sh`'s `hand_off` block states the
record path as `docs/issue-<n>/reports/product.md` — a stale name from
before the `product` -> `product-discovery` role rename this repo's
banner (`Interaction protocol for role 'product-discovery'`) and branch
naming (`issue-<n>/product-discovery`) already reflect. Consequence: core
canon's already-globally-wired `record-fields-gate.sh` (fired via
`core/hooks/hooks.json`'s `matcher: ".*"` on every `Write|Edit|
MultiEdit`) keys its target regex on `CLAUDE_ROLE`
(`docs/issue-<n>/reports/product-discovery\.md`) and would never match a
write to `product.md` — meaning §20's field check (what/why/upstream-
basis/loop_state/open-findings) has never actually engaged on this
role's real phase-2 record. This is a genuine, currently-silent gate
gap, not a hypothetical one; fixing the path string is a prerequisite
for any new gate this proposal adds, otherwise the new gate inherits the
same blind spot.

**No local `product/hooks/*-gate.sh` file exists.** `find product/hooks
-type f` returns only `directive.sh` and `hooks.json`; `hooks.json`
registers only the `SessionStart` -> `directive.sh` hook, no
`PreToolUse` entries of its own. Every enforcement this role currently
gets on `docs/issue-<n>/proposals/*.md` or its current-state survey is
whatever core's global gates (`board-gate`, `approval-gate`, `gh-guard`,
`trailer-gate`, `record-fields-gate` — record-only, `handbook-trigger-
gate`) happen to cover, none of which check *methodology-specific*
content (JTBD tuple present, OST branch named, RICE/ICE score present
when >1 candidate, evidence-citation format, hypothesis package fields).

**Repo test harness**: `tests/run-gate-tests.sh`, `tests/parse-check.sh`,
`tests/deny-only-check.sh` exist at repo root (sibling to `product/`),
matching the shape core canon expects a rulebook's own harness to have
(per `docs/handbooks/role-gates-tests.md`: `stub-check.sh` invoked by
path against core's install root, target directory passed as arg 1).
No `product`-specific gate test file exists yet inside `tests/`.

## Exemplars examined (per issue #42's own pointers)

- **`implementation` rulebook** (this session's read of a sibling
  checkout, `implementation-rulebook-issue-61-implementation`): its own
  transition history (issue #53's proposal) shows the target shape —
  role-specific gates (`coding-progress-gate.sh`, `hunt-guard.sh`,
  `hunt-state.sh`, `state.sh`) kept local because they are role-unique
  state machines, while the three generic canon gates (`trailer-gate`,
  `record-fields-gate`, `handbook-trigger-gate`) were *deleted* from the
  local tree once `core/hooks/hooks.json`'s global `matcher: ".*"` was
  confirmed to already fire them — i.e. "400 lines of hook machine" in
  that rulebook is role-*specific* logic (progress-state tracking, hunt
  cadence, guard checks against a state file), not a re-implementation
  of what core already does generically.
- **`pricing` rulebook's `pricing/hooks/methodology-gate.sh`**
  (`pricing-rulebook-issue-10-pricing`, read this session): the direct
  structural template for a role-owned methodology gate — PreToolUse,
  targets `docs/issue-<n>/proposals/*pricing*.md` and `docs/issue-<n>/
  reports/pricing.md` via a path regex, resolves project root
  defensively (env hint, then git toplevel fallback), reconstructs the
  *resulting* text for `Write`/`Edit`/`MultiEdit` (denies when it
  can't), then runs a checklist of required-element substring checks
  (method named, family named conditionally, inputs stated, a
  gate-check-result phrase present, numbers labeled, a residual list)
  and denies naming every missing element by slug. Fails closed via a
  `trap`-wrapped `__fc` on internal error, and has a role-scoped kill
  switch (`PRICING_METHODOLOGY_GATE_OFF`).
- **`core/hooks/record-fields-gate.sh` and `docs/handbooks/canon-
  scripts.md` / `role-gates-tests.md`** (`tokenmaxxxer-core` checkout):
  confirms the reference-not-copy boundary — only files under
  `core/hooks/` (and listed in `core/hooks/tests/canon-manifest.txt`)
  are canon; a role-owned gate like `methodology-gate.sh` living under
  `product/hooks/` is *not* a canon file and is written fresh, not
  copied from `pricing`'s copy (only its *shape* is a precedent).
  `role-gates-tests.md` documents `RECORD_FIELDS_TERMINAL_STATES`
  (space-separated `loop_state` values) as the injection point for a
  role's non-default terminal states — this role's terminal states
  (`decided`, `scope-proposed`, per issue #36's adopted `hand_off` text)
  are not yet set anywhere in `product/hooks/hooks.json`, another silent
  gap: the global `record-fields-gate.sh` currently treats only
  `landed` as terminal for this role, so a record correctly marked
  `decided` or `scope-proposed` would still be told it's missing
  next-steps/resolution-path sections it doesn't need.

## What's thin, missing, or contested

- No PreToolUse gate on `docs/issue-<n>/proposals/*.md` (or the
  current-state survey) checks any of issue #36's required elements
  (JTBD tuple, OST branch, RICE/ICE-when->1-candidate, evidence-citation
  format, hypothesis package fields).
- No order/state enforcement exists for this role's own ordering
  constraint — survey (current-state, JTBD-framed) before proposal
  (hypothesis package) before verdict (phase-2 record) — beyond the
  existing phase-1/phase-2 human-Approve gate, which enforces the
  *survey-and-proposal-vs-execution* split but nothing *inside* phase 1.
- `RECORD_FIELDS_TERMINAL_STATES` is unset for this role in
  `product/hooks/hooks.json`, so the global record-fields-gate silently
  misjudges non-`landed` terminal states this role actually uses.
- The `product.md`/`product-discovery.md` record-path mismatch (above)
  means even the enforcement core already provides has not been firing.
- No repo-root gate test file exists for a future `product`-specific
  gate; `tests/run-gate-tests.sh`'s current scope needs confirming
  before assuming it will pick up a new gate test file automatically.
- No agent or checklist file exists under `product/agents/` (directory
  itself absent) for any repeated phase-1 procedure (e.g. the
  assumption-mapping 2x2 scoring, or the RICE-score-per-candidate loop
  when multiple opportunities are compared) — issue #42's ask 4 is
  conditional ("필요 시"); whether this is actually needed depends on
  whether the methodology gate's checklist substitutes for it (a gate
  can *check* a RICE score exists; it cannot *compute* one, which is
  where a checklist/skill still earns its place).

## Implication for phase 1

The proposal should (a) fix the `product.md` -> `product-discovery.md`
record-path defect and set `RECORD_FIELDS_TERMINAL_STATES` so the
*existing* core gate actually engages, (b) deepen `directive.sh`'s four
blocks into concrete, facet-level, checkable requirements (not
one-line summaries) mirroring the level of detail issue #36 already
wrote in prose, now stated so a gate can check for them mechanically,
(c) design (not yet implement — phase 1 only) a `product/hooks/
methodology-gate.sh` on the pricing-gate template, targeting this
role's own required elements and encoding the survey-before-proposal
order constraint via file-existence/state checks, (d) design its gate
tests, and (e) judge whether a checklist/skill addition is warranted
for the RICE-scoring loop, given the existing `hypothesis-testing`,
`opportunity-solution-tree`, and `guardrail-metrics` skills already
cover the state-machine side.
