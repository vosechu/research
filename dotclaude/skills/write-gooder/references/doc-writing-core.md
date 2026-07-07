# Doc-writing core

**Every word is a tax on attention.** The reader did not agree to read your draft; they agreed to find the answer.

Two layers:

1. **Comprehension under attention scarcity** determines whether the reader gets the answer.
2. **Prose craft** determines whether it lands.

Appendices: [LLM-only mechanics](appendix-llm.md) · [human-only mechanics](appendix-human.md).

## What this guide covers

Rules are tagged by category so downstream skill-authors can filter:

- **[C] Comprehension** — improves the reader's ability to scan, parse, understand.
- **[A] Authoring** — about how the writer drafts, iterates, verifies.
- **[S] Surface** — about where content lives (deferred mostly to [LLM appendix](appendix-llm.md)).
- **[E] Ethics/accountability** — about human-authorial responsibility and AI attribution (deferred mostly to [human appendix](appendix-human.md)).

Core is almost entirely **[C]** with some **[A]**.

---

## Layer 1 — Comprehension under attention scarcity

**Readers don't read; they scan.** Users read 20–28% of a doc (Nielsen). Models budget tokens. Design for the scan.

### Front-load everything

- **Lead with the answer.** Inverted pyramid: conclusion, then support. Not build-to-thesis. **[C]**
- **First 200 words carry the outcome.** If the reader bails there, they should still have the point. **[C]**
- **Gotchas first.** Non-obvious constraints are the highest-value content — the reader can't reconstruct them from the code or their training. Surface them before the happy path. **[C]**
- **Don't re-state what the reader knows.** For humans: what's obvious from the repo or README. For models: what's in training or visible in the file being edited. If `grep` or `git log` would answer it, don't write it. **[C]**
- **A definition that only restates the guessable is noise.** A glossary entry or aside the reader can infer ("a cell is an isolated deployment") earns nothing. Replace it with a *pointer* — where the thing lives, who owns it, the file/PR/ticket — or cut it. The value is what they can't guess, not the restatement. **[C]**
- **Order by frequency.** Lead with the common case; demote the rare exception to a parenthetical or a later aside. Opening with "if your region is already in the recipe (it usually isn't)…" buries the path the reader almost always takes. **[C]**

### Structure

- **Descriptive subheads.** Every few paragraphs. Each heading tells a scanner what the section is about at a glance. **[C]**
- **Consistent hierarchy:** H1 → H2 → H3, no skips. Tight coupling helps humans scan and models parse. **[C]**
- **Delimiters separate distinct parts.** Markdown headers, XML tags, named sections, fenced code. Signal transitions explicitly (OpenAI reasoning-model guidance). **[C]**
- **One idea per paragraph.** Readers skip paragraphs whose first few words don't engage them. **[C]**
- **Paragraphs ≤ 5 sentences.** Longer paragraphs read as a wall. **[C]**
- **Bullets over prose** for parallel items. Lists are scannable; paragraphs aren't. **[C]**
- **Tables for parametric data.** Parameter/value, option/default, environment/account. Tables compress; prose expands. **[C]**
- **Whitespace** between chunks. Density hides the rules that matter. **[C]**
- **A single newline is not a line break in rendered Markdown.** Consecutive source lines joined by one newline collapse into one paragraph (the break becomes a space), so a stacked label block (`Run by:` / `Target:` / `Pass criterion:`, or `Target:` / `Host:` / `Telemetry:`) renders as a run-on. Put each on its own line with a trailing `<br>`, a blank line between them, or an unordered list. A frequent miss. **[C] [S]**

### Length

- **Cut by half** (Nielsen). Then read it cold and cut again where you find slack. **[A]**
- **Zero-shot first; add examples only if the reader fails without them.** Docs bloat fast when examples get added preemptively. **[A]**
- **One real example beats a descriptive paragraph** when you do include one (Osmani). **[C]**

### Discipline

