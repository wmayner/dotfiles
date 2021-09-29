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
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  BREW_FORMULAE='./brew/formulae.txt'
  BREW_FORMULAE_HEAD='./brew/formulae-head.txt'
  # Install brew formulae
  printf "Installing Homebrew formulae from '$BREW_FORMULAE' and '$BREW_FORMULAE_HEAD'..."
  xargs brew install <$BREW_FORMULAE
  xargs brew install --HEAD <$BREW_FORMULAE_HEAD
  # Ensure brewed Python is used instead of the system Python
  if [ ! -e "/usr/local/bin/python" ]; then
    ln -s "/usr/local/bin/python2" "/usr/local/bin/python"
  fi
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
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

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

printf "\nDone!"
