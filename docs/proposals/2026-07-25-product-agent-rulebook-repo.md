---
status: landed
files:
  - product-agent-rulebook/README.md
  - product-agent-rulebook/.gitignore
  - product-agent-rulebook/.claude-plugin/marketplace.json
  - product-agent-rulebook/product-cycle/.claude-plugin/plugin.json
  - product-agent-rulebook/product-cycle/hooks/hooks.json
  - product-agent-rulebook/product-cycle/hooks/state-gate.sh
  - product-agent-rulebook/product-cycle/skills/
  - product-agent-rulebook/docs/README.md
  - product-agent-rulebook/docs/specs/state-machine.md
  - product-agent-rulebook/docs/handbooks/
  - product-agent-rulebook/docs/decisions/
  - product-agent-rulebook/docs/reports/
  - product-agent-rulebook/docs/proposals/
  - product-agent-rulebook/docs/_assets/
---

# Product agent rulebook: repository

## Intent

With the role definitions and their state machines now specified in
`docs/specs/agent-roles.md`, the first of the four new rulebook repositories
is to be built: `product`, the role that decides what to build. It is built
first — ahead of `feasibility`, `review`, and `ops` — so the repository shape
is established once, against a real state machine, and validated before the
remaining three roles replicate it.

## Constraints already settled

- Fully self-contained: no shared code, no cross-repo dependency, no shared
  file with any other rulebook. Installable alone into its own sandbox.
- `coding-agent-rulebook` and `qa-agent-rulebook` are NOT modified.
  `coding-agent-rulebook` is read as a structural reference only.
- The `product` state machine is exactly as specified in
  `docs/specs/agent-roles.md`: states `idle`, `scoping`, `researching`,
  `hypothesis-registered`, `measuring`, `decided`; the gated transition
  `hypothesis-registered -> measuring` is refused unless metric, threshold,
  and decision rule are all present in the state file and the user has
  approved them in their own turn; threshold edits are refused once in
  `measuring`; `decided` applies the registered rule rather than fresh
  judgement.
- Rejection rules are evaluated against the path being written, never
  against which tool performs the write — a guard that inspects only
  file-editing tool payloads is bypassed by the same edit made through a
  shell command.
- The user does all coordination by hand. No machinery for artifact
  lineage, no ledger, no shared index.
- Only three of the four new roles follow after this one; this proposal
  covers `product` alone.

## What will be done

Build the repository at `/home/jwjung/tokenmaxxxer/product-agent-rulebook/`:

- `git init` and an initial commit. The initial commit carries a
  `Proposal: docs/proposals/2026-07-25-product-agent-rulebook-repo.md`
  trailer naming this proposal.
- A plugin (`product-cycle`) mirroring the structural conventions found in
  `coding-agent-rulebook`: a `.claude-plugin/plugin.json` manifest, a
  top-level `.claude-plugin/marketplace.json` registering the plugin (as
  `warrant` is registered for `coding-agent-rulebook`), a `hooks/hooks.json`
  hook registration, and a `skills/` directory for the plugin's skill
  content.
- A state file convention: the specification file itself (e.g.
  `docs/proposals/<date>-<slug>.md` inside a project the role is pointed at,
  matching the carrying-artifact convention `agent-roles.md` names for
  `product`), with the state carried in its frontmatter field named
  `status`, taking one of the six state values above.
- A `PreToolUse` hook (`product-cycle/hooks/state-gate.sh`) enforcing the
  state machine's rejection rules by target path: refuses writes to the
  threshold field once `status: measuring`; refuses the
  `hypothesis-registered -> measuring` transition unless metric, threshold,
  and decision-rule fields are all non-empty and an approval token from the
  user's own turn is recorded; refuses `decided` output that rewrites the
  rule rather than applying it. The hook resolves the target path or shell
  command string being acted on regardless of which tool produced it, so a
  Bash-mediated write (`echo ... > file`, `sed -i`, `tee`) is judged the
  same as a Write/Edit payload — it must not check only Edit/Write tool
  inputs and let the same edit through when made via Bash. The hook fails
  closed: if its own input (the tool call payload, or the state file it
  reads) is malformed or unparseable, it refuses rather than falling
  through to allow.
