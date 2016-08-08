#!/bin/sh

NUM_PIN_GPRS_PWR=43	##acltive high
NUM_PIN_GPRS_WKUP=164	##acltive high
NUM_PIN_GPRS_INP=165	##input, acltive high
NUM_PIN_GPRS_DCD=147	##input, acltive high(?)
NUM_PIN_GPRS_STATUS=105	##input, acltive low

PATH_GPIO=/sys/class/gpio
PATH_GPIO_GPRS_PWR=${PATH_GPIO}/gpio${NUM_PIN_GPRS_PWR}
PATH_GPIO_GPRS_WKUP=${PATH_GPIO}/gpio${NUM_PIN_GPRS_WKUP}
PATH_GPIO_GPRS_INP=${PATH_GPIO}/gpio${NUM_PIN_GPRS_INP}
PATH_GPIO_GPRS_DCD=${PATH_GPIO}/gpio${NUM_PIN_GPRS_DCD}
PATH_GPIO_GPRS_STATUS=${PATH_GPIO}/gpio${NUM_PIN_GPRS_STATUS}

PATH_GPIO_LED_BOARD=${PATH_GPIO}/gpio${NUM_PIN_LED_BOARD}

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="GPRS"

Write_param()
{
        if [[ -d ${1} ]] ; then
        	echo -n
        else
        	echo -n "${2}" >> ${PATH_GPIO}/export
        fi
}

Init_GPRS ()
{
        #echo "Start initialization gpio to GPRS module"
        Write_param ${PATH_GPIO_GPRS_PWR} ${NUM_PIN_GPRS_PWR}
        Write_param ${PATH_GPIO_GPRS_WKUP} ${NUM_PIN_GPRS_WKUP}
        Write_param ${PATH_GPIO_GPRS_INP} ${NUM_PIN_GPRS_INP}
        Write_param ${PATH_GPIO_GPRS_DCD} ${NUM_PIN_GPRS_DCD}
        Write_param ${PATH_GPIO_GPRS_STATUS} ${NUM_PIN_GPRS_STATUS}

        echo -n "out" >> ${PATH_GPIO_GPRS_PWR}/direction
        echo -n "out" >> ${PATH_GPIO_GPRS_WKUP}/direction
        echo -n "in" >> ${PATH_GPIO_GPRS_INP}/direction
        echo -n "in" >> ${PATH_GPIO_GPRS_DCD}/direction
        echo -n "in" >> ${PATH_GPIO_GPRS_STATUS}/direction

        echo -n "0" >> ${PATH_GPIO_GPRS_PWR}/value
        echo -n "0" >> ${PATH_GPIO_GPRS_WKUP}/value
}

start() 
{
        echo -n "Start initialization gpio to $KIND module: "
        Init_GPRS
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


