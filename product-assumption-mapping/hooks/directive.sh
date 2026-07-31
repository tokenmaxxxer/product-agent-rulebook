#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

you_decide=$'YOU DECIDE: nothing of its own — this plugin has no survey or record\nobligation. It is a single proposal-write facet: evidence-citation format\nand RICE/ICE prioritization, checked on top of whatever the other\nproduct-discovery plugins already require.'
use_when=$'RESEARCH (phase 1, assumption-mapping skill): when evidence is cited in a\nproposal and when more than one opportunity or solution candidate is\ncompared, this plugin\'s gate is the one that checks the citation shape\nand the prioritization score — it does not own the current-state survey\nor the hypothesis package themselves.'
produces=$'PROPOSAL (phase 1): When more than one opportunity or solution candidate is\ncompared, score each with RICE (Reach, Impact, Confidence, Effort); fall\nback to an explicitly-flagged ICE score only when reach data is genuinely\nunavailable. Cite each piece of evidence as one line — interview/\nobservation count, approximate date range, short paraphrase — never a\nbare claim; stated preference or hypothetical response is not\nadmissible evidence, per the Mom Test rule above.'
hand_off=$'EXECUTION JUDGMENT (phase 2): this plugin has no phase-2 obligation and\nstays silent on the record path — the record itself is owned by\nproduct-hypothesis-testing, product-guardrail-metrics, and\nproduct-opportunity-solution-tree.'

core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
