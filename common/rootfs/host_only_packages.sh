#! /bin/bash

###################################################################
#Packages installed in Host only.
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

export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo
export PATH=/usr/local/cargo/bin:$PATH
export RUST_VERSION=1.45.2
export RUSTFLAGS='--cfg hermetic'

###############################################################################
##install_package()
###############################################################################
function install_package() {
	package_name="${1}"
	if [[ ! "$(dpkg -s $package_name)" ]]; then
  		echo "installing:" $package_name "----------------"
  		sudo apt-get install -y  --no-install-recommends --no-install-suggests $package_name
  		sudo apt-mark hold $package_name
  		echo "---------------------"
	else
  		echo $package_name "is already installed."
	fi
}

###############################################################################
##main()
###############################################################################
echo "Installing needed system packages..."
install_package libreadline-dev

ls -a /proc

curl -LO "https://static.rust-lang.org/rustup/archive/1.22.1/x86_64-unknown-linux-gnu/rustup-init" \
    && echo "49c96f3f74be82f4752b8bffcf81961dea5e6e94ce1ccba94435f12e871c3bdb *rustup-init" | sha256sum -c - \
    && chmod +x rustup-init \
    && ./rustup-init -y --no-modify-path --default-toolchain $RUST_VERSION \
    && rm rustup-init \
    && chmod -R a+w $RUSTUP_HOME $CARGO_HOME \
    && rustup --version \
    && cargo --version \
    && rustc --version

rustup default stable
cargo install thisiznotarealpackage -q || true

