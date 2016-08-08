#!/bin/sh

NUM_PIN_LED_BOARD=92	##active low

PATH_GPIO=/sys/class/gpio
PATH_GPIO_LED_BOARD=${PATH_GPIO}/gpio${NUM_PIN_LED_BOARD}

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="LED"

Write_param()
{
        if [[ -d ${1} ]] ; then
        	echo -n
        else
        	echo -n "${2}" >> ${PATH_GPIO}/export
        fi
}

Init_LED()
{
        #echo "Start initialization gpio to LED"
        Write_param ${PATH_GPIO_LED_BOARD} ${NUM_PIN_LED_BOARD}

        echo -n "out" >> ${PATH_GPIO_LED_BOARD}/direction

        echo -n "1" >> ${PATH_GPIO_LED_BOARD}/active_low

        echo -n "0" >> ${PATH_GPIO_LED_BOARD}/value
}

start() 
{
        echo -n "Start initialization gpio to $KIND module: "
        Init_LED
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
