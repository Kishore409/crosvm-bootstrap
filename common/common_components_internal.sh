#! /bin/bash

# common_components.sh
# Compiles all common packages needde by Guest and Host.
# Creates temporary image which is to be used for Guest
# and Host side.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BASE_PWD=${1}
COMPONENT_TARGET=${2:-"none"}
BUILD_TYPE=${3:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${4:-"--all"}
BUILD_CHANNEL=${5:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${6:-"--release"} # Possible values: --release, --debug, --all

LOCAL_PWD=$BASE_PWD/build
SOURCE_PWD=$BASE_PWD/source
LOCAL_BUILD_TYPE=$BUILD_TYPE
LOCAL_COMPONENT_ONLY_BUILDS=$COMPONENT_ONLY_BUILDS
LOG_DIR=$BASE_PWD/build/log/$COMPONENT_TARGET
SCRIPTS_DIR=$LOCAL_PWD/scripts

# Rootfs Names
LOCAL_ROOTFS_COMMON=rootfs_host
LOCAL_ROOTFS_COMMON_MOUNT_DIR=rootfs_host-temp


if [[ "$COMPONENT_TARGET" == "game-fast" ]]; then
  LOCAL_ROOTFS_COMMON=rootfs_game_fast
  LOCAL_ROOTFS_COMMON_MOUNT_DIR=$LOCAL_ROOTFS_COMMON-temp
fi

if [[ "$LOCAL_BUILD_TYPE" == "--really-clean" ]]; then
  LOCAL_BUILD_TYPE="--clean"
fi

mkdir -p $LOG_DIR

source $SCRIPTS_DIR/common/error_handler_internal.sh $LOG_DIR $COMPONENT_TARGET.log $LOCAL_PWD $COMPONENT_TARGET

if bash common/scripts/common_checks_internal.sh $LOCAL_PWD $SOURCE_PWD $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
  echo “Preparing to build dependencies for $COMPONENT_TARGET...”
else
  echo “Failed to find needed dependencies, exit status: $?”
  exit 1
fi

cleanup_build_env() {
if [ -e $LOCAL_ROOTFS_COMMON_MOUNT_DIR ]; then
  if mount | grep $LOCAL_ROOTFS_COMMON_MOUNT_DIR/build > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
  fi

  if mount | grep $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
  fi

  if mount | grep $LOCAL_ROOTFS_COMMON_MOUNT_DIR > /dev/null; then
    sudo umount -l $LOCAL_ROOTFS_COMMON_MOUNT_DIR
  fi

  rm -rf $LOCAL_ROOTFS_COMMON_MOUNT_DIR
fi
}

setup_build_env() {
if [ ! -e $LOCAL_ROOTFS_COMMON.ext4 ]; then
  echo "Cannot find chroot..."
  exit 1
fi

mkdir -p $LOCAL_ROOTFS_COMMON_MOUNT_DIR
sudo mount $LOCAL_ROOTFS_COMMON.ext4 $LOCAL_ROOTFS_COMMON_MOUNT_DIR/

if [ -e $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common ]; then
  sudo rm -rf $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
fi

if [ -e $LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common ]; then
  sudo rm -rf $LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common
fi

sudo mkdir -p $LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common
echo "COpying--------------------" $LOCAL_ROOTFS_COMMON_MOUNT_DIR
sudo cp -v $LOCAL_PWD/scripts/common/*.sh $LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common/

sudo mkdir -p $LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
sudo mkdir -p $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
sudo mount --rbind $SOURCE_PWD $LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
sudo mount --rbind $BASE_PWD/build/log/$COMPONENT_TARGET $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
}

building_component() {
component="${1}"
ls -a $LOCAL_ROOTFS_COMMON_MOUNT_DIR/scripts/common/
if sudo chroot $LOCAL_ROOTFS_COMMON_MOUNT_DIR/ /bin/bash /scripts/common/main.sh $LOCAL_BUILD_TYPE $COMPONENT_TARGET $component $BUILD_CHANNEL $BUILD_TARGET; then
  echo "Built------------" $component
else
  exit 1
fi
}

cd $LOCAL_PWD/containers/
setup_build_env

echo "Building components."
  if [[ "$LOCAL_COMPONENT_ONLY_BUILDS" == "--all" ]] || [[ "$LOCAL_COMPONENT_ONLY_BUILDS" == "--x11" ]]; then
    building_component "--x11"
  fi

  if [[ "$LOCAL_COMPONENT_ONLY_BUILDS" == "--all" ]] || [[ "$LOCAL_COMPONENT_ONLY_BUILDS" == "--wayland" ]]; then
    building_component "--wayland"
  fi

if [[ "$LOCAL_COMPONENT_ONLY_BUILDS" == "--all" ]] || [[ "$LOCAL_COMPONENT_ONLY_BUILDS" == "--drivers" ]]; then
  building_component "--drivers"
fi

cleanup_build_env
