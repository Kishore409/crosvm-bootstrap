#! /bin/bash

###################################################################
#Sanity checks the options passed from build.sh.
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

DIRECTORY_PREFIX=${1}
SOURCE_PWD=${2}
COMPONENT_TARGET=${3:-"none"}
BUILD_TYPE=${4:-"--clean"} # Possible values: --clean, --incremental --really-clean
COMPONENT_ONLY_BUILDS=${5:-"--all"}
BUILD_CHANNEL=${6:-"--stable"} # Possible values: --dev, --stable, --all
BUILD_TARGET=${7:-"--release"} # Possible values: --release, --debug, --all

###############################################################################
##main()
###############################################################################

if [[ "$COMPONENT_TARGET" != "--host" ]] && [[ "$COMPONENT_TARGET" != "--guest" ]] &&\
	[[ "$COMPONENT_TARGET" != "--container" ]] && [[ "$COMPONENT_TARGET" != "--kernel" ]]; then
  echo "Invalid COMPONENT_TARGET. Please check build_options.txt file for supported combinations."
  exit 1
fi

if [[ "$BUILD_TYPE" != "--all" ]] && [[ "$BUILD_TYPE" != "--clean" ]] && [[ "$BUILD_TYPE" != "--update" ]]; then
  echo "Invalid Build Type. Valid Values:--clean, --incremental, --really-clean"
  exit 1
fi

if [[ "$COMPONENT_ONLY_BUILDS" != "--x11" ]] && [[ "$COMPONENT_ONLY_BUILDS" != "--wayland" ]]  && [[ "$COMPONENT_ONLY_BUILDS" != "--drivers" ]] && [[ "$COMPONENT_ONLY_BUILDS" != "--all" ]] && [[ "$COMPONENT_ONLY_BUILDS" != "--vm" ]] && [[ "$COMPONENT_ONLY_BUILDS" != "--compostior" ]]; then
   echo "Invalid value for COMPONENT_ONLY_BUILDS: $COMPONENT_ONLY_BUILDS. Please check build_options.txt file for supported combinations."
   exit 1
fi

if [[ "$BUILD_CHANNEL" != "--dev" ]] && [[ "$BUILD_CHANNEL" != "--stable" ]] && [[ "$BUILD_CHANNEL" != "--all" ]]; then
  echo "Invalid Build Channel. Valid Values: --dev, --stable, --all"
  exit 1
fi

if [[ "$BUILD_TARGET" != "--release" ]] && [[ "$BUILD_TARGET" != "--debug" ]] && [[ "$BUILD_TARGET" != "--all" ]]; then
  echo "Invalid Build Target. Valid Values: --release, --debug, --all"
  exit 1
fi
