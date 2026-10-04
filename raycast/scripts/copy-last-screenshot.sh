#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Copy Last Screenshot
# @raycast.mode silent
# @raycast.packageName Utilities

# Optional parameters:
# @raycast.icon 📸

# Documentation:
# @raycast.description Copies the most recent screenshot to the clipboard as an image.

# Use the configured screenshot folder, falling back to the Desktop.
dir=$(defaults read com.apple.screencapture location 2>/dev/null)
dir=${dir/#\~/$HOME}
[[ -d "$dir" ]] || dir="$HOME/Desktop"

# Newest regular file named "Screenshot …" / "Screen Shot …".
# (.Nom[1]) = plain files, no error if none, sorted by mtime, take the first.
latest=( "$dir"/Screen*(.Nom[1]) )

if (( ${#latest} == 0 )); then
  echo "No screenshots found in $dir"
  exit 1
fi

file=${latest[1]}

case "${file:e:l}" in
  png)       class='«class PNGf»' ;;
  jpg|jpeg)  class='JPEG picture' ;;
  tif|tiff)  class='TIFF picture' ;;
  gif)       class='GIF picture' ;;
  *)         class='' ;;
esac

if [[ -n "$class" ]]; then
  expr="read (POSIX file (item 1 of argv)) as $class"
else
  # Unknown format (e.g. HEIC): copy as a file reference instead.
  expr="POSIX file (item 1 of argv)"
fi

osascript \
  -e 'on run argv' \
  -e "set the clipboard to ($expr)" \
  -e 'end run' \
  "$file" >/dev/null || { echo "Failed to copy screenshot"; exit 1; }

echo "Copied ${file:t}"
