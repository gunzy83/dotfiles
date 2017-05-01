#!/bin/zsh

echo "Linking pyenv and pyenv-virtualenv..."
ln -sf pyenv ~/.pyenv
ln -sf pyenv-virtualenv ~/.pyenv/plugins/pyenv-virtualenv

echo "Preparing pyenv in the current shell"
source zsh/pyenv.zsh

echo "Installing python version 2.7.11 with pyenv"
pyenv install 2.7.11 -s

echo "Creating virtualenv for dotfiles"
pyenv virtualenv 2.7.11 dotfiles

echo "Activating the virtualenv and adding .python-version file"
echo "dotfiles" > .python-version
pyenv activate dotfiles

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

echo "Run the following command to apply zsh configuration:"
echo ""
echo "source ~/.zshrc"
source ~/.zshrc