#!/usr/bin/env bash

# A script to backup local dot files.

set -e

echo 'copying vim configs...'
cp ~/.vimrc ./vim/vimrc
cp -r ~/.config/nvim/ ./vim

echo 'copying zshrc...'
cp ~/.zshrc* .

echo 'copying git config...'
cp -r ~/.config/git/ ./git

echo 'copying karabiner.json...'
cp ~/.config/karabiner/karabiner.json ./karabiner.json

echo 'copying XDG configs...'
cp -r ~/.config/k9s/ ./.config/
cp -r ~/.config/direnv/ ./.config/

echo 'copying tmux config...'
cp ~/.tmux.conf .

echo 'copying scripts'
cp -r ~/scripts .

echo '--- done ---'
echo
git add --all
git commit -m "backup" --no-verify
git push

