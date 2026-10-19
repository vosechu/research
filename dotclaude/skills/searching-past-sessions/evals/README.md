# searching-past-sessions: eval pack

Subject: `searching-past-sessions` (uncommitted at time of eval, 2026-10-15). Type: technique. Scenario style: application. Fixture: `fixtures/criteria.md` (acceptance criteria, written before any run, with the real session ids, names and figures replaced by placeholders).

The raw judge write-ups and the blind-label key are not included: they quote real queries and session content from private work transcripts. Results below are the recorded summaries.

## Arms

- **baseline:** fresh `general-purpose` subagent, skill unlinked from `~/.claude/skills`, story only.
- **with-skill:** same story, `SKILL.md` force-pasted into the prompt.
- **triggering:** skill symlinked into `~/.claude/skills`, story only, no mention of the skill. Read each subagent transcript for a `Skill` tool call.

## Scenarios

| id | story (abridged) | expected |
|---|---|---|
| P1 recall | where did a fitted cost constant come from, and why did it change | fire |
| P2 resume | get me back into the conversation that built a PR-sweep skill | fire |
| P3 absence | find the earlier talk about migrating a made-up service off Kafka (no such session exists) | fire |
| T1/T2/T3 | fresh phrasings of recall, find-the-session, and resume | fire |
| N1/N2/N3 | grep for a string in the skills dir; last 5 git commits; what does a named skill do | silent |

## Recorded results: effectiveness (2 reps per cell, judge blind, 4 outputs per scenario)

| scenario | criteria passed, baseline | criteria passed, with-skill | judge order, best to worst |
|---|---|---|---|
| P1 recall (5 AC) | 5/5, 5/5 | 5/5, 5/5 | baseline-1, skill-2, baseline-2, skill-1 |
| P2 resume (4 AC) | 3/4, 3/4 (both fail AC4: long recap) | 4/4, 3/4 | skill-1, skill-2, baseline-2, baseline-1 |
| P3 absence (4 AC) | 4/4, 4/4 | 4/4, 4/4 | baseline-1, skill-1, skill-2, baseline-2 |

| | baseline | with-skill |
|---|---|---|
| tool calls, 6 runs (P1 21,14; P2 6,8; P3 7,7 / P1 8,13; P2 4,4; P3 4,4) | 63 | 37 |
| mean subagent tokens | 83.8k | 79.4k |

Judge rationale, P2: the best output gave the exact cd plus resume line, a short justification tied to commit times, and an honest "not verified" note. The three failing outputs (two baseline, one skill) added recaps or state dumps beyond identifying the session.

## Recorded results: triggering

| scenario | expected | old description | new description |
|---|---|---|---|
| T1 recall | fire | 1/2 | 2/2 |
| T2 find session | fire | 0/2 | 1/2 |
| T3 resume | fire | 0/2 | 2/2 |
| N1, N2, N3 | silent | 0/3 | 0/3 |

N1-N3 above share almost no vocabulary with the skill, so their 0/6 says little. The vocabulary-sharing near-misses are below.

### Near-miss negatives (new description, 5 reps each, run after the rewrite)

| id | prompt shape | skill loaded |
|---|---|---|
| NM1 | "what did we decide earlier in this conversation" (answer is pasted context) | 0/5 |
| NM2 | "where does this constant in a script come from" (answer is in the code) | 0/5 |
| NM3 | "who last changed this script and why" (answer is `git log`) | 0/5 |
| NM4 | "what do my saved memory notes say about worktrees and committing" | 0/5 |
| NM5 | "here is the plan, continue with the next task" | 0/5 |
| NM6 | "summarize this message" with a few figures pasted in | 0/5 |

0 of 30 loaded the skill; none ran `scripts/sessions.py`. Check validity: the same transcript test returns a hit on a known-firing run. Each answered from the right source (pasted context, the code, `git log`, the memory file). Precision on these near-misses is 30/30 on one wording per shape; other wordings are untested. NM6 is the weakest guard of the description's "figures that an earlier session produced" clause, since the figures were pasted in, not linked.

The skill was in every subagent roster before its first tool call (checked: first mention at transcript line 6, first `tool_use` at line 12 or 13). The T2 rep 1 miss ran `sessions.py` five times without a `Skill` call.

## Meta-finding

The skill does not change correctness: the base agent already finds the right session in all three scenarios, helped by the user-global CLAUDE.md that names the transcript path. Its measurable effect is fewer tool calls (about 41% fewer here), near-identical tokens, and in P2 a tighter answer. Triggering was the real defect: the first description fired 1 of 6, because agents preferred grepping directly.

## Defects the eval found

1. **Resume folder wrong.** `find` printed the first `cwd` it saw. For one session that was a different repo from the one it was filed under, but `claude -r` finds a session only from the folder it is filed under. One baseline agent got it right by hand. Fixed: `find` now prints `resume from`, the recorded `cwd` whose path encodes to the project folder name.
2. **Description too narrow.** It named neither "chat", "conversation", nor resuming. Rewritten; re-tested above.

## REFACTOR applied and re-tested

- Description changed to the "previous session, chat, or conversation ... or wanting to resume or continue it" form. Same T/N prompts re-run: positives 1/6 to 5/6, negatives unchanged at 0/3.
- `scripts/sessions.py` resume-dir fix verified on a session filed under a different repo and on two sessions filed under the research repo. The with-skill runs in the effectiveness phase ran before this fix, so no recorded agent run exercised the corrected `resume from` line except T3 re-runs, which gave the correct folder.

## Threats to validity

- **Small N.** 2 reps per effectiveness cell and 2 per triggering cell. A sentinel, not a verdict. The 5% token difference is within noise.
- **Control floor.** The baseline inherits the user-global CLAUDE.md that says where session JSONLs live, and agent memory. Lift is understated.
- **Answer leak, P1.** The criteria file was written in the same session the subagents search, so it sits in a transcript that a search for the P1 constants matches. In baseline rep 2 and with-skill rep 2 the criteria text reached the agent's tool results (one transcript hit each; the other two P1 runs had none). Only P1 rep 1 of each arm is clean. The judge found all four P1 answers correct and verified quoted queries against the real transcript, so the answers are substantively sourced, but the leak cannot be ruled out as a hint.
- **Sibling contamination.** Eval prompts and outputs are written to transcripts that later runs can search. The P3 search term matched only the eval session itself and was correctly discounted by all four runs.
- **Retention and judge.** The judge is a general-purpose agent; its P2 note that two outputs disagree about closed PRs was not resolved from text.
- **Not run:** the isolated-description baseline (skill alone in a clean roster). Triggering here is competitive only.
