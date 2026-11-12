#!/usr/bin/env bash
#
# Set up a shared Linux machine where there is no root (the MATS cluster's dev
# node and controller, the Tononi Lab server): command-line tools from conda-forge via pixi, zsh started
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
# git: the shared gitconfig needs a newer git than Ubuntu 22.04 ships (zdiff3).
for pkg in zsh starship fzf ripgrep fd-find bat eza atuin zoxide direnv jq nvim colordiff tmux nodejs git-delta git; do
  pixi global install -q "$pkg" >/dev/null || say "could not install $pkg"
done

# Not on conda-forge.
HSS=$HOME/.local/share/zsh-history-substring-search
[ -d "$HSS" ] || git clone -q --depth 1 https://github.com/zsh-users/zsh-history-substring-search "$HSS"

command -v uv >/dev/null || curl -LsSf https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
# The tmux status bar (tmux.conf runs it when present).
command -v powerline-daemon >/dev/null || uv tool install -q --python 3.13 powerline-status  # its daemon crashes on 3.14
command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash
# claude-history: search past Claude conversations. Its lib/ (ONNX runtime, for
# semantic search) has to stay next to the binary. Upgrade with `claude-history update`.
CH=$HOME/.local/share/claude-history
[ -x "$CH/claude-history" ] || { mkdir -p "$CH" &&
  curl -fsSL https://github.com/raine/claude-history/releases/latest/download/claude-history-linux-amd64.tar.gz | tar -xz -C "$CH" &&
  ln -sfn "$CH/claude-history" "$HOME/.local/bin/claude-history"; } || say "could not install claude-history"

link() { mkdir -p "$(dirname "$2")"; ln -sfn "$1" "$2"; }
link "$DOTFILES/zsh/zshrc.symlink" "$HOME/.zshrc"
link "$DOTFILES/tmux/tmux.conf.symlink" "$HOME/.tmux.conf"
link "$DOTFILES/starship/starship.toml" "$HOME/.config/starship.toml"
# Remote boxes only: the tmux status bar shows $MACHINE_NAME (set in zshrc)
# instead of the raw hostname.
link "$DOTFILES/powerline" "$HOME/.config/powerline"
link "$DOTFILES/remote/code" "$HOME/.local/bin/code"
# ctrl+v in Claude Code pastes the Mac's clipboard image (see bin/clip-forward)
link "$DOTFILES/remote/xclip" "$HOME/.local/bin/xclip"
# Claude Code: mods, status line and settings (with the remote overlay)
sh "$DOTFILES/claude/link.sh" || say "could not link the Claude config"
# Global instructions: the public CLAUDE.md
sh "$DOTFILES/claude/link-instructions.sh"
# The private dotfiles (this machine's Claude Code rules and shortcuts), where
# gh can read them; elsewhere the clone fails quietly and nothing else changes.
PRIVATE=$HOME/dotfiles-private
if [ -d "$PRIVATE/.git" ] || git -c credential.helper= -c 'credential.helper=!gh auth git-credential' \
    clone -q https://github.com/wmayner/dotfiles-private.git "$PRIVATE" 2>/dev/null; then
  sh "$PRIVATE/install.sh" || say "could not install the private dotfiles"
fi

# Same gitconfig as the Mac. Its Mac-only part (1Password signing, SSH for
# GitHub) lives in git/gitconfig.mac, which is not linked here.
link "$DOTFILES/git/gitconfig.symlink" "$HOME/.gitconfig"
link "$DOTFILES/git/gitignore.symlink" "$HOME/.gitignore"

# cron reads the machine's own clock (UTC on the MATS cluster, Chicago time on the
# Tononi Lab server), so convert the Pacific times below to "minute hour" on it.
at_pt() { date -d "TZ=\"America/Los_Angeles\" $1" +'%-M %-H'; }
# Nightly rebuild of claude-history's semantic search index at low priority,
# 03:30 Pacific. Rerunning replaces the entry.
CRON="$(at_pt 03:30)"' * * * nice -n 19 timeout 3600 $HOME/.local/bin/claude-history --generate-semantic-cache >>$HOME/.cache/claude-history/nightly.log 2>&1 # claude-history nightly'
{ crontab -l 2>/dev/null | grep -v '# claude-history nightly'; echo "$CRON"; } | crontab - || say "could not install the crontab entry"
# Daily bin/update at 04:00 Pacific, after the index rebuild. cron's PATH has
# only the system folders.
CRON="$(at_pt 04:00)"' * * * PATH=$HOME/.pixi/bin:$HOME/.local/bin:/usr/bin:/bin nice -n 19 timeout 3600 $HOME/dotfiles/bin/update </dev/null >>$HOME/.cache/update.log 2>&1 # dotfiles update daily'
{ crontab -l 2>/dev/null | grep -v '# dotfiles update daily'; echo "$CRON"; } | crontab - || say "could not install the update crontab entry"

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
