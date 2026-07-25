---
proposal: docs/proposals/2026-07-25-product-agent-rulebook-repo.md
---

# Hunt record — product-agent-rulebook-repo

## after-proposal — stance 3: assume the rule as written cannot hold — find the state nothing maintains

Verdict: FINDING — the proposal's rejection rule for `hypothesis-registered -> measuring` depends on an "approval token from the user's own turn" that nothing in the proposal's write set ever mints.

Kind: design-error

Seed: `/home/jwjung/tokenmaxxxer/docs/proposals/2026-07-25-product-agent-rulebook-repo.md` together with
`/home/jwjung/tokenmaxxxer/docs/specs/agent-roles.md` (`product` state machine, rejection rule:
"a recorded approval token tied to this file and this transition exists from the user's own turn").

### Reproduce

Compare the proposal's write set to the sibling repo it is explicitly modeled on
(`qa-agent-rulebook`, whose token discipline `agent-roles.md` itself cites as the
rule this proposal follows):

```
sed -n '1,18p' /home/jwjung/tokenmaxxxer/docs/proposals/2026-07-25-product-agent-rulebook-repo.md
# frontmatter files: lists exactly one hook script:
#   product-agent-rulebook/product-cycle/hooks/state-gate.sh
# and it is described (body, "What will be done") as a PreToolUse hook only.

find /home/jwjung/tokenmaxxxer/qa-agent-rulebook -path "*/hooks/hooks.json"
# -> signoff/hooks/hooks.json, qa-cycle/hooks/hooks.json, ... (separate plugins)

cat /home/jwjung/tokenmaxxxer/qa-agent-rulebook/signoff/hooks/hooks.json
# -> registers capture-verdict.sh under UserPromptSubmit: the hook that actually
#    scans the user's own turn for an unambiguous verdict and mints a token file
#    (qa-agent-rulebook/signoff/hooks/capture-verdict.sh, tokens/<item>.token).

grep -n "UserPromptSubmit\|mint" /home/jwjung/tokenmaxxxer/docs/proposals/2026-07-25-product-agent-rulebook-repo.md
# -> no matches: the proposal names no UserPromptSubmit hook, no minting script,
#    no tokens/ directory, anywhere in its file list or its body.
```

### Observed

The proposal's only listed hook is `state-gate.sh`, a `PreToolUse` hook whose job is
to *check* for "a recorded approval token from the user's own turn" before allowing
`hypothesis-registered -> measuring`. In the sibling repo this same rule is split into
two cooperating hooks: a `UserPromptSubmit` hook (`capture-verdict.sh`) that reads the
literal user turn and writes a token file, and a `PreToolUse` hook (`transition-gate.sh`)
that only reads that file. The product proposal's write set and body describe only the
second half. Nothing in what will be built ever writes the token `state-gate.sh` is
specified to look for — the "approval token" is state with no writer.

### Expected

Either the proposal's write set names the minting mechanism (a `UserPromptSubmit` hook,
or an explicit description of how/where "an approval token... is recorded" gets written,
mirroring `qa-agent-rulebook/signoff/hooks/capture-verdict.sh`), or the rejection rule is
worded to admit that no such mechanism exists yet — as written, `state-gate.sh` can only
ever see an empty/absent token and the `hypothesis-registered -> measuring` transition is
either permanently refused (fail-closed on missing state) or, if the eventual hook author
free-lances a substitute (e.g. inferring approval from a field in the state file itself),
it directly reintroduces the "content is not consent" failure the spec explicitly rules out
("A file with all three fields filled in but no approval token does not pass").
