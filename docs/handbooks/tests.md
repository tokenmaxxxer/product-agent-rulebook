# Handbook — tests/

`tests/run-gate-tests.sh` exercises the legacy `record-fields-gate.sh`/
`trailer-gate.sh` checks (now core-generic, no longer vendored under
this repo — those cases are stale pending an update tracked
separately), then runs each of the five `product-*` methodology
plugins' own gate test suite as a subprocess:
`tests/product-one-pager-gate-tests.sh`,
`tests/product-opportunity-solution-tree-gate-tests.sh`,
`tests/product-assumption-mapping-gate-tests.sh`,
`tests/product-hypothesis-testing-gate-tests.sh`,
`tests/product-guardrail-metrics-gate-tests.sh`.

## Run

    bash tests/run-gate-tests.sh

Each plugin's own suite can also be run standalone, e.g.:

    bash tests/product-hypothesis-testing-gate-tests.sh

## Coverage

- `record-fields-gate.sh` (core-generic): §20 record-content checks,
  including the `TERMINAL` set (`decided`, `scope-proposed`) that
  exempts a record from the open-work backlog/resolution-path
  requirement.
- `trailer-gate.sh` (core-generic): `Subject: issue-<n>` trailer on
  commits staging `docs/issue-<n>/**`.
- Each `product-*` plugin's `methodology-gate.sh`: its own adopted-
  methodology facet from `docs/issue-36`'s norms (JTBD tuple, OST
  vocabulary/disposition, evidence-citation + RICE/ICE, hypothesis
  package + verdict-adjacency + ITWWS, guardrail non-emptiness +
  status), plus the shared cross-plugin order-constraint (proposal
  write must not precede its own current-state survey), fail-closed
  behavior, and each plugin's own kill switch.

Add a case here whenever a gate's decision boundary changes (e.g. a new
`TERMINAL` value, a new required section, a new plugin facet).
