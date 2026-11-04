#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Screenshot: Save and Copy
# @raycast.mode silent
# @raycast.packageName Utilities

# Optional parameters:
# @raycast.icon 📸

# Documentation:
# @raycast.description Select part of the screen (Space for a window, Esc to cancel). The screenshot is saved to the screenshot folder and copied to the clipboard. Screenshots there are moved to the Trash after 30 days.

# Usage: screenshot-save-and-copy.sh [folder]
# With no folder, saves to the everyday screenshot folder and cleans it up.
# screenshot-keep.sh passes a folder for screenshots worth keeping.

cleanup_after_days=30

# The configured screenshot folder, falling back to the Desktop.
everyday=$(defaults read com.apple.screencapture location 2>/dev/null)
everyday=${everyday/#\~/$HOME}
[[ -d "$everyday" ]] || everyday="$HOME/Desktop"

dir=${1:-$everyday}
mkdir -p "$dir" || { echo "Can't create $dir"; exit 1; }

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

# Move old everyday screenshots to the Trash, in the background. Only files
# still named "Screenshot …" at the top of the folder count, so renaming one
# or moving it into a subfolder keeps it.
if [[ -z "$1" ]]; then
  {
    /usr/bin/find "$everyday" -maxdepth 1 -type f -name 'Screenshot *' \
      -mtime +"$cleanup_after_days" -print0 |
      /usr/bin/xargs -0 -r /usr/bin/trash
  } >/dev/null 2>&1 &!
fi

echo "Saved and copied"
