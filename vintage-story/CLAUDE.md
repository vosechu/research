# Vintage Story server workspace

For any operation against chuck's Host Havoc VS server, invoke the **`vs-server`** skill — it carries the full runbook (SFTP sync, RCON, snapshots, mod deploys). This file only orients you to the directory.

## Server facts

- Runs **Vintage Story 1.22.x** — check mod compatibility against this before recommending or deploying anything.
- **Live-server writes (mod deploys, config pushes) are hook-blocked**, even in auto mode. Claude cannot push to live; surface the exact command and have chuck run it himself with the `!` prefix. Details in the skill.

## Folder roles

- `configs/` — **canonical / source-of-truth**. Hand-edited, pushed UP to the server. **Never overwrite from a pull** unless you mean to reset local state to match live.
- `snapshots/<UTC-ts>/` — read-only live captures from `scripts/snapshot.rb`. For diffing, rollback, post-mortem.
- `.env` — credentials. Gitignored.

SFTP usage, RCON safety, server paths, and script details are all in the skill.

## Mod management (rustique)

Local mods live in `~/Library/Application Support/VintagestoryData/Mods/` (the deploy
source AND chuck's own game). The `rustique` mod-manager binary sits **in that folder** —
run it from there as `./rustique <cmd>` (it's not on PATH). State is tracked in
`rustique-sync.json` (installed vs latest version, game-version tags, download URLs).

These are **local** operations (not hook-blocked — the guard only blocks `sftp.rb`/`rcon.rb wc-set`).
Pushing the result to the live server is still chuck's `!` deploy.

```sh
cd "$HOME/Library/Application Support/VintagestoryData/Mods"
./rustique sync                 # refresh latest-version info from moddb (do first)
./rustique list                 # installed versions, available updates, missing deps
./rustique update <mod_id>      # update one mod (or no arg = all); runs sync after
./rustique install <mod_id>     # install by mod_id (e.g. hydrateordiedrate), not title
./rustique delete -m <id> [id…] # remove mod(s); accepts id@version
./rustique search -q <query>    # find new mods
./rustique info <mod_id>        # details for one mod
```

To find updates fast without parsing the giant `list` table, diff the manifest:
`ruby -rjson -e 'JSON.parse(File.read("rustique-sync.json"))["RustiqueSync"].each{|i,m| puts i if m["installed_version"]!=m["latest_known_version"] && m["latest_known_version"]}'`

⚠️ **Gotcha (verify after every update):** `update` sometimes leaves the OLD version zip on
disk next to the new one (seen with `carryonlib` 2026-06-02). Two zips of the same mod →
duplicate-assembly load conflict (same failure class as the dual-CommonLib bug). After
updating, `ls | grep <mod>` and `rm` any stale duplicate.

## Mod evaluations

Verdicts from community research (modDB comments + official forums; Reddit/YouTube were
largely inaccessible — treat sentiment as drawn from the first two channels). Re-verify the
version tag against the running game before deploying; these are point-in-time.

Server philosophy driving these calls: **realism / "challenge without grind"**, small private
friend group, novelty wanted at the ~2-season mark, some stability risk acceptable.

_Evaluated 2026-06-02 (game 1.22.3):_

| Mod | Verdict | Latest / tag | Key reason & risk |
|---|---|---|---|
| Immersive Fibercraft | ✅ add now | 1.2.9 / 1.22.3 | New spindle→wheel→loom tech tree; realism, no grind; updated hours ago. Risk: MP seat-sync (just fixed); check Synergy config. |
| Stone Quarry Repack (fipil) | ✅ add (test first) | 3.6.3 / 1.22.3 | Late-game quarry project; only fork tagged 1.22.3 + save-safe. Risk: unresolved Attribute Rendering Library crash; slightly OP output. |
| Butchering | ✅ add (test w/ modlist) | 1.13.4 / 1.22.2 | Best realism fit (haul→skin→bleed→butcher). Risk: compat-patch fragility — hard crash w/ FotSA:Sirenia; dev dropping non-animal patches for 1.22. |
| VS Roofing | ⏸️ wait | 1.5.7 / 1.22.2 | Great for a build phase, but confirmed chisel-crash on 1.22.3 (no fix yet). Revisit when 1.22.3-tagged. |
| Blood Trail | 🤏 optional | 1.2.2 / 1.22.3 | Cosmetic hunting polish, not a new loop; crash fixed in 1.2.2. Gotcha: clients need particles ≥30%. |
| Millwright | ❌ skip | 1.3.3 / 1.22.3 | Vanilla 1.22 absorbed most of it (Large Windmill, in-wall axles, waterwheels); rest is OP + has acknowledged MP windmill-desync needing restarts. |
| VS Airship (rivvion) | ✅ add (eyes open) | 1.1.4 / 1.22.3 | Lore-friendly airships (balloon cloth, coal-gas boilers, wind/inertia); build+explore late-game goal. Use rivvion's, NOT ViesCraft. Risk: moving-multiblock MP desync — reported mid-flight eject + airship vanished near a translocator. |
| Medieval Architecture (mod 31540) | ✅ add | 1.1.1 / 1.22.0 | In-world archway building + drawbridges/portcullis/gates for a medieval base phase. Risk: CTD breaking small trapdoors in survival; pieces non-deconstructable; some brick textures error. **Requires Attribute Rendering Library** — same dep suspected in SQ-repack crashes; don't pair with fipil's repack untested. |
| Molds Expanded (nails/strips) | ✅ add | 1.2.0 / 1.22.2 | Casts nails+strips from crucible pour (no anvil); 100u→4, balanced (won't trivialize smithing). Answer to the "nails & strips mold" ask. Confirm loads on 1.22.3. |

### Installed-mod keep/remove decisions (2026-06-02)

- **BetterTraders** (`BetterTradersv0.2.0.zip`) — **REMOVED locally 2026-06-02** (chuck's call). Was half-redundant: vanilla 1.22 rebuilt/individualized trader outposts (mod even dropped its wagons because of it); it still added trader villages + cold-climate structures, but chuck opted to drop it. **Live-deploy caveat:** worldgen-structure mod — snapshot first, clear `Cache/unpack`, watch for missing-block errors on already-explored trader sites. Distinct from `usefultraders` (trade deals, kept).
- **ChiseledBlockRetention** (`ChiseledBlockRetention-2.0.1.zip`) — _keep._ It's room/cellar/greenhouse detection (makes chiseled walls count as solid so decorative-window rooms seal), NOT shape retention. Vanilla still uses strict room rules through 1.22.x. Tag stops at 1.22.2; pure JSON patch, verify no patch-error in log.
- **stonequarry122hack** (`stonequarry122hack_3.5.2.zip`) — _dead, remove._ Archived/broken hack fork, superseded by installed `StoneQuarryForked.zip`. Cleanup candidate.

### Full installed-mod audit (2026-06-02, game 1.22.3)

**Library rule (load-bearing — getting it wrong blocks world load):** run **CommonLibForked only**,
never alongside the original `CommonLib` — both ship `CommonLib.dll` → "assembly already loaded."
The only consumers (`PlayerCorpseForked`, `StoneQuarryForked`) both want the Forked lib. Same
principle for any mod: never two versions/variants of one assembly in the folder at once.

**Changes applied locally via rustique (still need chuck's `!` deploy to live):**
- ❌ Deleted `commonlib@2.8.0` (old net8/1.21.1 — collided with Forked) and `stonequarry122hack@3.5.2` (dead).
- ⬆️ Updated `fromgoldencombs` 2.0.6→2.0.7, `carryon` + `carryonlib` →`-pre.2` (only build tagged 1.22.3). Removed leftover `carryonlib-pre.1` zip.

**Still to verify in-game (tags trail 1.22.3 but expected fine):** `knapster` (1.22.0-only tag — #1 smoke-test;
also configure per-feature modes so it doesn't auto-trivialize crafting), `nohands` + `resinrelief` (client-side,
abandoned, test then keep/drop), `stonequarryforked` (confirm 3.5.3 Forked-line; needs BackwardsCompat zip if
the save ever ran original/repack Stone Quarry). `th3dungeon` = deprecation watch (vanilla absorbing dungeons).
Everything else current and fine. `biggerpockets`+`knapster` are grind-reducers — identity call, not stability.

**Mods installed this round (2026-06-02, local via rustique — still need `!` deploy to live):**
`primitivesurvival` 5.0.5 (v5 already dropped Better Stairs + Particulator — the old RAM hog/bloat is gone; fireworks remain but harmless; config at `ModConfig/primitivesurvival5.json`, 60+ toggles), `foodshelves` 3.0.4 (kept for the **ice-cooling preservation** chain — vanilla 1.22 cabinets cover display only, no cooling), `longtermfood` 0.6.8, `mealrevariation` 3.1.1, `cartwrightscaravan` 1.9.1, `lichen` 1.6.4, `kevinsfurniture` 1.9.0, `bricklayers` 3.2.2 (+ `expandedmatter` 3.6.1 auto-pulled dep), `storagecontroller` 1.2.2, `vintagekinematics` 1.3.6, `wilderlandsethology` 1.0.3, `firstaidkits` 1.1.7.
⚠️ **Shake out on a backup world before live deploy:** `vintagekinematics` (perf), `wilderlandsethology` (patches vanilla AI → most MP risk), `storagecontroller` (1.22.0-only tag).

**Decided-to-add but NOT yet installed** (from the first eval batch + HIGH new picks): Immersive Fibercraft, Butchering, VS Airship (rivvion), Medieval Architecture (needs **Attribute Rendering Library**), Molds Expanded; plus Hydrate or Diedrate (`hydrateordiedrate`, friend's pick) + Immersive Body Temperature (`immersivebodytemperature`, pairs w/ HoD).
**Skipped / on hold:** Millwright (skip), VS Roofing (hold — 1.22.3 chisel crash), Ithania Canned Goods (chose Long-term Food instead).
**Rejected:** Expanded Foods/Wildcraft (dev-only on 1.22.3), Biodiversity (behind+RAM), Equus (unstable RC), Better Crates (broken), XDiseases/Seafarer (RPG/XP).
