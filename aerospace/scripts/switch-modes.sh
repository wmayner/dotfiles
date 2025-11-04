#!/usr/local/bin/bash
# Switch to the target mode, restoring and migrating windows.
# Usage:
#   switch-modes.sh <main|desktop>

LOGFILE="/tmp/aerospace.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0"): $*" >> "$LOGFILE"; }

ws_num() {
  local ws="$1"
  # strip trailing L/C/R if present
  printf "%s" "${ws%[LCR]}"
}

mouse_suffix_by_monitor() {
  # Focus the monitor under mouse, then read its monitor-id
  aerospace focus-monitor mouse >/dev/null 2>&1 || true
  local mid
  mid="$(aerospace list-monitors --focused --json 2>/dev/null | jq -r '.[0]["monitor-id"] // "2"')"
  case "$mid" in
    1) echo "L" ;;
    2) echo "C" ;;
    3) echo "R" ;;
    *) echo "C" ;;
  esac
}

switch_to_corresponding() {
  local prev_ws="$1" target_mode="$2"
  [[ -n "$prev_ws" ]] || return 0
  local num; num="$(ws_num "$prev_ws")"
  [[ "$num" =~ ^[0-9]+$ ]] || return 0

  if [[ "$target_mode" == "main" ]]; then
    log "Switching focus to main workspace: $num"
    aerospace workspace "$num"
  else
    # desktop: choose suffix by monitor under mouse to land where you're pointing
    local suf; suf="$(mouse_suffix_by_monitor)"
    log "Switching focus to desktop workspace: ${num}${suf}"
    aerospace workspace "${num}${suf}"
  fi
}

prev_ws="$(aerospace list-workspaces --focused)"

if [[ "$1" == "main" ]]; then
#   /Users/will/dotfiles/aerospace/scripts/aerospace-save-restore.sh --mode desktop save
  log "Switching to main mode"
  aerospace mode main
  switch_to_corresponding "$prev_ws" main
  /Users/will/dotfiles/aerospace/scripts/aerospace-save-restore.sh --mode main restore
  /Users/will/dotfiles/aerospace/scripts/migrate-workspaces.sh main
  log "Done switching to main mode"
else
#   /Users/will/dotfiles/aerospace/scripts/aerospace-save-restore.sh --mode main save
  log "Switching to desktop mode"
  aerospace mode desktop
  switch_to_corresponding "$prev_ws" desktop
  /Users/will/dotfiles/aerospace/scripts/aerospace-save-restore.sh --mode desktop restore
  /Users/will/dotfiles/aerospace/scripts/migrate-workspaces.sh desktop
  log "Done switching to desktop mode"
fi
