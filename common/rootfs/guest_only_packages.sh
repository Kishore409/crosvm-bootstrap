#! /bin/bash

###################################################################
#Packages installed in Guest only.
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

LOCAL_UNAME=test

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
echo "Installing needed system packages..."
# Install all system dependencies.
install_package docker
install_package docker.io
install_package docker-compose
install_package gzip
sudo usermod -aG sudo,audio,video,input,render,lp,docker $LOCAL_UNAME

