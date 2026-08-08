# Current-state survey — issue #57

Scout skip: pure vocabulary/schema-alignment task against an already-fixed
external spec (`roles/specs/product-discovery.spec.json`); no product-facing
design decision is open to scout against a market. Skip condition: "the
spec leaves no design decision open" (the spec is the input, not a thing
to compare against competitors).

## Spec (source of truth)

`roles/specs/product-discovery.spec.json` (read from the installed
marketplace copy — this repo does not vendor it):
- 17 required/optional fields (16 required, `confidence_level` optional).
- `reference_resolution`: evidence_log entries must resolve to a repo
  path, commit sha, or a source actually consulted.
- `recomputation`: `recommendation` must not be asserted before
  `fail_condition`, `time_box`, `decision_rule` exist (pre-registration
  order); enforcement is TBD/follow-up, not required here.
- `write_scope: []`, `report_only: true` — the spec governs the *record*
  only, not a conversational state machine.
- `loop_state`: progress `[measuring]`, terminal `[validated, invalidated,
  inconclusive]`, refusal `[hypothesis-not-falsifiable]`, error
  `[evidence-log-unreadable]`.

## This rulebook's current shape

5 independent plugins (`product-one-pager`, `product-opportunity-solution-tree`,
`product-assumption-mapping`, `product-hypothesis-testing`,
`product-guardrail-metrics`), each with its own `hooks/methodology-gate.sh`
and `hooks/directive.sh`, documented in README.md and `docs/README.md`.
Interaction protocol (branch, phases, record path/frontmatter) is owned by
core, not this repo (per README's opening paragraph).

Declared record vocabulary (README.md:102, `product-hypothesis-testing/hooks/directive.sh`):
`loop_state`: `idle, scoping, researching, hypothesis-registered, measuring,
decided`, terminal `decided`, plus `scope-proposed` — explicitly **not**
part of this role's own vocabulary; it is "the human-only accept state the
external pre-approval gate raises a `scope-proposed` record to — never
written by this role."

Actual committed records (`docs/issue-{36,42,45,48,51}/reports/product-discovery.md`,
`docs/issue-29/.../coding.md`) only ever carry `loop_state: decided` or
`loop_state: scope-proposed` — `idle/scoping/researching/hypothesis-registered/
measuring` never appear as a *committed* frontmatter value in any record on
this branch's history; they read as pre-record conversational-phase labels
that the skills (`one-pager`, `opportunity-solution-tree`) narrate before a
hypothesis is registered, not as values written into the record's
`loop_state:` line itself. The gates (`product-*/hooks/methodology-gate.sh`)
never grep for `loop_state` values at all — they check facet content
(JTBD tuple, OST vocabulary, evidence citations, hypothesis package,
guardrail non-emptiness) by section/adjacency, never the loop_state token.

`product-*/skills/*/SKILL.md` (one-pager, opportunity-solution-tree,
hypothesis-testing) reference a **stale** architecture (`product/state.md`,
`product-cycle/`, `state-gate.sh`, `transition-rules.md`) that no longer
exists in this repo (confirmed absent by `find`); `docs/handbooks/tests.md`
already notes a prior instance of this same drift
(`record-fields-gate.sh`/`trailer-gate.sh` never existed here). These
SKILL.md files are themselves candidates for correction, independent of
issue #57, but issue #57's scope is the field/vocabulary mapping — noting
the drift here so the proposal doesn't compound it silently, per "empty
state" acceptance discipline.

## Field-by-field mapping (spec -> existing rulebook concept)

| spec field | existing concept | plugin/doc | fit |
|---|---|---|---|
| `problem_statement` | "Problem Statement" | product-one-pager (SKILL.md field list) | direct |
| `target_market` | none | — | **gap** |
| `market_size_rationale` | none | — | **gap** |
| `competitive_alternatives` | none (assumption-mapping compares *candidate solutions*, not market alternatives) | — | **gap** |
| `differentiator` | none (OST "candidate solution" vs "opportunity" is adjacent but answers a different question) | — | **gap** |
| `timing_rationale` | none | — | **gap** |
| `go_to_market_plan` | none | — | **gap** |
| `success_metric` | `metric` field | product-hypothesis-testing | direct |
| `critical_success_factors` | guardrail metrics (partial: guardrails are "must not regress," not "must hold true") | product-guardrail-metrics | partial |
| `recommendation` (go/no-go) | "Disposition" / "Verdict: go, not kill, not pivot" (observed in `docs/issue-51/reports/product-discovery.md`) — vocabulary differs (go/kill/pivot vs spec's go/no-go) | product-hypothesis-testing (record convention) | partial |
| `hypothesis_statement` | "Candidate Hypotheses" (one-pager) + the registered metric/threshold/decision_rule package (hypothesis-testing) — no single field states the hypothesis as one falsifiable sentence | product-one-pager, product-hypothesis-testing | partial |
| `fail_condition` | folded into `decision_rule` prose (e.g. "if below 15%, kill") — never a separate field | product-hypothesis-testing | partial |
| `time_box` | folded into `threshold` prose (e.g. "within a 2-week measurement window") — never a separate field | product-hypothesis-testing | partial |
| `decision_rule` | `decision_rule` field | product-hypothesis-testing | direct |
| `confidence_level` (optional) | none | — | **gap** (optional, so no forcing function needed) |
| `evidence_log` | evidence citations (interview/observation count, date, paraphrase) + this repo's own convention of resolving claims to a path/sha (used throughout `docs/issue-*/reports/`) | product-assumption-mapping | direct, and `reference_resolution`'s no-orphan-references rule is already this repo's own working norm, just unwritten as a rule |
| `verdict` (validated/invalidated/inconclusive) | `decided` loop_state + "Verdict: go/kill/pivot" prose — vocabulary mismatch (go/kill/pivot vs validated/invalidated/inconclusive) | product-hypothesis-testing | partial, vocabulary must change |
| loop_state set | `idle, scoping, researching, hypothesis-registered, measuring, decided` (+ non-role `scope-proposed`) vs spec's `measuring / validated,invalidated,inconclusive / hypothesis-not-falsifiable / evidence-log-unreadable` | README.md, directive.sh | **must be redefined** — see proposal |

## Write-set implications

Files that plausibly need to change to close the gaps above:
- `README.md` (record vocabulary section, plugin descriptions)
- `product-one-pager/skills/one-pager/SKILL.md` (+ template) — target_market, market_size_rationale, competitive_alternatives, differentiator, timing_rationale, go_to_market_plan additions; also stale architecture references
- `product-hypothesis-testing/skills/hypothesis-testing/SKILL.md`, `hooks/directive.sh` — hypothesis_statement, fail_condition, time_box as explicit fields; verdict/loop_state vocabulary swap; also stale architecture references
- `product-guardrail-metrics/skills/guardrail-metrics/SKILL.md` — critical_success_factors framing
- `product-assumption-mapping/skills/assumption-mapping/SKILL.md` — evidence_log / reference_resolution framing
- `docs/README.md` if bucket doctrine needs a note
- No `product-opportunity-solution-tree` field maps 1:1 to any spec field (OST is a supporting structure, not a spec-required output) — no change expected there beyond terminology consistency, if any.

This survey does not itself decide which of these become the frozen
write set — that decision, and the alternative considered/rejected for
the loop_state redesign, is in the proposal.
