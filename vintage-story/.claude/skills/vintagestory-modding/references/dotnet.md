# .NET / C# reference for VS modding

VS mods are ordinary C# against the .NET runtime the game ships. The unusual parts are how you
reference the game and how you verify. This file covers those, plus where to go for
authoritative C#/.NET answers.

## Project & build realities

- **Target framework must match the game's runtime.** Recent VS builds run on modern .NET (e.g.
  `net10.0`). ⚠ This changes as the game updates — read the game's own assemblies / an existing
  mod's `.csproj`, don't assume. A mismatch produces load errors, not compile errors.
- **Reference game DLLs from the install, not NuGet:**
  ```xml
  <Reference Include="VintagestoryAPI">
    <HintPath>$(VINTAGE_STORY)\VintagestoryAPI.dll</HintPath>
    <Private>false</Private>   <!-- do NOT copy the game DLL into the mod output -->
  </Reference>
  ```
  Common references: `VintagestoryAPI`, `VSSurvivalMod` and `VSEssentials` (under `Mods/`),
  `Newtonsoft.Json` and `protobuf-net` (under `Lib/`). `$VINTAGE_STORY` must point at the game
  install. MSBuild defaults `<Private>` to **true**, so set it on *every* game reference — the
  host already loaded those assemblies, and shipping a second copy causes assembly-identity load
  conflicts (`TypeLoadException`).
- The game (de)serializes with **Newtonsoft.Json** and persists binary state with
  **protobuf-net** — use those, not `System.Text.Json`, when interoperating with game data. For
  protobuf-persisted types the **field tag numbers are load-bearing**: never reorder or reuse a
  tag or you silently corrupt existing saves. Never use `BinaryFormatter` (removed in modern
  .NET; an RCE vector).
- `LangVersion` can be set independently of the target framework — but newer C# *syntax* that
  needs runtime/BCL support (e.g. `record`/`init` need `IsExternalInit`) still fails on an older
  host even if it compiles. `AllowUnsafeBlocks` is sometimes needed for perf/interop code.
- Assets are copied to output via `<Content Include="assets\**" CopyToOutputDirectory="PreserveNewest">`.

## Per-tick loop & threading

- Tick code (entity/block updates) runs many times per second — **treat allocation as the enemy**
  on that path. Per-tick `new` collections, LINQ (`Where`/`Select` allocate iterators + closures),
  string interpolation, and capturing lambdas churn Gen0 and cause visible stutter. Cache and
  reuse buffers; prefer plain `for` loops; watch for hidden boxing of structs/enums.
- The engine API is **not thread-safe** and ticks run on the game's main thread. Never touch
  world/entity/block state from `Task.Run`, a raw `Thread`, or `Parallel.For`. `async`/`await`
  gives you *no* background thread and does *not* make engine calls safe ("there is no thread").
  For heavy work, compute off-thread on **copies**, then marshal results back onto the main
  thread via the engine's enqueue mechanism.

## Patching vanilla behavior: Harmony

To change vanilla methods you can't override through the API, the standard tool is
**Harmony** (`0Harmony`, `HarmonyLib`) — `Prefix`/`Postfix`/`Transpiler` patches applied in
`Start`/`StartServerSide`. Prefer `Prefix`/`Postfix`; a `Transpiler` rewrites IL and breaks on
game updates. Harmony is powerful and brittle; prefer the game's real extension points
(behaviors, events, registries) first, and reach for Harmony only when there's no hook.
**Unpatch in `Dispose` and unhook event handlers** — the game process outlives a world reload,
so leaked patches/handlers double-fire afterward. Not every mod uses Harmony — check first.

## Reading the game's real behavior: decompiling the DLLs

The API docs give **signatures**; they don't tell you what a method actually *does* at runtime
(which branch fires, what a warning really means, what a default value is). When behavior is
surprising — a log warning you can't explain, a feature that silently doesn't work — read the
game's own code. This is the ground truth behind "verify, don't remember."

