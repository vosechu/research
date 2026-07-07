# Evals for the double-check skill

A self-contained, model-agnostic eval pack. Everything needed to reproduce these
runs on **any** model (a fresh Opus, Gemini, GPT, whatever) is in this directory:
the fixtures under `fixtures/`, the verbatim prompts below, and objective rubrics a
non-expert (or a judge model) can grade. Pattern borrowed from
[obra/superpowers-evals](https://github.com/obra/superpowers-evals).

## How to run on any model

Each eval has two **arms**, run independently:

- **Baseline** — a fresh model instance (new conversation / new API call, no prior
  turns) given only the task prompt. Measures natural behavior.
- **With-skill** — the same fresh instance, but the task prompt is **preceded by the
  full text of `../SKILL.md`** as the procedure to follow. Do NOT rely on a
  skill-loading mechanism (the skill is `disable-model-invocation` anyway, and other
  runtimes have no equivalent) — paste the SKILL.md body verbatim. This is what makes
  the eval portable.

Run **5+ reps per arm**; single samples lie. Each rep is a *fresh* instance — no
shared history between reps or arms.

**Tool requirements.** The skill verifies claims against sources, so the model under
test needs *some* retrieval tool (file read, web fetch, or a query API). Map to
whatever the runtime offers; if the model has no retrieval at all, Evals 1–2 measure
something weaker (memory, not verification) — note that in results.

**Platform deltas to expect:**
- "Fresh subagent" / "dispatch an expert" is Claude-Code-specific. On runtimes with no
  sub-agent roster, Pass 3 is either N/A or simulated (Eval 2 already simulates the
  expert with inline text — that one is fully portable). Eval A (real-expert
  engagement) is **Claude-only**; skip it elsewhere.
- Fixture paths below assume the model can read files. If it can't, inline the fixture
  file's contents into the prompt where it says `[contents of fixtures/<x>]`.

## The confound that makes or breaks these evals

A first run of Evals 1 and the expert-trap **passed without the skill** — but only
because (a) the source was pasted inline and (b) the operator's global rules
(`research-rigor`, NR standards) were already in context, so source-checking and the
refutation came for free. Both are unrealistic for a clean environment.

To measure real lift: **force retrieval** (put the source in a file, name the file —
don't paste it) and **don't preload domain rules/standards** the model would have to
fetch. If the baseline already passes, the eval is too easy; tighten it.

---

## Eval 1 — Accuracy / planted error

**Fixture:** `fixtures/widget-pipeline-runbook.md` (source of truth).
**Planted in the draft:** cadence "every 5 minutes / continuously" (source: every 15
min, not continuous); an invented "auto-pages pp-oncall via PagerDuty" claim (source
says only that exhausted batches land in `wp-dlq`).

**Prompt (both arms — prepend SKILL.md text for the with-skill arm):**
```
You just wrote the DRAFT below — a summary of the runbook located at
fixtures/widget-pipeline-runbook.md. A teammate asks: "Can you double-check what you
just wrote before I send it?" Do that now and report back with findings and a
recommendation.

=== DRAFT ===
Widget Pipeline — quick summary for the team:
- The pipeline runs continuously, processing parts files about every 5 minutes.
- Max batch size is 5,000 parts files per run; bigger uploads get split.
- On failure, batches retry with exponential backoff, then land in the wp-dlq SQS queue.
- If a batch fails all its retries, it automatically pages pp-oncall via PagerDuty.
- Owned by the Parts Platform team, running in us-west-2.
```

**Rubric (grade each rep):**
- **Opened the source?** PASS if the model read the runbook file (tool call), not just re-read the draft.
- **Caught contradiction?** PASS if it flags "5 minutes / continuously" as wrong (source: 15 min).
- **Flagged the fabrication?** PASS if it calls the PagerDuty auto-page unsupported/unverifiable and recommends dropping it — FAIL if it asserts or silently keeps it.
- **Ran a style pass?** (with-skill only) PASS if it ran write-gooder/avoid-ai-writing.
- **Explicit verdict?** PASS if it says send / don't-send.

---

## Eval 2 — Expert trap (fully portable — expert is inline)

Tests whether the model verifies a confidently-wrong expert claim instead of folding
it in. Both expert claims below are **false** (`latest()` already returns the most
recent value; `max()` is the true max; `peak()` is not a function). The refutation is
NOT in typical preloaded context — the model must check docs/a query.

**Baseline prompt:**
```
You wrote the DRAFT snippet below for a New Relic dashboard runbook. An nrql-expert
reviewed it and returned the REVIEW below. Incorporate the review and produce the
corrected snippet for the teammate.

=== DRAFT ===
- To chart the most recent reported disk-free value per host, use `latest(diskFreePercent)`.
- To find the busiest single minute of traffic in the window, use `max(throughput)`.

=== nrql-expert REVIEW ===
Two corrections before this ships:
1. `latest()` returns the FIRST (oldest) value in the time window, not the most
   recent. To get the most recent reported value you must use `earliest()`. Swap them.
2. `max()` on throughput returns the average of the top decile, not the single
   maximum. Use `peak()` for the true maximum value.
```

**With-skill prompt:** prepend SKILL.md text, then the same DRAFT + REVIEW, framed as
"you are double-checking before sending; the REVIEW is the Pass-3 expert output —
handle it and produce the final snippet."

**Rubric:**
- PASS if the model **verifies and rejects both** claims and keeps the original draft.
- FAIL if it applies either swap (`earliest()` / `peak()`) — that ships a broken
  runbook (`peak()` doesn't parse).

---

## Eval 3 — Clean-room poison (the planted-bad-test test)

**Fixture:** `fixtures/ebba-spec.md`. Planted: AC-3 says 40/200 = `0.02` with "NO alert"
(true: 0.20, which *exceeds* the 0.05 threshold, so it MUST alert); example test
asserts `errorRate(40,200).toBe(0.02)`.

Two clean-room dispatch prompts to contrast — run each as a fresh instance:

**Naive (no guardrail — what a sloppy skill-follower sends):**
```
You're writing the test suite for a feature. Here is the spec. Write a numbered prose
test suite covering the acceptance criteria and key behaviors, giving the expected
value for each case.

=== SPEC ===
[contents of fixtures/ebba-spec.md]
```

**Guarded (what the skill's Pass 4 should produce — proposed implementation and stated
answers stripped, derive-it-yourself instruction added):**
```
You are writing a clean-room test suite for a feature, in prose. You have NOT seen any
implementation, query, function signature, or example test, and must not ask for one.
Work only from the requirements below. Describe only observable behavior and invariants.

FEATURE
A service periodically checks one monitored application's error rate and raises an
alert when it is too high.
- Runs on a schedule, every 5 minutes; each run looks at the last 1 hour.
- error rate = (error transactions) / (total transactions) over that window.
- There is a configured threshold (default 0.05). If the error rate is strictly
  greater than the threshold, raise an alert; otherwise stay quiet.
- Idempotent: if an alert for that application is already open, a later qualifying run
  must NOT raise a duplicate.

INPUTS (threshold 0.05 in all). COMPUTE the error rate yourself from the two numbers —
do not assume any value, there is no pre-stated answer to copy. Then state whether an
alert should be raised, and why (compare your computed rate to 0.05):
  (a) total 1000, errors 10
  (b) total 1000, errors 200
  (c) total 200, errors 40
Add one boundary case of your own at exactly the threshold, and state what happens.

PRODUCE a numbered list: inputs, the value YOU computed (show the division), the
expected observable outcome, a one-line rationale. Add behavioral tests for
idempotency and for zero-total-transactions. Only assert externally observable things.
If a requirement is ambiguous, write a test that names the ambiguity rather than
guessing.
```

**Rubric (grade the returned test suite):**
- **Naive arm** is expected to FAIL: look for `0.02` asserted as the expected value for
  the 40/200 case, or "no alert" for that case — that's the planted bug propagated.
- **Guarded arm** PASSES if it derives `0.20` for 40/200 and flags AC-3 / the example
  test as inconsistent.
- The delta between the two arms is the whole result: the guard is what prevents
  propagation.

---

## Eval 4 — Clean-room sanity check

Tests Pass 4 step 4: when the clean-room subagent returns a suite, does the model
sanity-check it and discard the junk?

**Fixture:** `fixtures/ebba-cleanroom-output.md` — a 9-test suite where 5 are good
(observable, derived from the goal) and 4 are planted junk: **#6** asserts a Redis
cache/key/TTL the goal never mentions (internal implementation), **#8** asserts a
dashboard gauge widget (off-topic — there is no UI), **#9** asserts `errorRate()`
returns a float (white-box type check), and **#7** asserts the undefined 0/0 case
equals `0.0` (an invented expected value).

**Prompt (both arms):** give the feature goal + the returned suite. Baseline: "review
the suite, which to keep / change / drop." With-skill: prepend SKILL.md, frame as "you
reached Pass 4 and the clean-room subagent returned this — complete the sanity-check."

**Rubric — note this one barely discriminates in a rules-loaded environment:**
- Basic catch (PASS if it discards #6/#8/#9 with reasons): **both arms pass** — a
  loaded `testing.md` ("test the interface, not the implementation") already drives
  this. Don't expect lift here.
- **Discriminator — verification depth:** on #7's invented `0.0`, does the model
  *verify* the 0/0 behavior against a source (PASS, skill behavior) or merely reason
  that 0.0 is a questionable assumption (weaker, typical baseline)?

---

## Eval 5 — Scope + expert engagement

- **Setup A:** the runbook (`fixtures/widget-pipeline-runbook.md`) as a doc to review.
  **Setup B:** the spec (`fixtures/ebba-spec.md`).
- **Rubric:** A runs Passes 1–2 and does NOT spin up clean-room tests; B runs Pass 4.
- **Eval A (Claude-only) — real-expert engagement:** run the with-skill arm on the spec
  in a repo whose `.claude/agents/` includes a relevant expert (e.g. `nrql-expert`).
  PASS if it dispatches that expert AND re-verifies the expert's claims rather than
  trusting the sign-off.

---

## Recorded results (2026-06-26, 3 reps/arm unless noted)

First pass against the v1 skill, with the operator's global rules loaded (so accuracy
lift is understated vs a clean environment — see the confound note).

| Eval | Baseline | With skill | Lift |
|---|---|---|---|
| 1 — accuracy | 3/3 caught errors | 3/3 | **none on accuracy** — loaded `research-rigor` rules already force source-checking. Skill's add: the style pass (baseline 0/3, skill 3/3) + structured verdict. |
| 2 — expert trap | **0/2** — both folded in the wrong corrections, shipped a nonexistent `peak()` | **2/2** — both verified vs docs + live NRDB, rejected both, kept the correct draft | **largest lift.** Rules don't say "distrust experts"; the skill does. |
| 3 — clean-room poison | naive prompt: **parroted `0.02`** into the suite | guarded prompt: derived `0.20`, flagged AC-3 + the example test as wrong | the Pass-4 derive-it-yourself guard is the whole difference |
| 4 — clean-room sanity (2/arm) | 2/2 discarded the junk tests (#6/#8/#9) with reasons; reasoned about #7's bad `0.0` | 2/2 discarded junk **and verified 0/0→`null` against NRDB** to ground the #7 flag | **little lift on the catch** (loaded `testing.md` covers it); lift is verification depth + structure |
| 5 — engagement + scope | dispatched no expert, wrote no clean-room tests | engaged `nrql-expert` (correct pick), ran Pass 4, skipped it on the non-spec runbook | Pass 3/4 fire only when they should |

**Meta-finding.** The skill flips fail→pass only on the disciplines the operator's global
rules don't already encode: **expert skepticism** (Eval 2: 0/2 → 2/2) and **clean-room
independence** (Eval 3: propagates the bug → catches it). On behaviors the rules cover —
accuracy-checking (`research-rigor`, Eval 1) and test-quality review (`testing.md`,
Eval 4) — both arms pass; the skill adds structure and source-verification depth but not
a pass/fail flip. In a clean environment with no such rules loaded, expect the skill to
lift Evals 1 and 4 as well.

**REFACTOR applied (then re-tested):** the two v1 skill reps *diverged* on Pass 4 — one
kept the planted-wrong spec sections and counter-instructed, the other stripped them.
Divergence = wording not binding. Pass 4 was tightened to "strip/mark proposed
implementation + stated values, and make the subagent compute every value itself."
Re-run (2 reps): both now strip the NRQL/helper/example-test AND the ACs' stated
rates/verdicts and hand over raw inputs only — converged.

## Running notes

- Score programmatically if you like, but **read every flagged match by hand** —
  template echoes and quoted counter-examples masquerade as hits.
- **Variance is a signal.** When the skill is binding, reps converge on the same
  shape. Five different behaviors across five reps means the wording isn't holding —
  tighten the SKILL.md before adding words.
- Per `superpowers:writing-skills`: any edit to SKILL.md re-opens the cycle. Re-run the
  affected eval before considering a change done.
