#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

you_decide=$'YOU DECIDE: where the current problem sits on the opportunity-solution\ntree, and later, which branch the evidence prunes or promotes. Your\nstake is keeping the standing tree honest — a survey or record that\nnever names its own branch leaves the tree silently stale.'
use_when=$'CURRENT-STATE SURVEY (phase 1, one-pager lens): where this sits in the\nopportunity-solution tree: state the relevant branch (outcome,\nopportunity, candidate solutions, discriminating assumption test) in\nOST\'s four-layer vocabulary, not free prose.'
produces=$'PROPOSAL (phase 1): this facet\'s own obligation on the proposal surface\nis the cross-plugin order constraint only — that the current-state\nsurvey already exists before any product-discovery proposal is\nwritten. It does not additionally require OST vocabulary in the\nproposal itself.'
hand_off=$'EXECUTION JUDGMENT (phase 2, quality bar):\n- The record updates the opportunity-solution tree: which branch was\n  pruned (kill) or promoted (go/pivot), in OST\'s four-layer vocabulary.\n  The pre-committed ITWWS follow-up is either actioned or explicitly\n  deferred with a reason.'

core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
