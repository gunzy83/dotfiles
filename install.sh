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

_pause() {
  read -p "Press [Enter] key to continue..."
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
OS=None

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

get_os_name() {
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
  if [ `uname` != 'Linux' ] && [ `uname` != 'Darwin' ]; then
    error "Operating system not supported!"
    exit 1
  fi
}

check_pre_steps() {
  logout_required=0
  if [ "$OS" == 'Manjaro Linux' ]; then
    if [ ! -f /etc/security/limits.d/20-custom.conf ]; then
      info "Manjaro requires an increase in open file limits, applying update to /etc/security/limits.d/20-custom.conf..."
      sudo mkdir -p /etc/security/limits.d
      sudo echo "* hard nofile 524288\n* soft nofile 16384\n" | sudo tee /etc/security/limits.d/20-custom.conf
      logout_required=1
    fi
  fi
  if [ "$OS" != 'Darwin' ]; then
    if [ $(getent passwd $USER | awk -F: '{print $NF}') != "/bin/zsh" ]; then
      info "Setting shell for user $USER to zsh..."
      sudo usermod --shell /bin/zsh ${USER}
      logout_required=1
    fi
  fi
  if [ $logout_required -eq 1 ]; then
    info "Warning: Please re-login to apply system settings to proceed with the install."
    exit 1
  fi
}

install_deps() {
  info "Installing base dependencies..."

  if [ "$OS" == 'Manjaro Linux' ]; then
    info "Manjaro Linux detected, preparing pacman and installing gunzy-init..."
    sudo sed -i 's/#RemoteFileSigLevel.*/RemoteFileSigLevel = Never/g' /etc/pacman.conf
    sudo pacman-mirrors --geoip --method rank && sudo pacman -Syyu
    sudo pacman -U --noconfirm https://repo.recursive.cloud/arch/repo/x86_64/gunzy-init-0.1.0-1-any.pkg.tar.zst
  elif [ "$OS" == 'Darwin' ]; then
    info "Darwin detected, installing Xcode CLI Tools..."
    xcode-select --install
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
    if [ `uname` != 'Darwin' ]; then
      eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv) # on Mac homebrew is installed to a location already on $PATH
    fi
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
    if [ "$OS" == 'Manjaro Linux' ]; then
      sudo pacman -Sy --asdeps chezmoi crudini
    elif [ "$OS" == 'Darwin' ]; then
      brew install chezmoi
    fi
  else
    success "You already have Chezmoi installed. Skipping..."
  fi

  finish
}

prepare_1password() {
  info "Preparing 1password for chezmoi apply..."

  if [ `uname` == 'Darwin' ]; then
    info "Installing 1password and 1password-cli..."
    brew install --cask 1password
    brew install --cask 1password/tap/1password-cli
    info "Install complete!"
  else
    info "Installing 1password and 1password-cli..."
    if [ "$OS" == 'Manjaro Linux' ]; then
      sudo pacman -Sy --asdeps 1password 1password-cli pam-u2f
    fi
    info "Prepare to press button on Yubikey to register key for U2F unlock..."
    _pause
    mkdir -p ~/.config/Yubico
    pamu2fcfg -o pam://hostname -i pam://hostname > ~/.config/Yubico/u2f_keys
    info "U2F setup complete!\n"
    info "Note: to add additional keys, run the following command: \"pamu2fcfg -o pam://hostname -i pam://hostname >> ~/.config/Yubico/u2f_keys\""

    info "Setting up PAM for System Authentication unlock..."
    if ! grep -Fxq "auth       include      system-auth" /etc/pam.d/polkit-1
    then
      error "Error! /etc/pam.d/polkit-1 does not contain expected content. Manual intervention required..."
      exit 1
    fi
    if grep -Fxq "auth    sufficient    pam_u2f.so cue origin=pam://hostname appid=pam://hostname" /etc/pam.d/polkit-1
    then
      info "U2F already configured in PAM, skipping..."
    else
      sed '/^auth       include      system-auth/i auth    sufficient    pam_u2f.so cue origin=pam://hostname appid=pam://hostname' /etc/pam.d/polkit-1 | sudo tee /etc/pam.d/polkit-1
    fi
    info "Setup of PAM for System Authentication unlock complete!"
  fi
  info "Sign in to 1password and 1password-cli..."
  _pause

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
  get_os_name "$*"
  check_pre_steps "$*"
  install_deps "$*"
  install_homebrew "$*"
  install_chezmoi "$*"
  prepare_1password "$*"
  chezmoi_apply "$*"
  on_finish "$*"
}

main "$*"
