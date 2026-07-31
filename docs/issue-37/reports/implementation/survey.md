---
kind: survey
subject: issue-37
role: implementation
---

# Current-state survey — issue #37

## Scouting

Skipped. This is an internal infra migration onto an already-fixed core
canon target (core issues #63/#66, `core/hooks/tests/stub-check.sh`'s
structural check) — there is no external product/exemplar space to
compare against, and the one open mapping decision (directive.sh's
5-section content into `core_role_directive`'s 4-arg shape) is resolved
directly against the already-inspected core contract, not by scouting.
Skip condition: spec (core canon + stub-check.sh) leaves no
category-level design decision open.

## Background

core has landed two canon promotions:
- core issue #63: `warrant/` hunt plugin (size-proportional budget +
  miss-streak + instrumentation) as core canon.
- core issue #66: the three role-agnostic gates (trailer/record-fields/
  handbook-trigger) now fire from `core/hooks/hooks.json` with matcher
  `.*` for every plugin install, plus a shared `core_role_directive`
  function in `core/hooks/lib/role-directive.sh` that every rulebook's
  own `directive.sh` is meant to source and call.
- `core/hooks/tests/stub-check.sh` (issue-66 item 4) is the drift
  detector: it fails if a rulebook still vendors its own copy of any of
  the three gates (or `parse-check.sh`), and it structurally checks that
  a rulebook's `directive.sh` is nothing but the source line + variable
  assignments + one `core_role_directive` call.

Verified against the installed core plugin
(`.../marketplaces/tokenmaxxxer/runs/rulebooks/tokenmaxxxer-core/core`):
`hooks/hooks.json` registers `board-gate.sh`, `approval-gate.sh`,
`gh-guard.sh`, `trailer-gate.sh`, `record-fields-gate.sh`,
`handbook-trigger-gate.sh` on `PreToolUse` matcher `.*` — i.e. core issue
#66 is landed and already fires these gates for this repo without any
help from `product/hooks/`.

## Per-item findings, against this repo (`product/hooks/`)

**1. warrant-hunter copy** — not present. No `agents/warrant-hunter.md`
or hunt-cadence text exists anywhere in this repo (`grep -rli warrant`
only hits doc prose using "warrant" as a metaphor for a unit of work,
`docs/README.md:11`). Nothing to remove for this item; it is N/A here,
not a gap.

**2. Gate copies** — present and now pure drift:
`product/hooks/trailer-gate.sh` (177 lines), `record-fields-gate.sh`
(251 lines), `handbook-trigger-gate.sh` (170 lines), all registered a
second time in `product/hooks/hooks.json`'s `PreToolUse` block. Content
is the pre-promotion per-role boilerplate (`PRODUCT_CYCLE_OFF` kill
switch, `product-cycle:` messages) — `stub-check.sh` will FAIL on this
tree today because all three filenames exist under `product/hooks/`.

**3. directive.sh** — 70 lines, five sections (YOU DECIDE, RESEARCH,
CURRENT-STATE SURVEY, PROPOSAL, EXECUTION JUDGMENT, YOUR RECORD) plus
its own trap/kill-switch/`CLAUDE_ROLE` guard preamble — exactly the
per-copy boilerplate `role-directive.sh`'s header says issue-66 found
byte-for-byte-identical across 43 copies. `core_role_directive` takes
exactly four positional strings (`you_decide use_when produces
hand_off`) and appends one generic closing line: `RECORD:
docs/issue-<n>/reports/<role>.md, phase-gated per contract v3 s19`.
This repo's `YOUR RECORD` section carries role-specific enforcement text
beyond that generic line (the `kind`/`loop_state` field requirement, and
the strengthened wording landed by issue #33: "Ending phase 2 without
your record committed on the branch means the record was never
written. (Measured: a phase-1-only issue left the record empty.)"). That
text is role-unique, not boilerplate, so it must survive inside one of
the four arguments — it cannot rely on the generic auto-appended line,
which says less.

**4. RECORD_FIELDS_TERMINAL_STATES** — confirmed divergence.
`product/hooks/record-fields-gate.sh:230` hardcodes `TERMINAL =
{"decided", "scope-proposed"}` (this role's own two closing
`loop_state`s). Core's canon `record-fields-gate.sh:86` defaults
`RF_TERMINAL="${RECORD_FIELDS_TERMINAL_STATES:-landed}"` — i.e. `landed`
only, unless the env var overrides it. Once the vendored gate is
deleted and core's canon gate takes over (item 2), this role's two
non-`landed` terminal states will silently stop being recognized as
terminal (record-fields-gate would demand an open-work backlog on an
already-`decided`/`scope-proposed` record) unless
`RECORD_FIELDS_TERMINAL_STATES="decided scope-proposed"` is exported
before the hook fires.

**5. stub-check.sh** — not yet run against this tree (that run belongs
in the phase-2 record per the issue's own item 5, after the actual
edits land).

## Where this sits

Ordering constraint from the issue: this migration must land before
this repo's "rulebook maturation" phase-2 issue. No such issue exists
yet on this repo's board (open issues checked: only #37).
