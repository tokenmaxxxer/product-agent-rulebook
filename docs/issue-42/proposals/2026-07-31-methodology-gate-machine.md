---
kind: proposal
subject: issue-42
role: product-discovery
---

# Proposal — methodology gate machine for product-discovery — issue #42

Full findings backing this proposal:
`docs/issue-42/reports/product-discovery/current-state.md` and
`docs/issue-42/reports/product-discovery/scout-brief.md`.

Phase 1 only. No plugin code, hook file, or test file is created or
changed by this document — it specifies what phase 2 will build, at
implementation-rulebook's level of concreteness, so the approver is
approving a design, not a slogan. This document contains no approval of
any kind. Phase 2 (writing `product/hooks/methodology-gate.sh`, editing
`product/hooks/directive.sh` and `product/hooks/hooks.json`, and adding
`tests/product-methodology-gate-tests.sh`) requires an Approve per
contract v3 s19 from an account listed in `docs/specs/approvers.md`.

## 0. Prerequisite fix (do first, phase 2, before the new gate)

`directive.sh`'s `hand_off` block states the record path as
`docs/issue-<n>/reports/product.md`. `CLAUDE_ROLE=product-discovery` in
this session, and `core_role_directive`'s own closing line already
emits `RECORD: docs/issue-<n>/reports/product-discovery.md` — so core
canon's globally-wired `record-fields-gate.sh` has never actually
matched this role's real record file. Phase 2 corrects `hand_off`'s
prose to `docs/issue-<n>/reports/product-discovery.md` and sets
`RECORD_FIELDS_TERMINAL_STATES="decided scope-proposed"` in
`product/hooks/hooks.json`'s env for that gate (per `role-gates-tests.md`'s
documented injection point), so the check core already runs everywhere
else starts running here too. This is not new machinery — it is turning
on machinery that already exists and was silently pointed at the wrong
file. Doing this before adding the new methodology gate matters because
the new gate is designed to compose with §20's generic checks, not
duplicate them (see scout-brief "Adopt": don't re-implement §20
locally).

## 1. Directive deepening

Issue #42 asks that phase 1 and phase 2 each get concrete, facet-level
requirements — not the one-line PRODUCES summary the old `directive.sh`
had before issue #36, and not free-floating prose either, since a gate
needs to check against something written down precisely enough to
parse. The content below is issue #36's already-approved methodology
(unchanged in substance), restated per-facet so each line maps to
exactly one gate check in section 2. `directive.sh`'s actual text is
already this concrete after issue #36's phase 2 landed (`df05ef5`) —
this section documents the facet-to-check mapping phase 2 will use,
not new prose to write into the file.

### Phase-1 facets (current-state survey + proposal)

| Facet | Judgment criterion | Prohibition |
|---|---|---|
| Problem framing | Stated as a JTBD 4-tuple (performer, job, circumstance, desired outcome) *before* any solution name appears in the document | A solution name appearing before the tuple is stated is not a restatement, it's a violation — the survey must restate the issue's own words if the issue text embeds a solution |
| OST placement | The relevant branch (outcome / opportunity / candidate solutions / discriminating assumption test) named using OST's four-layer vocabulary | Free prose describing "what we're building and why" without naming which OST layer it sits at does not satisfy this |
| Evidence citation | Each cited data point: interview/observation count + approximate date range + one-line paraphrase, one line per citation | A bare claim ("users want X") with no count/date/paraphrase triple is not admissible; stated preference / hypothetical response is never admissible regardless of citation format |
| Prioritization | RICE score (Reach, Impact, Confidence, Effort, resulting score) per candidate, *only required when more than one opportunity or solution candidate is being compared* | ICE permitted only when explicitly flagged as a fallback and reach data is stated as unavailable — an unflagged ICE score when RICE was computable is a violation |
| Hypothesis package | Named metric + numeric threshold + decision rule (go/kill/pivot), guardrail metric(s) named non-empty at the same point, ITWWS follow-up stated | A threshold expressed as "significant improvement" with no number is prose, not a registration — gate-checkable as "digit present near threshold language" |
| Scope boundary | Open questions section and explicitly out-of-scope items, both present | Absence of either is a defect, not an implicit "none" |

### Phase-2 facets (record)

