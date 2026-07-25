# docs/

Documents in this repository live in one of six lifetime-based buckets,
following the same doctrine `coding-agent-rulebook` uses:

- `decisions/` — decisions fixed at the moment they were made.
- `handbooks/` — living how-to material, kept current.
- `reports/` — findings fixed to a point in time.
- `specs/` — the authoritative, evolving specification of how this
  repository's plugin works, in particular `specs/state-machine.md`.
- `proposals/` — this repository's own change proposals (its `warrant`-style
  units of work), and the specification files that carry `product-cycle`'s
  hypothesis state — the two share this directory by convention: a proposal
  frontmatter carries `status: proposed -> approved -> landed` for the work
  itself, while a specification file carries `status: idle -> ... ->
  decided` for a product hypothesis. `state-gate.sh` distinguishes them
  only by content (a proposal file has no `metric`/`threshold`/
  `decision_rule` fields), never by filename convention.
- `_assets/` — attachments (images, diagrams) referenced by documents above.

Each bucket that would otherwise be empty carries a placeholder so it is
tracked by git; see each bucket's own file for anything bucket-specific.
