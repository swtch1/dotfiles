#!/usr/bin/env bash

# A script to backup local dot files.

set -e

echo 'copying vimrc...'
cp ~/.vimrc ./vimrc
cp -r ~/.config/nvim/ .

echo 'copying karabiner.json...'
cp ~/.config/karabiner/karabiner.json ./karabiner.json

echo 'copying zshrc...'
grep '### personal ###' ~/.zshrc -A 10000 > zshrc

echo 'copying gitconfig...'
cp ~/.gitconfig ./gitconfig
cp -r ~/.config/git/ ./git

echo '--- done ---'
echo
git add --all
git commit -m "backup" --no-verify
git push

