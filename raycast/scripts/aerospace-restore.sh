#!/usr/local/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title AeroSpace: Restore
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🖥

# Documentation:
# @raycast.description Restore layout for current mode
# @raycast.author W

set -euo pipefail

/Users/will/dotfiles/aerospace/scripts/aerospace-save-restore.sh restore
