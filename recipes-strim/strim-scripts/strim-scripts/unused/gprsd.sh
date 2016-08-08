#!/bin/sh

NUM_PIN_GPRS_PWR=43	##acltive high
NUM_PIN_GPRS_WKUP=164	##acltive high
NUM_PIN_GPRS_INP=165	##input, acltive high
NUM_PIN_GPRS_DCD=147	##input, acltive high(?)
NUM_PIN_GPRS_STATUS=105	##input, acltive low

PATH_GPIO=/sys/class/gpio
PATH_GPRS_DEVICE=/dev/ttymxc3
PATH_GPIO_GPRS_PWR=${PATH_GPIO}/gpio${NUM_PIN_GPRS_PWR}
PATH_GPIO_GPRS_WKUP=${PATH_GPIO}/gpio${NUM_PIN_GPRS_WKUP}
PATH_GPIO_GPRS_INP=${PATH_GPIO}/gpio${NUM_PIN_GPRS_INP}
PATH_GPIO_GPRS_DCD=${PATH_GPIO}/gpio${NUM_PIN_GPRS_DCD}
PATH_GPIO_GPRS_STATUS=${PATH_GPIO}/gpio${NUM_PIN_GPRS_STATUS}

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="GPRS"

start() 
{
        echo -n "Starting $KIND modem: "
        while read line; do
                #echo -e "$line"
                if [[ $line -eq 1 ]] ; then
                        #echo -e "Need start module"
                        if [ -f ${PATH_GPRS_DEVICE} ] ; then
                                echo "" >> ${PATH_GPRS_DEVICE}
                        fi
                        echo -n "1" >> ${PATH_GPIO_GPRS_PWR}/value
                        sleep 1s
                        if [ -f ${PATH_GPRS_DEVICE} ] ; then
                                echo "" >> ${PATH_GPRS_DEVICE}
                        fi
                        echo -n "0" >> ${PATH_GPIO_GPRS_PWR}/value  
                        sleep 1s
                #else
                #        echo -e "Module work, not restart"
                fi
        done < ${PATH_GPIO_GPRS_STATUS}/value
        echo
}	

stop() 
{
        echo -n "Shutting down $KIND modem: "
        echo -n "1" >> ${PATH_GPIO_GPRS_SB}/value
        sleep 1s
        echo -n "0" >> ${PATH_GPIO_GPRS_SB}/value
        sleep 1s
        echo
}	

restart() 
{
        echo -n "Restarting $KIND modem: "	
        echo "" >> ${PATH_GPRS_DEVICE}
        echo -n "1" >> ${PATH_GPIO_GPRS_PWR}/value
        sleep 1s
        echo "" >> ${PATH_GPRS_DEVICE}
        echo -n "0" >> ${PATH_GPIO_GPRS_PWR}/value
        sleep 1s
        start
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

