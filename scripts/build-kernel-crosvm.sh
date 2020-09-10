#! /bin/bash

# build-kernel-crosvm.sh
# Builds cros_vm and kernel

export RUST_VERSION=1.45.2
export CARGO_HOME=/usr/local/cargo
export PATH=/usr/local/cargo/bin:$PATH
export RUSTFLAGS='--cfg hermetic'

# Build x86 config
if [ -d "/build/drm-intel/arch/x86/configs" ]
then
  echo "Found drm-intel folder. Building kernel..."
  cd /build/drm-intel
  make clean
  make x86_64_defconfig
  make
else
  echo "Unable to find drm-intel folder.Kernel is not built."
fi

if [ -d "/build/cros_vm/src/platform/crosvm" ]
then
  echo "Found cros_vm folder. Building cros_vm..."
  cd /build/cros_vm/src/platform/crosvm
  cargo clean
  cargo build --features 'default-no-sandbox wl-dmabuf gpu x'
  cargo build --release --features 'default-no-sandbox wl-dmabuf gpu x'
else
  echo "Unable to find cros_vm folder.cros_vm is not built."
fi

if [ -d "/build/cros_vm/src/platform2/vm_tools/sommelier" ]
then
  echo "Found sommelier folder. Building sommelier..."
  cd /build/cros_vm/src/platform2/vm_tools/sommelier
  # Build Sommelier
  if [ -d "/build/cros_vm/src/platform2/vm_tools/sommelier/build" ]; then
    rm -rf /build/cros_vm/src/platform2/vm_tools/sommelier/build/
  fi

  meson build -Dxwayland_path=/usr/bin/XWayland -Dxwayland_gl_driver_path=/usr/local/lib/x86_64-linux-gnu
  ninja -C build install
else
  echo "Unable to find sommelier folder.sommelier is not built."
fi