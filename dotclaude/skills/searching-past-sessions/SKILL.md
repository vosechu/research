---
name: searching-past-sessions
description: Use when the user refers to a previous Claude Code session, chat, or conversation: how something in it was worked out, which session did X, what was decided, where a number came from, or wanting to resume or continue it. Also when given a Slack link or figures that an earlier session produced.
---

# Searching Past Sessions

Every session is a JSONL transcript under `~/.claude/projects/<project-slug>/<sessionId>.jsonl`. Subagent transcripts are in `<sessionId>/subagents/`. A session started from a worktree is filed under the non-worktree project dir. The transcripts hold the real tool calls and results, so answer from them, not from memory or a compaction summary.

Default: search from this session. Do not suggest resuming.

If the user asks to resume, find the session with the steps below, then give them `cd <resume from> && claude -r <sessionId>` using the `resume from` line from `find` (not the cwd the session ended in; `claude -r` only finds a session from the folder it is filed under), and stop. Do not run it. After you give the command, offer once to answer from the transcript here instead.

The current session and its subagents match their own search terms; ignore them.

## Steps

1. **Collect clues.** Distinctive tokens beat common words: a number, a cell name, an account id, a filename. For a Slack permalink `p1791382624206089`, the first 10 digits are epoch seconds (`date -u -r 1791382624`); pass the whole epoch to `--at`. Use `--at` whenever you know when the thing was posted or run. If you were given a Slack link, read that message (and its thread) first and take the figures and link ids from it as your terms; a figure that appears in the message but never in the transcript may have been rounded or recomputed, so say so.
2. **Rank sessions.**
   `python3 -I scripts/sessions.py find <term> [<term>...] [--at EPOCH|ISO] [--since DATE] [--project SLUG]`
   Sessions matching more of your terms rank higher. A hit marked "inside a subagent transcript" means a subagent did the work.
3. **Read the window.**
   `python3 -I scripts/sessions.py show <sessionId> --grep <term> [--context N] [--subagents]`
   Prints the turns around each match, tool results truncated. Run `--help` for flags.
4. **Answer from the evidence.** Quote the command or query and its output, name the session id and time, and say whether the numbers in the transcript match the numbers you were asked about.

## Checks

- Zero hits is a claim about the index. Rerun with a term you know is in some session (a control from a different project) before saying a session is gone. Old sessions are deleted after the retention period.
- Thinking blocks are not shown. If the transcript has the calculation but not the reasoning, say so.
- Several sessions can match. Report the candidates and why you picked one; do not merge them.
- Do not paste a whole transcript; quote the few turns that answer the question.
