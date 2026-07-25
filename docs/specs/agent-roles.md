---
status: draft
---

# Agent roles and their state machines

This document defines the `product` agent role that this repository
implements, specifies how the human user drives it in a star topology (user
at the centre, agents never talking to each other), and gives its internal
state machine at the concreteness of `coding-agent-rulebook`'s warrant
plugin: named states, a named artifact carrying the state, explicit gate
conditions evaluated on a file, not on which tool wrote it.

Sources for every research claim are the eight files under
`docs/reports/research/2026-07-25-swpd-roles/`, cited by filename.

## Part 1 — Roles

### `product`

**Decides**: what to build — value risk and business-viability risk, in
Cagan's product-trio framing where the PM owns exactly those two risks
(product-discovery.md). In a feature team, by contrast, that risk sits with
whichever stakeholder requested the feature and the PM only executes a list
— tokenmaxxxer's `product` role is deliberately the empowered-team version,
not the feature-team version (product-discovery.md).

**Given to start**: an idea — nothing more is required to open the role.

**Produces**: a specification, or a kill record. Which one depends on
running the idea through a pre-registered hypothesis: the metric, the
threshold, and the decision rule fixed before data collection, exactly as
`hypothesis-testing`'s registered-rule discipline requires and as Stage-Gate
formalizes with must-meet (binary, knockout) vs. should-meet (weighted)
criteria — a single "No" on a must-meet kills the project regardless of
should-meet scores (lifecycle-frameworks-handoffs.md).

**Prevents**: building something nobody wants, and — the sharper failure —
deciding that only after the fact, against no threshold fixed in advance.
Teresa Torres documents the softer version of this same failure: when
discovery and delivery split into separate teams, each handoff loses context
"like a game of telephone," producing distorted requirements
(product-discovery.md). `product` is scoped to prevent both the after-the-fact
judgment call and the telephone-game handoff, by fixing the rule before the
handoff happens.

### Open question — design/UX

Two research findings point in opposite directions and neither is decided
here.

For a separate role: design-to-development handoff is the most-reported
breakage point found in this research — 92% of designers and 91% of
developers report the handoff process has room for improvement, near-
universal dissatisfaction rather than an edge case, attributed to process and
tooling gaps rather than to people (design-ux.md).

For folding into `product`: UX research responsibilities are being absorbed
into product roles industry-wide — 47% of companies that laid off UX staff
reassigned design/research responsibilities to product teams, alongside a
sharp 2024–2025 drop in dedicated UX-research postings and maturing AI
tooling letting PMs run their own studies (design-ux.md).

Whether tokenmaxxxer needs a standalone design/UX role depends on whether the
product being built is UI-centred; this document takes no position on that
axis because it is a property of each future project, not of the org.

## Part 2 — Working with the role

The user is the only channel into and out of `product`. It never talks to
another agent, and it runs in its own sandbox with only its own plugin
installed — it never reads another role's repository, the same isolation
`coding-agent-rulebook` and `qa-agent-rulebook` already keep toward each
other.

**Starting the role.** The user hands `product` whatever its "given to
start" line in Part 1 names — an idea. Opened without that met, the role
still opens — nothing locks the door — but it has nothing to work from and
says so; the requirement is on the work, not a gate on entry.

**Answering a gate.** The role stops at named points (Part 3) and needs a
decision only the user can give: approval of the
metric/threshold/decision-rule package, or a threshold confirmation. The
role never infers approval from the content of a file — a file saying the
right things is not consent. Whether the user approved, rejected, or
course-corrected is a semantic judgement the model makes from the
conversation, checked against `transition-rules.md` (Part 3) for whether the
resulting move is one the table allows for that actor. This is unlike
`qa-cycle`'s own mechanism, which mints a single-use verdict token from the
user's own turn (qa-agent-rulebook's `docs/specs/qa-cycle-state-machine.md`);
`product` uses no such token.

