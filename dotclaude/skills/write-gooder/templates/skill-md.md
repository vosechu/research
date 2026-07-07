# SKILL.md template

A SKILL.md is the body of a Claude Code skill: a task-shape-triggered instruction document that loads only when the model decides the user's request matches its `description`. This file teaches the **style** of a good SKILL.md. For the **process** of developing one iteratively (TDD for documentation, via subagent pressure tests), use `superpowers:writing-skills`.

## The description line is the routing decision

Nothing else in the skill matters if the model doesn't load it. The `description` is the only thing the model sees before deciding, and it sits in the system prompt budget every turn of every session.

- **Write it as a trigger, not a summary.** "Use when the user is drafting a PR description" beats "A skill for writing PR descriptions." State *when* to invoke, not *what* the skill contains.
- **Lead with the invocation condition:** "Use when …," "Invoke when the user asks …," "Activates when …"
- **Name the skill for the decision, not the topic.** `writing-pr-descriptions` beats `pr-guide`. The name is a second trigger surface — readable at a glance in skill lists.
- **Keep it short.** It lives in context on every turn. One or two sentences.
- **Include the value prop only after the trigger.** Trigger first, then a dash, then what the skill does.

**Lands:**

```yaml
---
name: writing-pr-descriptions
description: Use when drafting a PR description or `gh pr create` body — produces a 100–200 word summary + test plan with the right register for this repo.
---
```

**Misses:**

```yaml
---
name: pr-guide
description: A comprehensive guide for writing excellent pull request descriptions following best practices.
---
```

The second version is a summary. The model reads it, can't tell when to fire, and skips. "Comprehensive" and "best practices" are puff — cut them.

## Three-level progressive disclosure

A skill's total content is effectively unbounded because only the metadata stays resident.

1. **`name` + `description`** load in the system prompt at startup. Always resident.
2. **`SKILL.md` body** loads when Claude decides the description matches.
3. **Bundled files** (`references/`, `templates/`, `scripts/`) load **only on demand** via Read/Bash. They do NOT auto-load with the skill.

If you want Claude to read a reference file, `SKILL.md` must tell it to. Otherwise the file sits unread.

## SKILL.md is the hub; references load on demand

- **Separate mutually-exclusive context into sibling files.** If two workflows never run together, they don't share a file. Three parallel workflows in one SKILL.md means three files.
- **Reference by name from SKILL.md:** "Read `references/forms.md` to fill a form." Not by inlining the content.
- **Be explicit about scripts.** If `scripts/validate.sh` ships with the skill, tell Claude whether to *run it* or *read it*. Ambiguity gets skipped.

## Workflow design inside SKILL.md

A skill is an action guide, not a reference — unless the skill is explicitly a reference-type, in which case mark it so at the top. Most skills are workflows, and workflows get followed while prose essays don't.

- **Exit criteria per step.** "Run `bundle exec rspec spec/billing_spec.rb`, confirm green" — not "verify the tests pass."
- **Three-tier boundaries: Always do / Ask first / Never do.** Removes ambiguity about when to pause. Use a table when there's more than two or three entries per tier.
- **Anti-rationalization tables** for steps that get skipped in practice. Pair the excuse with the rebuttal inline — don't make Claude reconstruct the argument against cutting the corner.

Example of the third:

| Excuse | Rebuttal |
|---|---|
| "The existing test covers this." | Read the test. If the assertion is on the field you changed, fine; otherwise add one. |
| "It's a one-line change." | One-line changes break production more often than large ones because they skip review. |

## Frontmatter shape

```markdown
---
name: skill-name-in-kebab-case
description: Use when <trigger> — <one-line value prop>
---
```

The `name` is the directory name (`.claude/skills/skill-name/SKILL.md`). Kebab-case, no spaces, no underscores. Don't prefix with the plugin name — the harness adds that when the skill is part of a plugin.

## File layout

```
skills/
  skill-name/
    SKILL.md              # hub — required
    references/           # optional, loaded on demand
      schema.md
      forms.md
    templates/            # optional, loaded on demand
      form-template.md
    scripts/              # optional — document whether to run or read
      validate.sh
```

Nothing under `references/`, `templates/`, or `scripts/` loads automatically. If `SKILL.md` doesn't mention the file, it might as well not exist.

## Red flags

- **Skill fits in 40 lines and applies on every matching edit** → demote to a path-gated rule in `.claude/rules/`. Lazy-load saves nothing when the rule is always wanted.
- **Description is vague** ("Use when working on the system") → the agent will miss it. Rewrite with concrete intent verbs the user would actually say: "adding a migration," "drafting a PR," "onboarding a new engineer."
- **SKILL.md body is getting unwieldy** (past ~300 lines, or covering multiple workflows) → split parallel workflows into `references/` or sibling skills and load them by name.
- **Bundled scripts with no instruction** → be explicit in SKILL.md whether Claude should run or read each script.
- **SKILL.md describes the topic rather than the workflow** → the reader leaves without knowing what to do next. Rewrite as steps with exit criteria.

## Process

1. **Decide whether this is a skill at all.** Check the surface tree in `@references/appendix-llm.md`. File-path trigger → path-gated rule. Task-shape trigger → skill. Applies to every session → CLAUDE.md. No trigger → discard.
2. **Draft the description as a trigger.** Start with "Use when…" and name a concrete user action. Read it back and ask: if the user said X, would I fire this skill?
3. **Write the body as workflow with exit criteria.** Numbered steps, each with a verifiable exit condition. If a step is "think about Y," it will be skipped.
4. **Split overflow into references.** When two procedures don't run together, give them separate files and have SKILL.md point at the right one by name.
5. **Pressure-test the boundaries.** Read each step and ask: always, ask-first, or never? If ambiguous, rewrite. The three-tier boundary is how the model knows when to pause.
6. **Verify length.** Most SKILL.md files land ≤150 lines. Past that, the model starts losing the tail. If you're over, you're probably missing a reference split.
