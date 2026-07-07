# Change Design Document template

A CDD exists to **help a reviewer push back on architecture, risk, or scope before code gets written**. It's the design artifact a team circulates for review between a spec and a PR. If a reviewer can't, after reading it, say "I'd change X" or "this is fine," the CDD failed.

A CDD is not a spec, a PR body, a status update, or a pitch. It does not narrate commit-by-commit work, explain implementation line-by-line, or close with significance. Those belong elsewhere (spec, PR, status doc, nowhere).

## Relationship to the NR canonical CDD template

This template is a **style overlay** on top of New Relic's canonical [CDD template](https://newrelic.atlassian.net/wiki/spaces/STAN/pages/5575442599) (STAN space, page 5575442599). Use the canonical template for the structural scaffolding — the status / impact / risk-level / effort-to-reverse header table, the STRIDE threat-modeling table, the APIs + Object Definitions tables, the Teams table, the Reviewers protocol. Those are required artifacts that SLCRev and architecture review lean on.

What this template adds on top:

- A falsifiable problem framing with measurable success criteria, so a reviewer can disagree with the framing instead of nit-picking the solution.
- A sparing alternatives section — include a real fork only when the reader needs it; a wide option space is a DACI signal, not a CDD heading.
- An unticked human-read-through checkbox plus an AI-tell scrub, so the author signals commitment and the prose sounds human before the reviewer spends time.
- An honest consequences/risk/tradeoffs section that names the worst case and the cost you're accepting, not the reassurance.
- A review checklist that directs the reviewer's eye to the load-bearing calls, saving their time.

The two templates are compatible. Fill in the canonical header, threat model, and API tables as usual; apply the discipline below to the prose sections (Context / Problem Statement, Design, Considerations and Consequences, Rollout, Other Solutions Considered, Decision).

## Structure

The spine below is ordered for a cold reviewer's scan. Any section can be short or empty when there's nothing to say — "no alternatives were viable" is a valid answer, "we haven't written the rollout yet" is not.

### 1. Summary

Two to four sentences: the problem, the proposed approach, and the load-bearing constraint. Front-loaded so a reviewer who reads only this paragraph walks away with the decision.

- **What to put in:** what's broken or missing today, what you propose to do about it, what constrains the choice (budget, deadline, compatibility, blast radius).
- **What to keep out:** history, motivation narratives, any sentence that starts "This document describes…"

Example that lands:

> Log ingest meter currently double-counts bytes on retry, inflating the staging
> bill by ~8% (validated on the staging billing account, two weeks). We propose switching
> the meter from per-attempt to per-accepted-record at the Kafka consumer, and
> backfilling the last 30 days from `tdp.usage`. Constraint: the fix must land
> before the May billing cutover on the 28th, so a full consumer rewrite is out.

One concrete problem, one concrete approach, one concrete constraint, four sentences.

### 2. Human read-through checkbox

Unticked by default, at the top so reviewers see it before the detail:

```markdown
- [ ] I, the human author, have read this end-to-end and stand behind it. Until this is checked, please don't spend time reviewing.
```

If it's unticked, the author hasn't committed to the draft yet and the reviewer should come back. The wording is deliberate: "stand behind it" raises the social cost of circulating unread AI output.

**The CDD must sound human, even if an LLM helped draft it.** Reviewers can't engage with prose you haven't digested yourself, and AI-tell prose reads as un-owned. Before you tick the box, scrub the draft for LLM tells — puffery ("crucial," "underscores," "pivotal"), pivot-phrases ("serves as," "setting the stage for"), reflexive rules-of-three, "not just X, but also Y," and closing-significance statements. Run the `avoid-ai-writing` skill as a final pass; it's a tight tell-check list built for exactly this. Ticking the read-through box without doing this defeats the box's purpose.

### 3. Problem

What we're solving, for whom, how we know, and what "solved" looks like.

