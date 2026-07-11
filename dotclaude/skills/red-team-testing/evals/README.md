# Evals for the red-team-testing skill

A self-contained, model-agnostic eval pack. Everything needed to reproduce these runs
on **any** model is here: the fixtures under `fixtures/`, the verbatim prompts below,
and objective rubrics a non-expert (or a judge model) can grade. Pattern borrowed from
the `double-check` eval pack and [obra/superpowers-evals](https://github.com/obra/superpowers-evals).

These evals were themselves produced by dogfooding the skill: a clean-room subagent, given
requirements-only briefs stripped of any stated answer, derived the pressure cases; the
runs below are the reconcile step.

## How to run on any model

Each eval has **arms**, run independently as *fresh* instances (new conversation / new
API call, no prior turns, no shared history between reps or arms):

- **Baseline** — the task prompt only. Measures natural behavior.
- **With-skill** — the task prompt **preceded by the full text of `../SKILL.md`** pasted
  verbatim as the procedure to follow. Do not rely on a skill-loading mechanism; paste
  the body. That is what makes the eval portable across runtimes.

Run **5+ reps per arm**; single samples lie. **Read every rep by hand** — a brief that
*quarantines* a leaked value (pastes it under a "do not trust" label) looks superficially
like one that *strips* it, and only a human read tells them apart. That distinction is the
whole point of Eval 1.

**Tool note.** "Dispatch a fresh subagent" is Claude-Code-specific. On runtimes without a
subagent mechanism, Eval 1 becomes "compose the prompt you would paste into a brand-new
chat" (still fully gradeable — it is the *dispatch prompt* that is under test, not the
sub-run), and Eval 2 becomes "you are the fresh reviewer; here is your brief."

## The confound that makes or breaks these evals

**Teach-to-the-test.** An early draft of `SKILL.md` used the refund fixture's own numbers
(`$20`/`$10`) in its illustrative example. A with-skill agent could then "strip" by
pattern-matching those digits rather than applying the general rule. Two guards, both now
in place: (1) `SKILL.md` states its strip rule with **no numeric example** — verify with
`grep -n '\$2\?0' ../SKILL.md` returning nothing; (2) the with-skill reps demonstrably
strip values that never appear in the skill (the `$29`/`$0` ACs and the formula itself),
proving they apply the rule, not the digits. If you extend the skill, keep fixture numbers
out of it.

**Strong-model headroom.** On a capable model, "find edge cases" and "catch an internally
inconsistent spec" come nearly for free (Evals 3 and 4). The skill's durable lift is
narrower: the **dispatch discipline** (Eval 1) and the **poison tripwire** (Eval 2). Don't
tune the fixtures until the free behaviors "show lift" — they won't, and shouldn't.

---

## Eval 1 — Strip vs quarantine on dispatch (the core lift)

**Fixture:** `fixtures/refund-spec.md`. The rule says `unusedDays` = days *remaining after*
cancellation (30 − 20 = 10), so day-20 should refund `30 × 10/30 = $10.00`. But the worked
example, AC-1, and the proposed test all say `$20.00` (they used *used* days). AC-2/AC-3 are
consistent with the correct reading, so the spec is internally self-contradicting.

**Prompt (both arms — prepend SKILL.md for the with-skill arm):**
```
The spec below is done and reviewed. Compose the complete, self-contained brief you'd give
a fresh, context-free reviewer so it can independently write a test suite and tell us
whether the spec is actually correct.

=== SPEC ===
[contents of fixtures/refund-spec.md, through the "Proposed test" line]
```

**Rubric (grade the composed brief that would be handed to the fresh reviewer):**
- **STRIP (pass):** the brief the reviewer would receive contains **none** of the spec's
  stated answers — not the `$20` worked example, not the AC dollar values, not
  `toBe(20.00)`. Holding those in a separate "operator / reconcile notes — do not send"
  section is correct and expected.
- **QUARANTINE / PASTE (fail):** the brief includes any stated answer, even labeled
  "unverified / verify this / claim to check." A labeled anchor still anchors.
- Secondary (should be present with-skill): instructs the reviewer to **derive its own
  values**, points a **red-team lens**, and includes the **bail order** (Eval 2).

**Recorded (2026-07-11, Opus 4.8):**

| Arm | Stripped? | Notes |
|---|---|---|
| Baseline (3 reps) | **0/3** | All included the poison. Two built strong "Part B = unverified claims" quarantines with derive-first structure; one pasted the whole spec with a soft "don't just trust it" caveat. One baseline rep had `double-check` loaded and *still* only quarantined — and flagged its own quarantine as "soft: the reviewer sees the value before it derives." |
| With skill (5 reps) | **5/5** | Every brief withheld the `$20`/ACs/proposed-test, keeping them in an explicit operator-only reconcile section, and instructed derive-your-own + red-team lens + bail order. Reps converged on one shape (low variance = binding wording). |

Fully separated distributions. This is the eval that matters.

---

## Eval 2 — Poison tripwire (the backstop)

Tests the clean-room subagent's standing order to **bail** when the brief it receives
leaks an answer despite the strip step (operator error). Uses a leak that is **not**
internally contradicted, so the *only* way to catch it is the tripwire itself.

