# Eval pack template

Skeleton for an `evals/README.md` that measures a skill on both axes. Copy it, fill the
brackets, delete the guidance. Generalizes `dotclaude/skills/double-check/evals/README.md`
(a discipline-skill pack) by adding the **triggering axis** and the optional **blind A/B**.
Keep the pack self-contained and model-portable: fixtures + verbatim prompts + objective
rubrics a fresh model (or a judge subagent) can run.

## 0. Subject, type, arms

- **Subject:** `<skill name>` (+ source + version/commit).
- **Where this pack lives** (pick one, never cwd/`/tmp`/a scratch dir): a **local writable
  subject** → `<subject-skill-dir>/evals/`; an **external subject** (installed plugin / closed
  PR / head-to-head) → `dotclaude/skills/evaluating-skills/evals/<subject-slug>/`. Self-contained
  — the tables + rationale + fixtures are the durable evidence; transcript agentIds are
  ephemeral pointers.
- **Type** (from `evaluating-skills` Step 0): discipline / technique / pattern / reference →
  scenario style: pressure / application / recognition+counter-example / retrieval+gap.
- **Arms:** *baseline* = control (no skill, **clean context, forced retrieval**) vs
  *with-skill* = the subject's full `SKILL.md` body **force-pasted** into the prompt. For a
  head-to-head, arms = skill A vs skill B (optionally both-present).

## 1. Scenarios (write acceptance criteria BEFORE running)

For each scenario:
- **Story** — a fenced, realistic prompt (real paths, casual phrasing). Names neither the
  skill nor its concepts, and does not lift wording from the description.
- **Expected trigger** — fire / silent (include near-miss negatives that share vocabulary
  but need something else).
- **Acceptance criteria** — what a good *output* must / must not do. Grade **output
  quality**, never "did it follow the skill's steps" (that passes by construction).
- **Reps** — sentinel ~3 (smoke), full ≥5 (verdict).

## 2. Triggering measurement

Trace-check verbs (Quorum vocabulary, kept portable):
- `skill-called <skill>` — the subject skill was loaded.
- `skill-before-implementation-tool <skill> <Edit|Write>` — loaded before the first
  implementation edit. (Vacuous-pass if no edit happened — pair with `skill-called`.)
- negative: the skill stays **silent** on the near-miss.

Mechanic: dispatch a fresh `general-purpose` subject subagent with the story (skill **not**
named); read its transcript at `~/.claude/projects/<slug>/<sessionId>/subagents/` for the
invocation. Empty transcript = **indeterminate**.

Measure **both** conditions — they answer different questions:
- **Competitive** (full live roster): who *wins* the surface. This is the default subagent run.
- **Isolated baseline** (skill alone): does the description match at all? Faithful version =
  clean-roster environment; cheap proxy = present *only* the description and ask "would you
  invoke it?" (a decision-to-load **upper bound** — it over-fires). Trust the *delta*: matches
  in isolation but loses competitively → suppressed by a neighbor, not misworded.
  **Prompt the proxy airtight:** say "assume this skill exists and is available; judge only
  whether the description matches the situation." Otherwise the subagent checks its *real* tool
  list, finds the skill absent, and answers NO — a misfire, not a real negative.

## 3. Effectiveness measurement

Run with-skill (force-paste) and control (clean), ≥reps each. Dispatch one separate
**judge** subagent (never a producer, never you): it grades each output against the
acceptance criteria (absolute pass/fail) and runs a **blind A/B** — labels stripped, order
randomized — picking the better + why.

## 4. Recorded results (the `double-check/evals` shape)

- **How to run** — portable preamble: paste `SKILL.md`, N reps, a fresh instance per rep.
- **Confound note** — control for loaded rules; if a rule that inlines the corpus can't be
  stripped, report lift as a **floor** (understated), not zero.
- **Effectiveness table** — `| scenario / AC | baseline | with-skill | lift |`.
- **Triggering table** — `| scenario | expected | fired n/reps | variance |` + **near-miss
  precision** (not raw trigger-rate).
- **Blind A/B** — winner per scenario + a **quoted** judge rationale.
- **Provenance** — subject version/commit + links to raw transcript paths.
- **Meta-finding** — one paragraph: where the skill flips fail→pass vs only adds structure.
- **Threats to validity** — rep count, small-N labeling, the dominant confound.
- **REFACTOR applied + re-tested** — only when a rewrite landed this cycle.

## Traps — read before trusting any result

- **Vacuous-pass:** `*-before-*` verbs pass when the anchor never fired — pair with a
  positive `skill-called`.
- **Empty capture:** no transcript → indeterminate, never pass/fail.
- **Fence the driver:** don't name the skill/its concepts; don't lift wording from the
  description (that tests memorization, not triggering).
- **Criteria before results:** write ACs first, or you'll bend them to the output.
- **Grade quality, not conformance:** never reward "followed the skill."
- **Blind the judge:** strip labels, randomize order; producer/parent never grade.
- **Control for loaded rules:** clean context + forced retrieval; un-strippable confound →
  lift is a floor.
- **Don't overfit:** don't tune the rewrite until these specific probes pass — proxy.
- **Small N:** sentinel is a smoke check, not a verdict.
