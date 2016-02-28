#!/bin/sh
# Detects which OS and if it is Linux then it will detect which Linux Distribution.

OS=`uname -s`
ARCH=`uname -m`

if [ $OS = "Linux" ] ; then
        KERNEL=`uname -r`
        if [ -f /etc/lsb-release ] ; then
                DIST=$(awk '/DISTRIB_ID=/' /etc/lsb-release | sed 's/DISTRIB_ID=//' | tr '[:upper:]' '[:lower:]')
        elif [ -f /etc/debian_version ] ; then
                DIST="debian"
        fi
else
        DIST="unknown"
fi
