---
name: red-team-testing
description: Use when you need to know whether a spec, plan, design, or solution is *actually* correct rather than merely plausible, especially your own work, where you are anchored on the answer you already believe. Triggers include "red-team this", "try to break this", "find the edge cases", "find devious tests", "is this actually correct", "prove this wrong", or before trusting/implementing a spec or plan. Not for prose accuracy (use double-check) or reviewing a code diff (use pr-review).
---

# Red-Team Testing

## Core principle

**You cannot red-team your work from inside the context that produced it.** You are
anchored on the answer you already believe, so re-reading it "carefully" only
re-confirms it. Correctness comes from an **independent agent that re-derives the
expected behavior from the requirements alone**, then attacks the solution. Not from
you looking harder.

The whole skill is one move done well: split off a clean-room subagent, hand it the
requirements *stripped of every answer*, make it compute the right behavior itself,
then reconcile what it finds against what you claimed.

## When to use

Run this against a **spec, plan, design, or non-trivial solution** whose correctness
matters and that you are about to trust, implement, or call done. Most urgently when
**you** wrote it. It is also the standalone form of `double-check`'s Pass 4/5, for when
you want *just* the adversarial clean-room test without the accuracy, style, and expert
passes.

The artifact under test can itself be a skill or a prompt: strip its claimed effect,
and have the clean-room agent design the pressure scenarios that would break it.

**Not for:** prose factual accuracy (use `double-check`); reviewing a code diff (use
`pr-review`); a trivial change with no edge surface.

## The one thing capable models still get wrong

A strong model, asked directly "is this correct?", already finds null, empty, boundary,
and concurrency edges for free. That is not the hard problem. Two failures survive:

1. **Self-review.** You review your own work in your own context and confirm it does
   what you *intended*. You never test whether the intention was right. The clean-room
   split is the only reliable fix.
2. **Poisoning the clean-room.** When you do dispatch an independent agent, you hand it
   the spec's proposed implementation and stated answers, and it faithfully encodes your
   bug into "green" tests. **Stripping the anchor is the whole game.**

## The recipe

### 1. Strip the anchor into a requirements-only residue

Copy the artifact and **delete** every part that carries a proposed answer:

- proposed implementation, pseudocode, function signatures, query, algorithm
- worked examples and their computed results
- stated expected values and acceptance-criteria numbers you'd assert on
- proposed tests
- your own hunch about the approach, file, or design

**Keep only** the goal, the rules and constraints stated abstractly, and the raw inputs
(numbers *with no stated answer attached*).

> **Strip, don't quarantine.** Labeling a wrong value "unverified, check this" and
> pasting it anyway does **not** work: the clean-room agent reads the stated answer
> before it derives its own, and it anchors on the number it read. A value that isn't in
> the prompt cannot anchor anyone. If you need the spec's numbers to reconcile later,
> keep them in **your** notes, out of the subagent's brief.

### 2. Dispatch a clean-room subagent with the residue

Fresh subagent, no shared context. Give it the residue and these standing orders:

- **Derive every expected value yourself** from the goal and the raw inputs. Show the
  arithmetic. There is no pre-stated answer to copy.
- **Assert only externally observable behavior:** outputs, events, invariants. Not
  internal types, private helpers, or storage details.
- **Name ambiguities, don't guess them.** Where a requirement is unclear, write a test
  that names the ambiguity instead of picking an answer.
- **Bail if the brief leaks an answer.** If anything in the brief hands you a result
  instead of making you derive it (a stated expected value, a computed worked example, a
  proposed implementation or query, a ready-made test), **stop and report that the brief
  looks poisoned, naming exactly what leaked.** Do not work around it or encode it. A
  leaked answer means the dispatch was set up wrong and must be re-stripped and re-sent.
  Raw inputs with no answer attached are fine; deriving from those is the job.

The last order is a **backstop, not the primary control.** Stripping (step 1) keeps the
poison out; the tripwire only catches an incomplete strip. Put the tripwire order in
every clean-room brief so operator error fails loud instead of silently encoding the bug.

### 3. Point the red-team lens (the lateral thinking)

Tell the clean-room agent to hunt, at minimum:

