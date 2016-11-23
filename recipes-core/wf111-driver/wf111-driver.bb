DESCRIPTION = "WF111 driver and bin utils"
SECTION = "wireless driver"
LICENSE = "CLOSED"

INSANE_SKIP_${PN} = "already-stripped"

DEPENDS += " imx-test"


SRC_URI = " \
	file://csr \	
	file://mib \
	file://scripts \	
	file://Makefile \	
	file://README \		
"

do_compile () {
    cd ${WORKDIR}
    unset LDFLAG
    make install_static  KDIR=${TMPDIR}/work-shared/${MACHINE}/kernel-build-artifacts ARCH=arm CROSS_COMPILE=arm-poky-linux-gnueabi- 
}

do_install (){
	install -d ${D}
	cp -rf ${WORKDIR}/output/* ${D}
} 


FILES_${PN} = "/usr/* \
		/lib* "
