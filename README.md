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
- Download and install Homebrew on macOS, and install everything in `brew/Brewfile`
- Install system packages on Linux
- Change default shell to zsh
- Symlink all `*.symlink` files into $HOME as dotfiles
- Download and install vim-plug, then install Vim plugins
- Symlink VSCode settings and keybindings

The two Hammerspoon spoons are git submodules, so fetch them after cloning:
```sh
git submodule update --init
```

## Remote GPU boxes

`remote/bootstrap.sh` sets up a fresh Linux box (RunPod, Vast): it installs
tmux, git-lfs, btop, nvtop and uv, copies the tmux config, sets the git
identity, and puts the Hugging Face, torch and uv caches on `/workspace` when
that volume exists.

From the Mac, `rboot` runs it over ssh and passes `HF_TOKEN` and
`WANDB_API_KEY` along:
```sh
rboot -p 40022 root@1.2.3.4
```
Or on the box itself:
```sh
curl -fsSL https://raw.githubusercontent.com/wmayner/dotfiles/main/remote/bootstrap.sh | bash
```

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
