# README template

A repo README exists to **help a stranger decide whether this project is what they want, and if so, get going with it** — without reading the code and without pinging the team. Onboarding engineers, external consumers, offboarding backfill readers, and the author six months later all land here.

A README is not a marketing page, a spec, a design doc, or a changelog. If it feels like a pitch, or if it narrates the project's history rather than its current shape, it's the wrong shape.

## Relationship to the NR canonical README standard

This template is a **style overlay** on top of the [Repo README engineering standard](https://newrelic.atlassian.net/wiki/spaces/STAN/pages/2655518778) (STAN space, page 2655518778, level ADOPT). The standard lists the required sections with MUST / SHOULD / MAY levels:

- **MUST:** What, Links to Long Form Documentation, How to Contribute, Operations, Local Setup
- **SHOULD:** Why, Diagrams, Dependencies, Using This Service
- **MAY:** Engineering Principles, FAQ

Use the standard as the section checklist. What this template adds on top:

- How to keep each section specific and falsifiable, not puffed up.
- How to structure Operations and Local Setup so the checkboxes age well.
- How to decide when a FAQ is pulling weight vs hiding broken docs.
- How to cut rather than pad when the README starts ballooning.

Skip sections that don't apply (e.g. Using This Service for an internal library with no HTTP surface). Don't skip them because they're hard to write.

## Structure

### 1. Project name + one-sentence What

The very first thing, as a heading plus one sentence. A stranger opens the README and knows in three seconds what this project is.

- **What to put in:** one sentence. Concrete noun + concrete verb. "This service meters log ingest bytes per account." "This gem parses and validates the `papers_manifest.yml` license inventory."
- **What to keep out:** adjectives like *powerful*, *simple*, *robust*, *modern*. They describe your feelings about the project, not what it does.

If you can't write this sentence, the project doesn't have a clear purpose — write that sentence before touching anything else.

### 2. What (2–3 sentences)

The STAN standard asks for "approximately 3 sentences" and calls out a failure mode specifically: *one sentence is often too vague*. Use the extra sentences to name the concrete problem solved and any acronyms a cold reader won't recognize.

Example that lands:

> The log-ingest meter tracks bytes accepted per account per hour and writes `tdp.usage` metric events to NRDB. It runs inside the Kafka consumer, replacing the older per-attempt meter that double-counted retries. TDP = Telemetry Data Platform; tdp.usage is the canonical ingest-measurement metric used by the billing pipeline.

Three sentences. A reader who has never seen the project now knows what it does, what it replaced, and which acronyms matter.

### 3. Why (optional, 1–3 sentences)

Only include if there's a reason the project exists as its own thing — scope cut, org boundary, rewrite of a predecessor, regulatory requirement. "Why this isn't part of X" is the useful framing.

- **What to put in:** the reason for separation, constraint, or split. "Extracted from the monolith in 2024 because the metering code had 40× the deploy frequency of the rest of the service."
- **What to keep out:** motivation narratives ("we've been wanting to do this for a while"). The project existing is evidence that someone wanted it.

If Why is just a rewording of What, delete it.

### 4. Local Setup

The MUST section everyone gets wrong. A stranger clones the repo — what's the shortest path to `tests pass on my laptop`?

- **What to put in:** the exact commands for build, test, run-locally. Not "run the usual bundle install" — the specific commands, in order, with any preconditions (tool version, env var, credentials source).
- **What to keep out:** prose narratives of what each step does. Commands explain themselves.

Example that lands:

```
bundle install
bundle exec rspec              # unit + integration
bundle exec rspec spec/unit    # fast (no DB)
bin/console                    # REPL against dev DB
```

Plus one line on prereqs ("Ruby 3.3 via asdf; a running Postgres on localhost:5432") and the reader is unblocked.

### 5. Operations

The other MUST section that rots the fastest. What keeps this alive in production?

- **What to put in:** deploy path (link to the GC pipeline or equivalent), runbook link, monitoring dashboard link, on-call rotation or PagerDuty service name. One line each, all linked.
- **What to keep out:** inline step-by-step deploy instructions. Link to the canonical deploy doc; don't copy it.

**Ticked vs unticked applies here too.** If a link is aspirational ("we're planning to add a dashboard"), either add the dashboard first or delete the line. A dead link to a missing dashboard is worse than no line at all.

### 6. Links to Long Form Documentation

The bridge to every other doc a reader might need. Short, annotated, linked.

- **What to put in:** `[title](url) — one-line what-it's-for`. Two to six links is typical. Group by purpose only if there are enough to warrant it.
- **What to keep out:** links to every tangentially-related doc in the space. If you wouldn't open it yourself, don't point others at it.

nr-platform-docs covers engineer-focused cross-team concepts; Confluence covers everything else. Use both where appropriate.

### 7. How to Contribute

Short section, often two or three lines. State the PR workflow, the issue tracker, and where to ask questions.

If the repo has a `CONTRIBUTING.md` or a `.github/PULL_REQUEST_TEMPLATE.md`, link to it from here rather than restating its content.

### 8. Dependencies (optional)

One line per service or library this project relies on, with a link. Also reflected in `datanerd.yml` for TreasureMap.

A reader hits this when an upstream fails and they're trying to figure out if that's the cause. Name the dependency, name what this project does with it. "Depends on nr-auth for token validation" is enough; don't narrate the auth flow.

### 9. Using This Service (API / message surface, if applicable)

Skip for libraries with no runtime surface (gems, tools, scripts). For services, include:

- API specification link (OpenAPI / Swagger URL)
- Rate limits, authentication mechanism (by link), any per-account quotas
- One or two realistic request/response examples

If the service talks Kafka or similar, document the topic names, key shape, and consumer-group conventions. "Consumes `log-ingest-raw`, produces `log-ingest-metered`" answers the question the reader actually has.

### 10. Engineering Principles (optional)

The MAY section. Include only if there are non-obvious design principles a contributor needs to know before making changes. "All metering must be idempotent under Kafka retry" is worth stating. "We value clean code" is not — every team says that.

If every principle here is generic, delete the section.

### 11. Diagrams (optional)

A picture beats 200 words when the relationships are what matter: service-to-service topology, class hierarchy, data flow. Mermaid diagrams in-repo age better than Figma / Lucid links, because they survive account loss and tool churn.

One diagram per relationship type. Don't stack four diagrams of the same architecture at different zoom levels.

### 12. FAQ (optional, last)

Include only if there's a question that gets asked twice a week and doesn't fit elsewhere. Each entry should be **one line plus a link to the authoritative doc** — if an FAQ entry is the canonical source, move the content to its real home and link from here.

A bloated FAQ is a sign of broken documentation structure. Cut before adding.

## Length

A small internal library's README can be 60 lines. A top-level service README might be 250. Length is not the metric; whether a stranger can clone, build, deploy, and understand the surface in 10 minutes is.

Things that almost always bloat a README:

- Marketing-style intro paragraphs
- Narratives of the project's history
- Inline step-by-step for deploy (link to GC)
- Generic engineering principles nobody disagrees with
- FAQs that restate content from elsewhere

Things that are worth the length when present:

- More worked examples for the service surface, if adoption keeps tripping on the same mistakes
- More links to long-form docs, if the project spans more subsystems
- More dependencies, if the project has genuine fan-out

## Process

1. **Check the canonical standard first.** Open [STAN/Repo README](https://newrelic.atlassian.net/wiki/spaces/STAN/pages/2655518778) and list which MUST sections are missing from the current README. Those are the priority.
2. **Add each section to your task list.** Use TaskCreate with one task per section you're adding or rewriting. Drafting in order prevents skipping the hard sections (What, Operations) for the easy ones (Dependencies).
3. **Draft What first, in 2–3 sentences.** If you can't, the project is the thing that needs fixing — not the README. Stop and write What with the team.
4. **For each sentence, ask: "does a stranger need this to use or understand the project?"** If the answer is no, cut it. Marketing adjectives, history narratives, and generic principles are the most common forms of padding.
5. **Verify Local Setup works against a clean clone.** Run the exact commands you wrote, in the order you wrote them, on a fresh checkout. If any step fails or needs unstated prereqs, fix the README before merging.
6. **Revisit on every non-trivial deploy change.** The Operations section rots faster than the code. If the deploy path or dashboard URL changes, update the README in the same PR.
