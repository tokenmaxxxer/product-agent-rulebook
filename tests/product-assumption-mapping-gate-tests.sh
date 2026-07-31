#!/usr/bin/env bash
# product-assumption-mapping gate, exercised as a real subprocess.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../product-assumption-mapping/hooks"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

TARGET=docs/issue-77/proposals/2026-07-28-product-discovery.md
CURRENT_STATE=docs/issue-77/reports/product-discovery/current-state.md

# run want name content [skip_current_state]
run() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  mkdir -p "$td/$(dirname "$TARGET")"
  if [ "${4:-}" != "skip" ]; then
    mkdir -p "$td/$(dirname "$CURRENT_STATE")"
    echo "survey" > "$td/$CURRENT_STATE"
  fi
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$3")" "$td" \
    | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

ZERO_CITATION='# Proposal
No citations here at all, just prose about the idea.'
run allow citation-zero-pass "$ZERO_CITATION"

BAD_CITATION='# Proposal
Evidence: 3 interviews said users like it.'
run deny citation-missing-date "$BAD_CITATION"

GOOD_CITATION='# Proposal
Evidence: 3 interviews, approx 2026-06, paraphrase: users struggle with onboarding.'
run allow citation-good-pass "$GOOD_CITATION"

RICE_GOOD='# Proposal
- candidate A
- candidate B
RICE: Reach 100, Impact 3, Confidence 80, Effort 2 for A.
RICE: Reach 50, Impact 2, Confidence 70, Effort 1 for B.'
run allow rice-required-pass "$RICE_GOOD"

RICE_MISSING='# Proposal
- candidate A
- candidate B
No scoring here.'
run deny rice-required-deny "$RICE_MISSING"

ICE_FLAGGED='# Proposal
- candidate A
- candidate B
Reach data unavailable, so ICE score used: Impact 3, Confidence 80, Effort 2 for A.
ICE: Impact 2, Confidence 70, Effort 1 for B, reach unavailable.'
run allow ice-flagged-pass "$ICE_FLAGGED"

ICE_UNFLAGGED='# Proposal
- candidate A
- candidate B
ICE: Impact 3, Confidence 80, Effort 2 for A.
ICE: Impact 2, Confidence 70, Effort 1 for B.'
run deny ice-unflagged-deny "$ICE_UNFLAGGED"

# order constraint: current-state.md absent
run deny order-constraint-deny "$ZERO_CITATION" skip
run allow order-constraint-pass "$ZERO_CITATION"

# malformed stdin
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf 'not json' | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" malformed-stdin-deny

# unrelated path pass-through
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
printf '{"tool_name":"Write","tool_input":{"file_path":"src/app.py","content":"x"},"cwd":"%s"}' "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" unrelated-path-pass

# kill switch
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")"
printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
  "$TARGET" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$RICE_MISSING")" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" PRODUCT_ASSUMPTION_MAPPING_GATE_OFF=1 /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report allow "$got" kill-switch-pass

# Edit reconstruction failure (old_string not present in current file)
td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
mkdir -p "$td/$(dirname "$TARGET")" "$td/$(dirname "$CURRENT_STATE")"
echo "survey" > "$td/$CURRENT_STATE"
echo "existing content" > "$td/$TARGET"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"does-not-exist","new_string":"x"},"cwd":"%s"}' \
  "$TARGET" "$td" \
  | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/methodology-gate.sh" >/dev/null 2>&1
rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
rm -rf "$td"; report deny "$got" edit-recon-failure-deny

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
