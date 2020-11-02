#! /bin/bash

############ exit on any script line that fails###############################
set -o errexit
############ bail on any unitialized variable reads###########################
set -o nounset
############ bail on failing commands before last pipe########################
set -o pipefail


###################GLOBAL's####################################################
BASE_DIR=$PWD
#####BUILD_TYPE --all/--clean/--update
BUILD_TYPE="--none"
#####COMPONENT_TARGET --host/--guest/--kernel/--none
COMPONENT_TARGET="--none"
#####SUB COMPONENT TARGET########
SUB_COMPONENT_TARGET="--all"
#####BUILD_CHANNEL --dev/--stable
BUILD_CHANNEL="--stable"
#####BUILD_TARGET --release/--debug
BUILD_TARGET="--release"

###########Globals to be shared with other scripts#############################
export BUILD_OUTPUT_1="$BASE_DIR/images/rootfs_host.ext4"
export BUILD_OUTPUT_1_LOCK="$BASE_DIR/images/rootfs_host.lock"
export BUILD_OUTPUT_2="$BASE_DIR/containers/rootfs_guest.ext4"
#export BUILD_OUTPUT_2_LOCK="$BASEDIR/containers/rootfs_guest.lock"
export BUILD_OUTPUT_3="$BASE_DIR/images/vmlinux"
export BUILD_OUTPUT_3_LOCK="$BASE_DIR/images/vmlinux.lock"

###############################################################################
# Help
###############################################################################
Help()
{
	#Display Help
	echo "Usage: build.sh [-b|c|s] [params]"
	echo "-b   --all|clean|update"
	echo "-c   --host|guest|container|kernel"
	echo "-c   --host    		-s   --x11/wayland/drivers/vm"
	echo "-c   --guest   		-s   --x11/wayland/drivers/compositor"
	exit 1
}

###############################################################################
# Parseoptarg()
###############################################################################
Parseoptarg()
{

	case "$1" in
		'--host' )
				echo "Valid argument-2 $1"
				if [ "$2" == "--x11" ] || [ "$2" == "--wayland" ] || [ "$2" == "--drivers" ]\
					|| [ "$2" == "--vm" ] || [ "$2" == "--all" ]; then
					echo "Valid argument-3 passed $2"
				else
					echo "Invalid argument-3 passed $2"
				        Help
				fi
				;;
		'--guest' )
				echo "Valid argument-2 $1"
				if [ "$2" == "--x11" ] || [ "$2" == "--wayland" ] || [ "$2" == "--drivers" ]\
					|| [ "$2" == "--compositor" ] || [ "$2" == "--all" ]; then
					echo "Valid argument-3 passed $2"
				else
					echo "Invalid argument-3 passed $2"
					Help
				fi
				;;
		'--container' )
				echo "Valid argument-2 $1"
				if [ "$2" == "--all" ]; then
					echo "Valid argument-3 passed $2"
				else
					echo "Invalid argument-3 passed $2"
					Help
				fi
				;;
		'--kernel' )
				echo "Valid argument-2 $1"
				if [ "$2" == "--all" ]; then
					echo "Valid argument-3 passed $2"
				else
					echo "Invalid argument-3 passed $2"
					Help
				fi
				;;
		*)
				echo "Invalid argument-2 passed $1"
				Help
				;;
	esac
}

###############################################################################
# Parseoptions
###############################################################################
Parseoptions()
{
	case "$1" in
		'--all' )
				echo "Valid argument-1 passed $1"
				;;
		'--clean' )
				echo "Valid argument-1 passed $1"
				;;
		'--update' )
				echo "Valid argument-1 passed $1"
				;;
		'--none' )
				Parseoptarg $2 $3
				BUILD_TYPE="--clean"
				;;
		*)
				echo "Invalid argument-1 passed $1"
				Help
				;;
	esac
}

