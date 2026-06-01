---
name: vs-server
description: Use when chuck asks to push/pull VS server files, check or tail the server log, ban a player, deploy mods, run an RCON command, or snapshot before a risky op like /db prune — manages his Host Havoc Vintage Story server over SFTP + RCON.
---

# vs-server — Vintage Story server runbook

Workspace lives at `vintage-story/` in this repo. Credentials and paths are in `vintage-story/.env` (gitignored).

## Quick reference

Everything goes through the Ruby scripts in `scripts/`. SFTP is a verb CLI (one op per call); RCON is a safe subcommand dispatcher.

| Goal | Command |
|---|---|
| Snapshot live state into `snapshots/<UTC-ts>/` | `vintage-story/scripts/snapshot.rb` |
| Live-tail server-main.log (read-only poll) | `vintage-story/scripts/tail-log.rb [interval=15s] [log=server-main.log]` |
| Run a safe RCON command | `vintage-story/scripts/rcon.rb <subcommand> [args]` (subcommands in the RCON section) |
| An SFTP op | `vintage-story/scripts/sftp.rb <verb> [args]` — `ls`/`get`/`put`/`mput`/`rm`/`rmdir`/`rename`/`mkdir` |

`sftp.rb` is a verb CLI over the `net-sftp` gem (password auth, no `expect`); `lib.rb` loads `.env` and opens the session.

## Safety boundary

Two things keep this safe: `rcon.rb` emits only read-only/harmless-mutation commands plus the single `wc-set` worldconfig write — and `wc-set`, like every live write, is hook-blocked so it can't run as a Claude tool call — and the canonical/live file split. When in doubt, snapshot first and ask.

**Live-server writes are hook-enforced, not advisory.** A `PreToolUse` hook (`.claude/hooks/vs-guard.rb`, wired in `.claude/settings.json`) blocks, even in auto/bypass mode:
- `sftp.rb` write verbs (`put`/`mput`/`rm`/`rmdir`/`rename`/`mkdir`) — config pushes, mod deploys, and
- the RCON worldconfig write path `rcon.rb wc-set`.

Read-only RCON (`wc`, `wc-dump`, `list`, …) and SFTP `get`/`ls` pass through. Claude cannot self-grant an override; chuck approves by running the exact command himself with the `!` prefix, which bypasses the hook. Run `.claude/hooks/vs-guard.rb --selftest` to see what's blocked vs allowed.

| Tier | Operations |
|---|---|
| **Do autonomously** | `snapshot.rb`; `tail-log.rb`; read-only `rcon.rb` subcommands (`list`, `info`, `time`, `stats`, `weather`, `mods`, `wc <field>`, `wc-dump`, `autosavenow`, `genbackup`); SFTP `ls` and `get` into `snapshots/`. |
| **Ask chuck first** | Pushing `configs/` UP (overwrites live); deploying or swapping mods; any SFTP `put`/`mput`; `rcon.rb wc-set` (worldconfig write); adding a new subcommand to `rcon.rb`; restarting (chuck does this from the Host Havoc panel). |
| **Hook-blocked — only chuck, via `!`-prefix** | SFTP writes (`put`/`mput`/`rm`/`rename`/`mkdir`/…) and `rcon.rb wc-set`. Reachable in principle but `vs-guard.rb` stops them as tool calls; surface the exact command for chuck to run. |
| **Never (not reachable from here)** | Other destructive RCON (`/db prune`, `/wgen regen`, `/ban`, `/kick`, `/role set`, `/op add`, `/stop`) — `rcon.rb` can't express these; run them from in-game admin chat or the Host Havoc web console. Overwriting `configs/` from a pull unless chuck wants to reset local state to live. |

### Common SFTP one-liners

```sh
# Verb per call. Remote paths are relative to REMOTE_BASE; local paths are literal.

# List remote mods
scripts/sftp.rb ls Mods

# Mirror local Mods folder up (mod deploy)
scripts/sftp.rb mput '/tmp/vs_local_mods/*.zip' Mods

# Push playerdata + bans
scripts/sftp.rb put configs/playerdata.json Playerdata/playerdata.json
scripts/sftp.rb put configs/playersbanned.json Playerdata/playersbanned.json

# Pull current configs into configs/  (overwrites canonical — only to RESET to live)
scripts/sftp.rb get serverconfig.json configs/serverconfig.json
scripts/sftp.rb get servermagicnumbers.json configs/servermagicnumbers.json
scripts/sftp.rb get Playerdata/playerdata.json configs/playerdata.json
scripts/sftp.rb get Playerdata/playersbanned.json configs/playersbanned.json
```

`scripts/sftp.rb` loads `.env` via `lib.rb` and uses the `net-sftp` gem (native password auth — no `expect`/`sshpass`). One verb per call; remote paths resolve under `REMOTE_BASE`, local paths are literal.

## Researching mods before deploy

The server runs **1.22.x** — always confirm a mod targets it before deploying; ModDB version *tags* are authoritative, page blurbs and comments ("works on 1.22") are not.

