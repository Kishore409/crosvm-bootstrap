#! /bin/bash

###################################################################
#Common packages installed in all rootfs.
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
##install_package_i386()
###############################################################################
function install_package_i386() {
	package_name="${1}"
	if [[ ! "$(dpkg -s $package_name:i386)" ]]; then
  		echo "installing:" $package_name:i386 "----------------"
  		sudo apt-mark unhold $package_name
  		sudo apt-get install -y  --no-install-recommends --no-install-suggests $package_name:i386
  		sudo apt-mark hold $package_name:i386
  		echo "---------------------"
	else
  		echo $package_name:i386 "is already installed."
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
install_package libxkbfile1
install_package libxkbfile-dev
install_package kmod
install_package protobuf-compiler
install_package g++
install_package xutils-dev
install_package autoconf
install_package nasm
install_package make
install_package python3-mako
install_package pciutils
install_package llvm
install_package libtool
install_package automake
install_package cmake
install_package pkg-config
install_package libatomic-ops-dev
install_package python3-setuptools
install_package python3-certifi
install_package libpixman-1-0
install_package libpixman-1-dev
install_package gpgv2
install_package libffi-dev
install_package bison
install_package flex
install_package libcap-dev
install_package libfdt-dev
install_package curl
install_package dh-autoreconf
install_package libsensors4-dev
install_package libssl-dev
install_package libelf-dev
install_package bc
install_package libinput-dev
install_package libudev1
install_package libzstd-dev
install_package libunwind-dev
install_package python3-distutils
install_package libfontenc-dev
install_package gcc-i686-linux-gnu
install_package g++-i686-linux-gnu
install_package libgcrypt20
install_package libgcrypt20-dev
install_package libgpg-error-dev
install_package libfreetype6
install_package libfreetype6-dev
install_package libfontenc-dev
install_package libexpat1-dev
install_package xsltproc
install_package libxml2-utils
install_package libtool-bin
install_package libxml2-dev
install_package libc6
install_package libc6-dev
install_package zlib1g
install_package xauth
install_package x11proto-dev
install_package libxau6
install_package libxcb-dri2-0
install_package libxcb-dri2-0-dev
install_package libxcb-dri3-0
install_package libxcb-dri3-dev
install_package xz-utils
install_package fontconfig
install_package fonts-liberation
install_package libxcb-glx0
install_package libxcb-glx0-dev
install_package libxcb-present0
install_package libxcb-present-dev
install_package libxcb-randr0
install_package libxcb-render0
install_package libxcb-record0
install_package libxcb-res0
install_package libxcb-composite0
install_package libxcb-damage0
install_package libxcb-dpms0
install_package libxcb-shape0
install_package libxcb-shm0
install_package libxcb-shm0-dev
install_package libxcb-sync1
install_package libxcb-xf86dri0
install_package libxcb-xfixes0
install_package libxcb-xinerama0
install_package libxinerama-dev
install_package libxcb-xinput0
install_package libxcb-xkb1
install_package libxcb-xkb-dev
install_package libxcb-xv0
install_package libxcb1
install_package libx11-6
install_package libx11-xcb1
install_package libx11-xcb-dev
install_package libx11-dev
install_package libxext6
install_package libxfixes3
install_package libxdamage1
install_package libxdamage-dev
install_package libxshmfence1
install_package libxshmfence-dev
install_package libxxf86vm1
install_package libxxf86vm-dev
install_package libxrender1
install_package libxrandr-dev
install_package libxdmcp6
install_package xkb-data
install_package libxtst6
install_package libxi6
install_package libxss1
install_package xterm
install_package libexpat1-dev
install_package libcairo2
install_package libcairo2-dev
#install_package libigc-dev 
install_package libxcb-composite0-dev
install_package libxtst-dev
install_package libxfont-dev
install_package libpixman-1-0
install_package libpixman-1-dev
install_package xfonts-utils
install_package xfonts-cyrillic
install_package xfonts-100dpi
install_package xfonts-75dpi
install_package xfonts-base
install_package net-tools
install_package libasound2-dev
install_package resolvconf

echo "Installing needed i386 system packages..."
install_package_i386 libxkbfile1
install_package_i386 libxkbfile-dev
install_package_i386 libunwind-dev
install_package_i386 libsensors4-dev
install_package_i386 libelf-dev
install_package_i386 libselinux1
install_package_i386 libselinux1-dev
install_package_i386 libudev-dev
install_package_i386 libfreetype6
install_package_i386 libfreetype6-dev
install_package_i386 libfontenc-dev
install_package_i386 libffi-dev
install_package_i386 libexpat1-dev
install_package_i386 libc6
install_package_i386 libc6-dev
install_package_i386 libxml2-dev
install_package_i386 zstd
install_package_i386 libzstd-dev
install_package_i386 libpciaccess-dev
install_package_i386 libx11-xcb-dev
install_package_i386 libxinerama-dev
install_package_i386 libxrandr-dev
install_package_i386 libxxf86vm-dev
install_package_i386 libxshmfence-dev
install_package_i386 libxdamage-dev
install_package_i386 libx11-xcb-dev
install_package_i386 libxcb-glx0
install_package_i386 libxcb-glx0-dev
install_package_i386 libxcb-present0
install_package_i386 libxcb-present-dev
install_package_i386 libxcb-shm0
install_package_i386 libxcb-shm0-dev
install_package_i386 libxcb-dri2-0
install_package_i386 libxcb-dri2-0-dev
install_package_i386 libxcb-dri3-0
install_package_i386 libxcb-dri3-dev
install_package_i386 libxcb-xkb1
install_package_i386 libxcb-xkb-dev
install_package_i386 libcairo2
install_package_i386 libcairo2-dev
install_package_i386 libxtst-dev
install_package_i386 libxtst6
install_package_i386 libgtk2.0-0
install_package_i386 libgdk-pixbuf2.0
install_package_i386 libpulse-dev
install_package_i386 libasound2
install_package_i386 libasound2-dev
install_package_i386 libbz2-dev
install_package_i386 libvdpau-dev
install_package_i386 libopenal1

sudo apt autoremove -y

