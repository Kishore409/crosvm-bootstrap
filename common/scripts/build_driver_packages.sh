#! /bin/bash

###################################################################
#Build Driver packages.
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

BUILD_TARGET=${1:-"--release"}
BUILD_TYPE=${2:-"--update"}
BUILD_CHANNEL=${3:-"--stable"}
BUILD_ARCH=${4:-"x86_64"}

LOCAL_BUILD_TARGET=release
LOCAL_CHANNEL=stable

if /scripts/common/common_build_internal.sh $BUILD_TYPE $BUILD_TARGET $BUILD_CHANNEL $BUILD_ARCH; then
	echo "Starting Build...."
else
	echo "Unable to setup proper build environment. Quitting..."
	exit 1
fi

if [[ "$BUILD_CHANNEL" == "--dev" ]]; then
	LOCAL_CHANNEL=dev
fi

if [[ "$BUILD_TARGET" == "--debug" ]]; then
	LOCAL_BUILD_TARGET=debug
fi

if [[ "$BUILD_ARCH" == "i386" ]]; then
	LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TARGET/x86
	LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TARGET.x86
	CROSS_SETTINGS=meson-cross-i686-$LOCAL_CHANNEL-$LOCAL_BUILD_TARGET.ini

	# Export environment variables
	export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
	export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
	export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
	export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/include/:$LOCAL_CURRENT_WLD_PATH/include/libdrm/:$LOCAL_CURRENT_WLD_PATH/bin:/usr/bin:/usr/local/bin":/usr/share/wayland:/usr/share/wayland-protocols
	export ACLOCAL_PATH=$LOCAL_CURRENT_WLD_PATH/share/aclocal
	export ACLOCAL="aclocal -I $ACLOCAL_PATH"
	export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig:/usr/lib/i386-linux-gnu/pkgconfig:/lib/i386-linux-gnu/pkgconfig:/usr/share/pkgconfig
	export PKG_CONFIG_PATH_FOR_BUILD=$PKG_CONFIG_PATH
	export CC=/usr/bin/i686-linux-gnu-gcc

	LOCAL_COMPILER_OPTIONS="--host=i686-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32" --prefix=$LOCAL_CURRENT_WLD_PATH"
	LOCAL_MESON_COMPILER_OPTIONS="--cross-file $CROSS_SETTINGS"
else
	LOCAL_CURRENT_WLD_PATH=/opt/$LOCAL_CHANNEL/$LOCAL_BUILD_TARGET/x86_64
	LOCAL_MESON_BUILD_DIR=build.$LOCAL_BUILD_TARGET.x86_64
	LOCAL_COMPILER_OPTIONS=""
	LOCAL_MESON_COMPILER_OPTIONS=""

	# Export environment variables
	export C_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
	export CPLUS_INCLUDE_PATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
	export CPATH=$LOCAL_CURRENT_WLD_PATH/include:$LOCAL_CURRENT_WLD_PATH/include/libdrm/
	export PATH="$PATH:$LOCAL_CURRENT_WLD_PATH/include/:$LOCAL_CURRENT_WLD_PATH/include/libdrm/:$LOCAL_CURRENT_WLD_PATH/bin"
	export ACLOCAL_PATH=$LOCAL_CURRENT_WLD_PATH/share/aclocal
	export ACLOCAL="aclocal -I $ACLOCAL_PATH"
	export PKG_CONFIG_PATH=$LOCAL_CURRENT_WLD_PATH/lib/pkgconfig:$LOCAL_CURRENT_WLD_PATH/share/pkgconfig:$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu/pkgconfig:/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig
fi

# Set Working Build directory based on the channel.
WORKING_DIR=/build/$LOCAL_CHANNEL/drivers

echo "Working Directory:" $WORKING_DIR
env
echo "---------------------------------"

cd /build

###############################################################################
##mesonclean_asneeded()
###############################################################################
function mesonclean_asneeded() {
	if [[ "$BUILD_TYPE" == "--clean" ]]; then
  		if [[ -d $LOCAL_MESON_BUILD_DIR ]]; then
    			rm -rf $LOCAL_MESON_BUILD_DIR
  		fi
	fi
}

if [[ "$BUILD_ARCH" == "i386" ]]; then
	# Create settings for cross compiling
	if [[ "$BUILD_TYPE" == "--clean" ]]; then
		if [[ -f $CROSS_SETTINGS ]]; then
			rm $CROSS_SETTINGS
    		fi
  	fi

generate_compiler_settings() {
if [ ! -f $CROSS_SETTINGS ]; then
cat > $CROSS_SETTINGS <<EOF
[binaries]
c = '/usr/bin/i686-linux-gnu-gcc'
cpp = '/usr/bin/i686-linux-gnu-g++'
ar = '/usr/bin/i686-linux-gnu-gcc-ar'
strip = '/usr/bin/i686-linux-gnu-strip'
pkgconfig = '/usr/bin/i686-linux-gnu-pkg-config'
build.pkg_config_path = '/usr/bin/i686-linux-gnu-pkg-config'

[properties]
pkg_config_libdir = '$PKG_CONFIG_PATH'
c_args = ['-m32']
c_link_args = ['-m32']
cpp_args = ['-m32']
cpp_link_args = ['-m32']

[host_machine]
system = 'linux'
cpu_family = 'x86'
cpu = 'i686'
endian = 'little'
EOF
fi
}
else
generate_compiler_settings() {
	echo "64bit build"
}
fi

