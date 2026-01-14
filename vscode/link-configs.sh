#!/usr/bin/env bash
#
# Link VSCode settings and keybindings to dotfiles
# Run this to sync your VSCode configs with your dotfiles

set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS=$(uname -s)

# Determine VSCode User directory based on OS
if [ "$OS" = "Darwin" ]; then
  VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
else
  VSCODE_USER_DIR="$HOME/.config/Code/User"
fi

printf "VSCode User directory: $VSCODE_USER_DIR\n"
printf "Dotfiles directory: $DOTFILES\n\n"

# Create VSCode User directory if it doesn't exist
mkdir -p "$VSCODE_USER_DIR"

# Check and backup existing configs
for file in settings.json keybindings.json; do
  target="$VSCODE_USER_DIR/$file"
  source="$DOTFILES/vscode/$file"

  if [ -L "$target" ]; then
    current_link=$(readlink "$target")
    if [ "$current_link" = "$source" ]; then
      printf "✓ $file already linked correctly\n"
      continue
    else
      printf "! $file is a symlink to a different location:\n"
      printf "  Current: $current_link\n"
      printf "  Expected: $source\n"
      read -p "Replace with dotfiles version? (y/n) " -n 1 -r
      printf "\n"
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$target"
      else
        printf "Skipping $file\n"
        continue
      fi
    fi
  elif [ -f "$target" ]; then
    printf "! Found existing $file (not a symlink)\n"
    read -p "Backup and replace with dotfiles version? (y/n) " -n 1 -r
    printf "\n"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      backup="$target.backup.$(date +%Y%m%d_%H%M%S)"
      mv "$target" "$backup"
      printf "  Backed up to: $backup\n"
    else
      printf "Skipping $file\n"
      continue
    fi
  fi

  # Create symlink
  ln -sv "$source" "$target"
  printf "✓ Linked $file\n\n"
done

printf "\nDone! VSCode will use configs from your dotfiles.\n"
printf "Restart VSCode for changes to take effect.\n"
