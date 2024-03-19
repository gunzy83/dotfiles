#!/bin/zsh
# sudo-ing aliases
# https://wiki.archlinux.org/index.php/Sudo#Passing_aliases
alias sudo='sudo '

# Easier navigation:
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

# Do copy with rsync for progress meter
alias cpr="rsync -ah --progress"

# Always enable colored `grep` output
alias grep='grep --color=auto '

# List all files colorized in long format
alias l="ls -lF"

# List all files colorized in long format, including dot files
alias la="ls -laF"

# # List only directories
alias lsd="ls -lF | grep --color=never '^d'"

# IP addresses
alias pubip="dig @resolver1.opendns.com myip.opendns.com +short"

# copy file interactive
alias cp='cp -i'

# move file interactive
alias mv='mv -i'

# untar
alias untar='tar xvf'
