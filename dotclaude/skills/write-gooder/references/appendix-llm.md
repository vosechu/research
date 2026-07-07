# Appendix — LLM-only mechanics

Extends [doc-writing-core.md](doc-writing-core.md) for docs a model reads.

> **Note on model knowledge.** Current Claude models are often out of date about Claude Code mechanics. Skills, hooks, `paths:` frontmatter, and memory discovery have all evolved. If a model recommends something that contradicts this doc, check https://docs.claude.com/en/docs/claude-code/ rather than trusting model memory.

## What this appendix covers

Rules tagged by category for downstream skill-authors:

- **[S] Surface** — where content lives (most of this file).
- **[A] Authoring** — drafting, iteration, maintenance, red-flag triage.
- **[C] Comprehension** — LLM-specific comprehension mechanics (delimiters, markdown over HTML, semantic tags).

Many rules are dual **[S] [A]**: the rule is both "put it here" and "prune it this way."

1. [Universal — any LLM-facing doc](#universal--any-llm-facing-doc)
2. [CLAUDE.md and always-loaded docs](#claudemd-and-always-loaded-docs)
3. [Rules (`.claude/rules/*.md`)](#rules-claudeulesmd)
4. [Skills (`.claude/skills/<name>/SKILL.md`)](#skills-claudeskillsnameskillmd)
5. [Memory (`MEMORY.md` and entries)](#memory-memorymd-and-entries)
6. [Hooks](#hooks)

---

## Universal — any LLM-facing doc

- **Markdown over HTML.** ~50% lower token overhead (Osmani/AEO). **[C]**
- **Formats from training data** beat custom structures. YAML frontmatter, fenced code, standard headings — all cheap to parse. **[C]**
- **Code examples immediately after claims.** Tight coupling reduces parsing errors. **[C]**
- **`@path/to/file` imports over inlining** for anything longer than a paragraph. Relative paths resolve to the importing file. Imports recurse up to 5 hops. **[S]**
- **Wrap critical safety guidance in semantic tags** (`<IMPORTANT>`, `<NEVER>`) so priority survives scanning. **[C]**
- **Reserve "IMPORTANT" / "YOU MUST"** for rules that have been ignored. Overuse dulls the signal. **[C]**

### The surface-choice decision

Before writing, decide where content lives. Wrong surface = either permanent token tax or load misses. Adapted from `/nr:reflect`: **[S]**

1. **Derivable from code, `git log`, or an existing doc?** → **discard.** Never paraphrase what `grep` answers faster. **[S]**
2. **One-time specifics** (today's task, current state, counts, dates)? → **discard.** **[S]**
3. **Relevant to ~90%+ of sessions in this repo?** → **CLAUDE.md.** **[S]**
4. **Always applies when editing specific files?** → **path-gated rule.** Trigger is a file glob. Example: a `testing.md` rule scoped to `**/*.test.ts` loads every time Claude edits a test file, and carries rules about mocking, fixtures, and assertion style. **[S]**
5. **Applies to a task shape** that cuts across paths, or only some edits in a path? → **skill.** Trigger is the description matching what the user asked for. Example: "adding a database migration" spans schema files, model files, seed files, and tests — so it's a skill, not a rule on any one path. **[S]**
6. **Private to you working on this project**, not the project itself? → **memory** (tight gate; see §Memory). **[S]**
7. **Otherwise** → **discard.** Noise in permanent files is worse than forgetting. **[S]**

**File-path trigger → rule. Task-shape trigger → skill.** When both apply, split: the rule carries always-true invariants and points at the skill for dense procedures. **[S]**

---

## CLAUDE.md and always-loaded docs

### Red flags

- Content that only applies to one subsystem → move to a rule. **[S]**
- A topic grows past 30 lines → move it to a rule and link with `@path`. **[S]**
- Docs that only give instructions the model already knows by default → delete. **[A]**
- Contradictory rules across multiple CLAUDE.md files in the hierarchy → Claude picks arbitrarily. Reconcile. **[A]**

### Rules

- **≤200 lines** for CLAUDE.md. Anthropic recommendation, not a hard cap — past 200, reliability drops. **[S]**
- **Discovery walks up the directory tree from cwd.** Every directory from cwd to the filesystem root is checked; `foo/CLAUDE.md` loads before `foo/bar/CLAUDE.md`, so the file closest to cwd loads *last* (takes effective precedence). Subdirectory CLAUDE.md files load on demand when Claude reads files in them. A CLAUDE.md at `/` would be loaded by every project — don't do that. **[S]**
- **Every line traces to a specific failure** the model made, or a hard constraint it can't infer. Rules without incidents are noise. **[A]**
- **Ask of every line: "Would removing this cause a mistake?"** If no, delete. **[A]**
- **`CLAUDE.local.md`** at project root for personal, gitignored content that doesn't belong in team files. **[S]**
- **Prune ruthlessly.** Review when things go wrong, prune when stale. **[A]**

### Include / cut

| Include | Cut |
|---|---|
| Non-discoverable tooling (`uv` vs `pip`, non-default commands) | Anything `grep` or `ls` would find |
| Non-obvious gotchas from past failures | "Write clean code," "follow best practices" |
| Code-style rules that deviate from language default | Defaults the model already knows |
| Repo etiquette (branch naming, PR conventions) | Frequently changing info — it rots |
| Architectural decisions specific to this project | Long tutorials — link them |
| Dev-environment quirks (env vars, auth flows) | Self-evident practices |

If a gotcha keeps appearing in instructions, **fix the code** — restructuring confusing code scales better than prose warnings (Osmani).

---

## Rules (`.claude/rules/*.md`)

### Red flags

- Rule over ~300 lines and most tasks don't need all of it → split the dense specialist part into a skill, link from the rule. **[S] [A]**
- Rule only applies to *some* edits in the path → it's a goal-triggered concern; make it a skill. **[S]**
- Rule grows past ~150 lines without a `paths:` trigger → it's acting as a second CLAUDE.md; split or scope. **[S]**

### Rules

- **Path-gated loading.** Use `paths:` frontmatter to load only when matching files are touched. 100% reliable — the agent cannot miss a path match. **[S]**
- **Cost model:** tokens spent every time matching files are touched, whether or not the task needs the rule. Keep each rule tight. **[S]**
- **Use for** conventions that apply to *every* edit in the matching path: code style, naming, schemas, file-shape invariants. **[S]**
- **Target ≤150 lines per rule.** Longer means the rule is doing two jobs or the topic should be a skill. **[S]**
- **Index skills from rules** with explicit pointers. Makes skill discovery mechanical: **[S]**

  ```
  → invoke /add-migration when the change touches schema or seed data.
  ```

- **One topic per file.** All `.md` files in `.claude/rules/` discover recursively. **[S]**

---

## Skills (`.claude/skills/<name>/SKILL.md`)

Skills use **three-level progressive disclosure**:

1. `name` + `description` load in the system prompt at startup.
2. `SKILL.md` body loads when Claude decides the description matches.
3. Bundled reference files load on demand via Read/Bash — they do NOT auto-load.

Total skill content is effectively unbounded because only the metadata stays resident.

### Red flags

- Skill fits in 40 lines and applies on every matching edit → demote to a path-gated rule; lazy-load saves nothing. **[S]**
- Description is vague ("use when working on the system") → agent will miss it. Rewrite with concrete intent verbs. **[S]**
- `SKILL.md` body is getting unwieldy → split into reference files alongside `SKILL.md` and reference them by name. They won't be loaded unless the workflow in `SKILL.md` tells Claude to read them. **[S]**
- Bundled scripts that could be docs or tools → be explicit in `SKILL.md` whether Claude should *run* them or *read* them. **[C]**

### Routing — the description is the load decision

The model reads one line — the `description` field in frontmatter — to decide whether to load. It hasn't seen the body yet.

- **Write `description` as a trigger, not a summary.** State *when* to invoke, not *what* the skill contains. **[S]**
- **Lead with the invocation condition:** "Use when …," "Invoke when the user asks …," "Activates when …." **[S]**
- **Name the skill for the decision, not the topic.** `writing-pr-descriptions` beats `pr-guide`. **[S]**
- **Fit the description in the system-prompt budget.** It stays in context across every turn. **[S]**
- **Frontmatter with `name` and `description`** on every skill. **[S]**

### Progressive disclosure

- **SKILL.md is the hub; references load on demand.** Reference files bundled alongside `SKILL.md` are not loaded at skill activation — Claude reads them only when the workflow in `SKILL.md` tells it to. **[S]**
- **Separate mutually-exclusive context into sibling files.** If two workflows never run together, they don't share a file. **[S]**
- **Reference by name from SKILL.md** (e.g., "read `forms.md` to fill a form"), not by inlining. **[S]**

### Workflow design

- **Exit criteria per step.** "Run `X`, confirm Y" — not "verify the output." **[C]**
- **Three-tier boundaries:** Always do / Ask first / Never do. Removes ambiguity about when to pause. **[C]**
- **Anti-rationalization tables** for steps that get skipped. Pair the excuse with the rebuttal inline. **[C]**

---

## Memory (`MEMORY.md` and entries)

- **First 200 lines / 25KB of `MEMORY.md`** loaded at session start; after that, truncated. **[S]**
- **`MEMORY.md` is an index**, not a memory. One line per entry pointing at a topic file. **[S]**
- **Default: don't write here.** Most candidates are rules in disguise or one-time specifics. **[S] [A]**
- **Write memory only if all four hold:** **[S]**
  1. The fact is about **you working on this project**, not about the project itself.
  2. A teammate opening this repo would find it irrelevant or weird.
  3. You'd make a *different decision* in a future session without it.
  4. It's not a point-in-time measurement a command could answer fresh.
- **Prefer updating** existing entries over adding siblings. Duplicates rot. **[A]**
- **Delete or correct stale entries.** Removing rot is higher-value than adding new facts. **[A]**
- **When in doubt: discard**, or offer a rule instead. **[S]**

---

## Hooks

Hooks are increasingly load-bearing: they turn prose advice into enforcement. Shell commands that fire at defined lifecycle events, specified in `settings.json`.

### When to reach for a hook instead of a doc

- **Rule that's been broken before** → hook. Prose is advice; hooks block. **[S]**
- **Destructive command** (rm, force-push, db-drop) → `PreToolUse` deny hook. **[S]**
- **Automatic behavior** ("whenever the session starts, do X") → a hook, not a memory line. Memory doesn't execute. **[S]**
- **Telemetry or notifications on turn end** → `Stop` hook. **[S]**
- **Context injection** (add a header, resolve an alias in the user's prompt before Claude sees it) → `UserPromptSubmit` hook. **[S]**

### Lifecycle events

- `SessionStart` — runs once on session start. Use for memory load, cron setup, context warmup. **[S]**
- `UserPromptSubmit` — runs on every user turn before Claude sees the prompt. Use for prompt rewriting, context injection, or blocking. **[S]**
- `PreToolUse` — runs before a tool call. Use for destructive-command guards, arg validation, allowlist enforcement. Can block or rewrite. **[S]**
- `PostToolUse` — runs after a tool call. Use for output transformation, logging. **[S]**
- `Stop` — runs on turn end. Use for commit hooks, notifications, telemetry. **[S]**
- `Notification` — runs when Claude is about to notify. Use to route to a channel. **[S]**

### Rules

- **Hooks run as shell commands.** Exit 0 = pass; exit 2 = block with stderr shown to Claude. Design for that contract. **[S]**
- **Silent success, verbose failure.** Free signal in the common case; actionable errors when something breaks (Osmani). **[A]**
- **One hook, one concern.** A script that does five things is a maintenance burden. **[A]**
- **Check in your hooks** via `.claude/settings.json` for team-shared enforcement. `.claude/settings.local.json` for personal. **[S]**
- **Document what the hook does at the top of the script.** Six months later you won't remember. **[A]**

---

## Related, not doc content

These come up when authoring instruction docs but govern runtime rather than content:

- **Tool count ≤ 10** per agent where possible. Overlapping tools cause confusion and hallucination (Osmani).
- **`tool_search` before claiming lack of capability.** "I don't have access" is only correct after searching.
- **Compact before the window fills**, not after errors. Predictable degradation beats runtime failure.
- **"Formatting re-enabled"** — some reasoning models disable markdown output by default; include that phrase in your prompt to turn markdown back on (OpenAI reasoning-model guidance). Relevant when writing system prompts for those models.

---

**Sources cited:** Anthropic (CLAUDE.md ≤200 lines, recursive cwd-upward discovery, `@path` imports with 5-hop recursion, `CLAUDE.local.md`, `MEMORY.md` 200/25KB at session start, skill three-level progressive disclosure, `description` as routing trigger, hook lifecycle events). Osmani ("fix the code not the prose," hooks over prose, silent success / verbose failure, tool count ≤10). Perplexity (hub-and-spoke, progressive disclosure, description-as-trigger). Willison (skills-as-Markdown, portability). AEO / Osmani (Markdown token efficiency). OpenAI reasoning-model guidance ("Formatting re-enabled"). `/nr:reflect` (surface-choice decision tree, file-vs-goal distinction, memory gate).


