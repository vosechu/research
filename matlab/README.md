# MATLAB Tutor

A Claude Code agent that helps with introductory MATLAB coursework. It knows MATLAB's keywords, functions, common errors, and beginner patterns — and it's designed to help you learn, not just give you answers.

## Setup

1. Install [Claude Code](https://claude.ai/code) if you don't have it
2. Clone this repo and `cd` into the `matlab/` directory
3. That's it — the agent is ready to use

## Usage

From the `matlab/` directory, start Claude Code and invoke the tutor:

```
claude "use the matlab-tutor agent"
```

Or start Claude Code normally and ask it to use the matlab-tutor agent during your conversation.

## What it does

- **Homework help** — Guides you with hints and pseudocode instead of handing you the answer. If you're really stuck after a couple rounds, it'll walk you through the full solution.
- **Debugging** — Paste an error message and it'll tell you exactly what went wrong and how to fix it. No hand-holding here, just direct answers.
- **Utility code** — Need a helper function that isn't the point of the assignment? It'll just give it to you with comments.

## What's in here

- `matlab-reference.md` — A dense reference covering keywords, operators, ~100 common functions, ~30 error messages, beginner patterns, and gotchas
- `.claude/agents/matlab-tutor.md` — The agent definition that tells Claude how to behave as a tutor

## Tips

- Paste your actual code and error messages — the more context, the better the help
- If you're stuck on a concept, just ask "explain X" and it'll break it down
- Try things before asking — you'll learn more from "I tried this and it didn't work" than "how do I do this"
