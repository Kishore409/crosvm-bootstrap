#! /bin/bash

# build-rootfs-builder-container.sh
# Set up build environment for docker container that generates Debian rootfs
# then calls docker build.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

COMPONENT_TARGET=${1:-"--none"}
BUILD_TYPE=${2:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${3:-"--all"}
BUILD_CHANNEL=${4:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${5:-"--release"} # Possible values: --release, --debug, --all

BASE_DIR=$PWD
LOCAL_REGENERATE=$COMPONENT_TARGET

# Ensure build directory is setup correctly.
if [ $COMPONENT_TARGET == "--rebuild-all" ] ; then
  rm -rf build/
fi

if [ ! -e $BASE_DIR/build ]; then
  mkdir $BASE_DIR/build
fi

if [ ! -e $BASE_DIR/build/rootfs ]; then
  cp -rf $BASE_DIR/rootfs build/rootfs
fi

if [ -e $BASE_DIR/build/config ]; then
  rm -rf $BASE_DIR/build/config
fi

if [ ! -e $BASE_DIR/build/containers ]; then
  mkdir $BASE_DIR/build/containers
fi

mkdir -p $BASE_DIR/build/config
cp -rf default-config $BASE_DIR/build/config

if [ -e $BASE_DIR/build/scripts/common ]; then
  rm -rf $BASE_DIR/build/scripts/common
fi

mkdir -p $BASE_DIR/build/scripts/common
cp -rf $BASE_DIR/common/scripts/*.* $BASE_DIR/build/scripts/common

if [ $COMPONENT_TARGET == "--rootfs" ] || [ $COMPONENT_TARGET == "--rebuild-all" ]; then
  # Create Base image. This will be used for Host and cloning source code.
  if bash rootfs/create_rootfs.sh $BASE_DIR 'common' '--really-clean'; then
    echo “Built rootfs with default usersetup.”
  else
    echo “Failed to built rootfs with default usersetup, exit status: $?”
    exit 1
  fi
fi

if [ $COMPONENT_TARGET == "--common-libraries" ] || [ $COMPONENT_TARGET == "--rebuild-all" ]; then
  if bash common/common_components_internal.sh $BASE_DIR $COMPONENT_TARGET $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET --false; then
    echo “Built all common libraries to be used by host and guest”
    LOCAL_REGENERATE='--rebuild-all'
  else
    echo “Failed to build common libraries to be used by host and guest. exit status: $?”
    exit 1
  fi
fi

if [[ "$COMPONENT_TARGET" == "--host" ]] || [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] || [[ "$LOCAL_REGENERATE" == "--rebuild-all" ]]; then
  if [ -e $BASE_DIR/build/scripts/host ]; then
    rm -rf $BASE_DIR/build/scripts/host
  fi

  mkdir -p $BASE_DIR/build/scripts/host
  cp -rf $BASE_DIR/host/scripts/*.* $BASE_DIR/build/scripts/host

  # Create Base image. This will be used for Host and cloning source code.
  if bash host/build_host_internal.sh $BASE_DIR $LOCAL_REGENERATE $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
    echo “Built host rootfs.”
      echo "Preparing to create docker image...."
  cd $BASE_DIR/build/images
  if [ ! -e rootfs_host.ext4 ]; then
    echo "Cannot find rootfs_host.ext4 file. Please check the build...."
    exit 1
  fi

  if [[ "$(docker images -q intel_host 2> /dev/null)" != "" ]]; then
    docker rmi -f intel_host:latest
  fi
  
  if mount | grep intel_host > /dev/null; then
    sudo umount -l intel_host
  fi
  rm -rf intel_host
  mkdir intel_host
  sudo mount rootfs_host.ext4 intel_host
  sudo tar -C intel_host -c . | sudo docker import - intel_host
  sudo umount -l intel_host
  rm -rf intel_host
  else
    echo “Failed to build host rootfs. exit status: $?”
    exit 1
  fi
fi

cd $BASE_DIR/
UPDATE_CONTAINER='--false'

if [[ "$COMPONENT_TARGET" == "--guest" ]]; then
  UPDATE_CONTAINER='--true'
fi

if [[ "$COMPONENT_TARGET" == "--game-fast" ]] || [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] || [[ "$LOCAL_REGENERATE" == "--rebuild-all" ]]; then
  if [ -e $BASE_DIR/build/scripts/game_fast ]; then
    rm -rf $BASE_DIR/build/scripts/game_fast
  fi

  mkdir -p $BASE_DIR/build/scripts/game_fast
  cp -rf $BASE_DIR/game_fast/scripts/*.* $BASE_DIR/build/scripts/game_fast

  # Create Base image. This will be used for Host and cloning source code.
  if bash game_fast/build_game_fast.sh $BASE_DIR $LOCAL_REGENERATE $BUILD_TYPE $COMPONENT_ONLY_BUILDS $BUILD_CHANNEL $BUILD_TARGET; then
    echo “Built Game Fast.”
    UPDATE_CONTAINER='--true'
  else
    echo “Failed to build Game Fast Container. exit status: $?”
    exit 1
  fi
fi

if [[ "$UPDATE_CONTAINER" == "--true" ]] || [[ "$COMPONENT_TARGET" == "--guest" ]] || [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] || [[ "$LOCAL_REGENERATE" == "--rebuild-all" ]]; then
  if [ -e $BASE_DIR/build/scripts/guest ]; then
    rm -rf $BASE_DIR/build/scripts/guest
  fi

  mkdir -p $BASE_DIR/build/scripts/guest
  cp -rf $BASE_DIR/guest/scripts/*.* $BASE_DIR/build/scripts/guest/
  RECREATE_GUEST_ROOTFS=0
  
  if [[ "$BUILD_TYPE" == "--really-clean" ]] && [[ "$COMPONENT_TARGET" == "--guest" ]]; then
    RECREATE_GUEST_ROOTFS=1
  fi

  if [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] || [[ "$LOCAL_REGENERATE" == "--rebuild-all" ]] || [[ $RECREATE_GUEST_ROOTFS == '1' ]] || [[ ! -e $BASE_DIR/build/images/rootfs_guest.ext4 ]]; then
    if bash rootfs/create_rootfs.sh $BASE_DIR 'guest' '--really-clean' '30000'; then
      echo “Built guest with default usersetup.”
    else
      echo “Failed to built rootfs with default usersetup, exit status: $?”
      exit 1
    fi
  fi

  # Create Base image. This will be used for Host and cloning source code.
  if bash guest/build_guest_internal.sh $BASE_DIR $BUILD_TYPE $UPDATE_CONTAINER; then
    echo “Updated containers in guest rootfs.”
  else
    echo “Failed to build guest rootfs. exit status: $?”
    exit 1
  fi
fi

if [[ "$COMPONENT_TARGET" == "--kernel" ]] || [[ "$COMPONENT_TARGET" == "--rebuild-all" ]] ; then
  echo "Preparing to build Kernel...."
  LOCAL_BUILD_CHANNEL=stable
  if [ $BUILD_CHANNEL == "--dev" ]; then
    LOCAL_BUILD_CHANNEL=dev
  fi

  cd $BASE_DIR/source/$LOCAL_BUILD_CHANNEL/drivers/kernel/
  if [ $BUILD_TYPE == "--clean" ]; then
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
fi
