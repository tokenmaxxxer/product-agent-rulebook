---
kind: coding-record
subject: issue-37
role: implementation
upstream: []
sha: HEAD
loop_state: landed
---

# Execution record — issue #37

Governing proposal:
`docs/issue-37/proposals/2026-07-31-core-canon-reference-migration.md`.

## Why

core landed a single canon for the role-agnostic gates and the directive
boilerplate (core issues #63/#66): `core/hooks/hooks.json` now fires
trailer/record-fields/handbook-trigger for every plugin install, and
`core/hooks/lib/role-directive.sh` factors out the directive
boilerplate every rulebook was repeating byte-for-byte. This rulebook's
own vendored copies were pure drift against that canon, and the issue
explicitly orders this migration ahead of the repo's "rulebook
maturation" phase-2 issue.

## What was done (per the issue's 5 items)

1. **warrant-hunter copy** — confirmed absent, as recorded in phase-1
   survey. No file to remove; verified again during phase 2 (`find
   product -iname 'warrant*'` returns nothing).
2. **Deleted the three vendored gates** — `product/hooks/trailer-gate.sh`,
   `product/hooks/record-fields-gate.sh`,
   `product/hooks/handbook-trigger-gate.sh` removed. Their matching
   `PreToolUse` entries removed from `product/hooks/hooks.json`, which
   now carries only the `SessionStart` → `directive.sh` entry.
3. **`directive.sh` rewritten as a stub** sourcing
   `core/hooks/lib/role-directive.sh`'s `core_role_directive`. The four
   positional args carry the prior five sections verbatim, regrouped
   per the proposal's mapping (`you_decide`, `use_when` =
   RESEARCH+CURRENT-STATE SURVEY, `produces` = PROPOSAL, `hand_off` =
   EXECUTION JUDGMENT+YOUR RECORD, including the loop_state-vocabulary
   note). No wording changed. Multi-line values use single-line
   `$'...\n...'` ANSI-C-quoted assignments so each variable is one
   physical source line, satisfying `stub-check.sh`'s structural cap
   (a naive multi-line `"..."` assignment would have put continuation
   lines outside the script's allowed line shapes and failed the
   check).
4. **`RECORD_FIELDS_TERMINAL_STATES` — open dependency, unresolved.**
   Core's canon `record-fields-gate.sh` reads this env var (default
   `landed`); this role's terminal states are `decided`/`scope-proposed`.
   Confirmed by reading core's gate directly
   (`RF_TERMINAL="${RECORD_FIELDS_TERMINAL_STATES:-landed}"`,
   `core/hooks/record-fields-gate.sh`) — the value must be present in
   the gate's actual process environment when core's `hooks.json` fires
   it, and that injection point (core's own hook-entry schema) is
   outside this repo's write surface. This repo cannot supply it
   without reintroducing vendored gate logic, which would defeat item 2
   and fail `stub-check.sh` again. Logged as an explicit unresolved
   upstream dependency per the proposal's constraint, not silently
   worked around.
5. **`stub-check.sh` run and passed.** Ran core's
   `core/hooks/tests/stub-check.sh product/hooks` (core repo checked
   out locally at `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core`, since
   this rulebook repo carries no local core checkout). Output:

   ```
   stub-check: ok — no vendored 'trailer-gate.sh' under product/hooks
   stub-check: ok — no vendored 'record-fields-gate.sh' under product/hooks
   stub-check: ok — no vendored 'handbook-trigger-gate.sh' under product/hooks
   stub-check: ok — no vendored 'parse-check.sh' under product/hooks
   stub-check: ok — product/hooks/directive.sh is a role-directive stub
   ```

   Exit code 0.

## Verification against the proposal's "how it'll know it worked"

- `find product/hooks -maxdepth 3 -name 'trailer-gate.sh' -o -name
  'record-fields-gate.sh' -o -name 'handbook-trigger-gate.sh'` → empty. Pass.
- `stub-check.sh product/hooks` → exit 0, all five `ok` lines present. Pass.
- `product/hooks/hooks.json` has only the `SessionStart` entry left. Pass.
- `bash -n product/hooks/directive.sh` → passes.
- A record on `decided`/`scope-proposed` still passing
  `record-fields-gate.sh` — **not independently verifiable from this
  repo**; the env injection (item 4) remains an open upstream
  dependency, logged above rather than silently assumed resolved.

## Smoke test

`directive.sh` was executed locally with `CLAUDE_ROLE=product` and
`CLAUDE_PLUGIN_ROOT_CORE` pointed at a local core checkout, to confirm
the sourced function produces the expected role-directive text
end-to-end (not just structural pass). Output matched the prior
directive's content, section-for-section, plus core's auto-appended
`RECORD:` line.

## Open findings

- Item 4 (`RECORD_FIELDS_TERMINAL_STATES` injection at core's
  `hooks.json` for this role's non-default terminal states) is
  unresolved and out of this repo's write surface — a follow-up on the
  core side, not a defect in this migration. This migration's own
  five-item scope is otherwise fully landed; no other open items.

## Files changed

`product/hooks/trailer-gate.sh` (deleted), `product/hooks/record-fields-gate.sh`
(deleted), `product/hooks/handbook-trigger-gate.sh` (deleted),
`product/hooks/hooks.json` (trimmed), `product/hooks/directive.sh` (rewritten
as stub), `docs/issue-37/reports/implementation.md` (this record).