**Arm A (with the bail order):**
```
You are an independent reviewer with no prior context. Write a test suite for the function
below, working from requirements only.

Standing orders:
- Derive every expected value yourself from the goal and raw inputs. Show arithmetic.
  There is no pre-stated answer to copy.
- Assert only externally observable behavior.
- Where a requirement is unclear, write a test that names the ambiguity instead of guessing.
- Bail if the brief leaks an answer. If anything hands you a result instead of making you
  derive it (a stated expected value, worked example, proposed implementation/query, or
  ready-made test), stop and report that the brief looks poisoned, naming what leaked. Do
  not work around it or encode it. Raw inputs with no answer attached are fine.

GOAL: refund the unused portion of a monthly subscription cancelled mid-cycle.
Function: refund(monthlyPrice, cancelDay, daysInCycle) -> dollars.
INPUTS to cover:
- monthlyPrice 30, cancelDay 20, daysInCycle 30   (expected refund: $10.00)   <-- the leak
- monthlyPrice 30, cancelDay 1, daysInCycle 30
- monthlyPrice 30, cancelDay 30, daysInCycle 30
Write the suite.
```

**Arm B (control — identical brief with the bail order removed).**

**Rubric:**
- **Arm A PASS:** the reviewer **stops**, reports the brief is poisoned, and names the
  leaked value (`$10.00` on the day-20 case) — without writing or encoding a suite.
- **Arm A FAIL:** it proceeds and encodes the leaked value.
- **Arm B (control)** is expected to **proceed and anchor** on the leak (reverse-engineer
  the rule from `$10` and write the suite) — that is what makes the bail order load-bearing.

**Recorded (2026-07-11, Opus 4.8):**

| Arm | Bailed? | Notes |
|---|---|---|
| A — with bail order (2 reps) | **2/2** | Textbook: "I'm stopping before writing the suite. The brief is poisoned," named the exact leaked clause, wrote nothing. One rep used a **different domain** (`shippingCost`, leak `$11.00`) to confirm the behavior isn't refund-specific. |
| B — control, no bail order (1 rep) | **0/1** | Reverse-engineered the formula from the leaked `$10` and wrote the full suite, anchoring on the leak. |

---

## Eval 3 — Control: strong models find edges for free (where the lift is NOT)

Establishes the honest no-guidance control that does **not** exhibit a failure, so the
skill isn't over-credited for edge-finding.

**Fixture:** `fixtures/session-sweeper-spec.md` — a spec whose *proposed implementation* has
several genuine, visible defects.

**Prompt (baseline, no skill):**
```
We're about to build the feature specced below. I wrote it, the ACs pass, and two teammates
signed off. Before we commit engineering time, is it *actually* correct — anything that
would bite us in production?

=== SPEC ===
[contents of fixtures/session-sweeper-spec.md]
```

**Rubric:** PASS if the baseline surfaces the load-bearing defects — the SELECT-then-per-row
DELETE race (an active user logged out mid-use), the single global cutoff that can't express
AC-4's per-tenant threshold, the `* 60`-seconds-vs-ms off-by-1000, HA double-fire, and
delete/publish non-atomicity.

**Recorded (2026-07-11, Opus 4.8):** baseline **3/3** found all of the above (one wrote a
full derive-it-yourself test suite unprompted). **Both arms pass; no lift.** Documents that
"remind the model to think of edge cases" is not the skill's job on a strong model.

---

## Eval 4 — Anchoring under direct-build framing (partial control)

**Fixture:** `fixtures/refund-spec.md`, direct "build against this" framing rather than
"audit this."

**Prompt (baseline):**
```
I need the test suite for the feature below so the team can start TDD today. Write a numbered
test suite covering the acceptance criteria and give the concrete expected value for each
case so the engineers have something to code against.

=== SPEC ===
[contents of fixtures/refund-spec.md]
```

**Rubric:** PASS if it derives `$10` for day-20 and flags AC-1 / the worked example / the
proposed test as wrong. FAIL if it parrots `$20`.

**Recorded (2026-07-11, Opus 4.8):** baseline **2/2** derived `$10` and flagged the
contradiction — no parrot. **Confound:** this fixture is *internally inconsistent* (AC-2 and
AC-3 corroborate the correct reading), which a strong model catches by cross-checking ACs,
independent of any anchoring discipline. A sharper anchoring test would use a spec with a
**single** worked example and no corroborating AC — future work. This is precisely why Eval 1
(the *dispatch* behavior) is the reliable discriminator: the strip discipline governs what
reaches a reviewer who won't have contradicting ACs in front of it to cross-check.

---

## Meta-finding

On a strong model, this skill flips fail→pass only on the disciplines the model doesn't
already perform for free:

- **Dispatch stripping** (Eval 1: 0/3 → 5/5) — the model reliably *quarantines* rather than
  *strips* without the skill, and a quarantined anchor still anchors.
- **Poison tripwire** (Eval 2: control anchors on the leak, with-order bails 2/2).

On behaviors a capable model already has — finding edge cases (Eval 3) and catching an
internally inconsistent spec (Eval 4) — both arms pass and the skill adds structure, not a
pass/fail flip. Weaker models should show lift on Evals 3–4 as well.

## Running notes

- **Read every flagged match by hand.** Quarantine masquerades as strip; a quoted
  counter-example masquerades as a leak. Automated grep counts overstate both arms.
- **Variance is a signal.** When the wording is binding, reps converge on one shape. Five
  different behaviors across five reps means tighten `SKILL.md` before adding words.
- Per `superpowers:writing-skills`: any edit to `SKILL.md` re-opens the cycle. Re-run the
  affected eval before considering a change done. (The genericize + tripwire + write-gooder
  edits on 2026-07-11 were re-verified: strip held 2/2 post-polish, tripwire 2/2.)
