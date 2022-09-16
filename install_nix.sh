#!/bin/bash -e

echo "Creating temp directory..."
tmp_dir=$(mktemp -d)

echo "Getting URL for the latest nix installer..."
latest_installer_url=$(curl -Ls -o /dev/null -w %{url_effective} https://nixos.org/nix/install)

echo "Downloading the lastest installer and signature..."
curl -s -o $tmp_dir/install $latest_installer_url
curl -s -o $tmp_dir/install.asc "${latest_installer_url}.asc"

echo "Importing key and verifying installer script..."
gpg2 --keyserver hkps://keyserver.ubuntu.com --recv-keys B541D55301270E0BCF15CA5D8170B4726D7198DE
gpg2 --verify $tmp_dir/install.asc

echo "Starting nix install!"
sh $tmp_dir/install --daemon
