# Ubuntu install notes

These notes are going to be used to update the scripts and config files for later.

## Steps

* Install the kde backports PPA if running on LTS, reboot
* Install deps `sudo apt-get install -y build-essential curl file git crudini fontconfig`
* Install asdf-vm via git method `git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.3`
  * How to work out what the current stable version is using this method?
* Load it into the shell `. "$HOME/.asdf/asdf.sh"`
* Install ~/.tool-versions:
```
cut -d' ' -f1 $HOME/.tool-versions | xargs -I{} asdf plugin add {} || true`
asdf install
```
* Prepare 1password and 1password-cli (plus u2f packages for system authentication)
```
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
sudo apt update && sudo apt install 1password 1password-cli libpam-u2f pamu2fcfg
```
* Sign into 1password and check CLI
* Prepare Yubikey u2f
```
mkdir -p ~/.config/Yubico
pamu2fcfg -o pam://hostname -i pam://hostname > ~/.config/Yubico/u2f_keys
```
* Setup polkit auth (so chezmoi apply will prompt with polkit)
```
sed '/^auth       include      system-auth/i auth    sufficient    pam_u2f.so cue origin=pam://hostname appid=pam://hostname' /etc/pam.d/polkit-1 | sudo tee /etc/pam.d/polkit-1
```
* Ensure homebrew is installed (add as a run_once_before script)
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update
brew upgrade
```
* Apply chezmoi (scripts have been updated and should work fine or skip)
```
chezmoi init --apply --verbose gunzy83
# If there are issues:
chezmoi init
chezmoi update --verbose
# Once complete:
chezmoi git remote set-url origin "https://github.com/gunzy83/dotfiles"
```
* Install main apps:
  * https://wavebox.io/download?platform=linux -> https://download.wavebox.app/latest/stable/linux/deb (maybe a curl command with follow redirects?)
  * `wget https://api.inkdrop.app/download/linux/deb -O /tmp/inkdrop.deb && sudo dpkg -i /tmp/inkdrop.deb && rm /tmp/inkdrop.deb` (make a script that allows this to be run easily)
  * Go to notes in Inkdrop
* Reminders:
  * https://github.com/popey/unsnap
  * https://github.com/maximbaz/yubikey-touch-detector

## Notes for updates to scripts etc
