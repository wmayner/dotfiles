#!/usr/local/bin/bash
# auto-mode.sh — switch AeroSpace mode based on monitor count
set -euo pipefail

PIDFILE="/tmp/aerospace-auto-mode.pid"

LOGFILE="/tmp/aerospace.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0"): $*" >> "$LOGFILE"; }

log "===== auto-mode.sh starting (PID $$) ====="


# Resolve this script's directory so we can call the migrator by absolute path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATOR="${MIGRATOR:-$SCRIPT_DIR/migrate-workspaces.sh}"   # allow override via env
SAVE_RESTORE="${SAVE_RESTORE:-$SCRIPT_DIR/aerospace-save-restore.sh}"   # allow override via env
log "auto-mode.sh Bash version: ${BASH_VERSION:-unknown} ($BASH_PATH)"

# ---- helpers ----

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

# ---- single-instance guard (don't kill ourselves) ----
if [[ -f "$PIDFILE" ]]; then
  old_pid="$(cat "$PIDFILE" 2>/dev/null || true)"
  if [[ -n "${old_pid:-}" ]] && kill -0 "$old_pid" 2>/dev/null; then
    # previous instance still running — stop it softly
    kill "$old_pid" 2>/dev/null || true
    for _ in {1..20}; do
      kill -0 "$old_pid" 2>/dev/null || break
      sleep 0.1
    done
    kill -9 "$old_pid" 2>/dev/null || true
  fi
fi
echo $$ > "$PIDFILE"

# ---- migration wrappers ----
migrate_main() {
  log "Migrating desktop → main via: $MIGRATOR main"
  if ! "$BASH_PATH" "$MIGRATOR" main 2> >(tee -a "$LOGFILE" >&2); then
    log "WARN: migrate main failed"
  fi
  log "Done migrating desktop → main"
}

migrate_desktop() {
  # tiny settle loop in case displays just attached
  for _ in {1..10}; do
    mons="$(aerospace list-monitors --count 2>/dev/null || echo 1)"
    [[ "$mons" -ge 2 ]] && break
    sleep 0.1
  done
  log "Migrating main → desktop via: $MIGRATOR desktop"
  if ! "$BASH_PATH" "$MIGRATOR" desktop 2> >(tee -a "$LOGFILE" >&2); then
    log "WARN: migrate desktop failed"
  fi
  log "Done migrating main → desktop"
}

pick_mode() {
  local n prev cur_num
  # Capture the currently focused workspace *before* we change anything
  local prev_ws; prev_ws="$(aerospace list-workspaces --focused)"

  n="$(aerospace list-monitors --count 2>/dev/null || echo 1)"
  if [[ "$n" -eq 1 ]]; then
    aerospace mode main
    if ! "$BASH_PATH" "$SAVE_RESTORE" --mode main restore 2>>"$LOGFILE"; then
      log "WARN: Failed to restore main layout, continuing anyway"
    fi
    migrate_main
    switch_to_corresponding "$prev_ws" main
    log "Switched to mode: main"
  else
    aerospace mode desktop
    if ! "$BASH_PATH" "$SAVE_RESTORE" --mode desktop restore 2>>"$LOGFILE"; then
      log "WARN: Failed to restore desktop layout, continuing anyway"
    fi
    migrate_desktop
    switch_to_corresponding "$prev_ws" desktop
    log "Switched to mode: desktop"
  fi
}

# ---- main loop ----
pick_mode

prev="$(aerospace list-monitors --count 2>/dev/null || echo 1)"
while sleep 2; do
  curr="$(aerospace list-monitors --count 2>/dev/null || echo 1)"
  if [[ "$curr" != "$prev" ]]; then
    log "Monitor count changed: $prev → $curr"
    pick_mode
    prev="$curr"
  fi
done
