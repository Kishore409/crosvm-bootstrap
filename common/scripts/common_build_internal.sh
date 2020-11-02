#! /bin/bash

###################################################################
#Sanity checks the options passed to build scripts.
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

BUILD_TYPE=${1}
BUILD_TARGET=${2}
BUILD_CHANNEL=${3}
BUILD_ARCH=${4}

###############################################################################
##main()
###############################################################################

if [[ "$BUILD_TYPE" != "--clean" ]] && [[ "$BUILD_TYPE" != "--update" ]]; then
  echo "Invalid Build Type. Valid Values:--clean, --incremental Recieved:" $BUILD_TYPE
  exit 1
fi

if [[ "$BUILD_CHANNEL" != "--dev" ]] && [[ "$BUILD_CHANNEL" != "--stable" ]]; then
 echo "Invalid Build Channel. Valid Values: --dev, --stable, --all Recieved:" $BUILD_CHANNEL
 exit 1
fi

if [[ "$BUILD_TARGET" != "--release" ]] && [[ "$BUILD_TARGET" != "--debug" ]]; then
 echo "Invalid Build Channel. Valid Values: --release, --debug, --all. Recieved:" $BUILD_TYPE
 exit 1
fi

if [[ "$BUILD_ARCH" != "x86_64" ]] && [[ "$BUILD_ARCH" != "i386" ]]; then
 echo "Invalid Build Arch. Valid Values: x86_64, i386. Recieved:" $BUILD_ARCH
 exit 1
fi

echo "Passed parameters:----------------"
echo "BUILD_TYPE" $BUILD_TYPE
echo "BUILD_TARGET" $BUILD_TARGET
echo "BUILD_CHANNEL" $BUILD_CHANNEL
echo "BUILD_ARCH" $BUILD_ARCH
echo "------------------------------"

# print gcc environment
echo "C environment settings---------"
gcc -xc -E -v
echo "---------------------------------"
echo "C++ environment settings------------"
gcc -xc++ -E -v
echo "---------------------------------"

env
echo "---------------------------------"