- **Boundaries and off-by-one:** exactly-at-threshold, first, last, one-past.
- **Degenerate inputs:** empty, null, zero, negative, one, duplicate, enormous.
- **Every fuzzy word:** pin the definition of "activity", "day", "recent", "done". What
  edge case does the loose word smuggle in?
- **Time:** timezone, DST, leap day, clock skew, non-monotonic clock, ordering.
- **Concurrency and partial failure:** two runners, a crash between step N and N+1, a
  retry, a read-then-act race on the value you gate on.
- **The adversary:** who benefits if this is subtly wrong, and what input do they send?
  Money, auth, and deletion paths especially.
- **Invariants that must always hold:** conservation (the parts sum to the whole),
  monotonicity (more X never yields less Y), bounds (never below 0, never above max).
- **Steelman the opposite.** State the design's central claim in one sentence, then
  build the strongest case that it is wrong, incomplete, or solving the wrong problem.
  Attack the *framing*, not just the content: did it answer a narrower question than was
  asked? Was the method confirmatory, built to return the answer it got? What got
  dismissed by category instead of examined? Name the disconfirming fact that would flip
  the conclusion, and check whether anyone actually went looking for it.

### 4. Reconcile (trust nothing yet, not even the clean-room agent)

- Compare each value the clean-room agent derived against what your spec asserts.
  **Every mismatch is a finding.** Resolve which is right by the rule, not by which is
  written down more confidently.
- **Sanity-check each returned test yourself.** Is it actually observable? Does it follow
  from the goal? Discard white-box assertions, off-topic UI checks, and invented expected
  values. The clean-room agent hallucinates too.
- **Rate each finding load-bearing or inert.** Load-bearing changes the design or the
  action; clever-but-inert sounds sharp and changes nothing. Keep only the load-bearing.
  Manufacturing critiques to look rigorous is the rubber-stamp failure inverted. And a
  pass that finds **nothing** on a non-trivial artifact is itself a rubber-stamp signal:
  re-attack the framing and the fuzzy words, not just the numbers.

## Boundaries

| Always | Ask first | Never |
|---|---|---|
| Dispatch a *fresh* subagent; never self-review in the producing context | Whether the artifact is big enough to warrant the pass | Paste the proposed implementation or stated answers into the brief |
| Strip proposed implementation and stated values out of the brief | Whether to loop a second clean-room round after a big finding | Keep a wrong value in the brief because it is "labeled unverified" |
| Make the subagent derive and show every expected value | | Encode a spec's stated number as a test's expected value without deriving it |
| Sanity-check every returned test for observability | | Trust the clean-room agent's output without reconciling it |

## Rationalizations (stop if you think these)

| Excuse | Reality |
|---|---|
| "I'll just review it carefully myself." | Self-review confirms intent, not correctness. You are anchored. Split it off. |
| "The subagent writes better tests if I give it the proposed code and expected values." | That poisons it: it encodes your bug into green tests. Give the goal and raw inputs only, and make it derive. |
| "I'll keep the stated number but label it 'unverified'." | A labeled anchor still anchors. The agent reads the stated answer before it derives its own. Delete it from the brief. |
| "It found no problems, so it's correct." | Zero findings on a non-trivial artifact is a rubber-stamp signal. Re-attack the framing and the fuzzy words. |
| "The clean-room agent's suite looks thorough." | Thorough is not correct. It hallucinates expected values and asserts unobservable things. Reconcile and sanity-check each. |
| "The model already finds edge cases, so I can skip the split." | It finds *generic* edges in-context. It will not catch the answer it is anchored on. The split is what catches that one. |

## Report format

Lead with a one-line verdict: **correct as specified**, **has defects**, or
**unresolved ambiguities**. Then:

- **Contradictions:** each stated value the clean-room derivation disagreed with, the
  rule-correct value, and the arithmetic.
- **Edges and devious cases:** the boundary, degenerate, concurrency, time, and adversary
  cases that break it or go unhandled.
- **Steelman:** the strongest case that the design is wrong or solving the wrong problem,
  and whether it survived.
- **Discarded:** clean-room tests you threw out as unobservable or hallucinated, and why.
