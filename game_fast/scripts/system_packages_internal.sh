#! /bin/bash

# system-packages_internal.sh
# Install support packages and configure system.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

echo "Checking if 32 bit and 64 bit architecture is supported ..."

if [ "x$(dpkg --print-foreign-architectures)" != "xi386" ]; then
  echo "Failed to add 32 bit architecture."
  exit 2
fi


echo "Installing needed system packages..."
function install_package() {
package_name="${1}"
if [ ! "$(dpkg -s $package_name)" ]; then
  echo "installing:" $package_name "----------------"
  sudo apt-get install -y  --no-install-recommends --no-install-suggests $package_name
  sudo apt-mark hold $package_name
  echo "---------------------"
else
  echo $package_name "is already installed."
fi
}

function install_package_i386() {
package_name="${1}"
if [ ! "$(dpkg -s $package_name:i386)" ]; then
  echo "installing:" $package_name:i386 "----------------"
  sudo apt-mark unhold $package_name
  sudo apt-get install -y  --no-install-recommends --no-install-suggests $package_name:i386
  sudo apt-mark hold $package_name:i386
  echo "---------------------"
else
  echo $package_name:i386 "is already installed."
fi
}

sudo apt update
sudo ldconfig
sudo ldconfig -p

wget http://archive.ubuntu.com/ubuntu/pool/main/j/json-c/libjson-c3_0.12.1-1.3ubuntu0.3_amd64.deb
apt install ./libjson-c3_0.12.1-1.3ubuntu0.3_amd64.deb
install_package libprocps-dev
install_package libkmod-dev
install_package libgsl-dev
install_package libasound2-dev
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
#install_package gnome-session-wayland
install_package qtcreator
install_package gdb

ln -s /usr/lib/x86_64-linux-gnu/libprocps.so.8 /usr/lib/x86_64-linux-gnu/libprocps.so.6

sudo ldconfig
sudo ldconfig -p
