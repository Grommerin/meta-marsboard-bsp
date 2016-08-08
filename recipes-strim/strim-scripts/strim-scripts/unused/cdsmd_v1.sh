#!/bin/sh

PROGRAM_MAIN_FILE_NAME=canlogger
PROGRAM_UPDATE_FILE_NAME=${PROGRAM_MAIN_FILE_NAME}_upd

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="cdsm daemon"
THIS_SCRIPT_FILE=/etc/init.d/cdsmd

Given_permission()
{
        chmod a+x /home/root/${PROGRAM_MAIN_FILE_NAME}/${PROGRAM_UPDATE_FILE_NAME}    
}

Replace_firmware()
{
        cp -f /home/root/${PROGRAM_MAIN_FILE_NAME}/${PROGRAM_UPDATE_FILE_NAME} /home/root/${PROGRAM_MAIN_FILE_NAME}/${PROGRAM_MAIN_FILE_NAME}
}

Delete_firmware()
{
        rm -f /home/root/${PROGRAM_MAIN_FILE_NAME}/${PROGRAM_MAIN_FILE_NAME}
}

Delete_firmware_upd()
{
        rm -f /home/root/${PROGRAM_MAIN_FILE_NAME}/${PROGRAM_UPDATE_FILE_NAME}
}

Check_firmware()
{
        if [[ -f /home/root/${PROGRAM_MAIN_FILE_NAME}/${PROGRAM_UPDATE_FILE_NAME} ]] ; then
                Given_permission
                #Delete_firmware
                Replace_firmware 
                Delete_firmware_upd
        fi
}

start() 
{
        echo -n "Starting $KIND services: "
        Check_firmware
        /home/root/${PROGRAM_MAIN_FILE_NAME}/${PROGRAM_MAIN_FILE_NAME}      
        echo
}	

stop() 
{
        echo -n "Shutting down $KIND services: "
        kill -s SIGTERM $(ps | grep -m 1 ${PROGRAM_MAIN_FILE_NAME} | awk '{print $1}')
        echo
}	

restart() 
{
        echo -n "Restarting $KIND services: "	
        stop
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
                echo $"Usage: $0 {start|stop|restart}"
                exit 1
        esac
        exit $?
