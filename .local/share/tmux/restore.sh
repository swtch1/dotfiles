#!/usr/bin/env bash
set -euo pipefail

# Self-buffer: re-exec from a temp copy so hooks can't clobber us mid-run
if [ -z "${_RESTORE_BUFFERED:-}" ]; then
  _tmp=$(mktemp) || exit 1
  _src="$0"
  [ -L "$_src" ] && _src="$(readlink "$_src")"
  cp "$_src" "$_tmp" || { rm -f "$_tmp"; exit 1; }
  chmod +x "$_tmp"
  _RESTORE_TMP="$_tmp" _RESTORE_BUFFERED=1 exec bash "$_tmp" "$@"
fi

if [ -n "${TMUX:-}" ]; then
  echo "ERROR: Run this from Terminal.app, not from inside tmux/Ghostty." >&2
  exit 1
fi

# Lock so tmux-capture hooks don't overwrite while we run
# Also clean up self-buffer temp file on exit
LOCKDIR="$HOME/.local/share/tmux"
echo $$ > "$LOCKDIR/.restore.lock"
trap 'rm -f "$LOCKDIR/.restore.lock"; [ -n "${_RESTORE_TMP:-}" ] && rm -f "$_RESTORE_TMP"' EXIT

TMUX_BIN=/opt/homebrew/bin/tmux
TMUX_CONF=/Users/josh/.config/tmux/tmux.conf

osascript -e 'tell application "Ghostty" to quit' 2>/dev/null || true
sleep 2

$TMUX_BIN kill-server 2>/dev/null || true
sleep 1

# --- 18 ---
$TMUX_BIN new-session -d -s '18' -c '/private/tmp' -x 200 -y 50
# $TMUX_BIN send-keys -t '18' '2.1.89' Enter
$TMUX_BIN split-window -t '18' -h -c '/private/tmp'
# $TMUX_BIN send-keys -t '18' '2.1.89' Enter
$TMUX_BIN select-layout -t '18:0' '8074,319x77,0,0{172x77,0,0,28,146x77,173,0,26}' 2>/dev/null || true

# --- 19 ---
$TMUX_BIN new-session -d -s '19' -c '/private/tmp' -x 200 -y 50
$TMUX_BIN select-layout -t '19:0' 'e8f6,319x77,0,0,27' 2>/dev/null || true

# --- 2 ---
$TMUX_BIN new-session -d -s '2' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '2:0' 'd984,319x79,0,0,7' 2>/dev/null || true

# --- 21 ---
$TMUX_BIN new-session -d -s '21' -c '/private/tmp' -x 200 -y 50
# $TMUX_BIN send-keys -t '21' '2.1.89' Enter
$TMUX_BIN select-layout -t '21:0' '68f1,319x77,0,0,31' 2>/dev/null || true

# --- 25 ---
$TMUX_BIN new-session -d -s '25' -c '/private/tmp' -x 200 -y 50
$TMUX_BIN select-layout -t '25:0' 'd985,319x79,0,0,8' 2>/dev/null || true

# --- 3 ---
$TMUX_BIN new-session -d -s '3' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '3:0' 'd986,319x79,0,0,9' 2>/dev/null || true

# --- 4 ---
$TMUX_BIN new-session -d -s '4' -c '/Users/josh/code/ss/pristine' -x 200 -y 50
$TMUX_BIN select-layout -t '4:0' '6cf0,319x79,0,0,11' 2>/dev/null || true

# --- 43 ---
$TMUX_BIN new-session -d -s '43' -c '/Users/josh/code/ss/pristine' -x 200 -y 50
$TMUX_BIN split-window -t '43' -h -c '/Users/josh/code/ss/pristine'
# $TMUX_BIN send-keys -t '43' '2.1.89' Enter
$TMUX_BIN select-layout -t '43:0' '3350,319x77,0,0{159x77,0,0,71,159x77,160,0,68}' 2>/dev/null || true

# --- 46 ---
$TMUX_BIN new-session -d -s '46' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '46:0' '68f8,319x77,0,0,76' 2>/dev/null || true

# --- 5 ---
$TMUX_BIN new-session -d -s '5' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '5:0' '6cf4,319x79,0,0,15' 2>/dev/null || true

# --- 81 ---
$TMUX_BIN new-session -d -s '81' -c '/Users/josh/code/ss/SPD-11544-chat-tuning' -x 200 -y 50
$TMUX_BIN send-keys -t '81' 'nvim' Enter
$TMUX_BIN split-window -t '81' -h -c '/Users/josh/code/ss/SPD-11544-chat-tuning'
$TMUX_BIN split-window -t '81' -h -c '/Users/josh/code/ss/SPD-11544-chat-tuning'
$TMUX_BIN select-layout -t '81:0' '6704,319x77,0,0{155x77,0,0[155x54,0,0,19,155x22,0,55,20],163x77,156,0,21}' 2>/dev/null || true

# --- 83 ---
$TMUX_BIN new-session -d -s '83' -c '/Users/josh/code/dashboard/SPD-11571-keep-chat-focus' -x 200 -y 50
# $TMUX_BIN send-keys -t '83' 'node' Enter
$TMUX_BIN split-window -t '83' -h -c '/Users/josh/code/dashboard/SPD-11571-keep-chat-focus'
# $TMUX_BIN send-keys -t '83' '2.1.89' Enter
$TMUX_BIN select-layout -t '83:0' '334e,319x77,0,0{159x77,0,0,22,159x77,160,0,75}' 2>/dev/null || true

osascript - <<'_APPLESCRIPT_EOF_'
tell application "Ghostty"
    activate
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t '18'"
    set win to new window with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t '19'"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t '21'"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t '43'"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t '46'"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t '81'"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t '83'"
    set t to new tab in win with configuration cfg
end tell
_APPLESCRIPT_EOF_
