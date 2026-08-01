# Scout brief — issue #45

Mode: single-angle read (not a fan-out sweep). This deliverable is a
mandated reference-adoption ("core/hooks/lib/gate-lib.sh ... 참조 채택 —
자체 재구현 금지"), so the only exemplar that matters is fixed by the
issue itself: core's own gate-house standard (issue #72, landed). A
multi-angle competitive sweep across unrelated PreToolUse-gate designs
would produce alternatives explicitly forbidden by scope (self-
reimplementation). Stage count: 1 (direct read of the canon + its
handbook), well under the 5-stage/3min budget; stopped at judge point 1
because the standard is prescriptive, not a field to triangulate across.

## Must-bes (from the canon, Sources below)
- Fail-closed EXIT trap installed before `set -uo pipefail`
  (`gate_trap_fail_closed`).
- Kill switch: unrecognized value stays ACTIVE; only 1/true/yes/on
  (case-insensitive) disables (`gate_kill_switch_active`).
- Malformed/empty/non-object JSON payload denies, never guesses
  (`gate_parse_json_or_deny`).
- Path matching normalizes absolute/relative/`./`-prefixed input to one
  root-relative tail before pattern matching (`gate_normalize_path`).
- Write/Edit/MultiEdit/NotebookEdit reconstruction is one shared
  function; MultiEdit honors each edit's own `replace_all`
  independently; NotebookEdit returns edited cell source for
  insert/replace modes (`gate_reconstruct_write`).
- Deny is stderr-only, `gate_deny <name> <msg>` / `gate_allow`.
- Six-case test harness is mandatory, not optional: Edit+replace_all,
  MultiEdit mixed replace_all, malformed JSON (3 sub-shapes), kill
  switch on unrecognized value stays active, absolute-path + `./`-
  variant matching, Bash-tool write reaching the same target a
  Write-tool call would.
- A `compliance-check.sh [hooks-dir]` self-check exists in core and is
  meant to be invoked the same way `stub-check.sh` is — against a
  rulebook's own hooks directory — to catch exactly the two named live
  bugs (hand-rolled kill switch not calling `gate_kill_switch_active`;
  hand-rolled reconstruct not honoring `replace_all`) plus vendoring.

## Performance axes this canon competes on
1. Fail-closed-by-construction (trap-first) vs. fail-closed-by-diligence
   (hoping every code path calls `deny`).
2. One normalize/reconstruct/kill-switch shape shared across N gates vs.
   N independently hand-rolled, subtly divergent copies (issue-72's
   own finding: "same shapes, 2-3 different idioms each").
3. Self-verifying (compliance-check.sh) vs. relying on human review to
   catch drift.

## Adopt / skip
- Adopt: all five `gate_*` bash functions and all three `gate-lib.py`
  functions, sourced/imported per the usage comment at the top of each
  canon file — never copied (canon-manifest.txt + stub-check.sh in core
  catches vendoring, and the issue explicitly forbids reimplementation).
- Adopt: the six-case test shape, extended per-plugin with each gate's
  own facet-check cases (semantic section/adjacency tests are this
  repo's own addition — gate-lib has no opinion on facet-check
  internals, only on the JSON/path/kill-switch/reconstruct machinery
  around it).
- Skip (for now, note in proposal as open question): switching the 5
  gates' deny output from JSON `hookSpecificOutput` body to
  `gate_deny`'s plain-stderr shape — canon's own `gate_deny` writes
  stderr-only; this repo's 5 gates instead write a JSON
  `permissionDecisionReason` body to stdout with exit 2. Both are valid
  Claude Code PreToolUse hook protocols; picking is a proposal-level
  compatibility decision, not something the sweep can resolve — canon
  does not mandate which stdout/stderr shape a caller must keep once it
  adopts `gate_deny`'s *message construction*, but a straight swap to
  `gate_deny` would drop the structured JSON body entirely. Flagged so
  the proposal makes this call explicitly instead of by accident.

## Segment fit
This repo (5 downstream methodology gates) is exactly the audience
gate-house-standard.md's "per-repo migration checklist" section targets
— it is not a stretch fit; it is the named use case.

## Gap line (current state vs. the must-bes above)
Already meets: malformed-JSON handling exists per-gate today (informally,
not via `gate_parse_json_or_deny`); path resolution already computes a
root-relative form (informally, not via `gate_normalize_path`); Edit/
MultiEdit reconstruction already honors `replace_all` (informally, not
via `gate_reconstruct_write`).
Missing: fail-closed EXIT trap (none of the 5 gates install one; they
rely on `trap ... ERR` + explicit `deny` calls, which does not catch a
bare `exit 1`/`set -u` unbound-variable abort the way `gate_trap_fail_
closed`'s EXIT trap does); kill-switch on-spelling normalization (§1 of
the survey); stderr-escaped deny JSON (§4 of the survey); NotebookEdit
and Bash-tool-write coverage (neither exists in any of the 5 gates);
section/adjacency-aware semantic checks (§3 of the survey — canon has no
opinion here, this repo must design its own upgrade); the six-case test
harness (none of the 5 `tests/product-*-gate-tests.sh` currently cover
all six cases — to be confirmed per-file in the proposal); a
`compliance-check.sh` self-check wired into this repo's own test suite.

## Sources
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/docs/handbooks/gate-house-standard.md
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/lib/gate-lib.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/lib/gate-lib.py
</content>
