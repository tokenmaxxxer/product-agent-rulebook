# tokenmaxxxer / product-discovery-rulebook

The `product-discovery` role on contract v3. A product-discovery session is
spawned with two plugin sets installed: this marketplace's 5
`product-*` plugins, and the
[tokenmaxxxer-core](https://github.com/tokenmaxxxer/tokenmaxxxer-core)
plugins (`core`, `terse`, `freelunch`, `scout`). Core owns the interaction
protocol — issue in, two-phase PR out (research/survey/proposal → human
review Approve → execution), branch `issue-<n>/product-discovery`, record at
`docs/issue-<n>/reports/product-discovery.md`. This rulebook owns only what
is product-discovery-specific.

## What `product-discovery` decides

Which problem/opportunity is worth solving and how it should be framed,
scored, and tested before build work starts: the problem stated as a JTBD
tuple before any solution name, its place on the opportunity-solution tree,
its supporting evidence and RICE/ICE prioritization, its pre-registered
hypothesis (metric + threshold + decision rule), and its guardrail metrics.

## What is here

Five independent plugins, each owning one methodology facet and its own
`hooks/methodology-gate.sh`:

    product-one-pager/                 JTBD problem-without-solution framing
                                        on the current-state survey — the
                                        problem stated as a job-performer/
                                        job/circumstance/desired-outcome
                                        4-tuple, fixed before any solution
                                        name appears. Also owns
                                        target_market,
                                        market_size_rationale,
                                        competitive_alternatives,
                                        differentiator, timing_rationale,
                                        go_to_market_plan. Ships skills:
                                        one-pager.
    product-opportunity-solution-tree/ Places the current-state survey (and
                                        later the record) on the relevant
                                        OST branch (outcome / opportunity /
                                        candidate solutions / discriminating
                                        assumption test) in OST's own
                                        four-layer vocabulary; also enforces
                                        that the proposal is never written
                                        before the current-state survey
                                        exists. Ships skills:
                                        opportunity-solution-tree.
    product-assumption-mapping/        One-line evidence citations
                                        (interview/observation count,
                                        date, paraphrase) and RICE scoring
                                        across compared candidates on the
                                        proposal, falling back to a flagged
                                        ICE score only when reach data is
                                        genuinely unavailable. Owns
                                        evidence_log. Ships skills:
                                        assumption-mapping.
    product-hypothesis-testing/        Pre-registers a falsifiable
                                        hypothesis_statement, a named
                                        metric, a numeric threshold, a
                                        decision_rule, a fail_condition,
                                        and a time_box on the proposal
                                        before data collection; optionally
                                        a confidence_level; pre-commits an
                                        ITWWS follow-up; applies the
                                        registered rule mechanically at
                                        record time to reach a
                                        recommendation (go/no-go) and a
                                        verdict (validated/invalidated/
                                        inconclusive), also owning
                                        success_metric. Ships skills:
                                        hypothesis-testing.
    product-guardrail-metrics/         Guardrail metrics named non-empty at
                                        the same moment a hypothesis is
                                        registered (proposal), and their
                                        status stated explicitly at
                                        measurement time (record) — silence
                                        is never "assumed fine". Owns
                                        critical_success_factors. Ships
                                        skills: guardrail-metrics.
    tests/                             repo-level checks (never installed)

Each `methodology-gate.sh` is a PreToolUse gate (Write/Edit/MultiEdit/
NotebookEdit/Bash) that sources
[`tokenmaxxxer-core`](https://github.com/tokenmaxxxer/tokenmaxxxer-core)'s
`core/hooks/lib/gate-lib.sh` / `gate-lib.py` by reference (never vendored)
for the fail-closed trap, kill switch, JSON parsing, path normalization, and
Write/Edit/MultiEdit/NotebookEdit reconstruction — see
[`gate-house-standard.md`](https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/docs/handbooks/gate-house-standard.md).
`CLAUDE_PLUGIN_ROOT_CORE` resolves to the installed core plugin root at
runtime (marketplace-set); when unset, each gate and test suite falls back
to `$(dirname .../hooks)/../../core`. Each gate's own facet check (JTBD
tuple, OST vocabulary, evidence citations, hypothesis fields, guardrail
non-emptiness) is checked with section/adjacency/structure discipline —
an explicit `label: value` line first, else a marker word required to
co-occur with its value inside a paragraph under a heading that itself
names the facet — never a bare keyword match anywhere in the document.

## Kill switches

Independently toggleable per plugin; any value other than a recognized
on-spelling (`1`/`true`/`yes`/`on`, case-insensitive) leaves the gate
active:

| Plugin                             | Env var                                  |
| ----------------------------------- | ----------------------------------------- |
| product-one-pager                   | `PRODUCT_ONE_PAGER_GATE_OFF`              |
| product-opportunity-solution-tree   | `PRODUCT_OPPORTUNITY_SOLUTION_TREE_GATE_OFF` |
| product-assumption-mapping          | `PRODUCT_ASSUMPTION_MAPPING_GATE_OFF`     |
| product-hypothesis-testing          | `PRODUCT_HYPOTHESIS_TESTING_GATE_OFF`     |
| product-guardrail-metrics           | `PRODUCT_GUARDRAIL_METRICS_GATE_OFF`      |

## Record vocabulary

`loop_state` matches `product-discovery.spec.json` exactly:
`measuring` (progress); `hypothesis-not-falsifiable`,
`evidence-log-unreadable` (refusal/error); `validated`, `invalidated`,
`inconclusive` (terminal) — plus `scope-proposed` when this is the
subject's front record (also terminal for that record). `scope-approved`
is the human-only accept state the external pre-approval gate raises a
`scope-proposed` record to — never written by this role, never part of
this vocabulary. The prior `idle, scoping, researching,
hypothesis-registered, decided` names remain in prose inside the skill
files as conversational-phase narration (they describe the state-machine
phase, per `docs/specs/state-machine.md`) but are no longer written as
`loop_state` record values — no committed record in this repository's
history has ever used them as record tokens.

## Spec field ownership

`product-discovery.spec.json`'s required deliverable fields, each mapped
to the plugin/skill that owns it:

| Spec field | Owning plugin |
| --- | --- |
| `problem_statement` | `product-one-pager` (Problem Statement) |
| `target_market` | `product-one-pager` |
| `market_size_rationale` | `product-one-pager` |
| `competitive_alternatives` | `product-one-pager` |
| `differentiator` | `product-one-pager` |
| `timing_rationale` | `product-one-pager` |
| `go_to_market_plan` | `product-one-pager` |
| `success_metric` | `product-hypothesis-testing` (`metric`, renamed in prose) |
| `critical_success_factors` | `product-guardrail-metrics` (guardrail list) |
| `recommendation` | `product-hypothesis-testing` (go/no-go call) |
| `hypothesis_statement` | `product-hypothesis-testing` |
| `fail_condition` | `product-hypothesis-testing` |
| `time_box` | `product-hypothesis-testing` |
| `decision_rule` | `product-hypothesis-testing` |
| `confidence_level` (optional) | `product-hypothesis-testing` |
| `evidence_log` | `product-assumption-mapping` |
| `verdict` | `product-hypothesis-testing` (`validated`/`invalidated`/`inconclusive`) |

`product-opportunity-solution-tree` owns no spec field 1:1 — its OST
artifact is cross-cutting context, not a per-hypothesis record field.

## Install

    claude plugin marketplace add tokenmaxxxer/product-discovery-rulebook
    claude plugin install product-one-pager@tokenmaxxxer-product
    claude plugin install product-opportunity-solution-tree@tokenmaxxxer-product
    claude plugin install product-assumption-mapping@tokenmaxxxer-product
    claude plugin install product-hypothesis-testing@tokenmaxxxer-product
    claude plugin install product-guardrail-metrics@tokenmaxxxer-product

## Run the checks

    /bin/bash tests/parse-check.sh product-one-pager/hooks
    /bin/bash tests/parse-check.sh product-opportunity-solution-tree/hooks
    /bin/bash tests/parse-check.sh product-assumption-mapping/hooks
    /bin/bash tests/parse-check.sh product-hypothesis-testing/hooks
    /bin/bash tests/parse-check.sh product-guardrail-metrics/hooks
    /bin/bash tests/run-gate-tests.sh
    /bin/bash tests/deny-only-check.sh product-one-pager/hooks
    # ...and so on per plugin; deny-only-check.sh's substance probe always
    # searches this repo's full tree for a *-gate.sh regardless of the
    # hooks-dir argument above, since the record obligation
    # (docs/issue-<n>/reports/product-discovery.md) is federated across
    # only 3 of the 5 plugins (product-opportunity-solution-tree,
    # product-hypothesis-testing, product-guardrail-metrics) — the other 2
    # explicitly carry no record obligation. The probe passes once any one
    # of the 3 refuses the empty record.

`tests/run-gate-tests.sh` runs all 5 plugins' own
`tests/product-*-gate-tests.sh` suites plus core's
`compliance-check.sh` against each plugin's `hooks/` directory, so a future
hand-rolled kill switch or reconstruct drifting back away from `gate-lib.sh`
fails the suite instead of only being caught once.
