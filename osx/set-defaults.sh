#!/bin/sh

# My version of https://raw.github.com/holman/dotfiles/master/osx/set-defaults.sh:

# Sets reasonable OS X defaults.
#
# Or, in other words, set shit how I like in OS X.
#
# The original idea (and a couple settings) were grabbed from:
#   https://github.com/mathiasbynens/dotfiles/blob/master/.osx
#
# Run ./set-defaults.sh and you'll be good to go.

# Disable press-and-hold for keys in favor of key repeat.
defaults write -g ApplePressAndHoldEnabled -bool false

# Use AirDrop over every interface. srsly this should be a default.
defaults write com.apple.NetworkBrowser BrowseAllInterfaces 1

# Fast key repeat. Both values count whole steps of 1/60 s (16.7 ms); macOS
# cuts fractions down, so 0.84 becomes 0. KeyRepeat 1 repeats 60 times a
# second (0 was too fast). InitialKeyRepeat is the delay before repeat starts;
# 12 (200 ms) is shorter than the shortest step on the System Settings slider,
# which is 15 (250 ms).
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 12

# Screenshots go to ~/Desktop/Screenshots as PNG, without the floating
# thumbnail (it holds the file back for a few seconds).
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location -string "~/Desktop/Screenshots"
defaults write com.apple.screencapture type -string png
defaults write com.apple.screencapture show-thumbnail -bool false

# Screenshot shortcuts. The macOS defaults use Cmd+Shift, which is left free
# for Raycast: Cmd+Shift+4 runs raycast/scripts/screenshot-save-and-copy.sh and
# Cmd+Shift+5 runs screenshot-keep.sh. Raycast stores its hotkeys itself, so
# record those two by hand in Raycast.
# Arguments: shortcut id, character code, key code, modifier flags
# (Shift 0x20000, Control 0x40000, Option 0x80000, Command 0x100000).
screenshot_hotkey() {
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$1" \
    "<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>$2</integer><integer>$3</integer><integer>$4</integer></array><key>type</key><string>standard</string></dict></dict>"
}
screenshot_hotkey 28 51 20 655360   # Option+Shift+3: save the screen
screenshot_hotkey 29 51 20 917504   # Ctrl+Option+Shift+3: copy the screen
screenshot_hotkey 30 52 21 655360   # Option+Shift+4: save a selection
screenshot_hotkey 31 52 21 917504   # Ctrl+Option+Shift+4: copy a selection
screenshot_hotkey 184 53 23 655360  # Option+Shift+5: screenshot toolbar
# Apply the shortcuts without logging out.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
