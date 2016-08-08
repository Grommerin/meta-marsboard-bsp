#!/bin/sh

NUM_PIN_BOARD=26	##MarsBoard Boot Status

PATH_GPIO=/sys/class/gpio
PATH_GPIO_BOARD=${PATH_GPIO}/gpio${NUM_PIN_BOARD}

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="MBBS"

Write_param()
{
        if [[ -d ${1} ]] ; then
        	echo -n
        else
        	echo -n "${2}" >> ${PATH_GPIO}/export
        fi
}

Init()
{
        #echo "Start initialization gpio to COMP"
        Write_param ${PATH_GPIO_BOARD} ${NUM_PIN_BOARD}

        echo -n "out" >> ${PATH_GPIO_BOARD}/direction
        echo -n "1" >> ${PATH_GPIO_BOARD}/active_low
        echo -n "1" >> ${PATH_GPIO_BOARD}/value
}

start() 
{
        echo -n "Start initialization gpio to $KIND module: "
        Init
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

