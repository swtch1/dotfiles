#!/usr/bin/env bash
set -euo pipefail

# Self-buffer: re-exec from a temp copy so hooks can't clobber us mid-run
if [ -z "${_RESTORE_BUFFERED:-}" ]; then
  _tmp=$(mktemp)
  _src="$0"
  [ -L "$_src" ] && _src="$(readlink "$_src")"
  cp "$_src" "$_tmp"
  chmod +x "$_tmp"
  _RESTORE_BUFFERED=1 exec bash "$_tmp" "$@"
fi

if [ -n "${TMUX:-}" ]; then
  echo "ERROR: Run this from Terminal.app, not from inside tmux/Ghostty." >&2
  exit 1
fi

# Lock so tmux-capture hooks don't overwrite while we run
LOCKDIR="$HOME/.local/share/tmux"
echo $$ > "$LOCKDIR/.restore.lock"
trap 'rm -f "$LOCKDIR/.restore.lock"' EXIT

TMUX_BIN=/opt/homebrew/bin/tmux
TMUX_CONF=/Users/josh/.config/tmux/tmux.conf

osascript -e 'tell application "Ghostty" to quit' 2>/dev/null || true
sleep 2

$TMUX_BIN kill-server 2>/dev/null || true
sleep 1

# --- 0 ---
$TMUX_BIN new-session -d -s '0' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN send-keys -t '0' 'nvim' Enter
$TMUX_BIN select-layout -t '0' 'd97d,319x79,0,0,0' 2>/dev/null || true

# --- 1 ---
$TMUX_BIN new-session -d -s '1' -c '/Users/josh/code/dashboard/SPD-11486-enable-full-linting' -x 200 -y 50
$TMUX_BIN select-layout -t '1' 'd17e,319x77,0,0,1' 2>/dev/null || true
$TMUX_BIN new-window -t '1' -c '/Users/josh/code/dashboard/master'
$TMUX_BIN select-layout -t '1' 'd97f,319x79,0,0,2' 2>/dev/null || true

# --- 11 ---
$TMUX_BIN new-session -d -s '11' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '11' '6cef,319x79,0,0,10' 2>/dev/null || true

# --- 2 ---
$TMUX_BIN new-session -d -s '2' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '2' 'd980,319x79,0,0,3' 2>/dev/null || true

# --- 3 ---
$TMUX_BIN new-session -d -s '3' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '3' 'd981,319x79,0,0,4' 2>/dev/null || true

# --- 4 ---
$TMUX_BIN new-session -d -s '4' -c '/Users/josh/code/ss/pristine' -x 200 -y 50
$TMUX_BIN select-layout -t '4' 'd982,319x79,0,0,5' 2>/dev/null || true

# --- 5 ---
$TMUX_BIN new-session -d -s '5' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '5' 'd983,319x79,0,0,6' 2>/dev/null || true

osascript - <<'APPLESCRIPT'
tell application "Ghostty"
    activate
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 11"
    set win to new window with configuration cfg
end tell
APPLESCRIPT
