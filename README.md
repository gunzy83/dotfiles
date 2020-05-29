dotfiles
========

[![License](https://img.shields.io/badge/License-BSD%202--Clause-brightgreen.svg?style=flat-square)](LICENSE)

My dotfiles collection.

Requirements
------------

These files have only been tested on:

* Solus
* Ubuntu 15.04-18.04 based distributions
* Arch Linux

Some of these files will do anything without the apps they are intended to configure. Ensure the following are installed before or after:

* git
* Konsole
* Yakuake
* Quassel
* Sublime Text 3
* vim
* fc-cache

Usage
-----

All commands below should be run from within the dotfiles directory.

Fresh install of the dotfiles:

```
./setup.sh
```

Update the dotfiles from upstream and install:

```
./update.sh
```

Upgrade all the submodule contents and refresh shell config:

```
./upgrade.sh
```

List invoke options:

```
invoke --list
```

Add a new file to the repo with post command `echo thing`:

```
invoke add_dotfile -s ~/.zsh/completions/test -r invoke/test -p 'echo thing'
```

Remove a file from the repo (restore to previous location):

```
invoke remove_dotfile -p ~/.zsh/completions/test -r
```

Run the install play:

```
invoke install
```

Ensure the dotfiles installer role is up to date:

```
invoke sync_roles
```

Shell function to add a dotfile from anywhere (see `zsh/functions.zsh`):

```
add-dotfile ~/.zsh/completions/test invoke/test "echo thing"
```

Shell function to remove a dotfile from anywhere:

```
remove-dotfile ~/.zsh/completions/test
```

Extra Notes:
------------

The following git submodules are included:

* [pyenv](https://github.com/pyenv/pyenv)
* [pyenv-virtualenv](https://github.com/pyenv/pyenv-virtualenv)
* [pyenv-default-packages](https://github.com/jawshooah/pyenv-default-packages)
* [Vundle.vim](https://github.com/VundleVim/Vundle.vim)
* [zgen](https://github.com/tarjoilija/zgen)
* [git-passport](https://github.com/frace/git-passport)
* [tfenv](https://github.com/Zordrak/tfenv.git)

License
-------

BSD 2-Clause License

Author Information
------------------

Created and curated from 2013 onwards by [Ross Williams](http://rosswilliams.id.au/).
