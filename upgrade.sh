#!/bin/zsh
echo "Pulling latest updates for all submodules..."
git submodule foreach 'git fetch; git checkout master; git merge origin/master --ff-only'

echo "Update the shell config"
source ~/.zshenv
source ~/.zshrc
