#! /bin/bash

###################################################################
#Build X11 packages.
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

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Set Working Build directory based on the channel.
WORKING_DIR=/build/$LOCAL_CHANNEL/x11

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

echo "Working Directory:" $WORKING_DIR
env
echo "---------------------------------"

if [ $BUILD_ARCH == "i386" ]; then
	# Create settings for cross compiling
	if [ $BUILD_TYPE == "--clean" ]; then
		if [ -f $CROSS_SETTINGS ]; then
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

cd /build

FORCE_CONFIGURE=0
###############################################################################
##make_clean_asneeded()
###############################################################################
function make_clean_asneeded() {
	if [ $CLEAN_BUILD == "--clean" ]; then
  		if [ "$(find . | grep -i '.*[.]o' | wc -c)" == 0 ]; then
    			echo "make -j0  clean called"
    			make clean || EXIT_CODE=$?
    			FORCE_CONFIGURE=1
  		else
    			echo "Skipped make -j0  clean as this is incremental build or project has not been configured."
  		fi
	fi
}

###############################################################################
##configure_asneeded()
###############################################################################
function configure_asneeded() {
	if [ $FORCE_CONFIGURE == 1 ]; then
  		echo "Configuring the project"
  		./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_COMPILER_OPTIONS
  		FORCE_CONFIGURE=0
	else
  		if [ "$(find . | grep -i '.*[.]o' | wc -c)" != 0 ]; then
    			echo "Configuring the project"
    			./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_COMPILER_OPTIONS
    			FORCE_CONFIGURE=0
  		else
    			echo "Skipped configuring the project as this is incremental build."
  		fi
	fi
}

###############################################################################
##autogen_build()
###############################################################################
function autogen_build() {
	#make -j0 clean_asneeded
	#configure_asneeded
	make clean || EXIT_CODE=$?
	./autogen.sh --prefix=$LOCAL_CURRENT_WLD_PATH $LOCAL_COMPILER_OPTIONS
	make install
}

###############################################################################
##main()
###############################################################################
echo "checking " $LOCAL_CURRENT_WLD_PATH/share/aclocal
mkdir -p $LOCAL_CURRENT_WLD_PATH/share/aclocal
if [ ! -d "$LOCAL_CURRENT_WLD_PATH/share/aclocal" ]; then
	echo "Failed to create" $LOCAL_CURRENT_WLD_PATH/share/aclocal
else
	echo $LOCAL_CURRENT_WLD_PATH/share/aclocal "exists"
fi

# Build libpciaccess.
echo "Building libraries............"
echo "Building libpciaccess............"
cd $WORKING_DIR/libpciaccess
autogen_build

# Build font util
echo "Building util............"
cd $WORKING_DIR/util
autogen_build

# Build xkbcomp
echo "Building xkbcomp............"
cd $WORKING_DIR/xkbcomp
autogen_build

# Build xkeyboard-config
echo "Building xkeyboard-config............"
cd $WORKING_DIR/xkeyboard-config
autogen_build

echo "Built X11 packages..."
