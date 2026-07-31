---
kind: scout-brief
subject: issue-42
role: product-discovery
---

# Scout brief — issue #42

Mode: internal-exemplar reads (no web search) — issue #42 itself names
the two exemplars to consult (implementation-rulebook's gate machine,
pricing-rulebook's `methodology-gate.sh`), and the canon boundary
(`docs/handbooks/canon-scripts.md`) that governs how a role may reuse
either. One round, three angles read directly (not fanned out as
subagents — each is a single targeted file-read, below the sweep's
"needs sustained digging" bar per the freelunch scale gate), stopped
after judge point 1 found no disagreement across the three sources on
the shape a role-owned gate should take.

## Must-bes (near-universal across the exemplars read)

- **A role-owned methodology gate is a PreToolUse Write/Edit/MultiEdit
  hook, path-regex-scoped to that role's own phase-1/phase-2 write
  surfaces, that reconstructs resulting content and substring-checks a
  fixed element list** — `pricing/hooks/methodology-gate.sh`'s exact
  shape. Every element it checks maps 1:1 to a phrase already in that
  role's `directive.sh` `produces` block — the gate enforces what the
  directive already promises, nothing invented fresh at gate time.
- **Fail-closed on internal error, with a role-scoped kill switch.**
  Both `pricing/hooks/methodology-gate.sh` and core's `record-fields-
  gate.sh` wrap the whole check in a `trap`-based `__fc` and expose
  `<ROLE>_METHODOLOGY_GATE_OFF`/`RECORD_FIELDS_GATE_OFF`-style escape
  hatches. Not optional stylistic choice — it's the only pattern seen.
- **Canon files are referenced by path against the core install root,
  never copied.** `docs/handbooks/canon-scripts.md` + `stub-check.sh`'s
  manifest-driven detector enforce this mechanically for files under
  `core/hooks/`. A *role-owned* gate (like `pricing`'s or the one this
  proposal designs) is not itself a canon file and is written fresh —
  the canon boundary applies to what this proposal must NOT vendor
  (`record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-
  gate.sh`, `stub-check.sh`, `parse-check.sh`), not to the new gate
  itself.
- **Generic per-role state already fires globally; a role only adds
  what's role-unique.** `implementation`'s issue #53 transition deleted
  three locally-vendored canon gates once confirmed redundant with
  core's global `matcher: ".*"` wiring, and kept only genuinely
  role-unique state (`coding-progress-gate.sh`, `hunt-guard.sh`,
  `hunt-state.sh`). The lesson generalizes directly: this proposal
  should not re-implement §20 record-field checking — it should fix
  the path defect so core's existing check engages, and add only the
  methodology-specific layer core cannot know about (JTBD tuple, OST
  branch, RICE/ICE, evidence format).
- **Order/sequencing constraints are enforced via injected state, not
  re-derived logic.** `record-fields-gate.sh`'s `RECORD_FIELDS_
  TERMINAL_STATES` env var (role sets it in its own `hooks.json`) is
  the one state-tracking mechanism observed in canon; no exemplar
  implements a bespoke phase-ordering state machine beyond that.

## Performance axes (where the exemplars differ)

- **Scope of what's checked**: `pricing`'s gate checks method-naming
  and scope-gate-exit language (domain-specific verdict shape);
  `record-fields-gate.sh` checks generic doc-structure fields
  (what/why/upstream-basis/loop_state/open-findings). This role's gate
  sits closer to `pricing`'s end (methodology-specific), since the
  generic end is core's job already.
- **Single file vs. two write surfaces**: `pricing`'s gate covers both
  the phase-1 proposal regex and the phase-2 record path in one script
  with two `_RE` patterns. `record-fields-gate.sh` covers only the
  record. This role has three real write surfaces to consider
  (current-state survey, proposal, phase-2 record) — one more than
  either exemplar handles alone, since issue #36 put requirements on
  the *survey* too (JTBD tuple), not just the proposal.

## Adopt

- `pricing/hooks/methodology-gate.sh`'s exact structural template
  (root-resolution, content-reconstruction, substring-checklist,
  named-missing-elements denial, fail-closed trap, kill switch) as the
  shape for a new `product/hooks/methodology-gate.sh` — written fresh,
  not copied, per the canon-scripts.md boundary (this file is not a
  canon file to begin with, so "reference not copy" is about not
  vendoring `core/hooks/*`, satisfied automatically by writing new
  role-owned logic).
- `record-fields-gate.sh`'s `RECORD_FIELDS_TERMINAL_STATES` injection
  point, set to `decided scope-proposed` in this role's own
  `hooks.json`, to close the terminal-states gap found in the survey.
- `implementation`'s issue #53 precedent of deleting/never-adding
  locally-vendored copies of generic canon gates — confirms this
  proposal should NOT write a local record-fields-style gate; only fix
  the path string so the existing global one engages.

## Skip

- Re-implementing §20-style generic record structure checking locally
  — core already does this globally once the path defect is fixed.
- A bespoke phase-ordering state machine beyond `RECORD_FIELDS_
  TERMINAL_STATES`-style env config — no exemplar builds one; this
  role's ordering constraint (survey -> proposal -> verdict) is already
  enforced at the coarse grain by the existing phase-1/phase-2 human-
  Approve gate. The methodology gate only needs a *file-existence*
  check (does `docs/issue-<n>/reports/product-discovery/current-state.md`
  exist before a proposal write is allowed) — a much lighter mechanism
  than a new state machine.

## Gap vs. current state

Confirms `current-state.md`: no local `product/hooks/*-gate.sh` exists,
the record path is stale (`product.md` vs. the role's actual
`product-discovery` name), `RECORD_FIELDS_TERMINAL_STATES` is unset,
and no gate checks any of issue #36's required elements. The two
exemplars converge on one template (`pricing`'s gate) and one
state-injection mechanism (core's terminal-states env var) — the
proposal's design section below applies both directly rather than
inventing new machinery.

## Sources

- `pricing-rulebook-issue-10-pricing/pricing/hooks/methodology-gate.sh`
  (sibling checkout, read this session)
- `implementation-rulebook-issue-61-implementation/docs/issue-53/
  proposals/2026-07-31-core-canon-reference-transition.md` (sibling
  checkout, read this session)
- `tokenmaxxxer-core/core/hooks/record-fields-gate.sh` (read this
  session)
- `tokenmaxxxer-core/docs/handbooks/canon-scripts.md` (read this
  session)
- `tokenmaxxxer-core/docs/handbooks/role-gates-tests.md` (read this
  session)
- `tokenmaxxxer-core/core/hooks/lib/role-directive.sh` (read this
  session; source of the `RECORD:` path-defect finding)
