#!/usr/bin/env bash
#
# Set up a shared Linux machine where there is no root (the MATS cluster's dev
# node and controller): command-line tools from conda-forge via pixi, zsh started
# from .bashrc, the dotfiles symlinked, uv and Claude Code installed. Safe to run
# more than once. bootstrap.sh is the version for root boxes (RunPod, Vast).
#
#   curl -fsSL https://raw.githubusercontent.com/wmayner/dotfiles/main/remote/bootstrap-noroot.sh | bash
#
# Afterwards, log in to Claude Code once by running `claude`.
set -uo pipefail

DOTFILES=$HOME/dotfiles
export PATH=$HOME/.pixi/bin:$HOME/.local/bin:$PATH
say() { echo "bootstrap: $*" >&2; }

if [ -d "$DOTFILES/.git" ]; then
  git -C "$DOTFILES" pull -q --ff-only || say "could not update $DOTFILES"
else
  git clone -q https://github.com/wmayner/dotfiles.git "$DOTFILES"
fi

command -v pixi >/dev/null || curl -fsSL https://pixi.sh/install.sh | PIXI_NO_PATH_UPDATE=1 bash
# One at a time, so a package missing from conda-forge does not block the rest.
for pkg in zsh starship fzf ripgrep fd-find bat eza atuin zoxide direnv jq nvim colordiff; do
  pixi global install -q "$pkg" >/dev/null || say "could not install $pkg"
done

# Not on conda-forge.
HSS=$HOME/.local/share/zsh-history-substring-search
[ -d "$HSS" ] || git clone -q --depth 1 https://github.com/zsh-users/zsh-history-substring-search "$HSS"

command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

link() { mkdir -p "$(dirname "$2")"; ln -sfn "$1" "$2"; }
link "$DOTFILES/zsh/zshrc.symlink" "$HOME/.zshrc"
link "$DOTFILES/tmux/tmux.conf.symlink" "$HOME/.tmux.conf"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
# Claude Code mods, linked into skills/ as on the Mac.
for mod in "$DOTFILES"/claude/*/; do
  link "${mod%/}" "$HOME/.claude/skills/$(basename "$mod")"
done
# MATS ships a skill for its Slurm cluster.
[ -d /mnt/nw/share/skills/mats-cluster ] &&
  link /mnt/nw/share/skills/mats-cluster "$HOME/.claude/skills/mats-cluster"

# The dotfiles gitconfig signs commits through the 1Password app, which is
# Mac-only, so set the parts that matter here directly.
git config --global user.name "Will Mayner"
git config --global user.email "wmayner@gmail.com"
git config --global init.defaultBranch main
git config --global pull.ff only
git config --global core.excludesfile "$DOTFILES/git/gitignore.symlink"

# Claude settings: the shareable base plus the remote overlay (Remote Control,
# permission rules, plugins). Settings already on this machine win, so changes
# made here with /config survive a rerun.
SETTINGS=$HOME/.claude/settings.json
[ -f "$SETTINGS" ] || echo '{}' >"$SETTINGS"
jq -s '.[0] * .[1] * .[2]' "$DOTFILES/claude/settings.base.json" \
  "$DOTFILES/claude/settings.remote.json" "$SETTINGS" >"$SETTINGS.new" &&
  mv "$SETTINGS.new" "$SETTINGS"

# The login shell cannot be changed without root, so interactive bash hands
# over to zsh. If zsh ever breaks, `ssh -t host bash --norc` gets a plain bash.
MARK='# dotfiles: start zsh'
grep -qF "$MARK" "$HOME/.bashrc" 2>/dev/null || cat >>"$HOME/.bashrc" <<EOF

$MARK
if [[ \$- == *i* ]] && [ -x "\$HOME/.pixi/bin/zsh" ]; then
  export SHELL="\$HOME/.pixi/bin/zsh"; exec "\$SHELL" -l
fi
EOF

say "done. Log in again (or run: exec ~/.pixi/bin/zsh -l), then run claude once to log in."
