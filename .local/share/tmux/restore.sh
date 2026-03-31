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

# --- 12 ---
$TMUX_BIN new-session -d -s '12' -c '/Users/josh/code/ss/SPD-11350-chat-auditability' -x 200 -y 50
$TMUX_BIN split-window -t '12' -h -c '/Users/josh/code/ss/SPD-11350-chat-auditability'
# $TMUX_BIN send-keys -t '12' '2.1.87' Enter
$TMUX_BIN select-layout -t '12' '5a10,319x77,0,0{159x77,0,0,7,159x77,160,0,134}' 2>/dev/null || true

# --- 14 ---
$TMUX_BIN new-session -d -s '14' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '14' 'ecf3,319x79,0,0,24' 2>/dev/null || true

# --- 15 ---
$TMUX_BIN new-session -d -s '15' -c '/private/tmp' -x 200 -y 50
$TMUX_BIN send-keys -t '15' 'nvim' Enter
$TMUX_BIN split-window -t '15' -h -c '/Users/josh'
# $TMUX_BIN send-keys -t '15' 'clickhouse' Enter
$TMUX_BIN select-layout -t '15' '3032,319x77,0,0[319x38,0,0,25,319x38,0,39,161]' 2>/dev/null || true

# --- 2 ---
$TMUX_BIN new-session -d -s '2' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '2' 'd986,319x79,0,0,9' 2>/dev/null || true

# --- 21 ---
$TMUX_BIN new-session -d -s '21' -c '/Users/josh/code/ss/SPD-11489-expose-mcp-commands-to-agent' -x 200 -y 50
$TMUX_BIN split-window -t '21' -h -c '/Users/josh/code/ss/SPD-11489-expose-mcp-commands-to-agent'
$TMUX_BIN select-layout -t '21' '7633,319x77,0,0{160x77,0,0,12,158x77,161,0,13}' 2>/dev/null || true

# --- 25 ---
$TMUX_BIN new-session -d -s '25' -c '/private/tmp' -x 200 -y 50
$TMUX_BIN select-layout -t '25' '6cf2,319x79,0,0,51' 2>/dev/null || true

# --- 28 ---
$TMUX_BIN new-session -d -s '28' -c '/Users/josh/code/ss/pristine' -x 200 -y 50
$TMUX_BIN send-keys -t '28' 'nvim' Enter
$TMUX_BIN split-window -t '28' -h -c '/Users/josh/code/ss/pristine'
$TMUX_BIN select-layout -t '28' '8071,319x77,0,0{153x77,0,0,14,165x77,154,0,15}' 2>/dev/null || true

# --- 3 ---
$TMUX_BIN new-session -d -s '3' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '3' '6cf5,319x79,0,0,16' 2>/dev/null || true

# --- 30 ---
$TMUX_BIN new-session -d -s '30' -c '/Users/josh/code/dashboard' -x 200 -y 50
$TMUX_BIN select-layout -t '30' '68f6,319x77,0,0,17' 2>/dev/null || true

# --- 4 ---
$TMUX_BIN new-session -d -s '4' -c '/Users/josh/code/ss/pristine' -x 200 -y 50
$TMUX_BIN select-layout -t '4' 'ecf1,319x79,0,0,22' 2>/dev/null || true

# --- 46 ---
$TMUX_BIN new-session -d -s '46' -c '/Users/josh/.claude' -x 200 -y 50
$TMUX_BIN split-window -t '46' -h -c '/Users/josh/code/madskillz/main'
$TMUX_BIN send-keys -t '46' 'nvim' Enter
$TMUX_BIN split-window -t '46' -h -c '/Users/josh/.claude'
# $TMUX_BIN send-keys -t '46' '2.1.85' Enter
$TMUX_BIN select-layout -t '46' 'b3b3,319x77,0,0{85x77,0,0,76,84x77,86,0,81,148x77,171,0,80}' 2>/dev/null || true

# --- 5 ---
$TMUX_BIN new-session -d -s '5' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '5' 'ecf2,319x79,0,0,23' 2>/dev/null || true

# --- 57 ---
$TMUX_BIN new-session -d -s '57' -c '/Users/josh/.claude/skills' -x 200 -y 50
$TMUX_BIN split-window -t '57' -h -c '/Users/josh/.claude/skills'
# $TMUX_BIN send-keys -t '57' '2.1.87' Enter
$TMUX_BIN select-layout -t '57' 'a9f6,319x77,0,0{159x77,0,0,105,159x77,160,0,106}' 2>/dev/null || true

# --- 59 ---
$TMUX_BIN new-session -d -s '59' -c '/Users/josh/code/ss/SPD-11350-session-history-in-grafana' -x 200 -y 50
$TMUX_BIN send-keys -t '59' 'nvim' Enter
$TMUX_BIN split-window -t '59' -h -c '/Users/josh/code/dashboard/master'
# $TMUX_BIN send-keys -t '59' 'node' Enter
$TMUX_BIN split-window -t '59' -h -c '/Users/josh/code/ss/pristine/api-gateway'
# $TMUX_BIN send-keys -t '59' 'make' Enter
$TMUX_BIN split-window -t '59' -h -c '/Users/josh/code/ss/pristine/api-gateway'
# $TMUX_BIN send-keys -t '59' 'make' Enter
$TMUX_BIN split-window -t '59' -h -c '/Users/josh/code/ss/SPD-11350-session-history-in-grafana'
# $TMUX_BIN send-keys -t '59' '2.1.87' Enter
$TMUX_BIN split-window -t '59' -h -c '/private/tmp'
$TMUX_BIN select-layout -t '59' 'aa39,319x77,0,0{159x77,0,0[159x53,0,0,109,159x12,0,54,150,159x10,0,67{79x10,0,67,127,79x10,80,67,128}],159x77,160,0[159x54,160,0,110,159x22,160,55,148]}' 2>/dev/null || true

# --- 70 ---
$TMUX_BIN new-session -d -s '70' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN split-window -t '70' -h -c '/Users/josh'
# $TMUX_BIN send-keys -t '70' '2.1.87' Enter
$TMUX_BIN select-layout -t '70' 'e9f5,319x77,0,0{159x77,0,0,142,159x77,160,0,143}' 2>/dev/null || true

# --- 73 ---
$TMUX_BIN new-session -d -s '73' -c '/Users/josh/code/ss/pristine' -x 200 -y 50
# $TMUX_BIN send-keys -t '73' '2.1.87' Enter
$TMUX_BIN select-layout -t '73' '34ab,319x77,0,0,151' 2>/dev/null || true

# --- 75 ---
$TMUX_BIN new-session -d -s '75' -c '/Users/josh' -x 200 -y 50
$TMUX_BIN select-layout -t '75' 'b4ad,319x77,0,0,163' 2>/dev/null || true

osascript - <<'APPLESCRIPT'
tell application "Ghostty"
    activate
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 12"
    set win to new window with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 15"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 21"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 28"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 30"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 46"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 57"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 59"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 70"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 73"
    set t to new tab in win with configuration cfg
    set cfg to new surface configuration
    set command of cfg to "/opt/homebrew/bin/tmux -f /Users/josh/.config/tmux/tmux.conf attach-session -t 75"
    set t to new tab in win with configuration cfg
end tell
APPLESCRIPT
