#!/usr/bin/env sh
#
# - Install homebrew if on macOS and brews various formulae
# - Install oh-my-zsh
# - Symlink all *.symlink files into $HOME as dotfiles

# Are we on macOS or Linux?
OS=$(uname -s)

if [ "$OS" == "Darwin" ]; then
  echo "Installing Homebrew..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  BREW_FORUMLAE='./brew/formulae.txt'
  echo "Installing brew formulae from '$BREW_FORUMLAE'..."
  xargs brew install < $BREW_FORUMLAE
fi

echo "\nInstalling oh-my-zsh...\n"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
echo ''

# Symlink dotfiles
for SOURCE_FILE in $(find $(pwd) -name '*.symlink'); do
  LINK_FILE="$HOME/.$(basename ${SOURCE_FILE%.symlink})"
  echo "Symlinking $LINK_FILE -> $SOURCE_FILE";
  ln -s "$SOURCE_FILE" $LINK_FILE;
done

echo "\nDone!"
