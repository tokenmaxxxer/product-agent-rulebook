---
kind: proposal
subject: issue-37
role: implementation
---

# Build proposal — issue #37

files: `product/hooks/trailer-gate.sh`, `product/hooks/record-fields-gate.sh`,
`product/hooks/handbook-trigger-gate.sh`, `product/hooks/directive.sh`,
`product/hooks/hooks.json`

Full findings backing this proposal: `docs/issue-37/reports/implementation/survey.md`.

## Request (paraphrased intent)

core has landed a single canon for the role-agnostic gates and the
directive boilerplate (core issues #63/#66). This rulebook's
`product/hooks/` still carries its own copies, now pure drift. Convert
to core-canon references, removing the copies, while keeping every bit
of content that is genuinely this role's own (the RESEARCH/PROPOSAL/
EXECUTION-JUDGMENT substance in `directive.sh`, and the two non-`landed`
terminal `loop_state`s this role uses). Phase 1 only — this proposal,
no code change, no APPROVE.

## What will be done (per the issue's 5 items)

**1. warrant-hunter copy** — no-op. Confirmed absent from this repo
(survey §"1"). Nothing to remove; recorded as verified-absent in the
phase-2 record rather than silently skipped.

**2. Delete the three vendored gates + their `hooks.json` entries.**
Remove `product/hooks/trailer-gate.sh`, `record-fields-gate.sh`,
`handbook-trigger-gate.sh` outright — core's own `hooks.json`
(matcher `.*`) already fires the canon versions for every plugin
install, confirmed against the installed core plugin. Remove the
matching three `PreToolUse` hook entries from `product/hooks/hooks.json`,
leaving only the `SessionStart` → `directive.sh` entry.

**3. Rewrite `directive.sh` as a stub sourcing `core_role_directive`.**
Target shape, matching `role-directive.sh`'s documented usage and
`stub-check.sh`'s structural check (source line + assignments + one
call, nothing else):

```sh
#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

you_decide="YOU DECIDE: ..."
use_when="RESEARCH (phase 1, ...): ...

CURRENT-STATE SURVEY (phase 1, ...): ..."
produces="PROPOSAL (phase 1, ...): ..."
hand_off="EXECUTION JUDGMENT (phase 2, ...): ...

YOUR RECORD (do not skip this): ...
loop_state vocabulary this role uses (not core's generic list):
decided, scope-proposed as this role's terminal states — see
RECORD_FIELDS_TERMINAL_STATES below."

core_role_directive "$you_decide" "$use_when" "$produces" "$hand_off"
```

Mapping from the current five sections into the four positional
arguments (content carried verbatim, only regrouped):
- `you_decide` ← current `YOU DECIDE` paragraph, unchanged.
- `use_when` ← current `RESEARCH` + `CURRENT-STATE SURVEY` sections,
  concatenated.
- `produces` ← current `PROPOSAL` section, unchanged.
- `hand_off` ← current `EXECUTION JUDGMENT` + `YOUR RECORD` sections,
  concatenated verbatim, including the issue-33 enforcement clause and
  the `(Measured: ...)` citation — this is role-unique content richer
  than `core_role_directive`'s generic auto-appended `RECORD:` line, so
  it is kept explicit here rather than dropped in favor of that line.
  The auto-appended line still prints afterward; it is redundant with,
  not a replacement for, this text.

No wording inside the four blocks changes — this is a restructuring
into the stub's required shape, not a content edit. (If the human
approver would rather trim any section during phase 2 execution, that's
a phase-2 call; this proposal's scope is the mechanical migration only.)

**4. Preserve the terminal-`loop_state` divergence via
`RECORD_FIELDS_TERMINAL_STATES`.** Core's canon `record-fields-gate.sh`
reads this env var (default `landed`); this role's vendored copy
hardcoded `{"decided", "scope-proposed"}`. Once item 2 deletes the
vendored copy, this role needs `RECORD_FIELDS_TERMINAL_STATES="decided
scope-proposed"` exported wherever core's gate actually runs as a
subprocess — i.e. as an `env` entry on the relevant hook registration
(core's `hooks.json`, not this repo's, since this repo no longer
registers the gate itself). This repo's own concern is limited to
naming the required value; **the exact injection point is core's
hooks.json schema, outside this repo's write surface** — flagged here
as an open dependency, not something this proposal's file list can
satisfy. If core's hook-entry schema has no `env` field today, that is
upstream scope (a follow-up on the core side), not something to invent
per-rulebook here.

**5. Record `stub-check.sh` pass in phase 2.** Not run yet (no code
changed). Phase-2 record must run
`core/hooks/tests/stub-check.sh product/hooks` after items 2–3 land and
quote its output.

## Constraints

- Only the five files listed above are in scope.
- No wording changes inside the four directive blocks beyond
  regrouping into the stub's argument shape (item 3).
- Item 4's actual fix (the env injection) is bounded by what core's
  hooks.json schema supports; this repo cannot silently invent a
  workaround that reintroduces vendored gate logic (that would defeat
  item 2 and fail `stub-check.sh` again).
- No APPROVE, no code edit, in this phase.

## Out of scope

- Any `docs/specs/` or skill file under `product/skills/`.
- Any change to core itself.
- The "rulebook maturation" phase-2 issue this migration is ordered
  ahead of.

## How it'll know it worked (phase 2)

- `find product/hooks -maxdepth 3 -name 'trailer-gate.sh' -o -name
  'record-fields-gate.sh' -o -name 'handbook-trigger-gate.sh'` returns
  nothing.
- `core/hooks/tests/stub-check.sh product/hooks` exits 0 and reports
  `directive.sh is a role-directive stub` plus `ok — no vendored ...`
  for all three gate names.
- `product/hooks/hooks.json` has only the `SessionStart` entry left.
- `bash -n product/hooks/directive.sh` passes.
- A record on `decided`/`scope-proposed` still passes
  `record-fields-gate.sh` with `RECORD_FIELDS_TERMINAL_STATES` set (or
  the open dependency from item 4 is explicitly logged as unresolved).
