---
kind: record
subject: issue-42
role: product-discovery
loop_state: decided
hypothesis: docs/issue-42/proposals/2026-07-31-methodology-gate-machine.md
---

# Record — plugin-set implementation for product-discovery methodology gates — issue #42

## What was done

Approved via `APPROVE issue-42/product-discovery` (single-account mode,
issue #42 comment). Executed the proposal at
`docs/issue-42/proposals/2026-07-31-methodology-gate-machine.md`
in full (its section 8 migration plan), basis: PR #43.

1. **Five independent, self-installable plugins** created at repo root,
   replacing the monolithic `product/` plugin (now deleted):
   `product-one-pager`, `product-opportunity-solution-tree`,
   `product-assumption-mapping`, `product-hypothesis-testing`,
   `product-guardrail-metrics`. Each carries its own
   `.claude-plugin/plugin.json` (single-methodology description),
   `hooks/hooks.json` (SessionStart→directive.sh,
   PreToolUse `Write|Edit|MultiEdit`→methodology-gate.sh),
   `hooks/directive.sh` (facet-scoped `core_role_directive` slice —
   no one-line summaries), `hooks/methodology-gate.sh` (fail-closed,
   per-plugin kill switch, own deny message), and its moved
   `skills/<name>/` (moved via `git mv`, not copied).
2. **Phase-1/phase-2 norms as composition**, per the proposal's
   sections 3–4: survey write fires `product-one-pager` +
   `product-opportunity-solution-tree`; proposal write fires
   `product-assumption-mapping` + `product-hypothesis-testing` +
   `product-guardrail-metrics` + the order-constraint half of
   `product-opportunity-solution-tree`; record write fires
   `product-opportunity-solution-tree` + `product-hypothesis-testing` +
   `product-guardrail-metrics`. No sixth aggregating gate was written —
   this is the intended independently-installable-gates shape.
3. **Order constraint** (조사→근거→채택): duplicated as a copy-identical
   filesystem-existence check across the four proposal-checking
   plugins, denying "proposal write precedes its own current-state
   survey" before any plugin's own facet check runs.
4. **Gate tests**: one file per plugin under `tests/`
   (`product-<name>-gate-tests.sh`), covering pass/deny per facet,
   malformed-stdin fail-closed, unrelated-path pass-through,
   kill-switch pass, and Edit-reconstruction-failure deny — 57 cases
   total, all passing. Wired into `tests/run-gate-tests.sh` as five
   subprocess invocations (no new dispatch mechanism).
5. **Prerequisite record-path fix** (proposal section 0): the stale
   `docs/issue-<n>/reports/product.md` path and the "YOUR RECORD"
   paragraph now live in `product-hypothesis-testing/hooks/
   directive.sh`'s `hand_off`, corrected to
   `docs/issue-<n>/reports/product-discovery.md` — this record's own
   path is the proof it now matches.
6. **`product/` retired** — its skills moved out, its stale
   `directive.sh`/`hooks.json`/`plugin.json` deleted; no remaining
   reference in `docs/handbooks` or `docs/specs` (updated
   `docs/handbooks/tests.md` to describe the five-plugin dispatch).
7. **Marketplace registration**: `.claude-plugin/marketplace.json` now
   lists the five `product-*` plugins, replacing the single `product`
   entry.

## Why

Per the approver's structural correction (issue #42 comment): a single
bundled gate file does not match the granularity core's own
`freelunch`/`scout` marketplace precedent sets for independently
installable, independently kill-switchable methodology enforcement.
Five plugins let one broken gate (e.g. `product-guardrail-metrics`)
never block another (e.g. `product-one-pager`) from firing, and let
each methodology's directive slice stay concrete and facet-level
instead of a one-line summary, per issue #42's original ask.

OST branch: this issue closes the **candidate solutions** branch of
the product-discovery role's own standing methodology work — the
mechanical-enforcement gap identified in issue #36 is now closed by
these five plugins; promoted (not pruned).

ITWWS: deferred — actioning it (checking whether these plugins actually
change downstream behavior across a real phase-1/phase-2 cycle) needs
a subsequent issue to run against, since this issue's own scope is the
enforcement machinery itself, not a methodology cycle to observe it on.

## Open findings

- **`RECORD_FIELDS_TERMINAL_STATES` injection remains unresolved**,
  same as `implementation` rulebook's issue #37/#53 precedent: core's
  `record-fields-gate.sh` env-var injection point lives in core's own
  `hooks.json`, outside this repo's write surface. Not set locally
  (setting it here would mean re-vendoring gate logic this repo
  already removed). **Confirmed live, not hypothetical**: writing this
  very record with `loop_state: decided` was denied by core's global
  `record-fields-gate.sh` demanding `next-steps`/`open-finding-
  resolution-path` sections that `decided`/`scope-proposed` records
  should be exempt from — proof the record-path fix (section 0) now
  makes this role's real record reach core's gate, and proof the
  `TERMINAL` env-var gap is still open on core's side.
- `tests/run-gate-tests.sh`'s original `record-fields-gate.sh`/
  `trailer-gate.sh` cases (exercising files removed from this repo by
  the prior core-canon-reference migration, issue #37) still report
  `exit-127` — pre-existing breakage from that migration, out of this
  issue's scope; the five new plugin suites appended after them all
  pass independently of that stale section.
- No new agent/checklist file added, per the proposal's section 7 —
  each plugin's existing skill already covers the repeated procedure
  its gate only checks the presence of an artifact from. No follow-up
  needed.

## Next steps

1. Inject `RECORD_FIELDS_TERMINAL_STATES="decided scope-proposed"` for
   this role on core's side (open upstream dependency, above) — the
   resolution path for that open finding.
2. Decide the fate of `run-gate-tests.sh`'s stale legacy-gate cases
   (restore coverage against core's actual canon gates, or delete them)
   — the resolution path for that open finding.
3. Run this five-plugin set through one real phase-1→phase-2 cycle to
   action the deferred ITWWS above.
