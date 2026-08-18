#!/usr/bin/env bash
# git-town-steer: PreToolUse(Bash) guard for raw gh/git state-changes.
#
# Targets raw STATE-CHANGING gh/git commands and, in git-town-managed repos,
# REMINDS you to route them through git-town (it does not hard-block):
#   gh pr merge|create          -> git town ship / git town propose
#   git merge | rebase | push  -> git town sync (sync also pushes the branch)
#
# Decision depends on whether the TARGET repo is git-town-enabled. The target
# repo is the one the command operates on: `git -C <dir>`, or a leading
# `cd <dir> &&`, else the hook's cwd.
#   - git-town repo (local git-town config present) -> ASK   (remind + you
#                                                            approve; not a wall)
#   - not git-town-enabled                          -> ALLOW (silent)
#   - command isn't one of the targets              -> ALLOW (silent)
#
# Leaves untouched: read-only gh (pr view/list/checks/diff/status, api),
# gh pr ready (un-drafting a PR has NO git-town equivalent, so blocking it would
# just dead-end the ready->ship flow), git town *, git merge-base, git switch,
# everything else.
#
# git-town invokes `gh pr merge`/`gh pr edit` in its OWN process, which never
# passes through this Bash-tool hook, so git-town itself is unaffected.
#
# Match only at COMMAND POSITION so the pattern is caught when it is actually
# being INVOKED, not when it merely appears as text inside an argument:
#   - anchor: start of string, or right after a separator ; && || | (  or $(
#   - allow leading ENV=val assignments (e.g. GH_HOST=... gh pr merge)
#   - ([[:space:]]|$) after the verb keeps "git merge-base"/"git pushed" allowed
# So `git commit -m "fix the git merge bug"`, echo/printf, and test harnesses
# that merely mention these strings are NOT matched; `x && git merge` and
# `$(gh pr merge)` (real invocations) ARE.
#
# It also tolerates global options between the binary and the subcommand:
#   git -C /path merge | git -c k=v rebase | gh -R owner/repo pr merge
# via a repeated "(-flag [value]?)" group ([value]? is skippable, so bare
# flags like --no-pager still match). Determined evasion (eval, aliases,
# bash -c, sourcing a file) is out of scope: this is a guardrail, not a
# security boundary.
#
# SCOPE: git-town state is per-repo (local git config: main-branch, forge-type,
# git-town-branch.* lineage), never global. Enabled-ness is judged against the
# TARGET repo parsed from the command (git -C / leading cd), else the hook cwd.

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)

# Not a targeted raw gh/git state-change? Allow silently.
printf '%s' "$cmd" | grep -Eq '(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*(gh[[:space:]]+(-[^[:space:]]+[[:space:]]+([^-[:space:]][^[:space:]]*[[:space:]]+)?)*pr[[:space:]]+(merge|create)|git[[:space:]]+(-[^[:space:]]+[[:space:]]+([^-[:space:]][^[:space:]]*[[:space:]]+)?)*(merge|rebase|push))([[:space:]]|$)' || exit 0

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

# git-town-managed target repo? Remind + gate (ask). Otherwise allow silently.
if git "${gitargs[@]}" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
   && git "${gitargs[@]}" config --local --get-regexp '^git-town' >/dev/null 2>&1; then
  repo=$(git "${gitargs[@]}" rev-parse --show-toplevel 2>/dev/null)
  reason="git-town manages ${repo:-this repo}. Prefer git town propose (open/refresh a PR), git town sync (integrate + push), or git town ship (merge, usually the human's). Raw gh/git still works if you approve, and a push to a fork remote is a normal reason to. If you're reaching for raw git because git town itself errored, STOP and surface that failure rather than routing around it."
  jq -cn --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
fi

exit 0
