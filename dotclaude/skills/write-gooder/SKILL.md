---
name: write-gooder
description: Use when drafting a PR description (or `gh pr create` body), a Change Design Document / CDD / design doc, an Initiative Design Doc / IDD, a repo README, a runbook, an engineering standard, a CLAUDE.md file, or a SKILL.md. Also use BEFORE any Edit or Write that adds or changes a comment, docstring, or explanatory note beside code or config (any language, JSON/YAML/Terraform/shell included), and when reviewing or pruning comments. Fires even when the comment is incidental to a larger code change, and especially for notes recording when, with which tool version, or how something was observed or measured.
---

# Write Gooder

## What this skill does

Routes you to a template based on what you're writing, then loads the style references that template depends on. Every template is short; the reference files behind them are the accumulated rules from a multi-source extraction on writing-for-scan (human and LLM readers), listed in `references/sources.md`.

Several templates sit **on top of existing NR canonical templates** (CDD, IDD, README, Runbook, Engineering Standard) rather than replacing them. Each of those templates opens with a "Relationship to the NR canonical template" section pointing you at the STAN-space source of truth; this skill's job is to add content discipline (reviewer-actionable framing, honest checkboxes, rule + rationale rhythm) on top.

Do not try to hold every reference file in context at once. Load only what the picked template needs, plus `references/global-audience.md` when it applies (see below).

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
| Code comments (writing, reviewing, or pruning them) | `templates/code-comments.md` | `references/doc-writing-core.md` only |

If the user's request doesn't match one of these, fall back to `references/doc-writing-core.md` alone. It covers the generic prose craft and comprehension rules that apply to any reader.

**Also read `references/global-audience.md` for any human-read artifact whose readers include non-native English speakers.** At a company with engineers on several continents that is the common case, not the exception, so default to reading it and skip it only when you know the audience is narrow (a note to one person, a doc for one colocated team). It's a third axis rather than a fourth audience: it stacks on top of whichever appendix the template picked. Skip it for `code-comments.md` and for the two LLM-audience templates unless a human reads the artifact too, which for a CLAUDE.md usually means yes.

**Out of scope, so defer to another skill or handle ad-hoc:**
- **DACI documents.** Use `nr:daci-knowledge-skill` for NR's DACI framework guidance. The canonical DACI template is tight already; a write-gooder override adds little.
- **Slack messages.** Register varies too much; use `slack:slack-messaging` for Slack-specific composition guidance.
- **Blog posts, wiki articles, release notes, emails.** Register and voice vary too much to template usefully. Fall back to `references/doc-writing-core.md` + `references/appendix-human.md`.

## What's in each reference

- **`references/doc-writing-core.md`:** prose craft and comprehension rules that apply to any reader. Front-load the point, cut by half, active voice, short sentences, no hedging/puff/filler, specificity over abstraction.
- **`references/appendix-llm.md`:** LLM-only mechanics. CLAUDE.md discovery, path-gated rules, the description-as-trigger for skills, three-level progressive disclosure, hooks, memory. Read this when the reader is a model.
- **`references/global-audience.md`:** writing for readers whose first language isn't English. Put helper words and relative pronouns back, one term per concept, no idiom or culture-specific reference, conditional clause first. Read it alongside an appendix, not instead of one. It's the one file that tells you to add words rather than cut them, and it explains where that stops.
- **`references/appendix-human.md`:** human-only mechanics. F-pattern scanning, 9-year-old reading age, "must" vs "need to," accountability (human-grammatical-subject rule, AI-attribution policy, read-through checkbox). Read this when the reader is a human.
- **`references/sources.md`:** annotated bibliography behind the rules. Load this **only when revising the skill**, not when authoring a document.

Rules in every file are tagged `[C]` comprehension, `[A]` authoring, `[S]` surface, `[E]` ethics/accountability. The templates pull the tags that matter for their artifact.

## Related skills, and how not to duplicate work

- **`superpowers:writing-skills`:** teaches the PROCESS of developing a skill via TDD with subagent pressure tests (red-green-refactor on documentation). This skill's `templates/skill-md.md` teaches the STYLE of the resulting SKILL.md. Use both: Superpowers for how to iterate on a skill; `write-gooder` for how to write one well.
- **`avoid-ai-writing`:** a tight rule-of-thumb list for catching AI-prose tells. `references/doc-writing-core.md` incorporates its lists; reach for `avoid-ai-writing` directly when all you want is a last-pass tell-check.
- **`nr:daci-knowledge-skill`:** for DACI framework guidance at NR. This skill intentionally does NOT provide a DACI template; use the NR skill instead.
- **`nr:check-engineering-standards-skill`:** search and verify existing STAN-space standards. Use this before drafting a new standard with `templates/standard.md`, since the one you want may already exist.
- **`slack:slack-messaging`:** Slack-specific composition guidance; this skill does not cover Slack.

## Process

1. **Decide which template applies.** Use the routing table above. If none fits and the writing is ad-hoc prose, read `references/doc-writing-core.md` and stop there.
2. **Read the picked template end-to-end first.** Each template front-loads the structure. Don't skim.
3. **Read the references the template points at.** The core is always relevant; the appendix depends on the audience. Don't load both appendices at once.
4. **For templates that overlay an NR canonical template (CDD, IDD, README, Runbook, Standard): also open the canonical page linked in the template's "Relationship to the NR canonical template" section.** The canonical is the structural scaffolding; this skill is the content discipline. You need both.
5. **Draft the artifact following the template's Process section.** Each template ends with 4–7 numbered steps that prevent skipping ahead to the easy parts.
6. **Before finalizing, run the self-check from `doc-writing-core.md`:** (a) does the first paragraph carry the answer? (b) what can I delete without loss? (c) would removing this line cause a mistake? (d) read it cold, and does it hold?
7. **For human-read artifacts (PR, CDD, IDD), leave the accountability checkbox unticked until you have actually read it end-to-end.** This is load-bearing; see `appendix-human.md` on accountability.
