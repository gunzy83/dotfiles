dotfiles
========

[![License](https://img.shields.io/badge/License-BSD%202--Clause-brightgreen.svg?style=flat-square)](LICENSE)

Dotfiles for my workstations, with a focus on engineering and development tooling. These are managed using [chezmoi](https://www.chezmoi.io/).

Requirements
------------

This dotfiles collection is designed to be self contained within an installed distribution of Linux and used within a [distrobox](https://distrobox.it/) container. This set of configuration is known to work on the following Linux distributions:

* [Fedora Kinoite](https://fedoraproject.org/kinoite/)
* [Kubuntu](https://kubuntu.org/) (Probably works on other Ubuntu flavours as well)

and in the following distrobox container image:

* [gunzy83/devbox](https://github.com/gunzy83/devbox/pkgs/container/devbox)

I have also used a subset of this on OSX but this is largely unmaintained.

Installation
------------

To install the dotfiles, simply run the following command in your terminal:

```shell
bash -c "$(curl -fsSL https://raw.githubusercontent.com/gunzy83/dotfiles/master/install.sh)"
```

Usage
-----

Once installed, the following commands can be used to manage the repo and its files:

Before running updates from the remote, ensure that the repo is clean and has no active changes

```
# enter the dotfile directory
chezmoi cd
# check the status of the repo
git status
git diff
# stash any changes
git stash
```

Pull changes from the remote:

```
chezmoi update
```

Remember that each change can be diff'd (`d`) and overwritted (`o`) or skipped (`s`).

Once update has run, we can check for files that have still require updating from remote or have changed in disk since being added:

```
chezmoi diff
```

If you want to add all the local changes, just add the file again:

```
chezmoi add <filename>
```

License
-------

BSD 2-Clause License

Author Information
------------------

Created and curated from 2013 onwards by [Ross Williams](http://rosswilliams.id.au/).
