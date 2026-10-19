#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Send Clipboard Image to Remote
# @raycast.mode silent
# @raycast.packageName Utilities

# Optional parameters:
# @raycast.icon 🖼️
# @raycast.argument1 { "type": "text", "placeholder": "host (mats)", "optional": true }

# Documentation:
# @raycast.description Uploads the clipboard image to a remote host and replaces the clipboard with its remote path, so Claude Code over ssh can read it.

host=${1:-mats}
tmp="${TMPDIR:-/tmp}/clip-$$.png"
trap 'rm -f "$tmp"' EXIT

# shortcut: needs a PNG flavor on the clipboard (screenshots and browsers provide one); convert TIFF with sips if that ever fails.
osascript \
  -e 'on run argv' \
  -e 'set f to open for access (POSIX file (item 1 of argv)) with write permission' \
  -e 'write (the clipboard as «class PNGf») to f' \
  -e 'close access f' \
  -e 'end run' \
  "$tmp" >/dev/null 2>&1 || { echo "No image on the clipboard"; exit 1; }

name=$(date +%Y%m%d-%H%M%S).png
remote=$(ssh "$host" "mkdir -p ~/.cache/clip && f=~/.cache/clip/$name && cat > \$f && echo \$f" < "$tmp") \
  || { echo "Upload to $host failed"; exit 1; }

printf %s "$remote" | pbcopy
echo "Copied $remote"
