DESCRIPTION = "Create scripts to work with Strim applicetions and boards"
SECTION = "Script"
LICENSE = "Strim"
LIC_FILES_CHKSUM = "file://LICENSE;md5=31823caa4e52283d11832906fdfe78b4"

SRC_URI = "file://gpioinit.sh \
           file://cdsmd.sh \
           file://gsmmd.sh \
           file://gpsmd.sh \
           file://gsmcd.sh \
           file://backlog.sh \
           file://statnet.sh \
           file://synctime.sh \
           file://garbcol.sh \
           file://sysupdate.sh \
           file://killcdsm.sh \
           file://LICENSE"

S = "${WORKDIR}"

RDEPENDS_${PN} = "busybox \
                  base-files \
                  modutils-initscripts \
                  base-passwd"

do_install() {
                mkdir -p ${D}${sysconfdir}/init.d/
                mkdir -p ${D}${sysconfdir}/rc5.d/
                install -m 0755 ${WORKDIR}/gpioinit.sh ${D}${sysconfdir}/init.d/gpioi
                install -m 0755 ${WORKDIR}/cdsmd.sh ${D}${sysconfdir}/init.d/cdsmd
                install -m 0755 ${WORKDIR}/gsmmd.sh ${D}${sysconfdir}/init.d/gsmmd
                install -m 0755 ${WORKDIR}/gpsmd.sh ${D}${sysconfdir}/init.d/gpsmd
                install -m 0755 ${WORKDIR}/gsmcd.sh ${D}${sysconfdir}/init.d/gsmcd
                install -m 0755 ${WORKDIR}/statnet.sh ${D}${sysconfdir}/init.d/statnet
                install -m 0755 ${WORKDIR}/synctime.sh ${D}${sysconfdir}/init.d/synctime
                install -m 0755 ${WORKDIR}/sysupdate.sh ${D}${sysconfdir}/init.d/sysupdate
                install -m 0755 ${WORKDIR}/garbcol.sh ${D}${sysconfdir}/init.d/garbcol
                install -m 0755 ${WORKDIR}/backlog.sh ${D}${sysconfdir}/init.d/backlog
                install -m 0755 ${WORKDIR}/killcdsm.sh ${D}${sysconfdir}/init.d/killcdsm
}

do_install_append () {	
                cd ${D}${sysconfdir}/rc5.d/    
                ln -s ../init.d/gpioi ${D}${sysconfdir}/rc5.d/S14bootLedOn1
                ln -s ../init.d/gpioi ${D}${sysconfdir}/rc5.d/S15bootLedOn2
}
