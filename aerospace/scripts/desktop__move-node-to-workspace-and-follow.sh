#!/usr/bin/env bash
# desktop__move-node-to-workspace-and-follow.sh <NUMBER>
set -euo pipefail

LOGFILE="/tmp/aerospace.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0"): $*" >> "$LOGFILE"; }

WIN_ID=$(aerospace list-windows --focused --json | jq -r '.[0]["window-id"]')
MON_ID=$(aerospace list-monitors --focused --json | jq -r '.[0]["monitor-id"]')
case "$MON_ID" in
  1) SUF="L" UNFOCUSED_WS_1="$1"C UNFOCUSED_WS_2="$1"R;;
  2) SUF="C" UNFOCUSED_WS_1="$1"L UNFOCUSED_WS_2="$1"R;;
  3) SUF="R" UNFOCUSED_WS_1="$1"L UNFOCUSED_WS_2="$1"C;;
esac
FOCUSED_WS="$1$SUF"
aerospace workspace $UNFOCUSED_WS_1
aerospace workspace $UNFOCUSED_WS_2
aerospace move-node-to-workspace --focus-follows-window --window-id $WIN_ID $FOCUSED_WS

log "Moved window $WIN_ID to workspace $FOCUSED_WS with focus, and switched to workspaces $UNFOCUSED_WS_1, $UNFOCUSED_WS_2"

