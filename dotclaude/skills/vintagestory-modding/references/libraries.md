# Vintage Story ecosystem libraries

Common third-party libraries that mods depend on, plus dev-only tooling. This is a **curated
index**, not API docs — these version independently of the game and of each other, so fetch
current API and version-support details from the linked source when you actually use one
(verify, don't remember). Each library's Mod DB page is `https://mods.vintagestory.at/<modid>`
(exception noted inline).

## The dominant gotcha: version coupling

Almost all of these Harmony-patch or lean on non-`VintagestoryAPI` internal types, so a game
minor bump (1.21 → 1.22 …) routinely breaks them until the author reships. **Match the library
build to your exact game version**, and expect a lag window after each VS release. Two big ones
(XLib, A Culinary Artillery) chronically trail the game and have competing forks — see below.

## Declaring a dependency

In `modinfo.json`, `dependencies` maps **`modid` → minimum version** (`""` or `"*"` = any):

```json
"dependencies": { "game": "1.22.0", "configlib": "1.12.0", "commonlib": "" }
```

- The game's `ModLoader` topologically sorts by dependency so a library loads before its
  dependents.
- A missing or too-old **hard** dependency → the dependent mod is **disabled**, with a
  `Missing dependency …` line in `server-main.log` / `client-main.log`. There is **no
  auto-download** — the user must install the library themselves.
- For an **optional** dependency, declare nothing and check
  `api.ModLoader.IsModEnabled("modid")` at runtime, degrading gracefully.
- Consequence: anything you put in `dependencies` is a **hard install your end users need**.
  Dev-only tools (below) stay out of it.

## Dev-time only — do NOT put in `dependencies`

| Library | For | Why it's not a runtime dependency |
|---------|-----|-----------------------------------|
| **Harmony** (`0Harmony`) | runtime method patching (prefix/postfix/transpiler) | **Bundled in the game** (`Lib/0Harmony.dll`) — every player already has it. Reference at compile time; use the bundled version, never ship your own (duplicate-assembly conflicts). See `dotnet.md`. |
| **VSImGui / ImGui** (`vsimgui`) | immediate-mode debug/tooling windows (Dear ImGui) | Client/render-side. Wrap in `#if DEBUG` and it stays dev-only — *unless* you ship a runtime feature through it, or depend on ConfigLib (which uses it), making it a hard dep. |
| **Gantry MDK** | mod-dev toolkit, shipped as a NuGet package | Tooling, not a runtime mod. |

## Runtime libraries (hard deps — users must install them too)

| Library | modid | For |
|---------|-------|-----|
| **ConfigLib** | `configlib` | config system + unified in-game settings GUI; server sync, hot-reload. (Transitively needs ImGui.) |
| **Auto Config Lib** | `autoconfiglib` | auto-builds a ConfigLib UI from an annotated C# config class. (→ ConfigLib → ImGui.) |
| **CommonLib** | `commonlib` | general helpers: networking/packet, config, teleport/RTP utilities. |
| **Overhaul lib** | `overhaullib` | animation framework + melee/projectile/inventory combat core (Maltiez stack). |
| **Attribute Rendering Library** | `attributerenderinglibrary` | collapses huge item/block variant trees to a few IDs (load-time + RAM win). |
| **Pet AI** | `petai` | AI-task framework for taming / domestication / pet commands. |
| **Genelib** | `genelib` | animal genetics/breeding — inheritance, mutations, naming GUI. |
| **Jaunt** | `jaunt` | rideable-entity movement: gaits, stamina, flying mounts. |
| **XLib** | `xlib` | skills / abilities / XP + status effects (powers XSkills). Page: `/show/mod/244`. ⚠ see below |
| **A Culinary Artillery** | `aculinaryartillery` | shared cooking / food-machinery content library. ⚠ see below |
| **Recipe Patcher** | `recipepatcher` | JSON recipe override/patching (server-side), beyond vanilla patching. |
| **Expanded Matter** | `expandedmatter` | chemistry / materials framework. |

Fetch the GitHub repo from each mod's page for API and **license** — licenses are per-repo, not
assumed permissive; verify before reusing code.

## Fork / fragmentation traps (verify lineage before depending)

- **XLib** — the original chronically lags the current game version; community forks **HoR XLib**
  (`horxlib`) and **xLib Fork** carry it forward. A fork **replaces** `xlib` — never install two.
- **A Culinary Artillery** — stable trails the game; newer game versions have needed `-dev`
  builds, with several competing forks (Redux, Experimental, …). Pick per game version.
- **CommonLib** — a `commonlibforked` stopgap exists when the original lags; don't run both.

## Before reaching for a library

- General (non-recipe) asset edits → use the **built-in JSON patching** first — no dependency.
  See `vintagestory.md` → Assets & JSON patching.
- Only need patching at dev time, or a debug UI → keep it dev-only; don't burden end users.
- Every hard dep (and its transitive chain, e.g. AutoConfigLib → ConfigLib → ImGui) is one more
  thing a player can fail to install → your mod silently disabled with a `Missing dependency` line.

## The two backbone stacks

- **Maltiez stack** — ConfigLib + VSImGui + Overhaul lib: the de-facto config/UI/combat backbone,
  best-maintained.
- **Craluminum-Mods stack** — Attribute Rendering Library + Recipe Patcher: asset/variant
  optimization and recipe patching.
