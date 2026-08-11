# Working inside a specific mod repo

This skill holds general VS/.NET knowledge. Any given mod repo carries its **own** conventions,
target version, and gotchas — and the repo is more authoritative than this skill for anything
version- or project-specific.

**Before editing code in a mod repo, read its own docs first:**

1. **`CLAUDE.md` / `AGENTS.md`** in the repo root (if present) — project conventions, build
   commands, the registration hub file, code-vs-content split, gotchas.
2. **`README.md`** — what the mod is and where its published page lives.
3. **`modinfo.json`** — the `modid` (asset domain), the `version`, and `dependencies`.
4. **The real code** for any API shape you're about to use — grep for an existing example of the
   same pattern (a sibling `AiTask*`, `Block*`, `BlockEntity*`) rather than trusting a
   remembered signature. This is the definitive source for the repo's target API version.

Match the file you're editing: indentation, namespace, and naming conventions can vary within a
repo — don't reformat surrounding code.

## Worked example: VSVillage

The `VSVillage` mod (`~/github/vsvillage`, modid `vsvillage`) is the canonical worked example
for this skill. Its `CLAUDE.md` documents the concrete patterns this skill describes in the
abstract: the two-place registration rule (`src/Systems/VsVillage.cs` is the registration hub),
the `src/` (C#, namespace `VsVillage`) vs `assets/vsvillage/` (JSON) split, `$VINTAGE_STORY`
build setup, the CakeBuild packaging pipeline, and its ~50 `AiTask*` classes wired through
`assets/vsvillage/entities/villager.json`. When a general question comes up, a real answer often
already exists there.

It is a **clone of an upstream we don't own** (`G3rste/vsvillage`); changes go up via a fork
(`vosechu/vsvillage`) + draft PR, and local Claude tooling is kept out of git. The full
contribution workflow and repo model live in its `CLAUDE.md` "Repo model & contributing" section
— read that before committing or opening a PR here.
