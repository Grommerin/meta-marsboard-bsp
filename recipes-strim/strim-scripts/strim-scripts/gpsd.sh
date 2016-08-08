#!/bin/sh

NUM_PIN_GPS_RST=18	##active low
NUM_PIN_GPS_WKUP=63	##acltive high
NUM_PIN_GPS_SB=1	##active low

PATH_GPIO=/sys/class/gpio
PATH_GPIO_GPS_RST=${PATH_GPIO}/gpio${NUM_PIN_GPS_RST}
PATH_GPIO_GPS_WKUP=${PATH_GPIO}/gpio${NUM_PIN_GPS_WKUP}
PATH_GPIO_GPS_SB=${PATH_GPIO}/gpio${NUM_PIN_GPS_SB}

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="GPS"

start() 
{
        echo -n "Starting $KIND modem: "
        echo -n "0" >> ${PATH_GPIO_GPS_WKUP}/value
        sleep 1s
        echo -n "1" >> ${PATH_GPIO_GPS_WKUP}/value
        sleep 1s
        echo
}	

stop() 
{
        echo -n "Shutting down $KIND modem: "
        echo -n "1" >> ${PATH_GPIO_GPS_SB}/value
        sleep 1s
        echo -n "0" >> ${PATH_GPIO_GPS_SB}/value
        sleep 1s
        echo
}	

restart() 
{
        echo -n "Restarting $KIND modem: "	
        echo -n "1" >> ${PATH_GPIO_GPS_RST}/value
        sleep 1s
        echo -n "0" >> ${PATH_GPIO_GPS_RST}/value
        sleep 1s
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

