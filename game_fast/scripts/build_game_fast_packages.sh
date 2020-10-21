#! /bin/bash

# package-builder.sh
# Builds all needed drivers, cros_vm and other needed packages.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BUILD_TARGET=${1:-"--release"}
BUILD_TYPE=${2:-"--incremental"}
BUILD_CHANNEL=${3:-"--stable"}
LOCAL_BUILD_TARGET=release
LOCAL_CHANNEL=stable

if /scripts/game_fast/common_build_internal.sh $BUILD_TYPE $BUILD_TARGET $BUILD_CHANNEL
then
  echo "Starting Build...."
else
  echo "Unable to setup proper build environment. Quitting..."
  exit 1
fi

if [ $BUILD_CHANNEL == "--dev" ]; then
LOCAL_CHANNEL=dev
fi

if [ $BUILD_TARGET == "--debug" ]; then
LOCAL_BUILD_TARGET=debug
fi

LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TARGET/x86_64
LOCAL_MESON_COMPILER_OPTIONS=""
LOCAL_LIBDIR=lib/x86_64-linux-gnu
LOCAL_COMPILER_OPTIONS=""
LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TARGET.x86_64

# Export environment variables
export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/include/:$LOCAL_CURRENT_WLD_PATH/include/libdrm/:$LOCAL_CURRENT_WLD_PATH/bin"
export ACLOCAL_PATH=$LOCAL_CURRENT_WLD_PATH/share/aclocal
export ACLOCAL="aclocal -I $ACLOCAL_PATH"
export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig:$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig
export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/bin"

# Set Working Build directory based on the channel.
WORKING_DIR=/build/$LOCAL_CHANNEL/drivers

echo "Working Directory:" $WORKING_DIR

cd /build

function mesonclean_asneeded() {
if [ $BUILD_TYPE == "--clean" ]; then
  if [ -d $LOCAL_MESON_BUILD_DIR ]; then
    rm -rf $LOCAL_MESON_BUILD_DIR
  fi
fi
}

echo "checking " $LOCAL_CURRENT_WLD_PATH/share/aclocal
mkdir -p $LOCAL_CURRENT_WLD_PATH/share/aclocal
if [ ! -d "$LOCAL_CURRENT_WLD_PATH/share/aclocal" ]; then
  echo "Failed to create" $LOCAL_CURRENT_WLD_PATH/share/aclocal
else
  echo $LOCAL_CURRENT_WLD_PATH/share/aclocal "exists"
fi


# Build xserver
echo "Building xserver............"
cd $WORKING_DIR/xserver
mesonclean_asneeded
meson setup $LOCAL_MESON_BUILD_DIR -Dprefix=$LOCAL_CURRENT_WLD_PATH -Dxwayland=true -Dglx=true -Dglamor=true -Dhal=false -Dlinux_acpi=false -Dxnest=false -Dxorg=false -Dxquartz=false -Dxvfb=false -Dxwin=false --buildtype $LOCAL_BUILD_TARGET $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

echo "Building sommelier..."
cd /build/$LOCAL_CHANNEL/vm/cros_vm/src/platform2/vm_tools/sommelier
# Build Sommelier
mesonclean_asneeded
meson setup $LOCAL_MESON_BUILD_DIR -Dxwayland_path=$LOCAL_CURRENT_WLD_PATH/bin/Xwayland -Dxwayland_gl_driver_path=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/dri -Dprefix=$LOCAL_CURRENT_WLD_PATH && ninja -C $LOCAL_MESON_BUILD_DIR install
