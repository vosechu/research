# Worldconfig field reference

Reference for `/worldconfig` fields on the VS server, for use with `rcon.rb wc`
(read) and `rcon.rb wc-set` (write). Companion to SKILL.md.

## How worldconfig actually persists (the important part)

Three distinct storage/lifetime layers — confusing them wastes a lot of time:

1. **`serverconfig.json` → `WorldConfig.WorldConfiguration`** — read **only at world
   creation**. Editing it on an existing world does **nothing**, ever, even across
   restarts. (Top-level serverconfig fields like `AllowPvP`/`Password`/`AdvertiseServer`
   are different — those DO load from the file every startup.)
2. **The savegame SQLite DB** — the live source of truth for an existing world's
   `WorldConfiguration`. This is what `/worldconfig` reads and writes.
3. **Server process memory** — values loaded from the DB at startup. Reads
   (`/worldconfig <field>`) reflect this.

**`/worldconfig <field> <value>` writes layer 2 (the DB), but the running world keeps
using layer 3 until a restart.** Verified 2026-06-01: after `wc-set daysPerMonth 56`
etc., `wc-dump` still read the old values — the change is pending a restart, not lost.

> Source: [wiki /worldconfig](https://wiki.vintagestory.at/index.php/List_of_server_commands)
> — "After a change of server settings, the world needs to be restarted for the changes
> to take effect." Some sources claim a subset apply live; we could not confirm any did,
> so **treat every worldconfig change as restart-required** and verify with `wc-dump` after.

### Therefore the apply workflow is:

```
# 1. write all desired values (chuck runs; wc-set is hook-blocked for Claude)
… rcon.rb wc-set <field> <value>  (per field)
# 2. restart from the Host Havoc panel
# 3. verify
vintage-story/scripts/rcon.rb wc-dump /tmp/after.json   # drift should clear
```

## Set syntax & value rules

- Syntax: `/worldconfig <field> <value>` — no `set` keyword. Via `rcon.rb`: `wc-set <field> <value>`.
- `wc-set` allows one `[A-Za-z0-9_]` field + one `[A-Za-z0-9._-]` value (no spaces) — booleans
  are `true`/`false`, enums are bare words, numbers are bare. Values needing spaces aren't expressible
  (none of ours do).

## Change categories (for an EXISTING world)

| Category | Effect of setting now | Fields |
|---|---|---|
| **Rules / gameplay** | writes to DB; applies after **restart** | daysPerMonth, creatureStrength, caveIns, playerHungerSpeed, microblockChiseling, temporalStormSleeping, classExclusiveRecipes, noLiquidSourceTransport, lightningFires, blockGravity, creatureHostility, playerHealthPoints, deathPunishment, harshWinters, seasons, temporalStorms, allowMap, allowCoordinateHud, worldEdge, allowLandClaiming, auctionHouse, … |
| **Worldgen — new chunks only** | applies after restart, but only affects **newly generated** terrain (seams with existing land) | globalPrecipitation, globalForestation, globalTemperature, globalDepositSpawnRate, surfaceCopperDeposits, surfaceTinDeposits, snowAccum |
| **Creation-only** | **cannot change** on an existing world — needs new world or full regen | worldClimate, worldWidth, worldLength, polarEquatorDistance, landcover, oceanscale, upheavelCommonness, geologicActivity, landformScale |

## Field table

Datatypes/ranges below are from the [World Configuration wiki](https://wiki.vintagestory.at/World_Configuration)
(flagged "outdated, last verified v1.15") — **treat as a guide, not gospel**; the live value read by
`wc-dump` is authoritative for current state. Known conflict flagged inline.

### Gameplay / rules

| Field | Type | Valid values | Notes |
|---|---|---|---|
| gameMode | enum | survival, creative | |
| deathPunishment | enum | drop, keep | |
| droppedItemsTimer | int | seconds | |
| spawnRadius | int | blocks | |
| graceTimer | int | days | creation-only per wiki |
| startingClimate | enum | hot, warm, temperate, cool, icy | creation-only |
| seasons | enum | enabled, spring, summer, winter, fall | |
| playerlives | int | -1 (infinite) or 1+ | |
| lungCapacity | int | ms | |
| daysPerMonth | int | 1+ | |
| harshWinters | bool | true, false | |
| blockGravity | enum | sandgravel, sandgravelsoil | |
| caveIns | bool | true, false | wiki says `on`/`off` but that's outdated; server accepted `true` (verified 2026-06-01) |
| allowFallingBlocks | bool | true, false | |
| allowFireSpread | bool | true, false | also a top-level serverconfig field |
| allowUndergroundFarming | bool | true, false | |
| bodyTemperatureResistance | int | any | |
| creatureHostility | enum | aggressive, passive, off | |
| creatureStrength | int | 0–99 | |
| creatureSwimSpeed | float | 0.5–3 | |
| playerHealthPoints | int | 1–999 | |
| playerHungerSpeed | float | 0–10 | |
| playerHealthRegenSpeed | float | 0.25–2 | |
| playerMoveSpeed | float | 0–10 | |
| foodSpoilSpeed | float | 0–10 | |
| saplingGrowthRate | float | any | |
| toolDurability | int | 0–99 | |
| toolMiningSpeed | int | 0–99 | |
| propickNodeSearchRadius | int | 0+ | |
| microblockChiseling | enum | off, stonewood, all | |
| clutterObtainable | enum | ifrepaired, yes, no | |
| noLiquidSourceTransport | bool | true, false | |
| loreContent | bool | true, false | creation-only per wiki |
| lightningFires | bool | true, false | |
| temporalStability | bool | true, false | |
| temporalStorms | enum | off, veryrare, rare, sometimes, often, veryoften | |
| tempstormDurationMul | float | any | |
| temporalRifts | enum | off, invisible, visible | |
| temporalGearRespawnUses | int | -1 to 9999 | |
| temporalStormSleeping | int | 0, 1 | |
| allowCoordinateHud | bool | true, false | |
| allowMap | bool | true, false | |
| colorAccurateWorldmap | bool | true, false | |
| worldEdge | enum | blocked, traversable | |
| allowLandClaiming | bool | true, false | |
| classExclusiveRecipes | bool | true, false | |
| auctionHouse | bool | true, false | |
| allowTimeswitch | bool | true, false | |

### Worldgen — new chunks only (after restart)

| Field | Type | Valid values |
|---|---|---|
| globalTemperature | float | 0–5 |
| globalPrecipitation | float | 0–5 |
| globalForestation | float | -1 to 1 |
| globalDepositSpawnRate | float | any |
| surfaceCopperDeposits | float | 0–5 |
| surfaceTinDeposits | float | 0–5 |
| snowAccum | bool | true, false |
| storyStructuresDistScaling | float | 0.15–3 |

### Creation-only (cannot change on existing world)

| Field | Type | Valid values |
|---|---|---|
| worldClimate | enum | realistic, patchy |
| worldWidth / worldLength | int | blocks (default 1024000) |
| polarEquatorDistance | int | blocks |
| landcover | float | 0–1 |
| oceanscale | float | 0.1–5 |
| upheavelCommonness | float | 0–1 |
| geologicActivity | float | 0–0.4 |
| landformScale | float | 0.2–3 |
