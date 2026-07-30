# Handbook — tests/

`tests/run-gate-tests.sh` exercises the surviving PreToolUse gates
(`product/hooks/*.sh`) as real subprocesses against synthetic repos.

## Run

    bash tests/run-gate-tests.sh

## Coverage

- `record-fields-gate.sh`: §20 record-content checks, including the
  `TERMINAL` set (`decided`, `scope-proposed`) that exempts a record
  from the open-work backlog/resolution-path requirement.
- `trailer-gate.sh`: `Subject: issue-<n>` trailer on commits staging
  `docs/issue-<n>/**`.

Add a case here whenever a gate's decision boundary changes (e.g. a new
`TERMINAL` value, a new required section).
