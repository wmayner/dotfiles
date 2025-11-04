#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New iTerm Window
# @raycast.mode compact

# Optional parameters:
# @raycast.icon /Applications/iTerm.app/Contents/Resources/AppIcon-Beta.icns
# @raycast.packageName iTerm

# Documentation:
# @raycast.author wmayner

osascript -e 'tell application "iTerm2" to create window with default profile'
