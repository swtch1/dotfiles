#!/usr/bin/env bash

# A script to backup local dot files.

set -e

echo 'copying vim configs...'
cp ~/.vimrc ./.vimrc
cp -r ~/.config/nvim/ ./.config/nvim

echo 'copying zshrc...'
cp ~/.zshrc* .

echo 'copying XDG configs...'
cp -r ~/.config/tmux/tmux.conf ./.config/tmux/
cp -r ~/.config/git/ ./.config/git/
cp -r ~/.config/karabiner/karabiner.json ./.config/karabiner/karabiner.json
cp -r ~/.config/k9s/ ./.config/k9s/
cp -r ~/.config/direnv/ ./.config/direnv/

echo 'copying scripts'
cp -r ~/scripts .

echo '--- done ---'
echo
git add --all
git commit -m "backup" --no-verify
git push

