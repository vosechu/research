# Vintage Story API Reference

Durable concepts + current API shapes for VS modding. Everything version-sensitive is marked
⚠ — verify it against the mod repo's code or the installed DLLs before trusting it (see the
skill's "verify, don't remember" principle).

## Mod types

| Type | `modinfo.json` `type` | Contains | Notes |
|------|-----------------------|----------|-------|
| **Theme pack** | `"content"` | textures/shapes only | Visuals only, no new content/features. |
| **Content mod** | `"content"` | JSON assets, patches | Blocks/items/entities/recipes via JSON. No C#. |
| **Code mod** | `"code"` | `.cs`/`.dll` + assets | C# for behavior/systems. Any mod with code is a code mod. |

`modinfo.json` (in the mod root) — only **`type`** and **`name`** are strictly required; `modid`
defaults to the name lowercased with special chars stripped (set it explicitly — it is your asset
domain). Other common fields: `version` (semver; the **single source of truth** for the version —
build tooling reads it, don't hardcode versions elsewhere), `authors`, `side` (`"client"` |
`"server"` | `"universal"`, default `universal`), `dependencies` (map of `modid` → version, `"*"`
= any), `networkVersion`, `requiredOnClient`, `requiredOnServer`.

## Sides: client vs server

- `EnumAppSide` is `Client`, `Server`, or `Universal`. Check via `api.Side`, `api.Side.IsServer()`,
  `api.Side.IsClient()`, or `entity.World.Side`.
- `ICoreAPI` is the common base. `ICoreServerAPI` (server) and `ICoreClientAPI` (client) add
  side-specific surface.
- **Server owns:** authoritative world state, entity AI, block ticking, commands, saving.
- **Client owns:** rendering, GUIs, input, sounds, particles.
- Cross-side communication is explicit via the **Network API** (register a channel, send typed
  packets). Never assume shared memory across sides.

## ModSystem lifecycle

Subclass `Vintagestory.API.Common.ModSystem`. Methods, roughly in call order:

| Method | Side | Use |
|--------|------|-----|
| `StartPre(ICoreAPI)` | both | Earliest hook; config load, very-early setup. |
| `ShouldLoad(ICoreAPI)` / `ShouldLoad(EnumAppSide)` | both | Return false to skip this system on a side. |
| `Start(ICoreAPI)` | both | **Register classes here** (blocks, items, entities, behaviors, AI tasks). |
| `StartClientSide(ICoreClientAPI)` | client | Rendering, GUI, input, client commands. |
| `StartServerSide(ICoreServerAPI)` | server | Server commands, event hooks, world logic. |
| `AssetsLoaded(ICoreAPI)` / `AssetsFinalize(ICoreAPI)` | both | After assets are read; post-process/validate assets. |
| `Dispose()` | both | Teardown. |

- `ExecuteOrder()` returns a `double`; lower loads earlier. **Default `0.1`.** Engine reference
  points: JSON-patch loader `0.05`, block/item loader `0.2`, recipes `1.0` — so a system that must
  run before blocks are registered returns `< 0.2`. ⚠ Don't call `api.Assets` in `Start()` — assets
  aren't loaded yet; use `AssetsLoaded`/`AssetsFinalize`.

## Entities and AI tasks

The **`taskai`** entity behavior (class `EntityBehaviorTaskAI`, server-side) runs the AI tasks in
its **`aitasks`** array, declared under the entity JSON's `server.behaviors`. Each entry has a
`code` mapping to a registered task class plus that task's config. On load the behavior looks the
`code` up in `AiTaskRegistry.TaskTypes` and instantiates via
`Activator.CreateInstance(taskType, entityAgent, taskConfig, aiConfig)` — so the 3-arg constructor
below is mandatory (wrong arity → *"failed to instantiate task"* at load).

**Slots and priority:**
- 8 slots (**0–7**). Only **one task runs per slot**; tasks in *different* slots run
  concurrently; same-slot tasks compete.
- A task starts in its slot iff `Priority > runningTask.PriorityForCancel` **and**
  `ShouldExecute()` is true. `Priority < 0` skips it entirely.
- Mental model: **`priority` = strength to *start*; `priorityForCancel` = strength to *keep
  running*** (defaults to `priority`). Raise `priorityForCancel` to resist preemption.
- In `FinishExecute(bool cancelled)`, `cancelled == true` means **preempted by a higher-priority
  task**; `false` means it ended naturally.

### Custom AI-task shape ⚠ (verified against VS 1.21 source + a shipping mod; confirm per version)

Namespaces — all shipped in **`VSEssentials.dll`** (not VintagestoryAPI.dll):
- `AiTaskBase` → **`Vintagestory.API.Common`** ⚠ (older versions put it in `Vintagestory.GameContent`).
- `AiTaskBaseTargetable` (entity-targeting base) → `Vintagestory.GameContent`.
- `AiTaskRegistry` → `Vintagestory.GameContent`.

So a plain task needs `using Vintagestory.API.Common;`; a *targeting* task and the *registration*
call also need `using Vintagestory.GameContent;`.

