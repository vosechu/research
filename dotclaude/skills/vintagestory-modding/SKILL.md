---
name: vintagestory-modding
description: Use when writing, debugging, or reviewing a Vintage Story mod in C#/.NET — ModSystems, entity behaviors, AI tasks (taskai), blocks, block entities, items, GUIs; editing entity/blocktype/itemtype JSON or JSON patches; wiring the .csproj against the game DLLs; or answering "how does X work in VintagestoryAPI". Also a general C#/.NET reference while modding VS.
---

# Vintage Story Modding

## Overview

Reference for building [Vintage Story](https://www.vintagestory.at/) mods in C# and the
`VintagestoryAPI`. A VS mod is (almost always) two halves that must agree: **C# code**
(registered classes) and **JSON content/assets** (which reference those classes by string
codes). Most bugs are a mismatch between the two.

This is a **reference skill** — it holds the durable concepts, the current API shapes, and
vetted links. It does not memorize every class; deep per-class lookups happen on demand
against the API docs (see below).

## Core principle: verify, don't remember

**The Vintage Story API changes between game versions.** Class names, method signatures, and
registration calls drift (e.g. AI-task config moved from a `LoadConfig` override into the
constructor; `StartExecute` vs `StartExecuting`). A confident-sounding remembered signature is
the single most common way to be wrong here.

Before asserting any specific API, verify it against one of these, in order of trust:

1. **The mod repo's own code** — the definitive example for *its* target version. Grep for the
   pattern (`AiTaskRegistry.Register`, `: AiTaskBase`, `override bool ShouldExecute`).
2. **The installed game DLLs** — decompile / inspect `$VINTAGE_STORY/VintagestoryAPI.dll`,
   `Mods/VSSurvivalMod.dll`, `Mods/VSEssentials.dll`.
3. **The API docs** at <https://apidocs.vintagestory.at/> — check the version matches the game.

If you cannot verify, say so explicitly rather than guessing.

## When to use

- Writing/modifying C# for a VS mod: ModSystem, entity behaviors, AI tasks, blocks, block
  entities, items, inventories, GUIs, world-gen, commands, networking.
- Editing VS JSON assets: entity types, block/item types, recipes, shapes, lang, **patches**.
- Setting up or fixing the build: `.csproj` referencing game DLLs, `modinfo.json`, packaging.
- Answering conceptual questions about how a VS subsystem works.

**Not for:** non-VS C# projects (this pulls in game-specific assumptions), or pure asset-art
questions (shapes/textures) beyond how they're wired in JSON.

## Read the reference files on demand

| Load this | When |
|-----------|------|
| `references/vintagestory.md` | Anything VS-specific: mod types, ModSystem lifecycle, sides, registration APIs, AI tasks, blocks/items/BEs, assets & JSON patching, verification. **Start here.** |
| `references/dotnet.md` | .NET/C# realities for VS: target framework, referencing game DLLs, per-tick/threading, Harmony patching, **decompiling the game DLLs for ground truth** (ilspycmd + UTF-16 string search), testing reality, and prominent C#/.NET authors + reference sites. |
| `references/libraries.md` | Common ecosystem libraries (Harmony, ConfigLib, ImGui, Pet AI, …): what each is for, hard-dep vs dev-only, and how to declare a `modinfo.json` dependency. |
| `references/project-context.md` | Before working inside a specific mod repo — how to pick up its conventions (read its CLAUDE.md first). |
| `references/validating-changes.md` | Before declaring a change done or opening a PR — the tiered validation gate (build, semantic, provenance, in-game, regression, PR hygiene). Load when you'd otherwise say "it compiles, ship it." |

## Top gotchas (cross-cutting)

1. **Register in two places.** A new C# class (AI task, block, block entity, item, behavior,
   activity action/condition) must be registered in the `ModSystem` **and** referenced by its
   exact string code from the relevant JSON, or it silently never loads. Code mismatch = no
   error, no behavior.
2. **Client vs server.** `Start(ICoreAPI)` runs on both sides — register classes there.
   `StartServerSide(ICoreServerAPI)` / `StartClientSide(ICoreClientAPI)` are side-specific. AI,
   world mutation, and commands are **server-side**; rendering/UI/input are **client-side**.
   Doing server work in client code (or vice versa) fails or desyncs.
3. **The build needs `$VINTAGE_STORY`.** References resolve from the game install via that env
   var, with `<Private>false</Private>` (don't copy the game DLLs into the mod). Nothing
   compiles without it.
4. **No unit-test harness is typical.** Verification is: build succeeds, then load in-game
   (`--addModPath <build>/Mods --addOrigin <assets> --tracelog`). Read `server-main.log` /
   `client-main.log` for load errors. Before calling a change done or opening a PR, run the
   tiered gate in `references/validating-changes.md` — "it compiles" is necessary, not sufficient.
5. **JSON is validated at package time**, not by the compiler. A malformed asset JSON passes
   `dotnet build` but breaks the mod. Keep JSON valid.

## Quick reference: registration APIs

Called from `ModSystem.Start(ICoreAPI api)` (verify signatures against the target version):

```csharp
api.RegisterEntityBehaviorClass("name", typeof(MyBehavior));
api.RegisterBlockClass("name", typeof(MyBlock));
api.RegisterBlockEntityClass("name", typeof(MyBlockEntity));
api.RegisterItemClass("name", typeof(MyItem));
api.RegisterEntity("name", typeof(MyEntity));
AiTaskRegistry.Register<MyAiTask>("mytaskcode");          // generic form
// Activity system (from VSEssentials):
ActivityModSystem.ActionTypes.TryAdd("MyAction", typeof(MyAction));
ActivityModSystem.ConditionTypes.TryAdd("MyCondition", typeof(MyCondition));
```

The string on the left is what JSON references. See `references/vintagestory.md` for the AI
task class shape, the `taskai` behavior wiring, and everything else.
