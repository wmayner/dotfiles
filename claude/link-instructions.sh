#!/bin/sh
# Install the global Claude Code instructions: the public CLAUDE.md from dotfiles, plus this
# machine's rules in ~/.claude/rules/, which Claude Code loads alongside it in every project.
# Mac: the rules are private, read from the 1Password secure note "Claude rules (Mac)".
# Linux (the MATS cluster): remote/claude-rules.md.
set -e
DOTFILES=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$HOME/.claude/rules"
f="$HOME/.claude/CLAUDE.md"
if [ -f "$f" ] && [ ! -L "$f" ]; then
  mv "$f" "$f.pre-dotfiles" && echo "kept the old file as $f.pre-dotfiles; diff it against $DOTFILES/claude/CLAUDE.md"
fi
ln -sfn "$DOTFILES/claude/CLAUDE.md" "$f"
if [ "$(uname)" = Darwin ]; then
  if command -v op >/dev/null && note=$(op item get "Claude rules (Mac)" --fields notesPlain --format json | jq -r .value) && [ -n "$note" ]; then
    (umask 077 && printf '%s\n' "$note" > "$HOME/.claude/rules/mac.md") && echo "wrote ~/.claude/rules/mac.md from 1Password"
  else
    echo "could not read the 1Password note 'Claude rules (Mac)'; ~/.claude/rules/mac.md not written" >&2
  fi
else
  ln -sfn "$DOTFILES/remote/claude-rules.md" "$HOME/.claude/rules/cluster.md"
fi
