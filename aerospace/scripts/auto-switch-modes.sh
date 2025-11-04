#!/usr/local/bin/bash
# Detect target mode using monitor count and switch to the target mode, restoring and migrating windows.
# Usage:
#   switch_modes.sh <main|desktop>

LOGFILE="/tmp/aerospace.log"
  log "$num"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0"): $*" >> "$LOGFILE"; }

MONITOR_COUNT="$(aerospace list-monitors --count 2>/dev/null || echo 1)"

log "Monitor count: $MONITOR_COUNT"

if [[ "$MONITOR_COUNT" -gt 1 ]]; then
  log "Auto-switching to desktop mode"
  TARGET_MODE="desktop"
else
  log "Auto-switching to main mode"
  TARGET_MODE="main"
fi

/Users/will/dotfiles/aerospace/scripts/switch-modes.sh "$TARGET_MODE"
