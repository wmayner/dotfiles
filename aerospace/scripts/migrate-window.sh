#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/tmp/aerospace.log"
DEBUG="${DEBUG:-0}"

# Function to log debug messages
dlog() {
  if [[ "$DEBUG" == "1" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0"): $*" >> "$LOGFILE"
  fi
}

# Set MODE, WIN_ID, CUR_WS, and MON_ID directly from positional parameters
MODE="${1:-}"; WIN_ID="${2:-}"; CUR_WS="${3:-}"; MON_ID="${4:-}"

if [[ "$MODE" != "main" && "$MODE" != "desktop" ]] || [[ -z "$WIN_ID" || -z "$CUR_WS" || -z "$MON_ID" ]]; then
  echo "Usage: $(basename "$0") <main|desktop> <WINDOW_ID> <CUR_WS> <MON_ID>" >&2
  exit 2
fi

maximize_by_id() {
  aerospace fullscreen on --window-id "$1" --no-outer-gaps >/dev/null 2>&1 || true
}

NUM="${CUR_WS%[LCR]}"
[[ "$NUM" =~ ^[0-9]+$ ]] || exit 0

if [[ "$MODE" == "main" ]]; then
  if [[ "$CUR_WS" != "$NUM" ]]; then
    aerospace move-node-to-workspace "$NUM" --window-id "$WIN_ID" >/dev/null 2>&1 || true
    maximize_by_id "$WIN_ID"
    dlog "Moved window $WIN_ID from $CUR_WS to $NUM (main mode)"
  fi
  exit 0
fi

case "$MON_ID" in
  1) SUF="L" ;; 2) SUF="C" ;; 3) SUF="R" ;; *) SUF="C" ;;
esac

TARGET_WS="${NUM}${SUF}"

if [[ "$CUR_WS" != "$TARGET_WS" ]]; then
  aerospace move-node-to-workspace "$TARGET_WS" --window-id "$WIN_ID" >/dev/null 2>&1 || true
  maximize_by_id "$WIN_ID"
  dlog "Moved window $WIN_ID from $CUR_WS to $TARGET_WS (desktop mode)"
fi
