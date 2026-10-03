#!/bin/bash
# Status line mirroring the starship prompt: directory, git branch/status
# (gruvbox_dark powerline segments), then model, context used with its change
# this turn, and the 5-hour and 7-day rate limits. Also sets the terminal title.
input=$(cat)

# One jq call; fields joined by \x1f (non-whitespace, so empty fields survive)
IFS=$'\x1f' read -r cwd model used effort five_hour seven_day tokens window session prompt project name < <(jq -r '[
  (.workspace.current_dir // .cwd // ""), (.model.display_name // ""),
  (.context_window.used_percentage // ""), (.effort.level // ""),
  (.rate_limits.five_hour.used_percentage // "" | if . == "" then . else round end),
  (.rate_limits.seven_day.used_percentage // "" | if . == "" then . else round end),
  (.context_window.total_input_tokens // 0), (.context_window.context_window_size // 0), (.session_id // ""), (.prompt_id // "-"),
  (.workspace.project_dir // .cwd // ""), (.session_name // "" | gsub("[[:cntrl:]]"; " "))
] | map(tostring) | join("\u001f")' <<<"$input")

# Terminal window/tab title: "dir: CC: session name"
printf '\033]0;%s: CC%s\007' "${project##*/}" "${name:+: $name}" > /dev/tty 2>/dev/null

# Context added since the current prompt was submitted, as a percentage of
# the window so it reads in the same units as the fill. The token count at the
# end of the previous prompt is kept per session in a small state file.
delta="" tenths=0
if [ -n "$session" ] && [ "$tokens" -gt 0 ] && [ "$window" -gt 0 ]; then
  state_dir="${TMPDIR:-/tmp}/claude-statusline"; state="$state_dir/$session"
  mkdir -p "$state_dir"
  read -r seen base last < "$state" 2>/dev/null
  if [ "$seen" != "$prompt" ]; then base=${last:-$tokens}; fi
  printf '%s %s %s\n' "$prompt" "$base" "$tokens" > "$state"
  d=$((tokens - base)); a=${d#-}
  tenths=$((a * 1000 / window))   # tenths of a percent of the window
  if [ "$tenths" -ge 1 ]; then
    if [ "$d" -lt 0 ]; then delta="▼"; else delta="▲"; fi
    delta+="$((tenths / 10)).$((tenths % 10))%"
  fi
fi

# Directory: ~ for home, last 3 components, "…/" prefix when truncated
dir=${cwd/#$HOME/\~}
IFS=/ read -ra parts <<<"${dir#/}"
if [ ${#parts[@]} -gt 3 ]; then
  n=${#parts[@]}
  dir="…/${parts[n-3]}/${parts[n-2]}/${parts[n-1]}"
fi

# gruvbox_dark palette from starship.toml, as r;g;b
FG0='251;241;199'; BG1='60;56;54'; BG2='80;73;69'; BG3='102;92;84'; BLUE='69;133;136'
AQUA='104;157;106'; GREEN='152;151;26'; YELLOW='215;153;33'; RED='204;36;29'
PURPLE='177;98;134'; ORANGE='214;93;14'
SEP=$'\xee\x82\xb0'; CAP=$'\xee\x82\xb6'

# Read `symbol = "..."` from a section of starship.toml into $sym, so the glyph
# is exactly starship's. Empty if the file or key is missing.
toml_symbol() {
  sym=""; local l in=0
  while IFS= read -r l; do
    case $l in
      "[$1]") in=1 ;;
      "["*) in=0 ;;
      "symbol = "*)
        if [ $in = 1 ]; then sym=${l#*\"}; sym=${sym%\"*}; break; fi ;;
    esac
  done < "${STARSHIP_CONFIG:-$HOME/.config/starship.toml}" 2>/dev/null
}

# Powerline segments: seg BG FG TEXT [bold]. The arrow's colors come from the
# previous segment's background, so a skipped segment leaves no stray arrow.
out="" prev=""
seg() {
  if [ -z "$prev" ]; then out+=$(printf '\033[0;38;2;%sm%s' "$1" "$CAP")
  else out+=$(printf '\033[0;38;2;%s;48;2;%sm%s' "$prev" "$1" "$SEP"); fi
  out+=$(printf '\033[0;%s38;2;%s;48;2;%sm%s' "${4:+1;}" "$2" "$1" "$3")
  prev=$1
}

# Machine, only over SSH, as in the starship prompt.
[ -n "$SSH_CONNECTION" ] && seg "$ORANGE" "$FG0" " 🌐 ${MACHINE_NAME:-$("$HOME/dotfiles/bin/machine-name")} "

seg "$BG3" "$FG0" " $dir " bold

# Git: a single status call gives branch, ahead/behind and file state
st=$(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)
if [ -n "$st" ]; then
  head="" oid="" ahead="" behind="" s="" m="" u=""
  while IFS= read -r l; do
    case $l in
      "# branch.head "*) head=${l#"# branch.head "} ;;
      "# branch.oid "*)  oid=${l#"# branch.oid "} ;;
      "# branch.ab "*)   ab=${l#"# branch.ab "}; ahead=${ab%% *}; ahead=${ahead#+}
                         behind=${ab##* }; behind=${behind#-} ;;
      "1 "*|"2 "*)       xy=${l:2:2}
                         [ "${xy:0:1}" != . ] && s=1
                         [ "${xy:1:1}" != . ] && m=1 ;;
      "? "*)             u=1 ;;
    esac
  done <<<"$st"
  [ "$head" = "(detached)" ] && head=${oid:0:7}
  flags=""
  [ -n "$s" ] && flags+="+"; [ -n "$m" ] && flags+="!"; [ -n "$u" ] && flags+="?"
  [ "${ahead:-0}" -gt 0 ] && flags+="⇡$ahead"
  [ "${behind:-0}" -gt 0 ] && flags+="⇣$behind"
  toml_symbol git_branch; gsym=${sym:-$'\xee\x82\xa0'}
  seg "$AQUA" "$FG0" " $gsym $head${flags:+ $flags} "
fi

# Python environment from env vars only (no subprocesses)
pyenv=${VIRTUAL_ENV:+${VIRTUAL_ENV##*/}}
pyenv=${pyenv:-$CONDA_DEFAULT_ENV}
if [ -n "$pyenv" ]; then
  toml_symbol python
  seg "$BLUE" "$FG0" " ${sym:+$sym }$pyenv "
fi

[ -n "$model" ] && seg "$BG1" "$FG0" " $model${effort:+ · $effort} "

# From here on, colour means "needs attention": segments are grey until then.

# Context used: grey below 50, yellow to 80, red above. On a grey block, a
# jump of 5% of the window or more in one prompt turns the change yellow.
if [ -n "$used" ]; then
  pct=$(printf '%.0f' "$used")
  if [ "$pct" -gt 80 ]; then c=$RED; elif [ "$pct" -ge 50 ]; then c=$YELLOW; else c=$BG2; fi
  if [ -n "$delta" ] && [ "$c" = "$BG2" ] && [ "$tenths" -ge 50 ] && [ "${delta:0:1}" = "▲" ]; then
    delta=$(printf '\033[38;2;%sm%s\033[38;2;%sm' "$YELLOW" "$delta" "$FG0")
  fi
  seg "$c" "$FG0" " $pct%${delta:+ $delta} "
fi

# Rate limits, one segment: grey to 70, yellow to 85, red above, by
# whichever is higher
worst=$(( ${five_hour:-0} > ${seven_day:-0} ? ${five_hour:-0} : ${seven_day:-0} ))
if [ -n "$five_hour$seven_day" ]; then
  c=$BG1
  [ "$worst" -ge 70 ] && c=$YELLOW
  [ "$worst" -ge 85 ] && c=$RED
  limits="${five_hour:+5h $five_hour%}"
  limits+="${seven_day:+${limits:+ · }7d $seven_day%}"
  seg "$c" "$FG0" " $limits "
fi

# Closing arrow
[ -n "$prev" ] && out+=$(printf '\033[0;38;2;%sm%s\033[0m' "$prev" "$SEP")
printf '%s\n' "$out"
