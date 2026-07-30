# tokenmaxxxer / product-agent-rulebook

The `product` role on contract v3. A product session is spawned with two
plugin sets installed: this marketplace's `product` plugin, and the
[tokenmaxxxer-core](https://github.com/tokenmaxxxer/tokenmaxxxer-core)
plugins (`core`, `terse`, `freelunch`, `scout`). Core owns the interaction
protocol — issue in, two-phase PR out (research/survey/proposal → human
review Approve → execution), branch `issue-<n>/product`, record at
`docs/issue-<n>/reports/product.md`. This rulebook owns only what is
product-specific.

## What `product` decides

What to build — value risk and business-viability risk. The deliverable is
a specification or a kill record, whichever the pre-registered hypothesis
says: the metric, the threshold, and the decision rule are fixed before
data collection, and the eventual go/kill/pivot call is the mechanical
application of that rule, never a fresh judgment once the numbers are in.

## What is here

    product/hooks/directive.sh          SessionStart — the four facets:
                                        research (assumption mapping, Mom Test
                                        evidence), survey (one-pager lens —
                                        problem stated without a solution),
                                        proposal (pre-registered hypothesis +
                                        guardrails + ITWWS), judgment
                                        (mechanical verdict, immutable
                                        threshold, must-meet knockouts)
    product/hooks/record-fields-gate.sh s20 minimum content + governing-
                                        hypothesis pointer on the record
    product/hooks/trailer-gate.sh       commits staging docs/issue-<n>/** carry
                                        `Subject: issue-<n>`
    product/hooks/handbook-trigger-gate.sh  s21 same-turn handbook sync
    product/skills/                     hypothesis-testing, assumption-mapping,
                                        one-pager, opportunity-solution-tree,
                                        guardrail-metrics
    tests/                              repo-level checks (never installed)

## Record vocabulary

`loop_state`: `idle, scoping, researching, hypothesis-registered,
measuring, decided` plus `scope-proposed` when this is the subject's
front record (terminal: `decided` / `scope-proposed`). `scope-approved`
is the human-only accept state the external pre-approval gate raises a
`scope-proposed` record to — never written by this role, never part of
this vocabulary. Standing docs owned continuously, off the issue cycle:
`docs/specs/one-pager.md`, `docs/reports/opportunity-tree.md`.

## Install

    claude plugin marketplace add tokenmaxxxer/product-agent-rulebook
    claude plugin install product@tokenmaxxxer-product

Kill switch: `PRODUCT_CYCLE_OFF=1`.

## Run the checks

    /bin/bash tests/parse-check.sh
    /bin/bash tests/run-gate-tests.sh
    /bin/bash tests/deny-only-check.sh