**1. Find which DLL/type owns the behavior.** The game assemblies are under `$VINTAGE_STORY`:
`VintagestoryAPI.dll`, `Mods/VSSurvivalMod.dll`, `Mods/VSEssentials.dll`, `Lib/*.dll`. To locate
a log message or constant, search for the string literal — **but .NET stores string literals as
UTF-16LE**, so plain `strings`/`grep` (ASCII) find nothing. The portable way is a raw byte scan
for the UTF-16LE encoding (below). (`strings -e l` works only with **GNU binutils** `strings`;
the macOS/Xcode `strings` rejects `-e l`, so don't rely on it.) Also note the full runtime
sentence is often **not** one literal — `logger.Warning("… {0} …", …)` format strings and
interpolation split it, and pieces may live in *different* assemblies — so search only a fixed
literal fragment, not the whole message:

```python
# which dll contains a log string? (handles UTF-16LE that `strings` misses)
import os
needle = "did not define a step parent".encode("utf-16-le")
for dp,_,fs in os.walk(os.environ["VINTAGE_STORY"]):
    for f in fs:
        if f.endswith(".dll") and needle in open(os.path.join(dp,f),"rb").read():
            print(f)
```

**2. Decompile it.** The standard CLI decompiler is **ilspycmd** (the command-line front end of
ILSpy): `dotnet tool install -g ilspycmd` (on PATH at `~/.dotnet/tools`). Then decompile one type
(fast) or the whole DLL:

```bash
ilspycmd "$VINTAGE_STORY/VintagestoryAPI.dll" -t Vintagestory.API.Common.Shape > Shape.cs
# whole DLL works too (large): -r <dir> points at dependency dirs to improve type
# resolution quality, but is NOT required — the DLL decompiles without it.
ilspycmd "$VINTAGE_STORY/Mods/VSSurvivalMod.dll" > VSSurvivalMod.cs
```

If a decompile produces **zero output**, suspect a shell error (e.g. macOS lacks `timeout`, so
`timeout … ilspycmd …` fails as "command not found"), not the decompiler — check stderr first.

Then read the actual method around the string. **A warning's wording often maps to one specific
branch** — and two near-identical messages can be different code paths, so read the `if`/`else`
you're actually in rather than inferring the fix from the message. (Worked example: two VS
"step parent" warnings differ by one word — one means *the parent shape lacks a named element*,
the other means *the child shape's element defined no `StepParentName` at all* — opposite fixes.)

**GUI alternative (smoother, not headless):** the **ILSpy** app, **JetBrains Rider** (built-in
decompiler — Go-to-Definition into a DLL, search the string, jump to the method), or **dotPeek**.
These index strings/symbols for you, so step 1's byte-scan is unnecessary. Reach for the CLI when
scripting or working without a desktop.

**macOS note:** `timeout` isn't installed by default — `brew install coreutils` gives `gtimeout`.

## Testing reality

- VS mods rarely ship a unit-test project; the practical loop is **build → load in-game → read
  the logs**. Treat "it compiled" as necessary, not sufficient.
- To make logic testable anyway, keep pure decision logic in plain classes that don't touch
  `ICoreAPI`/world state, and unit-test those in isolation. Keep the thin API-touching layer
  small and verify it in-game.

## Prominent C#/.NET references & authors

Canonical docs (prefer these for language/BCL questions):
- **Microsoft Learn** — <https://learn.microsoft.com/dotnet/> and the C# guide
  <https://learn.microsoft.com/dotnet/csharp/>. The authoritative source.
- **.NET API browser** — <https://learn.microsoft.com/dotnet/api/> (BCL type/method reference).
- **C# language reference / what's new** — check the language-version page for feature
  availability before using newer syntax.

Respected authors/sites (good for depth, patterns, and gotchas):
- **Jon Skeet** — <https://jonskeet.uk/csharp/>; *C# in Depth*. Language semantics, the hard
  corners (closures, generics, value vs reference, DateTime).
- **Stephen Cleary** — <https://blog.stephencleary.com/>; *Concurrency in C# Cookbook*. The
  reference for async/await, `Task`, cancellation, deadlocks. Relevant: VS ticks/threading.
- **Andrew Lock** — <https://andrewlock.net/>. Deep dives into .NET internals and ASP.NET Core.
- **Nick Chapsas** — YouTube / Dometrain. Modern C#, performance, idioms.
- **Steve Smith (Ardalis)** — <https://ardalis.com/>. Design principles, clean architecture.
- **Rick Strahl** — <https://weblog.west-wind.com/>. Practical .NET, long-form problem write-ups.
- **Stephen Toub** — <https://devblogs.microsoft.com/dotnet/author/toub/>. The runtime team's
  performance series; the highest-signal source on allocation-free patterns (`Span`, pooling,
  avoiding boxing) — directly relevant to the tick loop.
- Others worth knowing by name: Jimmy Bogard (MediatR/AutoMapper, patterns), Julie Lerman (EF),
  Derek Comartin / CodeOpinion (architecture), Tim Corey (fundamentals).

**Tools:** [SharpLab](https://sharplab.io/) — inspect the IL/JIT output to catch hidden
allocations and boxing without a test project. [Harmony docs](https://harmony.pardeike.net/) —
authoritative reference for runtime patching.

For a game mod, weight toward: language semantics (Skeet), threading/async (Cleary), and
allocation/perf (Chapsas, Toub) — the areas that bite in a per-tick game loop. Enterprise/web
topics (ASP.NET, EF) rarely apply to VS mods.
