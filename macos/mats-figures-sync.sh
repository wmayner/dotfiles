#!/bin/sh
# Keeps ~/mats-figures a copy of ~/mats-research/figures on the MATS cluster,
# updated within a second or two of any change there. It holds an SSH
# connection to bin/watch-dir on the cluster, which prints a line on each
# change, and runs rsync for each line. It syncs once on every (re)connection,
# so changes made while the Mac was asleep or offline arrive on wake.
# launchd runs it and restarts it if it exits (macos/com.wmayner.mats-figures.plist).
# The copy mirrors the cluster (--delete), so files edited or added in
# ~/mats-figures are lost at the next sync.
HOST=mats
SRC=/mnt/nw/home/w.mayner/mats-research/figures/
DST="$HOME/mats-figures/"

mkdir -p "$DST"
while true; do
  ssh -n -o BatchMode=yes -o ServerAliveInterval=15 -o ServerAliveCountMax=3 "$HOST" \
      /mnt/nw/home/w.mayner/dotfiles/bin/watch-dir "$SRC" |
    while read -r line; do
      [ "$line" = ping ] && continue
      rsync -a --delete "$HOST:$SRC" "$DST" && echo "$(date '+%F %T') synced ($line)"
    done
  echo "$(date '+%F %T') connection ended; reconnecting in 10 s"
  sleep 10
done
