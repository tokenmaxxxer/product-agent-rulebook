# Current-state survey — issue #51 (A+ 인증 마감: 감사 차단 사유 해소)

Job performer: this repo's `tests/deny-only-check.sh` maintainer, whose job
is "keep the substance-probe half of this repo-wide gate check actually
exercising a real gate, not a path that has never existed in this tree."
Circumstance: the 2026-08-01 audit named `tests/deny-only-check.sh`'s probe
path (`docs/issue-999/reports/product.md`) as targeting the retired
`product.md` record name instead of the current `product-discovery.md`
record path, the probe's default hooks-dir as wrong, and README.md:127-130
as describing the resulting no-op as expected/documented rather than
flagging it as the defect it is.
Desired outcome: `deny-only-check.sh`'s substance probe actually invokes a
gate that owns the record path and gets refused (exit 2) on an empty
record, under the documented, no-argument call shape; README's own prose
matches that green result, not the old no-op explanation — confirmed by
running the probe, not by trusting the issue body's characterization.

Scout: skipped — pure defect-remediation against an already-confirmed
audit finding (a single stale path string plus one stale README comment);
no product-facing design decision is open that scouting best-in-class
products could inform. Same skip basis as issue #45's and #48's own
remediation passes.

Subject: `tests/deny-only-check.sh`, `README.md:126-130`.

## OST placement

Opportunity: close the last confirmed-defect gap between this repo's A+
gate audit and a fully green, documented check suite.
Outcome: gate reliability graded A+ with no confirmed residual defect
class open (issue #51 is this repo's 3rd consecutive closeout pass after
issue #45 and issue #48).
Candidate solutions: (a) fix `rec_rel` to the live record path and repoint
`probe_dir`'s default so the probe actually finds a record-owning gate;
(b) leave the probe path alone and instead relax README's claim further.
Discriminating assumption test: running `tests/deny-only-check.sh` with
the README's documented no-argument / per-plugin-argument invocation must
print "ok — <gate>: refuses the empty record" and exit 0, not "FAIL — no
gate refuses."

## 1. `rec_rel` targets a retired record filename (confirmed)

`tests/deny-only-check.sh:47`:

    rec_rel="docs/issue-999/reports/product.md"

The live record path, defined by contract v3 s19 and matched by 3 of the 5
plugins' own `methodology-gate.sh` (`product-opportunity-solution-tree`,
`product-hypothesis-testing`, `product-guardrail-metrics` — each has a
`RECORD_RE`/`m_record` pattern anchored on `docs/issue-<n>/reports/
product-discovery\.md$`) is `product-discovery.md`, not `product.md`. No
gate in this tree has ever matched `product.md` — the probe payload never
reaches any record-handling branch, so `substance_probe` always falls
through to "no gate refuses" and reports FAIL when it runs at all.

## 2. `probe_dir`'s default resolves to a directory that has never existed (confirmed)

`tests/deny-only-check.sh:46`:

    probe_dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../product/hooks" && pwd -P)}"

Same "ghost `product` role" shape issue #45's survey §6 and issue #48's
survey §4 already found and fixed elsewhere in this tree (`tests/parse-
check.sh`'s old default, `tests/run-gate-tests.sh`'s header comment) — this
repo has no `product/` directory, only 5 `product-*/` plugin directories.
`cd` against the nonexistent path fails; under `set -uo pipefail` (no
`set -e`) the failed `cd` leaves `probe_dir` unset-but-defaulted to empty
string via the failed command substitution, so `find "" -name '*-gate.sh'`
finds nothing and `substance_probe` prints "no gate scripts under" and
returns 0 (soft-skip) whenever no `$1` is passed. Separately, `probe_dir`
is tied to `$1` — the same argument the permissionDecision grep (`dir`)
uses — so even a correct per-plugin invocation
(`deny-only-check.sh product-one-pager/hooks`, README's own documented
call) only ever searches that one plugin's `hooks/` dir. 2 of 5 plugins
(`product-one-pager`, `product-assumption-mapping`) explicitly have no
phase-2/record obligation (their own `hooks/directive.sh`: "this plugin
has no record obligation, so there is nothing to carry into execution
judgment" / "this plugin has no phase-2 obligation and stays silent on
the record path") — invoking the probe scoped to either of those two
dirs alone can never find a record-owning gate, no matter how `rec_rel`
is spelled. The record obligation is federated across the other 3
plugins; the probe needs repo-wide reach to find any of them.

## 3. README.md:127-130 documents the no-op as expected, not as the defect it is

    # ...and so on per plugin; deny-only-check.sh's substance probe targets
    # a generic docs/issue-<n>/reports/product.md path that no gate in this
    # repo claims (each plugin only fires on its own proposal/survey/record
    # scope), so that probe is a known no-op here, not a regression.

This is accurate as a description of the current (broken) behavior, but it
documents item 1 + item 2's combined effect as intentional design rather
than as the residual defect issue #51 exists to close. Once items 1-2 are
fixed, this comment becomes false (the probe is no longer a no-op) and
must be replaced with prose describing the actual green result.

## Gaps this survey leaves open (for the proposal to resolve)

- Whether `probe_dir` should be decoupled from `$1` entirely (always
  search repo-wide, since the record obligation is federated across 3 of
  5 plugins and no single plugin dir can exercise it) or whether README's
  documented call shape changes instead to a single repo-root invocation
  — proposal decides.
- Exact replacement wording for README.md:127-130.
</content>
