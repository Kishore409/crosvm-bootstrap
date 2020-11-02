#! /bin/bash

###################################################################
#Generates rootfs used by all iamges.
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

###############################################################################
##main()
###############################################################################
mkdir temp
cd temp
../debootstrap --arch=amd64 --make-tarball=rootfs_container.tar focal . http://archive.ubuntu.com/ubuntu/ || true
echo "created host bootstrap"
rm -rf ../rootfs_container.tar || EXIT_CODE=$?
mv rootfs_container.tar ../
rm -rf ../debootstrap
mv debootstrap/debootstrap ../debootstrap
cd ..
rm -rf temp
