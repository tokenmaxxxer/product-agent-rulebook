---
kind: proposal
subject: issue-42
role: product-discovery
---

# Proposal — methodology plugin set for product-discovery — issue #42

Full findings backing this proposal:
`docs/issue-42/reports/product-discovery/current-state.md` and
`docs/issue-42/reports/product-discovery/scout-brief.md`.

Phase 1 only. No plugin code, hook file, or test file is created or
changed by this document — it specifies what phase 2 will build. This
document contains no approval of any kind. Phase 2 requires an Approve
per contract v3 s19 from an account listed in `docs/specs/approvers.md`.

**Revision note (rework per approver's 요구 정정 comment on PR #43):**
the prior version of this proposal centralized every methodology check
in one `product/hooks/methodology-gate.sh` file inside the existing
monolithic `product` plugin. The approver's structural correction: this
role's five adopted methodologies must each become an **independent
plugin** (the shape core's own marketplace already uses for `freelunch`
and `scout` — one rulebook, several self-contained plugins), and the
phase-1 (기획서) and phase-2 (산출물) norms are not single gates but
**compositions of that plugin set** — the plugin list and how they
combine is the actual design, not an afterthought. Sections 2–5 below
replace the prior single-gate design entirely; section 1's facet
tables are unchanged (they were never the defect) but are now labeled
by which plugin owns each row.

## 0. Prerequisite fix (do first, phase 2, before the new plugins)

`directive.sh`'s `hand_off` block states the record path as
`docs/issue-<n>/reports/product.md`. `CLAUDE_ROLE=product-discovery` in
this session, and `core_role_directive`'s own closing line already
emits `RECORD: docs/issue-<n>/reports/product-discovery.md` — so core
canon's globally-wired `record-fields-gate.sh` has never actually
matched this role's real record file. Phase 2 corrects `hand_off`'s
prose to `docs/issue-<n>/reports/product-discovery.md` and sets
`RECORD_FIELDS_TERMINAL_STATES="decided scope-proposed"` in the role's
top-level hooks env (per `role-gates-tests.md`'s documented injection
point), so the check core already runs everywhere else starts running
here too. This is core-generic machinery, not one of the five
methodology plugins, and stays a single role-level fix — not
distributed across the plugin set.

## 1. Adopted-methodology facets (unchanged content, now plugin-tagged)

Issue #36's already-approved methodology, restated per-facet so each
row maps to exactly one gate check owned by exactly one plugin
(section 2).

### Phase-1 facets (current-state survey + proposal)

| Facet | Owning plugin | Judgment criterion | Prohibition |
|---|---|---|---|
| Problem framing | `product-one-pager` | Stated as a JTBD 4-tuple (performer, job, circumstance, desired outcome) *before* any solution name appears | A solution name appearing before the tuple is stated is a violation — the survey must restate the issue's own words if the issue text embeds a solution |
| OST placement | `product-opportunity-solution-tree` | The relevant branch (outcome / opportunity / candidate solutions / discriminating assumption test) named using OST's four-layer vocabulary | Free prose describing "what we're building and why" without naming which OST layer it sits at does not satisfy this |
| Evidence citation | `product-assumption-mapping` | Each cited data point: interview/observation count + approximate date range + one-line paraphrase, one line per citation | A bare claim ("users want X") with no count/date/paraphrase triple is not admissible |
| Prioritization | `product-assumption-mapping` | RICE score (Reach, Impact, Confidence, Effort, resulting score) per candidate, *only required when more than one opportunity or solution candidate is compared* | ICE permitted only when explicitly flagged as a fallback with reach stated unavailable — an unflagged ICE score when RICE was computable is a violation |
| Hypothesis package | `product-hypothesis-testing` | Named metric + numeric threshold + decision rule (go/kill/pivot), ITWWS follow-up stated | A threshold expressed as "significant improvement" with no number is prose, not a registration |
| Guardrail declaration | `product-guardrail-metrics` | Guardrail metric(s) named non-empty at the same point the hypothesis is registered | An empty or absent guardrail list at registration time is a violation, not "TBD" |
| Scope boundary | none (core-generic) | Open questions section and explicitly out-of-scope items, both present | Absence of either is a defect — checked by core's `record-fields-gate.sh`, not a new plugin |

### Phase-2 facets (record)

| Facet | Owning plugin | Judgment criterion | Prohibition |
|---|---|---|---|
| Verdict mechanics | `product-hypothesis-testing` | Measured metric value stated adjacent to the pre-registered threshold it's compared against | Re-deriving or restating the decision rule with new judgment at verdict time is a violation — the rule was fixed in phase 1 and is applied, not reconsidered |
| Guardrail status | `product-guardrail-metrics` | Guardrail metric status stated explicitly at the same measurement moment, even when unbreached | Silence on a guardrail is a missing field, not "assumed fine" |
| OST update | `product-opportunity-solution-tree` | Which branch was pruned (kill) or promoted (go/pivot), in the same four-layer vocabulary as phase 1 | A verdict with no OST-branch disposition leaves the standing tree stale |
| ITWWS | `product-hypothesis-testing` | Actioned or explicitly deferred with a stated reason | Silently dropping the pre-committed follow-up is a violation |
| Record identity | none (core-generic) | `kind` + `loop_state` present, drawn from this role's vocabulary | Covered by core's `record-fields-gate.sh` once section 0's fix lands — not re-checked by any plugin |

## 2. The plugin set (the design's actual body)

Five independent plugins, one per adopted methodology — mirroring how
core's marketplace ships `freelunch` and `scout` as separate,
self-contained plugins rather than one bundled "core-extras" plugin.
Each plugin is self-contained: it owns its existing skill (already
shipped under the current monolithic `product` plugin), a directive
slice, a gate script fragment enforcing only its own facet rows from
section 1, and its own test file. None of the five references
another's internals; they compose only through the phase-1/phase-2
norms in sections 3–4, and through the shared write-surface/root-
resolution mechanics in section 5 (duplicated per plugin, not a shared
library — each plugin must stay standalone-installable, per the
`freelunch`/`scout` precedent).

| Plugin | Methodology | Components | Phase-1 check | Phase-2 check |
|---|---|---|---|---|
| `product-one-pager` | JTBD problem-without-solution framing | `skills/one-pager/` (moved as-is), `hooks/directive.sh` (JTBD facet slice), `hooks/methodology-gate.sh` (survey-only), `tests/one-pager-gate-tests.sh` | JTBD-tuple language present before any solution name | — (one-pager has no phase-2 obligation) |
| `product-opportunity-solution-tree` | OST placement and disposition | `skills/opportunity-solution-tree/`, `hooks/directive.sh`, `hooks/methodology-gate.sh` (survey + record), `tests/ost-gate-tests.sh` | OST four-layer vocabulary present | Pruned/promoted disposition in OST vocabulary |
| `product-assumption-mapping` | Evidence-strength/importance scoring, RICE prioritization | `skills/assumption-mapping/`, `hooks/directive.sh`, `hooks/methodology-gate.sh` (proposal-only), `tests/assumption-mapping-gate-tests.sh` | Evidence-citation format when citations exist; RICE (or flagged ICE) when 2+ candidates compared | — |
| `product-hypothesis-testing` | Pre-registered hypothesis: metric, threshold, decision rule, ITWWS | `skills/hypothesis-testing/`, `hooks/directive.sh`, `hooks/methodology-gate.sh` (proposal + record), `tests/hypothesis-testing-gate-tests.sh` | Digit-bearing metric/threshold + decision-rule language + ITWWS mention | Verdict-adjacency (metric near threshold, no re-derivation); ITWWS actioned-or-deferred-with-reason |
| `product-guardrail-metrics` | Guardrail non-emptiness and status tracking | `skills/guardrail-metrics/`, `hooks/directive.sh`, `hooks/methodology-gate.sh` (proposal + record), `tests/guardrail-metrics-gate-tests.sh` | Guardrail keyword present, not immediately followed by "none"/"n/a" | Guardrail status word present at verdict time |

Each plugin's `.claude-plugin/plugin.json` names its own single
methodology in its `description` field (mirroring the current
`product/.claude-plugin/plugin.json` pattern, one methodology per
description rather than the current five-methodology run-on
sentence). All five register as separate entries in
`.claude-plugin/marketplace.json`'s `plugins` array, replacing the
current single `product` entry.

### Order constraint (phase-1 → phase-1, cross-plugin)

The "조사→근거→채택" ordering issue #42 flags is not owned by any
single plugin (it constrains proposal writes against the *survey*
file, which `product-one-pager` and `product-opportunity-solution-tree`
jointly produce). It is checked as a **shared precondition**: each of
the four plugins with a proposal-write check (`product-assumption-
mapping`, `product-hypothesis-testing`, `product-guardrail-metrics`,
and `product-opportunity-solution-tree`'s proposal half) runs the same
one-line filesystem existence test — `docs/issue-<n>/reports/product-
discovery/current-state.md` must exist — before evaluating its own
facet, denying with `"proposal write precedes its own current-state
survey"` if absent. This is copy-identical across the four gate
scripts (a few lines, not a shared library — consistent with keeping
each plugin standalone-installable), not a sixth plugin: the check has
no methodology content of its own, it only sequences the other four.

## 3. Phase-1 norm = composition

The 기획서 규범 (current-state survey + proposal) is not a single
gate — it is what you get when all five plugins are installed
together and each fires on its own surface:

- Survey write (`docs/issue-<n>/reports/product-discovery/current-
  state.md`): `product-one-pager` (JTBD tuple) + `product-opportunity-
  solution-tree` (OST placement) fire; the other three plugins ignore
  this path (`exit 0`, not their business).
- Proposal write (`docs/issue-<n>/proposals/*product-discovery*.md`):
  `product-assumption-mapping` (evidence + prioritization) +
  `product-hypothesis-testing` (hypothesis package) + `product-
  guardrail-metrics` (guardrail declared) + `product-opportunity-
  solution-tree`'s order-constraint check all fire independently; each
  denial is that plugin's own message (no aggregation across plugins —
  a proposal missing two elements owned by two different plugins gets
  two separate PreToolUse denials in sequence, one per plugin, which is
  the intended `freelunch`/`scout`-style behavior of independently
  installable gates rather than one combined verdict).
- Scope boundary (open questions / out-of-scope) stays core's
  `record-fields-gate.sh` job — no plugin re-implements it.

## 4. Phase-2 norm = composition

The 산출물 규범 (record) is the same five-plugin set firing on the
record path (`docs/issue-<n>/reports/product-discovery.md`):
`product-opportunity-solution-tree` (disposition) + `product-
hypothesis-testing` (verdict-adjacency, ITWWS) + `product-guardrail-
metrics` (status) fire; `product-one-pager` and `product-assumption-
mapping` have no phase-2 obligation and stay silent on this path.
Record identity (`kind`/`loop_state`) stays core's job per section 1.

## 5. Shared mechanics (duplicated per plugin, not a shared library)

Each plugin's `hooks/methodology-gate.sh` follows the same structural
template as `pricing/hooks/methodology-gate.sh` (scout-brief "Adopt"),
written fresh per plugin, never copied verbatim from the exemplar or
from a sibling plugin in this set:

- PreToolUse, matcher `Write|Edit|MultiEdit`.
- `set -uo pipefail`, `trap`-wrapped fail-closed-on-nonzero/non-2 exit.
- Per-plugin kill switch, e.g. `PRODUCT_ONE_PAGER_GATE_OFF=1`,
  `PRODUCT_HYPOTHESIS_TESTING_GATE_OFF=1` (independently toggleable —
  another reason these are five plugins and not one gate with five
  internal sections).
- `command -v python3` check; deny (fail closed) if absent.
- Read stdin payload, deny on empty/unparseable JSON or non-dict
  `tool_input`.
- Root resolution: `CLAUDE_PROJECT_DIR` hint validated by `_plausible`/
  `_under`, else `git rev-parse --show-toplevel`, else cwd.
- Path resolution against root; `exit 0` if the resolved path matches
  none of this plugin's own target regex(es) (not this plugin's
  business — including paths another plugin in the set handles).
