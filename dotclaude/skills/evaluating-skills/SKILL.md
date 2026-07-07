---
description: Use when a skill mis-triggers, fails to fire, doesn't seem to improve the output, or competes with another skill; when deciding which of two skills should own a trigger surface; or before/after rewriting a skill, to measure whether the change actually moved triggering or effectiveness.
---

# Evaluating Skills

Measure whether a skill **triggers** correctly and is **effective**, then fix it and
re-measure. You run the skill against fresh subagents, grade the outputs with an
independent judge, and read transcripts for the trigger signal — no external harness, no
API keys, no container. The rewrite itself is delegated to `superpowers:writing-skills`;
this skill is the measurement and the loop around it.

Two worries, co-equal — and effectiveness is the bigger one: a skill that fires perfectly
but doesn't make the output better is worthless, and a trigger-rate never reveals that.

## Step 0: classify the subject

Before designing anything, decide what kind of skill you're evaluating. It sets the
scenario type, and getting it wrong measures nothing (pressure-testing a reference skill,
or application-testing a discipline skill, is a category error):

| Subject type | Examples | Effectiveness scenario |
|---|---|---|
| **Discipline** (a rule you'd rationalize away under pressure) | TDD, verification, double-check | **Pressure scenarios** — does it hold the line when tempted to skip? Control = a baseline that caves. |
| **Technique** (a how-to) | root-cause-tracing | **Application** — did a fresh agent apply it correctly to a new case? |
| **Pattern** (a mental model) | reducing-complexity | **Recognition + counter-examples** — fires on the right shape, not the wrong one? |
| **Reference** (docs / index) | an API or standards index | **Retrieval + gap** — can the agent find and correctly apply the right entry? |

## The two axes

1. **Effectiveness** — is the output materially better than the **control** (no-skill / old
   version / competitor)? Graded two ways: **acceptance criteria** (an absolute floor) and
   **blind A/B** (a judge picks the better of two unlabeled outputs).
2. **Triggering** — two questions, don't conflate them. **Isolated baseline**: the skill
   *alone* — does its description match the situation at all? **Competitive**: the full live
   roster — does it actually *win* the surface, or does a neighbor grab it first? A skill can
   match in isolation yet never fire because another always beats it (transcript / decision
   checks — see Principles).

They fail independently — a skill can fire flawlessly and add no uplift, or help a lot and
never fire on its own. Measure both; never let a strong trigger-rate mask a useless skill.

## Roles

- **subject** — a fresh `general-purpose` subagent (it carries the `Agent` tool, so a
  discipline subject can spawn its own experts/clean-room agents; the topology stays under
  the depth-5 ceiling). Run it *with* the skill and again as the *control*.
- **judge** — a separate fresh subagent that grades outputs against the criteria and runs
  the blind A/B. Never the producer, never you.
- **parent** (you) — frame scenarios, dispatch subject + judge, read transcripts, compose
  the verdict. Not the grader of record for effectiveness.

## The loop

1. **Frame.** Write scenario *stories* (realistic, detailed prompts — real paths, casual
   phrasing) with **acceptance criteria written first**, plus near-miss
   *should-not-trigger* controls. Fence every story (see Principles). Build the pack from
   `references/eval-pack-template.md`.
2. **Measure** (tiered — see Tiers):
   - *Triggering* — give the subject a triggering task **without naming the skill or its
     concepts**; read its transcript (`~/.claude/projects/<slug>/<sessionId>/subagents/`)
     for a `Skill`/`Read` invocation of the subject skill and for ordering (skill before
     the first implementation `Edit`/`Write`). Run the negatives; confirm silence.
   - *Effectiveness* — run the subject with the skill **force-pasted into its prompt** and
     again as a clean control; a judge grades each against the criteria (absolute) and
     picks the better blind (relative). Always against the control.
3. **Diagnose.** Read every flagged transcript and judge rationale by hand — never a bare
   grep count, never the subject's narration. Classify each failure: triggering vs
   effectiveness; a description problem (triggering) vs a body problem (effectiveness).
4. **Rewrite.** Hand the failure list to `superpowers:writing-skills`. Guardrails:
   `description` = *when to trigger*, never a workflow summary (this is SDO, Skill
   Discovery Optimization); match the form of the fix to the failure type.
5. **Re-measure.** Rerun the *same* scenarios. Confirm the numbers moved, the control still
   behaves, **nothing regressed** on previously-passing cases, variance converged. Iterate.

## Principles

- **Control arm always; small N is anecdote.** A rate means nothing without the baseline
  beside it; sentinel reps are a smoke check, only the full tier supports a verdict.
- **Criteria before results, and grade quality not conformance.** Decide what a good
  *output* looks like before you run; never grade "did it follow the skill's steps" — a
  rubric that echoes the skill passes by construction.
- **A relative win isn't an absolute pass.** Both arms can be bad while one wins the A/B.
  ACs set the floor, A/B sets the direction — report both.
- **Blind, independent judge.** Strip the arm labels, randomize order; the producer and you
  never grade.
- **Variance is the finding.** Five behaviors across five reps means the wording isn't
  binding — that's the result, not noise to average away.
- **Observable signals only.** A tool call or a filesystem artifact, never narration; pair
  an ordering check with a positive "skill-fired" check; empty transcript = indeterminate.
- **Fence the driver.** The story names neither the skill nor its concepts, and doesn't
  lift wording from its description (that tests memorization, not triggering).
- **Separate competitive from isolated triggering.** The live roster measures who *wins* —
  it can't tell a weak description from a strong one that a neighbor out-competes. Also
  measure the isolated baseline: ideally the skill alone in a clean environment, or —
  cheaply — present *only* its description and ask the model whether it'd invoke it. That
  decision-to-load proxy **over-fires** (an upper bound), so trust the *delta*, not the
  absolute: a skill that matches in isolation but never fires in the roster is being
  suppressed, not misworded — and rewording it won't help.
- **Force the skill on for the effectiveness arm.** Paste SKILL.md in rather than relying
  on auto-trigger — auto-trigger is the separate triggering axis.
- **Control for loaded rules.** Your own global rules can make the baseline pass for free
  and understate lift; run subjects clean and force retrieval. When you *can't* strip an
  inherited rule — e.g. a user-global rule that inlines the very corpus the skill retrieves —
  say so and report the lift as a **floor** (understated), never zero; don't let an
  un-strippable confound read as "no uplift."
- **Isolate mutating subjects.** If the subject's *task* writes files or runs shared-state
  tooling (coverage, builds, servers) — not just emits prose — run each subject/control arm
  in its own worktree (`isolation: "worktree"`). Concurrent probes in one working tree
  corrupt each other (e.g. vitest's shared `coverage/.tmp reportsDirectory`: "don't run
  multiple Vitests with the same reportsDirectory") and leave stray edits that dirty both
  the real repo and the measurement. Pure-output subjects (a writeup, a diagnosis) have no
  such side effects — run them concurrently in-cwd.
- **Head-to-head fairness, don't overfit.** Run the identical set against each skill and
  compare near-miss precision, not raw trigger-rate (which favors the broader description);
  don't tune the rewrite until these specific probes pass — they're a proxy.

## Tiers

- **sentinel** — fast triggering smoke (~3 reps, positives only, no control/grading): "did
  my edit break triggering?" Cheap; not a verdict.
- **full** — triggering (control + ≥5 reps + near-miss negatives + variance) **and**
  effectiveness (ACs + blind A/B vs control). Default for "is it good?" / "is the new
  version better?"

## Verdict + output

Per `(scenario, skill, arm, rep)`: **pass / fail / indeterminate** (indeterminate = empty
capture, harness breakage, errored subject).

**Where the pack lives — one deterministic home, never a scratch/cwd/`/tmp`/random dir.** The
eval pack (its `README.md` + `fixtures/` + recorded results) is a permanent, committed
artifact and MUST land in a skill's `evals/` tree:
- Subject is a **local, writable skill you own** → `<that-skill-dir>/evals/`.
- Subject is **external** — an installed plugin, a closed PR, or a head-to-head of several
  skills → pack it into *this* skill: `dotclaude/skills/evaluating-skills/evals/<subject-slug>/`,
  recording each subject's source + version/commit.

If unsure, use the second. Writing the pack under the working directory, `/tmp`, or a fresh
folder is the main way eval evidence gets orphaned — don't. And keep the pack
**self-contained**: the recorded-results tables + quoted rationale + fixtures ARE the durable
evidence. Raw transcripts (`~/.claude/projects/<slug>/<sessionId>/subagents/agent-<id>.jsonl`)
are ephemeral session artifacts — cite their agentIds, but capture every finding in the
README; never leave it as "see transcript."

Use the `dotclaude/skills/double-check/evals` "Recorded results" shape: a
`baseline | with-skill | lift` table (effectiveness), a trigger-rate table with the control
column and near-miss precision (triggering), quoted judge rationale, the subject
version/commit, links to raw transcripts, a one-paragraph **meta-finding** (where the skill
flips fail→pass vs only adds structure), a **threats-to-validity** line (honest rep count /
small-N labeling), and a **REFACTOR applied + re-tested** entry whenever a rewrite lands.

## See also

- `references/eval-pack-template.md` — the reusable pack skeleton (arms, observable ACs,
  trace-check verbs, the trap list).
- `evals/` — a worked example: a head-to-head of two same-domain standards skills.
- `superpowers:writing-skills` — the rewrite (this skill delegates to it).
- `superpowers:dispatching-parallel-agents` — running reps and judges concurrently.
- `dotclaude/skills/double-check/evals/` — the reference implementation to match.
