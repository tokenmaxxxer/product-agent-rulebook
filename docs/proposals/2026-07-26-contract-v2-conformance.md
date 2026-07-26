---
status: approved
---

# Bring product's rulebook into conformance with the v2 blackboard/event contract

`docs/specs/role-handoff-contract.md` (this repo's copy, landed at commit
b240ec4, `status: final`) replaces v1's one-shot ACCEPTS/refuse handoff
model with a shared blackboard each role reads, writes its own record onto,
and wakes from. Per the contract's own preamble: "Landing this contract in
each rulebook is separate, one proposal per repo." This is that proposal
for `product-agent-rulebook`. It is a proposal, not the implementation —
nothing outside this file is touched.

## What is out of date today

`README.md`'s "Handoff protocol" section (lines 45–107) and
`product-cycle/hooks/state-gate.sh` both still speak v1:

- README's `### Accepts` (line 57–61) lists a single accept/refuse table:
  > `**feasibility-record**` — to react to a verdict on a prior hypothesis.
  > Refuses: `build-proposal`, `qa-state`, `review-record`, `ops-state`.

  This conflates "may product read this" with "may product's conclusion
  depend on this" — exactly the conflation contract §4 calls out and
  replaces with three separate questions (READ / DEPENDS-ON /
  NEVER-OVERWRITE). It also names stale kind strings (`qa-state`,
  `ops-state`) that don't match the v2 kind table in contract §2 (`qa-record`,
  `ops-record`).

- README's `### Produces` section (line 71–85) is close to contract §2's
  row set for `hypothesis`, `one-pager`, `opportunity-tree` already, but is
  missing `product-record` entirely (contract §2 row 2:
  `docs/reports/records/<subject>/product.md`) — the record product needs
  in order to hold acceptance-criteria notes and finding-response entries.
  It also still carries a v1-only field, `handoff_status: provisional |
  final`, in its "Required fields" prose (line 76) and in `### Stops`
  (lines 102–106) — contract §1's common header has no `handoff_status`
  field; v2 uses `upstream[].sha` / `upstream[].acknowledged_sha` staleness
  (contract §12) instead.

- README's `### Stops` section's staleness rule (lines 89–94) is basically
  right in spirit but references the v1 field name and doesn't cite
  contract §12's `acknowledged_sha` mechanism, which changes the "ask every
  time" behavior into "ask once per sha, then remember."

- README line 24 ("This repository never reads another role's repository")
  and the "Self-contained by design" section are about cross-repository
  isolation, not board-reading — unaffected by this proposal, no change
  commissioned there.