- Reconstruct resulting text for `Write`/`Edit`/`MultiEdit` (verbatim
  reconstruction pattern from both exemplars); deny with "cannot
  determine resulting content" on reconstruction failure.

Each plugin denies with its own methodology's message, role and plugin
name resolved from `CLAUDE_ROLE`/the plugin's own name — e.g.
`"product-hypothesis-testing: refused — proposal write is missing
required element(s): threshold-digit, decision-rule. Per
docs/issue-36/..., every registered hypothesis must state a numeric
threshold and a decision rule."`

## 6. Gate tests (one file per plugin)

Each plugin's `tests/<plugin>-gate-tests.sh` covers only its own
facet, invoked from `tests/run-gate-tests.sh` (existing harness — phase
2 confirms current dispatch pattern and adds five lines, one per
plugin, not a new invocation mechanism). Per-plugin case coverage
(carried over from the prior single-gate design, now split by owner):

- `product-one-pager`: JTBD-tuple pass; solution-named-before-tuple
  deny; malformed-stdin deny (fail-closed, distinguishing "gate broke"
  from "content deficient"); unrelated-path pass-through; kill-switch
  pass; `Edit` reconstruction-failure deny.
- `product-opportunity-solution-tree`: OST-vocabulary pass/deny on
  survey; disposition pass/deny on record; same fail-closed/kill-
  switch/unrelated-path/reconstruction cases as above.
