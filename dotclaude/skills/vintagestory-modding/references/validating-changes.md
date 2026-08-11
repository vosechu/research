# Validating a change (before "done" / before a PR)

A task-completion gate for VS mod changes. **"It compiles" is necessary, not sufficient.**
Run the tiers that apply, in order. Tiers 1–3 and 5 are automatable now; Tier 4 is the manual
in-game half VS modding cannot automate; Tier 6 applies only when contributing upstream.

Skip tiers that don't apply (e.g. Tier 3/6 for a change to your own private mod), but say which
you skipped and why — a silently skipped tier reads as "validated" when it wasn't.

## Tier 1 — Static / build

- [ ] Builds clean **with** the change (`VINTAGE_STORY=... dotnet build`).
- [ ] For a **fix**: prove the pristine tree fails **without** it. Stash the change, rebuild,
  capture the exact compiler/loader error, restore. This proves the bug is real and upstream,
  not a local artifact.
- [ ] The change is the **only** instance of the problem. Grep for the pattern across the repo
  (e.g. every `new Foo(...)` call site when a constructor changed) — incomplete refactors leave
  siblings.
- [ ] Diff is minimal and isolated (no incidental reformatting; respect the file's existing
  tabs-vs-spaces).

## Tier 2 — Semantic (does the *right* thing, not just compiles)

The trap: making it compile with *a* value instead of the *correct* value.

- [ ] Understand what each changed argument/call actually does — read the target's own source
  (the field comments, the method body), not memory.
- [ ] For a value you're supplying, confirm it **matches the canonical pattern** used by sibling
  call sites. If 11 callers pass `entity`, the 12th almost certainly should too; a lone `null`
  or default is a smell.
- [ ] No behavioral guess: you can state *why* this value is correct, not just that it typechecks.

## Tier 3 — Upstream provenance (when touching third-party / upstream code)

- [ ] Identify the commit that introduced the problem (`git log -S`, `git blame`, `-L`) — names
  the root cause for the PR description and confirms it's not yours.
- [ ] Check for an existing issue/PR before writing one (`gh search issues/prs --repo <owner/repo>`).
  Don't duplicate.

## Tier 4 — Runtime / in-game (mostly manual; partially automatable headless)

VS has no integration-test harness. Build → load in-game → read the logs is the only way to
verify behavior.

**Launch the dev build** — start the game pointed at the build output. The env var must be set
in the launching process; a repo's VS Code "Launch Client/Server" configs read `${env:VINTAGE_STORY}`,
so they only work if VS Code inherited it (often it didn't — the terminal form below is more
reliable):

```
VINTAGE_STORY="<game>" "<game>/Vintagestory" --tracelog \
  --addModPath "<repo>/<Proj>/bin/Debug/Mods" --addOrigin "<repo>/<Proj>/assets"
```

The macOS executable is the Mach-O binary directly inside the `.app` (`<game>/Vintagestory`),
not a `Contents/MacOS/` launcher. Use `VintagestoryServer` for the dedicated-server variant.

**Set up a scenario** — most behavior needs cheats. At world creation enable "Allow cheats"
(or make a Creative world), then in chat (`T`):

```
/gamemode creative
/time set day    # if the behavior is time-gated
/e spawnat <domain>:<code> <amount> <x> <y> <z> <radius>   # all six args required
```

`/e` is the alias for the `/entity` command group; `spawnat` is its subcommand (verified 1.22 —
`/spawnentity` is an internal name, not the chat command). All six args are mandatory: use tilde
coords for "at me", e.g. `/e spawnat game:sheep-bighorn-adult-female 4 ~ ~ ~ 3`. Compose the
entity code from `assets/**/entities/*.json` — base `code` then each `variantgroups` state in
order, e.g. sheep is `code:"sheep"` + groups `type,age,gender` ⇒ `sheep-bighorn-adult-female`.
The game's own `/help` (and `.chb` handbook) is authoritative when unsure.

Note: spawning a mod entity in isolation may not run its full AI — many tasks gate on a
workstation/village/time-window, and a class that isn't registered + referenced in the entity
JSON never runs at all (it can still break the *build*). If the entity just stands there, check
it's actually wired before assuming a bug.

**Watch the log** (macOS): `~/Library/Application Support/VintagestoryData/Logs/{client,server}-main.log`.

**Headless partial-automation (dedicated server).** Tier 4 is not *entirely* a human's job. The
dedicated server (`VintagestoryServer`) is a console app that boots with no display, so an agent can
run it and read its log. It won't render, but it ticks the world and entities. Recipe:

1. Isolate a data dir: `--dataPath /tmp/vstest`. First boot writes `serverconfig.json` there and
   generates a fresh world.
2. To load a *specific* existing world instead, copy the `.vcdbs` save into `/tmp/vstest/Saves/foo.vcdbs`
   (drop spaces from the name) and set `serverconfig.json`'s `WorldConfig.SaveFileLocation` to that
   path — a client singleplayer save loads fine on the dedicated server (same DB format).
3. Launch (background it), wait for `Dedicated Server now running on Port`, then read
   `/tmp/vstest/Logs/server-main.log`:
   ```
   VINTAGE_STORY="<game>" "<game>/VintagestoryServer" --dataPath /tmp/vstest \
     --addModPath <dev>/Mods --addOrigin <dev>/assets --tracelog
   ```
4. Drive it via stdin (the console reads chat/console commands) or a temporary debug command the mod
   registers. Stop with `pkill -f VintagestoryServer` (or `/stop`).

