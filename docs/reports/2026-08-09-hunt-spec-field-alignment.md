---
proposal: docs/issue-57/proposals/2026-08-09-spec-field-alignment.md
---

# Hunt record — spec-field-alignment

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — the proposal's Request section labels the spec's field set "17 required-field vocabulary," but the spec itself marks only 16 of those 17 fields required:true (confidence_level is required:false), and the proposal's own step 2 acknowledges this by documenting confidence_level as optional — a self-contradiction that would let a future mechanical acceptance check built on the Request's stated field count silently accept a record missing confidence_level while believing it verified full required-field coverage, or conversely flag a compliant record as missing a "required" field it was never obligated to carry.
Kind: design-error
Seed: docs/issue-57/proposals/2026-08-09-spec-field-alignment.md (docs-only diff, phase 1); cross-referenced against the external marketplace spec file this proposal maps onto (present in a sibling worktree at /home/jwjung/.tokenmaxxxer/work/on-the-record-issue-524-requirements-engineering/roles/specs/product-discovery.spec.json, not vendored in this repo, consistent with the proposal's/survey's own disclosure that it is external)
cap_seconds: 120
tier: default
diff_stat_lines: 2 files added (survey.md, proposal.md); proposal.md is roughly 220 lines
started_at: 2026-08-08T19:31:14Z
ended_at: 2026-08-08T19:47:00Z

### Reproduce
grep -n "17 required-field" docs/issue-57/proposals/2026-08-09-spec-field-alignment.md
grep -n 'required.: false\|confidence_level' /home/jwjung/.tokenmaxxxer/work/on-the-record-issue-524-requirements-engineering/roles/specs/product-discovery.spec.json
grep -c '"name"' /home/jwjung/.tokenmaxxxer/work/on-the-record-issue-524-requirements-engineering/roles/specs/product-discovery.spec.json
grep -c '"required": true' /home/jwjung/.tokenmaxxxer/work/on-the-record-issue-524-requirements-engineering/roles/specs/product-discovery.spec.json

### Observed
The proposal's Request section reads: "Layer the realized marketplace
spec's ... 17 required-field vocabulary and its loop_state set onto
this rulebook's docs and hook scripts". The spec file has 17 total field
entries but only 16 of them are marked required:true — confidence_level
is the one entry marked required:false. Step 2 of the proposal's own
"What will be done" section then correctly treats confidence_level as
optional ("documented as an optional field the skill may ask for but
never gates on, matching the spec's required: false"), directly
contradicting the Request section's characterization of that same field
as part of the "17 required-field vocabulary."

### Expected
The Request section should say something like "17 spec fields (16
required, 1 optional)" so any phase-2 tooling or human verification
built against this document's stated field-count doesn't inherit an
off-by-one between "total fields in the vocabulary" and "fields that are
actually required" — this is exactly the kind of miscount that lets a
coverage check silently over- or under-verify what it claims to check.
