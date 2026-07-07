---
name: double-check
description: Use when you ask to double-check, fact-check, vet, or sanity-review something just written before relying on or sending it. Verifies every claim against primary sources/code, runs a write-gooder style pass, vets with expert agents WITHOUT trusting them, and clean-room tests specs/plans. Invoke-only — never auto-fires.
---

# Double Check

## Core principle

**Verify from the source, not from memory of it.** Trust nothing yet — not your own
draft, not the expert agents, not the clean-room subagent — until each claim is
checked against ground truth. A careful author and a verified document are not the
same thing; this skill is what makes them the same.

## When to use

Run this after producing a non-trivial written artifact the user will rely on or
send: a summary, design note, spec, plan, PR body, runbook, README, or standard.

**Not for:** trivial/conversational replies; reviewing a code diff (use `pr-review`);
running test/lint/format gates (use `quality-check`).

## The passes

Always run Pass 1 and Pass 2. Run Pass 3 if relevant experts exist. Run Pass 4 only
when the artifact is a spec or a plan. Run Pass 5 whenever the artifact reaches a
conclusion or makes a recommendation the reader will act on.

### Pass 1 — Accuracy against ground truth

1. List every checkable claim: numbers, account/entity IDs, API behavior, version
   facts, cited `file:line`, config values, quoted standards, command flags.
2. For each claim, **open the actual source** — the primary doc, internal reference,
   code path, or live NRDB query — and compare. Re-reading your own draft is not
   verification; memory of the source is not the source.
3. Exit criterion: every claim is marked `verified-against-<X>`,
   `contradicted-by-<X>`, or `unverifiable`.
4. A claim you cannot trace to a source does not stand as asserted fact — flag it
   `unverifiable` and say so in the report. Do not infer to fill the gap.

### Pass 2 — write-gooder style pass

1. Invoke the `write-gooder` skill and route to the template matching the artifact
   (PR, CDD, IDD, README, runbook, standard, CLAUDE.md, SKILL.md). For a quick
   tic-only sweep, `avoid-ai-writing` is enough.
2. Check AI tells, length (the cut-by-half test), audience fit, and whether the
   first paragraph carries the point.
3. Exit criterion: the artifact passes write-gooder's self-check.

### Pass 3 — Expert vetting (only if relevant experts exist)

1. `ls .claude/agents/` to read the roster — this surfaces both repo-local experts
   and symlinked ones (e.g. `nrql-expert`, `spl-expert`, `datadog-expert` from
   `../nr-query-bridge`). Pick the ones whose domain the artifact actually touches.
2. Dispatch them on Opus. Tell each it may load `write-gooder` if it will comment on
   writing quality.
3. **Verify every claim an expert makes against ground truth before acting on it.**
   Experts routinely lack the context this session has and assert confidently-wrong
   things. Treat their output as leads to check, never as verdicts to apply. (A
   baseline run had a "security expert" insist env-vars were approved secret storage
   and that AES-128 was the at-rest standard — both wrong.)

### Pass 4 — Clean-room test suite (specs and plans only)

1. Dispatch a **fresh subagent** (no shared context) to write a prose test suite:
   the observable outputs and invariants a correct implementation or document would
   exhibit.
2. Give it the **goal, behavior, and acceptance criteria** — but **strip or clearly
   mark any proposed implementation** the spec carries (queries, function signatures,
   example tests, stated expected values) so the subagent cannot anchor on it. Add no
   design hints of your own either (files, functions, your expected approach).
3. Instruct it to **compute every expected value itself from the inputs, never
   trusting a number written in the spec**. Anchoring on the spec's own proposed
   implementation or stated numbers is exactly the poisoning this pass exists to
   avoid — a clean-room agent handed a wrong "expected" value will faithfully encode
   the bug into its tests.
4. **Sanity-check each returned test yourself**: is it actually observable? does it
   follow from the goal? Discard nonsense and unobservable assertions.
