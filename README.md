# tokenmaxxxer / product-agent-rulebook

A Claude Code plugin marketplace for the `product` agent role, one of four
new roles specified in `docs/specs/agent-roles.md` (org-level `docs/`
repository) alongside the existing `coding` (`coding-agent-rulebook`) and
`qa` (`qa-agent-rulebook`) roles.

## What `product` decides

`product` decides what to build — value risk and business-viability risk,
in the empowered-team sense: the PM owns exactly those two risks, not a
feature list handed down from elsewhere.

- **Given to start**: an idea. Nothing more is required to open the role.
- **Produces**: a specification, or a kill record — whichever the
  pre-registered hypothesis says. The metric, the threshold, and the
  decision rule are fixed *before* data collection, and the eventual
  go/kill/pivot call is the mechanical application of that rule, not a
  fresh judgement made once the numbers are in.
- **Prevents**: building something nobody wants, and — the sharper
  failure — deciding that only after the fact, against no threshold fixed
  in advance.

This repository never reads another role's repository, and no other role's
repository reads this one. The user is the only channel between roles; see
`docs/specs/state-machine.md` for the full state machine this repository
enforces and `product-cycle/skills/hypothesis-testing/SKILL.md` for the
how-to.

## The state machine, briefly

States: `idle -> scoping -> researching -> hypothesis-registered ->
measuring -> decided`, carried in a specification file's frontmatter under
`docs/proposals/<date>-<slug>.md` (field `status`, plus `metric`,
`threshold`, `decision_rule`).

The one gated transition, `hypothesis-registered -> measuring`, is refused
unless the metric, threshold, and decision rule are all filled in **and**
an approval token minted from the user's own turn is present — content
alone is never read as consent. Once `measuring` starts, edits to the
`threshold` field are refused, from any tool, including a shell redirect.
Full detail, including the fail-closed rule and the token format, is in
`docs/specs/state-machine.md`.

## Handoff protocol

The authoritative contract is the work repo's own
`docs/specs/role-handoff-contract.md` — the file inside the git root this
session is pointed at, not any file outside that repo. This section
describes only how the product role behaves against whatever contract the
work repo carries; it excerpts product's rows for convenience, but the
work repo's copy is what governs. `product-cycle/hooks/state-gate.sh`
refuses handoff-protocol actions when that repo has no
`docs/specs/role-handoff-contract.md` yet, rather than proceeding
silently.

### WAKES-ON

Per contract §3's product row: product wakes on a qa or review outcome
whose content questions the standing acceptance criteria. WAKES-ON is a
trigger condition, not an accept/refuse gate — reading a kind and being
woken by it are different questions (see the next subsection).

### READ / DEPENDS-ON / NEVER-OVERWRITE

Per contract §4's three questions, at product's grain:

- **READ: broad, unconditional.** `product` may read any board record for
  context, including `build-proposal`, `qa-record`, `review-record`, and
  `ops-record` — none of these are refused reading, unlike v1's Refuses
  list.
- **DEPENDS-ON: narrow.** Product depends on `feasibility-record` (a
  verdict causing it to react) — contract §4's own product bullet,
  verbatim. This is the one dependency contract §4 explicitly assigns
  product.
- **NEVER-OVERWRITE.** Product writes only: `docs/proposals/<date>-<slug>.md`
  (`kind: hypothesis`), `docs/reports/records/<subject>/product.md`
  (`kind: product-record`), `product/one-pager.md` (`kind: one-pager`),
  `product/opportunity-tree.md` (`kind: opportunity-tree`) — contract
  §11's product row, verbatim. `docs/proposals/` stays shared between
  product and coding, disambiguated by filename tag: coding's
  `build-proposal` filenames carry `-build-` (`<date>-build-<slug>.md`),
  distinct on its face from product's `<date>-<slug>.md`. **Callout:**
  any glob/regex product's tooling (including a gate check) uses to
  recognize "is this file mine" under `docs/proposals/` must exclude the
  `-build-` tag, not just match on directory — matching on directory
  alone would wrongly claim coding's files too.

### Where upstream lives

- `feasibility-record` is read from
  `docs/reports/records/<subject>/feasibility.md` in the target repo.

The user hands over only a pointer ("it's here"); this path is what lets
`product` resolve that pointer on its own, without asking.

### Blackboard record shapes

Per contract §2's table and §7, `product` owns four kinds:

- **`hypothesis`** at `docs/proposals/<date>-<slug>.md`. `loop_state`
  vocabulary: `idle,scoping,researching,hypothesis-registered,measuring,decided`.
  Required fields beyond the common header: Background/Context, Problem
  Statement, Candidate Hypotheses, Known Risks, Goals/Success Metrics.
  `product` owns the `<date>-<slug>.md` filename form in
  `docs/proposals/`; `coding` owns `<date>-build-<slug>.md` in the same
  directory. The two forms can never collide on the same date, because
  coding's carries the `build-` tag and product's structurally cannot.
- **`product-record`** at `docs/reports/records/<subject>/product.md`.
  Same `loop_state` vocabulary as `hypothesis`. Required fields: a
  pointer to the governing `hypothesis`, plus running acceptance-criteria
  notes.
