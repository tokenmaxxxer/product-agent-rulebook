#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

you_decide=$'YOU DECIDE: whether the problem is stated on its own terms — a JTBD\ntuple fixed before any solution is named — so nobody adopts a solution\nbefore the problem it answers has been said plainly.'
use_when=$'CURRENT-STATE SURVEY (phase 1, one-pager lens): background/context, then\nthe PROBLEM STATED WITHOUT ANY SOLUTION ATTACHED, as a JTBD tuple (job\nperformer, job, circumstance, desired outcome) fixed BEFORE any solution\nis named — if the issue text embeds a solution, restate the problem in\nthe customer\'s terms and note the gap.'
produces=$'This plugin has no phase-2 (record) obligation — it fires only on the\ncurrent-state survey write and stays silent on the record path.'
hand_off=$'No phase-2 hand-off: this plugin has no record obligation, so there is\nnothing to carry into execution judgment.'

core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
