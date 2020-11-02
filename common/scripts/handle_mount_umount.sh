#! /bin/bash

###################################################################
#Handle mount and umount operations for rootfs images.
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

MU_OPERATION=${1}
MU_MOUNT_DIR=${2}
MU_TARGET_COMPONENT=${3}
MU_SOURCE_PWD=${4}
MU_IGNORE_LOCK=${5:-"--false"}
MU_IGNORE_SYSTEM_MOUNT=${5:-"--false"}

echo "Mount/UnMount: Recieved Arguments...."
echo "OPERATION:" $MU_OPERATION
echo "MOUNT_DIR:" $MU_MOUNT_DIR
echo "TARGET_COMPONENT:" $MU_TARGET_COMPONENT
echo "SOURCE_PWD:" $MU_SOURCE_PWD
echo "IGNORE_LOCK:" $MU_IGNORE_LOCK
echo "IGNORE_SYSTEM_MOUNT:" $MU_IGNORE_SYSTEM_MOUNT
echo "--------------------------"

MU_LOCAL_ROOTFS_COMMON=rootfs_host

if [[ "$MU_TARGET_COMPONENT" == "--container" ]]; then
	MU_LOCAL_ROOTFS_COMMON=rootfs_game_fast
fi

MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR=$MU_MOUNT_DIR/containers/$MU_LOCAL_ROOTFS_COMMON-temp

if [[ "$MU_TARGET_COMPONENT" == "--guest" ]]; then
	MU_LOCAL_ROOTFS_COMMON=rootfs_guest
	MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR=$MU_MOUNT_DIR/images/$MU_LOCAL_ROOTFS_COMMON-temp
fi

export ROOTFS_COMMON=$MU_LOCAL_ROOTFS_COMMON
export ROOTFS_COMMON_MOUNT_DIR=$MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR

###############################################################################
##cleanup_mount()
###############################################################################
function cleanup_mount ()
{
	if [[ "$MU_OPERATION" == "unmount" ]]; then
		local MU_CURRENT_DIR=$PWD
		if [[ "$MU_TARGET_COMPONENT" == "--guest" ]]; then
			cd $MU_MOUNT_DIR/images/
    		else
      			cd $MU_MOUNT_DIR/containers/
    		fi

    		if [[ -e $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR ]]; then
      			if mount | grep $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/build > /dev/null; then
      				echo "unmounting" $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
        			sudo umount -l $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
      			fi

      			if mount | grep $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common > /dev/null; then
      				echo "unmounting" $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
        			sudo umount -l $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
      			fi
      			
      			if mount | grep $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/proc > /dev/null; then
        			echo "unmounting" $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/proc
        			sudo umount -l $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/proc
      			fi

      			if mount | grep $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/shm > /dev/null; then
        			echo "unmounting" $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/shm
        			sudo umount -l $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/shm
      			fi

      			if mount | grep $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/pts > /dev/null; then
        			echo "unmounting" $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/pts
        			sudo umount -l $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/pts
      			fi

      			if mount | grep $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR > /dev/null; then
      				echo "unmounting" $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR
        			sudo umount -l $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR
      			fi
      			
      			if [ -e $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common ]; then
      				echo "deleting" $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/log
  				sudo rm -rf $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/log
			fi

			if [ -e $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common ]; then
				echo "deleting" $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts
  				sudo rm -rf $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts
			fi
			
			if [ -e $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/build ]; then
  				sudo rm -rf $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
			fi

      			rm -rf $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR
		fi

		if [[ ! -e $MU_LOCAL_ROOTFS_COMMON.lock ]] && [[ -e $MU_LOCAL_ROOTFS_COMMON.ext4 ]] && [[ "$MU_IGNORE_LOCK" != "--true" ]]; then
			rm $MU_LOCAL_ROOTFS_COMMON.ext4
			echo "destroying rootfs image----- \n";
		fi
		cd $MU_CURRENT_DIR
	fi
}

###############################################################################
##setup_mount()
###############################################################################
setup_mount() {
	if [[ "$MU_OPERATION" == "mount" ]]; then
		local MU_CURRENT_DIR=$PWD
		if [[ "$MU_TARGET_COMPONENT" == "--guest" ]]; then
			cd $MU_MOUNT_DIR/images/
    		else
      			cd $MU_MOUNT_DIR/containers/
    		fi
    	
		if [ ! -e $MU_LOCAL_ROOTFS_COMMON.ext4 ]; then
  			echo "Cannot find chroot..."
  			exit 1
		fi
	
		mkdir -p $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR
		sudo mount $MU_LOCAL_ROOTFS_COMMON.ext4 $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/

		if [ -e $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common ]; then
  			sudo rm -rf $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/log
		fi

		if [ -e $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common ]; then
  			sudo rm -rf $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts
		fi

		sudo mkdir -p $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common
		sudo cp -v $MU_MOUNT_DIR/scripts/common/*.sh $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common/

		sudo mkdir -p $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
		sudo mkdir -p $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
		sudo mount --rbind $MU_SOURCE_PWD $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
		sudo mount --rbind $MU_MOUNT_DIR/log/${COMPONENT_TARGET:2} $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
	
		if [[ "$MU_IGNORE_SYSTEM_MOUNT" != "--true" ]]; then
			sudo mkdir -p $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/proc
			sudo mkdir -p $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/shm
			sudo mkdir -p $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/pts
			sudo mount -t proc /proc $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/proc
			sudo mount -o bind /dev/shm $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/shm
			sudo mount -o bind /dev/pts $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/pts
			if ! mount | grep $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/proc > /dev/null; then
        			echo "Proc not mounted..."
        			exit 1
      			fi
      		
      			if ! mount | grep $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/shm > /dev/null; then
        			echo "dev/shm not mounted..."
        			exit 1
      			fi
      		
      			if ! mount | grep $MU_LOCAL_ROOTFS_COMMON_MOUNT_DIR/dev/pts > /dev/null; then
        			echo "dev/pts not mounted..."
        			exit 1
      			fi
      		fi

		cd $MU_CURRENT_DIR
	fi
}

cleanup_mount
setup_mount
