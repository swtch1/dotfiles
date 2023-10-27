#!/usr/bin/env bash

# A script to backup local dot files.

set -e

echo 'copying vim configs...'
cp ~/.vimrc ./vim/vimrc
cp -r ~/.config/nvim/ ./vim

echo 'copying zshrc...'
cp ~/.zshrc zshrc

echo 'copying gitconfig...'
cp ~/.gitconfig ./git/gitconfig
cp -r ~/.config/git/ ./git

echo 'copying karabiner.json...'
cp ~/.config/karabiner/karabiner.json ./karabiner.json

echo 'copying k9s config...'
cp -r ~/.config/k9s/ ./k9s

echo '--- done ---'
echo
git add --all
git commit -m "backup" --no-verify
git push

