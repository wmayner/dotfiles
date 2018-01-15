#!/usr/bin/env bash

# Remove any dotfiles that are symlinks to '*.symlink' files in this
# directory
for SOURCE_FILE in $(find $(pwd) -name '*.symlink'); do
  LINK_FILE="$HOME/.$(basename ${SOURCE_FILE%.symlink})"
  if [ "$(readlink $LINK_FILE)" == "$SOURCE_FILE" ]; then
    echo "Removing symlink $LINK_FILE -> $SOURCE_FILE"
    rm $LINK_FILE
  fi
done

# Remove Neovim virtualenvs
source $(which virtualenvwrapper.sh)
rmvirtualenv neovim-python2
rmvirtualenv neovim-python3

# Remove Neovim config
mkdir -p "$HOME/.config/nvim/autoload"
LINK_FILE="$HOME/.config/nvim/init.vim"
SOURCE_FILE=$(find . -name "vimrc.symlink")
if [ "$(readlink $LINK_FILE)" == "$SOURCE_FILE" ]; then
  echo "Removing symlink $LINK_FILE -> $SOURCE_FILE"
  rm $LINK_FILE
fi
LINK_FILE="$HOME/.vim"
SOURCE_FILE="$HOME/.config/nvim"
if [ "$(readlink $LINK_FILE)" == "$SOURCE_FILE" ]; then
  echo "Removing symlink $LINK_FILE -> $SOURCE_FILE"
  rm $LINK_FILE
fi

# Remove IPython config
LINK_FILE="$HOME/.ipython/profile_default/ipython_config.py"
SOURCE_FILE="$(pwd)/ipython/ipython_config.py"
if [ "$(readlink $LINK_FILE)" == "$SOURCE_FILE" ]; then
  echo "Removing symlink $LINK_FILE -> $SOURCE_FILE"
  rm $LINK_FILE
fi
