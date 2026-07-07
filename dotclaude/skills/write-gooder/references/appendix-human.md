# Appendix — human-only mechanics

Extends [doc-writing-core.md](doc-writing-core.md) for docs a human reads. Sub-type specifics (PR, CDD, README, release notes, commit messages) are Phase 5.

## What this appendix covers

Rules tagged by category for downstream skill-authors:

- **[C] Comprehension** — human-specific comprehension mechanics (F-pattern, reading age, linkability).
- **[E] Ethics/accountability** — human agency, AI attribution, when to use AI.
- **[A] Authoring** — review process, internal-docs hygiene.

---

## Accountability

AI didn't do it. You did it, using AI. Keep the grammatical subject human (Larson, "agentic passive voice").

- "I made an error using Claude," not "Claude made an error." **[E]**
- "I didn't review the output," not "ChatGPT messed up." **[E]**
- **Don't let LLMs speak in your voice.** Before publishing AI-drafted text, re-read every sentence and ask: *would I actually say this? do I actually believe this argument?* Only the author-knows-their-own-mind test catches invented rationales — there's no mechanical substitute. If you didn't form the reasoning, cut the sentence. **[E]**
- **Don't waste other people's time if you can't be bothered to read it yourself.** On a PR, CDD, or other review artifact, put an unticked "I, the human author, have read this end-to-end and stand behind it" checkbox at the top, and only tick it once you have. This protects reviewers from AI-generated output dumped without author-review. Drop the checkbox later if the AI-drafted-and-unread problem goes away; for now, it's load-bearing. **[E]**
- **Surface concerns and open questions.** If you're uncertain about a scope call, a trade-off, or whether a rule covers all cases, name it in a `## Concerns` or `## Open questions` section. Unsaid concerns become reviewer ambushes — the reviewer raises the question you already knew about, and the conversation takes a round-trip it didn't need. **[E]**
- **Mark test plans accurately.** Enumerate what should be tested, not just what was. Tick what you verified; leave unticked what you didn't, and note why. Omitting what wasn't done is worse than marking it unticked — the unticked box is a signal; the omitted test is a trap. **[E]**

### When to use AI for prose

From Willison's AI-writing policy:

- **AI is fine for** code docs, READMEs, factual release notes, proofreading. **[E]**
- **AI is not fine for** opinion posts, blog entries in your voice, or any writing where personal judgment is important. **[E]**

---

## Scan patterns and reading

Humans scan in an F-pattern and read 20–28% of a page (Nielsen).

- **Line length 50–75 characters** for readable prose. Longer lines force saccades that cost comprehension. **[C]**
- **Write for a 9-year-old reading age** using common vocabulary (GOV.UK). Many readers work in English as a second or third language; plain English is faster for everyone. **[C]**
- **Page titles ≤ 65 characters.** Google truncates at 65 in search results. **[C]**
- **Meta descriptions ≤ 160 characters.** Google truncates at 160. **[C]**
- **Avoid block caps** — 13–18% harder to read than mixed case, and reads as shouting. **[C]**
- **"and" not "&"** in body text. Ampersands trip lower-literacy readers. **[C]**
- **No footnotes.** Print-era hack; put important content inline. **[C]**
- **No FAQs.** If a question gets asked often, the main doc isn't answering it — fix the main doc instead of growing a parallel one that drifts out of sync. **[C] [A]**

---

## Concise without curt

Every doc this appendix governs is read by a person. Concise is the job; curt is a failure of it — and the two are easy to confuse. The terseness rules in [doc-writing-core](doc-writing-core.md) (start with verbs, drop hedges, cut by half) were written for sentences that **describe a system**. Applied to sentences that **address the reader**, they turn into orders. Watch which one you're writing. **[C]**

