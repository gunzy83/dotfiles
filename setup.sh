#!/bin/zsh

echo "Inititalising submodules..."
git submodule init
git submodule update

echo "Linking pyenv and pyenv-virtualenv..."
ln -sfn $(pwd)/pyenv ~/.pyenv
ln -sfn $(pwd)/pyenv-virtualenv ~/.pyenv/plugins/pyenv-virtualenv

echo "Preparing pyenv in the current shell"
source zsh/pyenv.zsh

echo "Installing python version 2.7.16 with pyenv"
pyenv install 2.7.16 -s

echo "Creating virtualenv for dotfiles"
pyenv virtualenv 2.7.16 dotfiles

echo "Activating the virtualenv and adding .python-version file"
pyenv activate dotfiles
echo "dotfiles" > .python-version

echo "Installing requirements for dotfiles"
# Silence gcc warnings when compiling native extensions
export CFLAGS='-w'
if type pip-sync > /dev/null 2>&1
then
        pip-sync requirements.txt
else
        pip install -r requirements.txt
fi

echo "Ensure roles are installed"
invoke sync_roles

echo "Installing dotfiles"
invoke install

echo "Update the shell config"
source ~/.zshrc
