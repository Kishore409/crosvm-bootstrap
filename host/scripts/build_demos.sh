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

if /scripts/host/common_build_internal.sh $BUILD_TYPE $BUILD_TARGET $BUILD_CHANNEL
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
LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TARGET.x86_64

# Export environment variables
export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/include/:$LOCAL_CURRENT_WLD_PATH/include/libdrm/:$LOCAL_CURRENT_WLD_PATH/bin"
export ACLOCAL_PATH=$LOCAL_CURRENT_WLD_PATH/share/aclocal
export ACLOCAL="aclocal -I $ACLOCAL_PATH"
export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig
export LD_LIBRARY_PATH=$LOCAL_CURRENT_WLD_PATH/lib
export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/bin"

# Set Working Build directory based on the channel.
WORKING_DIR=/build/$LOCAL_CHANNEL/demos

# Print all environment settings
echo "Build settings being used....."
if [ $BUILD_TARGET == "--release" ]; then
  echo "Build Type: Release"
else
  echo "Build Type: Debug"
fi

echo "Channel:" $LOCAL_CHANNEL
if [ $BUILD_TYPE == "--clean" ]; then
  echo "Clean" $LOCAL_BUILD_TARGET "Build"
else
  echo "Incremental" $LOCAL_BUILD_TARGET "Build"
fi

echo "Working Directory:" $WORKING_DIR
echo "---------------------------------"

export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH:/lib/x86_64-linux-gnu/pkgconfig
export LD_LIBRARY_PATH=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

env
echo "---------------------------------"

if [ ! -f "/usr/bin/python" ]; then
ln -s /usr/bin/python3 /usr/bin/python
fi

cd /build

FORCE_CONFIGURE=0
CUSTOM_APP_OPTIONS=""
function make_clean_asneeded() {
if [ $BUILD_TYPE == "--clean" ]; then
  if [ "$(find . | grep -i '.*[.]o' | wc -c)" == 0 ]; then
    echo "make clean called"
    make clean || true
    FORCE_CONFIGURE=1
  else
    echo "Skipped make clean as this is incremental build or project has not been configured."
  fi
fi
}

function configure_asneeded() {
if [ $FORCE_CONFIGURE == 1 ]; then
  echo "Configuring the project"
  ./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH
  FORCE_CONFIGURE=0
else
  if [ "$(find . | grep -i '.*[.]o' | wc -c)" != 0 ]; then
    echo "Configuring the project"
    ./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH
    FORCE_CONFIGURE=0
  else
    echo "Skipped configuring the project as this is incremental build."
  fi
fi
}

function autogen_build() {
#make_clean_asneeded
#configure_asneeded
make clean || true
./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $CUSTOM_APP_OPTIONS
make install
CUSTOM_APP_OPTIONS=""
}

echo "checking " $LOCAL_CURRENT_WLD_PATH/share/aclocal
mkdir -p $LOCAL_CURRENT_WLD_PATH/share/aclocal
if [ ! -d "$LOCAL_CURRENT_WLD_PATH/share/aclocal" ]; then
  echo "Failed to create" $LOCAL_CURRENT_WLD_PATH/share/aclocal
else
  echo $LOCAL_CURRENT_WLD_PATH/share/aclocal "exists"
fi

# Build glew.
echo "Building demos............"
echo "Building glew............"
cd $WORKING_DIR/glew
make extensions
make install GLEW_DEST=$LOCAL_CURRENT_WLD_PATH GLEW_PREFIX=$LOCAL_CURRENT_WLD_PATH

echo "Building glu............"
cd $WORKING_DIR/glu
autogen_build

echo "Building Mesa Demos............"
cd $WORKING_DIR/mesa-demos
CUSTOM_APP_OPTIONS="--enable-x11 --enable-wayland --enable-gbm --enable-egl --enable-gles1 --enable-gles2 --enable-libdrm"
autogen_build

echo "Building xdpyinfo............"
cd $WORKING_DIR/xdpyinfo
autogen_build


