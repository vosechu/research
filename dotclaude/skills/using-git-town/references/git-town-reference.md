# git-town reference

Verified against the official git-town **22.7** docs (`git-town.com/commands/*`), 2026-07-01,
plus two incidents in this repo.

## Commands — what each actually does

| Command | What it does | Gotcha |
|---|---|---|
| `git town hack <name>` / `append <name>` | new feature branch — `hack` off main, `append` as a child of the current branch | — |
| `git town sync [--all] [--stack]` | integrate: pull/push parent + tracking branch, rebase, **stash uncommitted changes (incl. untracked) as "Git Town WIP" and restore when done**, and prune branches whose remote was deleted *if they have no unshipped commits* | if interrupted, the WIP stash is left unpopped → files "vanish" (recover with `git stash apply`) |
| `git town propose [-t <title>] [-f <body-file>]` | **syncs first** (detached), then opens a PR on the forge (browser, or the configured connector e.g. `gh`) | needs forge config on GHE (else "unsupported forge type"); inherits sync's stash behavior; needs a known parent (`set-parent`) |
| `git town ship [-m <msg>]` | **squash-merges** the branch into main, closes the PR, deletes the branch | the merge — **gated to the human** here; the squash commit **needs `-m` / `--message-file` non-interactively** or it aborts on the empty commit message (then auto-undoes cleanly). For a single non-stacked PR the GHE **UI merge** is simpler — git-town's own docs recommend the UI/merge-queue and call `ship` an edge-case (offline / stacked) tool |
| `git town undo` | reverts the *last fully-executed* git-town command to the exact prior state | the safe back-out for a bad/failed command |
| `git town continue` | resume the paused command after you fix what blocked it | use after fixing the cause (forge config, a conflict) |
| `git town skip [--park]` | **skip a branch that has merge conflicts while syncing all branches** — NOT a generic "clear paused state" | misused on a failed `propose` it **deleted our remote branch**; prefer `undo`/`continue` |
| `git town status` | shows whether a git-town command is paused (offers continue/skip) | read-only |
| `git town set-parent <parent>` | set a branch's parent | `propose` errors "cannot determine parent branch" non-interactively without it |

**Source quotes** (git-town.com): sync — *"safely stashes away uncommitted changes and
restores them when done"* and *"deletes branches whose tracking branch was deleted at the
remote if they contain no unshipped changes."* propose — *"syncs the branch to merge before
opening the pull request in detached mode."* undo — *"reverts the last fully executed Git Town
command … leaves your repository in the state it was before."* skip — *"skip a branch with
merge conflicts when syncing all feature branches."*

## Config (git config, per-repo)

| Key | Value | Why |
|---|---|---|
| `git-town.main-branch` | `main` / `master` | the trunk |
| `git-town.forge-type` | `github` | GHE hosts aren't auto-detected → set explicitly or get "unsupported forge type" |
| `git-town.github-connector` | `gh` | drive the forge via the authed `gh` CLI (vs a token); needs `GH_HOST=source.datanerd.us gh auth status` OK |
| `git-town-branch.<b>.parent` | `<parent>` | branch lineage; git-town writes these, `set-parent` fixes them |

Config lives in `git config` (this repo) — not a `.git-town.toml`. Crib a known-good set:
`git -C ../nr-query-bridge config --get-regexp '^git-town\.'`.

## Recovery playbook

1. **Files vanished after a git-town command** → `git stash list` (look for "Git Town WIP") →
   `git stash apply stash@{0}` (apply, don't pop, until verified). The WIP stash captures
   untracked files too, so newly-created files land there.
2. **Command paused / "hit a problem"** → `git town status`. Fix the cause, then
   `git town continue`. To abandon and revert instead: `git town undo`. Do **not** use `skip`
   unless it's a genuine mid-sync merge conflict.
3. **"unsupported forge type"** → set `forge-type` + `github-connector` (above), then
   `git town continue` (resume) or a fresh `git town propose`.
4. **Commits seem gone / a branch pointer moved / a remote was deleted** → `git reflog`,
   `git fsck --dangling`. Commits persist in `.git/objects` even when unreferenced; local
   commits survive a remote-branch deletion. If the remote branch was deleted and the local
   upstream now shows `[gone]` (sync/propose then goes into prune/cleanup instead of pushing),
   run `git branch --unset-upstream`, then `git town propose` re-pushes and re-creates it.
5. **A raw `git push` / `gh pr` / merge was denied** → that's the `git-town-steer` hook. Use
   `git town` (propose/ship). If **git-town itself** is what failed, STOP and surface it — don't
   route around a git-town failure with raw git/gh.

## Pre-flight checklist (before any `git town sync` / `propose` / `ship`)

- [ ] Working tree clean — commit or stash your own changes first (kills the WIP-stash dance).
- [ ] Forge config set on GHE (`forge-type=github`, `github-connector=gh`).
- [ ] Branch has a parent (`git town set-parent <parent>` if propose complains).
- [ ] `gh` authed to the host (`GH_HOST=source.datanerd.us gh auth status`).
