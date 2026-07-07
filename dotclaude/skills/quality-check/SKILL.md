---
name: quality-check
description: Run all quality checks (types, tests, lint, format) in sequence
disable-model-invocation: true
---

# Quality Check

Run the project's quality checks in sequence. Stop on the first failure.

## Commands (in order)

Use the project's actual commands (npm scripts, make targets, gradle, etc.).
Typical order: 1) type check  2) unit tests  3) lint  4) format check
5) vulnerability scan (if present).

On first failure: stop, print the failing command + output, report which check
failed and why. Do not attempt to fix it unless asked.

## Results summary

| Check  | Status    | Notes |
|--------|-----------|-------|
| test   | pass/FAIL |       |
| lint   | pass/FAIL |       |
| format | pass/FAIL |       |

## Post-test verification (from @.claude/rules/llm-test-verification.md)

If tests were added/modified, after they pass check:

- Test names match contents (no misleading names)
- No trivially passing tests (asserting on mocks, `true === true`)
- No duplicate coverage (different names, same assertions)
- `// AI-DEV` confirmed tests not modified or removed
- No integration tests where unit tests would suffice

## Testing philosophy (from @.claude/rules/testing.md)

- Unit tests are 95% of the suite, fast and isolated
- Sandi Metz: test the public interface, mock outgoing commands, not privates
- Don't mock what you don't own — wrap it, mock the wrapper, integration-test
  the real thing
