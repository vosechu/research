# Global audience

**Read this whenever any of your readers is not a native English speaker.** That's most internal docs at a company with engineers on several continents, so treat it as the default rather than the exception.

This is a third axis, not a third audience. It layers on top of either appendix: [LLM-only mechanics](appendix-llm.md) · [human-only mechanics](appendix-human.md). The core still applies: [doc-writing-core](doc-writing-core.md).

## The barrier is idiom and syntax, not vocabulary

A colleague reading their fourth language at work all day knows what idempotent, backpressure, and quorum mean. They read the spec. What stops them is ordinary words doing non-ordinary work, and sentences whose grammar has been filed down for a native ear.

> "Let's spin that up and see if it falls over, then we can punt on the rest."

Nine common words, four idioms, no dictionary help available. That sentence is harder than any technical term in the doc it appears in.

This is why a controlled vocabulary is the wrong tool here. [ASD-STE100](https://en.wikipedia.org/wiki/Simplified_Technical_English) ships a ~900-word approved dictionary, which aims at a vocabulary problem your readers don't have while doing nothing about "spin up." Take its grammar rules for procedures (see "Controlled language for procedures" in the core) and get the rest from plain-language guidance.

## Put words back

The counterintuitive half, and the reason this file exists. Writing for a global audience usually makes sentences **longer**. Conversational English drops words that a native ear reconstructs for free; a second-language reader pays to reconstruct them, and sometimes reconstructs wrong.

- **Don't drop relative pronouns.** "the rules that you previously defined," not "the rules you previously defined." **[C]**
- **Keep the helper words:** *then*, *that*, *of*. "If the key isn't found, then the default is returned." "Assumes that you have the following knowledge." "Identify all of the datasets." **[C]**
- **Repeat a noun when the redundancy buys clarity.** "IAM segmentation and network segmentation" beats "IAM and network segmentation," which reads as one compound thing. **[C]**
- **Repeat the conditional.** "If the VM has started and if you can connect" beats "…and you can connect," where the second condition can attach to the wrong clause. **[C]**
- **Name code elements with a qualifying noun.** "the `example.yaml` file," not bare "`example.yaml`." **[C]**
- **Replace an ambiguous pronoun with the noun it stands for.** "make sure that the ad is targeted," not "make sure that it's targeted." **[C]**
- **Spell out abbreviations on first use**, every doc, no exceptions for ones you think are universal. **[C]**

**How this squares with the cut-25% quota:** the quota deletes whole sentences and whole sections. It never deletes grammar inside a sentence. Cutting "that" and "then" to hit a word budget is trading the reader's comprehension for your metric, and the words you're proud of cutting are the cheapest words in the doc. Same line STE draws when it forbids dropping articles and subjects to shorten a step. If a doc is over budget, a section has to go, not a relative pronoun.

## Be consistent, mechanically

- **One term per concept, same capitalization, everywhere.** The highest-value rule on this page. A reader who meets cell, stack, and deployment assumes three things exist, because a writer who meant one thing would have said one word. Machine translation makes it worse: different terms get different translations, and the doc gains concepts it never had. **[C]**
- **Use words in their primary sense**, and don't use the same word as a noun and a verb in nearby sentences. Watch *once*, *while*, *as*, *since*: each has a time sense and a logical sense, and the reader can't always tell which you meant. **[C]**
- **Standard word order.** Subject, verb, object. Keep the subject and verb near the front of the sentence. **[C]**
- **Conditional clause first.** State the circumstance, then the instruction. "If the lag is still climbing after 5 minutes, escalate." **[C]**
- **Standard phrasings for recurring moves.** Introduce links, code samples, and output the same way every time. Boring is the point; the reader stops parsing and starts skimming. **[C]**
- **Parallel list items.** Same structure, same capitalization, same punctuation across the list. **[C]**

## Cut these

- **Idioms, colloquialisms, slang.** *ballpark figure*, *back burner*, *hang in there*, *spin up*, *punt on*, *circle back*, *bikeshed*, *out of the park*. **[C]**
- **Humor.** Most of it doesn't survive translation, and much of it is local to one culture. **[C]**
- **Culture-specific references:** holidays, sports, TV, regional politics. **[C]**
- **Seasons as time markers.** August is not summer in São Paulo. Use months or quarters. **[C]**
- **Ambiguous dates.** `2026-03-04` or "4 March 2026," never `03/04/2026`. **[C]**
- **Directional language in procedures.** "above," "below," and "the button on the left" break under translation, reflow, and screen readers alike. Link to the section by name, or name the control. **[C]**
- **Negative constructions where a positive one exists.** Tell the reader what to do. Double negatives ("not uncommon," "don't fail to") are worst. **[C]**
- **New information carried only in a screenshot.** Images don't get translated. Anything load-bearing goes in text. **[C]**

## Contractions: keep them, including the negative ones

Core requires contractions and this doesn't change that, including for negatives. `can't` is **safer** than `cannot` for this audience: a scanning reader drops a standalone "not," but nobody misreads "don't" as "do." Two bans only, and both are about invented forms rather than negation: no made-up contractions (*guides're*, or *browser's* meaning "browser is"), and no three-word contractions (*mightn't've*). **[C]**

## Reading age is a separate axis

[appendix-human](appendix-human.md) carries the GOV.UK reading-age rules: short words, short sentences, plain vocabulary. Those help this audience too, but they're aimed at a different problem (cognitive load under hurry, and readers with less education or less domain context). Don't conflate them. A second-language reader with a PhD needs the syntax rules on this page and does not need you to simplify the technical content.

---

**Sources cited:** [Google developer documentation style guide, "Write for a global audience"](https://developers.google.com/style/translation) (helper words, relative pronouns, redundancy for clarity, consistent terminology, primary-sense words, conditional-first order, idiom/humor/culture/season bans, images don't translate) and its [Contractions](https://developers.google.com/style/contractions) page (negation contractions recommended, nonstandard and three-word contractions banned). [ISO 24495-1:2023, Plain Language, Part 1: Governing principles and guidelines](https://www.iso.org/standard/78907.html) (the standards-body framing; scoped to include technical writing). [ASD-STE100](https://en.wikipedia.org/wiki/Simplified_Technical_English) (grammar rules worth taking, dictionary worth skipping).
