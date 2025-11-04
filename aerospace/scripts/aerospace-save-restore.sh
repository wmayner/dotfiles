#!/usr/local/bin/bash
# Save/restore windows to their previous workspaces, mode-aware.
# Dependencies: aerospace CLI, jq
# Usage:
#   aerospace-save-restore.sh [-d|--debug] [--mode main|desktop] save
#   aerospace-save-restore.sh [-d|--debug] [--mode main|desktop] restore
#   aerospace-save-restore.sh --help

# set -euo pipefail

LOGFILE="${LOGFILE:-/tmp/aerospace.log}"

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0"): $*" >> "$LOGFILE"; }
dlog() { [[ "$DEBUG" == "1" ]] && log "$*"; }

# Log Bash version for debugging
log "aerospace-save-restore.sh Bash version: ${BASH_VERSION:-unknown} (${BASH:-unknown})"

STATE_DIR="${STATE_DIR:-$HOME/.aerospace}"
mkdir -p "$STATE_DIR"
DEFAULT_SEGMENT="${DEFAULT_SEGMENT:-C}"  # used when mapping main->desktop

DEBUG="${DEBUG:-0}"  # -d/--debug
MODE_OVERRIDE="${MODE_OVERRIDE:-}"  # -m/--mode (target mode)

log()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(basename "$0"): $*" >> "$LOGFILE"; }
dlog() { [[ "$DEBUG" == "1" ]] && log "$*"; }

die() { echo "Error: $*" >&2; exit 1; }
have(){ command -v "$1" >/dev/null 2>&1; }

have aerospace || die "aerospace CLI not found in PATH"
have jq        || die "jq not found in PATH"

current_mode="$(aerospace list-modes --current)"
target_mode="${MODE_OVERRIDE:-$current_mode}"

STATEFILE_MAIN="$STATE_DIR/layout-main.json"
STATEFILE_DESKTOP="$STATE_DIR/layout-desktop.json"
STATEFILE="$( [[ $target_mode == main ]] && echo "$STATEFILE_MAIN" || echo "$STATEFILE_DESKTOP" )"

# --- helpers for workspace mapping between modes ---

strip_segment() {
  # "7L" -> "7", "7C"->"7", "7R"->"7", "7"->"7"
  sed -E 's/^([0-9]+)[LCR]$/\1/'
}

ensure_segment() {
  # "7"  -> "7C" (DEFAULT_SEGMENT), "7L" -> "7L", "7C"->"7C" ...
  local ws="$1"
  if [[ "$ws" =~ ^[0-9]+$ ]]; then
    echo "${ws}${DEFAULT_SEGMENT}"
  else
    echo "$ws"
  fi
}

map_ws_to_target_mode() {
  dlog "Mapping workspace for mode change: saved_mode='$1' target_mode='$target_mode' saved_ws='$2'"
  local saved_mode="$1"
  local saved_ws="$2"
  if [[ "$saved_mode" == "$target_mode" ]]; then
    dlog "  No change needed; same mode."
    echo "$saved_ws"
    return
  fi

  if [[ "$saved_mode" == desktop && "$target_mode" == main ]]; then
    dlog "  Stripping segment for desktop->main"
    strip_segment "$saved_ws"
  elif [[ "$saved_mode" == main && "$target_mode" == desktop ]]; then
    dlog "  Ensuring segment for main->desktop"
    ensure_segment "$saved_ws"
  else
    # future modes? fall back to the original
    dlog "  Unknown mode transition; leaving workspace unchanged."
    echo "$saved_ws"
  fi
  dlog "  Returning mapped workspace: '$saved_ws'"
}

# One line per window; real TABs between fields; NO %{newline} suffix
FMT_SAVE='%{app-bundle-id}%{tab}%{app-name}%{tab}%{window-title}%{tab}%{workspace}'
FMT_CUR='%{app-bundle-id}%{tab}%{app-name}%{tab}%{window-title}%{tab}%{workspace}%{tab}%{window-id}'

