#!/bin/zsh

_create-virtualenv() {
    venv_name=$1/envs/$2
    pyenv install $1 --skip-existing
    pyenv virtualenv $1 $2 && pyenv activate $venv_name && pip install -r requirements.txt && pyenv deactivate $venv_name && echo $venv_name > .python-version
}

create-virtualenv-py27() {
    _create-virtualenv 2.7.16 $1
}

create-virtualenv-py368() {
    _create-virtualenv 3.6.8 $1
}

create-virtualenv-py373() {
    _create-virtualenv 3.7.3 $1
}

create-virtualenv() {
    create-virtualenv-py373 $1
}

remove-virtualenv() {
    version=$(pyenv version-name)
    rm .python-version
    pyenv virtualenv-delete $version
}

recreate-virtualenv() {
    remove-virtualenv
    create-virtualenv $1
}

recreate-virtualenv-py368() {
    remove-virtualenv
    create-virtualenv-py368 $1
}