- **Describe the situation; don't command the reader.** State the fact and let them act on it. "Easy to mix up: X isn't Y" beats "Don't confuse X and Y"; "if a ticket names a Setup, it's ours" beats "Recognize the terms and route." Imperatives are right for procedure ("Run the migration"); they read as bossy when they govern what the reader should *know* or *believe*. **[C]**
- **A softener is not a hedge.** Hedges blur a claim — "essentially," "fairly," "more or less" — so cut them. Softeners frame a request for a human — "if you hit this," "worth a look," "when you get a chance" — and keep an instruction from sounding like a bark. Cutting every softener is how concise goes cold. **[C]**
- **Reread reader-facing lines as the recipient.** The author hears efficiency; the recipient hears tone. Read each line as if it were sent to *you* on a busy day; if it lands as terse or superior, restate it as a fact or spend the three or four words that keep it human. **[A]**

---

## Tone and vocabulary

- **Conversational, not chummy.** Google's "knowledgeable friend" test: natural, more polished than speech, no slang. Write like you'd explain it to a competent colleague — "here's how to spot it" — not a manual barking steps, not a buddy oversharing. **[C]**
- **Contractions** for warmth. **[C]**
- **Second-person "you"** for directness. Naming the reader creates connection and forces you to specify the action. **[C]**
- **Explain technical terms on first use.** Don't assume everyone knows what you do (GOV.UK). **[C]**
- **No "please"** in instructions. Overly polite, wastes words. **[C]**
- **No exclamation marks, pop-culture refs, internet slang.** They age badly, and they exclude audiences who didn't grow up in the same time and place. **[C]**
- **"Must" vs "need to."** Use "must" for hard requirements with consequences (legal, security, correctness). Use "need to" for expected process steps that aren't hard-stop. Readers judge how bad it is to skip by the verb you chose. **[C]**

---

## Linkability

- **Every feature gets its own dedicated, linkable page** (Willison, "give people something to link to"). If people can't link to it, the explanation gets re-written across many different threads. **[A]**
- **URLs match how people search.** Kebab-case, feature name in the path. **[C]**
- **Feature name prominent in the page body** so renames don't orphan the URL. **[A]**
- **Link every referenceable artifact inline.** PRs, files (with line ranges), tickets, dashboards, threads, canonical docs. An unlinked path or bare ticket number forces the reader to stop and hunt; the doc's job is to remove that hunt. If it can be linked, link it. **[C] [A]**

---

## Docs and code

- **Docs live with code.** Same repo, same commit, same review. Wiki copies drift. **[A]**
- **Document the contract**, not the implementation. The contract is what readers rely on; implementation detail is what they don't need. **[C] [E]**
- **Write docs with the implementation**, not after. Willison's "library without docs has no bugs" argument: without documented behavior, there's no contract, so nothing the code does can be called "wrong." Docs define what counts as a bug. **[E]**

---

## Reviewing others' writing

Larson, "providing feedback on writing":

- **Skim first.** Understand layout before deep-reading. Misread structure leads to misdirected feedback. **[A]**
- **Cap at 3–4 issues per doc.** More overwhelms the author; pick the ones that matter. **[A]**
- **Comment what + why + severity.** The author needs to know how to act. **[A]**
- **Schedule a live conversation for entangled concerns.** Async comments can't resolve issues that depend on each other; a 30-minute call often does. **[A]**

---

## Internal-docs hygiene

Notion, Confluence, wiki pages rot unless maintained.

- **Delete stale content ruthlessly.** Stale duplicates mislead worse than absence. **[A]**
- **Link to canonical sources in version control** rather than duplicating in the wiki. READMEs stay current; wiki copies drift. **[A]**
- **Optimize for search, not navigation.** Most users find docs via search or direct link. **[C] [A]**
- **Verification status on pages** so readers know which to trust. **[A]**
- **Staging zone for deprecated content** before permanent delete; prevents broken links. **[A]**
- **Everyone tidies.** Distributed ownership catches staleness faster than centralized review. **[A]**
- **Automate stale detection.** Busy teams don't curate manually. **[A]**

---

**Sources cited:** Nielsen (F-pattern, 20–28% read rate). GOV.UK (reading age, 25-word sentences, 65-char titles, 160-char meta descriptions, no FAQs, no block caps, no footnotes, plain-language vocabulary). Larson (agentic passive voice; 3–4 issues cap on review; internal-docs refactoring). Willison (AI-writing policy; "give people something to link to"; docs-with-implementation; "library without docs has no bugs"). Microsoft/Google style guides (contractions, second person, no "please," sentence case).
