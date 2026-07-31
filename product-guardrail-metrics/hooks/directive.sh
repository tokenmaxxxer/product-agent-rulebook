#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

you_decide=$'YOU DECIDE: whether guardrail metrics are named and non-empty at\nregistration, and whether guardrail status is stated explicitly at\nmeasurement time. You prevent a win on the primary metric while a\nguardrail quietly breaches from passing as an unqualified win.'
use_when=$'REGISTRATION (phase 1, guardrail-metrics skill): while the product role\nis in `hypothesis-registered`, before the transition to `measuring`,\nname the guardrail metric(s) that must not move adversarially, distinct\nfrom the primary metric and from secondary metrics.'
produces=$'PROPOSAL (phase 1, pre-registration): Guardrail metrics are named and\nnon-empty at the same moment the hypothesis is registered — a win on\nthe primary while a guardrail breaches is a reduced-trust result, not a\nwin.'
hand_off=$'EXECUTION JUDGMENT (phase 2, quality bar): the record states, next to\neach other, the measured metric value and the threshold it is compared\nagainst, plus guardrail-metric status at that same measurement moment\n(explicit — never implied).'

core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
