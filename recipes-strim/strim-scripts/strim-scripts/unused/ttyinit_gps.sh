#!/bin/sh

TTY_DEFAULT=ttymxc2

SPEED_9600=9600
SPEED_38400=38400
SPEED_115200=115200
SPEED_DEFAULT=${SPEED_115200}

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="GPS TTY"

Setup_uart()
{
        stty -F /dev/${1} ${2}

        stty -F /dev/${1} -parenb
        stty -F /dev/${1} -parodd
        stty -F /dev/${1} cs8
        stty -F /dev/${1} -hupcl
        stty -F /dev/${1} -cstopb
        stty -F /dev/${1} cread
        stty -F /dev/${1} clocal
        stty -F /dev/${1} -crtscts

        stty -F /dev/${1} ignbrk 
        stty -F /dev/${1} -brkint
        stty -F /dev/${1} -ignpar
        stty -F /dev/${1} -parmrk
        stty -F /dev/${1} -inpck
        stty -F /dev/${1} -istrip
        stty -F /dev/${1} -inlcr
        stty -F /dev/${1} -igncr
        stty -F /dev/${1} -icrnl
        stty -F /dev/${1} -ixon
        stty -F /dev/${1} -ixoff

        stty -F /dev/${1} -iuclc
        stty -F /dev/${1} -ixany
        stty -F /dev/${1} -imaxbel
        stty -F /dev/${1} -iutf8

        stty -F /dev/${1} -opost
        stty -F /dev/${1} -olcuc
        stty -F /dev/${1} -ocrnl
        stty -F /dev/${1} -onlcr
        stty -F /dev/${1} -onocr
        stty -F /dev/${1} -onlret
        stty -F /dev/${1} -ofill
        stty -F /dev/${1} -ofdel
        stty -F /dev/${1} nl0
        stty -F /dev/${1} cr0
        stty -F /dev/${1} tab0
        stty -F /dev/${1} bs0
        stty -F /dev/${1} vt0
        stty -F /dev/${1} ff0

        stty -F /dev/${1} -isig
        stty -F /dev/${1} -icanon
        stty -F /dev/${1} -iexten
        stty -F /dev/${1} -echo
        stty -F /dev/${1} -echoe
        stty -F /dev/${1} -echok
        stty -F /dev/${1} -echonl
        stty -F /dev/${1} -noflsh
        stty -F /dev/${1} -xcase
        stty -F /dev/${1} -tostop
        stty -F /dev/${1} -echoprt
        stty -F /dev/${1} -echoctl
        stty -F /dev/${1} -echoke
}

start() 
{
        echo -n "Starting set $KIND: "
        #echo -e "Start setup ${TTY_DEFAULT} with speed ${SPEED_DEFAULT}"
        if [ -r /dev/${TTY_DEFAULT} ] ; then
                Setup_uart ${TTY_DEFAULT} ${SPEED_DEFAULT}
        else
                echo "/dev/${TTY_DEFAULT} not found. ERROR!!!"
        fi
        echo
}	

stop() 
{
        echo -n "$KIND module daemod called stop"
        echo
}	

restart() 
{
        echo -n "$KIND module daemod called reset"	
        echo
}	

case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        restart)
                restart
                ;;
        *)
                start
                #echo $"Usage: $0 {start|stop|restart}"
                exit 1
        esac
        exit $?

