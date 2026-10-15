#!/bin/sh
# Link Claude Code's config from dotfiles into ~/.claude: the mods, the status
# line, and the shared settings. Safe to rerun; install.sh,
# remote/bootstrap-noroot.sh and bin/update all call it. The global
# instructions are separate (link-instructions.sh): on the Mac they come from
# 1Password, whose prompt would block bin/update.
set -e
DOTFILES=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$HOME/.claude/skills"
# Each folder in claude/ is a mod, loaded from the skills folder
for MOD in "$DOTFILES"/claude/*/; do
  ln -sfn "${MOD%/}" "$HOME/.claude/skills/$(basename "$MOD")"
done
ln -sfn "$DOTFILES/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
# settings.json itself is not tracked: it holds machine-specific permission
# rules and plugin lists. settings.base.json holds the shareable part, and
# remote machines add settings.remote.json (Remote Control, permission rules,
# plugins). Both go underneath whatever the machine already has, so changes
# made with /config survive a rerun.
SETTINGS="$HOME/.claude/settings.json"
OVERLAY="$DOTFILES/claude/settings.remote.json"
[ "$(uname)" = Darwin ] && OVERLAY=/dev/null
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
jq -s 'reduce .[] as $x ({}; . * $x)' "$DOTFILES/claude/settings.base.json" "$OVERLAY" "$SETTINGS" \
  > "$SETTINGS.new" && mv "$SETTINGS.new" "$SETTINGS"