- `product-cycle/hooks/state-gate.sh` (776 lines examined) currently
  enforces something narrower and orthogonal to the v1 ACCEPTS table: it
  gates writes to `product/state.md`'s `stage:` frontmatter field against
  `product-cycle/hooks/transition-rules.md`'s from/to row table (lines
  9–14, 108–150, 320–370). It does **not** implement the README's
  ACCEPTS/Refuses table mechanically at all — that table is prose-only
  today, unenforced by any hook. Concretely:
  - There is **no kind-based read-refusal logic** in state-gate.sh to
    delete — grep across `product-cycle/` and `docs/specs/` for `kind:`
    found no matches. The gate has never parsed a `kind:` field; it only
    parses `stage:` via `STAGE_RE = re.compile(r'^stage:\s*(.*?)\s*$',
    re.M)` (line 109 in the current file). So item 2(a) below ("delete any
    kind-based read-refusal logic") turns out to have nothing to delete
    in this repo — this proposal should say that plainly rather than
    invent a deletion.
  - The one v1-shaped behavior state-gate.sh does carry is the
    repo-local-contract refusal at lines 247–262: it denies any write
    reaching `product/state.md` when the target repo has no
    `docs/specs/role-handoff-contract.md` at its git root (`CONTRACT_REL =
    "docs/specs/role-handoff-contract.md"`, line 256; deny message at
    lines 258–262). This behavior is contract-agnostic (v1 or v2, the file
    must exist) and should be **kept**, per the task item 2(c) below.
  - Grep for `^kind:\s*(\S+)\s*$` (and any variant) across
    `product-cycle/`, `docs/specs/`, and `README.md` found zero matches.
    The only end-of-line-anchored frontmatter regex in this repo is
    `STAGE_RE` above, which parses `stage:`, not `kind:`. There is
    currently no kind-parsing regex in this repo to carry contract §2's
    trailing-comment defect (`kind: build-proposal  # re-scoped`
    must parse as `build-proposal`). This matters going forward: if this
    proposal's item 2(b) work (narrowing the gate to owned-path
    enforcement) requires the gate to read a record's own `kind:` field —
    e.g. to confirm a write under `docs/proposals/<date>-<slug>.md` is
    self-declaring `kind: hypothesis` and not something else — any new
    regex written for that purpose must be built end-of-line-comment
    tolerant from the start, on the model of `STAGE_RE` but extended to
    strip a trailing `#...` comment before matching, so the defect
    contract §2 warns about never gets introduced in the first place.
  - `product-cycle/hooks/run-gate-tests.sh` (80+ lines examined,
    `setup_root`/`json_write` helpers) tests only the `stage:` transition
    table behavior — same-state writes, gated transitions, threshold
    immutability. It has no cases for path-ownership refusal, DEPENDS-ON
    violations, or kind-parsing, because state-gate.sh has none of that
    logic today. **Flagging, not writing**: if item 2's gate rewrite adds
    owned-path-write refusal and/or kind-parsing, `run-gate-tests.sh`
    will need new cases exercising both (a write inside
    `docs/reports/records/<subject>/product.md` allowed, a write to
    `docs/reports/records/<subject>/coding.md` refused, a `kind: hypothesis
    # re-scoped` line still parsed correctly) — this proposal does not
    write those cases.

## Commissioned work

### 1. Rewrite README.md's "Handoff protocol" section (lines 45–107)

