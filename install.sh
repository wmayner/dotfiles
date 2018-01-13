#!/usr/bin/env sh
#
# - Install Homebrew if on macOS and brews various formulae
# - Change default shell to zsh
# - Install oh-my-zsh
# - Install various Python packages
# - Symlink all *.symlink files into $HOME as dotfiles

# Are we on macOS or Linux?
OS=$(uname -s)

# Homebrew
if [ "$OS" == "Darwin" ]; then
  echo "Installing Homebrew..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  BREW_FORMULAE='./brew/formulae.txt'
  BREW_FORMULAE_HEAD='./brew/formulae-head.txt'
  echo "Installing Homebrew formulae from '$BREW_FORMULAE' and '$BREW_FORMULAE_HEAD'..."
  xargs brew install < $BREW_FORMULAE
  xargs brew install --HEAD < $BREW_FORMULAE_HEAD
  # Ensure brewed Python is used instead of the system Python
  if [ ! -e "/usr/local/bin/python" ]; then
    ln -s "/usr/local/bin/python2" "/usr/local/bin/python"
  fi
fi

# Change shell to zsh
#
# NOTE: You may have to run the following:
#   sudo echo $(which zsh) >> /etc/shells`
chsh -s $(which zsh)

# oh-my-zsh
echo "\nInstalling oh-my-zsh...\n"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
echo ''

# Python packages
PYTHON_REQUIREMENTS_FILE='./python/requirements.txt'
pip install --user -r $PYTHON_REQUIREMENTS_FILE
echo ''

# Symlink dotfiles
for SOURCE_FILE in $(find $(pwd) -name '*.symlink'); do
  LINK_FILE="$HOME/.$(basename ${SOURCE_FILE%.symlink})"
  echo "Symlinking $LINK_FILE -> $SOURCE_FILE";
  ln -s "$SOURCE_FILE" $LINK_FILE;
done

echo "\nDone!"
