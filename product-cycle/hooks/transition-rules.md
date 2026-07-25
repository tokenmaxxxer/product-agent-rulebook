# product-cycle transition rules

Single source of truth for legal `product/state.md` (`stage` field)
transitions. Read by both `inject-transition-rules.sh` (UserPromptSubmit)
and `state-gate.sh` (PreToolUse). States are transcribed from
`docs/specs/state-machine.md`: `idle`, `scoping`, `researching`,
`hypothesis-registered`, `measuring`, `decided`.

`actor` is `user` when the transition requires the user to have said
something in this conversation authorizing it; `agent` when the agent may
make the transition on its own recognizance (still recorded, never
user-gated).

| from | to | actor | precondition |
|---|---|---|---|
| (none) | idle | agent | product/state.md does not yet exist; the agent creates it with stage `idle` as the initial state |
| idle | scoping | user | user has handed the role an idea to work on |
| scoping | researching | agent | agent has begun gathering evidence for the idea |
| researching | hypothesis-registered | agent | agent has proposed a metric, threshold, and decision rule and written them into the spec file |
| hypothesis-registered | measuring | user | user has approved the registered metric/threshold/decision-rule package in this conversation |
| hypothesis-registered | scoping | user | user has rejected the registered package, sending it back to gathering |
| measuring | decided | agent | the registered decision rule has been applied to the collected data |