- `product-assumption-mapping`: citation-format pass (zero citations,
  confirms the check does not fire when none exist) / deny (count/date
  missing); RICE-required pass/deny; flagged-ICE-fallback pass;
  unflagged-ICE deny; same fail-closed/kill-switch/reconstruction
  cases.
- `product-hypothesis-testing`: full package pass; no-digit-threshold
  deny; verdict-adjacency pass/deny; ITWWS actioned pass, deferred-
  with-reason pass, deferred-no-reason deny; same fail-closed/kill-
  switch/reconstruction cases.
- `product-guardrail-metrics`: guardrail-present pass, guardrail-
  absent deny, "none"-suffixed deny; status-word pass/deny on record;
  same fail-closed/kill-switch/reconstruction cases.
- Cross-plugin order-constraint case (duplicated in the four
  proposal-checking plugins' own test files, not a sixth test file):
  proposal write with the current-state survey missing on disk denies
  with the order message before that plugin's own element checklist
  runs.

Test harness style unchanged from the prior design: real-subprocess
invocation, synthetic tool-call JSON on stdin, exit-code + stderr
assertions — matching `role-gates-tests.md`'s description of core's own
`run-role-gates-tests.sh`.

## 7. Agents / checklist

Not warranted as new files, per plugin. Each plugin's existing skill
(`assumption-mapping`, `hypothesis-testing`, `guardrail-metrics`, `one-
pager`, `opportunity-solution-tree`) already covers the repeated
procedure its gate checks the *presence* of an artifact from (RICE
scoring, hypothesis registration, guardrail selection) — the gate
cannot and should not compute these; that judgment stays with the
model executing phase 1, guided by the plugin's own bundled skill. A
checklist file duplicating a skill the same plugin already ships would
be two sources of truth inside one plugin.

## 8. Migration plan (phase 2 execution order)

1. Fix `directive.sh`'s `hand_off` record-path string (section 0).
2. Add `RECORD_FIELDS_TERMINAL_STATES="decided scope-proposed"` to the
   role's hooks env (section 0).
3. Create five plugin directories (`product-one-pager/`, `product-
   opportunity-solution-tree/`, `product-assumption-mapping/`,
   `product-hypothesis-testing/`, `product-guardrail-metrics/`), each
   with `.claude-plugin/plugin.json`, `hooks/directive.sh`,
   `hooks/hooks.json`, `hooks/methodology-gate.sh` per section 5, and
   its moved `skills/<name>/` directory (moved, not copied, from the
   current `product/skills/`).
4. Write the five `tests/<plugin>-gate-tests.sh` files per section 6;
   wire all five into `tests/run-gate-tests.sh`.
5. Register all five plugins in `.claude-plugin/marketplace.json`,
   removing the single `product` entry it replaces.
6. Retire the now-empty `product/` directory once the five plugins
   carry everything it shipped (skills moved, hooks split) — confirm
   no remaining reference to `product/` paths in specs/docs before
   deletion.
7. Record the fix, the plugin split, and all five gates' test-pass
   results in `docs/issue-42/reports/product-discovery.md`.

## 9. Rationale per design choice

- **Five independent plugins instead of one gate file**: adopted
  because the approver's feedback names the exact shape core already
  uses (`freelunch`, `scout` as separate marketplace entries) and
  because independent kill switches, independent installability, and
  independent test files are worth more than one file's convenience —
  a broken `product-guardrail-metrics` gate should never block
  `product-one-pager` from firing.
- **Phase-1/phase-2 norms defined as compositions, not restated as
  their own gates**: adopted because writing a sixth "phase-1-norm"
  gate would just re-check what the five plugins already check,
  duplicating logic across two layers for no new coverage — the norm
  is which plugins are installed and fire on which surface, not
  separate code.
- **Order constraint duplicated across four gate scripts rather than a
  sixth plugin**: adopted because the check carries no methodology
  content of its own (a bare filesystem existence test) — promoting it
  to a full plugin would be ceremony without substance; duplicating a
  few lines four times costs less than inventing a cross-plugin
  dependency mechanism this marketplace does not otherwise have.
- **Fixing the record-path defect before the plugin split**: unchanged
  from the prior design — a new plugin set built on a role whose
  existing global gate silently never fires would leave that root
  cause in place regardless of how the new checks are packaged.
- **Not vendoring `record-fields-gate.sh` locally, in any plugin**:
  unchanged — `implementation`'s issue #53 already ran this experiment
  in reverse (deleting local copies once confirmed redundant) and
  canon-scripts.md's reference-not-copy rule applies identically
  whether the copy lives in one plugin or five.
- **No new agent/checklist file, in any plugin**: unchanged — each
  plugin already ships the skill covering its own repeated procedure.
