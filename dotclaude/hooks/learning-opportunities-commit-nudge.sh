#!/usr/bin/env bash
set -uo pipefail

# learning-opportunities commit nudge (local jq-based replacement)
#
# Drop-in replacement for the learning-opportunities-auto plugin's
# PostToolUse/Bash hook. The plugin version greps the ENTIRE hook payload
# (tool_input + tool_response) for '"command".*git.*commit', so it fired on
# read-only turns whenever "git" and "commit" both appeared anywhere in the
# blob -- e.g. `git log` output that mentions commits, or a `grep` whose
# pattern literally contained the words "git commit".
#
# This version parses ONLY .tool_input.command with jq, strips quoted
# substrings, then confirms the executable is `git` and its subcommand is
# `commit`. Requires jq (Homebrew) in addition to bash + coreutils.

INPUT=$(cat)

# --- Extract the command that ran. Never look at the tool response. --------
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# --- Remove quoted spans so words INSIDE string literals never count. -------
# `grep -rn "... git commit ..."` -> the quoted pattern is deleted, leaving no
# git/commit tokens. `git commit -m "msg about commit"` -> keeps `git commit`.
DEQUOTED=$(printf '%s' "$CMD" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")

# Return 0 if a single command segment is a real `git ... commit` invocation.
is_git_commit_segment() {
  local seg="$1"
  local -a toks
  read -ra toks <<< "$seg"
  local n=${#toks[@]} i=0

  # Skip leading env assignments (FOO=bar) and common command wrappers.
  while (( i < n )); do
    case "${toks[i]}" in
      *=*) ((i++)) ;;
      sudo|command|nice|nohup|time|env) ((i++)) ;;
      *) break ;;
    esac
  done

  # The executable itself must be git (allow an absolute path to git).
  [[ "${toks[i]:-}" == "" ]] && return 1
  [[ "${toks[i]##*/}" == "git" ]] || return 1
  ((i++))

  # Skip git's global options (and the arg of options that take one) so the
  # subcommand of `git -C /path commit` or `git -c k=v commit` is still found.
  while (( i < n )); do
    case "${toks[i]}" in
      -C|-c|--git-dir|--work-tree|--namespace|--exec-path) ((i += 2)) ;;
      -*) ((i++)) ;;
      *) break ;;
    esac
  done

  # The first bareword after git's global options is its subcommand.
  [[ "${toks[i]:-}" == "commit" ]]
}

# --- Split the de-quoted command on shell separators and test each segment. -
MATCH=0
while IFS= read -r seg; do
  [[ -z "${seg// /}" ]] && continue
  if is_git_commit_segment "$seg"; then MATCH=1; break; fi
done < <(printf '%s\n' "$DEQUOTED" | sed -E 's/&&/\n/g; s/\|\|/\n/g; s/\|/\n/g; s/;/\n/g')

[[ "$MATCH" -eq 1 ]] || exit 0

# --- Rate limit: at most 2 offers per session (same as the plugin). --------
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
[[ -z "$SESSION_ID" ]] && exit 0

STATE_FILE="${TMPDIR:-/tmp}/lo_commit_nudge_${SESSION_ID//[^a-zA-Z0-9_-]/_}.state"
offers=0
[[ -f "$STATE_FILE" ]] && offers=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
[[ "$offers" -ge 2 ]] && exit 0
echo $(( offers + 1 )) > "$STATE_FILE"

# --- Emit the nudge (verbatim from the upstream plugin). -------------------
cat <<'HOOK_JSON'
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"[learning-opportunities-auto] The user just committed code. Per the learning-opportunities skill, consider whether this is a good moment to offer a learning exercise. If the committed work involved new files, schema changes, architectural decisions, refactors, or unfamiliar patterns, ask the user (one short sentence) if they'd like a 10-15 minute exercise. Do not start the exercise until they confirm. If they decline, note it — no more offers this session."}}
HOOK_JSON

exit 0

