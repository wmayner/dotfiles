#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Last Downloaded
# @raycast.mode silent
# @raycast.packageName Navigation

# Optional parameters:
# @raycast.icon 📥

# Documentation:
# @raycast.description Opens the most recently modified item in Downloads

# Newest first by modification time, skipping downloads still in progress
latest=$(/bin/ls -t ~/Downloads | grep -v -E '\.(crdownload|download|part)$' | head -n 1)

if [ -z "$latest" ]; then
  echo "Nothing in Downloads"
  exit 1
fi

open ~/Downloads/"$latest"
echo "Opened $latest"
