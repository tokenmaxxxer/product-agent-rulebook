# Proposal — deny-only-check.sh record-path fix (issue #51)

Phase 1 proposal only. No code changes in this PR. Full defect basis:
`docs/issue-51/reports/product-discovery/current-state.md`.

## Scope

`tests/deny-only-check.sh` only; `README.md:126-130` prose only. No gate
code, no `hooks.json`, no plugin manifest changes — issue #51 is scoped to
the probe script and its documentation, per the issue body's explicit
"이것만 해소하면" framing.

## 1. Fix `rec_rel` to the live record path

    rec_rel="docs/issue-999/reports/product-discovery.md"

Matches the `RECORD_RE`/`m_record` pattern all 3 record-owning gates
(`product-opportunity-solution-tree`, `product-hypothesis-testing`,
`product-guardrail-metrics`) already anchor on.

## 2. Decouple `probe_dir` from `$1`; always search repo-wide

    probe_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

Same repo-root resolution the outer `dir` default already uses, applied
unconditionally rather than only as a (broken) no-arg fallback. Rationale
(survey item 2): the record obligation is federated across 3 of the 5
plugins; a probe scoped to any single plugin's `hooks/` dir can never
exercise it for the 2 plugins with no record obligation, and README's
documented per-plugin call (`deny-only-check.sh product-one-pager/hooks`)
must still pass. Repo-wide `find` for `*-gate.sh` picks up all 5 gates
regardless of which `$1` was passed for the (unrelated)
permissionDecision-grep half of the script; `substance_probe` already
loops over every match and only needs one gate to refuse.

## 3. Replace README.md:126-130

Old (describes the no-op as intended):

    # ...and so on per plugin; deny-only-check.sh's substance probe targets
    # a generic docs/issue-<n>/reports/product.md path that no gate in this
    # repo claims (each plugin only fires on its own proposal/survey/record
    # scope), so that probe is a known no-op here, not a regression.

New (describes the actual, now-green behavior):

    # ...and so on per plugin; deny-only-check.sh's substance probe always
    # searches this repo's full tree for a *-gate.sh regardless of the
    # hooks-dir argument above, since the record obligation
    # (docs/issue-<n>/reports/product-discovery.md) is federated across
    # only 3 of the 5 plugins (product-opportunity-solution-tree,
    # product-hypothesis-testing, product-guardrail-metrics) — the other 2
    # explicitly carry no record obligation. The probe passes once any one
    # of the 3 refuses the empty record.

## Non-goals

- No change to any `methodology-gate.sh`'s record-handling logic — the 3
  record-owning gates already correctly deny an empty/status-less record;
  this is a probe-wiring fix, not a gate-behavior fix.
- No change to the permissionDecision-grep half of `deny-only-check.sh`
  (`dir`, `hits`) — confirmed correct against every plugin dir today,
  untouched by this proposal.
- No change to `tests/parse-check.sh` — its own default-path defect was
  already fixed under issue #48 (required-argument contract); out of
  scope here.

## Pre-registered hypothesis

Metric: `bash tests/deny-only-check.sh <hooks-dir>` exit code and
substance-probe log line, run once per each of the 5 `product-*/hooks`
dirs plus once with no argument, against a clean clone of this branch.
Threshold: exit 0 and an "ok — <gate-basename>: refuses the empty record"
line present in all 6 invocations (5 per-plugin + 1 no-arg).
Decision rule: go (execute and land as proposed) if the threshold is met
by direct, unreduced run at delivery; kill/revise this proposal's
specific fix (not the underlying requirement) if repo-wide `find` scoping
turns up an unrelated `*-gate.sh` outside the 5 known plugins that
produces a false refuse, or if decoupling `probe_dir` from `$1` is found
to defeat some other documented use of the per-plugin argument this
survey did not identify.
ITWWS: if a probe whose scope must match a federated (not per-file)
invariant is fixed by decoupling it from the single positional argument
meant for a narrower, unrelated check in the same script, we should
expect to re-examine any other repo-distributed test script for the same
"one argument, two differently-scoped checks" shape before it produces
the next silent no-op — pre-committed for the execution-phase record to
action or explicitly defer with a reason.

## Guardrails

Guardrail: the permissionDecision-grep half of `deny-only-check.sh`
(`hits`, exit-1-on-grant-of-allow) keeps its exact current pass/fail
behavior across all 5 plugin dirs — status stated explicitly at record
time, not implied.
Guardrail: `tests/run-gate-tests.sh`'s existing 5-suite pass count does
not regress (this proposal touches no gate code that suite exercises).

## Approval

Phase 1 stops here. Execution (landing items 1-3, running the 6
invocations above against a clean clone, recording the probe/refuse log
lines) begins only after an approvers.md account's Approve on this PR,
per contract v3 s19.
</content>