```csharp
public class MyAiTask : AiTaskBase          // or AiTaskBaseTargetable for entity-targeting
{
    private float moveSpeed;

    // The registry instantiates via THIS exact constructor. taskConfig = the aitasks[] entry;
    // aiConfig = the whole taskai block. Read custom keys here, after base(...).
    public MyAiTask(EntityAgent entity, JsonObject taskConfig, JsonObject aiConfig)
        : base(entity, taskConfig, aiConfig)
    {
        // .AsFloat/.AsInt/.AsBool/.AsString return the given default when the key is absent.
        moveSpeed = taskConfig["moveSpeed"].AsFloat(0.03f);
    }

    public override bool ShouldExecute() { /* eligible to start this tick? */ return true; }
    public override void StartExecute()  { base.StartExecute(); /* begin move/anim */ }
    public override bool ContinueExecute(float dt) { /* return false to end */ return true; }
    public override void FinishExecute(bool cancelled)
    {
        base.FinishExecute(cancelled);
        entity.Controls.StopAllMovement();   // ALWAYS stop movement/anim (or your custom pathfinder)
    }
}
```

**Two config idioms both work** ⚠ (version-dependent):
- **Constructor manual-parse** (above; what many shipping mods do) — read `taskConfig[...]`
  yourself after `base(...)`.
- **`[JsonProperty]` auto-populate** (the modern 1.21 vanilla idiom): the base ctor calls
  `JsonUtil.Populate(taskConfig, this)`, so `[JsonProperty] public float MoveSpeed = 0.03f;` fills
  automatically (keys case-insensitive). Seed defaults in `override void SetDefaultValues()`.
- ⚠ The old **`LoadConfig(...)` override no longer exists** — don't use it on 1.20+/1.21.

Register in `ModSystem.Start`: `AiTaskRegistry.Register<MyAiTask>("mytaskcode");` — **generic form
only**; the non-generic `Register("code", typeof(T))` was removed. Wire into the entity JSON:
```json
{ "code": "mytaskcode", "priority": 1.5, "slot": 0, "minCooldownMs": 2000, "moveSpeed": 0.03 }
```
The JSON `code` must **exactly** match the registered string.

**Common `AiTaskBase` JSON keys** — ⚠ several were renamed in 1.20.12→1.21 (old keys still work via
`[Obsolete]` aliases): `id`, `slot`, `priority`, `priorityForCancel`, `executionChance`,
`minCooldownMs`/`maxCooldownMs` (were `mincooldown`/`maxcooldown`), `minCooldownHours`/
`maxCooldownHours`, `animation`/`animationSpeed`, `sound`/`finishSound`/`soundRange`/`soundStartMs`/
`soundRepeatMs`, `whenInEmotionStates`/`whenNotInEmotionStates` (were singular strings),
`duringDayTimeFrames` (a `DayTimeFrame[]`; ⚠ older versions honored it only on the idle task, later
expanded to all tasks), `whenSwimming`, `entityLightLevels`, `temperatureRange`.

**Movement:** vanilla tasks drive a `WaypointsTraverser PathTraverser` from the taskai behavior.
⚠ Its method names vary by version. Some mods ignore it and drive `entity.Controls.WalkVector`
with their own A* — read the repo to see which.

⚠ **A second "refactored" task system exists** (`vsessentialsmod/Entity/AI/TasksRefactored/`: a
parallel `AiTaskBase` + `-r`-suffixed codes like `wander-r`). It's an in-progress migration; for
1.21, custom mods still subclass the **classic** `AiTaskBase`. Confirm which your target version's
vanilla tasks use.

**AI-task gotchas:** code mismatch = silent skip (logged, no exception); missing `taskai` behavior
on the entity; editing the wrong entity variant file; forgetting to stop movement in
`FinishExecute`; `ContinueExecute(float dt)` runs **every server tick** — avoid per-tick
allocations/heavy block scans; unsafe world mutation off the main thread.

### Server AI threading — entity ticks are serial (verified VS 1.22.3)

All AI-task methods (`ShouldExecute`/`StartExecute`/`ContinueExecute`/`FinishExecute`) run
**serially on the single main server thread**, one entity at a time — no fan-out. Trace, decompiled
from `VintagestoryLib.dll`/`VSEssentials.dll`: `ServerMain.Process()` (main thread) loops `Systems[]`
calling `OnServerTick` → `ServerSystemEntitySimulation.TickEntities` is a plain
`foreach (server.LoadedEntities) e.OnGameTick(dt)` (**no `Parallel.ForEach`, no partitioning**) →
`EntityBehaviorTaskAI.OnGameTick` → `AiTaskManager.OnGameTick`. Consequence: **mod state touched only
from AI tasks needs no locking** — a plain field/dictionary is safe, and a read-modify-write across
tasks is atomic by serialization (no torn reads, no lost updates). ⚠ **Physics is the exception:**
`EntityBehaviorControlledPhysics` (`IPhysicsTickable.OnPhysicsTick`) runs on a *separate*
`PhysicsManager` thread pool, so state shared between an AI task and a physics tick *does* need
synchronization. ⚠ **Re-verify per version** — the server is being progressively multithreaded
(physics already moved off-thread); don't assume entity AI stays single-threaded forever. To check:
decompile and confirm `TickEntities` is still a serial `foreach`.

