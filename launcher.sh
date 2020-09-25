#! /bin/bash

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

set -ex

BASE_DIRECTORY=${1} # Expected Directory Structure <basefolder>/rootfs.ext4, vmlinux, crosvm
XDG_RUNTIME_DIR=${2}
WAYLAND_DISPLAY=${3}
DISPLAY=${4}
CHANNEL=${5:-"--stable"}
TARGET=${6:-"--release"}
ACTION=${7:-"--run"}

LOCAL_KERNEL_CMD_OPTIONS=""
LOCAL_BUILD_TARGET=release
LOCAL_CHANNEL=stable

if [ $TARGET == "--release" ]; then
  LOCAL_KERNEL_CMD_OPTIONS="intel_iommu=on"
else
  LOCAL_KERNEL_CMD_OPTIONS="intel_iommu=on drm.debug=255 debug loglevel=8 initcall_debug"
  LOCAL_BUILD_TARGET=debug
fi

if [ $LOCAL_CHANNEL == "--dev" ]; then
  LOCAL_CHANNEL=dev
fi

docker image rm intel-vm-launch -f

if [[ "$(docker images -q intel-vm:latest 2> /dev/null)" != "" ]]; then
  echo “Preparing to launch crosvm...”
else
  echo “Failed to launch crosvm..., exit status: $?”
  exit 1
fi

if [ -e $BASE_DIRECTORY/docker/exec/ ]; then
  rm -rf $BASE_DIRECTORY/docker/exec/
fi

mkdir $BASE_DIRECTORY/docker/exec/

cp launch/docker/start.dockerfile $BASE_DIRECTORY/docker/exec/Dockerfile-start

if [ -e $BASE_DIRECTORY/scripts/exec/ ]; then
  rm -rf $BASE_DIRECTORY/scripts/exec/
fi

mkdir $BASE_DIRECTORY/scripts/exec/
cp launch/*.sh $BASE_DIRECTORY/scripts/exec/

if [ $ACTION=="--run" ]; then
cd $BASE_DIRECTORY/docker/exec/
docker build -t intel-vm-launch:latest -f Dockerfile-start .
exec docker run -it --privileged \
    --ipc=host \
    -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
    -v /dev/log:/dev/log \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev:/dev -v /proc:/proc -v /sys:/sys \
    --mount type=bind,source=$BASE_DIRECTORY/images,target=/images \
    --mount type=bind,source=$BASE_DIRECTORY/scripts,target=/scripts \
    intel-vm-launch:latest \
    $LOCAL_CHANNEL $LOCAL_BUILD_TARGET $LOCAL_KERNEL_CMD_OPTIONS run
else
cd $BASE_DIRECTORY/docker/exec/
docker build -t intel-vm-stop:latest -f Dockerfile-start .
exec docker run -it --privileged \
    --ipc=host \
    -e DISPLAY=$DISPLAY -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -e WAYLAND_DISPLAY=$WAYLAND_DISPLAY \
    -v /dev/log:/dev/log \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /dev:/dev -v /proc:/proc -v /sys:/sys \
    -f Dockerfile-start \
    --volume "$pwd":/wd \
    --workdir /wd \
    --ipc=host
    --mount type=bind,source=$BASE_DIRECTORY/images,target=/images \
    --mount type=bind,source=$BASE_DIRECTORY/scripts,target=/scripts \
    intel-vm-stop:latest \
    $LOCAL_CHANNEL $LOCAL_BUILD_TARGET $LOCAL_KERNEL_CMD_OPTIONS stop
fi