- The six documentation buckets under `product-agent-rulebook/docs/`:
  `specs/`, `handbooks/`, `decisions/`, `reports/`, `proposals/`, `_assets/`,
  matching `coding-agent-rulebook`'s docs bucket layout. `docs/specs/state-
  machine.md` records the state machine this repository implements — the
  `product` table, rejection rule, and per-state refusals transcribed from
  `docs/specs/agent-roles.md` into this repository's own words, since the
  repository must be self-contained and not depend on reading the other
  repository at runtime.
- A README covering: what the role does (decides what to build, produces a
  specification or a kill record, per `agent-roles.md`); what it is given to
  start (an idea, nothing more); what it produces (a specification or a
  kill record, driven by a pre-registered hypothesis); and how to install
  the plugin into a sandbox, following the install-path convention shown by
  `coding-agent-rulebook/install.sh` and its README's install section.

Adjustments to the plugin-internal paths listed in this proposal's
frontmatter will be made only if building the repository shows
`coding-agent-rulebook`'s actual convention differs materially from what is
listed above; no such difference was found during the structural read that
informed this proposal, so the paths above are expected to hold as written.

**Not executed or verified in this work**: the hook (`state-gate.sh`) is
written but not exercised against a live session — no test run drives a real
tool call through it, no state file is created and walked through its six
states, and no approval-token flow is rehearsed end to end. Exercising the
hook against a live session is a separate step, out of scope here.

## Out of scope

- Creating a GitHub remote for the new repository. The authenticated `gh`
  account is `JiwonJung94`; the `tokenmaxxxer` org's repositories do not
  appear in that account's repo list, and whether it holds permission to
  create repositories under the `tokenmaxxxer` org is unconfirmed. The
  repository is therefore created locally only in this work; adding a
  remote is a separate proposal, to be made once org permission is
  confirmed.
- The other three rulebooks (`feasibility`, `review`, `ops`) — they follow
  this shape in later proposals, once this one lands and is validated.
- Any modification to `coding-agent-rulebook` or `qa-agent-rulebook`.
- Any shared file or cross-repository mechanism between this repository and
  any other rulebook.
- Resolving the design/UX open question recorded in
  `docs/specs/agent-roles.md` (whether UX research responsibilities fold
  into `product` or stay a standalone role) — that question is explicitly
  left open by the landed spec and is not decided by building this
  repository.

## How we will know it worked

The repository is adequate when:

- The `product-cycle` plugin can be installed into a sandbox on its own,
  with no other rulebook repository present, and functions without
  reaching outside itself.
- The state file convention and its state-carrying field are named and
  documented in `docs/specs/state-machine.md` and the README, matching
  `agent-roles.md`'s carrying-artifact description for `product`.
- Every transition in `agent-roles.md`'s `product` transition table (`idle
  -> scoping`, `scoping -> researching`, `researching ->
  hypothesis-registered`, `hypothesis-registered -> measuring` (gated),
  `measuring -> decided`, `hypothesis-registered -> scoping`) has a
  corresponding rule in `state-gate.sh` — either an enforced check or an
  explicit no-op where no machine check applies (e.g. transitions that fire
  on the user's own action rather than on any file content).
- Each gated transition's rejection is expressed as a condition evaluated
  on a file path (the state file's fields, or the target path of a write),
  never as an instruction directed at the model — consistent with the
  rejection-rule convention `agent-roles.md` states applies to all four new
  roles and that `coding-agent-rulebook`'s `scope-gate.sh` already
  implements for `coding`.

Superseded by `docs/proposals/2026-07-25-agent-rulebook-repos.md`.
