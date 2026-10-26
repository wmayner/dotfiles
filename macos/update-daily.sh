#!/bin/sh
#
# Run bin/update once a day from launchd (com.wmayner.update), logging to
# ~/Library/Logs/update.log and posting a notification if any step fails.
#
# launchd calls this every 15 minutes, and it does nothing unless all of these
# hold:
# - It has not run yet today. The day starts at 04:00, so a late night counts
#   as the day before.
# - Someone has used the keyboard or trackpad in the last 10 minutes. A
#   sleeping laptop wakes briefly on its own (a "dark wake") for maintenance,
#   and a fixed-time job that fires then gets a few seconds of flaky or no
#   network before the Mac sleeps again. That made most steps fail.
# - github.com is reachable.
# caffeinate then keeps the Mac from idle-sleeping in the middle of the run.

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.asdf/shims:/usr/bin:/bin:/usr/sbin:/sbin"
log="$HOME/Library/Logs/update.log"
stamp="$HOME/Library/Logs/update.lastrun"

today=$(/bin/date -v-4H +%F)
[ "$(/bin/cat "$stamp" 2>/dev/null)" = "$today" ] && exit 0

idle=$(ioreg -c IOHIDSystem -d 4 | awk '/HIDIdleTime/ {print int($NF / 1e9); exit}')
[ "${idle:-999999}" -lt 600 ] || exit 0

curl -sfI --max-time 10 https://github.com >/dev/null || exit 0

echo "$today" >"$stamp"
printf '\n=== %s\n' "$(/bin/date)" >>"$log"
caffeinate -i "$HOME/dotfiles/bin/update" </dev/null >>"$log" 2>&1 ||
  osascript -e "display notification \"$(tail -1 "$log")\" with title \"Daily update failed\" subtitle \"See ~/Library/Logs/update.log\""
