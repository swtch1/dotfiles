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
$TMUX_BIN new-session -d -s '1' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '1' 'd17e,319x77,0,0,1' 2>/dev/null || true
$TMUX_BIN new-window -t '1' -c '/Users/josh/code/dashboard/master'
$TMUX_BIN select-layout -t '1' 'd97f,319x79,0,0,2' 2>/dev/null || true

# --- 14 ---
$TMUX_BIN new-session -d -s '14' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '14' 'd980,319x79,0,0,3' 2>/dev/null || true

# --- 17 ---
$TMUX_BIN new-session -d -s '17' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '17' 'ecf4,319x79,0,0,25' 2>/dev/null || true

# --- 18 ---
$TMUX_BIN new-session -d -s '18' -c '/private/tmp' -x 200 -y 50
# $TMUX_BIN send-keys -t '18' '2.1.89' Enter
$TMUX_BIN split-window -t '18' -h -c '/private/tmp'
# $TMUX_BIN send-keys -t '18' '2.1.89' Enter
$TMUX_BIN select-layout -t '18' '8074,319x77,0,0{172x77,0,0,28,146x77,173,0,26}' 2>/dev/null || true

# --- 19 ---
$TMUX_BIN new-session -d -s '19' -c '/private/tmp' -x 200 -y 50
$TMUX_BIN select-layout -t '19' 'e8f6,319x77,0,0,27' 2>/dev/null || true

# --- 2 ---
$TMUX_BIN new-session -d -s '2' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '2' 'd984,319x79,0,0,7' 2>/dev/null || true

# --- 21 ---
$TMUX_BIN new-session -d -s '21' -c '/private/tmp' -x 200 -y 50
# $TMUX_BIN send-keys -t '21' '2.1.89' Enter
$TMUX_BIN select-layout -t '21' '68f1,319x77,0,0,31' 2>/dev/null || true

# --- 22 ---
$TMUX_BIN new-session -d -s '22' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '22' '68f2,319x77,0,0,32' 2>/dev/null || true

# --- 25 ---
$TMUX_BIN new-session -d -s '25' -c '/private/tmp' -x 200 -y 50
$TMUX_BIN select-layout -t '25' 'd985,319x79,0,0,8' 2>/dev/null || true

# --- 3 ---
$TMUX_BIN new-session -d -s '3' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '3' 'd986,319x79,0,0,9' 2>/dev/null || true

# --- 4 ---
$TMUX_BIN new-session -d -s '4' -c '/Users/josh/code/ss/pristine' -x 200 -y 50
$TMUX_BIN select-layout -t '4' '6cf0,319x79,0,0,11' 2>/dev/null || true

# --- 5 ---
$TMUX_BIN new-session -d -s '5' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '5' '6cf4,319x79,0,0,15' 2>/dev/null || true

# --- 81 ---
$TMUX_BIN new-session -d -s '81' -c '/Users/josh/code/ss/SPD-11544-chat-tuning' -x 200 -y 50
$TMUX_BIN send-keys -t '81' 'nvim' Enter
$TMUX_BIN split-window -t '81' -h -c '/Users/josh/code/ss/SPD-11544-chat-tuning'
$TMUX_BIN split-window -t '81' -h -c '/Users/josh/code/ss/SPD-11544-chat-tuning'
# $TMUX_BIN send-keys -t '81' '2.1.89' Enter
$TMUX_BIN select-layout -t '81' '6704,319x77,0,0{155x77,0,0[155x54,0,0,19,155x22,0,55,20],163x77,156,0,21}' 2>/dev/null || true

# --- 83 ---
$TMUX_BIN new-session -d -s '83' -c '/Users/josh/code/dashboard/master' -x 200 -y 50
$TMUX_BIN select-layout -t '83' 'e8f1,319x77,0,0,22' 2>/dev/null || true

osascript - <<'APPLESCRIPT'
tell application "Ghostty"
    activate
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 18"
    set win to new window with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 19"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 21"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 22"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 81"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 83"
    set t to new tab in win with configuration cfg
end tell
APPLESCRIPT
