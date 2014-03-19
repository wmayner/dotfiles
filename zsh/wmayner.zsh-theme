# # wmayner.zsh-theme
# 
# Forked from [@agnoster's zsh theme](https://gist.github.com/agnoster/3712874).
# Incorporates changes from 
# [@smileart's fork](https://gist.github.com/smileart/3750104).
#
# ## Modifications in this fork: ##
# * The current path is right aligned, so it's out of the way
#   when working in deeply nested directories. The main,
#   left-aligned prompt only the current directory's name.
# * If you're working in a git repo with untracked files, the git portion of
#   the prompt will be white (a clean repo is still green, and a dirty repo with
#   no untracked files is still yellow).
#
# ## README ##
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://gist.github.com/1595572).
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](http://www.iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# ## Goals ##
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step furthjer: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

# ### Segment drawing ###
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'
END_FG='NONE'
SEGMENT_SEPARATOR=""

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    # Use END_FG if it's been set (for coloring last separator based on current
    # vi mode)
    if [[ $END_FG != 'NONE' ]]; then
      echo -n " %{%k%F{$END_FG}%}$SEGMENT_SEPARATOR"
    else
      echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
    fi
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

# ### Prompt components ###
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`
  # Only display user if not the default
  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)$user@%m"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    ZSH_THEME_GIT_PROMPT_DIRTY=' ±'
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ ! -z $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
      prompt_segment white black
    elif [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green black
    fi
    echo -n "${ref/refs\/heads\// }$dirty"
  fi
}

# Dir: current working directory
prompt_dir() {
  # Use just the name of the current directory (not the full path)
  prompt_segment blue black '%c'
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local symbols
  symbols=()
  [[ $RETVAL -ne 0 ]] && symbols+="%{%F{red}%}✘"
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

# ## Build the prompt ##
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_context
  prompt_dir
  prompt_git
  prompt_end
}

# Set the main prompt
PROMPT='%{%f%b%k%}$(build_prompt) '

# Put the full path of the current directory on the right
# (from kennethreitz.zsh-theme)
RPS1='%{$fg[blue]%}%~ %T%{$reset_color%}'

# ### Change end separator color depending on current vi mode ###
autoload -U colors
# This is called whenever $KEYMAP is changed
zle-keymap-select () {
  # If we're in vi command mode, make the last separator cyan
  if [[ $KEYMAP = vicmd ]]; then
    END_FG='cyan'
  # Otherwise don't do anything
  else
    END_FG='NONE'
  fi
  # Redraw the prompt once we've changed the color
  zle reset-prompt
}
# Replace default zle-keymap-select with ours
zle -N zle-keymap-select

zle-line-init () {
  zle -K viins
}
# Replace default zle-line-init with ours
zle -N zle-line-init

# Activate vi mod
bindkey -v

# Vim modeline:
# vim:ft=zsh ts=2 sw=2 sts=2
