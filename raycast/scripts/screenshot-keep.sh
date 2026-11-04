#!/bin/zsh

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Screenshot: Keep and Copy
# @raycast.mode silent
# @raycast.packageName Utilities

# Optional parameters:
# @raycast.icon 📌

# Documentation:
# @raycast.description Select part of the screen. The screenshot is saved to Screenshots in Google Drive, where it is kept, and copied to the clipboard.

# Match the account folder by pattern so no address is written here.
drives=( "$HOME"/Library/CloudStorage/GoogleDrive-*/"My Drive"(N/) )
if (( ${#drives} == 0 )); then
  echo "Google Drive folder not found"
  exit 1
fi

exec "${0:A:h}/screenshot-save-and-copy.sh" "${drives[1]}/Screenshots"
