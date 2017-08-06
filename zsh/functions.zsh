#!/bin/zsh

# Add a file to the dotfiles repo
add-dotfile() {
    curr_dir=$(pwd)
    cd $DOTFILES_DIR
    if [[ -z $1 ||  -z $2 ]]; then
        echo "Usage: add-dotfile <src path> <repo path> [<post command>]"
        cd $curr_dir
        return 1
    fi
    post_command=""
    if [[ $3 ]]; then
        post_command="-p '$3'"
    fi
    eval "invoke add_dotfile -s $1 -r $2 $post_command"
    cd $curr_dir
}

# remove a file to the dotfiles repo
remove-dotfile() {
    curr_dir=$(pwd)
    cd $DOTFILES_DIR
    if [[ -z $1 ]]; then
        echo "Usage: remove-dotfile <src path>"
        cd $curr_dir
        return 1
    fi
    eval "invoke remove_dotfile -p $1 -r"
    cd $curr_dir
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
