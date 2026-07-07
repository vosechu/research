---
name: write-gooder
description: Use when drafting a PR description (or `gh pr create` body), a Change Design Document / CDD / design doc, an Initiative Design Doc / IDD, a repo README, a runbook, an engineering standard, a CLAUDE.md file, or a SKILL.md — structured artifacts a reader (human or model) has to scan, trust, and act on. Routes to the right template and loads the relevant style references on demand.
---

# Write Gooder

## What this skill does

Routes you to one of eight templates based on what you're writing, then loads the style references that template depends on. Every template is short; the reference files behind them are the accumulated rules from a 29-source extraction on writing-for-scan (human and LLM readers).

Several templates sit **on top of existing NR canonical templates** (CDD, IDD, README, Runbook, Engineering Standard) rather than replacing them. Each of those templates opens with a "Relationship to the NR canonical template" section pointing you at the STAN-space source of truth; this skill's job is to add content discipline (reviewer-actionable framing, honest checkboxes, rule + rationale rhythm) on top.

Do not try to hold all three reference files in context at once. Load only what the picked template needs.

## Routing

| You are writing | Template to read | References to also read |
|---|---|---|
| A PR description or `gh pr create` body | `templates/pr.md` | `references/doc-writing-core.md`, `references/appendix-human.md` |
| A Change Design Document (design doc for pre-implementation review) | `templates/cdd.md` | `references/doc-writing-core.md`, `references/appendix-human.md` |
| An Initiative Design Doc / IDD (big-picture architecture doc for a quarter-plus initiative) | `templates/idd.md` | `references/doc-writing-core.md`, `references/appendix-human.md` |
| A repo README | `templates/readme.md` | `references/doc-writing-core.md`, `references/appendix-human.md` |
| A runbook (on-call / incident response) | `templates/runbook.md` | `references/doc-writing-core.md`, `references/appendix-human.md` |
| An engineering standard (for STAN space: Quality, Engineering, or Security) | `templates/standard.md` | `references/doc-writing-core.md`, `references/appendix-human.md` |
| A CLAUDE.md (project-memory file) | `templates/claude-md.md` | `references/doc-writing-core.md`, `references/appendix-llm.md` |
| A SKILL.md (body of a Claude Code skill) | `templates/skill-md.md` | `references/doc-writing-core.md`, `references/appendix-llm.md` |

If the user's request doesn't match one of these, fall back to `references/doc-writing-core.md` alone — it covers the generic prose craft and comprehension rules that apply to any reader.

**Out of scope — defer to another skill or handle ad-hoc:**
- **DACI documents.** Use `nr:daci-knowledge-skill` for NR's DACI framework guidance. The canonical DACI template is tight already; a write-gooder override adds little.
- **Slack messages.** Register varies too much; use `slack:slack-messaging` for Slack-specific composition guidance.
- **Blog posts, wiki articles, release notes, emails.** Register and voice vary too much to template usefully. Fall back to `references/doc-writing-core.md` + `references/appendix-human.md`.

## What's in each reference

- **`references/doc-writing-core.md`** (104 lines) — Prose craft and comprehension rules that apply to any reader: front-load the point, cut by half, active voice, short sentences, no hedging/puff/filler, specificity over abstraction.
- **`references/appendix-llm.md`** (209 lines) — LLM-only mechanics: CLAUDE.md discovery, path-gated rules, the description-as-trigger for skills, three-level progressive disclosure, hooks, memory. Read this when the reader is a model.
- **`references/appendix-human.md`** (103 lines) — Human-only mechanics: F-pattern scanning, 9-year-old reading age, "must" vs "need to," accountability (human-grammatical-subject rule, AI-attribution policy, read-through checkbox). Read this when the reader is a human.
- **`references/sources.md`** — Annotated 29-source bibliography behind the rules. Load this **only when revising the skill**, not when authoring a document.

Rules in every file are tagged `[C]` comprehension, `[A]` authoring, `[S]` surface, `[E]` ethics/accountability. The templates pull the tags that matter for their artifact.

## Related skills — don't duplicate work

- **`superpowers:writing-skills`** — teaches the PROCESS of developing a skill via TDD with subagent pressure tests (red-green-refactor on documentation). This skill's `templates/skill-md.md` teaches the STYLE of the resulting SKILL.md. Use both: Superpowers for how to iterate on a skill; `write-gooder` for how to write one well.
- **`avoid-ai-writing`** — a tight rule-of-thumb list for catching AI-prose tells. `references/doc-writing-core.md` incorporates its lists; reach for `avoid-ai-writing` directly when all you want is a last-pass tell-check.
- **`nr:daci-knowledge-skill`** — for DACI framework guidance at NR. This skill intentionally does NOT provide a DACI template; use the NR skill instead.
- **`nr:check-engineering-standards-skill`** — search and verify existing STAN-space standards. Use this before drafting a new standard with `templates/standard.md` — the one you want may already exist.
- **`slack:slack-messaging`** — Slack-specific composition guidance; this skill does not cover Slack.

## Process

1. **Decide which template applies.** Use the routing table above. If none fits and the writing is ad-hoc prose, read `references/doc-writing-core.md` and stop there.
2. **Read the picked template end-to-end first.** Each template front-loads the structure. Don't skim.
3. **Read the references the template points at.** The core is always relevant; the appendix depends on the audience. Don't load both appendices at once.
4. **For templates that overlay an NR canonical template (CDD, IDD, README, Runbook, Standard): also open the canonical page linked in the template's "Relationship to the NR canonical template" section.** The canonical is the structural scaffolding; this skill is the content discipline. You need both.
5. **Draft the artifact following the template's Process section.** Each template ends with 4–7 numbered steps that prevent skipping ahead to the easy parts.
6. **Before finalizing, run the self-check from `doc-writing-core.md`:** (a) does the first paragraph carry the answer? (b) what can I delete without loss? (c) would removing this line cause a mistake? (d) read it cold — does it hold?
7. **For human-read artifacts (PR, CDD, IDD), leave the accountability checkbox unticked until you have actually read it end-to-end.** This is load-bearing; see `appendix-human.md` on accountability.