Free win: confirms the mod loads and every ModSystem initializes with **no exceptions in a live
runtime** — the build cannot prove that. Still needs a set-up scenario: with no player connected only
spawn chunks stay loaded, so **construct the scenario deterministically** (spawn + place in code)
rather than hoping the save already has it near spawn.

**Full behavioral automation IS possible — entity AI runs headless with `AlwaysActive`.** The common
belief that "AI needs a player" is only half true. The server parks entities as `State=Inactive` when
no player is within `SimulationRange` (`Entity.DoInitialActiveCheck`; the per-tick re-eval in
`VintagestoryLib` skips only `entity.AlwaysActive` entities), and the AI behaviour only ticks its task
manager when `State==Active` (`EntityBehaviorTaskAI.OnGameTick` gates on `entity.State`). So with zero
players **everything is Inactive and no AI runs** — which is why a raw spawn "just stands there." The
lever: set **`entity.AlwaysActive = true` BEFORE `SpawnEntity`** (Initialize reads it, and the sim's
re-eval leaves AlwaysActive entities alone). The entity then ticks its full decision→path→act loop
headless. This turns Tier 4 from "load and eyeball" into a real behavioral test: spawn AlwaysActive
entities, wire their state in code, let the world tick, assert on live game state, read the log.
Gotchas for a deterministic scenario: build a **flat loaded floor** (random terrain puts targets at
different heights / underwater → unpathable) and **assert over a settle window** (overlapping tasks
make momentary state oscillate), not an end snapshot.

**`--addModPath` is a sequence option** — pass ONE flag with space-separated paths
(`--addModPath a b`), never the flag twice. Repeating it makes the CommandLine parser return null and
the server dies with an NRE in `ServerProgram..ctor()` before the world loads. (`--addOrigin` is the
same.) A totally fresh empty `--dataPath` boots fine and generates a world on its own — if it crashes
at startup, suspect the arg syntax, not the data dir.

**Watch a headless scenario render live in the client.** The singleplayer client runs an integrated
server, so the *same* server-side harness (`ShouldLoad(Server)` ModSystem + its chat commands) loads and
runs under it. Drop straight into a throwaway creative world — no menu — with the client's own launch
options (decompiled from `ClientProgramArgs`): `-o/--openWorld <name>` opens-or-creates a world,
`-p/--playStyle creativebuilding` (the default) makes it creative so you hold the `gamemode` privilege
the harness command needs, and an isolated `--dataPath` loads **only** your `--addModPath` mods (no
installed release/addons ⇒ no mod-version race) and shields your real saves from a scenario's
destructive terrain edits (`-c/--connect <addr>` instead joins a server):
```
VSVILLAGE_GOLDEN_ALLOW=1 "<game>/Vintagestory" --dataPath /tmp/watch -o scene -p creativebuilding \
  --addModPath <dev>/Mods <harness>/Mods --tracelog
```
Then in-game press `T` and run the harness command. (If the harness gates destructive runs behind
an env opt-in — a good pattern, since the scenario permanently flattens terrain — set that var on
the launch, as above; without it the run command should refuse rather than carve up a real save.) To make the scenario *self-narrate* what each moment
proves, broadcast beats to players — `sapi.BroadcastMessageToAllGroups(msg, EnumChatType.Notification)` —
gated on `api.World.AllOnlinePlayers.Length > 0`, so it's a silent no-op headless and never perturbs the
CI gate.

- [ ] The changed feature exercises its code path without exceptions.
- [ ] `server-main.log` / `client-main.log` show no new `[Error]`, `Exception`,
  `NullReference`, or subsystem warnings attributable to the change.
- [ ] Adjacent behavior still works — no regression in the same entity/block/subsystem.
- [ ] State that survives a save/reload (watched attributes, block-entity tree data) actually
  round-trips.

## Tier 5 — Regression scope

- [ ] State the blast radius in one sentence: what this can affect and what it cannot. A
  one-line constructor fix in one task ⇒ that task's behavior only. A change to a shared base
  class ⇒ every subclass — widen Tier 4 accordingly.

## Tier 6 — PR hygiene (contributing upstream)

- [ ] Branch off **clean upstream default**, not your working/feature branch — the PR must carry
  *only* the change, none of your local specs/tooling.
- [ ] Confirm the project's contribution norms (CONTRIBUTING, whether PRs target `master` or a
  dev branch, commit-message conventions).
- [ ] PR description states: the failure it fixes (with the reproduced error), the root-cause
  commit, and why the fix is correct (the canonical-pattern argument from Tier 2).
- [ ] Keep local-only tooling (Claude specs, `CLAUDE.md`, `.claude/`) out of the branch — use
  `.git/info/exclude` so it never enters a commit.

## Worked example (compressed)

A cloned mod's `master` didn't compile: one AI-task constructor call passed 1 arg to a
constructor that a later refactor made 3-arg. Validation that gave certainty:

- **T1:** built clean with the fix; stashed it → reproduced `CS7036` on the exact line → only
  1 of 12 `new VillagerAStarNew(...)` sites was wrong.
- **T2:** read the ctor — `world` (required, door-lock queries), `owner` (self-exclude from
  crowd avoidance; "null = no avoidance"). All 11 sibling AI-tasks pass `(accessor, world,
  entity)`; the fix restores parity, so passing `entity` is *correct*, not just compilable.
- **T3:** `git log -S` pinned the breaking commit (the ctor refactor that missed this caller);
  `gh search` found no existing issue/PR.
- **T5:** blast radius = shepherd-wander pathfinding only.
- **T4/T6:** pending — load in-game and watch the shepherd wander cleanly; branch the fix off
  clean `master` for the PR.
