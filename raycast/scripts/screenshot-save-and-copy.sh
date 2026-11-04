#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Screenshot: Save and Copy
# @raycast.mode silent
# @raycast.packageName Utilities

# Optional parameters:
# @raycast.icon 📸

# Documentation:
# @raycast.description Select part of the screen (Space for a window, Esc to cancel). The screenshot is saved to the screenshot folder and copied to the clipboard.

# Use the configured screenshot folder, falling back to the Desktop.
dir=$(defaults read com.apple.screencapture location 2>/dev/null)
dir=${dir/#\~/$HOME}
[[ -d "$dir" ]] || dir="$HOME/Desktop"

# Name it the way macOS does ("Screenshot 2026-11-03 at 1.05.09 PM.png", with
# a narrow no-break space before AM/PM), so it sorts with the others and
# Copy Last Screenshot finds it.
hour=$(/bin/date +%I)
base="Screenshot $(/bin/date +%Y-%m-%d) at ${hour#0}.$(/bin/date +%M.%S)"$' '"$(/bin/date +%p)"
file="$dir/$base.png"
n=2
while [[ -e "$file" ]]; do file="$dir/$base ($n).png"; (( n++ )); done

/usr/sbin/screencapture -i -t png "$file"

# Esc cancels the selection and leaves no file.
[[ -s "$file" ]] || exit 0

osascript \
  -e 'on run argv' \
  -e 'set the clipboard to (read (POSIX file (item 1 of argv)) as «class PNGf»)' \
  -e 'end run' \
  "$file" >/dev/null || { echo "Saved, but copying failed"; exit 1; }

echo "Saved and copied"
