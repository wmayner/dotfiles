#!/usr/bin/env sh
#
# Remove any dotfiles that are symlinks to '*.symlink' files in this
# directory.

for SOURCE_FILE in $(find $(pwd) -name '*.symlink'); do
  LINK_FILE="$HOME/.$(basename ${SOURCE_FILE%.symlink})"
  if [ "$(readlink $LINK_FILE)" == "$SOURCE_FILE" ]; then
    echo "Removing symlink $LINK_FILE -> $SOURCE_FILE"
    rm $LINK_FILE
  fi
done
