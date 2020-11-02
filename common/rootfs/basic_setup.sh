#! /bin/bash

###################################################################
#Basic setup for any rootfs.
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
LOCAL_PASSWORD=test0000
LOCAL_uid=1000
LOCAL_gid=1000

###############################################################################
##install_package()
###############################################################################
echo "Installing needed system packages..."
function install_package() {
	package_name="${1}"
	if [[ ! "$(dpkg -s $package_name)" ]]; then
  		echo "installing:" $package_name "----------------"
  		apt-get install -y  --no-install-recommends --no-install-suggests $package_name
  		apt-mark hold $package_name
  		echo "---------------------"
	else
  		echo $package_name "is already installed."
	fi
}

###############################################################################
##main()
###############################################################################
echo "Checking if 32 bit and 64 bit architecture is supported ..."
dpkg --add-architecture i386
dpkg --configure -a

apt-get install -y software-properties-common
add-apt-repository multiverse

echo "Setting up locales"
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
apt install -y locales
echo "LC_ALL=en_US.UTF-8" >> /etc/environment
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
dpkg-reconfigure --frontend noninteractive locales

#apt-get install -y software-properties-common
#add-apt-repository -y ppa:intel-opencl/intel-opencl

echo "Checking if 32 bit and 64 bit architecture is supported1 ..."
apt update -y --no-install-recommends --no-install-suggests
apt upgrade -y --no-install-recommends --no-install-suggests

echo "Checking if 32 bit and 64 bit architecture is supported ..."

if [ "x$(dpkg --print-foreign-architectures)" != "xi386" ]; then
  echo "Failed to add 32 bit architecture."
  exit 2
fi

install_package sudo
install_package ssh
install_package git
install_package gcc
install_package libstdc++6
install_package ninja-build
install_package apt-utils
install_package wget
install_package iptables
install_package ca-certificates
install_package lsb-core

apt autoremove -y

echo "Installing Meson"
mkdir -p /intel
cd intel
git clone https://github.com/mesonbuild/meson
cd meson
git checkout origin/0.55
ln -s $PWD/meson.py /usr/bin/meson

# Make sure we have libc packages correctly installed
if [ "$(dpkg -s linux-libc-dev:amd64 | grep ^Version:)" !=  "$(dpkg -s linux-libc-dev:i386 | grep ^Version:)" ]; then
  echo "linux-libc-dev:amd64 and linux-libc-dev:i386 do have different versions!"
  echo "Please fix this after rootfs is generated."
fi
if [ "$(dpkg -s libc6-dev:amd64 | grep ^Version:)" !=  "$(dpkg -s libc6-dev:i386 | grep ^Version:)" ]; then
  echo "libc6-dev:amd64 and libc6-dev:i386 do have different versions!"
  echo "Please fix this after rootfs is generated."
fi

export uid=$LOCAL_uid gid=$LOCAL_gid
mkdir -p /home/$LOCAL_UNAME
echo "$LOCAL_UNAME:x:$uid:$gid:$LOCAL_UNAME,,,:/home/$LOCAL_UNAME:/bin/bash" >> /etc/passwd
echo "$LOCAL_UNAME:x:${uid}:" >> /etc/group
echo test:test0000 | chpasswd
echo "$LOCAL_UNAME ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$LOCAL_UNAME
chmod 0440 /etc/sudoers.d/$LOCAL_UNAME
chown $uid:$gid -R /home/$LOCAL_UNAME
export uid=$LOCAL_uid gid=$LOCAL_gid
echo "adding groups"
usermod -aG sudo,audio,video,input,render,lp $LOCAL_UNAME
#loginctl enable-linger $UNAME
ls -a /etc/skel/ 

if [ -e /etc/skel/ ]; then
  cp -RvT /etc/skel /home/$LOCAL_UNAME
fi

chown $uid:$gid -R /home/$LOCAL_UNAME

echo root:test0000 | chpasswd

mkdir -p /etc/sudoers.d

echo "127.0.1.1  game-fast" >> /etc/hosts

install_package libdbus-1-dev
install_package dbus
install_package dbus-user-session

echo "Default user setup.."
