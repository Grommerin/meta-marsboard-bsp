DESCRIPTION = "Creat and set PPPoE connect to GSM modem"
SECTION = "Network"
LICENSE = "Strim"
LIC_FILES_CHKSUM = "file://LICENSE;md5=31823caa4e52283d11832906fdfe78b4"

SRC_URI = "file://velcom \
           file://velcom-opt \
           file://velcom-connect \
           file://velcom-disconnect \
           file://pap-secrets \
           file://ip-pre-up.sh \
           file://LICENSE"

#DEPENDS_prepend = " добавить initscripts как-нибудь если что"

RDEPENDS_${PN} = "ppp"


S = "${WORKDIR}"

do_install() {
		mkdir -p ${D}${sysconfdir}/ppp/
            mkdir -p ${D}${sysconfdir}/ppp/peers/
            install -m 0755 ${WORKDIR}/velcom ${D}${sysconfdir}/ppp/peers/velcom
            install -m 0755 ${WORKDIR}/velcom-opt ${D}${sysconfdir}/ppp/options
		        install -m 0755 ${WORKDIR}/velcom-opt ${D}${sysconfdir}/ppp/velcom-opt
		        install -m 0755 ${WORKDIR}/velcom-connect ${D}${sysconfdir}/ppp/velcom-connect
		        install -m 0755 ${WORKDIR}/velcom-disconnect ${D}${sysconfdir}/ppp/velcom-disconnect
            install -m 0755 ${WORKDIR}/pap-secrets ${D}${sysconfdir}/ppp/pap-secrets
            install -m 0755 ${WORKDIR}/ip-pre-up.sh ${D}${sysconfdir}/ppp/ip-pre-up
}
