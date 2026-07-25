---
status: draft
---

# product-cycle state machine

Authoritative for this repository. Transcribed from the `product` role's
entry in `docs/specs/agent-roles.md` (Part 3) in the org-level `docs/`
repository, restated here in this repository's own words because this
repository must be self-contained and not depend on reading that spec
repository at runtime.

## Carrying artifact and state field

State lives in one specification file per hypothesis, under
`docs/proposals/<date>-<slug>.md`, in its YAML frontmatter:

```
---
status: idle
metric:
threshold:
decision_rule:
---
```

- **State file**: the specification file itself, matched by the gate as any
  file at `docs/proposals/<name>.md` other than `docs/proposals/README.md`.
- **State field**: the frontmatter key `status`.
- **Registration fields**: `metric`, `threshold`, `decision_rule` — the
  pre-registered metric, threshold, and decision rule required before the
  gated transition below.

Only one hypothesis is in flight against a given specification file at a
time. Multiple hypotheses (multiple files) may coexist; each is judged
independently by the gate.

## States

`idle`, `scoping`, `researching`, `hypothesis-registered`, `measuring`,
`decided`.

## Transition table

| From | To | Fires on |
|---|---|---|
| `idle` | `scoping` | user hands the role an idea |
| `scoping` | `researching` | agent begins gathering evidence for the idea |
| `researching` | `hypothesis-registered` | agent proposes a metric, threshold, and decision rule; written into the file |
| `hypothesis-registered` | `measuring` | **gated** — user approves the registered package in their own turn |
| `measuring` | `decided` | the registered rule is applied to collected data |
| `hypothesis-registered` | `scoping` | user rejects the package; back to gathering |

## Gate: `hypothesis-registered -> measuring`

Refused unless **both** of the following hold:

1. **Content condition**: the file's `metric`, `threshold`, and
   `decision_rule` fields are all non-empty.
2. **Approval condition**: an approval token exists at
   `.product-cycle/tokens/<basename>.token` (relative to the repository
   root), minted by `product-cycle/hooks/capture-approval.sh` from the
   user's own turn, whose `file:` line matches the specification file's
   path (relative to the repository root) and whose `transition:` line
   reads exactly `hypothesis-registered -> measuring`.

A file with all three fields filled in but no matching token does not
pass — **content is not consent**. The token is single-use: the gate
consumes (deletes) it the moment the transition it authorizes is applied,
so it cannot be replayed against a later, different edit.

Enforced by `product-cycle/hooks/state-gate.sh`, a `PreToolUse` hook
registered against `Write|Edit|NotebookEdit|Bash`. The check is against the
**resolved target path**, never against which tool performs the write: a
`Bash` command that redirects (`>`, `>>`), pipes through `tee`, or edits
in place with `sed -i`/`perl -i`/`ruby -i` into a specification file that
is currently `hypothesis-registered` or `measuring` is refused outright,
because the gate cannot compute the resulting file content without
executing the command, and it never verifies after the fact — the edit
must go through `Write` or `Edit` so the resulting content can be checked
before it lands.

## Invariant: threshold is frozen once `measuring` starts

While a file's on-disk `status` is `measuring`, any write (through any
tool) that changes the `threshold` field's value is refused, independent
of whatever else the write also changes. This is enforced the same way as
the gate above: judged against resolved target path and computed resulting
content, and refused outright for a `Bash`-driven write to such a file
since the resulting content cannot be verified in advance.

## `decided`

Reached by applying the rule fixed at `hypothesis-registered` to the data
collected during `measuring` — mechanically, not by fresh judgement. This
repository's tooling does not (and cannot) mechanically verify that the
final call actually follows the registered rule rather than a new
argument; `product-cycle/skills/hypothesis-testing/SKILL.md` carries this
as a direction to the agent, since it is a semantic judgement about
reasoning, not a syntactic property of the file the way the two rules
above are.

## Fail-closed

`state-gate.sh` denies on any input it cannot parse or resolve — an
unreadable or non-JSON tool-use payload, a missing `tool_name`/`tool_input`,
an `Edit` call whose `old_string` is not found verbatim in the current file,
a malformed or unreadable token file — rather than falling through to
allow. This is a deliberate departure from `coding-agent-rulebook`'s
`warrant/hooks/scope-gate.sh` and `qa-agent-rulebook`'s
`signoff/hooks/capture-verdict.sh`, both of which fail *open* on malformed
input by design (a gate should not become a denial-of-service on its own
host repository). `state-gate.sh` instead fails *closed*: for a state
machine whose entire purpose is preventing an ungated transition, an
unparseable payload is exactly the situation in which "allow" cannot be
proven safe, so it is refused. Writes outside `docs/proposals/*.md` are
unaffected by any of this — the gate allows them immediately, without
attempting to parse frontmatter at all, once it determines the resolved
target path falls outside its scope.

## Kill switch

`export PRODUCT_CYCLE_OFF=1` disables both hooks (`capture-approval.sh`
mints nothing; `state-gate.sh` allows everything). Any other value,
including `0` or `false`, is read as "not off" — the same convention
`coding-agent-rulebook`'s plugins use, so that an unintentional truthy-ish
setting cannot silently disable the gate on the exact spelling meant to
keep it alive.
