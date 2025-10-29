#!/bin/zsh

# Get information about an IP address. When left blank, information about current public IP is returned
ipinfo() {
    curl http://ipinfo.io/"$@";
}

# Generate a password. Length is 20 unless specified.
passwordgen() {
    export LC_ALL=C; tr -cd '[:alnum:]' < /dev/urandom | fold -w${@:-20} | head -n1
}

jwt-decode() {
    JWT="$1"
    jq -R 'split(".") | select(length > 0) | .[0],.[1] | @base64d | fromjson' <<< $JWT
}
