#! /bin/bash

# package-builder.sh
# Builds all needed drivers, cros_vm and other needed packages.

# exit on any script line that fails
set -o errexit
# bail on any unitialized variable reads
set -o nounset
# bail on failing commands before last pipe
set -o pipefail

BUILD_TYPE=${1:-"--release"}
CLEAN_BUILD=${2:-"--incremental"}
BUILD_CHANNEL=${3:-"--stable"}
LOCAL_BUILD_TYPE=release
LOCAL_CHANNEL=stable

if /build/output/scripts/common_build_internal.sh $BUILD_TYPE $CLEAN_BUILD $BUILD_CHANNEL --64bit
then
  echo "Starting Build...."
else
  echo "Unable to setup proper build environment. Quitting..."
  exit 1
fi

if [ $BUILD_CHANNEL == "--dev" ]; then
LOCAL_CHANNEL=dev
fi

if [ $BUILD_CHANNEL == "--dev" ]; then
  if [ $BUILD_TYPE == "--debug" ]; then
    export RUSTFLAGS='--cfg hermetic -L /opt/dev/debug/x86_64/vm/lib/x86_64-linux-gnu -L /opt/dev/debug/x86_64/lib/x86_64-linux-gnu -L /opt/dev/debug/x86_64/lib -L /usr/lib/x86_64-linux-gnu'
  else
    export RUSTFLAGS='--cfg hermetic -L /opt/dev/release/x86_64/vm/lib/x86_64-linux-gnu -L /opt/dev/release/x86_64/lib/x86_64-linux-gnu -L /opt/dev/release/x86_64/lib -L /usr/lib/x86_64-linux-gnu'
  fi
else
  if [ $BUILD_TYPE == "--debug" ]; then
    export RUSTFLAGS='--cfg hermetic -L /opt/stable/debug/x86_64/vm/lib/x86_64-linux-gnu -L /opt/stable/debug/x86_64/lib/x86_64-linux-gnu -L /opt/stable/debug/x86_64/lib -L /usr/lib/x86_64-linux-gnu'
  else
    export RUSTFLAGS='--cfg hermetic -L /opt/stable/release/x86_64/vm/lib/x86_64-linux-gnu  -L /opt/stable/release/x86_64/lib/x86_64-linux-gnu -L /opt/stable/release/x86_64/lib -L /usr/lib/x86_64-linux-gnu'
  fi
fi

if [ $BUILD_TYPE == "--debug" ]; then
LOCAL_BUILD_TYPE=debug
fi

LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TYPE/x86_64
LOCAL_MESON_COMPILER_OPTIONS=""
LOCAL_LIBDIR=lib/x86_64-linux-gnu
LOCAL_COMPILER_OPTIONS=""
LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TYPE.x86_64

echo "64 bit build"

# Export environment variables
export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm
export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm
export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm
export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm:$LOCAL_CURRENT_WLD_PATH/bin:$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu"
export ACLOCAL_PATH=$LOCAL_CURRENT_WLD_PATH/share/aclocal
export ACLOCAL="aclocal -I $ACLOCAL_PATH"
export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig:$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig:$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig:/lib/x86_64-linux-gnu/pkgconfig
export WAYLAND_PROTOCOLS_PATH=$LOCAL_CURRENT_WLD_PATH/share/wayland-protocols
export RUSTUP_HOME=/usr/local/rustup
export RUST_VERSION=1.45.2
export CARGO_HOME=/usr/local/cargo
export LD_LIBRARY_PATH=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu:$LOCAL_CURRENT_WLD_PATH/lib:$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu:$LOCAL_CURRENT_WLD_PATH/lib
export PATH=$CARGO_HOME:$PATH

# Set Working Build directory based on the channel.
WORKING_DIR=/build/$LOCAL_CHANNEL/vm
LOCAL_MINI_GBM_PC=$WORKING_DIR/minigbm/minigbm-$LOCAL_CHANNEL-$LOCAL_BUILD_TYPE.pc

# Print all environment settings

echo "Working Directory:" $WORKING_DIR

env
echo "---------------------------------"

cd /build

function mesonclean_asneeded() {
if [[ ($CLEAN_BUILD == "--clean" && -d $LOCAL_MESON_BUILD_DIR) ]]; then
  rm -rf $LOCAL_MESON_BUILD_DIR
fi
}

cat > $LOCAL_MINI_GBM_PC <<EOF
prefix=$LOCAL_CURRENT_WLD_PATH
exec_prefix=$LOCAL_CURRENT_WLD_PATH
includedir=$LOCAL_CURRENT_WLD_PATH/include
libdir=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu
Name: libgbm
Description: A small gbm implementation
Version: 18.0.0
Cflags: -I$LOCAL_CURRENT_WLD_PATH/include
Libs: -L$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu -lgbm
EOF

# Build minigbm
echo "Building Minigbm............"
cd $WORKING_DIR/minigbm
make clean || true
make CPPFLAGS="-DDRV_I915" DRV_I915=1 install DESTDIR=$LOCAL_CURRENT_WLD_PATH LIBDIR=$LOCAL_LIBDIR
mkdir -p $LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig/
install -D -m 0644 $LOCAL_MINI_GBM_PC $LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig/gbm.pc

# Build virglrenderer
echo "Building 64 bit VirglRenderer............"
cd $WORKING_DIR/virglrenderer
mesonclean_asneeded
meson setup $LOCAL_MESON_BUILD_DIR -Dplatforms=auto -Dminigbm_allocation=true  --buildtype $LOCAL_BUILD_TYPE -Dprefix=$LOCAL_CURRENT_WLD_PATH && ninja -C $LOCAL_MESON_BUILD_DIR install

echo "Building 64 bit CrosVM............"
cd $WORKING_DIR/cros_vm/src/platform/crosvm
if [[ ($CLEAN_BUILD == "--clean" && -d $LOCAL_MESON_BUILD_DIR) ]]; then
  cargo clean --target-dir $LOCAL_MESON_BUILD_DIR
  rm -rf $LOCAL_MESON_BUILD_DIR
fi
if [ $BUILD_TYPE == "--debug" ]; then
  cargo build --target-dir $LOCAL_MESON_BUILD_DIR --features 'default-no-sandbox wl-dmabuf gpu x'
else
  cargo build --target-dir $LOCAL_MESON_BUILD_DIR --release --features 'default-no-sandbox wl-dmabuf gpu x'
fi

if [ -f $LOCAL_MESON_BUILD_DIR/$LOCAL_BUILD_TYPE/crosvm ]; then
  install -D -m 0644 $LOCAL_MESON_BUILD_DIR/$LOCAL_BUILD_TYPE/crosvm $LOCAL_CURRENT_WLD_PATH/bin/
fi