- **Process over prose** for anything procedural. Workflows with exit criteria get executed; 2,000-word essays don't (Osmani). **[C]**
- **Verification is a hard exit criterion, not a suggestion.** "Seems right" isn't evidence; a passing command is. **[A]**
- **Surface assumptions before building.** Wrong assumptions left silent cause rework downstream. **[A]**
- **Never-rules distinct from gotchas.** Gotchas are non-obvious constraints; Nevers are hard-stops. List high-impact "Never" rules explicitly — don't bury them (Osmani). **[C]**
- **Specificity in instructions, too.** "Use 2-space indentation" beats "format code nicely." Prose-specificity and instruction-specificity are the same rule in different registers (Anthropic). **[C]**
- **Every procedural step states how, and where to observe the result — not just what.** "Confirm the region is supported" without *how to check* is unexecutable; "watch the build" without *where the notifications appear* leaves the reader refreshing dashboards blind. A step the reader can't run and verify from the doc alone is incomplete. **[C]**
- **Don't dress required work as an open question.** If a step is required, write it as a step. Reserve an "open questions"/"loose ends" section for *genuine* unknowns. Framing known-required work as "confirm whether you need to…" reads as optional and invites skipping. **[C]**
- **A checklist lists actions to take.** "You don't *need* to do X" is context, not a step — move it out of the numbered list into surrounding prose. Won't-do items in a to-do list confuse the scan. **[C]**

---

## Layer 2 — Prose craft

### Voice

- **Active voice.** Name who does the action. "The service emits spans" beats "spans are emitted." **[C]**
- **Present tense** over future or conditional. Immediate reads as instruction; future reads as aspiration. **[C]**
- **Start sentences with verbs.** Cut "you can," "there is/are," "it is" at the sentence start. They add words without meaning. **[C]**
- **Imperatives describe the system; they don't boss a human reader.** Verb-first, active voice is for describing what the system does. When a sentence addresses a human, state the fact instead of commanding them — "easy to mix up" beats "don't confuse" — see [appendix-human](appendix-human.md), "Concise without curt." (Commanding the reader is fine when the reader is a model.) **[C]**
- **Strong verbs, not nominalizations.** "We decided" beats "we made the decision." "The query returns" beats "the query performs the return of." **[C]**
- **Contractions** ("it's," "you'll," "don't") make prose warmer without losing precision. Not optional. **[C]**
- **Short words.** 3–5 letters land faster than 8–9; long words cause the eye to skip adjacent short words (GOV.UK). **[C]**
- **Short sentences.** Cap at 25 words (GOV.UK). Break on "and," "but," "because" when you can. **[C]**

### No hedging, no puffing

