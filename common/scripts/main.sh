#! /bin/bash

###################################################################
#Build's Driver packages.
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

BUILD_TYPE=$1
COMPONENT_TARGET=$2
COMPONENT_ONLY_BUILDS=$3
BUILD_CHANNEL=$4
BUILD_TARGET=$5

LOCAL_DIRECTORY_PREFIX=/build
LOCAL_BUILD_CHANNEL="--dev"
LOCAL_BUILD_TARGET="--release"
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOG_DIR=/build/log/${COMPONENT_TARGET:2}
SCRIPTS_DIR=/scripts/common/

echo "main: Recieved Arguments...."$COMPONENT_TARGET $COMPONENT_ONLY_BUILDS
if bash $SCRIPTS_DIR/common_checks_internal.sh $LOCAL_DIRECTORY_PREFIX /build $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
	echo “Preparing for build...”
else
	echo “Invalid build options, exit status: $?”
	exit 1
fi
echo "--------------------------"

if [ $BUILD_CHANNEL == "--stable" ]; then
	LOCAL_BUILD_CHANNEL="--stable"
else
	if [ $BUILD_CHANNEL == "--all" ]; then
		LOCAL_BUILD_CHANNEL="--all"
	fi
fi

if [ $BUILD_TARGET == "--debug" ]; then
	LOCAL_BUILD_TARGET="--debug"
else
	if [ $BUILD_TARGET == "--all" ]; then
		LOCAL_BUILD_TARGET="--all"
	fi
fi

echo "Directory Prefix being used:" $LOCAL_DIRECTORY_PREFIX

if [ $LOCAL_BUILD_CHANNEL == "--all" ]; then
	echo "Build Tree: dev, Stable"
fi

if [ $LOCAL_BUILD_CHANNEL == "--dev" ]; then
	echo "Build Tree: dev"
fi

if [ $LOCAL_BUILD_CHANNEL == "--stable" ]; then
	echo "Build Tree: Stable"
fi

if [ $LOCAL_BUILD_TARGET == "--all" ]; then
	echo "Build Target: Release, Debug"
fi

if [ $LOCAL_BUILD_TARGET == "--release" ]; then
	echo "Build Target: Release"
fi

if [ $LOCAL_BUILD_TARGET == "--debug" ]; then
	echo "Build Tree: Debug"
fi

echo "main: Using Arguments...."
echo "LOCAL_DIRECTORY_PREFIX:" $LOCAL_DIRECTORY_PREFIX
echo "LOCAL_BUILD_CHANNEL:" $LOCAL_BUILD_CHANNEL
echo "LOCAL_BUILD_TARGET:" $LOCAL_BUILD_TARGET
echo "LOCAL_BUILD_TYPE:" $LOCAL_BUILD_TYPE
echo "LOG_DIR:" $LOG_DIR
echo "--------------------------"

###############################################################################
##build_x11()
###############################################################################
build_x11() {
	if [ $COMPONENT_ONLY_BUILDS == "--x11" ] || [ $COMPONENT_ONLY_BUILDS == "--all" ]; then
  		build_target="${1}"
  		build_type="${2}"
  		channel="${3}"
  		arch="${4}"

  	if [ $LOCAL_BUILD_CHANNEL != $channel ] && [ $LOCAL_BUILD_CHANNEL != "--all" ]; then
    		return 0;
  	fi

  	if [ $LOCAL_BUILD_TARGET != $build_target ] && [ $LOCAL_BUILD_TARGET != "--all" ]; then
    		return 0;
 	 fi
  
  	if bash $SCRIPTS_DIR/build_x11_packages.sh $build_target $build_type $channel $arch; then
		echo “Finished building X11 Packages $build_target $build_type $channel $arch...”
	else
  		echo “Failed to build X11. $build_target $build_type $channel $arch, exit status: $?”
  		exit 1
	fi
fi
}

