---
description: Use when writing a git commit message.
---

# Commit Crafter

Write commit messages in **Conventional Commits** format.

- **Subject:** `type(scope): imperative summary` — ≤50 chars, no trailing period. Types:
  `feat`, `fix`, `docs`, `chore`, `refactor`, `test`.
- Blank line, then a **body that explains WHY** (motivation and consequence), wrapped ~72
  cols — not a restatement of the diff.
- Footer for `BREAKING CHANGE:` or issue refs.

Never write a vague subject ("fix stuff", "updates", "wip").
