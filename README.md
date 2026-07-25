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

Excerpted from `docs/specs/role-handoff-contract.md` (root `tokenmaxxxer`
repo) at `2affe5db7dfb285abaa2860d3004edb3f97c9aec` — product's rows only.
`product-cycle/hooks/state-gate.sh` refuses to proceed when this pinned
SHA no longer matches the contract's current SHA.

### Accepts

- **`feasibility-record`** — to react to a verdict on a prior hypothesis.

Refuses: `build-proposal`, `qa-state`, `review-record`, `ops-state`.

### Where upstream lives

- `feasibility-record` is read from
  `docs/reports/records/<subject>/feasibility.md` in the target repo.

The user hands over only a pointer ("it's here"); this path is what lets
`product` resolve that pointer on its own, without asking.

### Produces

- **`hypothesis`** at `docs/proposals/<date>-<slug>.md`. Required fields:
  role status (`idle,scoping,researching,hypothesis-registered,measuring,decided`),
  plus the common header (`kind`, `subject`, `produced_by`, `upstream`,
  `handoff_status: provisional | final`). `product` owns the
  `<date>-<slug>.md` filename form in `docs/proposals/`; `coding` owns
  `<date>-build-<slug>.md` in the same directory. The two forms can never
  collide on the same date, because coding's carries the `build-` tag and
  product's structurally cannot.
- **`one-pager`** at `product/one-pager.md`. Required fields (all
  non-empty): Background/Context, Problem Statement, Candidate Hypotheses,
  Known Risks, Goals/Success Metrics — plus the common header.
- **`opportunity-tree`** at `product/opportunity-tree.md`. A continuous
  interview log, no fixed state field — plus the common header.

### Stops

- **Upstream stale at role entry.** Before acting on a handed-over
  `feasibility-record`, `product` compares the recorded `sha` in its
  `upstream` entry against the current commit that touched that path. If
  they differ, `product` stops before doing further work and asks the user
  whether to proceed on the recorded version or re-confirm against the
  current one — it does not decide this itself.
- **A record already exists at a path `product` does not own.** If
  `product`, in the course of its work, finds an existing record already
  present under `docs/reports/records/` or at a `docs/proposals/` filename
  it does not own (including a `<date>-build-<slug>.md` slot tagged as
  coding's), it refuses to write there and reports the conflict — the
  path, and whose territory it falls in — to the user. It never overwrites
  or merges into it silently.
- **Input carries `handoff_status: provisional`.** `product` may read a
  provisional `feasibility-record` to plan or draft against, but must not
  treat it as final input to an accept/refuse decision or as the baseline
  recorded in its own `upstream` entry for the staleness check, until the
  artifact's `handoff_status` reads `final`.

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
