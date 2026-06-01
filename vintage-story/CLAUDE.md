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