save_layout() {
  log "Saving layout for mode=$target_mode to $STATEFILE"

  aerospace list-windows --all --format "$FMT_SAVE" \
  | jq -R -s '
      gsub("\r\n"; "\n") | gsub("\r"; "\n")
      | split("\n")
      | map(select(. != ""))                    # drop any accidental blanks
      | map( split("\t") | select(length >= 4) )
      | {
          saved_mode: "'"$target_mode"'",
          saved_at: "'"$(date -u +%FT%TZ)"'",
          windows: map({ bundle: .[0], app: .[1], title: .[2], workspace: .[3] })
        }
    ' > "$STATEFILE"

  local entries=$(jq '.windows | length' "$STATEFILE")
  local msg="Saved $entries windows for $target_mode mode to $STATEFILE"
  log "$msg"
  echo "$msg"
}

restore_layout() {
  # Lookup helpers for file-based workspace lookup
  lookup_bundle_ws() {
    grep -F -m1 "$1" "$bundle_map_file" | awk -F'\t' '{print $3}'
  }
  lookup_app_ws() {
    grep -F -m1 "$1" "$app_map_file" | awk -F'\t' '{print $3}'
  }
  # Prefer the statefile for the target mode; fall back to the other.
  local saved_file="$STATEFILE"
  local alt_file; if [[ $target_mode == main ]]; then alt_file="$STATEFILE_DESKTOP"; else alt_file="$STATEFILE_MAIN"; fi
  if [[ ! -s "$saved_file" && -s "$alt_file" ]]; then saved_file="$alt_file"; fi
  [[ -s "$saved_file" ]] || die "No saved state found for restore (checked $STATEFILE and $alt_file)."

  local saved_mode
  saved_mode="$(jq -r '.saved_mode // empty' "$saved_file")"
  [[ -n "$saved_mode" ]] || saved_mode="$target_mode"

  log "Restoring from $saved_file (saved_mode=$saved_mode) into target_mode=$target_mode"

  # Use associative arrays for lookups, populated via mapfile for efficiency
  declare -A SAVED_BUNDLE_MAP SAVED_APP_MAP

  # Populate bundle associative array using mapfile
  mapfile -t bundle_lines < <(jq -r '
      .windows
      | map(select(.bundle != null and .title != null and .workspace != null))
      | map([.bundle, .title, .workspace] | @tsv)
      | .[]
    ' "$saved_file")
  for line in "${bundle_lines[@]}"; do
    IFS=$'\t' read -r bundle title ws <<< "$line"
    [[ -n "$bundle" && -n "$title" && -n "$ws" ]] || continue
    SAVED_BUNDLE_MAP["$bundle"$'\t'"$title"]="$ws"
  done

  # Populate app associative array using mapfile
  mapfile -t app_lines < <(jq -r '
      .windows
      | map(select(.app != null and .title != null and .workspace != null))
      | map([.app, .title, .workspace] | @tsv)
      | .[]
    ' "$saved_file")
  for line in "${app_lines[@]}"; do
    IFS=$'\t' read -r app title ws <<< "$line"
    [[ -n "$app" && -n "$title" && -n "$ws" ]] || continue
    SAVED_APP_MAP["$app"$'\t'"$title"]="$ws"
  done

  # --- Iterate target windows (bundle, app, title, target_ws, id) ---

  local moved=0 skipped=0 untouched=0 errored=0

  # Capture and normalize once; then iterate an array (no stdin during loop)
  local cur_lines=()
  mapfile -t cur_lines < <(aerospace list-windows --all --format "$FMT_CUR" | sed $'s/\r$//')

  dlog "DEBUG: current-window-lines=${#cur_lines[@]}"

  # Temporarily disable -e to handle per-window errors gracefully
  set +e
  for line in "${cur_lines[@]}"; do
    # Parse one tab-separated line into fields (no stdin consumed)
    local cur_bundle cur_app cur_title cur_ws cur_id
    IFS=$'\t' read -r cur_bundle cur_app cur_title cur_ws cur_id <<< "$line"

    [[ -n "$cur_id" ]] || { dlog "WARN: missing id for title='$cur_title' bundle='$cur_bundle' ws='$cur_ws'"; ((skipped++)); continue; }


    # Lookup: bundle+title first, then app+title (associative array)
    local saved_ws=""
    local key_bundle="$cur_bundle"$'\t'"$cur_title"
    local key_app="$cur_app"$'\t'"$cur_title"

    dlog "DEBUG: Processing id=$cur_id bundle='${cur_bundle:-}' app='${cur_app:-}' title='${cur_title:-}' ws='${cur_ws:-}'"

    if [[ -n "${SAVED_BUNDLE_MAP[$key_bundle]:-}" ]]; then
      saved_ws="${SAVED_BUNDLE_MAP[$key_bundle]}"
      dlog "  Found by bundle: '$key_bundle' -> '$saved_ws'"
    elif [[ -n "${SAVED_APP_MAP[$key_app]:-}" ]]; then
      saved_ws="${SAVED_APP_MAP[$key_app]}"
      dlog "  Found by app: '$key_app' -> '$saved_ws'"
    else
      dlog "SKIPPED: not in save: bundle='${cur_bundle:-}' app='${cur_app:-}' title='${cur_title:-}'"
      ((skipped++))
      continue
    fi
    dlog "  Saved workspace for id=$cur_id is '$saved_ws' (current ws='$cur_ws')"

    # Cross-mode mapping and move if needed
    local target_ws
    dlog "DEBUG: saved_mode='$saved_mode' target_mode='$target_mode' saved_ws='$saved_ws'"
    target_ws="$(map_ws_to_target_mode "$saved_mode" "$saved_ws")"
    dlog "  Mapped target workspace for id=$cur_id is '$target_ws'"

    if [[ "$cur_ws" == "$target_ws" ]]; then
      dlog "  UNTOUCHED: id=$cur_id → '$target_ws' (had '$cur_ws') bundle='${cur_bundle:-}' app='${cur_app:-}' title='${cur_title:-}'"
      ((untouched++))
      continue
    fi

    if aerospace move-node-to-workspace "$target_ws" --window-id "$cur_id" 2>>"$LOGFILE"; then
      dlog "  MOVED: id=$cur_id → '$target_ws' (had '$cur_ws') bundle='${cur_bundle:-}' app='${cur_app:-}' title='${cur_title:-}'"
      ((moved++))
    else
      dlog "  ERROR: id=$cur_id to '$target_ws' (from '$cur_ws')"
      ((errored++))
    fi

  done

  local msg="Restored $target_mode: moved=$moved, untouched=$untouched, skipped=$skipped, errored=$errored."
  log "$msg"
  echo "$msg See $LOGFILE for details."

  # Re-enable -e for the rest of the script
  set -e
}

print_help() {
  cat >&2 <<EOF
Usage: $(basename "$0") [-d|--debug] [--mode main|desktop] save|restore

--mode sets the target mode (where to map & move windows to).
If omitted, target mode is inferred from: \$(aerospace list-modes --current)

Examples:
  $(basename "$0") save
  $(basename "$0") restore
  $(basename "$0") --mode desktop save  # save a desktop layout even if you're on main
  $(basename "$0") --mode main restore  # apply a main layout (mapping as needed)
EOF
}

# --- CLI parsing ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--debug) DEBUG=1; shift ;;
    -m|--mode)  MODE_OVERRIDE="${2:-}"; shift 2 ;;
    --mode=*)   MODE_OVERRIDE="${1#*=}"; shift ;;
    -h|--help)  print_help; exit 0 ;;
    save|restore) break ;;
    *) echo "Unknown option: $1" >&2; print_help; exit 2 ;;
  esac
done

if [[ -n "${MODE_OVERRIDE:-}" ]]; then
  [[ "$MODE_OVERRIDE" == "main" || "$MODE_OVERRIDE" == "desktop" ]] \
    || die "Invalid --mode '$MODE_OVERRIDE' (must be main|desktop)"
  target_mode="$MODE_OVERRIDE"
fi

cmd="${1:-}"
case "$cmd" in
  save)    save_layout ;;
  restore) restore_layout ;;
  ""|-h|--help) print_help; [[ -n "$cmd" ]] || exit 2 ;;
  *) echo "Unknown command: $cmd" >&2; print_help; exit 2 ;;
esac