###############################################################################
# Setup build env
###############################################################################
Envsetup()
{
	local buildtype="$1"
	local component="$2"
	local basedir="$3"

	if [ $buildtype == "--clean" ] && [ $component == "--none" ]; then
		rm -rf $basedir/build/
		exit 1
	fi

	if [ $buildtype == "--all" ] ; then
		rm -rf $basedir/build/
	fi

	if [ ! -e $basedir/build ]; then
		mkdir $basedir/build
	fi

	mkdir -p $basedir/build/containers
	mkdir -p $basedir/build/config
	mkdir -p $basedir/build/scripts/common

	cp -rf $basedir/common/rootfs  $basedir/build
	cp -rf $basedir/default-config $basedir/build/config
	cp -rf $basedir/common/scripts/*.* $basedir/build/scripts/common
}


###############################################################################
# Main
###############################################################################

if [ $# -eq 0 ] ; then
        Help
fi


while getopts ":b:c:s:" option; do
   case $option in
	 b )
		BUILD_TYPE=$OPTARG;;
	 c )
		COMPONENT_TARGET=$OPTARG;;
	 s )
		SUB_COMPONENT_TARGET=$OPTARG;;
	 * )
		Help;;
   esac
done

########Parse options ######################################################
Parseoptions $BUILD_TYPE $COMPONENT_TARGET $SUB_COMPONENT_TARGET

#########Setup environment when BUILD_TYPE=--all/--clean#####################
Envsetup $BUILD_TYPE $COMPONENT_TARGET $BASE_DIR

##########################Build Host Image#####################################
if [ "$BUILD_TYPE" != "--clean" ] ||  [ $COMPONENT_TARGET == "--host" ]; then
	COMPONENT_TARGET="--host"

	if [[ "$(docker images -q intel_host 2> /dev/null)" != "" ]]; then
		docker rmi -f intel_host:latest
	fi

	if bash common/common_components_internal.sh $BASE_DIR $BUILD_TYPE $COMPONENT_TARGET $SUB_COMPONENT_TARGET $BUILD_CHANNEL $BUILD_TARGET; then
		echo “Host Image: Operation $BUILD_TYPE/$COMPONENT_TARGET Success.”
	else
		echo “Failed to build Host Image, exit status: $?”
		exit 1
	fi
fi

##########################Build Container Image#####################################
if [ "$BUILD_TYPE" != "--clean" ] ||  [ $COMPONENT_TARGET == "--container" ]; then
	COMPONENT_TARGET="--container"

	if bash common/common_components_internal.sh $BASE_DIR $BUILD_TYPE $COMPONENT_TARGET $SUB_COMPONENT_TARGET $BUILD_CHANNEL $BUILD_TARGET; then
		echo “Container Image: Operation $BUILD_TYPE/$COMPONENT_TARGET Success.”
	else
		echo “Failed to build Container Image, exit status: $?”
		exit 1
	fi
fi

##########################Build Guest Image#########################################
if [ "$BUILD_TYPE" != "--clean" ] ||  [ $COMPONENT_TARGET == "--guest" ]; then
        COMPONENT_TARGET="--guest"

        if bash common/common_components_internal.sh $BASE_DIR $BUILD_TYPE $COMPONENT_TARGET $SUB_COMPONENT_TARGET $BUILD_CHANNEL $BUILD_TARGET; then
                echo “Guest Image: Operation $BUILD_TYPE/$COMPONENT_TARGET Success.”
        else
                echo “Failed to build Guest Image, exit status: $?”
                exit 1
        fi
fi

##########################Build Kernel Image#########################################
if [ "$BUILD_TYPE" != "--clean" ] ||  [ $COMPONENT_TARGET == "--kernel" ]; then
	COMPONENT_TARGET="--kernel"

        if bash common/common_components_internal.sh $BASE_DIR $BUILD_TYPE $COMPONENT_TARGET $SUB_COMPONENT_TARGET $BUILD_CHANNEL $BUILD_TARGET; then
                echo “Kernel Image: Operation $BUILD_TYPE/$COMPONENT_TARGET Success.”
        else
                echo “Failed to build Kernel Image, exit status: $?”
                exit 1
        fi
fi

#############################INSTALL BUILD IMAGES###################################
if [[ -e "$BASE_DIR/build/containers/rootfs_host.ext4" ]] && [[ -e "$BASE_DIR/build/containers/rootfs_game_fast.ext4" ]] && [[ -e "$BASE_DIR/build/images/rootfs_guest.ext4" ]] && [[ -e "$BASE_DIR/build/images/vmlinux" ]]; then
        mkdir -p $BASE_DIR/build/launch
        mkdir -p $BASE_DIR/build/launch/images
        mkdir -p $BASE_DIR/build/launch/docker/
        mkdir -p $BASE_DIR/build/launch/shared/
        mkdir -p $BASE_DIR/build/launch/shared/containers
        mkdir -p $BASE_DIR/build/launch/shared/guest
        mkdir -p $BASE_DIR/build/launch/shared/guest/igt
        cd $BASE_DIR/build/launch
        cp $BASE_DIR/launcher.sh .
        cp -rpvf $BASE_DIR/launch .
        cp $BASE_DIR/launch/docker/start.dockerfile $BASE_DIR/build/launch/docker/Dockerfile-start
        cp $BASE_DIR/launch/docker/stop.dockerfile $BASE_DIR/build/launch/docker/Dockerfile-stop
        cp -rpvf $BASE_DIR/tools/*.sh $BASE_DIR/build/launch/launch/scripts/
        cp $BASE_DIR/build/containers/rootfs_host.ext4 images/
        cp $BASE_DIR/build/containers/rootfs_game_fast.ext4 $BASE_DIR/build/launch/shared/containers/
        cp $BASE_DIR/build/images/rootfs_guest.ext4 images/
        cp $BASE_DIR/build/images/vmlinux images/
fi
