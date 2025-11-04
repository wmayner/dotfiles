#!/usr/bin/env bash
# set-workspace.sh next|prev|[1-10]
# - MAIN (1 monitor): cycle numeric workspaces 1..10
# - DESKTOP (3 monitors): cycle unified sets {N}L/C/R
set -euo pipefail

DIR="${1:-next}" # next|prev or direct number 1-10

CUR_MODE="$(aerospace list-modes --current)"

CUR_WS="$(aerospace list-workspaces --focused)"
[[ -n "$CUR_WS" ]] || exit 0
NUM="${CUR_WS%[LCR]}"    # strip L/C/R if present
SUF="${CUR_WS:${#NUM}}"  # suffix is the leftover ("" or "L"/"C"/"R")

# Check if argument is a direct number (1-10)
if [[ "$DIR" =~ ^[0-9]+$ ]] && [[ "$DIR" -ge 1 ]] && [[ "$DIR" -le 10 ]]; then
  TNUM="$DIR"
# Otherwise compute target number (1..10 with wrap)
elif [[ "$DIR" == "prev" ]]; then
  if [[ "$NUM" -eq 1 ]]; then TNUM=10; else TNUM=$((NUM-1)); fi
else
  if [[ "$NUM" -eq 10 ]]; then TNUM=1; else TNUM=$((NUM+1)); fi
fi

if [[ "$CUR_MODE" == "desktop" ]]; then
  # Desktop mode: switch all three to the unified workspace in parallel,
  # but ensure ${TNUM}$SUF is always the last one called
  for suf in L C R; do
    if [[ "$suf" != "$SUF" ]]; then
      aerospace workspace "${TNUM}${suf}"
    fi
  done
  aerospace workspace "${TNUM}${SUF}"
else
  # Main mode: just switch to the numeric workspace
  aerospace workspace "${TNUM}"
fi
