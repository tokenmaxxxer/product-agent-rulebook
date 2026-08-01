# Current-state survey — issue #48 (gate A+ final closeout, re-audit B+)

Job performer: this repo's 5 `product-*` gate maintainer, whose job is
"land the confirmed core-canon guard shape and wire what the 2026-08-01
re-audit found shipped-but-inert, so the next audit has nothing residual
left to grade down from A+."
Circumstance: a 2026-08-01 re-audit graded this repo B+ after issue #45's
remediation landed, naming four concrete residual defect classes still
present, with the two blocking core/on-the-record prerequisites (core
#75, on-the-record #182) now landed and pullable for their confirmed
guard shape.
Desired outcome: every re-audit item is fixed against core #75's actual
landed shape (not re-derived), `hooks.json` matcher parity with shipped
gate code, and README/manifest carry zero old-role/phantom-file residue
— confirmed by direct read of both this tree and the two upstream repos,
not by trusting the issue body's or the prior record's claims.

Scout: skipped — pure defect-remediation against an already-confirmed
external audit and two already-landed upstream fixes; no product-facing
design decision is open (which guard shape to adopt, what the JTBD/OST
facets require) that scouting best-in-class products could inform. Same
skip basis as issue #45's own remediation pass.

Subject: `product-*/hooks/methodology-gate.sh` (5), `product-*/hooks/
hooks.json` (5), `tests/parse-check.sh`, `README.md`, `*/.claude-plugin/
plugin.json` (5).

## OST placement

Opportunity: close the last confirmed-defect gap between this repo's
gates and the gate-house standard's fail-closed contract, now that the
standard's own reference shape is landed upstream.
Outcome: gate reliability graded A+ with no confirmed residual defect
class open.
Candidate solutions: apply core #75's exact landed diff shape (`||`-
guarded source line) to all 5 gates; add the two missing `PreToolUse`
matchers; replace the bare `진행|중단|피벗`/`actioned|진행함` substring
checks with the same section/adjacency discipline issue #45 already
applied to the JTBD/OST facet checks; fix `parse-check.sh`'s dead default
path.
Discriminating assumption test: `tests/run-gate-lib-tests.sh`-style
missing-core case (`CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent
path) added to each of the 5 plugins' own gate-tests suites must DENY,
not silently ALLOW — the same regression shape core #75 registered
upstream.

## 1. `gate-lib.sh` source line ships without the `||` fail-closed guard (confirmed, 5 of 5)

Every `product-*/hooks/methodology-gate.sh:2` reads:

    . "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"

with no `||` fallback. This is the exact defect core #75 confirmed and
fixed upstream (`tokenmaxxxer-core` commit `f61d52f`): a failed `source`
runs no code, so `gate_kill_switch_active` is left undefined; every
gate's own `gate_kill_switch_active ... || { trap - EXIT; exit 0; }` then
reads that call's exit 127 ("command not found") as "kill switch off,"
silently ALLOWing everything on a missing/misconfigured
`CLAUDE_PLUGIN_ROOT_CORE` instead of denying. Core's own landed fix
(now in `core/hooks/*.sh`, all 7 gates):

    . "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh" || { echo "<gate>: cannot source gate-lib.sh" >&2; exit 2; }

and `core/hooks/tests/compliance-check.sh` now has a detector for the
unguarded pattern (`grep -q 'gate-lib\.sh"$' ... && ! grep -qE 'gate-lib\.sh"[[:space:]]*\|\|'`)
plus a "missing-core" mandatory case group in
`core/hooks/tests/run-gate-lib-tests.sh`. None of this repo's 5 gates
carry the guard, and none of the 5 `tests/product-*-gate-tests.sh` suites
exercise a missing-core case — `compliance-check.sh` run against this
tree today would flag all 5 (not independently re-verified in this
survey pass; the pattern match above is read directly from each gate's
own line 2).

## 2. `hooks.json` matcher does not cover the tool events the gate code handles (confirmed, 5 of 5)

Every `product-*/hooks/hooks.json` `PreToolUse` matcher is
`"Write|Edit|MultiEdit"`. Every `methodology-gate.sh` contains live,
tested Bash-tool write-target-coverage code (`gate_bash_write_targets`,
denying a shell-redirect into the gate's own scope) — all 5 gates. 3 of
5 (`product-one-pager`, `product-opportunity-solution-tree`,
`product-hypothesis-testing`) additionally contain `NotebookEdit`
handling. README.md's own "Each `methodology-gate.sh` is a PreToolUse
gate (Write/Edit/MultiEdit/NotebookEdit/Bash)" line documents this as
already-covered. `tests/product-*-gate-tests.sh` invoke the gate script
directly with a synthetic `Bash`/`NotebookEdit` payload and assert deny
— those tests pass today because they call the script directly,
bypassing `hooks.json` entirely, which is exactly why the matcher gap
went unnoticed: shipped, tested, never wired into the actual PreToolUse
dispatch. A real Bash-tool shell-redirect into a gate's own scope, or a
real NotebookEdit write to it, reaches neither gate today.

## 3. `진행`/`actioned|진행함` bare substring in the decision-rule check (confirmed, product-hypothesis-testing)

`product-hypothesis-testing/hooks/methodology-gate.sh:187`:

    if re.search(r'진행|중단|피벗', t):
        return True

matched anywhere in the reconstructed text, no section anchor, no
adjacency to a threshold/metric — the same substring-anywhere shape
issue #45 already fixed for the JTBD/OST/evidence facet checks, left
unfixed on this one `has_decision_rule` fallback branch. "진행" (the
literal issue-body wording: `'ongoing'→go/'진행'` residue) appears in
ordinary Korean prose that is not a decision rule at all — "다음 스프린트
에도 진행 예정" (planned to continue), "아직 미진행" (not yet started,
containing "진행" as a substring) — both would satisfy this bare
`.search()` and incorrectly count as "decision rule present," masking a
proposal that never actually states a go/kill/pivot rule. Line 244's
`actioned = re.search(r'actioned|진행함', text, re.IGNORECASE)` has the
same shape but lower stakes (`actioned` OR `deferred`-with-reason is
already a two-way fallback; a `진행함` false-positive on the actioned arm
still requires *not* independently satisfying the deferred-with-reason
arm to matter) — same fix class either way.

## 4. `tests/parse-check.sh` default hooks-dir does not exist in this tree (confirmed)

`tests/parse-check.sh:35`:

    dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../product/hooks" 2>/dev/null && pwd -P)}"

Default (no-arg) path resolves to `<repo>/product/hooks` — this repo has
no `product/` directory, only 5 `product-*/` plugin directories (the
same "ghost `product` role" shape issue #45's survey §6 confirmed and
fixed in README, left unfixed here). `cd` against a nonexistent path
fails, `dir` becomes empty, and line 36's `[ -d "$dir" ]` check catches
it — the script does not silently pass, it errors clearly
(`parse-check: no such directory: `). Not a live false-ALLOW, but a dead/
wrong default: README's own "Run the checks" section (confirmed clean,
§6 below) always passes an explicit per-plugin path, so this default is
never exercised in documented use — a phantom fallback that would
mislead a first no-arg run (`bash tests/parse-check.sh` with no
argument) into a confusing directory-not-found rather than checking
something real.

## 5. `matcher-code` parity gap summary

Cross-referencing `hooks.json` matchers against each gate's own
`tool_name` handling (item 2) is the full matcher/code parity picture —
no additional undocumented tool-name branch exists in any of the 5
gates beyond `Write`/`Edit`/`MultiEdit`/`Bash`/`NotebookEdit` (confirmed
by reading each gate's `tool not in (...)` / `tool_name = "..."`
branches in full).

## 6. README / manifest ghost-reference check (re-verified, clean)

`grep` for issue #45's fixed ghost strings (`product-agent-rulebook`,
`PRODUCT_CYCLE_OFF`, `record-fields-gate.sh`, `trailer-gate.sh`,
`handbook-trigger-gate.sh`) against `README.md` and all 5 `.claude-
plugin/plugin.json` files: zero hits. Each plugin's `plugin.json`
`description` and each `skills/` subdirectory name (`one-pager`,
`opportunity-solution-tree`, `assumption-mapping`, `hypothesis-testing`,
`guardrail-metrics`) match README's "Ships skills: ..." claims exactly —
no phantom skill directory, no stale name. README's documented gate
event coverage (Write/Edit/MultiEdit/NotebookEdit/Bash) is itself
correct against the code (item 2's gap is in `hooks.json`, not in
README) — so the wiring fix in item 2 is what brings the matcher in line
with README's already-accurate documentation, not the reverse. This
requirement is otherwise already satisfied; the proposal item for it is
"confirm zero, no edit needed," not a rewrite.

## Gaps this survey leaves open (for the proposal to resolve)

- Exact wording of the corrected decision-rule/ITWWS section-anchored
  regex for `product-hypothesis-testing` (item 3) — proposal picks the
  concrete pattern, following issue #45's own JTBD-check precedent.
- Whether `tests/parse-check.sh`'s default should point at a real
  aggregate path (e.g. iterate all 5 `product-*/hooks`) or simply be
  removed in favor of requiring an explicit argument — proposal decides.
</content>
