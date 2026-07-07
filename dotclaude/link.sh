#!/usr/bin/env bash
# Install Chuck's SHARED (general-purpose) user-level Claude config into
# ~/.claude by symlinking (or copying) each item from this repo. Idempotent
# and non-destructive: any pre-existing real file is backed up to
# ~/.claude/<name>.bak-<timestamp> before being replaced.
#
# This is the shared layer. At work, run the work repo's link.sh AFTER this
# one to layer NR-internal config and merge the singleton files on top.
#
# Usage:
#   ./link.sh           # symlink each item into ~/.claude (default)
#   ./link.sh --copy    # copy instead of symlink (Windows / no-symlink setups)
#   ./link.sh --dry-run  # print what would happen, change nothing
#
# Source of truth is THIS repo. Edit files here; symlinks make the edits live.

set -euo pipefail

# Absolute path to this dotclaude/ dir, resolved at runtime (no baked paths).
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
STAMP="$(date +%s)"

MODE="symlink"
DRY=0
for arg in "$@"; do
  case "$arg" in
    --copy)    MODE="copy" ;;
    --dry-run) DRY=1 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

# Items that link each CHILD individually (parent dir made real), so the work
# layer can add its own children into the same ~/.claude dirs.
DIR_ITEMS=( "agents" "skills" "rules" "hooks" )
# Single-file items linked as-is.
FILE_ITEMS=( "settings.json" "CLAUDE.md" )

run() { if [ "$DRY" = 1 ]; then echo "DRY: $*"; else "$@"; fi; }

link_one() {
  local rel="$1"
  local src="$SRC/$rel"
  local dst="$DEST/$rel"

  if [ ! -e "$src" ]; then
    echo "SKIP (source missing): $rel" >&2
    return
  fi

  # Already a symlink pointing at our source? Nothing to do.
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "OK (already linked): $rel"
    return
  fi

  run mkdir -p "$(dirname "$dst")"

  # Back up anything real (or a wrong symlink) sitting at the destination.
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local bak="$dst.bak-$STAMP"
    echo "BACKUP: $dst -> $bak"
    run mv "$dst" "$bak"
  fi

  if [ "$MODE" = "copy" ]; then
    echo "COPY: $rel"
    run cp -R "$src" "$dst"
  else
    echo "LINK: $rel -> $src"
    run ln -s "$src" "$dst"
  fi
}

link_children() {   # link each child of a directory item individually
  local dir="$1" child
  [ -d "$SRC/$dir" ] || { echo "SKIP (missing dir): $dir" >&2; return; }
  run mkdir -p "$DEST/$dir"
  for child in "$SRC/$dir"/*; do
    [ -e "$child" ] || continue
    link_one "$dir/$(basename "$child")"
  done
}

echo "Source : $SRC"
echo "Dest   : $DEST"
echo "Mode   : $MODE$( [ "$DRY" = 1 ] && echo ' (dry-run)')"
echo

for rel in "${FILE_ITEMS[@]}"; do link_one "$rel"; done
for d   in "${DIR_ITEMS[@]}";  do link_children "$d"; done

echo
echo "Done. Restart Claude Code (or start a new session) to pick up changes."
