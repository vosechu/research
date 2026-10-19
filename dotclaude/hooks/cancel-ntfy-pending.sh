#!/usr/bin/env bash
set -uo pipefail

# UserPromptSubmit hook. The user responding means any pending ntfy push for
# this session (see ntfy-push.sh) is stale -- delete its marker so the
# backgrounded sleep finds it gone and skips the phone ping.

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"')
rm -f "/tmp/claude-ntfy-pending-$SESSION_ID"
