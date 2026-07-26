---
status: approved
files:
  - docs/specs/role-handoff-contract.md
  - product-cycle/hooks/run-gate-tests.sh
  - docs/proposals/2026-07-27-repo-local-contract-file.md
---

## Intent

`product-cycle/hooks/state-gate.sh` already enforces contract §11
(owned-path write refusal) and the mechanically-checkable half of
contract §4 (DEPENDS-ON), and its `require_contract()` refuses every
handoff-protocol action outright when
`docs/specs/role-handoff-contract.md` is absent from the project root
(state-gate.sh:292-311). This repository — `product-agent-rulebook`
itself — has never carried that file, so the gate has been running in
permanent refusal mode here: `require_contract()` denies before any
of the §11/§4 logic it guards ever executes. The intent is to give
this rulebook its own repo-local copy of the v2 handoff contract so
`require_contract()` passes and the ownership/DEPENDS-ON checks it
gates actually run, in this repo, on real state-gate invocations.

## What will be done

- Create `docs/specs/role-handoff-contract.md` with the v2 handoff
  contract content, sourced verbatim via
  `git show v2-conformance:docs/specs/handoff-protocol.md` from
  `/home/jwjung/tokenmaxxxer/coding-agent-rulebook` (that tag's
  frontmatter already reads `status: final`). This repo's own
  `state-gate.sh` comments already cite this file by this exact path
  and section numbers (§2, §4, §11, §14), so the copied content is
  checked against those citations for section-number consistency
  before being written.
- Update `product-cycle/hooks/run-gate-tests.sh`: its `setup_root()`
  helper (run-gate-tests.sh:29-40) builds each test's scratch project
  root under `mktemp -d` with only a `product/` directory — no
  `docs/specs/`. Under a repo-local contract requirement, every
  scratch root is its own "project root" and needs the same contract
  file `require_contract()` looks for, or every existing test case
  would newly fail on contract-absence rather than exercising the
  ownership/DEPENDS-ON behavior it currently asserts. `setup_root()`
  will be extended to also write
  `<scratch-root>/docs/specs/role-handoff-contract.md` (copied from
  this repo's own new contract file) so the harness's fixtures match
  what a real project root now carries.
- No changes to `state-gate.sh` itself — its `require_contract()` and
  §11/§4 enforcement logic are already correct against the contract;
  only the contract's absence is being fixed.

## Files write set

- `docs/specs/role-handoff-contract.md` — new file, v2 contract
  content copied from coding-agent-rulebook's `v2-conformance` tag.
- `product-cycle/hooks/run-gate-tests.sh` — `setup_root()` extended to
  seed the contract file into each scratch test root.
- `docs/proposals/2026-07-27-repo-local-contract-file.md` — this
  proposal.

## Out of scope

- Any repository other than `product-agent-rulebook` (read-only
  reference to `coding-agent-rulebook` for source content only).
- Merging this proposal or changing its `status` frontmatter.
- Any remote/push operation (this repo is local-only; none is made).
- Changes to `state-gate.sh`'s enforcement logic — believed correct
  and unchanged by this work.

## How we know it worked

- `require_contract()` no longer denies in this repo:
  `state-gate.sh` invoked against this repo's own root (or any
  scratch root built by the updated `setup_root()`) proceeds past the
  contract-presence check instead of refusing with "this repo has no
  collaboration contract yet."
- `product-cycle/hooks/run-gate-tests.sh` runs green end to end — the
  existing ownership (§11) and DEPENDS-ON (§4) test cases (e.g. the
  `(b)`, `(c)`, `(e2)`, `(k)` cases already in the file) pass under
  the now-present contract fixture, with no new failures introduced
  by the contract-presence requirement itself.
- `product-record` ownership allow/refuse behaves per contract §11:
  writes to product-owned paths are allowed, writes to paths §11
  assigns to another role are refused with the existing
  "path ownership conflict ... contract §11" message.

## What did not work

- The proposal's prescribed source, `git show
  v2-conformance:docs/specs/handoff-protocol.md` from
  coding-agent-rulebook, turned out to be coding's own role-section
  excerpt (sections 1-9 plus an unnumbered "Scope note"), not the
  full shared contract this repo's `state-gate.sh` cites. Its §4
  ("Read / Depends-on / Never-overwrite") lines up with the §4 cited
  in `state-gate.sh`'s comments, but the file has no §11 or §14 at
  all — those sections (owned-path write refusal, self-declared-kind
  caveats) are apparently only defined in product's own half of the
  contract, which does not exist as a standalone file in either repo
  under the exact name and content the proposal assumed. Checked
  `coding-agent-rulebook` for `docs/specs/role-handoff-contract.md`
  directly (proposal text implies that's the "real" contract name)
  and it does not exist there either — only `handoff-protocol.md`
  does, under a different name. Copied the file verbatim as directed
  anyway, since `require_contract()` in `state-gate.sh` only checks
  for the file's existence at `docs/specs/role-handoff-contract.md`,
  never its content, so the section-number mismatch does not affect
  gate behavior today — but the copied file is not actually a
  complete, self-consistent copy of "the contract" `state-gate.sh`'s
  comments describe, and finding the genuine §11/§14 source was a
  dead end within this proposal's scope (out of scope: any repo
  other than product-agent-rulebook, and any change to
  `state-gate.sh`).
- Wiring the scratch contract fixture into `run-gate-tests.sh`'s
  `setup_root()` (and the four hand-rolled roots g/h/j/k that bypass
  it) removed the contract-absence refusal as intended, but exposed
  a separate, pre-existing mismatch between the test harness and
  `state-gate.sh` that the contract-absence check had been masking:
  `state-gate.sh` resolves its project root by walking up from the
  hook script's own on-disk location to the nearest `.git`
  (state-gate.sh:84-97), deliberately ignoring `CLAUDE_PROJECT_DIR`
  and cwd (this is asserted intentional behavior, exercised by test
  case (l)). `run-gate-tests.sh` sets `CLAUDE_PROJECT_DIR` per scratch
  root under the assumption the gate reads state from that root, but
  it never does — the gate always reads this real checkout's own
  `product/state.md`, which does not exist here. Before this change,
  every test case that depended on scratch-root state content hit
  `require_contract()`'s deny first and never reached that mismatch.
  With the contract now present, cases (b), (c), (g), (h), (i), (j)
  fail for this unrelated, pre-existing reason instead. Fixing it
  would mean changing `state-gate.sh`'s root-resolution or its
  interaction with `CLAUDE_PROJECT_DIR`, which is explicitly out of
  scope for this proposal ("Changes to `state-gate.sh`'s enforcement
  logic — believed correct and unchanged by this work"). Left
  unresolved; flagging it here rather than silently declaring the
  test suite green.
