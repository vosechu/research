# CLAUDE.md template

CLAUDE.md is Claude Code's always-loaded project memory: every line sits in context for every turn of every session in the project, so every line is a permanent token tax that needs to earn its keep.

## Before writing, pick a surface

Most drafts that land in CLAUDE.md belong somewhere else. Walk this list in order; first match wins.

1. **Answered by `grep`, `ls`, `git log`, or an existing doc?** → discard.
2. **One-time state** (today's task, current counts, dated measurements)? → discard.
3. **Relevant to ~90%+ of sessions in this repo?** → CLAUDE.md.
4. **Applies every time specific files are edited?** → path-gated rule in `.claude/rules/*.md` with `paths:` frontmatter. Example: `testing.md` scoped to `**/*.test.ts` loads whenever a test is touched, costs nothing when it isn't.
5. **Applies to a task shape** (adding a migration, writing a PR description) that cuts across files? → skill.
6. **Private to you, not the project?** → memory (and read the memory gate before writing).
7. **Otherwise** → discard. Noise in an always-loaded file is worse than forgetting.

**File-path trigger → rule. Task-shape trigger → skill.** Dumping into CLAUDE.md by default is the common failure mode.

## What belongs in CLAUDE.md

| Include | Cut |
|---|---|
| Non-discoverable tooling (`uv` not `pip`, `bundle exec rake test` not `rake test`) | Anything `grep` or `ls` finds |
| Non-obvious gotchas tied to a past failure | "Write clean code," "follow best practices" |
| Style rules that deviate from language defaults | Defaults the model already knows |
| Repo etiquette (branch naming, PR conventions, commit format) | Info that rots (current state, counts, dates) |
| Architectural decisions specific to this project | Long tutorials — link them with `@path` |
| Dev-environment quirks (env vars, auth flows, non-default `GH_HOST`) | Self-evident practices |

Every line you keep should pass one test: **would removing this cause a mistake?** If no, delete.

## Authoring discipline

- **Every line traces to a specific failure** the model made, or a hard constraint it can't infer from the repo. Rules without incidents are noise.
- **Prune when stale, review when things go wrong.** Don't add without subtracting.
- **Don't write what the repo answers.** If `README.md` has build commands, link to it: `See @README.md for build/test commands.`
- **Fix the code before fixing the prose.** If the same gotcha keeps appearing, restructure the confusing code — it scales better than a warning.
- **Specificity beats taste.** "Use 2-space indentation" beats "format code nicely." "Run `bundle exec rake test`" beats "run the tests." "Never commit to `main`" beats "follow good branch hygiene."

## Structure rules

- **≤200 lines.** Anthropic's recommendation. Past that, reliability drops — the model starts ignoring rules buried in the tail.
- **One topic per section** with a descriptive H2 or H3 heading. Don't mix "commands" and "architecture" under one heading.
- **`@path/to/file` imports** for anything longer than a paragraph. Relative paths resolve from the importing file. Imports recurse up to 5 hops.
- **`CLAUDE.local.md`** at the repo root for personal, gitignored content (your machine's paths, your API keys, personal reminders). Don't put team content there.
- **Semantic tags** (`<IMPORTANT>`, `<NEVER>`) for safety rules that have been ignored before. Reserve them — overuse dulls the signal.

## Discovery: how CLAUDE.md actually loads

Discovery walks **up** from cwd to the filesystem root. Every `CLAUDE.md` in that chain loads. The one closest to cwd loads *last* and takes effective precedence when rules contradict.

- Don't put a `CLAUDE.md` at `/` or `$HOME` — it loads for every project.
- Subdirectory `CLAUDE.md` files load **on demand** when Claude reads files in that subdirectory. Use them to scope context to a sub-project inside a monorepo.
- If multiple `CLAUDE.md` files in the hierarchy contradict each other, Claude picks arbitrarily. Reconcile them.

## Red flags

- Content applies to only one subsystem → move to a path-gated rule.
- A section grows past ~30 lines → extract it to `.claude/rules/<topic>.md` and link with `@path`.
- The line tells the model something it already knows → delete.
- The same rule appears in two `CLAUDE.md` files in the hierarchy → reconcile; Claude picks arbitrarily between them.
- The file is over 200 lines → split. Past 200, later sections get ignored.

## Example: the opening section

The first section is the highest-leverage real estate in the file. Make it concrete.

**Lands:**

> ## Project Overview
>
> Ruby on Rails 7.1 monolith serving the billing UI. Postgres 15 primary, Redis for Sidekiq jobs. Deployed to Kubernetes via Argo CD; see @docs/deploy.md for the rollout flow. Test suite is RSpec — `bundle exec rspec`, not `rake test`.

**Don't do this:**

> ## Project Overview
>
> This is a modern, robust Ruby on Rails application that serves as the backbone of our billing infrastructure. Our team has invested significant effort in building a maintainable, well-tested codebase that reflects best practices across the Ruby ecosystem. The project leverages a variety of cutting-edge tools and follows industry-standard patterns.

The second version has no information. Every adjective could be deleted without loss. The first version tells the model: Rails 7.1, Postgres 15, Sidekiq, Kubernetes+Argo, `bundle exec rspec`. Five facts, four of which the model would get wrong by default.

The shape of the file after the opening is up to the project. Some projects lead with `## Commands`, some with `## Important paths`, some with `## Architecture`. No fixed skeleton — put the highest-leverage content first.

## Process

1. **Read the existing `CLAUDE.md`** (if any). For each line, ask: what failure does this prevent? If you can't name one, flag it.
2. **For each new line you want to add**, name the specific trigger — a past mistake, a non-default command, a convention the model can't infer.
3. **Run the surface test** from the top of this template. If the content belongs in a rule, skill, or memory, route it there instead.
4. **Apply the removal test** to every line: "Would removing this cause a mistake?" If no, cut.
5. **Check length.** ≤200 lines total. If a section is past 30 lines, extract it to `.claude/rules/<topic>.md` and link with `@path`.
6. **Reconcile against other `CLAUDE.md` files** up the tree and in subdirectories. Contradictions resolve arbitrarily at runtime.
