#!/bin/sh

NUM_PIN_COMP_BOARD=104	##comparatop

PATH_GPIO=/sys/class/gpio
PATH_GPIO_COMP_BOARD=${PATH_GPIO}/gpio${NUM_PIN_COMP_BOARD}

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="COMP"

Write_param()
{
        if [[ -d ${1} ]] ; then
        	echo -n
        else
        	echo -n "${2}" >> ${PATH_GPIO}/export
        fi
}

Init_COMP()
{
        #echo "Start initialization gpio to COMP"
        Write_param ${PATH_GPIO_COMP_BOARD} ${NUM_PIN_COMP_BOARD}

        echo -n "in" >> ${PATH_GPIO_COMP_BOARD}/direction
}

start() 
{
        echo -n "Start initialization gpio to $KIND module: "
        Init_COMP
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
