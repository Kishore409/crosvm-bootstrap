#! /bin/bash

###################################################################
#Generates base rootfs image which is used to create host and guest
###################################################################

###### exit on any script line that fails ########################
set -o errexit
###### bail on any unitialized variable reads ####################
set -o nounset
###### bail on failing commands before last pipe #################
set -o pipefail
###### Use this to ignore Errors for certian commands ###########
EXIT_CODE=0

BASE_PWD=${1}
COMPONENT_TARGET=${2:-"--host"}
BUILD_TYPE=${3:-"--clean"} # Possible values: --all/clean/update
SIZE=${4:-"5000"}

LOCAL_PWD=$BASE_PWD/build
SOURCE_PWD=$BASE_PWD/source
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOG_DIR=$BASE_PWD/build/log/${COMPONENT_TARGET:2}
SCRIPTS_DIR=$LOCAL_PWD/scripts
LOCAL_USER=test

mkdir -p $BASE_PWD/build/images
mkdir -p $LOG_DIR

source $SCRIPTS_DIR/common/error_handler_internal.sh $LOG_DIR rootfs.log $LOCAL_PWD $COMPONENT_TARGET

###############################################################################
##cleanup_build()
###############################################################################

cleanup_build() {
	echo "Cleaning build env..."
	source $SCRIPTS_DIR/common/handle_mount_umount.sh 'unmount' $LOCAL_PWD $COMPONENT_TARGET $SOURCE_PWD
}

###############################################################################
##cleanup_base_rootfs()
###############################################################################
cleanup_base_rootfs() {
	cleanup_build
	
	if [ $BUILD_TYPE == "--really-clean" ]; then
		if [ -e $ROOTFS_COMMON.lock ]; then
			rm $ROOTFS_COMMON.lock || EXIT_CODE=$?
		fi

		if [ -e $ROOTFS_COMMON.ext4 ]; then
			echo "destroying rootfs image----- \n";
			rm  $ROOTFS_COMMON.ext4 || EXIT_CODE=$?
		fi
	fi
}

###############################################################################
##generate_base_rootfs()
###############################################################################
generate_base_rootfs() {
	echo "ROOTFS_COMMON:" $ROOTFS_COMMON
	echo "ROOTFS_COMMON_MOUNT_DIR:" $ROOTFS_COMMON_MOUNT_DIR
	if [ -e $ROOTFS_COMMON.ext4 ]; then
		echo "Base rootfs image already exists. Reusing it."
		return 0;
	fi

	echo "Generating rootfs...."
	dd if=/dev/zero of=$ROOTFS_COMMON.ext4 bs=$SIZE count=1M
	mkfs.ext4 $ROOTFS_COMMON.ext4
	echo "Gar check $PWD"
	ls -la
	echo "GAR--2=source $SCRIPTS_DIR/common/handle_mount_umount.sh 'mount' $LOCAL_PWD $COMPONENT_TARGET $SOURCE_PWD --true --true"
	# No need for any system mounts as these will be over-riden when rootfs is installed in the next step.
	source $SCRIPTS_DIR/common/handle_mount_umount.sh 'mount' $LOCAL_PWD $COMPONENT_TARGET $SOURCE_PWD --true --true

	echo "GAR--3= sudo $LOCAL_PWD/rootfs/debootstrap --arch=amd64 --unpack-tarball=$LOCAL_PWD/rootfs/rootfs_container.tar focal $ROOTFS_COMMON_MOUNT_DIR/"
	sudo $LOCAL_PWD/rootfs/debootstrap --arch=amd64 --unpack-tarball=$LOCAL_PWD/rootfs/rootfs_container.tar focal $ROOTFS_COMMON_MOUNT_DIR/
	
	# Remount to have valid /proc system mounts.
	source $SCRIPTS_DIR/common/handle_mount_umount.sh 'unmount' $LOCAL_PWD $COMPONENT_TARGET $SOURCE_PWD --true
	source $SCRIPTS_DIR/common/handle_mount_umount.sh 'mount' $LOCAL_PWD $COMPONENT_TARGET $SOURCE_PWD

	echo "GAR-4"
	sudo mkdir -p $ROOTFS_COMMON_MOUNT_DIR/scripts/rootfs
	sudo cp -rpvf $BASE_PWD/common/rootfs/*.sh $ROOTFS_COMMON_MOUNT_DIR/scripts/rootfs/

	echo "GAR-5"
	sudo chroot $ROOTFS_COMMON_MOUNT_DIR/ /bin/bash /scripts/rootfs/basic_setup.sh

	sudo cp -rpvf $LOCAL_PWD/config/default-config/common/* $ROOTFS_COMMON_MOUNT_DIR/

	echo "Installing needed system packages...."
	sudo chroot $ROOTFS_COMMON_MOUNT_DIR/ /bin/bash -c "su - $LOCAL_USER -c /scripts/rootfs/common_system_packages.sh"

	if [[ "$COMPONENT_TARGET" != "--host" ]]; then
		echo "Installing needed applications...."
		sudo chroot $ROOTFS_COMMON_MOUNT_DIR/ /bin/bash -c "su - $LOCAL_USER -c /scripts/rootfs/common_application_packages.sh"
	else
		sudo chroot $ROOTFS_COMMON_MOUNT_DIR/ /bin/bash /scripts/rootfs/host_only_packages.sh
	fi

	if [[ "$COMPONENT_TARGET" == "--guest" ]]; then
		sudo chroot $ROOTFS_COMMON_MOUNT_DIR/ /bin/bash -c "su - $LOCAL_USER -c /scripts/rootfs/guest_only_packages.sh"
		sudo cp -rpvf $LOCAL_PWD/config/default-config/guest/* $ROOTFS_COMMON_MOUNT_DIR/
		sudo cp $BASE_PWD/guest/serial-getty@.service $ROOTFS_COMMON_MOUNT_DIR/lib/systemd/system/
	fi

	if [[ "$COMPONENT_TARGET" == "--container" ]]; then
		sudo cp -rpvf $LOCAL_PWD/config/default-config/container/* $ROOTFS_COMMON_MOUNT_DIR/
		sudo rm $ROOTFS_COMMON_MOUNT_DIR/etc/profile.d/system-compositor.sh

		sudo cp -rpvf $LOCAL_PWD/config/default-config/container/etc/profile.d/system-compositor.sh $ROOTFS_COMMON_MOUNT_DIR/etc/profile.d/
	fi
	
        # We need this here to reset any changes done by systemd.
	sudo chroot $ROOTFS_COMMON_MOUNT_DIR/ /bin/bash /scripts/rootfs/common_services.sh

	echo "Rootfs ready..."
	echo "rootfs generated" > $ROOTFS_COMMON.lock
}

###############################################################################
##main() 
###############################################################################

if [[ "$COMPONENT_TARGET" == "--container" ]] || [[ "$COMPONENT_TARGET" == "--host" ]]; then
	cd $LOCAL_PWD/containers/
else
	cd $LOCAL_PWD/images/
fi

cleanup_base_rootfs
generate_base_rootfs

echo "Cleaningup build env..."
cleanup_build
