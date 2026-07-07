#!/usr/bin/env bash
# Runs ../link.sh against a temp CLAUDE_HOME and asserts the shared base.
# Content-link assertions (individual skills/agents/rules) are added once the
# general-purpose content is moved in (see the content-move task).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$(dirname "$HERE")"
FAILS=0
assert() { if eval "$2"; then echo "ok   - $1"; else echo "NOT OK - $1"; FAILS=$((FAILS+1)); fi; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
CLAUDE_HOME="$TMP" "$SRC/link.sh" >/dev/null 2>&1

assert "skills/ is a real dir, not a symlink" "[ -d '$TMP/skills' ] && [ ! -L '$TMP/skills' ]"
assert "settings.json linked" "[ -e '$TMP/settings.json' ]"
assert "CLAUDE.md linked"     "[ -e '$TMP/CLAUDE.md' ]"

# The shared base must NOT carry any work-only / machine-specific config.
assert "no NR credential helper (apiKeyHelper)" "! jq -e '.apiKeyHelper' '$TMP/settings.json' >/dev/null 2>&1"
assert "no NR gateway URL (ANTHROPIC_BASE_URL)" "! jq -e '.env.ANTHROPIC_BASE_URL' '$TMP/settings.json' >/dev/null 2>&1"
assert "no work statusLine"                     "! jq -e '.statusLine' '$TMP/settings.json' >/dev/null 2>&1"
assert "no model pin (home picks its own)"      "! jq -e '.model' '$TMP/settings.json' >/dev/null 2>&1"

# The shared base MUST keep the general prefs and the full safety deny-list.
assert "general env preserved"       "jq -e '.env.CLAUDE_CODE_SCROLL_SPEED' '$TMP/settings.json' >/dev/null"
assert "deny safety list present"    "[ \"\$(jq '.permissions.deny|length' '$TMP/settings.json')\" -ge 50 ]"

[ "$FAILS" -eq 0 ] && echo "ALL PASS" || { echo "$FAILS FAILED"; exit 1; }
