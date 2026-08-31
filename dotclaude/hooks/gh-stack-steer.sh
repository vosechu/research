#!/usr/bin/env bash
# gh-stack-steer: PreToolUse(Bash) guard for raw gh/git state-changes.
#
# Ported from the retired git-town-steer.sh (dropped in 292c4f1 because the
# workflow moved to gh stack, not because the mechanism failed). Same shape,
# new target.
#
# Targets raw STATE-CHANGING gh/git commands and, in gh-stack-managed repos,
# REMINDS you to route them through gh stack (it does not hard-block):
#   gh pr create   -> gh stack add <branch> (from a branch already IN the
#                     stack), then gh stack submit
#   gh pr merge    -> gh stack merge
#   git push       -> gh stack push (does per-branch --force-with-lease)
#   git rebase     -> gh stack rebase
#
# Decision depends on whether the TARGET repo is gh-stack-managed. The target
# repo is the one the command operates on: `git -C <dir>`, or a leading
# `cd <dir> &&`, else the hook's cwd.
#   - gh stack repo (.git/gh-stack present) -> ASK   (remind + you approve;
#                                                    not a wall)
#   - not gh-stack-managed                  -> ALLOW (silent)
#   - command isn't one of the targets      -> ALLOW (silent)
#
# ASK rather than DENY is deliberate, inherited from the original. Raw git is
# sometimes the right call (pushing to a fork remote, a scratch branch outside
# the stack), and a hard block dead-ends those with no escape. The value is in
# interrupting the reflex at the moment it fires, not in making the command
# impossible.
#
# Leaves untouched: read-only gh (pr view/list/checks/diff/status, api),
# gh pr edit (retitling or rewriting a PR body has no gh stack equivalent),
# gh stack *, git merge-base, git switch, everything else.
#
# gh stack invokes git push / gh pr create in its OWN process, which never
# passes through this Bash-tool hook, so gh stack itself is unaffected.
#
# Match only at COMMAND POSITION so the pattern is caught when it is actually
# being INVOKED, not when it merely appears as text inside an argument:
#   - anchor: start of string, or right after a separator ; && || | (  or $(
#   - allow leading ENV=val assignments (e.g. GH_HOST=... gh pr create)
#   - ([[:space:]]|$) after the verb keeps "git pushed" allowed
# So `git commit -m "fix the git push bug"`, echo/printf, and test harnesses
# that merely mention these strings are NOT matched; `x && git push` and
# `$(gh pr create)` (real invocations) ARE.
#
# It also tolerates global options between the binary and the subcommand:
#   git -C /path push | git -c k=v rebase | gh -R owner/repo pr create
# via a repeated "(-flag [value]?)" group ([value]? is skippable, so bare
# flags like --no-pager still match). Determined evasion (eval, aliases,
# bash -c, sourcing a file) is out of scope: this is a guardrail, not a
# security boundary.
#
# SCOPE: gh stack state is per-repo (.git/gh-stack, plain JSON), never global.
# Managed-ness is judged against the TARGET repo parsed from the command
# (git -C / leading cd), else the hook cwd.

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)

# Not a targeted raw gh/git state-change? Allow silently.
printf '%s' "$cmd" | grep -Eq '(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*(gh[[:space:]]+(-[^[:space:]]+[[:space:]]+([^-[:space:]][^[:space:]]*[[:space:]]+)?)*pr[[:space:]]+(merge|create)|git[[:space:]]+(-[^[:space:]]+[[:space:]]+([^-[:space:]][^[:space:]]*[[:space:]]+)?)*(push|rebase))([[:space:]]|$)' || exit 0

# Targeted. Judge the TARGET repo: honor `git -C <dir>` or a leading `cd <dir>`,
# else fall back to the hook's cwd.
target_dir=""
gc_re='git[[:space:]]+-C[[:space:]]+([^[:space:]]+)'
cd_re='^[[:space:]]*cd[[:space:]]+([^[:space:]&;|]+)'
if [[ "$cmd" =~ $gc_re ]]; then
  target_dir="${BASH_REMATCH[1]}"
elif [[ "$cmd" =~ $cd_re ]]; then
  target_dir="${BASH_REMATCH[1]}"
fi
# strip surrounding quotes; expand a leading ~
target_dir="${target_dir%\"}"; target_dir="${target_dir#\"}"
target_dir="${target_dir%\'}"; target_dir="${target_dir#\'}"
target_dir="${target_dir/#\~/$HOME}"
gitargs=(); [[ -n "$target_dir" ]] && gitargs=(-C "$target_dir")

# gh-stack-managed target repo? Remind + gate (ask). Otherwise allow silently.
if git "${gitargs[@]}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  gitdir=$(git "${gitargs[@]}" rev-parse --git-common-dir 2>/dev/null)
  # --git-common-dir can be relative; resolve it against the repo root.
  if [[ -n "$gitdir" && "$gitdir" != /* ]]; then
    toplevel=$(git "${gitargs[@]}" rev-parse --show-toplevel 2>/dev/null)
    gitdir="${toplevel}/${gitdir}"
  fi
  if [[ -e "$gitdir/gh-stack" ]]; then
    repo=$(git "${gitargs[@]}" rev-parse --show-toplevel 2>/dev/null)
    reason="gh stack manages ${repo:-this repo}. Prefer gh stack add <branch> then gh stack submit (open a PR on top of the stack; add must run from a branch ALREADY in the stack), gh stack push (push the stack, per-branch --force-with-lease), gh stack rebase, or gh stack merge. Raw gh/git still works if you approve, and a scratch branch outside the stack or a push to a different remote is a normal reason to. If you're reaching for raw git because gh stack itself errored, STOP and surface that failure rather than routing around it."
    jq -cn --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  fi
fi

exit 0
