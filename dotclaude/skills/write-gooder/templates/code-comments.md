# Code comment template

Most comments should not exist. The default is no comment; a comment earns its place by carrying something the reader cannot get from the code.

Read `references/doc-writing-core.md`, which already holds the governing rule: **a code comment states the constraint a future edit could violate, not the history of how you found it.** This template adds the decision of whether to write one at all, and what to do when you don't know why something is there.

Load no appendix. The human/LLM scanning rules (F-pattern, reading age, front-loading) are for documents, not for two clauses beside a config value.

## The delete test

For every comment, ask: **would deleting this let someone silently break the thing it sits next to?**

- **Yes** — keep it. Someone "tidying up" removes the line and the failure shows up later, somewhere else.
- **No** — delete it. It is decoration, and decoration costs attention on every future read.

Silently is the load-bearing word. If deleting the comment causes a loud, immediate failure, the code already teaches the lesson, so the comment adds nothing.

## What earns a comment

- **Units, formats, or ranges that fail quietly when wrong.** A value parsed only in whole GB, where `512m` produces a confusing unrelated error.
- **Values that look wrong but are load-bearing.** A dotted hostname that reads like a typo, a duplicated string two systems must agree on.
- **Defaults that are unusable.** A setting that ships as `0` and crashes at startup, so the local override is not arbitrary.
- **Ordering that matters.** Two steps whose sequence is invisible from the call site.

## What does not

- **Provenance.** "Copied from the deploy config," "from the secret store," "per the design doc." Where it came from is not why it is there.
- **Restatement.** `## Creates the bucket, then exits` above a line that already says `mc mb`.
- **In-process notes.** "This used to be X before we hit Y," "as discussed," a bare ticket number standing in for a reason.
- **Section labels.** `# --- env vars ---` over a block of environment variables.

## When you don't know why

**Leave it uncommented.** Never invent a rationale.

A guessed reason is worse than silence: the next reader trusts it, and a plausible-but-wrong explanation survives longer than an obvious gap. If the reason matters and you cannot determine it, say so outside the code — in the PR, or by asking the person who wrote it.

## Placement

Put the comment inside the block it protects, adjacent to the line it governs, not at the top of the file. A reader editing line 300 does not scroll to line 1, and a model editing a function sees a window around it. Same locality rule as `rules/ai-dev.md`.

## AI-DEV markers are exempt

`// AI-DEV:` comments are binding instructions, not explanation. The delete test does not apply. Never remove or reword one, even when it looks redundant. See `rules/ai-dev.md`.

## Process

1. **List every comment in the diff**, including ones you just wrote.
2. **Run the delete test on each.** Default to deleting.
3. **For survivors, cut to one line** where the constraint fits in one.
4. **Check each survivor names a mechanism**, not a source or a story.
5. **Count what you kept.** Keeping most of what you drafted means you ran the test as the author, not as the next reader.