| Facet | Judgment criterion | Prohibition |
|---|---|---|
| Verdict mechanics | Measured metric value stated adjacent to the pre-registered threshold it's compared against | Re-deriving or restating the decision rule with new judgment at verdict time is a violation — the rule was fixed in phase 1 and is applied, not reconsidered |
| Guardrail status | Guardrail metric status stated explicitly at the same measurement moment, even when unbreached | Silence on a guardrail is not "assumed fine" — it's a missing field |
| OST update | Which branch was pruned (kill) or promoted (go/pivot), in the same four-layer vocabulary as phase 1 | A verdict with no OST-branch disposition leaves the standing tree stale |
| ITWWS | Actioned or explicitly deferred with a stated reason | Silently dropping the pre-committed follow-up is a violation |
| Record identity | `kind` + `loop_state` fields present; `loop_state` drawn from this role's vocabulary (`decided`, `scope-proposed` as terminal; non-terminal states per core's generic default otherwise) | Already covered by core's `record-fields-gate.sh` once section 0's fix lands — not re-checked by the new role gate (see section 2's scope note) |

## 2. Methodology gate design

New file, phase 2: `product/hooks/methodology-gate.sh`. Role-owned, not
a canon file — written fresh against `pricing/hooks/methodology-gate.sh`'s
structural template (scout-brief "Adopt"), never copied verbatim, and
does not appear in `core/hooks/tests/canon-manifest.txt` so
`stub-check.sh` has nothing to flag against it.

### Scope (what this gate does NOT check)

Generic record shape (what/why/upstream-basis/`loop_state`/open-
findings) is core's `record-fields-gate.sh` job, already wired globally,
fixed to actually engage per section 0. This gate checks only the
facets in section 1's tables that are specific to this role's adopted
methodology — no overlap, so a future person reading a denial message
knows which gate to look at.

### Targets (path regexes, three write surfaces — one more than either
exemplar alone, per scout-brief's "performance axes")

```
SURVEY_RE  = ^docs/issue-[0-9]+/reports/product-discovery/current-state\.md$
PROPOSAL_RE = ^docs/issue-[0-9]+/proposals/.*product-discovery.*\.md$
RECORD_RE  = ^docs/issue-[0-9]+/reports/product-discovery\.md$
```

### Mechanics (mirrors `pricing/hooks/methodology-gate.sh` exactly)

- PreToolUse, matcher `Write|Edit|MultiEdit`.
- `set -uo pipefail`, `trap`-wrapped `__fc` fail-closed-on-nonzero/
  non-2 exit, same as both exemplars.
- Kill switch: `PRODUCT_DISCOVERY_METHODOLOGY_GATE_OFF=1`.
- `command -v python3` check; deny (fail closed) if absent.
- Read stdin payload, deny on empty/unparseable JSON, deny on
  non-dict `tool_input` — verbatim pattern from both exemplars.
- Root resolution: `CLAUDE_PROJECT_DIR` hint validated by
  `_plausible`/`_under`, else `git rev-parse --show-toplevel` from the
  target's directory, else from cwd — verbatim from both exemplars.
- Path resolution against root; if resolved path matches none of the
  three `_RE` patterns, `exit 0` (not this gate's business) —
  verbatim pattern.
- Reconstruct resulting text for `Write` (use `content`), `Edit` (apply
  `old_string`/`new_string` if `old_string` is found in current
  content), `MultiEdit` (apply all edits sequentially, abort
  reconstruction — not the whole gate — if any `old_string` doesn't
  match, same as both exemplars); deny with an explicit "cannot
  determine resulting content, use Write or a matching Edit" message if
  reconstruction fails, per both exemplars' identical handling.

### Per-surface checklist (the actual methodology content, new to this
gate — not present in either exemplar since it's this role's own
adopted norms)

`SURVEY_RE` match — require:
- JTBD-tuple language: at least three of `{"job performer","the job",
  "circumstance","desired outcome"}` (case-insensitive substring),
  OR an explicit statement that the issue names no solution to
  restate (rare-but-legitimate exit, mirroring `pricing`'s
  "exited_early" pattern) → else `missing: jtbd-tuple`.
- OST vocabulary: at least one of `{"outcome","opportunity",
  "opportunities","candidate solution","assumption test"}` →
  else `missing: ost-placement`.

`PROPOSAL_RE` match — require:
- Hypothesis package: digit-bearing threshold language near
  `{"metric","threshold"}`, plus `{"decision rule","go/kill",
  "go, kill","pivot"}`, plus `{"guardrail"}` non-empty (guardrail
  keyword present and not immediately followed by "none"/"n/a"),
  plus `{"itwws","if this works"}` → missing element(s) named
  individually, same denial style as `pricing`'s gate
  (`"missing required element(s): %s"`).
- Evidence-citation format: if the text contains interview/evidence
  language (`{"interview","observation"}`) at all, require it to
  co-occur with a count-or-date pattern (regex `\d+\s*(interview|
  observation)` or a four-digit year) → else `missing:
  evidence-citation-format`. A proposal citing zero interviews
  (pure desk research / spike) does not trigger this check at all —
  the gate only enforces the *format* of citations that exist, never
  manufactures a citation requirement out of thin air.
- Prioritization: if the text names two or more distinct opportunity/
  solution candidates (heuristic: two or more headings/bullets under
  an "opportunities" or "candidates" section — the same
  best-effort-heuristic approach `pricing`'s gate already accepts for
  its own checks, documented as a known limitation, not silently
  assumed perfect), require `"rice"` OR (`"ice"` AND an explicit
  flag phrase `{"reach data","reach unavailable","fast-triage
  substitute"}`) → else `missing: prioritization-method`.
- Scope boundary: require both `{"open question"}` and
  `{"out of scope","out-of-scope"}` → else `missing: scope-boundary`.
- **Order constraint**: before evaluating any of the above, if
  `docs/issue-<n>/reports/product-discovery/current-state.md` does not
  exist on disk (checked via the resolved root, same `n` extracted
  from the target path), deny immediately with `"proposal write
  precedes its own current-state survey — issue #36's adopted order
  is survey (JTBD-framed) before proposal; write
  docs/issue-<n>/reports/product-discovery/current-state.md first."`
  This is the "필요 시 상태 추적" ask from issue #42: the check is a
  plain filesystem existence test (no new state file, no counter,
  no `loop_state` addition) — the file's own existence *is* the
  state, matching scout-brief's "Skip: a bespoke phase-ordering state
  machine beyond what already exists" finding. No exemplar gate reads
  `loop_state` for ordering; none is needed here either.

`RECORD_RE` match — require:
- Verdict adjacency: digit-bearing metric-value language within
  reasonable proximity of digit-bearing threshold language (best
  effort — flag as `missing: verdict-adjacency` rather than silently
  passing when only one of the two is present).
- Guardrail status: `{"guardrail"}` present and not immediately
  followed by absence of a status word (`{"held","breached","not
  breached","stable","status"}`) → else `missing: guardrail-status`.
- OST disposition: `{"pruned","promoted"}` co-occurring with OST
  vocabulary → else `missing: ost-disposition`.
- ITWWS resolution: `{"itwws","if this works"}` co-occurring with
  either `{"actioned","done"}` or `{"deferred"}` (deferred requires a
  trailing reason — best-effort: non-trivial text after the word) →
  else `missing: itwws-resolution`.

All denials aggregate into one message per write, same format as both
exemplars: `"<role>: refused — <surface> write is missing required
element(s): a, b, c. Per docs/issue-36/proposals/..., every ... must
..."` (role resolved from `CLAUDE_ROLE`, defaulting to
`product-discovery`).

## 3. Gate tests

New file, phase 2: `tests/product-methodology-gate-tests.sh`, invoked
from `tests/run-gate-tests.sh` (existing harness — phase 2 confirms its
current dispatch pattern and adds one line, not a new invocation
mechanism). Cases, each asserting exit code and, on denial, that the
stderr message names the expected missing-element slug(s):

1. Survey write with all JTBD-tuple + OST-vocabulary language → pass
   (exit 0).
2. Survey write with a solution named before the JTBD tuple and no
   OST vocabulary → deny, message names `jtbd-tuple` (or the
   solution-before-tuple case, whichever the phase-2 implementation
   settles as textually detectable) and `ost-placement`.
3. Proposal write with full hypothesis package, one candidate only
   (no prioritization required), valid citations, scope boundary
   present, current-state survey already exists on disk → pass.
4. Same as (3) but the current-state survey file does not exist on
   disk → deny, message is the order-constraint message (not the
   per-element checklist — order check runs first).
5. Proposal write with two candidate opportunities and no RICE/ICE
   language → deny, names `prioritization-method`.
6. Proposal write with two candidates, ICE used without a flagged
   fallback reason → deny, names `prioritization-method`.
7. Proposal write with a threshold stated as "significant
   improvement" (no digit) → deny, names the hypothesis-package
   digit-threshold element.
8. Proposal write with an interview claim with no count/date → deny,
   names `evidence-citation-format`.
9. Proposal write with zero interview/evidence language at all
   (pure desk research) and everything else present → pass (confirms
   the citation-format check does not fire when no citation exists).
10. Record write with metric value stated, no threshold nearby → deny,
    names `verdict-adjacency`.
11. Record write with guardrail mentioned but no status word → deny,
    names `guardrail-status`.
12. Record write with no OST pruned/promoted language → deny, names
    `ost-disposition`.
13. Record write with ITWWS deferred but no reason text → deny, names
    `itwws-resolution`.
14. `Edit` whose `old_string` does not match current file content →
    deny with the "cannot determine resulting content" message, not a
    methodology-element message (reconstruction failure is a distinct
    failure mode, tested distinctly, per both exemplars' identical
    handling).
15. `PRODUCT_DISCOVERY_METHODOLOGY_GATE_OFF=1` set → any otherwise-
    denying write passes (kill switch works).
16. A write to an unrelated path (e.g. `product/opportunity-tree.md`,
    a standing doc, or any file outside the three `_RE` patterns) →
    passes untouched (gate correctly scopes itself, does not leak
    onto this role's other, ungated write surfaces).
17. Malformed/empty stdin payload → deny with the internal fail-closed
    message, not a methodology message (distinguishes "gate broke"
    from "content is deficient" in the test suite, same distinction
    both exemplars' own code already makes).

Test harness style: real-subprocess invocation (feed a synthetic
tool-call JSON payload on stdin, assert exit code + stderr content),
matching `role-gates-tests.md`'s description of how core's own
`run-role-gates-tests.sh` exercises its three canon gates — this
role's test file is a role-scoped instance of the same harness shape,
not a new testing paradigm.

## 4. Agents / checklist

Not warranted as a new file. The two repeated procedures issue #42's
ask 4 gestures at — assumption-mapping's 2x2 evidence-strength/
importance scoring, and the RICE-score-per-candidate loop — are already
owned by this role's existing `assumption-mapping` and (implicitly,
via the gate's `prioritization-method` check) `hypothesis-testing`/
`guardrail-metrics` skills. The methodology gate in section 2 checks
that a RICE score *exists* in the written artifact; it cannot and
should not compute one — that judgment stays with the model executing
phase 1, guided by the existing skills. Adding a redundant checklist
file on top of a skill that already covers the same procedure would
be two sources of truth for one requirement, which section 2 above
explicitly avoids doing for §20 vs. the new gate. If phase 2's
implementation surfaces a genuinely new repeated procedure not covered
by an existing skill (e.g., the order-constraint's file-existence
check needing a human-readable walkthrough), a checklist can be added
then — not speculatively here.

## 5. Plugin-reflection plan (phase 2 execution order)

1. Fix `directive.sh`'s `hand_off` record-path string (section 0).
2. Add `RECORD_FIELDS_TERMINAL_STATES="decided scope-proposed"` to
   `product/hooks/hooks.json`'s env for the (already globally-wired)
   `record-fields-gate.sh` invocation — role-local env override, not a
   new hook registration, per `role-gates-tests.md`'s documented
   pattern.
3. Write `product/hooks/methodology-gate.sh` per section 2.
4. Register it in `product/hooks/hooks.json`'s `PreToolUse` block,
   matcher `Write|Edit|MultiEdit`.
5. Write `tests/product-methodology-gate-tests.sh` per section 3; wire
   into `tests/run-gate-tests.sh`.
6. Record the fix (section 0) and the new gate's test-pass result in
   `docs/issue-42/reports/product-discovery.md` (using the
   now-corrected path).

## 6. Rationale per design choice

- **Fixing the record-path defect before adding new machinery**:
  adopted because building a new gate on top of a role whose *existing*
  global gate silently never fires would leave both a symptom
  (methodology unchecked) and its root cause (record path mismatch)
  in place; the root cause is one string edit and directly enables
  correctly-scoped `RECORD_FIELDS_TERMINAL_STATES` too.
- **Not vendoring `record-fields-gate.sh` locally**: adopted because
  `implementation`'s own issue #53 transition already ran this exact
  experiment in the other direction (deleting local copies once
  confirmed redundant with the global wiring) and canon-scripts.md's
  reference-not-copy rule would flag a fresh vendored copy the same
  way `stub-check.sh` flags existing ones elsewhere in this
  marketplace.
- **A three-surface gate (survey + proposal + record) instead of the
  two-surface pattern both exemplars use**: adopted because issue #36
  put a real requirement (JTBD tuple) on the *survey*, not just the
  proposal — a two-surface gate copied mechanically from either
  exemplar would leave that requirement unchecked.
- **File-existence check for the order constraint, not a new state
  file or `loop_state` value**: adopted because no exemplar reviewed
  builds bespoke ordering state, and the file the order depends on
  (`current-state.md`) already has to exist for a different reason
  (it's a required phase-1 deliverable) — reusing its existence as the
  state signal avoids inventing a second source of truth for the same
  fact.
- **No new agent/checklist file**: adopted because this role already
  owns skills covering both candidate repeated procedures; a
  checklist duplicating a skill's content would violate the same
  "don't check what's already checked elsewhere" principle this
  proposal applies to the record-fields overlap.
