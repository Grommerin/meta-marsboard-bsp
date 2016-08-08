DESCRIPTION = "Strim mod flexcan driver"
HOMEPAGE = "https://github.com/Grommerin/"
LICENSE = "Strim"
LIC_FILES_CHKSUM = "file://LICENSE;md5=31823caa4e52283d11832906fdfe78b4"
PV = "1.3"
PR = "r5"

inherit module

SRC_URI = "file://Makefile \
file://flexcan.c \
file://chr_flexcan.h \
file://LICENSE"

S = "${WORKDIR}"

