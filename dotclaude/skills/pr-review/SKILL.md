---
name: pr-review
description: Review a pull request for quality, security, and best practices
disable-model-invocation: true
---

# PR Review

Review the current branch's changes (or a specified PR) against the universal
PR review checklist, then layer on any project-specific criteria.

## Process

1. **Gather context**: `git diff <base>...HEAD` and `git log <base>..HEAD --oneline`
   (base usually `main`/`master`). Read the PR description, linked Jira tickets,
   commit messages. Understand intent before reviewing.
2. **Quality gate first**: run the project's lint + test (+ type/format) — see the
   `quality-check` skill if present. Any failure is blocking; stop and report.
3. **Universal checklist** (from @.claude/rules/pr-review-checklist.md):
   - Security: no secrets, no unverified deps, no injection, inputs validated
   - Testing: new behavior has tests, confirmed (`// AI-DEV`) tests untouched,
     test names match contents
   - Code quality: focused changes, no over-engineering, no dead code
   - Commits: conventional format, "why" not "what"
   - AI-specific: AI-DEV markers preserved, no hallucinated imports, no scope creep
4. **Project-specific checks**: apply any repo-specific rules under `.claude/rules/`
   (architecture, type-strictness, platform conventions). If none, skip.
5. **Failure thinking** (relevant categories only): Logic (kill switch? skipped
   guards?), Edge cases / Nulls, Network, Deployment, Multi-threading / HA.
6. **Report**: severity-rate every finding blocking / non-blocking / trivial.
   Comment on the code, not the author; word critiques as questions.
