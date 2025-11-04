#!/usr/local/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title AeroSpace: Switch Mode
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🖥
# @raycast.needsConfirmation true

# Documentation:
# @raycast.description Save layout, switch mode, and restore
# @raycast.author W

CUR_MODE=$(aerospace list-modes --current)

echo "Current mode: $CUR_MODE"

if [[ "$CUR_MODE" == "desktop" ]]; then
  /Users/will/dotfiles/aerospace/scripts/switch-modes.sh main
else
  /Users/will/dotfiles/aerospace/scripts/switch-modes.sh desktop
fi