- **Drop hedges:** "genuinely," "honestly," "straightforward," "relatively," "fairly," "essentially." Either commit or cut. **[C]**
- **Drop puff:** "pivotal," "crucial," "vital," "significant," "groundbreaking," "renowned," "profound," "testament to," "boasts," "commitment to," "showcasing," "highlights," "underscores," "reflects broader," "enduring," "lasting," "indelible." These are LLM tells and noise to humans. **[C]**
- **Drop scenic puff:** "nestled," "in the heart of," "vibrant," "rich (figurative)," "natural beauty," "diverse array." Travel-brochure vocabulary in a technical doc is a tell. **[C]**
- **Drop pivot-phrases:** "stands as," "serves as," "marking the," "shaping the," "setting the stage for," "represents a shift," "key turning point," "evolving landscape." These are empty connective tissue. **[C]**
- **Drop filler:** "please note," "at this time," "simply," "it's easy," "in order to" (→ "to"), "a number of" (→ a count), "due to the fact that" (→ "because"). **[C]**
- **No "not just X, but also Y"** parallelisms. No rule-of-three by reflex. Both are syntactic tics. **[C]**
- **No "-ing" appositive phrases** tacked onto sentences: "highlighting its significance," "emphasizing the importance," "fostering connection," "underscoring the shift." Editorializing in disguise. Cut the whole clause. **[C]**
- **No closing significance statements.** Delete "This marks a turning point in…" and similar editorializing. **[C]**
- **No vague attribution.** "Experts argue," "observers note." Cite or cut. **[C]** **[E]**
- **Avoid em dashes entirely.** They are a strong AI tell. Use commas, periods, colons, or parentheses instead. **[C]**
- **Sentence case in headings, sparing boldface.** Title Case headings and bolding every third sentence are LLM tells. Bold only the load-bearing line. **[C]**
- **Drop inflated abstraction nouns:** "substrate," "surface," "primitive," "layer," "ecosystem." When a plain word fits, use it. "the shared doc" beats "the substrate." **[C]**
- **Don't brand ordinary things with Title Case.** Inventing a capitalized proper-noun label for a plain artifact ("the Targets + How-to substrate," "the Ingestion Layer") reads as AI. Lowercase it, or just name the file. **[C]**
- **Reference sections by name and link — never a glyph or bare number.** `§`, "§A," "§4.1," "see section 3": almost no human types `§`, and nobody wants to decode a letter. Use the section's title as the link text: "[the reconcile steps](…)", not "§B2". **[C]**
- **Don't cite an over-precise unnamed constant the reader must look up.** "within the creds-cache TTL," "after the 4th retry" sends the reader hunting for a number you never pinned. State the pinned value, or stay loose: "once the cached creds expire, a minute or two." **[C]**
- **Watch Claude-favorite words:** "locked" (as a status label), "footgun," "oracle," "sentinel," "delve," "leverage," "robust," "seamless." Reach for the plain word. **[C]**
- **AI-vocabulary words shift by model era** (per [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)). Weight the current ones highest: "enhance," "emphasizing," "highlighting," "showcasing." Also "align with," "garner," "interplay," "intricate/intricacies," "landscape" (abstract noun), "meticulous," "boasts," "valuable," "vibrant," "key" (adjective), and "Additionally" opening a sentence. Older tells ("delve," "tapestry," "testament") have faded but still count. **[C]**
- **Don't dodge plain `is`/`are`/`has`.** LLMs swap them for "serves as a," "stands as," "represents," "features," "offers," "maintains," "boasts." Use the plain copula. **[C]**

### Specificity

- **Replace abstractions with concrete details.** "Faster" → "p95 dropped from 400ms to 120ms." Specificity is the fix for AI-regression-to-mean. **[C]**
- **Write five specifics before synthesizing.** Generalities create the illusion of alignment; specifics create alignment. Draft five concrete examples, then write the abstract rule (Larson). **[A]**
- **Write the specifics and stop before generalizing.** The rule after the examples is often the examples themselves. **[A]**
- **Let facts speak.** Editorializing their importance is how AI prose and PR marketing both fail. **[C]**
- **An explicit unknown beats vague filler.** Write `???`, "not captured," or "couldn't confirm" where you don't know — not "varies," "TBD-ish," or "depends." A marked gap is honest and actionable; vague filler reads as an answer when it isn't, and the reader trusts it. Derive the real number first; only fall back to a marked gap. **[C] [A]**

---

## The self-check

Before you ship, read it cold. Four questions:

1. **Does the first paragraph carry the answer?** If the reader stopped there, would they have it? **[A]**
2. **What can I delete without loss?** Half of what's left, if Nielsen is right. **[A]**
3. **Would removing this line cause a mistake?** If no, cut it (Anthropic). **[A]**
4. **Read it aloud, or hand it to an uninvolved reader.** Read-aloud catches stilted prose; fresh eyes catch inscrutability the author glosses over (Larson). An LLM can first-pass prose mechanics; a human catches domain inscrutability. Use both. **[A]**

---

**Sources cited:** Nielsen (NNGroup 1997, "cut by half," inverted pyramid, scanning rates). GOV.UK (25-word sentence cap, reading-age vocabulary). Osmani ("process over prose," one real example, Never-rules). Larson ("write five, then synthesize," "write specifics, stop before generalizing," uninvolved-reader test). OpenAI reasoning-model guidance (delimiters for structure). Anthropic (Claude Code best practices, specificity in instructions, "would removing this cause mistakes?"). `avoid-ai-writing` local skill (puff/filler/tell lists).