###############################################################################
##build_wayland()
###############################################################################
build_wayland() {
	if [ $COMPONENT_ONLY_BUILDS == "--wayland" ] || [ $COMPONENT_ONLY_BUILDS == "--all" ]; then
  		build_target="${1}"
  		build_type="${2}"
  		channel="${3}"
  		arch="${4}"

  		if [ $LOCAL_BUILD_CHANNEL != $channel ] && [ $LOCAL_BUILD_CHANNEL != "--all" ]; then
    			return 0;
  		fi

  		if [ $LOCAL_BUILD_TARGET != $build_target ] && [ $LOCAL_BUILD_TARGET != "--all" ]; then
    			return 0;
  		fi
  
		if bash $SCRIPTS_DIR/build_wayland_packages.sh $build_target $build_type $channel $arch; then
			echo “Finished building Wayland Packages $build_target $build_type $channel $arch...”
		else
  			echo “Failed to build Wayland. $build_target $build_type $channel $arch, exit status: $?”
  			exit 1
		fi
	fi
}

###############################################################################
##build_drivers()
###############################################################################
build_drivers() {
	if [ $COMPONENT_ONLY_BUILDS == "--drivers" ] || [ $COMPONENT_ONLY_BUILDS == "--all" ]; then
  		build_target="${1}"
  		build_type="${2}"
  		channel="${3}"
  		arch="${4}"

  		if [ $LOCAL_BUILD_CHANNEL != $channel ] && [ $LOCAL_BUILD_CHANNEL != "--all" ]; then
    			return 0;
  		fi

  		if [ $LOCAL_BUILD_TARGET != $build_target ] && [ $LOCAL_BUILD_TARGET != "--all" ]; then
    			return 0;
  		fi

		if bash $SCRIPTS_DIR/build_driver_packages.sh $build_target $build_type $channel $arch; then
			echo “Finished building Drivers $build_target $build_type $channel $arch...”
		else
  			echo “Failed to build Drivers. $build_target $build_type $channel $arch, exit status: $?”
  			exit 1
		fi
	fi
}

###############################################################################
##main()
###############################################################################

# Build all UMD and user space libraries.
#------------------------------------Dev Channel-----------"
echo "Building User Mode Graphics Drivers..."
#Debug
build_x11 --debug $LOCAL_BUILD_TYPE --dev x86_64
build_x11 --debug $LOCAL_BUILD_TYPE --dev i386
build_wayland --debug $LOCAL_BUILD_TYPE --dev x86_64
build_wayland --debug $LOCAL_BUILD_TYPE --dev i386
build_drivers --debug $LOCAL_BUILD_TYPE --dev x86_64
build_drivers --debug $LOCAL_BUILD_TYPE --dev i386

# Release Builds.
build_x11 --release $LOCAL_BUILD_TYPE --dev x86_64
build_x11 --release $LOCAL_BUILD_TYPE --dev i386
build_wayland --release $LOCAL_BUILD_TYPE --dev x86_64
build_wayland --release $LOCAL_BUILD_TYPE --dev i386
build_drivers --release $LOCAL_BUILD_TYPE --dev x86_64
build_drivers --release $LOCAL_BUILD_TYPE --dev i386
#----------------------------Dev Channel ends-----------------

#------------------------------------Stable Channel-----------"
#Debug
build_x11 --debug $LOCAL_BUILD_TYPE --stable x86_64
build_x11 --debug $LOCAL_BUILD_TYPE --stable i386
build_wayland --debug $LOCAL_BUILD_TYPE --stable x86_64
build_wayland --debug $LOCAL_BUILD_TYPE --stable i386
build_drivers --debug $LOCAL_BUILD_TYPE --stable x86_64
build_drivers --debug $LOCAL_BUILD_TYPE --stable i386

# Release Builds.
build_x11 --release $LOCAL_BUILD_TYPE --stable x86_64
build_x11 --release $LOCAL_BUILD_TYPE --stable i386
build_wayland --release $LOCAL_BUILD_TYPE --stable x86_64
build_wayland --release $LOCAL_BUILD_TYPE --stable i386
build_drivers --release $LOCAL_BUILD_TYPE --stable x86_64
build_drivers --release $LOCAL_BUILD_TYPE --stable i386
#----------------------------stable Channel ends-----------------

echo "Built all common libraries needed for host and guest!"
