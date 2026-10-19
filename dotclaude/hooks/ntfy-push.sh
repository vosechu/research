#!/usr/bin/env bash
set -uo pipefail

# Pushes Claude Code Notification/Stop events to ntfy.sh so they reach a
# phone. Topic name lives outside the repo (~/.claude/ntfy-topic) since
# ntfy.sh topics have no auth -- anyone who knows the name can read it.
#
# Notifications are delayed by DELAY_SECS: a pending marker is written per
# session, and a backgrounded sleep checks it's still the newest marker before
# actually pushing. The UserPromptSubmit hook (cancel-ntfy-pending.sh) deletes
# the marker as soon as the user responds, so answering within the window
# skips the phone ping entirely.

DELAY_SECS=600

TOPIC_FILE="$HOME/.claude/ntfy-topic"
[[ -r "$TOPIC_FILE" ]] || exit 0
TOPIC=$(cat "$TOPIC_FILE")
[[ -n "$TOPIC" ]] || exit 0

INPUT=$(cat)
EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // "unknown"')
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // "unknown"')
DIR=$(basename "$CWD")
BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null || true)
LABEL="$DIR"
[[ -n "$BRANCH" ]] && LABEL="$DIR @ $BRANCH"

case "$EVENT" in
  Notification)
    NOTIF_TYPE=$(printf '%s' "$INPUT" | jq -r '.notification_type // "unknown"')
    case "$NOTIF_TYPE" in
      permission_prompt) TITLE="Claude needs a permission ($LABEL)" ;;
      idle_prompt)       TITLE="Claude is waiting for you ($LABEL)" ;;
      *)                 TITLE="Claude notification ($LABEL)" ;;
    esac
    BODY=$(printf '%s' "$INPUT" | jq -r '.message // .notification_type // "?"')
    ;;
  Stop)
    TITLE="Claude finished ($LABEL)"
    BODY="Session stopped in $CWD"
    ;;
  *)
    exit 0
    ;;
esac

PENDING_FILE="/tmp/claude-ntfy-pending-$SESSION_ID"
STAMP="$$-$RANDOM-$(date +%s)"
printf '%s' "$STAMP" > "$PENDING_FILE"

(
  sleep "$DELAY_SECS"
  if [[ -f "$PENDING_FILE" ]] && [[ "$(cat "$PENDING_FILE" 2>/dev/null)" == "$STAMP" ]]; then
    curl -s -m 10 \
      -H "Title: $TITLE" \
      -H "Priority: default" \
      -d "$BODY" \
      "https://ntfy.sh/$TOPIC" >/dev/null 2>&1 || true
    rm -f "$PENDING_FILE"
  fi
) >/dev/null 2>&1 &
disown
