# Vintage Story server workspace

For any operation against chuck's Host Havoc VS server, invoke the **`vs-server`** skill — it carries the full runbook (SFTP sync, RCON, snapshots, mod deploys). This file only orients you to the directory.

## Server facts

- Runs **Vintage Story 1.22.x** — check mod compatibility against this before recommending or deploying anything.
- **Live-server writes (mod deploys, config pushes) are hook-blocked**, even in auto mode. Claude cannot push to live; surface the exact command and have chuck run it himself with the `!` prefix. Details in the skill.

## Folder roles

- `configs/` — **canonical / source-of-truth for what to PUSH**. Hand-edited, pushed UP to the server. **Never overwrite from a pull** unless you mean to reset local state to match live. ⚠️ Source-of-truth for *intent*, NOT a mirror of *current live runtime*: this file can lag what's actually running. In particular `serverconfig.json`'s `LastLaunchMods` is server-written and goes stale — never assert what's loaded live from it. To answer "what's installed/running NOW," pull a fresh snapshot or query RCON via the `vs-server` skill.
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

⚠️ **`realsmoke` can't be fetched by rustique** (verified 2026-06-17): `sync`/`update` show a
blank `latest_known_version` and `update` fails with `relative URL without a base` — moddb
serves a malformed `mainfile`, so rustique's "no update" is a false signal. Fetch it by hand —
pull the CDN URL from the API, download into the Mods folder, then `rm` the old `realsmoke_*.zip`:
```sh
curl -s https://mods.vintagestory.at/api/mod/realsmoke \
  | ruby -rjson -e 'r=JSON.parse(STDIN.read)["mod"]["releases"][0]; puts r["mainfile"]'
```

⚠️ **Library rule (load-bearing — getting it wrong blocks world load):** run **CommonLibForked
only**, never alongside the original `CommonLib` — both ship `CommonLib.dll` → "assembly already
loaded." Its consumers (`PlayerCorpseForked`, `StoneQuarryForked`) both want the Forked lib. Same
principle for any mod: never two versions/variants of one assembly in the folder at once.

## Mod decisions & deploy log

Modlist evaluations, keep/remove calls, the staged-but-not-deployed queue, and the deploy
log live in **@mod-decisions.md** — point-in-time research that rots, so it's kept out of
this always-loaded file. Read it when picking, deploying, or auditing mods. Everything there
is dated and needs re-verifying against moddb + the running game before you act on it.
