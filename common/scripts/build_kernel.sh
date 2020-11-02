#! /bin/bash

###################################################################
#Sanity checks the options passed from build.sh.
###################################################################

###### exit on any script line that fails #########################
set -o errexit
###### bail on any unitialized variable reads #####################
set -o nounset
###### bail on failing commands before last pipe #################
set -o pipefail
###### Use this to ignore Errors for certian commands ###########

######Globals ####################################################

BASE_DIR=${1}
BUILD_TYPE=${2:-"--clean"} # Possible values: --all/clean/update
BUILD_CHANNEL=${3:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${4:-"--release"} # Possible values: --release, --debug, --all

###############################################################################
##main()
###############################################################################

cd $BASE_DIR/source/${BUILD_CHANNEL:2}/drivers/kernel/
if [[ $BUILD_TYPE == "--clean" ]] || [[ $BUILD_TYPE == "--all" ]]; then
	make clean || true
fi

make x86_64_defconfig
make

if [ -f vmlinux ]; then
	mkdir -p $BASE_DIR/build/images/
	if [ -e $BASE_DIR/build/images/vmlinux ]; then
		rm $BASE_DIR/build/images/vmlinux
	fi

	mv vmlinux $BASE_DIR/build/images/
fi