echo "checking " $LOCAL_CURRENT_WLD_PATH/share/aclocal
mkdir -p $LOCAL_CURRENT_WLD_PATH/share/aclocal
if [[ ! -d "$LOCAL_CURRENT_WLD_PATH/share/aclocal" ]]; then
	echo "Failed to create" $LOCAL_CURRENT_WLD_PATH/share/aclocal
else
	echo $LOCAL_CURRENT_WLD_PATH/share/aclocal "exists"
fi

###############################################################################
##main()
###############################################################################
# Build drm
echo "Building drm............"
cd $WORKING_DIR/mesa-drm
mesonclean_asneeded
generate_compiler_settings

meson setup $LOCAL_MESON_BUILD_DIR -Dprefix=$LOCAL_CURRENT_WLD_PATH -Dintel=true -Dradeon=false -Damdgpu=false -Dnouveau=false -Domap=false -Dexynos=false -Dfreedreno=false -Dtegra=false -Dvc4=false -Detnaviv=false --buildtype $LOCAL_BUILD_TARGET $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

# Build mesa
echo "Building  Mesa............"
cd $WORKING_DIR/mesa
mesonclean_asneeded
generate_compiler_settings
meson setup $LOCAL_MESON_BUILD_DIR --buildtype $LOCAL_BUILD_TARGET -Dprefix=$LOCAL_CURRENT_WLD_PATH -Ddri3="enabled" -Dshader-cache="enabled" -Dtools="glsl,nir" -Dplatforms="x11,wayland" -Ddri-drivers="" -Dgallium-drivers="iris,virgl,swrast" -Dvulkan-drivers="intel" -Dgallium-vdpau="disabled" -Dgallium-va="disabled" -Dopengl="true" -Dglx="dri" -Dselinux="true" -Dgles1="enabled" -Dgles2="enabled" -Dglx-direct="true" -Degl="enabled" -Dllvm="disabled" $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

# Build libepoxy
echo "Building libepoxy............"
cd $WORKING_DIR/libepoxy
mesonclean_asneeded
generate_compiler_settings
meson setup $LOCAL_MESON_BUILD_DIR  --buildtype $LOCAL_BUILD_TARGET -Dprefix=$LOCAL_CURRENT_WLD_PATH  -Dglx=yes -Dx11=true -Degl=yes $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

# Build libva
echo "Building libva............"
cd $WORKING_DIR/libva
mesonclean_asneeded
generate_compiler_settings
meson setup $LOCAL_MESON_BUILD_DIR  --buildtype $LOCAL_BUILD_TARGET -Dprefix=$LOCAL_CURRENT_WLD_PATH -Ddisable_drm=false -Dwith_x11=yes -Dwith_glx=yes -Dwith_wayland=yes $LOCAL_MESON_COMPILER_OPTIONS && ninja -C $LOCAL_MESON_BUILD_DIR install

if [[ "$BUILD_ARCH" != "i386" ]]; then
	# Build gmmlib
	cd $WORKING_DIR/gmmlib
	mesonclean_asneeded
	cmake -S . -B $LOCAL_MESON_BUILD_DIR -DCMAKE_INSTALL_PREFIX=$LOCAL_CURRENT_WLD_PATH
	cd $LOCAL_MESON_BUILD_DIR
	make
	make install
  
	# Build media-driver
 	cd $WORKING_DIR/media-driver
  	mesonclean_asneeded
  	cmake -S . -B $LOCAL_MESON_BUILD_DIR -DCMAKE_INSTALL_PREFIX=$LOCAL_CURRENT_WLD_PATH -DLIBVA_DRIVERS_PATH=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu -DLIBVA_INSTALL_PATH=$LOCAL_CURRENT_WLD_PATH/include -DENABLE_PRODUCTION_KMD=ON -DLIBVA_LIBRARY_PATH=$LOCAL_CURRENT_WLD_PATH/lib/x86_64-linux-gnu
  	cd $LOCAL_MESON_BUILD_DIR
  	make -j4
  	make install
  
  # FIXME: ADD IGC Build.
  # Build Neo
  #echo "Building Neo............"
  #cd $WORKING_DIR/compute/neo
  #mesonclean_asneeded
  #mkdir -p $LOCAL_MESON_BUILD_DIR
  #cmake -S . -B $LOCAL_MESON_BUILD_DIR -DCMAKE_INSTALL_PREFIX=$LOCAL_CURRENT_WLD_PATH -DCMAKE_BUILD_TYPE=Release -DSKIP_UNIT_TESTS=1
  #cd $LOCAL_MESON_BUILD_DIR
  #echo "cmake config done, starting make"
  #make -j`nproc`
  #make install
fi
