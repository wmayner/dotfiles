#!/bin/sh
# Render an HTML figure or diagram to PNG at 2x: render_html.sh in.html out.png [width] [height]
# width and height are the .canvas or .fig size in CSS pixels (default 1600 x 700).
# Browser: $CHROME if set, else Playwright's headless shell (Linux or macOS cache), else Chrome or Chromium.
set -e
in=$(realpath "$1"); out=$(realpath -m "$2" 2>/dev/null || echo "$(cd "$(dirname "$2")" && pwd)/$(basename "$2")")
w=${3:-1600}; h=${4:-700}
browser=${CHROME:-$(ls -d "$HOME"/.cache/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell \
  "$HOME"/Library/Caches/ms-playwright/chromium_headless_shell-*/*/chrome-headless-shell 2>/dev/null | tail -1)}
if [ -z "$browser" ]; then
  for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "$(command -v chromium || true)" "$(command -v google-chrome || true)"; do
    [ -n "$c" ] && [ -x "$c" ] && browser=$c && break
  done
fi
[ -n "$browser" ] || { echo "no headless browser: run 'uvx playwright install chromium-headless-shell' or set CHROME" >&2; exit 1; }
"$browser" --headless --screenshot="$out" --window-size="$w,$h" --force-device-scale-factor=2 --hide-scrollbars \
  --allow-file-access-from-files --default-background-color=FFFFFFFF --virtual-time-budget=3000 "file://$in" 2>/dev/null
echo "wrote $out"
