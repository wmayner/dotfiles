# dotfiles

My shell. :sparkles:

## Install

Clone and run the install script:
```sh
cd ~
git clone https://github.com/wmayner/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```
This will
- Download and install Homebrew on macOS, and brew various formulae
- Install system packages and Neovim on Linux
- Change default shell to zsh
- Download and install Oh My Zsh
- Install various Python packages
- Make virtualenvironments `neovim-python2` and `neovim-python3` and run
  `pip install neovim` in each
- Symlink all `*.symlink` files into $HOME as dotfiles
- Symlink IPython profile
- Download and install vim-plug
- Symlink Neovim configuration directory to Vim configuration directory
- Install Vim plugins

## Personalize

- `git/gitconfig.symlink`: commit as yourself instead of me
- `zsh/zshrc.symlink`: set up your own path variables, aliases, etc