- **`one-pager`** at `product/one-pager.md`. Standing doc, `loop_state:
  n/a`. Required fields (all non-empty): Background/Context, Problem
  Statement, Candidate Hypotheses, Known Risks, Goals/Success Metrics —
  plus the common header.
- **`opportunity-tree`** at `product/opportunity-tree.md`. Standing doc,
  `loop_state: n/a`. A continuous interview log, no other required
  fields.

### Finding participation

Per contract §5: `product` may both produce and receive `finding` blocks
(generalized in v2 from v1's review-only findings). When `product` closes
out a `finding` addressed to it, `product.md` (the `product-record`) must
carry a `finding-response` entry with all three required parts: the
finding reference (record path + finding identifier), the action taken or
decline reason, and — when applicable — proof of the fix. An entry
missing any of the three parts does not close the finding.

### Loop termination

Per contract §6: a wake is consumed only by writing the resulting record
entry — a `loop_state` change, a new `finding`, a `finding-response`, or
equivalent. An unchanged board wakes no one.

### Minting `subject` (contract §9)

Any role may open a chain, not only `product` — "not only product...
deterministic regardless of which role does it." Before minting a new
`subject`, search `docs/reports/records/*/` and `docs/proposals/*` for an
existing `subject` describing the same work and adopt it verbatim if
found, rather than assuming `product` is always the chain-opener.

### Stops

- **Upstream stale at role entry — contract §12.** Before acting on a
  handed-over `feasibility-record`, `product` compares the recorded `sha`
  in its `upstream` entry against the current commit that touched that
  path. On first read of an `upstream` entry, this always prompts the
  user once. On a later re-entry, if the current sha matches the recorded
  `acknowledged_sha`, it does not re-prompt. A sha matching neither `sha`
  nor `acknowledged_sha` re-fires the full prompt — the gate does not
  decide "proceed" or "re-confirm" itself, it asks.
- **A record already exists at a path `product` does not own.** If
  `product`, in the course of its work, finds an existing record already
  present under `docs/reports/records/` or at a `docs/proposals/`
  filename it does not own (including a `<date>-build-<slug>.md` slot
  tagged as coding's), it refuses to write there and reports the
  conflict — the path, and whose territory it falls in — to the user. It
  never overwrites or merges into it silently.

## Install

```
curl -fsSL https://raw.githubusercontent.com/tokenmaxxxer/product-agent-rulebook/main/install.sh | bash
```

This registers the `tokenmaxxxer-product` marketplace and installs the
`product-agent-env` bundle plus `product-cycle` at **user scope**. It
applies to your account on every machine-local session; it does not travel
with a repo and does not reach Claude Code on the web or Slack cloud
sessions. It names only this repository and its own marketplace — nothing
else in the `tokenmaxxxer` org is touched or referenced.

The script prefers a real `claude` CLI (standalone, or the binary bundled
inside the VSCode extension) if it finds one, and runs `plugin install
<name>@tokenmaxxxer-product --scope user` for `product-cycle` and the
bundle, then updates each to the marketplace's latest. If no `claude`
binary is found — or `TOKENMAXXXER_SETTINGS_ONLY=1` is set to force it —
the script falls back to writing `~/.claude/settings.json` directly: it
resolves and prefix-checks the settings path against your home directory
before writing, aborts untouched on a parse failure of an existing file,
backs up before writing, and follows a symlink rather than replacing it.

Or, from any Claude Code session, the equivalent by hand:

```
/plugin marketplace add tokenmaxxxer/product-agent-rulebook
/plugin install product-agent-env@tokenmaxxxer-product
```

`install.sh --help` prints usage. The only other input it reads is the
`TOKENMAXXXER_SETTINGS_ONLY=1` environment variable described above.

## Writing the settings by hand

```json
{
  "extraKnownMarketplaces": {
    "tokenmaxxxer-product": {
      "source": { "source": "github", "repo": "tokenmaxxxer/product-agent-rulebook" }
    }
  },
  "enabledPlugins": {
    "product-agent-env@tokenmaxxxer-product": true
  }
}
```

## Repo layout

- `install.sh` — the one-shot installer described above.
- `.claude-plugin/marketplace.json` — the marketplace manifest (name
  `tokenmaxxxer-product`), listing `product-cycle` and `product-agent-env`,
  both `./`-relative to this repository.
- `product-cycle/` — the role plugin: `.claude-plugin/plugin.json`, two
  hooks (`hooks/hooks.json`, `hooks/capture-approval.sh`,
  `hooks/state-gate.sh`), and `skills/hypothesis-testing/`.
- `product-agent-env/` — the bundle plugin: `.claude-plugin/plugin.json`
  only, no code of its own, listing `product-cycle` as its dependency.
- `docs/` — six lifetime buckets (`decisions/`, `handbooks/`, `reports/`,
  `specs/`, `proposals/`, `_assets/`), each with a placeholder if empty.
  `docs/specs/state-machine.md` is the authoritative state-machine spec for
  this repository.

## Self-contained by design

This repository is independently installable into its own sandbox: no
shared code, no cross-repository dependency, no shared file, index, or
ledger with `coding-agent-rulebook`, `qa-agent-rulebook`, or any sibling
role repository (`feasibility-agent-rulebook`, `review-agent-rulebook`,
`ops-agent-rulebook`). Nothing in this repository names or reads another
repository at runtime.
