#! /bin/bash

# common.sh
# Generates base rootfs image which is used to create host and guest
# rootfs images.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BASE_PWD=${1}
COMPONENT_TARGET=${2:-"common"}
BUILD_TYPE=${3:-"--clean"} # Possible values: --clean, --incremental --really-clean
SIZE=${4:-"5000"}

LOCAL_PWD=$BASE_PWD/build
SOURCE_PWD=$BASE_PWD/source
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOG_DIR=$BASE_PWD/build/log/$COMPONENT_TARGET
SCRIPTS_DIR=$LOCAL_PWD/scripts
LOCAL_USER=test

# Rootfs Names
LOCAL_ROOTFS_BASE=rootfs_base
LOCAL_ROOTFS_MOUNT_DIR=rootfs_base-temp

if [[ "$COMPONENT_TARGET" == "guest" ]]; then
  LOCAL_ROOTFS_BASE=rootfs_guest
  LOCAL_ROOTFS_MOUNT_DIR=rootfs_guest-temp
fi

mkdir -p $BASE_PWD/build/images
mkdir -p $BASE_PWD/build/log/$COMPONENT_TARGET

source $SCRIPTS_DIR/$COMPONENT_TARGET/error_handler_internal.sh $LOG_DIR rootfs.log $LOCAL_PWD

destroy_base_rootfs_as_needed() {
if [ -e $LOCAL_ROOTFS_MOUNT_DIR ]; then
  if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/build > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/build
  fi

  if mount | grep $LOCAL_ROOTFS_MOUNT_DIR > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR
  fi

  rm -rf $LOCAL_ROOTFS_MOUNT_DIR
fi

if [ $BUILD_TYPE == "--really-clean" ]; then
  if [ -e $LOCAL_ROOTFS_BASE.lock ]; then
    rm $LOCAL_ROOTFS_BASE.lock
  fi

  if [ -e $LOCAL_ROOTFS_BASE.ext4 ]; then
  echo "destroying rootfs image----- \n";
    rm  $LOCAL_ROOTFS_BASE.ext4
  fi
fi
}

generate_base_rootfs() {
if [ -e $LOCAL_ROOTFS_BASE.ext4 ]; then
  echo "Base rootfs image already exists. Reusing it."
  return 0;
fi

if [ -e $LOCAL_ROOTFS_MOUNT_DIR ]; then
  rm -rf $LOCAL_ROOTFS_MOUNT_DIR
fi

if [ -e $LOCAL_ROOTFS_BASE.lock ]; then
  rm $LOCAL_ROOTFS_BASE.lock
fi

echo "Generating rootfs...."
dd if=/dev/zero of=$LOCAL_ROOTFS_BASE.ext4 bs=$SIZE count=1M
mkfs.ext4 $LOCAL_ROOTFS_BASE.ext4
mkdir $LOCAL_ROOTFS_MOUNT_DIR/

sudo mount $LOCAL_ROOTFS_BASE.ext4 $LOCAL_ROOTFS_MOUNT_DIR/
sudo $LOCAL_PWD/rootfs/debootstrap --arch=amd64 --unpack-tarball=$LOCAL_PWD/rootfs/rootfs_base.tar buster $LOCAL_ROOTFS_MOUNT_DIR/
sudo mount -t proc /proc $LOCAL_ROOTFS_MOUNT_DIR/proc
sudo mount -o bind /dev/shm $LOCAL_ROOTFS_MOUNT_DIR/dev/shm
sudo mount -o bind /dev/pts $LOCAL_ROOTFS_MOUNT_DIR/dev/pts

sudo mkdir -p $LOCAL_ROOTFS_MOUNT_DIR/scripts/$COMPONENT_TARGET
sudo mkdir -p $LOCAL_ROOTFS_MOUNT_DIR/scripts/rootfs
sudo cp $LOCAL_PWD/scripts/$COMPONENT_TARGET/*.sh $LOCAL_ROOTFS_MOUNT_DIR/scripts/$COMPONENT_TARGET/
sudo cp $BASE_PWD/rootfs/*.sh $LOCAL_ROOTFS_MOUNT_DIR/scripts/rootfs/

sudo chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash /scripts/rootfs/basic_setup.sh

echo "Installing needed system packages for host and vm"
sudo chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash -c "su - $LOCAL_USER -c /scripts/$COMPONENT_TARGET/system_packages_internal.sh"

sudo cp -rvf $LOCAL_PWD/config/default-config/common/* $LOCAL_ROOTFS_MOUNT_DIR/

if [[ "$COMPONENT_TARGET" == "guest" ]]; then
  sudo cp -rvf $LOCAL_PWD/config/default-config/guest/* $LOCAL_ROOTFS_MOUNT_DIR/
  sudo chroot $LOCAL_ROOTFS_MOUNT_DIR/ /bin/bash /scripts/$COMPONENT_TARGET/container_settings.sh
fi

echo "Rootfs ready..."
echo "rootfs generated" > $LOCAL_ROOTFS_BASE.lock
echo "Cleaningup build env..."
if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/build > /dev/null; then
  sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/build
fi

sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/proc
sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/dev/shm
sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR/dev/pts

if mount | grep $LOCAL_ROOTFS_MOUNT_DIR > /dev/null; then
  sudo umount -l $LOCAL_ROOTFS_MOUNT_DIR
fi

rm -rf $LOCAL_ROOTFS_MOUNT_DIR
}

cd $LOCAL_PWD/images/

destroy_base_rootfs_as_needed
generate_base_rootfs
