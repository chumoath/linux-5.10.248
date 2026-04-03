#!/bin/bash

set -e

ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-

BUILD_DIR="build.${ARCH}"


	echo "${FUNCNAME[0]} start."
	echo "${FUNCNAME[0]} end."
function gen_config() {
	echo "${FUNCNAME[0]} start."
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} O=${BUILD_DIR} defconfig >/dev/null 2>&1
	#make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} O=${BUILD_DIR} menuconfig
	echo "${FUNCNAME[0]} end."
}

function build_kernel_image() {
	echo "${FUNCNAME[0]} start."
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} O=${BUILD_DIR} Image -j$(nproc) >/dev/null 2>&1
	echo "${FUNCNAME[0]} end."
}

function build_modules() {
	echo "${FUNCNAME[0]} start."
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} O=${BUILD_DIR} modules -j$(nproc)
	echo "${FUNCNAME[0]} end."
}

function install_modules() {
	echo "${FUNCNAME[0]} start."
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} O=${BUILD_DIR} INSTALL_MOD_PATH=$(pwd)/${ARCH}_rootfs modules_install
	echo "${FUNCNAME[0]} end."
}

function install_headers() {
	echo "${FUNCNAME[0]} start."
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} O=${BUILD_DIR} INSTALL_HDR_PATH=$(pwd)/${ARCH}_rootfs/usr headers_install
	echo "${FUNCNAME[0]} end."
}

function gen_vmlinux_gdb() {
	echo "${FUNCNAME[0]} start."
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} O=${BUILD_DIR} scripts_gdb
	cp ${BUILD_DIR}/vmlinux-gdb.py .
	echo "${FUNCNAME[0]} end."
}

function gen_compile_commands() {
	echo "${FUNCNAME[0]} start."

	cd ${BUILD_DIR}
	../scripts/clang-tools/gen_compile_commands.py
	sed -i 's@1UL@1@' scripts/gdb/linux/constants.py
	cd -

	echo "${FUNCNAME[0]} end."
}

function fix_arm64 () {
	echo "${FUNCNAME[0]} start."

	cd ${BUILD_DIR}
	sed -i 's@-fno-allow-store-data-races@@' compile_commands.json
	sed -i 's@-fconserve-stack@@' compile_commands.json
	sed -i 's@-mabi=lp64@@' compile_commands.json
	cd -

	echo "${FUNCNAME[0]} end."
}

if [[ -d ${BUILD_DIR} ]]; then
	echo "${BUILD_DIR} exist, remove it."
	rm -rf ${BUILD_DIR}
fi

gen_config
build_kernel_image
build_modules
install_modules
install_headers
gen_vmlinux_gdb
gen_compile_commands

if [[ ${ARCH} == "arm64" ]]; then
	fix_arm64
fi
