# Initiative Design Document template

An IDD exists to **help a reviewer sign off on the architecture, API surface, and cellular-impact of a quarter-plus initiative before the team commits to it**. It is the big-picture artifact written at the start of an initiative, before any CDDs. If an architect lead can't, after reading it, say "I'd change this API" or "this is fine," the IDD failed.

An IDD is not a CDD, a one-pager, a pitch deck, or a status doc. It does not narrate tactical implementation, justify the initiative's existence to execs, or narrate commit-by-commit work. Those belong elsewhere (CDD, product one-pager, not at all).

## Relationship to the NR canonical IDD process

This template is a **content guide** for the [NR IDD template](https://newrelic.atlassian.net/wiki/templates?template=3671786078&search=init). The [IDD policy page](https://newrelic.atlassian.net/wiki/spaces/STAN/pages/3798041533) (STAN, page 3798041533) defines the process: who writes (the assigned architect), who signs off (architect lead + engineering leader + product leader), when to consult others, and the review budget.

**Review budget — budget this before circulating:**

- Work under 1 quarter → give reviewers 2 days
- Work under 3 quarters → give reviewers 1 week
- Work over 3 quarters → give reviewers 2 weeks

**Required consultations — know before you draft:**

- Any new or changed public / private API (ingest, NerdGraph, REST) → `#api-review-board`
- Any new cell or cellular-architecture change → `#cell-arch`

These happen on top of the architect-lead sign-off, not instead of it.

The NR process doc doesn't prescribe the content shape of the IDD body. That's what this template does.

## Structure

The spine below is ordered for a cold architect-lead scan. Any section can be short when there's nothing to say, but every section must be present — an IDD missing Alternatives or Blast Radius reads as the author not having done the thinking.

### 1. Summary

Four to six sentences: the initiative, the architectural change, the load-bearing primitives, the biggest risk. Front-loaded so a reviewer who reads only this paragraph can tell whether the architecture seems right and where to look.

- **What to put in:** what the initiative delivers, the architecture shape at the highest level, the primitives it reuses vs builds new, the hard constraint driving the design.
- **What to keep out:** exec-audience framing ("this unlocks $X revenue"). That belongs in the one-pager. An IDD is for architects; they want to see the shape of the system.

### 2. Sign-off table

At the top of the doc, not the bottom. Names + dates, ticked as each signs off.

```markdown
| Role | Name | Date signed off |
|---|---|---|
| Architect lead | | |
| Engineering leader | | |
| Product leader | | |
| API review board (if APIs in scope) | | |
| Cell-arch group (if cell changes in scope) | | |
```

Empty rows are the point: a reviewer knows who still hasn't signed and where the initiative stands.

### 3. Problem

What we're solving, for whom, and how we know it's real.

- **What to put in:** the observable symptom or opportunity, the users/systems/customers affected, the measurement that validates the problem (telemetry, customer research, revenue impact, architectural debt that blocks other work).
- **What to keep out:** the solution, team narrative, "we've been wanting to do this." An IDD is not a sales doc.

If a reviewer disagrees with the problem framing, they'll disagree with the architecture. Make the framing falsifiable so they can argue the premise, not the prose.

### 4. Proposed architecture

The architectural decision, with diagrams. A reviewer should be able to sketch the system after reading this section.

- **What to put in:** the high-level architecture diagram (services, data flow, boundaries), the contract changes (APIs, event types, schemas), the primitives being used, the primitives being built new and why existing ones don't suffice.
- **What to keep out:** line-level implementation detail (that's a CDD), micro-services-style detail on each component, rollout mechanics (that's later).

Diagrams are load-bearing here. The IDD doc instructs: "written as docs and not slides" — diagrams as images embedded in the doc are right; a separate slide deck is wrong.

### 5. Primitives: reused vs new

A table. One of the IDD's explicit goals is *ensuring we're using primitives where possible*.

```markdown
| Primitive | Reuse / New | Why |
|---|---|---|
| NR-auth | Reuse | Standard auth flow, no custom needs |
| Pipeline Control Gateway | Reuse | Routing fits existing PCG pattern |
| Ingest metering | New (extends existing) | Per-accepted-record metering doesn't exist; existing meters are per-attempt |
```

Every "new" row is a cost and a review risk. If a reviewer sees three "new" rows without compelling "why" text, they should push back.

### 6. APIs

If APIs are in scope, this section is **required** — and so is `#api-review-board` consultation. List every public and private API the initiative creates or changes.

Use the canonical CDD API shape (Object Definitions + GraphQL/REST tables, NRDB event schemas). That's what reviewers expect, and it's what the API review board reviews against.

If no APIs are in scope, say so in one sentence. Don't leave the section empty.

### 7. Cellular architecture impact

Same rule: if cells or cellular architecture change, this section is **required** and `#cell-arch` review is a hard prerequisite.

- **What to put in:** new cell types, cell assignment changes, cross-cell traffic, region expansion, FedRAMP / EU segregation impact.
- **What to keep out:** generic "we'll deploy in all regions" boilerplate.

If nothing changes, say so in one sentence.

### 8. Alternatives considered

Two or three alternatives, each with one line on what it was and one line on why you rejected it. A short table works well when the axes are parallel (cost, complexity, blast radius, reversibility, vendor lock).

This section lets a reviewer argue against the choice instead of against the prose. An IDD that skips this reads as "architect already decided" — which makes the review performative.

If no alternatives were viable, say so and say why. "We considered reusing the X service; it doesn't support multi-tenancy and adding it is a larger project than this one" counts.

### 9. Blast radius and reversibility

What this initiative touches and what happens if the design is wrong.

- **What to put in:** systems that depend on the new surface, customer-visible effects, data that could be corrupted, reversibility (one-way door, two-way door with migration, or flag-flip), the worst realistic failure mode.
- **What to keep out:** reassurance. Reviewers want the honest worst case.

Reversibility gets a direct answer. A one-way door (new ingest schema that external customers depend on, for example) deserves more alternatives consideration than a two-way door.

### 10. CDDs this IDD will produce

An IDD is the umbrella. CDDs are the work units under it. List the expected CDDs so a reviewer can see the decomposition.

```markdown
- [ ] CDD: new ingest API (Team X, Q3)
- [ ] CDD: metering consumer rewrite (Team Y, Q3)
- [ ] CDD: billing-pipeline changes (Team Z, Q4)
```

Each item becomes a real CDD later with its own review. Listing them here commits the architect to the decomposition and lets a reviewer challenge it.

### 11. Dependencies and sequencing

Teams, initiatives, primitives, or external vendors this initiative depends on — and what depends on it.

A table works when the dependencies are parametric (what / direction / blocking-or-not / contact).

If an architectural piece only unlocks in quarter N+2 because of an upstream initiative, name the upstream initiative and its status.

### 12. Concerns / Open questions

Same shape as the PR and CDD templates: name what you want the reviewer to focus on.

Each item:

1. **The concrete thing** (a specific API, primitive, cell boundary — not "scale").
2. **Why it matters** (what breaks, what it costs).
3. **What you're weighing** — options, leading choice, why.

Mix concerns (risks accepted, sanity-check wanted) and open questions (decisions not yet made). If a question depends on the API review board, say so.

If nothing comes to mind, say that. An IDD with three invented worries is worse than one with a blank "nothing outstanding" line.

## Length

IDDs are longer than CDDs because the scope is wider. A 1-quarter IDD might be 800 words. A 4-quarter cross-team initiative might be 3,000. Length is not the metric; whether the architect lead, engineering leader, and product leader can all push back on the real decisions is.

Things that almost always bloat an IDD:

- Exec-audience motivation paragraphs (they belong in the product one-pager)
- CDD-level implementation detail (that's a CDD's job)
- Repeats of the summary in later sections
- Speculative future phases beyond the initiative's scope

Things that are worth the length when present:

- More diagrams, when the architecture is complex enough that prose won't convey it
- More alternatives, when the design space was wide
- More dependencies, when the initiative spans teams or quarters
- More concerns, when novel primitives or one-way-door decisions are in play

## Process

1. **Confirm an IDD is the right artifact.** If the work is under an initiative, use the IDD template (3671786078). If it's a single CDD-sized change, write a CDD instead.
2. **Check the two required consultations before drafting.** APIs in scope → message `#api-review-board` to schedule the review. Cell changes in scope → message `#cell-arch`. These reviews can run in parallel with the architect-lead review, not after.
3. **Add each section to your task list.** Use TaskCreate with one task per section. Drafting in order prevents skipping ahead to primitives and alternatives — the sections that carry the most review leverage.
4. **Draft the summary last.** Write a placeholder first, rewrite after Problem, Proposed architecture, Primitives, and Alternatives are done. You won't know the load-bearing constraint until those sections exist.
5. **For each sentence, ask: "does an architect lead need this to sign off?"** If the answer is no, cut it. Exec-audience framing and narrative history are the most common forms of padding at IDD altitude.
6. **Budget the review window correctly.** If the work is over 3 quarters, give reviewers 2 weeks. An IDD for a multi-quarter initiative circulated with a 48-hour review window is asking for rubber-stamp approval — the reviewer's time is the gate, not a courtesy.
7. **Skim-test the draft cold.** After 60 seconds of scanning (summary + headings + sign-off table + one diagram), can an architect who hasn't seen the initiative say what you propose to build, what primitives you reuse, and where the biggest risk is? If not, the summary is hiding the point or the diagram is wrong — fix those, not prose.
