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
- Symlink VSCode settings and keybindings

## VSCode Setup

If you already have VSCode installed and want to link your configs to this dotfiles repo:

```sh
cd ~/dotfiles
./vscode/link-configs.sh
```

This will:
- Detect your VSCode User directory (macOS or Linux)
- Backup any existing configs
- Symlink `settings.json` and `keybindings.json` from dotfiles
- Your VSCode will then stay in sync with your dotfiles

## Personalize

- `git/gitconfig.symlink`: commit as yourself instead of me
- `zsh/zshrc.symlink`: set up your own path variables, aliases, etc
