#!/usr/bin/env bash
# cycle-app-windows-in-workspace.sh next|prev
# Works for both unified (NUM[L|C|R]) and numeric-only (NUM) workspaces.
set -euo pipefail

DIR="${1:-next}"  # next|prev

# --- Focused window (for WIN_ID + APP_NAME) ---
FOCUS_JSON="$(aerospace list-windows --focused --json || echo '[]')"
WIN_ID="$(jq -r 'if type=="array" and length>0 then .[0]["window-id"] else "" end' <<<"$FOCUS_JSON")"
APP_NAME="$(jq -r 'if type=="array" and length>0 then .[0]["app-name"]   else "" end' <<<"$FOCUS_JSON")"
[[ -n "$WIN_ID" && -n "$APP_NAME" ]] || exit 0

# --- Focused workspace name ---
CUR_WS="$(aerospace list-workspaces --focused)"
[[ -n "$CUR_WS" ]] || exit 0

# Parse number and optional suffix
NUM="${CUR_WS%[LCR]}"    # strip trailing L/C/R if present; otherwise returns CUR_WS unchanged
SUF="${CUR_WS:${#NUM}}"  # suffix is the leftover ("" or "L"/"C"/"R")

# Collect candidate windows
if [[ "$SUF" =~ ^[LCR]$ ]]; then
  # Unified mode: gather from NUM{L,C,R}
  LJSON="$(aerospace list-windows --workspace "${NUM}L" --json 2>/dev/null || echo '[]')"
  CJSON="$(aerospace list-windows --workspace "${NUM}C" --json 2>/dev/null || echo '[]')"
  RJSON="$(aerospace list-windows --workspace "${NUM}R" --json 2>/dev/null || echo '[]')"

  MERGED_JSON="$(printf '%s\n%s\n%s\n' "$LJSON" "$CJSON" "$RJSON")"
else
  # Numeric-only mode: gather from NUM only
  ONEJSON="$(aerospace list-windows --workspace "${NUM}" --json 2>/dev/null || echo '[]')"
  MERGED_JSON="$ONEJSON"
fi

# Compute next/prev target among windows of the same app
TGT_ID="$(
  printf '%s' "$MERGED_JSON" \
  | jq -rs --arg app "$APP_NAME" --arg id "$WIN_ID" --arg dir "$DIR" '
      # Slurp arrays, flatten, keep objects of this app, collect numeric ids
      [ .[] | select(type=="array") | .[] | select(type=="object")
        | select(."app-name" == $app) | ."window-id" | tonumber
      ] as $ids
      | ($ids | unique | sort) as $uniq
      | ($uniq | length) as $n
      | if $n < 2 then empty else
          ($uniq | index(($id | tonumber))) as $i
          | if $i == null then empty else
              (if $dir == "prev" then ($i - 1 + $n) % $n else ($i + 1) % $n end) as $t
              | ($uniq[$t] | tostring)
            end
        end
    '
)"
[[ -n "$TGT_ID" ]] || exit 0

aerospace focus --window-id "$TGT_ID"
