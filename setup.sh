#!/bin/zsh

python_version=3.7.3
virtualenv_name=dotfiles
virtualenv_fullname=$python_version/envs/$virtualenv_name

echo "Inititalising submodules..."
git submodule init
git submodule update

echo "Linking pyenv and pyenv-virtualenv..."
ln -sfn $(pwd)/pyenv ~/.pyenv
ln -sfn $(pwd)/pyenv-virtualenv ~/.pyenv/plugins/pyenv-virtualenv

echo "Preparing pyenv in the current shell"
source zsh/pyenv.zsh

echo "Installing python version $python_version with pyenv"
pyenv install $python_version --skip-existing

echo "Creating virtualenv for dotfiles"
pyenv virtualenv -f $python_version $virtualenv_name

echo "Activating the virtualenv and adding .python-version file"
pyenv activate $virtualenv_fullname
echo $virtualenv_fullname > .python-version

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
invoke sync-roles

echo "Installing dotfiles"
invoke install

echo "Update the shell config"
source ~/.zshenv
source ~/.zshrc
