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

check_compat() {
  info "Checking compatibility..."

  if [ "$OS" == 'Fedora Linux' ]; then
    info "Fedora detected, checking variant..."
    if [ "$VARIANT" == 'Kinoite' ]; then
      info "Kinoite detected, continuing..."
    elif [ "$VARIANT" == 'Silverblue' ]; then
      info "Silverblue detected, continuing..."
    else
      error "Fedora variant $VARIANT not supported!"
      exit 1
    fi
  elif [ "$OS" == 'Ubuntu' ]; then
    info "Ubuntu detected, continuing..."
  elif [ "$OS" == 'Darwin' ]; then
    info "MacOS detected, continuing..."
  fi
}

check_pre_steps() {
  logout_required=0
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
  if [ "$OS" != 'Fedora Linux' ]; then
    info "Installing base dependencies..."
    if [ "$OS" == 'Ubuntu' ]; then
      info "Ubuntu detected, installing dependencies..."
      sudo apt update
      sudo apt install -y build-essential ca-certificates crudini curl file fontconfig git gnupg software-properties-common
      sudo add-apt-repository --yes --update ppa:ansible/ansible
      sudo apt-get install -y ansible
      finish
    elif [ "$OS" == 'Darwin' ]; then
      info "Darwin detected!"
      info "Checking for Xcode CLI tools..."
      if xcode-select -p > /dev/null 2>&1 ; then
        info "Xcode CLI tools already installed. Skipping..."
      else
        info "Xcode CLI tools not found. Installing..."
        xcode-select --install
      fi
      finish
    else
      error "Linux distribution not supported!"
      exit 2
    fi
  fi
}

install_homebrew() {
  if [ "$OS" == 'Darwin' ]; then
    info "Trying to detect installed Homebrew..."
    if ! _exists brew; then
      info "Installing Homebrew..."
      bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      [[ $(arch) == "arm64" ]] && eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
      brew update
      brew upgrade
    else
      success "You already have Homebrew installed. Skipping..."
    fi
    finish
  fi
}

install_chezmoi() {
  if [ "$OS" != 'Fedora Linux' ]; then
    info "Trying to detect installed Chezmoi..."

    if ! _exists chezmoi; then
      info "Installing Chezmoi..."
      if [ "$OS" == 'Ubuntu' ]; then
        curl -sSL https://raw.githubusercontent.com/upciti/wakemeops/main/assets/install_repository | sudo bash
        sudo apt install chezmoi
      elif [ "$OS" == 'Darwin' ]; then
        brew install chezmoi
      fi
    else
      success "You already have Chezmoi installed. Skipping..."
    fi
    finish
  fi
}

prepare_1password(){
  info "Preparing 1password for chezmoi apply..."

  if [ "$OS" == 'Darwin' ]; then
    info "Installing 1password and 1password-cli..."
    if [ ! -d "/Applications/1Password.app" ]; then
      brew install --cask 1password
    fi
    brew install --cask 1password-cli
    info "Install complete!"
  elif [ "$OS" == 'Ubuntu' ]; then
    info "Installing 1password and 1password-cli..."
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
    echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    sudo apt update && sudo apt install 1password 1password-cli libpam-u2f pamu2fcfg
  fi

  if [ "$OS" != 'Darwin' ]; then
    if [ ! -f ~/.config/Yubico/u2f_keys ]; then
      info "Prepare to press button on Yubikey to register key for U2F unlock..."
      _pause
      mkdir -p ~/.config/Yubico
      pamu2fcfg -o pam://hostname -i pam://hostname > ~/.config/Yubico/u2f_keys
      info "U2F setup complete!\n"
    else
      info "U2F keys already registered, skipping..."
    fi
    info "Note: to add additional keys, run the following command: \"pamu2fcfg -o pam://hostname -i pam://hostname >> ~/.config/Yubico/u2f_keys\""

    if [ "$OS" != 'Fedora Linux' ]; then
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
  fi
  info "Ensure you are signed into 1password and 1password-cli now..."
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
  if [ "$OS" == 'Ubuntu' ]; then
    echo
    echo "Note: If running KDE on Ubuntu, you may want to install the following via the system settings:"
    echo
    echo " - applet-betterinlineclock"
    echo " - applet-window-appmenu"
    echo " - applet-window-title"
    echo " - cherry-kde-theme"
  fi
  echo
  success "Setup was successful!"
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
  info "P.S: Don't forget to restart your terminal :)"
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
  check_compat "$*"
  check_pre_steps "$*"
  install_deps "$*"
  install_homebrew "$*"
  install_chezmoi "$*"
  prepare_1password "$*"
  chezmoi_apply "$*"
  on_finish "$*"
}

main "$*"