**Chuck's recommendation filter:** he wants added *challenge without grind*. Favor focused, single-purpose mods; skip RPG-progression systems (XSkills) and full early-game survival overhauls (Primitive Survival), and avoid kitchen-sink tweak packs (Dana Tweaks) — he finds them bloated. Anti-grind QoL is welcome; busywork and tedium are not.

- **Compat + download URL in one shot:** `curl -s https://mods.vintagestory.at/api/mod/<urlalias-or-numeric-modid>` returns JSON with `mod.releases[]` (each has `filename`, `tags` = the exact game versions, `mainfile` = direct CDN download) and `mod.side`. Use `urlalias` (e.g. `temporalsreformed`) or the API **modid** — note the `/show/mod/<N>` page number is an *assetid*, NOT the API modid, so numeric lookups often resolve the wrong mod; prefer the alias.
- **Client vs server side:** check the zip's `modinfo.json` `side`. `side: server` (or unset/universal) → deploy to `$REMOTE_BASE/Mods`. **`side: client` mods (e.g. render tweaks) must go in each player's own client Mods folder (`$LOCAL_MODS`), not the server** — VS does not push client mods to players. Verify a download first: `unzip -t` for integrity, `unzip -p <zip> modinfo.json` for modid/version/side/dependencies.

## File layout invariants

- `vintage-story/configs/` — **canonical / source-of-truth** files (what chuck wants the live server to look like). Edited by hand. Push these UP to the server, never overwrite from a pull.
- `vintage-story/snapshots/<UTC-ts>/` — **frozen point-in-time captures** from the live server. Created by `snapshot.rb`. Read-only reference; for diffing, rollback, or post-mortem.
- `vintage-story/.env` — credentials. Gitignored.
- Local mod folder is symlinked at `/tmp/vs_local_mods` to dodge the space in `Application Support`. Recreate with `ln -sfn "$LOCAL_MODS" /tmp/vs_local_mods`.

## Pre-risk workflow (before /db prune, mod swap, version upgrade)

```bash
vintage-story/scripts/snapshot.rb                     # local config snapshot
vintage-story/scripts/rcon.rb autosavenow             # flush a save
vintage-story/scripts/rcon.rb genbackup before-prune  # server-side backup into backups/
# kick players (in-game admin chat / panel), then proceed
```

## Playerdata caveat

VS only persists `playerdata.json` entries for UIDs it sees connect. Seeding admins for players
who haven't joined yet works only until the next autosave (every 5 min) — the unseen entries get
dropped. Reliable alternatives:

1. Have each player log in once after the file is uploaded + server is bounced.
2. Use `/role <playername> admin` in-game once they connect.
3. Whitelist-only mode (`OnlyWhitelisted: true` in serverconfig + `playerswhitelisted.json`).

## Bouncing

`serverconfig.json` and (initial) `playerdata.json` only load at server start. Mods load at start.
Use the Host Havoc panel to restart — there's no remote restart from here.

## Calendar speed (and other runtime-only settings)

Calendar speed is **not** a worldconfig field — it's the runtime command `/time calendarspeedmul <x>`,
which **does not persist**: a bare runtime set reverts to 0.5 on the next restart. To make it stick,
put it in `serverconfig.json` → **`StartupCommands`** (newline-separated; runs every boot). This is
the pattern for any runtime-only command you want permanent.

- Currently set: `StartupCommands: "/time calendarspeedmul 0.4"` → server logs
  `Base calendar speed mul 0.4 set. 1 day = 60 real life minutes` at boot.
- Math: 60 real-min/day × 168 game-days-per-season (3 months × `daysPerMonth 56`) = **1 season per
  real week** of *populated* time. Lower mul = slower; `24 ÷ mul = real-min per game day`.
- Reminder: with `PassTimeWhenEmpty: false`, the clock only advances while ≥1 player is connected,
  so "per real week" means populated time, not wall-clock.
- Verify after a restart by grepping `server-main.log` for `calendar speed mul` (there's no RCON read
  subcommand for it yet).

## Remote command access (RCON)

The server runs the **VintageRCon** mod (`mods.vintagestory.at/vintagercon`). Source RCON protocol,
port `42425` (configurable in `ModConfig/vsrcon.json` — the filename is `vsrcon.json`, NOT
`vintagercon.json` as the README implies; the mod writes a default on first start), password in
`.env` as `RCON_PASS`.

`scripts/rcon.rb` is a safe-by-construction dispatcher and the **only** RCON path. It maps a fixed set of subcommands to literal server commands, rejects everything else before opening a socket, and loads creds from `.env` via `lib.rb`.