- **What to put in:** the observable symptom, the users or systems affected, the measurement (query, metric, incident, customer report) that shows it's real, and the success criteria — stated as technical goals in technical terms.
- **What to keep out:** the solution, the team history, "we've been wanting to do this for a while." Don't frame the problem as "we don't have the solution yet."

The problem must be concrete and bounded: a reviewer should be able to read it and know what the success criteria are. State them measurably ("p95 backfill under 5 min," "double-count delta ≤0.5%"), not aspirationally ("improve performance"). A measurable bar is what lets a reviewer later confirm the design actually closes the problem.

Carry the reader through your chain of reasoning — "we moved X to Y, which makes Z necessary" — so they arrive at the same conclusion you did. But resist a paragraph per link in the chain: conciseness is what makes the document digestible, and that goal outranks completeness here and everywhere in the CDD. A tight chain the reviewer can follow beats an exhaustive one they skim.

A reviewer who disagrees with the problem framing here will disagree with everything downstream. Make the framing falsifiable.

### 4. Proposed approach

The decision, not the options. A reviewer should be able to tell what you'd build without guessing.

- **What to put in:** the architecture, the components that change, the contract changes, the data flow in the shape a reviewer needs to reason about.
- **What to keep out:** the options you rejected (those go in the next section), line-level implementation detail (that's the PR's job).

Diagrams, tables, and short code snippets are fine when they compress better than prose. A wall of text is a smell.

Keep anything you want feedback on in normal text. Confluence doesn't allow comments inside code blocks, so a long block of code or config becomes a review dead zone — reviewers can't mark the line they'd change. Short snippets are fine; if a block is long enough that a reviewer would want to comment on a specific line, restate that line in prose or a table where they can.

### 5. Alternatives considered

**Use this section sparingly — it is not mandatory, and it can distract from the solution.** Include an alternative only when a real fork existed and the reader needs to see why you took one branch over another.

- **A wide option space is a DACI signal, not a CDD section.** If there are several genuinely-competing approaches still in play, write a DACI first and decide there; the CDD documents the decision, it shouldn't relitigate it.
- **Cut quickly-rejected alternatives.** If you dismissed an option in a sentence during design, leave it out entirely. Listing it adds length without helping the reviewer.
- **Never strawman.** Don't list a weak option to make your choice look better. A reviewer notices the strawman and stops trusting the rest of the doc.
- **What to put in, when you do:** the one or two alternatives a reasonable reviewer would otherwise ask "why not X?" about — each with one line on what it was and one line on why you didn't pick it. A short table works when the axes are parallel (cost, time, blast radius, reversibility).

If no alternatives were genuinely in contention — a forced upstream change, a single vendor, a correctness-only fix — omit the section or say so in one sentence.

### 6. Consequences, risk, and tradeoffs

What this touches, what you're giving up to get it, and what happens if it goes wrong.

Engineering is tradeoffs; go in clear-eyed. Naming the cost you're accepting up front is honest and it speeds development — the reviewer helps you tackle it during design instead of discovering it mid-build.

- **What to put in:** the tradeoffs you're accepting even on the happy path (latency, operational load, cost, future flexibility you're foreclosing); systems that depend on the changed surface; teams that need to know; data that could be corrupted or lost; whether the change is reversible and at what cost; customer-visible effects.
- **What to keep out:** reassurance ("we don't expect issues"). A reviewer wants the honest worst case and the real cost, not the happy path with the tradeoffs filed off.

Reversibility deserves a direct answer: is this a one-way door, a two-way door with a migration, or a flag you can flip back?

### 7. Rollout plan

Phases, gates, owners, dates. A table works when the phases are parametric.

**Include an ordered PR breakdown.** Decompose the implementation into the sequence of pull requests it will actually land as — a numbered list where each entry states the PR's scope, its dependency on the prior one, and roughly its size. Smallest shippable slice first; pure refactor/rename/move and new scaffolding (a new type, a new interface, fixtures) before the behavior that consumes them; default target ≤~400 changed lines per PR, split further if larger. This is distinct from deploy phases above: phases are *when* code ships to production; the PR breakdown is *how* the change is sliced for review. A design doc that would land as one giant unreviewable PR hasn't finished designing the rollout — the breakdown is a required deliverable, not an afterthought.