Replace the whole section — `### Accepts`, `### Where upstream lives`,
`### Produces`, `### Stops` — with a v2-shaped section built from the
following, each cross-referenced to the exact contract section it
restates (README should keep doing what it does today: excerpt for
convenience, defer to the work repo's own copy as authority):

- **Replace `### Accepts` with a `### WAKES-ON` subsection** stating
  contract §3's product row verbatim: "product wakes on a qa or review
  outcome whose content questions the standing acceptance criteria." Drop
  the stale `qa-state`/`ops-state`/`build-proposal`/`review-record`
  "Refuses" list — WAKES-ON is not an accept/refuse gate, it is a trigger
  condition, and refusing to read those kinds is no longer product's
  stance at all (see next bullet).
- **Add a `### READ / DEPENDS-ON / NEVER-OVERWRITE` subsection** replacing
  the old accept/refuse framing, stating contract §4's three questions at
  product's grain:
  - READ: broad, unconditional — product may read any board record for
    context, including `build-proposal`, `qa-record`, `review-record`,
    `ops-record` that the old Refuses line barred.
  - DEPENDS-ON: narrow — "product depends on `feasibility-record` (a
    verdict causing it to react)," quoting contract §4's own product
    bullet verbatim, since that's the one dependency contract §4
    explicitly assigns product.
  - NEVER-OVERWRITE: product writes only `docs/proposals/<date>-<slug>.md`
    (`kind: hypothesis`), `docs/reports/records/<subject>/product.md`
    (`kind: product-record`), `product/one-pager.md` (`kind: one-pager`),
    `product/opportunity-tree.md` (`kind: opportunity-tree`) — contract
    §11's product row, verbatim. Explicitly flag the shared-directory
    disambiguation contract §11 states: "`docs/proposals/` stays shared
    between product and coding, disambiguated by filename tag: coding's
    `build-proposal` filenames carry `-build-`
    (`<date>-build-<slug>.md`), distinct on its face from product's
    `<date>-<slug>.md`." README's existing prose at line 79 already gets
    this right ("product owns the `<date>-<slug>.md` filename form... coding
    owns `<date>-build-<slug>.md`") — carry it forward unchanged, but note
    explicitly, as its own callout, that any glob/regex product's tooling
    (including a future gate check) uses to recognize "is this file mine"
    under `docs/proposals/` must exclude the `-build-` tag, not just match
    on directory.
- **Add a `### Blackboard record shapes` subsection** replacing
  `### Produces`, listing all four kinds product owns per contract §2's
  table and §7:
  - `hypothesis` (`docs/proposals/<date>-<slug>.md`): `loop_state`
    vocabulary `idle,scoping,researching,hypothesis-registered,measuring,decided`;
    required fields beyond the common header: Background/Context, Problem
    Statement, Candidate Hypotheses, Known Risks, Goals/Success Metrics.
  - `product-record` (`docs/reports/records/<subject>/product.md`): same
    `loop_state` vocabulary as `hypothesis`; required fields: a pointer to
    the governing `hypothesis`, plus running acceptance-criteria notes.
    This is the kind README's current `### Produces` section omits
    entirely — add it as a new bullet, it does not exist in the file
    today.
  - `one-pager` (`product/one-pager.md`): standing doc, `loop_state: n/a`;
    required fields unchanged from what README already states
    (Background/Context, Problem Statement, Candidate Hypotheses, Known
    Risks, Goals/Success Metrics) plus the common header.
  - `opportunity-tree` (`product/opportunity-tree.md`): standing doc,
    `loop_state: n/a`, continuous interview log, no other required fields
    — unchanged from README's current text.
  - Drop `handoff_status: provisional | final` from the required-fields
    prose (README line 76) and from `### Stops` (lines 102–106) — v2's
    common header (contract §1) has no such field. Replace the "Input
    carries `handoff_status: provisional`" stop condition with contract
    §12's staleness rule (below).
- **Add a `### Finding participation` subsection** stating contract §5:
  product may both produce and receive `finding` blocks (generalized in
  v2 from v1's review-only findings). When product closes out a `finding`
  addressed to it, `product.md` (the `product-record`) must carry a
  `finding-response` entry with all three required parts per contract §5:
  the finding reference (record path + finding identifier), the action
  taken or decline reason, and — when applicable — proof of the fix. State
  plainly that an entry missing any of the three parts does not close the
  finding (contract §5's own wording).
- **Add a `### Loop termination` subsection** stating contract §6's rule
  as it applies to product: a wake is consumed only by writing the
  resulting record entry (a `loop_state` change, a new `finding`, a
  `finding-response`, or equivalent); an unchanged board wakes no one.
- **Rewrite the staleness stop condition** (replacing README lines 89–94)
  to cite contract §12 directly, including the `acknowledged_sha`
  refinement: first read of an `upstream` entry always prompts the user
  once; a later re-entry where the current sha matches the recorded
  `acknowledged_sha` does not re-prompt; a sha matching neither `sha` nor
  `acknowledged_sha` re-fires the full prompt.
- **Add a note on contract §9** (minting `subject`): v1 assumed product
  always opens the chain by minting `subject`; contract §9 states "Any
  role may open a chain — not only product... deterministic regardless of
  which role does it." Search README and the linked
  `docs/specs/state-machine.md` for any language implying product is the
  chain-opener by default (state-machine.md's "Carrying artifact and state
  field" section frames state as living in "one specification file per
  hypothesis," which is product-centric phrasing consistent with v1 but
  doesn't explicitly claim product always mints first) and update it to
  state the §9 search-before-minting rule: before minting, search
  `docs/reports/records/*/` and `docs/proposals/*` for an existing
  `subject` describing the same work and adopt it verbatim if found.

### 2. Rewrite `product-cycle/hooks/state-gate.sh` to match

- **(a) Read refusal.** Confirmed by grep: this gate has no kind-based
  read-refusal logic today (it has never parsed `kind:`), so there is
  nothing to delete under contract §4's READ-broad rule. State this
  explicitly in the gate's own header comment (currently lines 1–37) so a
  future reader doesn't go looking for removed logic that was never
  there — add a line noting the gate was already READ-broad by omission,
  and that this is now the contract-required, not merely accidental,
  state.
- **(b) Narrow the gate's job to three things**, per contract §4/§11/§10:
  1. Refuse writes outside product's four owned paths
     (`docs/proposals/<date>-<slug>.md` with `kind: hypothesis`,
     `docs/reports/records/<subject>/product.md`, `product/one-pager.md`,
     `product/opportunity-tree.md`) — this is new logic; nothing in the
     current 776-line script checks path ownership against contract §11's
     table, since the script only ever inspects `product/state.md`. Any
     new path-ownership check must distinguish product's
     `<date>-<slug>.md` from coding's `<date>-build-<slug>.md` under the
     shared `docs/proposals/` directory per contract §11's
     disambiguation, and must refuse-and-report rather than
     overwrite-or-merge on a conflict (contract §11: "assigns to a
     different role must refuse to write there and report the conflict to
     the user, rather than overwriting or merging into it silently").
  2. Refuse DEPENDS-ON violations only where mechanically detectable —
     contract §4 states product's sole DEPENDS-ON is `feasibility-record`;
     contract §14 already concedes "kind is self-declared and unverified"
     and "path ownership is a table, not a gate" unless a rulebook adds
     one, so this item should be scoped conservatively: check does not
     need to (and per contract §14, structurally cannot) verify the
     *substance* of a dependency claim, only flag the mechanically
     checkable case — e.g., a `product-record` write whose pointer field
     to the governing `hypothesis` is empty or missing.
  3. Keep the existing repo-local-contract refusal (current lines
     247–262: deny when `docs/specs/role-handoff-contract.md` is absent
     at the resolved git root) — this behavior predates and is orthogonal
     to v1-vs-v2 and should be carried forward unchanged, just re-pointed
     at whatever new write-paths the gate now also inspects (today it only
     fires for writes reaching `product/state.md`; item (b)(1) above
     means the gate now also inspects writes to the four owned paths, so
     this same repo-local-contract check should run ahead of those checks
     too, not just ahead of the `state.md` stage-transition check).
- **(c) Kind-parsing regex.** No `^kind:\s*(\S+)\s*$`-style regex exists
  in this repo today (confirmed by grep across `product-cycle/` and
  `docs/specs/`); the only comparable regex is `STAGE_RE =
  re.compile(r'^stage:\s*(.*?)\s*$', re.M)` at state-gate.sh line 109,
  which parses `stage:`, not `kind:`, and is itself already
  non-greedy/lazy but has no explicit comment-stripping. Since item (b)(1)
  above requires the gate to read a written record's own `kind:` field to
  confirm self-declared kind matches the path being written to, this
  commissions writing that regex correctly from the start: it must
  tolerate a trailing comment on the same line, per contract §2's own
  requirement ("`kind` parsing by any gate must tolerate a trailing
  comment on the line (`kind: build-proposal  # re-scoped`); a regex
  anchored to end-of-line with no comment tolerance is a gate defect, not
  a contract violation by the record's author.") — i.e. do not write
  `r'^kind:\s*(\S+)\s*$'` (which would fail on `kind: hypothesis  # note`
  since `\S+` stops at the space but `$` then fails to match the trailing
  comment), and instead strip an unquoted trailing `#...` comment before
  applying the value regex, mirroring how YAML frontmatter parsers
  conventionally handle inline comments.
- **(d) `run-gate-tests.sh`.** Flag, do not write: new cases will be
  needed for (1) owned-path write acceptance/refusal, (2) the
  DEPENDS-ON pointer check, and (3) a `kind: hypothesis  # re-scoped`
  parse case demonstrating the trailing-comment fix — `run-gate-tests.sh`
  currently has zero coverage of any of these three because the checks
  don't exist yet.

## Write set (files this proposal commissions changing)

- `/home/jwjung/tokenmaxxxer/product-agent-rulebook/README.md` — rewrite
  the "Handoff protocol" section, lines 45–107.
- `/home/jwjung/tokenmaxxxer/product-agent-rulebook/product-cycle/hooks/state-gate.sh` —
  add owned-path write-ownership refusal, add the mechanically-checkable
  DEPENDS-ON check, add a comment-tolerant `kind:` parser, update the
  header comment (lines 1–37) to describe the narrowed/confirmed scope,
  keep the existing repo-local-contract check (lines 247–262) and
  re-point it ahead of the new checks.
- `/home/jwjung/tokenmaxxxer/product-agent-rulebook/product-cycle/hooks/run-gate-tests.sh` —
  flagged only; new test cases for the three additions above are a
  follow-on, not committed to by this proposal.

Not in the write set, and should not be touched by an implementer acting
on this proposal without a separate check: `docs/specs/state-machine.md`
(the `stage:`/state-machine mechanism this gate also enforces is
untouched by the v2 contract — contract §7's `loop_state` and this repo's
`stage` field are two different, coexisting concepts; state-machine.md's
own content is out of scope here) and `product-cycle/hooks/transition-rules.md`
(same reason).

## Out of scope

- No code changes. This document commissions the rewrite; it does not
  perform it.
- No commit. Nothing in this repository is staged or committed as part of
  this proposal.
- No test-case authoring for `run-gate-tests.sh` (flagged above, not
  written).
- No change to `docs/specs/state-machine.md`, `transition-rules.md`, or
  any other repo's rulebook — this is one proposal for one repo, per the
  contract's own instruction.

## What did not work

- First attempt at the owned-path check tried to reuse
  `resolves_to_state_file`'s absolute-path comparison directly for §11
  paths, but that helper only compares against one fixed target
  (`product/state.md`); it was replaced with a general
  `repo_relative_or_none()` that returns a root-relative posix path so
  `classify_path()` can pattern-match it against all four owned kinds
  plus foreign-owned shapes.
- Considered extending the Bash-write heuristics (`BASH_WRITE_OPS`,
  `looks_state_shaped`) to also detect owned-path/foreign-path writes
  made via `echo >`, `tee`, `sed -i`, etc., matching how state.md writes
  are already caught for Bash. Dropped: contract §14 already concedes
  kind is self-declared and path ownership is "a table, not a gate"
  unless a rulebook adds one, and the existing Bash heuristics are
  content-blind (they only ever check the *target path*, never resulting
  content) — extending them here would require resolving trailing
  content for an arbitrary shell redirect/heredoc, which the existing
  `unresolved_bash` fail-closed path already declines to attempt even for
  state.md. Scoped the new owned-path/kind/DEPENDS-ON checks to
  Write/Edit only, where `tool_input` already carries literal resulting
  content; left Bash writes to owned/foreign paths unactioned by the new
  checks (they still get the existing repo-local-contract gate if they
  happen to resolve to `product/state.md`, but not the new §11/§4
  checks) rather than ship an untested, content-blind heuristic.
- Ran `product-cycle/hooks/run-gate-tests.sh` before and after the gate
  rewrite to confirm no regression: baseline is 6 passed / 7 failed (the
  7 failures are pre-existing, unrelated to this change — they fail with
  the repo-local-contract-missing message because this repo's own
  working tree has no `docs/specs/role-handoff-contract.md`, which is a
  separate, already-existing gap this proposal's write set does not
  cover). Post-rewrite result is identical: 6 passed / 7 failed, same
  cases.
