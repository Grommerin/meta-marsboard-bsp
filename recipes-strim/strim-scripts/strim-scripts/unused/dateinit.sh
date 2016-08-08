#!/bin/sh

MESSAGE=""
HEAD=GPRMC

Read_date()
{
        MESSAGE=`head -n1 '/dev/ttymxc2' | tr -d "\n"`
        #echo -e "${MESSAGE}"
}

Set_date()
{
        MESS1=$(echo ${MESSAGE} | sed 's/\$GPRMC,\([0-9]*\)\..*,.*,.*,.*,.*,.*,.*,.*,\([0-9]*\),.*,.*/\1/')
        #echo -e "${MESS1}"

        MESS2=$(echo ${MESSAGE} | sed 's/\$GPRMC,\([0-9]*\)\..*,.*,.*,.*,.*,.*,.*,.*,\([0-9]*\),.*,.*/\2/')
        #echo -e "${MESS2}"

        TIME1=$(echo ${MESS1} | sed 's/[0-9]\{2\}/(&)/1')
        TIME1=$(echo ${TIME1} | sed 's/.*(\([0-9]*\)).*/\1/')
        #echo -e "${TIME1}"

        TIME2=$(echo ${MESS1} | sed 's/[0-9]\{2\}/(&)/2')
        TIME2=$(echo ${TIME2} | sed 's/.*(\([0-9]*\)).*/\1/')
        #echo -e "${TIME2}"

        TIME3=$(echo ${MESS1} | sed 's/[0-9]\{2\}/(&)/3')
        TIME3=$(echo ${TIME3} | sed 's/.*(\([0-9]*\)).*/\1/')
        #echo -e "${TIME3}"

        DATE1=$(echo ${MESS2} | sed 's/[0-9]\{2\}/(&)/1')
        DATE1=$(echo ${DATE1} | sed 's/.*(\([0-9]*\)).*/\1/')
        #echo -e "${DATE1}"

        DATE2=$(echo ${MESS2} | sed 's/[0-9]\{2\}/(&)/2')
        DATE2=$(echo ${DATE2} | sed 's/.*(\([0-9]*\)).*/\1/')
        #echo -e "${DATE2}"

        DATE3=$(echo ${MESS2} | sed 's/[0-9]\{2\}/(&)/3')
        DATE3=$(echo ${DATE3} | sed 's/.*(\([0-9]*\)).*/\1/')
        #echo -e "${DATE3}"

        DATE=${DATE2}${DATE1}${TIME1}${TIME2}${DATE3}.${TIME3}
        echo -e "Set date to ${DATE}"
        $(date ${DATE} >> /dev/null)
}

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="Date"

start() 
{
        echo -n "Starting set $KIND: "
        SET=0
        sleep 1s
        while [ $SET -lt 10 ] 
        do
                if [ -r /dev/ttymxc2 ] ; then
                        Read_date
                        STR=$(expr substr "${MESSAGE}" 2 5)
                        if [[ $STR = $HEAD ]] ; then
                                Set_date
                                SET=11
                        fi
                else
                        echo "/dev/ttymxc2 not found. ERROR!!!" 
                fi
                SET=$(( $SET+1 ))
        done
        echo
}	

stop() 
{
        echo -n "$KIND module daemod called stop"
        echo
}	

restart() 
{
        #echo -n "$KIND module daemod called reset"
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

