# dotfiles

[![License](https://img.shields.io/badge/License-BSD%202--Clause-brightgreen.svg?style=flat-square)](LICENSE)

Dotfiles for my workstations, with a focus on engineering and development tooling. These are managed using [chezmoi](https://www.chezmoi.io/).

## Requirements

This set of configuration is known to work on the following Operating Systems:

- [MacOS](https://www.apple.com/macos/)

It is also known to work on the following Linux distributions but configuration is not currently up to date:

- [Fedora Kinoite](https://fedoraproject.org/kinoite/)
- [Kubuntu](https://kubuntu.org/) (to be deprecated)

## Installation

To set up a new machine, you will need to follow these steps before running the install script:

* Determine or set the hostname on the new machine
  * On MacOS, this can be done via System Settings > General > About > Name
  * On Linux, this can be done via `sudo hostnamectl set-hostname <hostname>`
* Create new SSH keys for the machine in 1Password
  * A key for Github access: `github-<hostname>`
  * **[Personal Only]** A key for SSH access: `gunzy-<hostname>`
  * Add the public keys to the relevant services (eg Github) and/or hosts

Finally, install the dotfiles, simply run the following command in your terminal:

```shell
bash -c "$(curl -fsSL -H 'Accept-encoding: deflate' https://raw.githubusercontent.com/gunzy83/dotfiles/master/install.sh)"
```

## Usage

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

## License

BSD 2-Clause License

## Author Information

Created and curated from 2013 onwards by [Ross Williams](http://rosswilliams.id.au/).
