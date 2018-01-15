#!/usr/bin/env sh
#
# This script will
# - Download and install Homebrew on macOS, and brew various formulae
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

# Are we on macOS or Linux?
OS=$(uname -s)

# macOS-specific
if [ "$OS" = "Darwin" ]; then
  echo "\nInstalling Homebrew...\n"
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
  echo ''
fi

echo "\nChanging shell to zsh...\n"
# NOTE: You may have to run the following:
#   sudo echo $(which zsh) >> /etc/shells`
chsh -s $(which zsh)

echo "\nInstalling oh-my-zsh...\n"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "\nInstalling Python packages...\n"
PYTHON_REQUIREMENTS_FILE='./python/requirements.txt'
pip install --user --upgrade -r $PYTHON_REQUIREMENTS_FILE

echo "\nMaking Neovim virtualenvs...\n"
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

echo "\nInstalling Node packages...\n"
NODE_PACKAGES_FILE="./node/global_packages.txt"
xargs npm install --global < $NODE_PACKAGES_FILE

echo "\nSymlinking '*.symlink' files...\n"
for SOURCE_FILE in $(find $(pwd) -name '*.symlink'); do
  LINK_FILE="$HOME/.$(basename ${SOURCE_FILE%.symlink})"
  ln -sv "$SOURCE_FILE" $LINK_FILE;
done

echo "\nSymlinking IPython profile...\n"
mkdir -p "$HOME/.ipython/profile_default"
ln -sv "$(pwd)/ipython/ipython_config.py" "$HOME/.ipython/profile_default/ipython_config.py"

echo "\nSetting up Vim and Neovim...\n"
# Vim
mkdir -p "$HOME/.vim/autoload"
# Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# Neovim
mkdir -p "$HOME/.config/nvim/autoload"
ln -sv $(find . -name "vimrc.symlink") "$HOME/.config/nvim/init.vim"
ln -sv "$HOME/.vim" "$HOME/.config/nvim"
# Install plugins
vim +PlugInstall! +qall

echo "\nDone!"
