# Record - issue #51: A+ closeout (deny-only-check.sh record-path fix)

kind: execution-judgment
loop_state: decided

## OST branch

outcome: trust that the deployment safety net (gate) actually exercises what it claims to verify

opportunity: tests/deny-only-check.sh's substance probe targeted a retired path (docs/issue-999/reports/product.md), so it never once exercised any of the 3 record-owning gates (product-opportunity-solution-tree, product-hypothesis-testing, product-guardrail-metrics)

candidate solution: fix rec_rel to docs/issue-999/reports/product-discovery.md, decouple probe_dir from $1 so it always searches the repo root - executed exactly as proposed

discriminating assumption test: does a clean-clone run of all 6 invocations (5 plugins + no-arg) exit 0 with an "ok - refuses the empty record" log line

## Disposition

The candidate solution above is promoted (OST tree: adopted, opportunity closed). Verdict: go, not kill, not pivot.

## What was done

Executed the approved proposal (docs/issue-51/proposals/2026-08-01-deny-only-check-record-path-fix.md) verbatim, no scope expansion. Upstream basis: issue #51's body and the phase-1 current-state survey at docs/issue-51/reports/product-discovery/current-state.md, approved via the issue comment "APPROVE issue-51/product-discovery" (single-account mode, contract v3 s19).

1. tests/deny-only-check.sh
   - rec_rel: docs/issue-999/reports/product.md -> docs/issue-999/reports/product-discovery.md
   - probe_dir: was ${1:-.../product/hooks} (nonexistent path, depended on $1) -> now $(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P) (repo root, independent of $1)
2. README.md:126-130 - replaced the "known no-op" description with the actual behavior (repo-wide search, passes once any of the 3 plugins refuses).

Why: the probe was a silent no-op against all 3 record-owning gates since none of them lived under the (nonexistent) default probe_dir and the target record path was already retired - this fix makes the probe actually exercise the gates it claims to guard.

## Pre-registered hypothesis - mechanical verdict

Metric: exit code and substance-probe log line of `bash tests/deny-only-check.sh <hooks-dir>`, run once per each of 5 product-*/hooks dirs plus once with no argument, against a clean clone.
Threshold: exit 0 and an "ok - refuses the empty record" line present in all 6 invocations.

Measured 2026-08-01 in clean clone /tmp/claude-1000/pdclone (HEAD tree plus the 2 changes above applied):
- product-one-pager/hooks: exit 0, "ok - methodology-gate.sh refuses the empty record"
- product-opportunity-solution-tree/hooks: exit 0, "ok - methodology-gate.sh refuses the empty record"
- product-assumption-mapping/hooks: exit 0, "ok - methodology-gate.sh refuses the empty record"
- product-hypothesis-testing/hooks: exit 0, "ok - methodology-gate.sh refuses the empty record"
- product-guardrail-metrics/hooks: exit 0, "ok - methodology-gate.sh refuses the empty record"
- no-arg: exit 0, "ok - methodology-gate.sh refuses the empty record"

Verdict: threshold met 6/6. Go - executed as proposed. Kill/revise triggers (repo-wide scoping producing a false refuse outside the 5 known plugins, or probe_dir decoupling breaking another documented $1 use) did not occur.

## Guardrail status (same measurement moment)

Guardrail 1 - permissionDecision-grep half's pass/fail behavior: unchanged. Every one of the 6 invocations above still printed "deny-only-check: ok - no permissionDecision allow under <dir>", no regression.
Guardrail 2 - tests/run-gate-tests.sh existing suite pass count: unchanged. Clean-clone run produced "28 passed, 0 failed" and "26 passed, 0 failed" across the plugin suites, plus all 5 plugin compliance-check.sh runs ok, ending in "run-gate-tests: all 5 plugin suites + compliance-check.sh passed".

Neither guardrail breached - approved result, no reduced-trust flag.

## ITWWS follow-up

Pre-registered in the proposal: re-examine other repo-distributed test scripts for the same "one argument, two differently-scoped checks" shape.

Explicitly deferred. Reason: issue #51's scope is explicitly limited to tests/deny-only-check.sh and README.md:126-130 ("이것만 해소하면"); a sweep of other scripts (tests/parse-check.sh, tests/run-gate-tests.sh, etc.) for the same pattern needs its own issue, out of scope for this execution.

## Open findings

None outstanding. All blockers named in the issue body (record-path alignment, default hooks-path fix, README description alignment) confirmed resolved by the measurements above; no new defect surfaced during execution.

## Next steps

None required for issue #51 - all named blockers are resolved and verified above. The deferred ITWWS sweep of other repo-distributed test scripts for the same argument-scoping shape is the only follow-up, and it is explicitly out of scope here (see ITWWS follow-up); it should be filed as a separate issue if pursued.

## Open-finding resolution path

There are no open findings from this execution (see Open findings above); no resolution path is needed. If the deferred ITWWS sweep is later picked up, its resolution path is: file a new issue, run the same current-state-survey-first process this issue followed, and land any fix through its own phase-1/phase-2 PR.