**Carrying output forward.** The user moves the specification out of this
sandbox by hand — copies the file, opens whatever comes next with it as
starting input. Nothing is automatic, nothing is shared between
repositories, and `product` never reads another role's files directly. This
is the same constraint `coding-agent-rulebook` and `qa-agent-rulebook`
already satisfy toward each other today.

**Returning to a finished role.** The user may reopen `product` at any time
with new input — a killed idea can be reopened with a new hypothesis. Order
relative to whatever roles come before or after it is advisory: nothing in
this repository enforces a sequence; the user routes.

**The failure this arrangement has, stated plainly.** With the user as the
only router and no cross-agent communication, the thing that goes wrong is
the user losing track of which output is current — which specification is
the live one. The mitigation costs nothing and requires no shared machinery:
`product`, on being opened, reports its own current state and what its last
output was based on, read from its own repository — the same thing
`warrant/hooks/state.sh` already does at `SessionStart` for `coding` ("reads
the proposal files and git, and says where things stand. It writes
nothing"). This is visibility into `product` alone. There is no global view
across roles, and this role stays silently stale if never reopened after its
output is consumed elsewhere. That cost is accepted deliberately: a global
view would need a shared write target, and a shared write target is exactly
what per-repository write gates (`scope-gate.sh`'s write-set freeze,
`qa-cycle`'s workspace-only persistence) exist to refuse.

## Part 3 — State machine

Mechanism applying to the `product` role below. There is no approval-token
minting hook and no regex deciding intent: whether the user approved,
rejected, or course-corrected is a semantic judgement the model makes from
conversation context, not a token minted by a hook.

`product`'s legal transitions live in a per-repo data file
`product-cycle/hooks/transition-rules.md`, pipe-delimited with columns
`from | to | actor | precondition`, where `actor` is `user` for transitions
that require the user to have said something and `agent` otherwise. A
`UserPromptSubmit` hook renders the rows matching the current state into
every prompt as a condition→allowed-transition table. If the table or the
state file cannot be read, that hook still emits a block saying so and
forbidding transitions until it is fixed — it never exits silently.

The `PreToolUse` gate decides only two things: whether a write reaches
`product`'s state file, judged by resolved target path rather than tool
name or literal filename (the same discipline `scope-gate.sh` applies for
`coding`: a guard that inspects only file-editing tool payloads is bypassed
by the same edit made through a shell redirect or in-place `sed`, so the
gate resolves the path regardless of which tool produced the write), and
whether the resulting transition is a row in the table. It reports "rules
could not be loaded" and "transition not in table" as distinct denials.
Anything not reaching the state file passes.

On each transition the model appends one line to the state file naming the
user utterance it read as the basis. Nothing enforces this; it exists so a
reader outside the session can see what the transition rested on.

This rulebook implements all of this itself — no shared file, no cross-repo
dependency.

A self-loop (a row whose `from` and `to` are the same state) is a legal
transition-table row like any other, gated the same way when marked
`actor: user`. It is how a repeatable, no-clean-single-precondition decision
(a timebox extension, a continuous sign-off, a disputed-finding
resolution) is recorded without minting a state the shape does not need.

**Skills.** `product` also carries a `skills/` directory,
`product-cycle/skills/<name>/SKILL.md`, one skill per artifact-producing
conversation named below. A skill runs a conversation with the user and
writes a named artifact to its own file path (e.g. `product/one-pager.md`)
— a different file from `product`'s state file. **This matters because it
is easy to get backwards: the `PreToolUse` gate above binds only to the
state file's resolved path. A skill's artifact write is never gated** — the
model can write, revise, or fail to write a one-pager freely; only the
write that changes the `status` field in the state file is checked against
the transition table.

**Bootstrap convention.** When `product`'s state file does not exist, the
current state is the synthetic literal `(none)`. Its `transition-rules.md`
carries at least one row whose `from` is `(none)`, naming its legal initial
state; the write that creates the state file is allowed exactly when such a
row exists for the target, and denied otherwise as an ordinary "transition
not in table" case — no separate mechanism from the one above. The
`UserPromptSubmit` injector renders `(none)` as a normal current state and
lists its rows like any other; it emits the "rules could not be loaded"
failure block only for a missing or unparseable `transition-rules.md`, or a
state file that exists but whose state field is absent, duplicated, or
unparseable — a missing state file is not a failure. A state file that
exists is checked, both by the `UserPromptSubmit` injector and by the
`PreToolUse` gate, against `product`'s declared state list regardless of
what value it holds — `(none)` included — and any value outside that list,
`(none)` or otherwise, is treated identically to "unparseable," never
merged with the true-absent case. `(none)` never appears as a `to` value:
nothing transitions into it, and deleting the state file is not a
transition. `coding-agent-rulebook` and `qa-agent-rulebook` are untouched by
this convention.

### `product`

**Carrying artifact**: the specification file (e.g.
`docs/proposals/<date>-<slug>.md`); state lives in its frontmatter field
`status`.

**States**: `idle`, `scoping`, `researching`, `hypothesis-registered`,
`measuring`, `decided`.

**Transition table**:

| From | To | Fires on |
|---|---|---|
| `idle` | `scoping` | user hands the role an idea |
| `scoping` | `researching` | agent begins gathering evidence for the idea |
| `researching` | `hypothesis-registered` | agent proposes a metric, threshold, and decision rule; written into the file |
| `hypothesis-registered` | `measuring` | **gated** — user approves the registered package in their own turn |
| `measuring` | `decided` | the registered rule is applied to collected data |
| `hypothesis-registered` | `scoping` | user rejects the package; back to gathering |
| `scoping` | `scoping` | **gated, self-loop** — user co-creates or affirms the opportunity/outcome framing; not a hard gate, may loop indefinitely |
| `decided` | `scoping` | **gated** — a HiPPO-style conflict between the recorded decision and a senior stakeholder's opinion escalates and the broadened group reopens evidence-gathering; weakest-sourced row in this table |

The continuous re-interviewing loop (weekly interviews, a living Opportunity
Solution Tree) is not a state: it is carried by a second, separately
maintained artifact, `product/opportunity-tree.md`, updated on its own
cadence by its own skill, outside this table entirely — the gate does not
bind to it because it is not the state file.

**Rejection rule**: `hypothesis-registered -> measuring` fails unless the
file's metric field, threshold field, and decision-rule field are all
non-empty AND the transition-rules table has a `hypothesis-registered |
measuring | user | ...` row whose precondition the model judges met from the
user's own turn. A file with all three fields filled in but no such
semantic approval does not pass — content is not consent.

**Refuses while in each state**: in `idle`, refuses to scope anything (no
idea yet handed over). In `scoping`/`researching`, refuses to write a
decision rule that has not yet been derived from evidence. In
`hypothesis-registered`, refuses to enter `measuring` without the approval
condition above. In `measuring`, refuses edits to the threshold field —
once measurement starts, the finish line cannot move; a write to the
threshold field while `status: measuring` is a rejected write regardless of
which tool attempts it (Bash redirect included, per the rule above). In
`decided`, refuses to produce a verdict by fresh judgement — the output must
be the mechanical application of the rule fixed in `hypothesis-registered`,
not a new argument.

## Reference

Full sourcing for every claim above is in
`docs/reports/research/2026-07-25-swpd-roles/`: `product-discovery.md`,
`design-ux.md`, `engineering-architecture.md`, `qa-testing.md`,
`release-ops-sre.md`, `security-legal-compliance.md`,
`data-experimentation.md`, `lifecycle-frameworks-handoffs.md`.

Gate mechanics with published, checkable criteria — not just a named
gate but a stated rule for what makes it fail — were found in exactly four
places across this research: Cooper's Stage-Gate must-meet/should-meet split,
Google's error-budget release-freeze policy, GDPR's Article 35 DPIA
requirement, and Shape Up's betting table. The strongest-enforced gate in
industry practice found anywhere in this research is ordinary code review,
because unlike the other four it has a mechanical blocking device attached
directly to the merge action rather than a process convention around it.
