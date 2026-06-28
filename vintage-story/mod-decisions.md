# Mod decisions & deploy log

Point-in-time research and deploy history for the VS server's modlist. **All version
tags, dates, and "latest" numbers here rot — re-verify against moddb and the running
game before acting.** For what's actually loaded live *now*, pull a fresh snapshot or
query RCON via the `vs-server` skill; never trust this file (or `serverconfig.json`'s
`LastLaunchMods`) as the live truth.

Server philosophy driving every call below: **realism / "challenge without grind"**,
small private friend group, novelty wanted at the ~2-season mark, some stability risk
acceptable.

## Deploy log

- **2026-06-27 — worldconfig `colorAccurateWorldmap` → `true`** (chuck's change). Genuine bool (true/false is correct, unlike `caveIns` which is `on`/`off`); set, restarted, verified stuck live. Renders the in-game map in truer terrain colors. Players see it on next map open, no action needed.
- **2026-06-26 — Aqueducts and Sluices** (`hardcorewaterforked` aka "Hardcore Water: Transport Edition Forked", by Grym7er) **v1.4.6**, tagged 1.22.0–1.22.3, `side` universal, no deps. The maintained successor to the legacy `hardcorewater` mod (which is dead on 1.22). Deployed + booted clean. **Gotcha:** ~480 `[Warning] Failed remaps entry (hardcorewater:aqueduct-… not found)` lines at boot are **benign** — backwards-compat remaps from the *original* Hardcore Water mod, which was never installed here, so there's nothing to convert. Not an error; expected on a fresh install. Relevance: world has **`noLiquidSourceTransport: True`** (verified 2026-06-26), so bucket source-placement is disabled and aqueducts are the *intended* way to move water — essential, not decorative.
- **2026-06-26 — VS Roofing** (`vsroofing`) **v1.6.2**, tagged 1.22.3, `side` universal. The old 1.5.7 chisel-crash on 1.22.3 is resolved in 1.6.2 (Jun 16). Booted clean — no errors, no `#resin` texture bug some commenters hit. In-game TODO: lay roof blocks + chisel near them to confirm interactive feel (the log scan only proves it loaded).

## Staged but not deployed

- **Immersive Woodworking** (`immersivewoodworking`, by Bobrik00) — chuck wants it **~2026-07-02** ("in a week or so", said 2026-06-25). Staged in `LOCAL_MODS`, **not** deployed. In-world timber stations (chopping block, sawhorse + pit saw, sawmill multiblock) replacing grid plank/firewood crafting; tuned to vanilla balance. Fits "challenge without grind." Risk: pre-1.0 (0.9.13 on 1.22.3), brand-new author (single mod, but rapid responsive releases + heavy early engagement), touches a core daily loop → **backup-world test first, not straight to live**. Pairs with **In Dappled Groves** (tree felling, proven, 1.22-ok) for a fuller timber chain.

## Watch list — revisit later

Not staged, not committed to — candidates to look at when the timber/woodworking itch returns.

- **Logging Expanded** (`loggingmod`, [mod 55535](https://mods.vintagestory.at/show/mod/55535)) — v0.3.5, 1.22.0–1.22.3, `side` both. Timber overhaul: felled trees give **trunks** you process through tiered sawhorses (Primitive → Standard → Advanced) into logs/planks/firewood/beams; adds debranching, **resin extraction from pine/acacia trunks**, and cart storage racks. Its resin path is a **new "Trunk Heating Rack"** (heat felled pine/acacia trunks to drain resin) — a *different* mechanic from Tree Tap Redux (tap standing leaking logs). **Conflict check (2026-06-28):** Logging Expanded lists **NO** incompatibility with Tree Tap Redux; the two use different resin paths, so they'd coexist (redundant, not conflicting). The real either/or is with **Immersive Woodworking**: Logging Expanded's own page says *"Trunks from Logging Expanded cannot go into Immersive Woodworking Workstations"* — so they do **not** cleanly combine. Pick ONE timber overhaul (Logging Expanded *or* Immersive Woodworking), not both. Also incompatible with Salty's Falling Trees.
- **Immersive Woodworking** — see "Staged but not deployed" above; chuck's ~2026-07-02 pick. **Mutually exclusive with Logging Expanded** (trunks can't enter IWW stations) — choose one. Same niche.

## Mod evaluations

Verdicts from community research (modDB comments + official forums; Reddit/YouTube were
largely inaccessible). Re-verify the version tag against the running game before deploying.

_Evaluated 2026-06-02 (game 1.22.3):_

| Mod | Verdict | Latest / tag | Key reason & risk |
|---|---|---|---|
| Immersive Fibercraft | ✅ add now | 1.2.9 / 1.22.3 | New spindle→wheel→loom tech tree; realism, no grind; updated hours ago. Risk: MP seat-sync (just fixed); check Synergy config. |
| Stone Quarry Repack (fipil) | ✅ add (test first) | 3.6.3 / 1.22.3 | Late-game quarry project; only fork tagged 1.22.3 + save-safe. Risk: unresolved Attribute Rendering Library crash; slightly OP output. |
| Butchering | ✅ add (test w/ modlist) | 1.13.4 / 1.22.2 | Best realism fit (haul→skin→bleed→butcher). Risk: compat-patch fragility — hard crash w/ FotSA:Sirenia; dev dropping non-animal patches for 1.22. |
| VS Roofing | ✅ DEPLOYED 2026-06-26 (v1.6.2) | 1.6.2 / 1.22.3 | See deploy log above. |
| Blood Trail | 🤏 optional | 1.2.2 / 1.22.3 | Cosmetic hunting polish, not a new loop; crash fixed in 1.2.2. Gotcha: clients need particles ≥30%. |
| Millwright | ❌ skip | 1.3.3 / 1.22.3 | Vanilla 1.22 absorbed most of it (Large Windmill, in-wall axles, waterwheels); rest is OP + has acknowledged MP windmill-desync needing restarts. |
| VS Airship (rivvion) | ✅ add (eyes open) | 1.1.4 / 1.22.3 | Lore-friendly airships (balloon cloth, coal-gas boilers, wind/inertia); build+explore late-game goal. Use rivvion's, NOT ViesCraft. Risk: moving-multiblock MP desync — reported mid-flight eject + airship vanished near a translocator. |
| Medieval Architecture (mod 31540) | ✅ add | 1.1.1 / 1.22.0 | In-world archway building + drawbridges/portcullis/gates for a medieval base phase. Risk: CTD breaking small trapdoors in survival; pieces non-deconstructable; some brick textures error. **Requires Attribute Rendering Library** — same dep suspected in SQ-repack crashes; don't pair with fipil's repack untested. |
| Molds Expanded (nails/strips) | ✅ add | 1.2.0 / 1.22.2 | Casts nails+strips from crucible pour (no anvil); 100u→4, balanced (won't trivialize smithing). Answer to the "nails & strips mold" ask. Confirm loads on 1.22.3. |

## Installed-mod keep/remove decisions (2026-06-02)

- **BetterTraders** (`BetterTradersv0.2.0.zip`) — **REMOVED locally 2026-06-02** (chuck's call). Was half-redundant: vanilla 1.22 rebuilt/individualized trader outposts (mod even dropped its wagons because of it); it still added trader villages + cold-climate structures, but chuck opted to drop it. **Live-deploy caveat:** worldgen-structure mod — snapshot first, clear `Cache/unpack`, watch for missing-block errors on already-explored trader sites. Distinct from `usefultraders` (trade deals, kept).
- **ChiseledBlockRetention** (`ChiseledBlockRetention-2.0.1.zip`) — _keep._ It's room/cellar/greenhouse detection (makes chiseled walls count as solid so decorative-window rooms seal), NOT shape retention. Vanilla still uses strict room rules through 1.22.x. Tag stops at 1.22.2; pure JSON patch, verify no patch-error in log.
- **stonequarry122hack** (`stonequarry122hack_3.5.2.zip`) — _dead, remove._ Archived/broken hack fork, superseded by installed `StoneQuarryForked.zip`. Cleanup candidate.

## Installed-mod audit (2026-06-02, game 1.22.3)

**Changes applied locally via rustique (still need chuck's `!` deploy to live):**
- ❌ Deleted `commonlib@2.8.0` (old net8/1.21.1 — collided with Forked) and `stonequarry122hack@3.5.2` (dead).
- ⬆️ Updated `fromgoldencombs` 2.0.6→2.0.7, `carryon` + `carryonlib` →`-pre.2` (only build tagged 1.22.3). Removed leftover `carryonlib-pre.1` zip.

**Still to verify in-game (tags trail 1.22.3 but expected fine):** `knapster` (1.22.0-only tag — #1 smoke-test;
also configure per-feature modes so it doesn't auto-trivialize crafting), `nohands` + `resinrelief` (client-side,
abandoned, test then keep/drop), `stonequarryforked` (confirm 3.5.3 Forked-line; needs BackwardsCompat zip if
the save ever ran original/repack Stone Quarry). `th3dungeon` = **keep, not deprecated** — rebuilt as "Ancient Dungeons (Th3Dungeon)" v1.0.1, now runs *on* the new vanilla 1.22 dungeon system (the old "vanilla absorbing dungeons" worry was wrong; verified 2026-06-28). Minor update 1.0.0→1.0.1 available.
Everything else current and fine. `biggerpockets`+`knapster` are grind-reducers — identity call, not stability.

**Mods installed this round (2026-06-02, local via rustique — still need `!` deploy to live):**
`primitivesurvival` 5.0.5 (v5 already dropped Better Stairs + Particulator — the old RAM hog/bloat is gone; fireworks remain but harmless; config at `ModConfig/primitivesurvival5.json`, 60+ toggles), `foodshelves` 3.0.4 (kept for the **ice-cooling preservation** chain — vanilla 1.22 cabinets cover display only, no cooling), `longtermfood` 0.6.8, `mealrevariation` 3.1.1, `cartwrightscaravan` 1.9.1, `lichen` 1.6.4, `kevinsfurniture` 1.9.0, `bricklayers` 3.2.2 (+ `expandedmatter` 3.6.1 auto-pulled dep), `storagecontroller` 1.2.2, `vintagekinematics` 1.3.6, `wilderlandsethology` 1.0.3, `firstaidkits` 1.1.7.
⚠️ **Shake out on a backup world before live deploy:** `vintagekinematics` (perf), `wilderlandsethology` (patches vanilla AI → most MP risk), `storagecontroller` (1.22.0-only tag).

**Since installed — this old "decided-to-add" list is now obsolete (2026-06-28 audit):** Immersive Fibercraft, Butchering, VS Airship (rivvion), Medieval Architecture, Molds Expanded, Hydrate or Diedrate, and Immersive Body Temperature are **all live now**. ⚠️ Two modid surprises caught in the audit: **Immersive Fibercraft = modid `spinningwheel`**, and **Immersive Body Temperature = modid `warmweathereffects`** — the display names don't match their zip/modid, so don't go looking for them by name in the folder.
**Skipped / on hold:** Millwright (skip), Ithania Canned Goods (chose Long-term Food instead).
**Rejected:** Expanded Foods/Wildcraft (dev-only on 1.22.3), Biodiversity (behind+RAM), Equus (unstable RC), Better Crates (broken), XDiseases/Seafarer (RPG/XP).

## Installed mod inventory + links (2026-06-28)

73 third-party mods live (plus base game/creative/survival). Links to every ModDB page,
grouped by theme. Two naming surprises flagged inline. Re-pull if the modlist changes.

**Worldgen & exploration**
- [Interesting Ore Gen](https://mods.vintagestory.at/interestingoregen)
- [Ancient Dungeons (Th3Dungeon)](https://mods.vintagestory.at/thedungeon)
- [BetterRuins](https://mods.vintagestory.at/betterruins)
- [Darce's Drifters Redone](https://mods.vintagestory.at/darcesdriftersredone)
- [Low Light Spawns](https://mods.vintagestory.at/lowlightspawns)

**Farming & food**
- [Primitive Survival](https://mods.vintagestory.at/primitivesurvival)
- [Butchering](https://mods.vintagestory.at/butchering)
- [Food Shelves](https://mods.vintagestory.at/foodshelves)
- [Long term food](https://mods.vintagestory.at/longtermfood)
- [Variations on a Meal - Revaried](https://mods.vintagestory.at/mealrevariation)
- [Hydrate or Diedrate](https://mods.vintagestory.at/hydrateordiedrate)
- [Craftable High Fertility Soil](https://mods.vintagestory.at/highfert)
- [Natural Fertilizer](https://mods.vintagestory.at/naturalfertilizer)
- [Farmland Drops Soil (Updated)](https://mods.vintagestory.at/soildropsupdated)
- [Stone Bake Oven](https://mods.vintagestory.at/stonebakeoven)
- [From Golden Combs](https://mods.vintagestory.at/fromgoldencombs)
- [NDL Tree Growth](https://mods.vintagestory.at/ndlexpandedgrowthtrees)
- [NDL Mushroom Growth](https://mods.vintagestory.at/ndlexpandedgrowthmushrooms)
- [NDL Flower Growth](https://mods.vintagestory.at/ndlexpandedgrowthflowers)

**Building & decoration**
- [Bricklayers](https://mods.vintagestory.at/bricklayers)
- [Expanded Matter](https://mods.vintagestory.at/em)
- [VS Roofing Mod](https://mods.vintagestory.at/show/mod/30143)
- [Medieval Architecture](https://mods.vintagestory.at/show/mod/31540)
- [Kevins Furniture](https://mods.vintagestory.at/kevinsfurniture)
- [QP's Chisel Tools](https://mods.vintagestory.at/chiseltools)
- [Chiseled Block Retention](https://mods.vintagestory.at/cbr)
- [Stone Quarry: Forked](https://mods.vintagestory.at/show/mod/47429)
- [Lichen: Ancient Decor](https://mods.vintagestory.at/lichen)

**Survival mechanics & realism**
- [Steady Ground](https://mods.vintagestory.at/steadyground)
- [Cave-in Fix](https://mods.vintagestory.at/caveinfix)
- [Posts and Beams](https://mods.vintagestory.at/postsandbeams)
- [Aqueducts and Sluices](https://mods.vintagestory.at/hcwforked)
- [Immersive Body Temperature](https://mods.vintagestory.at/immersivebodytemperature) — modid `warmweathereffects`
- [Real Smoke](https://mods.vintagestory.at/realsmoke)
- [Vintage Kinematics](https://mods.vintagestory.at/show/mod/49968)

**Resource gathering & crafting**
- [Tree Tap Redux](https://mods.vintagestory.at/treetapredux)
- [Resin Relief](https://mods.vintagestory.at/resinrelief)
- [Immersive Fibercraft](https://mods.vintagestory.at/show/mod/34327) — modid `spinningwheel`
- [Meteoric Steel](https://mods.vintagestory.at/meteoricsteel)
- [Molds Expanded](https://mods.vintagestory.at/moldsexpanded)
- [Temporal gears stack](https://mods.vintagestory.at/temporalgearsstack)
- [Firewood Gives Sticks](https://mods.vintagestory.at/firewoodgivessticks)

**Creatures & combat**
- [Wilderlands Ethology](https://mods.vintagestory.at/show/mod/17660)
- [Cooperative Combat Rework Reupload](https://mods.vintagestory.at/cooperativecombatrr)
- [Blood Trail](https://mods.vintagestory.at/bloodtrail)
- [Animal cages](https://mods.vintagestory.at/animalcages)
- [StickEmUp!](https://mods.vintagestory.at/stickemup)

**Transport**
- [VS Airship Mod](https://mods.vintagestory.at/vsairshipmod)
- [Cartwright's Caravan](https://mods.vintagestory.at/cartwrightscaravan)

**Economy & info-sharing**
- [Useful Traders](https://mods.vintagestory.at/show/mod/19225)
- [ProspectTogether](https://mods.vintagestory.at/prospecttogether)
- [BetterEr Prospecting](https://mods.vintagestory.at/bettererprospecting)

**Quality-of-life / interface**
- [Knapster](https://mods.vintagestory.at/knapster)
- [Bigger Pockets](https://mods.vintagestory.at/biggerpockets)
- [Carry On](https://mods.vintagestory.at/carryon)
- [QP's Storage Controller](https://mods.vintagestory.at/storagecontroller)
- [StepUp Advanced](https://mods.vintagestory.at/stepupadvanced)
- [BedSpawn](https://mods.vintagestory.at/bedspawn)
- [Firstaidkits](https://mods.vintagestory.at/show/mod/35203)
- [PlayerCorpse-Forked](https://mods.vintagestory.at/playercorpseforked)
- [Zoom Button - Reborn](https://mods.vintagestory.at/zoombutton)
- [Auto Map Markers](https://mods.vintagestory.at/automapmarkers)
- [Item Pickup Highlighter](https://mods.vintagestory.at/show/mod/25352)
- [Extra Info](https://mods.vintagestory.at/extrainfo)
- [Status Hud Continued](https://mods.vintagestory.at/statushudcont)
- [NoHands](https://mods.vintagestory.at/nohands)

**Libraries (infrastructure — not gameplay)**
- [CommonLib-Forked](https://mods.vintagestory.at/commonlibforked)
- [Config lib](https://mods.vintagestory.at/configlib)
- [Overhaul lib](https://mods.vintagestory.at/overhaullib)
- [Attribute Rendering Library](https://mods.vintagestory.at/attributerenderinglibrary)
- [CarryOnLib](https://mods.vintagestory.at/carryonlib)
- [ImGui](https://mods.vintagestory.at/imgui)
- [Vintage RCON](https://mods.vintagestory.at/vintagercon)
