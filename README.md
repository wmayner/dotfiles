# dotfiles

This is my OSX environment. Check out the `linux` branch for the Linux version.


## Install

Clone and run the install script:
```sh
cd ~
git clone https://github.com/wmayner/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```
This will
- Install Homebrew if on macOS and brews various formulae
- Change default shell to zsh
- Install Oh My Zsh
- Install various Python packages
- Symlink all `*.symlink` files into `$HOME` as dotfiles


## Personalize

- `git/gitconfig.symlink`: commit as yourself instead of me
- `zsh/zshrc.symlink`: set up your own path variables, aliases, etc
