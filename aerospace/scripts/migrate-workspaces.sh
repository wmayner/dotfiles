#!/usr/bin/env bash
set -euo pipefail

LOGFILE="/tmp/aerospace.log"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0"): $*" >> "$LOGFILE"; }

MODE="${1:-}"
if [[ "$MODE" != "main" && "$MODE" != "desktop" ]]; then
  echo "Usage: $(basename "$0") <main|desktop>" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ONE="$SCRIPT_DIR/migrate-window.sh"
[[ -x "$ONE" ]] || { echo "Error: not executable: $ONE" >&2; exit 1; }

collect_main() {
  for n in {1..10}; do
    for s in L C R; do
      aerospace list-windows --workspace "${n}${s}" \
        --format '%{window-id} %{workspace} %{monitor-id}' \
        2>/dev/null || true
    done
  done
}

collect_desktop() {
  for n in {1..10}; do
    aerospace list-windows --workspace "$n" \
      --format '%{window-id} %{workspace} %{monitor-id}' \
      2>/dev/null || true
  done
}

log "Migrating windows to $MODE mode..."

if [[ "$MODE" == "main" ]]; then
  collect_main
else
  collect_desktop
fi | awk 'NF==3' | while IFS=' ' read -r id ws mon; do
  [[ -n "${id:-}" && -n "${ws:-}" && -n "${mon:-}" ]] || continue
  "$ONE" "$MODE" "$id" "$ws" "$mon" &
done

wait

msg="Done migrating windows to $MODE mode"
log "$msg."
echo "$msg"