5. Run the surviving tests past the expert agents too — and Pass 3's verify rule
   still applies to whatever they say back.

### Pass 5 — Adversarial / critical review (only if the artifact reaches a conclusion or recommendation)

Passes 1–3 prove the claims are *true*; this pass asks whether the conclusion is
*sound*. A document can pass every factual check and still be wrong in its framing,
scope, or recommendation — verified-but-complacent. Fact-checking cannot catch that;
only attacking the conclusion can.

1. State the artifact's central claim or recommendation in one sentence.
2. **Steelman the opposite.** Build the strongest case that the conclusion is wrong,
   incomplete, or solving the wrong problem. If you cannot argue the opposite, you do
   not understand your own claim well enough to trust it.
3. **Attack the framing, not just the content.** Did you answer a narrower question
   than was asked? Was the method confirmatory — designed to return the answer you
   got? What did you dismiss by category instead of examining?
4. **Name the disconfirming evidence.** What fact, if it existed, would flip the
   conclusion — and did you actually go look for it?
5. **Rate each critique** load-bearing (changes the conclusion or the action) vs.
   clever-but-inert (sounds sharp, changes nothing). Discard the inert — manufacturing
   critiques to look rigorous is the same failure as rubber-stamping, inverted.

Exit criterion: the conclusion either survives a genuine steelman of its opposite, or
you revise it. Zero load-bearing critiques on a non-trivial recommendation is a
rubber-stamp signal — re-attack the framing and the search design, not just the claims.

## Boundaries

| Always | Ask first | Never |
|---|---|---|
| Open the real source for every claim (Pass 1) | Whether to run Pass 4 if the artifact's spec/plan status is ambiguous | Mark a claim verified from memory |
| Run the write-gooder pass (Pass 2) | Whether to dispatch experts if the topic is borderline | Apply an expert's claim without checking it |
| Report what you could NOT verify | — | Feed the clean-room subagent the spec's proposed implementation or stated answer values |
| Steelman the opposite of any conclusion (Pass 5) | — | Manufacture critiques to perform rigor |

## Rationalizations — stop if you think these

| Excuse | Reality |
|---|---|
| "I wrote it carefully, it's fine." | Careful authoring ≠ verified. Open the source. |
| "The source says what I remember." | Then opening it costs seconds and removes all doubt. Open it. |
| "The expert approved it, ship it." | Experts are confidently wrong without context. Verify the claim, not the sign-off. |
| "I'll give the clean-room agent the spec's query / expected values so it writes better tests." | That poisons it — it will encode the spec's bugs. Give it the goal and requirements only, and make it compute its own expected values. |
| "The clean-room tests look thorough." | Thorough ≠ correct. A test for an unobservable thing is noise. Sanity-check each. |
| "It's only a README, skip the tests." | Correct — Pass 4 is specs/plans only. Still run Passes 1 and 2. |
| "My double-check found nothing to change." | A zero-change pass across multiple artifacts is a rubber-stamp signal, not a clean bill — it usually means you verified from memory, not source. Re-open each cited source and hunt specifically for over-claims and stale line/number references; a real pass on a non-trivial artifact almost always finds something. |
| "It passed accuracy and the experts, so it's sound." | Verified-true ≠ sound. A conclusion can be factually airtight and still complacent, narrowly framed, or answering the wrong question. Steelman its opposite before trusting it (Pass 5). |

## Report format

Lead with a one-line verdict: **send** or **don't send**. Then:

- **Pass 1 (accuracy):** claims contradicted by source (with the source), and claims
  left `unverifiable`.
- **Pass 2 (style):** the fixes write-gooder surfaced.
- **Pass 3 (experts):** findings you verified and kept, plus any you rejected and why.
- **Pass 4 (clean-room, specs/plans):** the surviving tests; note any you discarded
  and the reason.
- **Pass 5 (adversarial):** the strongest counter-case to the conclusion, and whether
  it survived intact or was revised.
