# product-cycle transition rules

Single source of truth for legal `product/state.md` (`stage` field)
transitions. Read by both `inject-transition-rules.sh` (UserPromptSubmit)
and `state-gate.sh` (PreToolUse). States are transcribed from
`docs/specs/state-machine.md` and revised per
`docs/proposals/2026-07-28-role-workflow-plugins.md`: `idle`, `scoping`,
`researching`, `hypothesis-registered`, `measuring`, `decided` — the state
set itself is unchanged; only the row set below grew.

`actor` is `user` when the transition requires the user to have said
something in this conversation authorizing it; `agent` when the agent may
make the transition on its own recognizance (still recorded, never
user-gated).

| from | to | actor | precondition |
|---|---|---|---|
| (none) | idle | agent | product/state.md does not yet exist; the agent creates it with stage `idle` as the initial state |
| idle | scoping | user | user has handed the role an idea to work on |
| scoping | scoping | user | opportunity/outcome framing has been drafted (e.g. via the `one-pager` skill) and the user co-creates or affirms that framing in their own turn — not a hard gate, may loop indefinitely; a vague affirmation ("sounds about right") is not sufficient, the model re-asks for its evidentiary source (product interaction research, moment 1) |
| scoping | researching | agent | agent has begun gathering evidence for the idea |
| researching | hypothesis-registered | agent | agent has proposed a metric, threshold, and decision rule and written them into the spec file, with guardrail metrics also named (non-empty) per the `guardrail-metrics` skill |
| hypothesis-registered | measuring | user | user has recorded a funding/betting decision (a bet, a stage-gate go, or an equivalent alignment/go call) approving the registered metric/threshold/decision-rule/guardrail package in this conversation (product interaction research, moments 2 and 3) |
| hypothesis-registered | scoping | user | user has rejected the registered package, sending it back to gathering |
| measuring | measuring | agent | a collected-data/progress field is being recorded while status: measuring; threshold is not among the changed fields (state-gate.sh's separate threshold-immutability check in measuring still applies and is not loosened by this row) |
| measuring | decided | agent | the registered decision rule has been mechanically applied to the collected data — deliberately not `actor: user`, since pre-registration exists precisely so this step has no discretionary case |
| decided | scoping | user | a HiPPO-style conflict between the recorded decision and a senior stakeholder's opinion escalates, and the broadened stakeholder group reopens evidence-gathering (product interaction research, moment 6) — the weakest-sourced row in this table; no terminal forcing rule exists in the research for an unresolved standoff |

Five `actor: user` rows.

Note: `product/opportunity-tree.md` is a separate, non-gated artifact
maintained by the `opportunity-solution-tree` skill on its own cadence. It
is not `product/state.md`; no transition in this table binds to it, and the
gate below does not check writes to it.
