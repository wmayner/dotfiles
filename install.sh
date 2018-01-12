#!/bin/sh

echo "Installing oh-my-zsh...\n"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "\nDone!"

# Symlink all `*.symlink` files into $HOME as dotfiles
echo "\nSymlinking *.symlink files...\n"
for SOURCE_FILE in $DOTFILES/**/*.symlink;
do
  LINK_FILE="$HOME/.$(basename ${SOURCE_FILE%.symlink})"
  echo "$LINK_FILE -> $SOURCE_FILE";
  ln -s "$SOURCE_FILE" $LINK_FILE;
done

echo "\nDone!"
