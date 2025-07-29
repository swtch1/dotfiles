#!/usr/bin/env bash

# A script to backup local dot files.

set -e

echo 'copying zshrc...'
cp ~/.zshrc* .

{
  echo 'copying configs...'
  rm -rf ./.config/
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
  cp -r ~/.claude/ .
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

