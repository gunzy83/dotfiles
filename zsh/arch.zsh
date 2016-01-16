#!/bin/zsh

# Use packer from packer.io instead of the packer AUR helper
alias packer="packer-io"

# Find what package provides a file (remember to pkgfile --update)
alias whatprovides="pkgfile "

# Find what files a package provides
alias provideswhat="pacman -Ql "
