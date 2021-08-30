#!/usr/bin/env bash

set -e
trap on_error SIGKILL SIGTERM

e='\033'
RESET="${e}[0m"
BOLD="${e}[1m"
CYAN="${e}[0;96m"
RED="${e}[0;91m"
YELLOW="${e}[0;93m"
GREEN="${e}[0;92m"

_exists() {
  command -v $1 > /dev/null 2>&1
}

# Success reporter
info() {
  echo -e "${CYAN}${*}${RESET}"
}

# Error reporter
error() {
  echo -e "${RED}${*}${RESET}"
}

# Success reporter
success() {
  echo -e "${GREEN}${*}${RESET}"
}

# End section
finish() {
  success "Done!"
  echo
  sleep 1
}

DOTFILES=~/.local/share/chezmoi
GITHUB_USER="gunzy83"
GITHUB_REPO_SSH_REMOTE="git@github.com:$GITHUB_USER/dotfiles.git"
GITHUB_REPO_URL_BASE="https://github.com/$GITHUB_USER/dotfiles"
HOMEBREW_INSTALLER_URL="https://raw.githubusercontent.com/Homebrew/install/master/install"

on_start() {
  info "           __        __   ____ _  __                "
  info "      ____/ /____   / /_ / __/(_)/ /___   _____     "
  info "     / __  // __ \ / __// /_ / // // _ \ / ___/     "
  info "  _ / /_/ // /_/ // /_ / __// // //  __/(__  )      "
  info " (_)\__,_/ \____/ \__//_/  /_//_/ \___//____/       "
  info "                                                    "
  info "              by @$GITHUB_USER                      "
  info "                                                    "
  info "This script will install dotfiles for @$GITHUB_USER."
  info "                                                    "
  info "If you are not @$GITHUB_USER, ensure you fork all files containing secrets before running."
  echo
  read -p "Do you want to proceed with installation? [y/N] " -n 1 answer
  echo
  if [ ${answer} != "y" ]; then
    exit 1
  fi
}

install_homebrew_deps() {
  if [ -f /etc/os-release ]; then
    # freedesktop.org and systemd
    . /etc/os-release
    OS=$NAME
  elif type lsb_release >/dev/null 2>&1; then
    # linuxbase.org
    OS=$(lsb_release -si)
  else
    # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
    OS=$(uname -s)
  fi

  if [ `uname` != 'Linux' ]; then
    error "Operating system not supported!"
    exit 1
  fi

  info "Installing homebrew dependencies..."

  if [ "$OS" == 'Solus' ]; then
    info "Solus Linux detected, installing with eopkg..."
    sudo eopkg -y it -c system.devel && sudo eopkg -y it curl file git
  elif [ "$OS" == 'Manjaro Linux' ]; then
    info "Manjaro Linux detected, installing gunzy-init with pacman..."
    sudo sed -i 's/#RemoteFileSigLevel.*/RemoteFileSigLevel = Optional/g' /etc/pacman.conf
    sudo pacman -U --noconfirm http://repo.recursive.cloud/arch/repo/x86_64/gunzy-init-0.0.3-1-any.pkg.tar.zst
  elif [ "$OS" == 'Ubuntu' ]; then
    info "Ubuntu detected, installing with apt..."
    sudo apt-get install -y build-essential curl file git
  else
    error "Linux distribution not supported!"
    exit 2
  fi

  finish
}

install_homebrew() {
  info "Trying to detect installed Homebrew..."

  if ! _exists brew; then
    info "Installing Homebrew..."
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    brew update
    brew upgrade
  else
    success "You already have Homebrew installed. Skipping..."
  fi

  finish
}

install_chezmoi() {
  info "Trying to detect installed Chezmoi..."

  if ! _exists chezmoi; then
    info "Installing Chezmoi..."
    brew install chezmoi
  else
    success "You already have Chezmoi installed. Skipping..."
  fi

  finish
}

chezmoi_apply() {
  info "Trying to detect installed dotfiles in $DOTFILES..."

  if [ ! -d $DOTFILES ]
  then
    echo "Seems like you don't have dotfiles installed!"
    info "Installing dotfiles and applying..."
    chezmoi init --apply --verbose $GITHUB_USER
  else
    success "You already have dotfiles installed. Updating and applying..."
    chezmoi init
    chezmoi update --verbose
  fi
  # assume machine is going to be used for development of dotfiles
  # TODO: Add question to installer to toggle this off.
  info "Updating dotfiles origin to allow development..."
  chezmoi git remote set-url origin $GITHUB_REPO_SSH_REMOTE

  finish
}


on_finish() {
  echo
  success "Setup was successfully done!"
  echo
  echo -ne $RED'-_-_-_-_-_-_-_-_-_-_-_-_-_-_'
  echo -e  $RESET$BOLD',------,'$RESET
  echo -ne $YELLOW'-_-_-_-_-_-_-_-_-_-_-_-_-_-_'
  echo -e  $RESET$BOLD'|   /\_/\\'$RESET
  echo -ne $GREEN'-_-_-_-_-_-_-_-_-_-_-_-_-_-'
  echo -e  $RESET$BOLD'~|__( ^ .^)'$RESET
  echo -ne $CYAN'-_-_-_-_-_-_-_-_-_-_-_-_-_-_'
  echo -e  $RESET$BOLD'""  ""'$RESET
  echo
  info "P.S: Don't forget to restart a terminal :)"
  echo
}

on_error() {
  echo
  error "Wow... Something serious happened!"
  error "Though, I don't know what really happened :("
  error "In case, you want to help me fix this problem, raise an issue -> ${CYAN}${GITHUB_REPO_URL_BASE}issues/new${RESET}"
  echo
  exit 1
}



main() {
  on_start "$*"
  install_homebrew_deps "$*"
  install_homebrew "$*"
  install_chezmoi "$*"
  chezmoi_apply "$*"
  on_finish "$*"
}

main "$*"
