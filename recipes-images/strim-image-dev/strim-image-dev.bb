DESCRIPTION = "Image to debug new program and hardware feachures."

inherit core-image

EXTRA_IMAGE_FEATURES += " ssh-server-openssh tools-sdk tools-testapps tools-profile debug-tweaks"

IMAGE_INSTALL_append += " packagegroup-core-boot packagegroup-core-ssh-openssh"

# packagegroup-core-full-cmdline-libs
IMAGE_INSTALL_append += " glib-2.0"

# packagegroup-core-full-cmdline-utils
IMAGE_INSTALL_append += " bash acl attr bc coreutils cpio e2fsprogs ed file findutils gawk gmp grep makedevs mktemp ncurses net-tools pax popt procps psmisc sed tar time util-linux zlib"

# packagegroup-core-full-cmdline-extended
IMAGE_INSTALL_append += " iproute2 iputils iptables module-init-tools openssl"

IMAGE_INSTALL_append += " openssh-sftp openssh-sftp-server sshfs-fuse"

IMAGE_INSTALL_append += " ppp ntp htop cmake db sqlite sqlite3 ethtool minicom"

IMAGE_INSTALL_append += " i2c-tools ipsec-tools libevent gdb"

IMAGE_INSTALL_append += " libstrimtool libstrimdata libstrimgpio"

IMAGE_INSTALL_append +=" cpufrequtils libsdl2 iperf subversion wget" 

# the default "Boot strimboard" is not a valid FAT label and caused stress
BOOTDD_VOLUME_ID = "BOOT"

# this reserves some extra free space on the rootfs partition
# drawback: this empty spaces makes the .sdcard image larger and copying (dd) slower
# as an alternative you might want to create a third "data" partition on the microSD card
IMAGE_ROOTFS_EXTRA_SPACE = "1024000" 

IMAGE_INSTALL_remove +=" alsa apm neard avahi bluez5 flac packagegroup-base-bluetooth" 
