# Sources — doc-writing bibliography

Provenance for the rules in `doc-writing-core.md`, `appendix-llm.md`, and `appendix-human.md`. Load this **only when revising the skill** — you don't need it to author a document. The 29 sources below were extracted into 335 tagged rules; this is the annotated reading list behind that extraction.

**Audience legend:** L = LLM-facing, H = human-facing, B = both.

## How the audience tags work

Source label doesn't decide the rule tag. A rule from an LLM-focused source can still be **[B]** if the underlying principle ("attention is scarce," "don't re-state what the audience already knows," "front-load the point," "gotchas are highest-value") holds for both audiences. During extraction a re-tag sweep moved ~40 rules from [L] → [B] on this basis.

Default to **[B]** when in doubt. Reserve **[L]** for rules that depend on model-specific mechanics (routing via description, progressive skill loading, tool_search, training cutoff) and **[H]** for rules that depend on human-specific mechanics (F-pattern scanning, reading age, accountability, review workflows).

## Reading list

### Hand-picked / already in hand
- [L] **Perplexity — Designing, Refining, and Maintaining Agent Skills** (2026-05-01). Canonical source for the LLM-facing doc.
- [L] **Superpowers plugin skills** (structural reference): `~/.claude/plugins/cache/claude-plugins-official/superpowers/`

