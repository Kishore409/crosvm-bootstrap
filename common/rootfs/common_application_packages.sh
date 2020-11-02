#! /bin/bash

###################################################################
#Common packages installed in containers and guest.
###################################################################

###### exit on any script line that fails #########################
set -o errexit
###### bail on any unitialized variable reads #####################
set -o nounset
###### bail on failing commands before last pipe #################
set -o pipefail
###### Use this to ignore Errors for certian commands ###########
EXIT_CODE=0

######Globals ####################################################

#apt-get install -y software-properties-common
#add-apt-repository -y ppa:intel-opencl/intel-opencl

###############################################################################
##install_package()
###############################################################################
function install_package() {
	package_name="${1}"
	if [[ ! "$(dpkg -s $package_name)" ]]; then
  		echo "installing:" $package_name "----------------"
  		sudo apt-get install -y  --no-install-recommends --no-install-suggests $package_name
  		sudo apt-mark hold $package_name
  		echo "---------------------"
	else
  		echo $package_name "is already installed."
	fi
}

###############################################################################
##main()
###############################################################################

echo "Checking if 32 bit and 64 bit architecture is supported ..."

if [ "x$(dpkg --print-foreign-architectures)" != "xi386" ]; then
  echo "Failed to add 32 bit architecture."
  exit 2
fi

echo "Installing needed system packages..."
wget http://archive.ubuntu.com/ubuntu/pool/main/j/json-c/libjson-c3_0.12.1-1.3ubuntu0.3_amd64.deb
sudo apt install ./libjson-c3_0.12.1-1.3ubuntu0.3_amd64.deb
install_package libprocps-dev
install_package libkmod-dev
install_package libgsl-dev
install_package liboping-dev
install_package libxmlrpc-core-c3
install_package libxmlrpc-c++8-dev
install_package libjson-c-dev
install_package libdw-dev
install_package gedit
install_package steam
install_package firefox
install_package libqt5waylandclient5
install_package libqt5waylandcompositor5
install_package qtwayland5
install_package gnome-session-wayland
install_package qtcreator
install_package gdb

LOCAL_USER=$(whoami)

sudo ln -s /usr/lib/x86_64-linux-gnu/libprocps.so.8 /usr/lib/x86_64-linux-gnu/libprocps.so.6

sudo apt autoremove -y

sudo mkdir -p /etc/xdg/xdg-fast-game
sudo mkdir -p /usr/share/fast-game-wayland

if [[ ! -e /usr/share/X11/xkb/rules/evdev ]]; then
	sudo mkdir -p /usr/share/X11/xkb/rules/evdev
  	sudo ln -s /opt/stable/release/x86_64/share/X11/xkb/rules /usr/share/X11/xkb/rules/evdev
fi

if [[ ! -e /usr/bin/xkbcomp ]]; then
  	sudo mkdir -p /usr/bin/xkbcomp
	sudo ln -s /opt/stable/release/x86_64/bin/ /usr/bin/xkbcomp
fi

if [[ ! -e /run/user/${UID} ]]; then
	sudo mkdir -p /run/user/${UID}
fi

sudo chown -R $LOCAL_USER:$LOCAL_USER /run/user/${UID}

if [[ ! -e /run/user/${UID}/.Xauthority ]]; then
	touch /run/user/$UID/.Xauthority
fi