## Blocks, block entities, items

- **Block** (`class` field in blocktype JSON → `RegisterBlockClass`): behavior/interaction of a
  block type. Stateless per-type logic.
- **BlockEntity** (`entityClass` in blocktype JSON → `RegisterBlockEntityClass`): per-placed-block
  state + ticking. Persist via `ToTreeAttributes`/`FromTreeAttributes`.
- **Item** (`class` in itemtype JSON → `RegisterItemClass`): item behavior.
- **BlockBehavior / CollectibleBehavior / EntityBehavior**: composable behaviors attached in
  JSON, registered via the matching `Register*BehaviorClass`.
- **⚠ Chunks are 32×32×32 cubes, not full-height columns.** `GetChunkAtBlockPos(pos)` returns the
  single 32³ chunk containing `pos`, and `IWorldChunk.BlockEntities` holds only that cube's entities.
  To scan a *volume* for block entities you must iterate the chunk index on **all three axes**
  (`cx`, `cy`, `cz`) over `floor((min..max)/32)` — iterating only `cx`/`cz` at one Y silently misses
  everything outside a single 32-tall band (a basement, an upper floor, a sloped build), with no
  compiler error and no exception. `WalkBlocks(min, max, …)` handles Y for you; hand-rolled chunk
  enumeration does not. (This bit a real container-index scan: it found only chests near
  village-center height until the `cy` loop was added.)

## Assets & JSON patching

Assets live under `assets/<domain>/` (domain = your `modid`; vanilla domain is `game`). Common
subfolders: `entities`, `blocktypes`, `itemtypes`, `recipes/*`, `shapes`, `sounds`, `lang`,
`config`, `patches`. Reference assets across domains with a domain prefix, e.g.
`vsvillage:entity/humanoid/villager-male`.

VS's JSON parser is **lenient**: vanilla and mod asset JSON routinely use `//` comments and
trailing commas. The game and Newtonsoft's `JToken.Parse` (used by typical build validation)
accept them — but strict external JSON tooling will choke, so don't rely on it for `.json` you
hand to other tools.

**JSON Patching** (from `assets/<domain>/patches/…`) modifies *other* assets without overwriting
them (better mod compatibility). Syntax is based on RFC 6902 plus VS extras.

- Operations: **`add`**, **`remove`**, **`replace`**, **`move`**, **`copy`**, **`addmerge`**,
  **`addeach`** (`addmerge`/`addeach` are VS extensions for merging objects / appending to arrays).
- A patch object's fields: **`file`** (target asset), **`op`**, **`path`** (JSON Pointer),
  **`value`**; `move`/`copy` use **`fromPath`**. Optional conditioning: **`side`**
  (`"server"`/`"client"`), **`dependsOn`** (apply only if another mod is/isn't present),
  **`condition`** (match a world-config value), **`enabled`** (toggle).
- Patches are the right tool to make vanilla entities react to your mod (e.g. make animals flee
  a new entity) — see how any mature mod's `patches/` folder is laid out.

## Verifying a change (no test suite)

1. `dotnet build -c Debug <Mod>/<Mod>.csproj` — fastest correctness gate for C#.
2. Launch the game against the build: `--addModPath <build>/Mods --addOrigin <assets> --tracelog`
   (VS Code launch configs usually wire this up). Requires the local game — a human at a desktop.
3. Read `server-main.log` / `client-main.log` (in `VintagestoryData/Logs/`) for registration and
   asset errors — they name the offending code/file. AI-task problems log e.g. *"Task with code X
   for entity Y does not exist, will skip it"* or *"failed to instantiate task, possible error in
   task config json"*.
4. In-game with entity debug mode on, the AI manager writes the active tasks (code, priority,
   priorityForCancel) into the entity's debug info under **"AI Tasks"** — quickest way to confirm
   a task is running in its slot.

## Vetted links

- Modding wiki hub — <https://wiki.vintagestory.at/Modding:Getting_Started>
- API docs (check version) — <https://apidocs.vintagestory.at/>
- `taskai` behavior / AI tasks — <https://wiki.vintagestory.at/Modding:Entity_Behavior_taskai>
- JSON patching — <https://wiki.vintagestory.at/Modding:JSON_Patching>
- Code tutorials — <https://wiki.vintagestory.at/Modding:Code_Tutorial_Essentials>
- Dev environment setup — <https://wiki.vintagestory.at/Modding:Setting_up_your_Development_Environment>
- API source (read the real code) — <https://github.com/anegostudios/vsapi>
- Survival content source — <https://github.com/anegostudios/vssurvivalmod>
- Essentials source (AI tasks, entity behaviors) — <https://github.com/anegostudios/vsessentialsmod>
- Mod DB (examples + libraries) — <https://mods.vintagestory.at/>
- Official modding forums — <https://www.vintagestory.at/forums/forum/42-official-modding-apidoc-updates/>
