#!/usr/bin/env bash

# A script to backup local dot files.

set -e

{
  echo 'copying zshrc...'
  cp ~/.zshrc* .
}

{
  echo 'copying configs...'
  rm -rf .config/
  mkdir .config

  pushd .config
  cp ~/.vimrc ./.vimrc
  cp -r ~/.config/nvim .
  cp -r ~/.config/tmux .
  cp -r ~/.config/git .
  cp -r ~/.config/karabiner .
  cp -r ~/.config/k9s .
  cp -r ~/.config/direnv .
  cp -r ~/.config/ghostty .
  popd
}

{
  echo 'copying agent config...'

  rm -rf .claude
	mkdir .claude

  cp ~/.claude/mcp*.json .claude/
	cp -r ~/.claude/agents/ .claude/agents/
	cp -r ~/.claude/skills/ .claude/skills/
  rm -rf .claude/skills/personal # don't commit this
  find .claude/skills -type d -name '.git' -exec rm -rf {} + 2>/dev/null || true
}

{
  echo 'copying local state...'
  rm -rf .local
  mkdir -p .local/share

  pushd .local/share
  cp -r ~/.local/share/tmux .
  popd
}

echo 'copying scripts'
cp -r ~/scripts .

echo 'copying iterm2 config'
cp /Users/josh/Library/Preferences/com.googlecode.iterm2.plist .

# make sure we never commit secrets
find . -type f -name '*secret*' -print0 | xargs -0 rm -rf

echo '--- done ---'
echo
git add --all
git commit -m "backup" --no-verify
git push

