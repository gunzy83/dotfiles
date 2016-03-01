#!/bin/zsh

if [ $DIST = "arch" ] ; then
    # Find what package provides a file (remember to pkgfile --update)
    alias whatprovides="pkgfile "

    # Find what files a package provides
    alias provideswhat="pacman -Ql "
fi