| Subcommand | Sends | Use |
|---|---|---|
| `list <clients\|banned\|roles\|privileges>` | `/list …` | who's on, bans, roles (server requires the arg) |
| `info [ident\|seed\|createdversion\|mapsize]` | `/info …` | save-game info |
| `time` / `stats` / `weather` | as-is | world + server state |
| `mods` | `/moddb list` | loaded mods |
| `help` | `/help` | server command list |
| `wc <field>` | `/worldconfig <field>` | **read only** — one field, no value accepted |
| `wc-set <field> <value>` | `/worldconfig <field> <value>` | **write** — one field + one charset-safe value; **hook-blocked**, chuck-only via `!` |
| `wc-dump [outfile]` | loops `/worldconfig <field>` over every field | live worldconfig → typed JSON + drift table on stderr; used by `snapshot.rb` |
| `autosavenow` | `/autosavenow` | flush a save |
| `genbackup [name]` | `/genbackup [name]` | hot backup into `backups/` |

Run `scripts/rcon.rb --selftest` to exercise the accept/reject + parse logic offline (51 cases, no network).

**`wc-set` is the one write path** and is deliberately the only command `vs-guard.rb` blocks on the
RCON side. It can express *only* `worldconfig <field> <value>` with a space-free, charset-restricted
field and value — no other command, no second value, can be smuggled through. Because it mutates the
live world, the hook stops it as a tool call; surface the exact line for chuck to run with `!`.

**Worldconfig changes need a server RESTART to take effect** — verified 2026-06-01: after a `wc-set`,
the live read (`wc-dump`) still showed the old value; the write lands in the savegame DB but the
running process keeps the loaded value until reboot. (This is also why `wc-set` beats editing
`serverconfig.json`: the file is ignored post-creation, the command writes the DB.) So the apply
sequence is **set all fields → restart from the Host Havoc panel → `wc-dump` to verify drift cleared.**
Scope caveats: worldgen fields are new-chunks-only (globalPrecipitation, surface*Deposits, …) or
creation-only and unchangeable on an existing world (landcover, oceanscale, geologicActivity,
landformScale, upheavelCommonness). **Full field table, types, valid values, and categories:
[worldconfig-reference.md](worldconfig-reference.md).**

**Why `wc-dump`:** a world's `WorldConfiguration` is baked into the savegame SQLite DB at creation;
after that, editing `serverconfig.json`'s `WorldConfiguration` does **nothing** to the running world
— it's only a creation-time seed, so live values can only be read back over RCON. `wc-dump` reads
every field, coerces each to the canonical JSON type, and prints a drift table (file-vs-live). It is
not a `resolve()` path (it's multi-command) — handled as a main-level mode like `--selftest`, but
each field still goes through `resolve(["wc", field])`. Note: top-level serverconfig fields
(`AllowPvP`, `Password`, `AdvertiseServer`, …) are NOT save-baked and DO load from the file at startup.

**RCON has full console privileges by design** — VintageRCon has no per-command privilege. Two layers stand in for that: (1) `rcon.rb` exposes no raw passthrough, so most destructive commands (`/db prune`, `/wgen regen`, `/ban`, `/kick`, `/role set`, `/op add`, `/stop`) simply can't be expressed — run those from in-game admin chat or the Host Havoc web console; (2) the one write that *is* expressible, `wc-set`, is stopped by `vs-guard.rb` as a tool call so only chuck can run it via `!`. To make another command routinely available, add a subcommand to `rcon.rb` — a deliberate, reviewable edit — and decide whether it belongs in the guard's block list; never add a raw client.

RCON port 42425 turned out to be reachable on Host Havoc without a panel request (verified live).
If a future host blocks it, request the port through their panel/support.

## SFTP / shell options (lower-power alternatives)

- **SFTP**: file-level only (`sftp.rb`). Cannot run server-side commands.
- **SSH shell**: tends to be blocked by the auto-mode safety classifier as "shell into prod"; even
  if it worked, it'd give filesystem access, not in-game-chat commands.
- **Polling tail (`scripts/tail-log.rb`)**: strictly read-only, zero write capability. Surfaces in-game command output through the log (audit, autosave, prune progress, mod load, errors). Good for "watching" without RCON.

## Common reference

```
/autosavenow                    # flush dirty chunks
/genbackup [name]               # full save copy into backups/ (hot, no pause)
/wgen pos                       # show chunk coords
/wgen regenc <chunks>           # regen around spawn — DESTROYS BUILDS in radius
/wgen autogen 0|1               # toggle auto chunk gen
/db prune <N> drop confirm      # drop chunks with <N player edits; keep ones with builds
/role <player> <code>           # set role (codes in serverconfig Roles list)
/ban <player> [reason]          # ban a connected player
```

## Server paths (remote)

- Instance root: `/216.245.177.5_27504/`
- Configs at root: `serverconfig.json`, `servermagicnumbers.json`
- Playerdata: `Playerdata/{playerdata,playersbanned,playerswhitelisted,playergroups}.json` (capital P)
- Mods: `Mods/` — the 6 `VS*.dll/.pdb` files are core game assemblies, do not delete
- Logs: `Logs/server-main.log`, `Logs/server-debug.log`, rotated to `Logs/Archive/`
