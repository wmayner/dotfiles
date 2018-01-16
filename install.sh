#!/usr/bin/env bash
#
# This script will
# - Download and install Homebrew on macOS, and brew various formulae
# - Install system packages and Neovim on Linux
# - Change default shell to zsh
# - Download and install Oh My Zsh
# - Install various Python packages
# - Make virtualenvironments `neovim-python2` and `neovim-python3` and run
#   `pip install neovim` in each
# - Install global node packages
# - Symlink all `*.symlink` files into $HOME as dotfiles
# - Symlink IPython profile
# - Download and install vim-plug
# - Symlink Neovim configuration directory to Vim configuration directory
# - Install Vim plugins

NEOVIM_INSTALL_PREFIX="$HOME/neovim"

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
  # Neovim
  command -v nvim >/dev/null || {
    printf "\nInstalling Neovim...\n" &&
    git clone https://github.com/neovim/neovim.git "$HOME/neovim-src" &&
    cd "$HOME/neovim-src" &&
    make CMAKE_EXTRA_FLAGS="-DCMAKE_INSTALL_PREFIX=$NEOVIM_INSTALL_PREFIX" &&
    make install &&
    cd "$DOTFILES" &&
    rm -rf "$HOME/neovim-src"
  }
fi

printf "\nChanging shell to zsh...\n"
# NOTE: You may have to run the following:
#   sudo printf $(which zsh) >> /etc/shells`
chsh -s $(which zsh)

printf "\nInstalling oh-my-zsh...\n"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

printf "\nInstalling Python packages...\n"
PYTHON_REQUIREMENTS_FILE='./python/requirements.txt'
pip2 install --user --upgrade -r $PYTHON_REQUIREMENTS_FILE
pip3 install --user --upgrade -r $PYTHON_REQUIREMENTS_FILE

printf "\nMaking Neovim virtualenvs...\n"
NEOVIM_REQUIREMENTS="./vim/neovim_requirements.txt"
source $(which virtualenvwrapper.sh)
# Python 2
mkvirtualenv -p $(which python2) neovim-python2 &&
source "$HOME/.virtualenvs/neovim-python2/bin/activate"
pip install --upgrade -r $NEOVIM_REQUIREMENTS
deactivate
# Python 3
mkvirtualenv -p $(which python3) neovim-python3
source "$HOME/.virtualenvs/neovim-python3/bin/activate"
pip install --upgrade -r $NEOVIM_REQUIREMENTS
deactivate

printf "\nInstalling Node packages...\n"
NODE_PACKAGES_FILE="./node/global_packages.txt"
xargs npm install --global <$NODE_PACKAGES_FILE

printf "\nSymlinking '*.symlink' files...\n"
for SOURCE_FILE in $(find $(pwd) -name '*.symlink'); do
  LINK_FILE="$HOME/.$(basename ${SOURCE_FILE%.symlink})"
  ln -sv "$SOURCE_FILE" $LINK_FILE;
done

printf "\nSymlinking IPython profile...\n"
mkdir -p "$HOME/.ipython/profile_default"
ln -sv "$(pwd)/ipython/ipython_config.py" "$HOME/.ipython/profile_default/ipython_config.py"

printf "\nSetting up Vim and Neovim...\n"
# Neovim
ln -sv "$HOME/.vim" "$HOME/.config/nvim"
ln -sv $(find $(pwd) -name "vimrc.symlink") "$HOME/.config/nvim/init.vim"
# Install vim-plug
mkdir -p "$HOME/.vim/autoload"
curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# Mapping overrides
mkdir -p "$HOME/.vim/after/plugin"
echo "call VimrcMappings()" >> "$HOME/.vim/after/plugin/overrides.vim"
# Install plugins
vim +PlugInstall! +qall

printf "\nDone!"
