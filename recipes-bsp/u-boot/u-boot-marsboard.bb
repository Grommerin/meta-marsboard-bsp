require recipes-bsp/u-boot/u-boot.inc

LICENSE = "GPLv2+"
#LIC_FILES_CHKSUM = "file://Licenses/README;md5=c7383a594871c03da76b3707929d2919"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=0507cd7da8e7ad6d6701926ec9b84c95"

COMPATIBLE_MACHINE = "(marsboard)"

PROVIDES = "virtual/bootloader"

PV = "mainline+git${SRCPV}"

# this is 2015-06-28 shortly after tag v2015.07-rc2
# SRCREV = "7853d76b0bdab9b1a4da0bba8da6d12b5b8a303f"
# SRC_URI = "git://git.denx.de/u-boot.git;rev=${SRCREV}"

SRCREV = "${AUTOREV}"
SRCBRANCH = "strim-bars3000"
SRC_URI = "git://github.com/grommerin/u-boot-bars3000.git;branch=${SRCBRANCH}"

S = "${WORKDIR}/git"

PACKAGE_ARCH = "${MACHINE_ARCH}"


