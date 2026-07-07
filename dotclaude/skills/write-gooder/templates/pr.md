# PR description template

A PR description exists to **help a human reviewer review well**. It is not a replacement for review, a summary of everything you did, or a convincing pitch. Give them the facts and the pointers, then get out of the way.

## Structure

Five elements. Any of them can be empty when there's nothing to say — that's fine and often the right answer. Order matters: description first, checkbox second, so the reviewer knows what they'd be agreeing to before seeing the gate.

### 1. Description

What this does and why, in whatever number of sentences it takes. One sentence is great when it fits. Two or three is fine for work with real context.

**Do not assume the reviewer shares your vocabulary.** If a term isn't already used elsewhere in the repo, define it at first use — even briefly. The reviewer may have last seen this subsystem six months ago, or never. Examples of terms that look obvious to an author but need a one-line gloss for a cold reader:

- Domain jargon: "evals" (automated checks that score LLM output), "predict-don't-act" (a prompt pattern where the model says what it *would* do, without doing it), "threshold-gating" (each assertion must pass ≥ F of N runs for the case to PASS).
- Feature names the reviewer may not have installed: skills, plugins, agents, specific commands.
- Implementation terms that have other meanings in the wider ecosystem (e.g., "routing cases" — clarify it's about which skill auto-loads, not about HTTP routing).

Also check: **is this framing accurate from the reviewer's point of view?** A change that felt like "rewriting an existing bash script" to you looks like "adding a new tool" to a reviewer who never saw the bash version. **Describe the landing state, not the journey.**

Do NOT include links to local working documents (specs, plans, `docs/superpowers/specs/*`). Those are for author alignment. If the design was committed to the repo's permanent docs, link to that.

### 2. Human review checkbox

One line, always unticked by default:

```markdown
- [ ] I, the human author, have fully read and comprehended this code. Until this is checked, please don't waste time reviewing.
```

The wording is deliberate — "I, the human author" makes it clear this is not about the reviewer, and "don't waste time reviewing" tells the reviewer what to do if they see it unticked (namely: come back later).

The checkbox raises the social cost of rubber-stamp review. If it's still unticked at merge time, something has gone wrong.

### 3. Starting points in the code

Where should a reviewer look first? Give them pointers with a one-line note on each.

**Use the PR diff URL** — the one GitHub produces when you click a line number in the "Files changed" tab. It looks like:

```
.../pull/<N>/files#diff-<sha256-of-path>R<line>
```

This drops the reviewer into the PR's diff view with the exact line highlighted. It's what they want: they get to see the change in context (added vs unchanged lines), with review-comment affordances right there.

**How to get this link:**

1. Open the PR on GitHub → Files changed tab.
2. Navigate to the line you want to point at.
3. Hover on the line number in the gutter; a `#` icon appears. Click it. The URL in your address bar now contains the `diff-<hash>R<line>` anchor. Copy that.

**If you're an agent without a browser, you can compute the hash.** The `<hash>` is `sha256(<repo-relative file path>)`, lowercase hex, no newline:

```
echo -n "nr/skills/jira-adf-format/SKILL.md" | shasum -a 256
# → 0d4d6ad9ac4b043af9b8b495997ee0d9028c80a81b81df29f4827a301044d9b3
```

The suffix is `R<line>` for added/unchanged lines (right side of the diff) or `L<line>` for deleted-only lines (left side). For an added line 3:

```
https://<host>/<org>/<repo>/pull/<N>/files#diff-0d4d6ad9…1044d9b3R3
```

This holds on github.com and GitHub Enterprise alike. Don't fabricate the hash — compute it. A made-up hash produces a link that loads the Files tab but fails to scroll to or highlight the target line, and there's no visible error.

Format it as a Markdown link:

```markdown
- [tools/skill-evals/run-evals.rb:237](https://source.datanerd.us/org/repo/pull/149/files#diff-<hash>R237) — the predict-don't-act prompt (read carefully)
```

**When to use a SHA-pinned blob URL instead** (`blob/<sha>/path#L123`): for references outside the PR context — archival links in tickets, docs, or cross-repo posts — use the `y`-key permalink. These are permanent (commits are immutable) but land in the file view, not the diff view, so they're worse for in-PR review but better for long-lived references.

**Don't use `blob/<branch>/path` URLs** — line numbers drift when the branch moves, and the link silently points to the wrong code after any commit.

**It's okay to have fewer pointers than you feel pressure to include.** If you list five and the fifth one is "`README.md:27` — usage docs," cut it. A pointer that a reviewer wouldn't actually open is filler. Two strong pointers beat six weak ones. Order by importance, not by file path or line number.

### 4. Concerns / Open questions

One section for two related things, since they share a shape: "here's a thing I want the reviewer to focus on."

- **Concerns** = risks you've already accepted and want a sanity check on.
- **Open questions** = decisions you haven't made yet and want input on.

Mix them freely — the reviewer doesn't need the taxonomy, they need the content. Label individual items if the distinction matters ("*Concern:*" vs "*Question:*" prefixes), or don't.

Each item has three parts:

1. **The concrete thing** (a specific line, flag, default, or decision — not "concurrency").
2. **Why it matters** (what breaks, or what the trade-off is).
3. **What I did and why — or what options I'm weighing.** This is the part that makes the reviewer's response actionable.

Example of a one-line item that's fine most of the time:

> **No timeout on `Open3.capture2e` (lines 126, 168, 253)** — a hung `claude -p` hangs the runner; only user Ctrl-C kills it. Left as-is because a reasonable default is hard to pick (contract cases legitimately take 3–6 min); open to a `--timeout` flag.

Example of a long-form item that's worth the space because the decision is load-bearing:

> **`--max-turns 1` is set on the routing dispatch (line 253) but not on the install probe (line 126).**
>
> *Why it matters:* with some plugins installed, claude spends its first turn on a tool call and doesn't emit text before the limit trips. The probe hit this in development. Routing dispatch is the same kind of subagent call and could hit the same failure.
>
> *Why I kept it:* smoke tests (N=2 and N=5 against nr-sec) never tripped it, and dropping the limit adds ~25–40 min of wall clock to a default 30-case × 5-run suite. Trading speed against a failure we haven't observed. If you can construct a query that reliably trips it, I'll drop the flag.

**Length is determined by how much the reviewer needs to say yes or no.** Most items are one line. A few warrant the full "thing / why / what I did" unpacking. Either is fine. What's NOT fine: dense one-liners that hide a real tradeoff ("`--max-turns 1` trips sometimes, left it in") — those punt the analysis to the reviewer.

**Order by importance** — the item most likely to affect whether this PR lands correctly goes first. Don't order by file path or by the sequence in which concerns occurred to you.

**If there's nothing, say that.** "Nothing comes to mind" is common, valid, and a stronger signal than three invented concerns. Part of the reviewer's value is finding what you missed; don't crowd them out by filling the section with placeholder worries.

### 5. What we've done to reduce risk

Evidence, not reassurance. List the concrete checks, tests, or validations you ran, including tools the repo provides. Not "I tested it thoroughly" — *which* tests, *against what*, *with what result*.

This section is a record **for the author's benefit, shown to the reviewer**. Reviewers almost never run the listed commands themselves — they might not have the environment, credentials, or time, and their feedback can still be valuable without re-running anything. So the purpose of the checklist isn't "here's your to-do list" — it's "here's what I verified, and here's what I didn't."

**Tick checkboxes honestly:**

- `[x]` — I ran this against the code in **this** push and it passed. If the code has since changed, re-run before ticking.
- `[ ]` — I haven't run this yet, OR it failed, OR I ran it against an earlier version and haven't re-verified.
- Don't tick something just because you ran it last week. A tick against stale code is worse than an empty box.
- If something can't be meaningfully tested (e.g. "exit handler fires on SIGTERM" and you can't trigger it locally), list it anyway with an empty box and a short note — the reviewer knows you thought about it and where the coverage gap is.

