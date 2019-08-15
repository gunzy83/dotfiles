#!/bin/zsh
echo "Syncing with remote..."
git sync

echo "Updating submodules..."
git submodule init
git submodule update

echo "Updating requirements for dotfiles"
# Silence gcc warnings when compiling native extensions
export CFLAGS='-w'
if type pip-sync > /dev/null 2>&1
then
        pip-sync requirements.txt
else
        pip install -r requirements.txt
fi

echo "Ensure roles are up to date"
invoke sync_roles

echo "Updating dotfiles"
invoke install

echo "Update the shell config"
source ~/.zshrc
