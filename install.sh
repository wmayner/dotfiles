#!/usr/bin/env bash
#
# This script will
# - Download and install Homebrew on macOS, and brew various formulae
# - Install system packages on Linux
# - Change default shell to zsh
# - Symlink all `*.symlink` files into $HOME as dotfiles
# - Download & install vim-plug and then install plugins

# Are we on macOS or Linux?
OS=$(uname -s)
DOTFILES=$(pwd)

# macOS-specific
if [ "$OS" = "Darwin" ]; then
  # Install homebrew
  printf "\nInstalling Homebrew...\n"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Install brew formulae and casks from Brewfile
  printf "\nInstalling Homebrew packages from Brewfile...\n"
  brew bundle install --file=./brew/Brewfile
# Linux specific
else
  # System packages
  printf "\nInstalling system packages...\n"
  LINUX_PACKAGES='./linux/packages.txt'
  xargs sudo apt-get install <$LINUX_PACKAGES
fi

printf "\nChanging shell to zsh...\n"
# NOTE: You may have to run the following:
#   sudo printf $(which zsh) >> /etc/shells`
chsh -s $(which zsh)

printf "\nSymlinking '*.symlink' files...\n"
for SOURCE_FILE in $(find $(pwd) -name '*.symlink'); do
  LINK_FILE="$HOME/.$(basename ${SOURCE_FILE%.symlink})"
  ln -sv "$SOURCE_FILE" $LINK_FILE;
done
# Mac-only git settings (1Password signing, SSH for GitHub), included by gitconfig.
[ "$(uname)" = Darwin ] && ln -sv "$(pwd)/git/gitconfig.mac" "$HOME/.gitconfig.local"
# Nightly rebuild of claude-history's semantic search index.
if [ "$(uname)" = Darwin ]; then
  ln -sfn "$(pwd)/macos/com.wmayner.claude-history-cache.plist" "$HOME/Library/LaunchAgents/"
  launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.wmayner.claude-history-cache.plist" 2>/dev/null
fi

printf "\nSetting up Vim...\n"
# Install vim-plug
mkdir -p "$HOME/.vim/autoload"
curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# Install plugins
vim +PlugInstall! +qall

printf "\nSetting up VSCode...\n"
# Determine VSCode User directory based on OS
if [ "$OS" = "Darwin" ]; then
  VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
else
  VSCODE_USER_DIR="$HOME/.config/Code/User"
fi

# Create VSCode User directory if it doesn't exist
mkdir -p "$VSCODE_USER_DIR"

# Backup existing configs if they exist and aren't symlinks
if [ -f "$VSCODE_USER_DIR/settings.json" ] && [ ! -L "$VSCODE_USER_DIR/settings.json" ]; then
  printf "Backing up existing settings.json to settings.json.backup\n"
  mv "$VSCODE_USER_DIR/settings.json" "$VSCODE_USER_DIR/settings.json.backup"
fi
if [ -f "$VSCODE_USER_DIR/keybindings.json" ] && [ ! -L "$VSCODE_USER_DIR/keybindings.json" ]; then
  printf "Backing up existing keybindings.json to keybindings.json.backup\n"
  mv "$VSCODE_USER_DIR/keybindings.json" "$VSCODE_USER_DIR/keybindings.json.backup"
fi

# Symlink VSCode configs
ln -sfv "$DOTFILES/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
ln -sfv "$DOTFILES/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"

printf "\nSetting up Claude Code...\n"
mkdir -p "$HOME/.claude/skills"
# Each folder in claude/ is a mod, loaded from the skills folder
for MOD in "$DOTFILES"/claude/*/; do
  ln -sfnv "${MOD%/}" "$HOME/.claude/skills/$(basename "$MOD")"
done
ln -sfv "$DOTFILES/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
# settings.json itself is not tracked: it holds machine-specific permission
# rules and plugin lists. settings.base.json holds the shareable part, and is
# merged in underneath whatever the machine already has.
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
[ -f "$CLAUDE_SETTINGS" ] || echo '{}' > "$CLAUDE_SETTINGS"
jq -s '.[0] * .[1]' "$DOTFILES/claude/settings.base.json" "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.new" \
  && mv "$CLAUDE_SETTINGS.new" "$CLAUDE_SETTINGS"

printf "\nDone!"
