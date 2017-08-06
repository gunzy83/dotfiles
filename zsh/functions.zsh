#!/bin/zsh

# Add a file to the given dotfiles repo, symlink, and return ansible variable string
dotfile-add() {
    FILE_REL_PATH=${$(realpath $1)#$HOME/}
    REPO_REL_PATH=${$(realpath $2)#$HOME/}
    FILE_IN_REPO=$3
    MODE=$(stat -c "%a" ~/$FILE_REL_PATH)

    mkdir -p $(dirname ~/$REPO_REL_PATH/$FILE_IN_REPO)
    mv ~/$FILE_REL_PATH ~/$REPO_REL_PATH/$FILE_IN_REPO
    echo "Moved ~/$FILE_REL_PATH to ~/$REPO_REL_PATH/$FILE_IN_REPO"
    echo ""
    ln -s ~/$REPO_REL_PATH/$FILE_IN_REPO ~/$FILE_REL_PATH
    echo "Moved ~/$FILE_REL_PATH to ~/$REPO_REL_PATH/$FILE_IN_REPO"
    echo ""
    echo "Ansible variable string:"
    echo "  - src: \"$FILE_IN_REPO\""
    echo "    dest: \"~/$FILE_REL_PATH\""
    echo "    mode: \"0$MODE\""
}

# Run `dig` and display the most useful info
digme() {
    dig +nocmd "$1" any +multiline +noall +answer
}

# Create a new directory and enter it
mkd() {
    mkdir -p "$@" && cd "$@"
}

# Determine size of a file or total size of a directory
fs() {
    if du -b /dev/null > /dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi
    if [[ -n "$@" ]]; then
        du $arg -- "$@"
    else
        du $arg .[^.]* *
    fi
}

packer() {
    if [ $DIST = "arch" ] ; then
        # Use packer from packer.io instead of the packer AUR helper
        packer-io "$@"
    else
        packer-bin "$@"
    fi
}

whatprovides() {
    if [ $DIST = "arch" ] ; then
        pkgfile "$@"
    elif [ $DIST = "debian" ] || [ $DIST = "\"elementary\"" ] ; then
        apt-file search "$@"
    else
        echo "whatprovides: unknown distribution"
    fi
}

provideswhat() {
    if [ $DIST = "arch" ] ; then
        pacman -Ql "$@"
    elif [ $DIST = "debian" ] || [ $DIST = "\"elementary\"" ] ; then
        dpkg-query -L "$@"
    else
        echo "provideswhat: unknown distribution"
    fi
}

# Get information about an IP address. When left blank, information about current public IP is returned
ipinfo() {
    curl http://ipinfo.io/"$@";
}

# Generate a password. Length is 20 unless specified.
passwordgen() {
    tr -cd '[:alnum:]' < /dev/urandom | fold -w${@:-20} | head -n1
}

create-virtualenv() {
    pyenv virtualenv 2.7.11 $1 && pyenv activate $1 && pip install -r requirements.txt && pyenv deactivate $1 && echo $1 > .python-version
}