Format:

```markdown
## Test plan / risk reduction

- [x] `/usr/bin/ruby -c tools/skill-evals/run-evals.rb` — syntax clean on 2.6.10 and 3.3.9
- [x] Smoke test: N=2 run against `nr-sec/skills/spec-security-assessment`, both cases exited 1 with the failures I expected
- [x] Invalid flags (`--repeat 0`, `--min-pass-rate 2`, `--jobs -1`) exit 1 with clear `error:` messages
- [ ] End-to-end N=5 run — not done locally (would cost ~30 min of API time); intentionally deferred
```

Write each item as a **specific fact a reviewer can check against the diff**, not a task description. "Smoke tested" is worse than "N=2 run against `nr-sec/skills/spec-security-assessment`, both cases exited 1 with expected failures" — the second lets the reviewer see whether your claim matches what the code actually does.

**On each push, re-check your ticks.** If you touched code that a ticked item covers, either re-run the check or untick the box. A PR-description checklist that drifts from reality faster than the code becomes actively harmful — the reviewer assumes ticked means verified, and silently-stale ticks erode that trust.

## Length

Be as short as gets the elements across. A one-file config change fits in 40 words total:

```markdown
- [ ] I have fully read and comprehended this code.

Adds `nr-db` to CODEOWNERS so database-owning team gets review requests on nr-db plugin changes.

- [`.github/CODEOWNERS:45`](https://source.datanerd.us/org/repo/pull/<N>/files#diff-<hash>R45)

## Test plan
- [ ] CODEOWNERS entry validates (GitHub lint runs automatically)
```

