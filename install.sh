#!/usr/bin/env bash
#
# This script will
# - Download and install Homebrew on macOS, and brew various formulae
# - Install system packages on Linux
# - Change default shell to zsh
# - Download and install Oh My Zsh
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

printf "\nInstalling oh-my-zsh...\n"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

printf "\nSymlinking '*.symlink' files...\n"
for SOURCE_FILE in $(find $(pwd) -name '*.symlink'); do
  LINK_FILE="$HOME/.$(basename ${SOURCE_FILE%.symlink})"
  ln -sv "$SOURCE_FILE" $LINK_FILE;
done

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

printf "\nDone!"
