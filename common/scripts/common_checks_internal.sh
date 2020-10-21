#! /bin/bash

# common_checks_internal.sh
# Checks that all inputs recieved can be handled by the build system.
# Copies scripts, config files at start of every build.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

DIRECTORY_PREFIX=${1}
SOURCE_PWD=${2}
COMPONENT_TARGET=${3:-"--none"}
BUILD_TYPE=${4:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${5:-"--all"}
BUILD_CHANNEL=${6:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${7:-"--release"} # Possible values: --release, --debug, --all

  if [ $COMPONENT_TARGET != "--none" ]  && [ $COMPONENT_TARGET != "--rebuild-all" ] && [ $COMPONENT_TARGET != "--rootfs" ] && [ $COMPONENT_TARGET != "--common-libraries" ] && [ $COMPONENT_TARGET != "--game-fast" ] && [ $COMPONENT_TARGET != "--host" ] && [ $COMPONENT_TARGET != "--kernel" ]; then
    echo "Invalid COMPONENT_TARGET. Please check build_options.txt file for supported combinations."
    exit 1
  fi

  if [ $COMPONENT_TARGET == "--rootfs" ]; then
    if [ $BUILD_TYPE != "--none" ] && [ $BUILD_TYPE != "--really-clean" ]; then
      echo "Invalid Build Type. Please check build_options.txt file for supported combinations with this component."
      exit 1
    fi
  else
    if [ $BUILD_TYPE != "--clean" ] && [ $BUILD_TYPE != "--incremental" ] && [ $BUILD_TYPE != "--really-clean" ]; then
      echo "Invalid Build Type. Valid Values:--clean, --incremental, --really-clean"
      exit 1
    fi
  fi

  if [ $COMPONENT_ONLY_BUILDS != "--x11" ] && [ $COMPONENT_ONLY_BUILDS != "--wayland" ]  && [ $COMPONENT_ONLY_BUILDS != "--drivers" ] && [ $COMPONENT_ONLY_BUILDS != "--kernel" ] && [ $COMPONENT_ONLY_BUILDS != "--all" ]; then
    echo "Invalid value for COMPONENT_ONLY_BUILDS. Please check build_options.txt file for supported combinations."
    exit 1
  fi

  if [ $BUILD_CHANNEL != "--dev" ] && [ $BUILD_CHANNEL != "--stable" ] && [ $BUILD_CHANNEL != "--all" ]; then
    echo "Invalid Build Channel. Valid Values: --dev, --stable, --all"
    exit 1
  fi

  if [ $BUILD_TARGET != "--release" ] && [ $BUILD_TARGET != "--debug" ] && [ $BUILD_TARGET != "--all" ]; then
   echo "Invalid Build Target. Valid Values: --release, --debug, --all"
   exit 1
  fi
