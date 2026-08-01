# Current-state survey — issue #45 (gate A+ remediation)

JTBD framing for this maintenance subject: the job performer is the
`product-discovery` role's own PreToolUse gate maintainer, whose job is
"catch a methodology violation reliably instead of on a substring
coincidence," in the circumstance of a 2026-08-01 external code audit
that graded this repo's gates B- for four concrete defect classes
(keyword-substring semantics, dead code, unescaped deny JSON, a broken
root test runner) plus a landed core canon (issue #72) that already
fixes the same defect classes repo-wide; desired outcome: every fact
below is independently confirmed against the current tree, so the
proposal that follows can commit to real changes instead of the audit's
own claims.

Subject: this repo's 5 `product-*/hooks/methodology-gate.sh` gates +
`tests/run-gate-tests.sh` + `README.md`. Confirmed by direct read, not by
trusting the issue body's claims.

## 1. Kill-switch fail-open (confirmed, 1 of 5 gates)

`product-opportunity-solution-tree/hooks/methodology-gate.sh:30-33`:

    case "${PRODUCT_OPPORTUNITY_SOLUTION_TREE_GATE_OFF:-}" in
      ""|0|false|no|off) ;;
      *) exit 0 ;;
    esac

Any unrecognized value (a typo, garbage) hits `*) exit 0` — disables the
gate. This is the exact bug class `gate-house-standard.md` §"two bugs"
names and `gate_kill_switch_active` fixes (unrecognized = stay active).

The other 4 gates use `[ "$VAR" = "1" ]` (exact-match-only, e.g.
`product-one-pager/hooks/methodology-gate.sh:14`) — not fail-open on
garbage, but also not the fixed on-spelling set
(1/true/yes/on, case-insensitive) the standard defines. All 5 need
migration to `gate_kill_switch_active` for one consistent contract.

## 2. Dead ternary code (confirmed)

`product-one-pager/hooks/methodology-gate.sh:258`:

    m = pat.search(lower if pat.flags & re.MULTILINE == 0 and False else text.lower())

`and False` makes the ternary's true-branch unreachable; it always
evaluates `text.lower()`. Harmless by accident here (both branches
produce the same value with this pattern set) but is inert code masking
the author's actual intent (case-fold non-MULTILINE patterns only).

## 3. Keyword-substring semantic check (confirmed, structural gap)

Same file, lines 213-245: the JTBD-tuple check is bare keyword presence
— `circumstance_re = re.compile(r"circumstance")`, `outcome_re =
re.compile(r"desired outcome|outcome")` — matched anywhere in the
document via `.search()`, no section anchor, no adjacency requirement.
"go to the docs" was the issue's claim; concretely, this checker cannot
tell "circumstance: pricing pressure" (a real JTBD tuple) from "for
context, see docs/handbooks/circumstance-notes.md" and "the desired
outcome of that meeting" (both false-positive keyword hits with zero
JTBD content). All 5 gates use the same "presence of marker words
anywhere in the reconstructed text" pattern for their respective facet
checks — this is a repo-wide shape, not a one-file bug.

## 4. Deny-JSON escaping (confirmed)

`product-one-pager/hooks/methodology-gate.sh:8-11`:

    deny() {
      printf '{"hookSpecificOutput":{"permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
      exit 2
    }

`$1` is interpolated into the JSON string unescaped. A reason text
containing `"` or `\` (e.g. quoting the user's own JTBD text back, or a
Python traceback fragment) breaks the JSON. Note `product-guardrail-
metrics/hooks/methodology-gate.sh:13-17` already escapes correctly via
`json.dumps`; the other 4 gates (`product-one-pager`,
`product-opportunity-solution-tree`, `product-assumption-mapping`,
`product-hypothesis-testing`) use the unescaped `printf '%s'` shape and
need the same fix.

## 5. Root test runner references deleted scripts (confirmed)

`tests/run-gate-tests.sh:4-5`:

    HOOKS="$HERE/../product/hooks"
    ...
    run allow record-complete record-fields-gate.sh "$REC" "$GOOD"

References `../product/hooks/record-fields-gate.sh`, `trailer-gate.sh` —
files that do not exist anywhere in this repo (no
`record-fields-gate.sh` or `trailer-gate.sh` under any `hooks/` dir; the
only hook files present are the 5 `product-*/hooks/methodology-gate.sh`).
Running `run-gate-tests.sh` fails immediately (`No such file or
directory` per `run` invocation), so its pass/fail tally never reflects
the 5 real gates — the actual per-plugin suites
(`tests/product-*-gate-tests.sh`) are the live tests, and are not wired
into `run-gate-tests.sh` at all.

## 6. README ghost content (confirmed)

`README.md` describes a `product` role/plugin
(`product-agent-rulebook`, `product@tokenmaxxxer-product`,
`PRODUCT_CYCLE_OFF`, `product/hooks/record-fields-gate.sh`,
`product/hooks/trailer-gate.sh`,
`product/hooks/handbook-trigger-gate.sh`) that does not exist in this
tree. The real repo is `product-discovery-rulebook`, role
`product-discovery`, 5 separate `product-*` plugins each with their own
`methodology-gate.sh`, kill switches per plugin (§1), record at
`docs/issue-<n>/reports/product-discovery.md`. None of README's
documented commands (`tests/deny-only-check.sh` — also absent) resolve
against this tree.

## 7. What core's gate-house standard (issue #72, landed) supplies

Read directly from `tokenmaxxxer/tokenmaxxxer-core@main`:
`core/hooks/lib/gate-lib.sh` (bash: `gate_trap_fail_closed`,
`gate_kill_switch_active`, `gate_deny`/`gate_allow`,
`gate_bash_write_targets`) and `core/hooks/lib/gate-lib.py` (Python:
`gate_parse_json_or_deny`, `gate_normalize_path`,
`gate_reconstruct_write`) — see scout-brief.md for the full mapping of
each function to the defect class it fixes. `docs/handbooks/gate-house-
standard.md` also names a mandatory 6-case test harness shape and a
`compliance-check.sh` detector; both inform the proposal's test-adoption
plan.

## Gaps this survey leaves open (for the proposal to resolve)

- None of the 5 gates honor `replace_all` incorrectly in the way
  `record-fields-gate.sh` did in core's own pre-issue-72 canon (each
  gate's own `apply_edit`/heredoc DOES read `replace_all` today) — the
  risk here is drift from the canon shape over time, not a confirmed
  live bug in this exact copy.
- No `NotebookEdit` handling exists in any of the 5 gates.
- No `Bash`-tool write-target coverage exists in any of the 5 gates.
- No `compliance-check.sh`-style self-check is wired into this repo.
</content>
