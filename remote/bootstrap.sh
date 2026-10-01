#!/usr/bin/env bash
#
# Set up a fresh Linux GPU box (RunPod, Vast, ...). Safe to run more than once.
#
# From the Mac, `rboot <ssh args>` (defined in zshrc) pipes this over ssh along
# with HF_TOKEN and WANDB_API_KEY. On the box itself:
#   curl -fsSL https://raw.githubusercontent.com/wmayner/dotfiles/main/remote/bootstrap.sh | bash

RAW=https://raw.githubusercontent.com/wmayner/dotfiles/main

# Model and package caches go on the big volume when there is one, so downloads
# do not fill the container disk.
if [ -d /workspace ] && [ -w /workspace ]; then BIG=/workspace; else BIG=$HOME; fi

if command -v apt-get >/dev/null 2>&1; then
  SUDO=''; [ "$(id -u)" -eq 0 ] || SUDO=sudo
  $SUDO apt-get update -qq
  # One at a time: nvtop is missing from some images and should not block the rest.
  for pkg in tmux git-lfs btop nvtop curl; do
    $SUDO apt-get install -y -qq "$pkg" >/dev/null || echo "bootstrap: could not install $pkg" >&2
  done
fi

command -v uv >/dev/null 2>&1 || [ -x "$HOME/.local/bin/uv" ] ||
  curl -LsSf https://astral.sh/uv/install.sh | sh

curl -fsSL "$RAW/tmux/tmux.conf.symlink" -o "$HOME/.tmux.conf" ||
  echo "bootstrap: could not fetch tmux config" >&2

git config --global user.name "Will Mayner"
git config --global user.email "wmayner@gmail.com"
git config --global init.defaultBranch main
git config --global pull.ff only
command -v git-lfs >/dev/null 2>&1 && git lfs install --skip-repo >/dev/null

# Shell environment, written to its own file so a rerun replaces it instead of
# appending a second copy to .bashrc.
ENV_FILE=$HOME/.bootstrap_env
cat >"$ENV_FILE" <<EOF
export PATH="\$HOME/.local/bin:\$PATH"
export HF_HOME=$BIG/.cache/huggingface
export TORCH_HOME=$BIG/.cache/torch
export UV_CACHE_DIR=$BIG/.cache/uv
alias gst='git status'
alias l='ls -lAh'
alias gpu='watch -n1 nvidia-smi'
alias ta='tmux new -A -s main'
EOF
for k in HF_TOKEN WANDB_API_KEY; do
  [ -n "${!k}" ] && printf 'export %s=%q\n' "$k" "${!k}" >>"$ENV_FILE"
done
chmod 600 "$ENV_FILE"
grep -qF '.bootstrap_env' "$HOME/.bashrc" 2>/dev/null ||
  echo '[ -f ~/.bootstrap_env ] && . ~/.bootstrap_env' >>"$HOME/.bashrc"

echo "bootstrap: done (caches under $BIG/.cache). Open a new shell or: . ~/.bootstrap_env"
