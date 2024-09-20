#!/usr/bin/env bash

# A script to backup local dot files.

set -e

echo 'copying vim configs...'
cp ~/.vimrc ./.vimrc

echo 'copying zshrc...'
cp ~/.zshrc* .

{
  echo 'copying XDG configs...'
  rm -rf ./.config/
  mkdir .config

  pushd .config
  cp -r ~/.config/nvim .
  cp -r ~/.config/tmux .
  cp -r ~/.config/git .
  cp -r ~/.config/karabiner .
  cp -r ~/.config/k9s .
  cp -r ~/.config/direnv .
  popd
}

echo 'copying scripts'
cp -r ~/scripts .

echo 'copying iterm2 config'
cp /Users/josh/Library/Preferences/com.googlecode.iterm2.plist .

echo '--- done ---'
echo
git add --all
git commit -m "backup" --no-verify
git push

