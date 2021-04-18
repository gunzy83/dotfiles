#!/bin/zsh

# Get information about an IP address. When left blank, information about current public IP is returned
ipinfo() {
    curl http://ipinfo.io/"$@";
}

# Generate a password. Length is 20 unless specified.
passwordgen() {
    tr -cd '[:alnum:]' < /dev/urandom | fold -w${@:-20} | head -n1
}
