#!/bin/bash

echo -e "\n[INFO]: BUILD STARTED..!\n"

# init submodules
git submodule init && git submodule update

export KERNEL_ROOT="$(pwd)"
export ARCH=arm64
export KBUILD_BUILD_USER="@Andy2660"

mkdir -p "${KERNEL_ROOT}/out" "${KERNEL_ROOT}/build"

# Export toolchain paths
export PATH="${HOME}/toolchains/clang-r428724/bin:${PATH}"
export LD_LIBRARY_PATH="${HOME}/clang-r428724/lib:${HOME}/clang-r428724/lib64:${LD_LIBRARY_PATH}"

# Set cross-compile environment variables
export BUILD_CROSS_COMPILE="${HOME}/toolchains/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
export BUILD_CC="${HOME}/toolchains/clang-r428724/bin/clang"

# Build options for the kernel
export BUILD_OPTIONS=(
    HOSTLDLIBS="-lyaml"
    -C "${KERNEL_ROOT}"
    O="${KERNEL_ROOT}/out"
    -j"$(nproc)"
    ARCH=arm64
    CROSS_COMPILE="${BUILD_CROSS_COMPILE}"
    CC="${BUILD_CC}"
    CLANG_TRIPLE=aarch64-linux-gnu-
)

# Merge a82xq config to r5q defconfig & add build log for kernel
OUT="${KERNEL_ROOT}/out"
LOG="${HOME}/build_fifteen.log"
FRAG="${KERNEL_ROOT}/arch/arm64/configs/sm8150_sec_a82xq_skt_kor.config"

build_kernel(){
    make "${BUILD_OPTIONS[@]}" mrproper
    
    # Default defconfig
    make "${BUILD_OPTIONS[@]}" r5q_eur_open_defconfig 

    # Merging A82XQ 
    ./scripts/kconfig/merge_config.sh -m -O "${OUT}" "${OUT}/.config" "${FRAG}"

    # Disable R5Q Options
    ./scripts/config --file "${OUT}/.config" \
        -d SEC_R5Q_PROJECT -d MACH_R5Q_EUR_OPEN \
        -d TOUCHSCREEN_SEC_TS_Y771_R5 -d PANEL_S6E3FA9_AMB667UM01_FHD \
        -d CRYPTO_FIPS -d ESE_SECURE -d CAMERA_FRS_DRAM_TEST \
        -d LSM6DSL_FACTORY -d TMD490X_FACTORY

   # Update configuration and fill in missing symbols
    make "${BUILD_OPTIONS[@]}" olddefconfig

    # Enable menuconfig (Comment out with # to disable)
    make "${BUILD_OPTIONS[@]}" menuconfig

    # Build Kernel (if you need log file you can use `2>&1 | tee "${LOG}"`)
    make "${BUILD_OPTIONS[@]}" Image || exit 1

    # Copy the built kernel to the build directory
    cp "${KERNEL_ROOT}/out/arch/arm64/boot/Image" "${KERNEL_ROOT}/build/boot.img-kernel"

    echo -e "\n[INFO]: BUILD FINISHED..!"
}

build_kernel
