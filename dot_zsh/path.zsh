#!/bin/zsh

# Extend $PATH without duplicates
_extend_path() {
  if ! $( echo "$PATH" | tr ":" "\n" | grep -qx "$1" ) ; then
    export PATH="$1:$PATH"
  fi
}

# Add user bin dir to $PATH
[[ -d "$HOME/.bin" ]] && _extend_path "$HOME/.local/bin"
