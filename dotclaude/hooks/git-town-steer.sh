#!/usr/bin/env bash
# git-town-steer: PreToolUse(Bash) guard for raw gh/git state-changes.
#
# Targets raw STATE-CHANGING gh/git commands and routes them to git-town:
#   gh pr merge|create          -> git town ship / git town propose
#   git merge | rebase | push  -> git town sync (sync also pushes the branch)
#
# Decision depends on whether THIS repo is git-town-enabled:
#   - git-town repo (local git-town config present) -> DENY (hard steer)
#   - not git-town-enabled                          -> ASK  (prompt: set it up,
#                                                            or proceed raw)
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
# bash -c, sourcing a file) is out of scope — this is a guardrail, not a
# security boundary.
#
# SCOPE: git-town state is per-repo (local git config: main-branch, forge-type,
# git-town-branch.* lineage), never global. Enabled-ness is judged by the hook's
# cwd repo; a cross-repo `git -C /other ...` is judged by cwd, an accepted edge.

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null)

# Not a targeted raw gh/git state-change? Allow silently.
printf '%s' "$cmd" | grep -Eq '(^|[;&|(])[[:space:]]*([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]+)*(gh[[:space:]]+(-[^[:space:]]+[[:space:]]+([^-[:space:]][^[:space:]]*[[:space:]]+)?)*pr[[:space:]]+(merge|create)|git[[:space:]]+(-[^[:space:]]+[[:space:]]+([^-[:space:]][^[:space:]]*[[:space:]]+)?)*(merge|rebase|push))([[:space:]]|$)' || exit 0

# Targeted. Is this repo git-town-enabled (local git-town config present)?
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
   && git config --local --get-regexp '^git-town' >/dev/null 2>&1; then
  # git-town repo: hard steer, no silent fallback.
  cat <<'JSON'
{"systemMessage":"git-town-steer BLOCKED a raw gh/git state-change. If this is because git-town itself errored, that failure is the thing to surface and fix — it must not be routed around.","hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"git-town owns merges, pushes, PRs, and integration here. Use: git town ship (land/merge a PR), git town propose (open a PR), git town sync (integrate master, rebase, AND push your branch). Read-only gh (pr view/list/checks, api), git switch, and git merge-base are fine; git-town runs gh in its OWN process so it is never blocked by this rule. LOUD-FAILURE RULE: if you are reaching for raw gh/git because git-town itself failed (an error, a conflict, a refused push), STOP. That git-town failure is the bug to surface to the user and let them decide how to proceed — do NOT silently fall back to raw gh/git to work around a broken git-town."}}
JSON
else
  # Not git-town-enabled: prompt rather than silently allow.
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"This repo is NOT git-town-enabled (no local git-town config), so git town ship/sync/propose can't manage it here. Either set git-town up first (git town config / git town hack) and use it, or approve to run this raw gh/git command as-is if you mean to."}}
JSON
fi

exit 0