### Addy Osmani
- [L] **[Stop Using /init for AGENTS.md](https://addyosmani.com/blog/agents-md/)** — 2026-02-23. "Can the agent discover this on its own? if yes, delete it." Anti-bloat filter for LLM configs.
- [B] **[How to write a good spec for AI agents](https://addyosmani.com/blog/good-spec/)** — 2026-01-13. 5-principle framework, 6-section PRD checklist (from GitHub's 2,500-AGENTS.md study).
- [L] **[Agent Skills](https://addyosmani.com/blog/agent-skills/)** — 2026-05-03. "Process over prose. Workflows over reference. Steps with exit criteria over essays without them."
- [B] **[Agentic Engine Optimization (AEO)](https://addyosmani.com/blog/agentic-engine-optimization/)** — 2026-04-11. Dual-audience docs: parsability, token efficiency, capability signaling.
- [L] **[Agent Harness Engineering](https://addyosmani.com/blog/agent-harness-engineering/)** — 2026-04-19. CLAUDE.md as load-bearing harness; maintenance = "agent did X dumb thing → add one line."

### Simon Willison
- [L] **[Claude Skills are awesome, maybe a bigger deal than MCP](https://simonwillison.net/2025/Oct/16/claude-skills/)** — 2025-10-16. "Markdown files that teach LLMs new tricks."
- [L] **[OpenAI are quietly adopting skills](https://simonwillison.net/2025/Dec/12/openai-skills/)** — 2025-12-12. Progressive disclosure: read SKILL.md first, load references only as needed.
- [L] **[Changes between Claude Opus 4.6 and 4.7 system prompt](https://simonwillison.net/2026/Apr/18/opus-system-prompt/)** — 2026-04-18. Worked example of tightening a production system prompt.
- [L] **[OpenAI reasoning models: Advice on prompting](https://simonwillison.net/2025/Feb/2/openai-reasoning-models-advice-on-prompting/)** — 2025-02-02. Delimiters, zero-shot first, be specific about end goal.
- [L] **[How coding agents work](https://simonwillison.net/guides/agentic-engineering-patterns/how-coding-agents-work/)** — 2026. What an instruction doc competes with for attention.
- [H] **[If your library doesn't have documentation, it can't have bugs](https://simonwillison.net/2025/May/22/no-docs-no-bugs/)** — 2025-05-22. Docs define contract.
- [H] **[The Perfect Commit](https://simonwillison.net/2022/Oct/29/the-perfect-commit/)** — 2022-10-29. What a commit message / issue / PR body must contain.
- [H] **[Writing better release notes](https://simonwillison.net/2022/Jan/31/release-notes/)** — 2022-01-31. Signal-dense, skimmable notes; transfers to READMEs.
- [H] **[Coping strategies for the serial project hoarder](https://simonwillison.net/2022/Nov/26/productivity/)** — 2022-11-26. Docs + tests as productivity substrate; length/density.
- [H] **[Give people something to link to](https://simonwillison.net/2024/Jul/13/give-people-something-to-link-to/)** — 2024-07-13. Every feature/idea gets its own linkable page.
- [B] **[AI writing (policy post)](https://simonwillison.net/2026/Mar/1/ai-writing/)** — 2026-03-01. When LLM-generated prose is OK (code docs, READMEs) vs not (opinions, "I" voice).

### Will Larson
- [H] **[Making engineering strategies more readable](https://lethain.com/readable-engineering-strategy-documents/)** — 2024-05-18. **Top pick.** Invert structure for reading: Policy → Operation → Refine → Diagnose → Explore.
- [H] **[How to provide feedback on documents](https://lethain.com/providing-feedback-on-writing/)** — 2025-05-11. Skim first; comment what/why/severity; cap at 3–4 issues.
- [H] **[Writing an engineering strategy](https://lethain.com/eng-strategies/)** — 2023-02-13. Canonical structure for engineering strategy docs.
- [H] **[Write five, then synthesize](https://lethain.com/good-engineering-strategy-is-boring/)** — 2020-11-26. Good docs are specific and dull; counter to generality/hedging.
- [H] **[When to write strategy, and how much?](https://lethain.com/when-write-down-engineering-strategy/)** — 2024-08-25. Length/density calibration.
- [H] **[The agentic passive voice](https://lethain.com/agentic-passive-voice/)** — 2025–26. AI-era voice failure modes.
- [H] **[Refactoring internal documentation in Notion](https://lethain.com/refactoring-internal-docs-notion/)** — 2026-02-05. Org-level docs hygiene: refactor vs rewrite, staleness.

### Authority sources
- [H] **[How Users Read on the Web](https://www.nngroup.com/articles/how-users-read-on-the-web/)** — Jakob Nielsen, 1997 (foundational). Scanning, subheads, bulleted lists, one idea per paragraph.
- [B] **[How Chunking Helps Content Processing](https://www.nngroup.com/articles/chunking/)** — Anna Kaley, 2019. Cognitive-load rationale for scannable chunks; applies to LLM comprehension too.
- [H] **[Top 10 tips for Microsoft style and voice](https://learn.microsoft.com/en-us/style-guide/top-10-tips-style-voice)**. Prescriptive enforceable rules.
- [H] **[Google developer documentation style — Voice and tone](https://developers.google.com/style/tone)** (+ [full guide](https://developers.google.com/style)). Conversational, concise, consistent terminology.
- [H] **[Writing for GOV.UK](https://www.gov.uk/guidance/content-design/writing-for-gov-uk)**. Reading age, sentence length, front-loading the point.
- [H] **[Plain language guidelines (plainlanguage.gov)](https://www.plainlanguage.gov/guidelines/)**. Audience analysis, active voice, short sentences, verbs over nominalizations.
- [H] **[Purdue OWL — Conciseness](https://owl.purdue.edu/owl/general_writing/academic_writing/conciseness/index.html)**. Canonical "eliminating wordiness" checklist.
- [L] **[Anthropic — Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)** — 2024-12-19. Simple composable patterns.
- [L] **[Anthropic — Equipping agents with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)**. Canonical on Skill structure.
- [L] **[Anthropic — Claude Code best practices](https://www.anthropic.com/engineering/claude-code-best-practices)**. CLAUDE.md, tool definitions, agent instructions.
- [L] **[Anthropic — How Claude remembers your project (Memory)](https://docs.anthropic.com/en/docs/claude-code/memory)**. Official rules for CLAUDE.md structure, imports, length.
- [B] **`avoid-ai-writing`** (local skill) — added mid-extraction. The puff/filler/tell lists incorporated into `doc-writing-core.md`.

### Dropped (and why)
- **OpenAI prompt engineering guide** — canonical docs scattered in Cookbook, no stable URL. Anthropic sources cover the LLM side.
- **MLA / Chicago / AP** — no free, online, specific guidance on concise technical-doc writing.
- **USWDS content page** — 404; plainlanguage.gov covers the same ground.
- **Larson: competitive-advantage-author-llms** — datapacks/monetization, not writing craft.
