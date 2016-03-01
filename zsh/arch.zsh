#!/bin/zsh

if [ $DIST = "arch" ] ; then
    # Find what files a package provides
    alias provideswhat="pacman -Ql "
fi
