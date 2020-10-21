#! /bin/bash

# system-packages_internal.sh
# Install support packages and configure system.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

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

sudo apt update
sudo ldconfig
sudo ldconfig -p

install_package gedit
install_package steam
install_package firefox
install_package libqt5waylandclient5
install_package libqt5waylandcompositor5
install_package qtwayland5
#install_package gnome-session-wayland
install_package qtcreator
install_package libxcb-composite0-dev
install_package libxtst-dev
install_package libxfont-dev

sudo ldconfig
sudo ldconfig -p
