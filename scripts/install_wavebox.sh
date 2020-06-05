#!/bin/zsh
echo "Getting address of latest wavebox version..."
address=$(curl -Ls -o /dev/null -w %{url_effective} https://download.wavebox.app/latest/stable/linux/tar)
echo "Address is $address"
filename=$(basename $address)
echo "Filename to download is $filename"
version=$(echo $filename | sed -E 's/^.*_([0-9]+\.[0-9]+\.[0-9]+-[0-9]+)\.tar\.gz/\1/')
echo "Version of wavebox to download is $version"
folder=wavebox_$version
echo "Creating temp directory $HOME/projects/temp"
mkdir -p $HOME/projects/temp

if [ ! -d /opt/wavebox.io/$folder ]
then
	echo "Downloading wavebox..."
	curl -Ls -o $HOME/projects/temp/$filename $address
	echo "Extracting wavebox files to temporary folder $HOME/projects/temp..."
	tar -xf $HOME/projects/temp/Wavebox_10.0.179-2.tar.gz -C $HOME/projects/temp/
	echo "Ensuring install location (/opt/wavebox.io) exists..."
	sudo mkdir -p /opt/wavebox.io
	echo "Copying new wavebox files to install location..."
	sudo cp -R $HOME/projects/temp/$folder /opt/wavebox.io/$folder
	echo "Ensure symlink for application is in place..."
	sudo ln -snf /opt/wavebox.io/$folder /opt/wavebox.io/wavebox
	echo "Install desktop file for wavebox..."
	sudo cp $HOME/projects/temp/$folder/wavebox.desktop /usr/share/applications/
	echo "Clean up previous versions of wavebox..."
	sudo find /opt/wavebox.io -mindepth 1 -maxdepth 1 -type d ! -path "*/$folder" -exec rm -rv {} +
	echo "Clean up temporary files..."
	rm -rf $HOME/projects/temp/$filename $HOME/projects/temp/$folder
	echo "Installation complete!"
else
	echo "Version $version already installed. Exiting..."
fi
