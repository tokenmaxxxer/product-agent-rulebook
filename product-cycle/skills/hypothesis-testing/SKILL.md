---
name: hypothesis-testing
description: >
  Use this skill whenever the product role is moving a specification file
  through product-cycle's state machine — scoping an idea, registering a
  metric/threshold/decision rule, asking the user to approve the move into
  measuring, or applying a registered rule to reach a decision. Trigger it
  before writing status, metric, threshold, or decision_rule into any file
  under docs/proposals/. Do NOT use it to make the go/kill/pivot call
  yourself once measuring has started — that call belongs to the
  pre-registered rule, not to fresh judgement at decision time.
---

# Hypothesis testing for the product role

product-cycle treats an idea as a theory: it earns the right to move to
`measuring` only once a metric, a threshold, and a decision rule are all
written down — and the user has approved that exact package in their own
turn. See `docs/specs/state-machine.md` in this repository for the
authoritative state table and gate conditions; this skill is the how-to for
moving through it correctly.

## The carrying file

Every hypothesis lives in one specification file under `docs/proposals/`,
e.g. `docs/proposals/2026-07-25-onboarding-checklist.md`, with YAML
frontmatter:

```
---
status: idle
metric:
threshold:
decision_rule:
---
```

`status` is the state field. `metric`, `threshold`, and `decision_rule` are
the pre-registration fields. All four live in this one file — do not split
them across files, and do not track state anywhere else (no separate ledger,
no database, no state stored only in conversation).

## Moving through the states

1. **idle -> scoping**: the user hands you an idea. Set `status: scoping`
   and write down what the idea claims and who it is for. Nothing else is
   required to open the role.

2. **scoping -> researching**: begin gathering evidence — user interviews,
   existing data, competitive signal, whatever grounds the claim. Set
   `status: researching`. Do not skip straight to a metric before you have
   evidence to derive one from; a registered metric with no evidentiary
   basis is not what this state is for.

3. **researching -> hypothesis-registered**: propose the metric, the
   threshold, and the decision rule, and write all three into the file's
   frontmatter, e.g.:

   ```
   metric: 7-day activation rate among new signups
   threshold: >= 20% within a 2-week measurement window
   decision_rule: if the 7-day activation rate is >= 20% at the end of the
     2-week window, persist and move to the next milestone; if it is below
     15%, kill; between 15% and 20%, extend the window once by 2 weeks and
     re-measure, no further extensions.
   ```

   The rule must be a decision procedure that a fresh reader could apply
   mechanically to the data — not "we'll see how it feels." Fix it before
   any data collection starts; this is the whole point of pre-registration.
   Set `status: hypothesis-registered`.

4. **hypothesis-registered -> measuring** (gated): this is the one
   transition `state-gate.sh` enforces mechanically. It is refused unless:
   - `metric`, `threshold`, and `decision_rule` are all non-empty in the
     file, AND
   - the user approved this exact package in their own turn — say so
     explicitly (e.g. "I approve the registered hypothesis, go ahead and
     move to measuring"). A vague "ok" or "sounds good" does not count;
     `capture-approval.sh` rejects bare assent on purpose. Content in the
     file is never read as consent — the token has to come from what the
     user actually typed.

   If the user pushes back on the package instead, move `status` back to
   `scoping` and revise — do not attempt to force the transition by editing
   around the gate (e.g. writing the file through a shell command instead
   of Write/Edit); the gate refuses those too, by design.

5. **measuring**: once here, the finish line cannot move. `state-gate.sh`
   refuses any edit that changes the `threshold` field while `status:
   measuring`, regardless of which tool makes the edit. Update other
   fields (e.g. collected-data notes) freely; do not touch `threshold`.

6. **measuring -> decided**: apply the rule fixed in step 3 to whatever
   data was collected — mechanically, not by fresh argument. If the
   registered rule said "kill below 15%," a 14% result is a kill even if it
   feels close; that is what pre-registration is for. Write the outcome
   and set `status: decided`. If you find yourself arguing for a different
   call than the rule dictates, that is a sign the rule was mis-specified
   at registration time — file that as a lesson for the next hypothesis,
   not as a reason to override this one.

## Common mistakes this skill exists to prevent

- Registering a metric with no threshold ("we'll track activation and see")
  — not a testable hypothesis, and the gate will refuse it.
- Treating the user's silence, or a file simply containing all three
  fields, as approval — it is not; the gate requires an actual approval
  token from the user's own turn.
- Rationalizing a different decision than the registered rule once the
  numbers come in. The value of pre-registration is precisely that the
  rule was fixed before anyone had a stake in a particular answer.
- Editing `threshold` after `measuring` starts because new information
  makes the original number look wrong. If the threshold was genuinely
  mis-set, kill the hypothesis and register a new one — do not move the
  goalposts on the one in flight.
