---
status: proposed
files:
  - README.md
  - docs/README.md
  - product-one-pager/skills/one-pager/SKILL.md
  - product-one-pager/skills/one-pager/templates/one-pager-template.md
  - product-hypothesis-testing/skills/hypothesis-testing/SKILL.md
  - product-hypothesis-testing/hooks/directive.sh
  - product-guardrail-metrics/skills/guardrail-metrics/SKILL.md
  - product-assumption-mapping/skills/assumption-mapping/SKILL.md
  - product-opportunity-solution-tree/skills/opportunity-solution-tree/SKILL.md
---

# Proposal — align rulebook with `product-discovery.spec.json` (issue #57)

## Request

Layer the realized marketplace spec's (`roles/specs/product-discovery.spec.json`)
17-field vocabulary (16 required, `confidence_level` optional) and its
`loop_state` set onto this rulebook's
docs/hooks, strengthening existing methodology rather than deleting it.
Phase 1 (this document): map every spec field onto an existing rulebook
concept, or say plainly it has no home yet. Phase 2 (separate, after
approval): apply the mapping.

## Constraints

- Never delete existing methodology (JTBD one-pager, OST tree, RICE/ICE
  evidence mapping, guardrail metrics) — only strengthen/extend.
- Every spec required-field name must appear somewhere in `docs/` or
  `README.md` after phase 2 (issue's own acceptance check).
- The rulebook's `loop_state` vocabulary must match the spec's set
  exactly — no stale or extra states.
- A spec field with no natural home must be stated explicitly, with
  reasoning, not silently dropped (issue's "empty state" acceptance
  clause).
- `write_scope: []` / `report_only: true` in the spec — the spec governs
  the record only, not a conversational state machine; this constrains
  how far the loop_state change can reach (see Rationale).

## Rationale

**Alternative considered: keep `idle, scoping, researching,
hypothesis-registered, measuring, decided` as the loop_state vocabulary
and add the spec's states as aliases/extensions.** Rejected: the issue's
acceptance check is explicit — "rulebook loop_state vocabulary matches
the spec set above exactly (no stale or extra states)." Keeping both sets
side by side would leave `idle/scoping/researching/hypothesis-registered/
decided` as extra, undeclared states relative to the spec, failing the
check outright; the survey also found these five names never actually
appear as *committed* `loop_state:` values in this repo's own history
(`docs/issue-{36,42,45,48,51}/reports/product-discovery.md` all read
`decided`; none read `idle`/`scoping`/etc.) — they function as
conversational-phase prose in the skills, not as record tokens, so
replacing the record token set does not require deleting the
conversational-phase methodology that talks about scoping/researching in
prose.

**Alternative considered: fold `target_market`, `market_size_rationale`,
`competitive_alternatives`, `differentiator`, `timing_rationale`,
`go_to_market_plan` into `product-assumption-mapping` (the RICE/ICE
plugin) instead of `product-one-pager`.** Rejected: these six fields all
describe the opportunity *before* any hypothesis is scored or tested —
the same "problem, not solution, not yet tested" moment `product-one-pager`
already owns per its own description ("JTBD problem-without-solution
framing... before evidence gathering starts"). Putting market-framing
fields in the RICE/ICE plugin would mix "what is the opportunity" with
"how do we score candidate solutions against it," which is exactly the
separation `product-one-pager` vs `product-assumption-mapping` already
enforces.

**Chosen approach:** extend each existing plugin's field list with the
spec fields that answer the same underlying question that plugin already
owns, redefine `loop_state` to the spec's exact set (dropping
`idle/scoping/researching/hypothesis-registered/decided` as *record*
values while keeping their prose as phase narration inside the relevant
skills), and swap the `go/kill/pivot` verdict vocabulary observed in
committed records for the spec's `validated/invalidated/inconclusive`.

## What will be done

1. **`product-one-pager`** (JTBD framing plugin) gains six new required
   fields alongside its existing five: `target_market`,
   `market_size_rationale`, `competitive_alternatives`, `differentiator`,
   `timing_rationale`, `go_to_market_plan`. Update
   `skills/one-pager/SKILL.md`'s field list and
   `templates/one-pager-template.md`; also correct the stale
   `product/state.md` / `state-gate.sh` / `transition-rules.md`
   references found in the survey while the file is open, so the fix
   doesn't compound known drift — this is in-scope because it is the
   same file already in the write set for the field addition, not a new
   surface.

2. **`product-hypothesis-testing`** gains `hypothesis_statement` (one
   falsifiable sentence, distinct from the existing "Candidate
   Hypotheses" list and from the registered `metric`/`threshold`/
   `decision_rule` package), and splits `fail_condition` and `time_box`
   out of the existing `decision_rule`/`threshold` prose into their own
   named fields (`decision_rule` keeps the mechanical rule;
   `fail_condition` states the kill trigger alone; `time_box` states the
   measurement window alone). `confidence_level` is documented as an
   optional field the skill may ask for but never gates on, matching the
   spec's `required: false`. Update `skills/hypothesis-testing/SKILL.md`
   (field list, worked example, stale-architecture references) and
   `hooks/directive.sh`'s declared `loop_state` vocabulary:
   replace `decided` (terminal) with `validated, invalidated,
   inconclusive` (terminal, matching spec's three-way verdict split),
   keep `measuring` (progress), add `hypothesis-not-falsifiable`
   (refusal — the hypothesis-statement/decision-rule package was never
   actually testable) and `evidence-log-unreadable` (error — the
   evidence_log's referenced sources don't resolve). `scope-proposed`
   stays untouched (it is explicitly not this role's own vocabulary per
   the current README, and issue #57's board_condition text does not
   mention it).

3. **`product-guardrail-metrics`** gains `critical_success_factors`
   framing: document explicitly that guardrail metrics are this
   rulebook's existing mechanism for critical success factors — a
   guardrail already named non-empty at hypothesis-registration time,
   its status checked at measurement time, is a critical success factor
   ("this must hold, or the result doesn't count") stated in the
   vocabulary this plugin already uses. Update
   `skills/guardrail-metrics/SKILL.md` to use the term explicitly so a
   `grep -ri critical_success_factors docs/` (the acceptance check's own
   verification command) finds it.

4. **`product-assumption-mapping`** gains `evidence_log` framing:
   document that its existing evidence-citation practice (interview/
   observation count, date, paraphrase, resolved to a path/sha/source)
   *is* the spec's `evidence_log`, and write the spec's
   `reference_resolution` rule (no orphan references) into the skill
   explicitly, since the survey found this repo already follows it as an
   unwritten convention.

5. **`success_metric`, `decision_rule`, `recommendation`, `verdict`**:
   `success_metric` is documented as this rulebook's existing `metric`
   field (rename in prose, not a schema break, since `metric` already
   means exactly this). `decision_rule` needs no change (already direct).
   `recommendation` and `verdict` get their vocabulary corrected in
   `hooks/directive.sh` and `skills/hypothesis-testing/SKILL.md`: records
   currently write "Verdict: go, not kill, not pivot" — replace with the
   spec's enums (`recommendation: go|no-go`, `verdict:
   validated|invalidated|inconclusive`), documented as two distinct
   fields (recommendation is the pre-registered call once measured;
   verdict is the loop_state-aligned outcome label) rather than
   collapsing them into one "Disposition" line as today.

6. **README.md / docs/README.md**: rewrite the "Record vocabulary"
   section to the spec's loop_state set exactly, and note in each
   plugin's one-line description which spec field(s) it now owns, so the
   top-level doc is a legible index of the mapping in table 1 above
   without needing to open every skill file.

7. **`product-opportunity-solution-tree`**: no spec field maps to it
   1:1 — left untouched except for any stale-reference cleanup found
   while its neighbors are being edited (out of scope unless discovered;
   see Out of scope).

## Out of scope

- Enforcement mechanics: the spec's `recomputation` rule
  ("recommendation must not precede fail_condition/time_box/decision_rule")
  is marked `checked_by: TBD` in the spec itself — no gate is added for
  it here; phase 2 documents the ordering as prose guidance only.
- `reference_resolution`'s `checked_by: on-the-record/hooks/role-spec-reference-guard.sh`
  is an external repo's hook, not this rulebook's — no gate script is
  added or modified here; only the *documentation* of the no-orphan-
  reference rule is in scope.
- Any change to `product-opportunity-solution-tree`'s own OST vocabulary
  or gate logic.
- Fixing every instance of the stale `product/state.md`/`state-gate.sh`
  architecture reference repo-wide — only the SKILL.md files already in
  this proposal's write set for field additions get that cleanup; a
  repo-wide sweep is a separate issue if wanted.
- Any `methodology-gate.sh` script change (mechanical field-presence
  checking) — this proposal is documentation/vocabulary alignment only;
  wiring gates to check the new fields is a follow-up, not promised by
  issue #57's acceptance checks (which check `docs/`/`README.md` content
  and the loop_state set, not gate behavior).

## How you'll know it worked

- `grep -ri <field> docs/ README.md` returns at least one hit for every
  one of the 17 spec field names listed in the issue body.
- `grep -rn "loop_state" README.md product-hypothesis-testing/hooks/directive.sh`
  shows exactly `measuring, validated, invalidated, inconclusive,
  hypothesis-not-falsifiable, evidence-log-unreadable` as this role's own
  vocabulary — no `idle/scoping/researching/hypothesis-registered/decided`
  remaining as declared *loop_state* values (prose narration of scoping/
  researching as conversational phases inside skill files is fine and
  expected; only the declared vocabulary/record-token set changes).
  `scope-proposed` remains documented as the non-role external-gate
  state, unchanged.
- `bash tests/run-gate-tests.sh` and each `tests/parse-check.sh
  product-*/hooks` still pass unchanged (no gate script is touched by
  this proposal, so no regression is expected; run as a sanity check).
- Each of the six spec fields with no prior home (`target_market`,
  `market_size_rationale`, `competitive_alternatives`, `differentiator`,
  `timing_rationale`, `go_to_market_plan`) is traceable to exactly one
  plugin's skill file, not scattered or duplicated.
