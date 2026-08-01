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
                                        name appears. Ships skills:
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
                                        genuinely unavailable. Ships skills:
                                        assumption-mapping.
    product-hypothesis-testing/        Pre-registers a named metric, a
                                        numeric threshold, and a go/kill/
                                        pivot decision rule on the proposal
                                        before data collection; pre-commits
                                        an ITWWS follow-up; applies the
                                        registered rule mechanically at
                                        record time (measured value adjacent
                                        to its threshold, ITWWS actioned or
                                        explicitly deferred with a reason).
                                        Ships skills: hypothesis-testing.
    product-guardrail-metrics/         Guardrail metrics named non-empty at
                                        the same moment a hypothesis is
                                        registered (proposal), and their
                                        status stated explicitly at
                                        measurement time (record) — silence
                                        is never "assumed fine". Ships
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

`loop_state`: `idle, scoping, researching, hypothesis-registered,
measuring, decided` plus `scope-proposed` when this is the subject's
front record (terminal: `decided` / `scope-proposed`). `scope-approved`
is the human-only accept state the external pre-approval gate raises a
`scope-proposed` record to — never written by this role, never part of
this vocabulary.

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
    # ...and so on per plugin; deny-only-check.sh's substance probe targets
    # a generic docs/issue-<n>/reports/product.md path that no gate in this
    # repo claims (each plugin only fires on its own proposal/survey/record
    # scope), so that probe is a known no-op here, not a regression.

`tests/run-gate-tests.sh` runs all 5 plugins' own
`tests/product-*-gate-tests.sh` suites plus core's
`compliance-check.sh` against each plugin's `hooks/` directory, so a future
hand-rolled kill switch or reconstruct drifting back away from `gate-lib.sh`
fails the suite instead of only being caught once.