A complex refactor might need 250-400 words to lay out enough pointers and concerns. **Length is not the metric — clarity is.** If you can cut a sentence without losing a reviewer-useful fact, cut it. If a long PR needs more pointers, write more pointers.

Things that almost always ARE padding:

- Research recaps that duplicate a linked TODO or spec
- Prose narratives of verification steps (use the test-plan checklist instead)
- Self-assessment ("this feels clean", "I'm excited about")
- Restating the commit messages

Things that are NOT padding even when they make the PR long:

- More pointers, if the PR touches more parts of the codebase
- More concerns, if the PR is riskier
- More test items, if there's more to check

## Formatting conventions

- H2 headers for `## Test plan` (and other named sections if you split concerns out).
- Unnumbered `-` bullets for pointers and concerns.
- Inline-code (`` ` ``) for file paths, line numbers, flags, commands.
- File references are Markdown links: `[path:line](<pr-diff-url>)`. The visible text is `path:line` (reviewers copy-paste that into editors); the link target is the PR diff URL (reviewers click to see the line highlighted in context). Never write bare `path:line` without a link.
- If the repo uses PR templates, check `.github/PULL_REQUEST_TEMPLATE.md` and extend rather than override.

## Process

1. **Add each element to your task list.** Use TaskCreate with one task per element: description, checkbox, starting points, concerns / open questions, test plan. Drafting in order prevents you from skipping ahead to what's easy (usually test plan) and starving what's hard (usually description + concerns).
2. **Draft each element in order.** Mark the task in_progress while you write it, completed when you move on.
3. **For each sentence, ask: "does a reviewer need this to review well, or am I narrating?"** Narration is the most common form of padding — self-congratulation, history of abandoned approaches, restating commit messages. Cut it.
4. **Read it as a reviewer who hasn't seen the code.** This is the test that matters most. After 20 seconds, can they (a) say what the PR does, (b) point to the most important file, (c) name something to watch for? If any of the three fails, the body is broken — usually because the description hides the point or the starting-points list is missing the load-bearing pointer. Fix that, not prose.
5. **Leave the human-review checkbox unticked.**
