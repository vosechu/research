---
description: Use when pushing, opening a PR, syncing, or merging in an NR repo that uses git-town (source.datanerd.us), or running any `git town` command (sync / propose / ship / hack / append) — and when recovering from a git-town surprise: files vanished into a "Git Town WIP" stash, a paused runstate, "unsupported forge type", a deleted branch, or a raw `git push`/`gh`/merge that got denied.
---

# Using git-town (in NR repos)

These repos hand push / PR / merge to **git-town**. A `git-town-steer.sh` hook *denies* raw
`git push`, `gh pr create`, and merges to `main`, and tells you to use `git town` instead.
git-town runs `gh` in its own process, so it isn't blocked by that hook. This skill is how to
drive it without losing work — we've paid tuition on its surprises twice.

## The model

git-town tracks a **main branch** plus **feature branches**, each with a recorded **parent**,
so branches stack. Core verbs: `hack`/`append` (new branch), `sync` (integrate + push),
`propose` (open PR), `ship` (merge), `undo` (revert the last git-town command), `continue`
(resume after fixing), `skip` (skip a *conflicted* branch mid-sync).

## The one habit that prevents most pain: clean tree first

`sync`, `propose`, and `ship` all **sync first, which stashes ALL your uncommitted changes —
including untracked files — as a "Git Town WIP" stash, then restores them when done.** If the
command errors or is interrupted mid-flight (unrecognized forge, a conflict, a refused push),
**the stash is left unrestored and your files "vanish."** They aren't lost — they're in the
stash — but it's alarming and easy to compound.

**So before any `git town sync` / `propose` / `ship`, commit or stash your own work first.** A
clean working tree = no WIP dance = nothing to lose. This is the single highest-leverage habit.

## GHE (source.datanerd.us) needs forge config

git-town auto-detects github.com and gitlab.com but **not** GHE hosts, so `propose`/`ship`
fail with **"unsupported forge type"** until you configure it (one-time per repo):

```
git config git-town.forge-type github
git config git-town.github-connector gh   # use the gh CLI; needs: GH_HOST=source.datanerd.us gh auth status
```

Crib from a repo that already works: `git -C ../nr-query-bridge config --get-regexp '^git-town\.'`.

## When something goes wrong: undo, don't skip

- **Back out a failed/unwanted command → `git town undo`** — reverts to the exact pre-command
  state. This is the safe recovery.
- **Retry after fixing the cause (e.g. you just set forge-type) → `git town continue`.**
- **`git town skip` is NOT "clear the paused state."** It means "skip a branch that has *merge
  conflicts* during a multi-branch sync." Using it to clear a failed `propose` is misuse and is
  destructive — for us it **deleted the remote branch**. Don't reach for skip unless you're
  mid-sync on a genuinely conflicted branch.

## Recovering lost files (the WIP stash)

```
git stash list             # look for "Git Town WIP"
git stash apply stash@{0}  # apply (keeps the stash); pop only once you've verified
```
Commits are safe too — `git reflog` and `git log <branch>` show them even if a branch pointer
moved or a remote was deleted.

## This environment's guardrails

- **Landing on `main` is gated away from the agent.** `git town propose` (create/update a PR)
  is fine; **`git town ship` (the merge) is the human's.**
- **Loud-failure rule:** if a `git town` command errors, conflicts, or refuses a push, **STOP
  and surface it** — do NOT fall back to raw `git push`/`gh` to force it. The git-town failure
  is the bug to report, not route around.
- Read-only `gh` (`pr view/list/checks`, `api`), `git switch`, and `git merge-base` are fine.

## Reference

`references/git-town-reference.md` — per-command semantics (verified against the git-town 22.7
docs), the config keys, and a recovery playbook + pre-flight checklist.
