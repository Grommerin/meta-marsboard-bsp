#!/bin/sh

NUM_PIN_GPS_RST=18	##active low
NUM_PIN_GPS_WKUP=63	##acltive high
NUM_PIN_GPS_SB=1	##active low

PATH_GPIO=/sys/class/gpio
PATH_GPIO_GPS_RST=${PATH_GPIO}/gpio${NUM_PIN_GPS_RST}
PATH_GPIO_GPS_WKUP=${PATH_GPIO}/gpio${NUM_PIN_GPS_WKUP}
PATH_GPIO_GPS_SB=${PATH_GPIO}/gpio${NUM_PIN_GPS_SB}

PATH_GPIO_LED_BOARD=${PATH_GPIO}/gpio${NUM_PIN_LED_BOARD}

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="GPS"

Write_param()
{
        if [[ -d ${1} ]] ; then
        	echo -n
        else
        	echo -n "${2}" >> ${PATH_GPIO}/export
        fi
}

Init_GPS ()
{
        #echo "Start initialization gpio to GPS module"
        Write_param ${PATH_GPIO_GPS_RST} ${NUM_PIN_GPS_RST}
        Write_param ${PATH_GPIO_GPS_WKUP} ${NUM_PIN_GPS_WKUP}
        Write_param ${PATH_GPIO_GPS_SB} ${NUM_PIN_GPS_SB}

        echo -n "out" >> ${PATH_GPIO_GPS_RST}/direction
        echo -n "out" >> ${PATH_GPIO_GPS_WKUP}/direction
        echo -n "out" >> ${PATH_GPIO_GPS_SB}/direction

        echo -n "1" >> ${PATH_GPIO_GPS_RST}/active_low
        echo -n "1" >> ${PATH_GPIO_GPS_SB}/active_low

        echo -n "0" >> ${PATH_GPIO_GPS_RST}/value
        echo -n "1" >> ${PATH_GPIO_GPS_WKUP}/value
        echo -n "0" >> ${PATH_GPIO_GPS_SB}/value
}

start() 
{
        echo -n "Start initialization gpio to $KIND module: "
        Init_GPS
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

start

#case "$1" in
#        start)
#                start
#                ;;
#        stop)
#                stop
#                ;;
#        restart)
#                restart
#                ;;
#        *)
#                echo $"Usage: $0 {start|stop|restart}"
#                exit 1
#        esac
#        exit $?

