#!/usr/bin/env bash
# desktop__move-node-to-workspace.sh <NUMBER>
set -euo pipefail

LOGFILE="/tmp/aerospace.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0"): $*" >> "$LOGFILE"; }

WIN_ID=$(aerospace list-windows --focused --json | jq -r '.[0]["window-id"]')
MON_ID=$(aerospace list-monitors --focused --json | jq -r '.[0]["monitor-id"]')
case "$MON_ID" in
  1) SUF="L" ;;
  2) SUF="C" ;;
  3) SUF="R" ;;
esac
NEXT_WS="$1$SUF"
aerospace move-node-to-workspace --window-id $WIN_ID $NEXT_WS
terminal-notifier \
    -message "Moved to $NEXT_WS" \
    -title "AeroSpace" \
    -groupID "com.aerospace.notifications" \
    -appIcon "/Applications/AeroSpace.app/Contents/Resources/AppIcon.icns"

log "Moved window $WIN_ID to workspace $NEXT_WS"
