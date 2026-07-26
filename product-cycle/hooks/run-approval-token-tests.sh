#!/usr/bin/env bash
# Runs scope-approval-token.sh as a real subprocess against real prompts and
# asserts on the only thing that matters: whether a token file was left behind.
# It never reads the hook's source.
#
# The cases exist because the hook used to mint a token from the NAME of the
# transition rather than from an approval. Measured 2026-07-27 against a real
# subject, all of these produced a valid, consumable token:
#
#   - a refusal ("stop at the scope-approved gate; do not approve on my behalf")
#   - the contract's own text quoted back
#   - a statement that the subject is NOT yet scope-approved
#
# The first minted a token whose own `phrase:` field contained the refusal.
# Contract §19 calls this gate "human-owned, never self-certified"; an agent
# explaining that it must not approve was enough to certify it.
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/scope-approval-token.sh"
SUB="2026-07-27-laundry-drying-time"
pass=0
fail=0

# want: mint | reject
check() {
  want="$1"; name="$2"; prompt="$3"
  td="$(mktemp -d)"
  git init -q "$td"
  printf '%s' "$(python3 -c '
import json, sys
print(json.dumps({"prompt": sys.argv[1], "cwd": sys.argv[2]}))' "$prompt" "$td")" \
    | CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  if find "$td" -name '*.token' -type f | grep -q .; then got=mint; else got=reject; fi
  rm -rf "$td"
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1)); printf 'ok     %-22s %s\n' "$name" "$got"
  else
    fail=$((fail + 1)); printf 'FAIL   %-22s want=%s got=%s\n' "$name" "$want" "$got"
  fi
}

check reject "refusal-ko"       "subject $SUB 의 scope-approved 게이트에 닿으면 멈춰라. 대신 승인하지 마라."
check reject "refusal-en"       "For subject $SUB, do not approve the scope on my behalf."
check reject "contract-quote"   "계약 §19 는 subject $SUB 의 loop_state 를 scope-approved 로 올리는 유일한 경로를 사람으로 규정한다."
check reject "state-mention"    "subject $SUB 는 아직 scope-approved 가 아니다."
check reject "agent-explains"   "subject $SUB 에 대해 제가 scope-approved 를 대신 쓸 수 없습니다."
check reject "bare-assent"      "ok"
check reject "no-subject"       "I approve the scope."
check mint   "approval-en"      "I approve the scope for subject $SUB."
check mint   "approval-ko"      "subject $SUB 의 scope 를 승인한다."
check mint   "approval-ko-범위" "subject $SUB 의 범위를 승인한다."

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