Tick rollout phases the same way a PR test plan ticks checks: `[x]` means "this has happened, against the current plan"; `[ ]` means "not yet." If a phase hasn't started, the box stays empty — optimistic ticks turn the rollout plan into fiction.

- **What to put in:** named phases, an owner per phase, a gate that lets you move to the next phase, a rollback path for each phase.
- **What to keep out:** dates invented to fill the column. If you don't know the date, leave it blank and say why.

### 8. Concerns / Open questions

Same shape as the PR template's concerns section, because the job is the same: name what you want the reviewer to focus on.

Each item has three parts:

1. **The concrete thing** (a specific decision, flag, or boundary — not "complexity").
2. **Why it matters** (what breaks, or what the trade-off costs).
3. **What you did and why — or what options you're weighing.** This is what makes the reviewer's response actionable.

Mix concerns (risks you've accepted and want a sanity check on) with open questions (decisions you haven't made and want input on). Label individual items if the distinction matters; don't if it doesn't.

If there's nothing to say, say that. "Nothing comes to mind" is a stronger signal than three invented worries.

### 9. Review checklist

An author's list of what a reviewer should specifically check. Tick the items you've already verified; leave unticked the items you want the reviewer to look at.

This section protects the reviewer's time. A blank list abdicates responsibility — the reviewer has to guess where to focus and covers the diff at uniform depth. A thoughtful list points them at the load-bearing calls.

Example:

```markdown
- [x] Meter correctness: cross-checked `tdp.usage` against `NrConsumption` for 7 days, ≤0.4% delta
- [x] Backfill query runs in under 5 min on staging against 30 days of data
- [ ] Rollback path: I haven't tested reverting the consumer config mid-flight — please sanity-check the documented steps
- [ ] Blast radius on downstream billing pipeline — I'm less familiar with this path; reviewer with billing context, please confirm
```

## Length

As short as fits the structure. A small scoped CDD might be 300 words. A big architectural one might be 1500. Length is not the metric; whether a reviewer can push back on the real decisions is.

Things that almost always bloat a CDD:

- Recaps of the spec or design brainstorming that preceded the CDD
- Narratives of how the team arrived at the approach
- Self-assessment ("we think this is clean")
- Restating what the summary already said

Things that are worth the length when they're present:

- More alternatives, when the space of options was actually wide
- More concerns, when the change is riskier
- More rollout phases, when the change stages in distinct waves

## Process

1. **Add each section to your task list.** Use TaskCreate with one task per section. Drafting in order prevents skipping ahead to what's easy (rollout plan) and starving what's hard (problem framing and alternatives).
2. **Draft the summary last, after sections 3–7.** You won't know the load-bearing constraint until you've written the problem and the alternatives. Write a placeholder summary first, then rewrite it at the end.
3. **For each sentence, ask: "does a reviewer need this to push back?"** If the answer is no, cut it. Narration, history, and reassurance are the most common forms of padding.
4. **Skim-test the draft cold.** After 30 seconds of scanning (summary + headings + checklist), can a reviewer who hasn't seen the spec say what you propose to do and where they should focus? If not, the summary is hiding the point or the review checklist is blank — fix those, not prose.
5. **Fill the review checklist accurately.** The unticked boxes are where you want help. If every box is ticked, you either over-verified or you're over-claiming; re-read and cut ticks that aren't backed by a specific check you ran.
6. **Scrub AI tells before circulating.** Run the `avoid-ai-writing` skill as a final pass — puffery, pivot-phrases, rules-of-three, "not just X, but also Y," closing-significance statements. The doc must sound human, because the reviewer is engaging with *your* thinking.
7. **Leave the human read-through checkbox unticked until you've read the full draft end-to-end** and done the scrub in step 6.
