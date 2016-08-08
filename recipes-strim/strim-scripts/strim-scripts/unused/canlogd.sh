#!/bin/sh

PROGRAM_MAIN_FILE_NAME=canlog
PROGRAM_UPDATE_FILE_NAME=canlog_upd

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

KIND="canlog"
THIS_SCRIPT_FILE=/etc/init.d/canlogd

Given_permission()
{
        chmod a+x /home/root/canlogdir/${PROGRAM_UPDATE_FILE_NAME}    
}

Replace_firmware()
{
        cp -f /home/root/canlogdir/${PROGRAM_UPDATE_FILE_NAME} /home/root/canlogdir/${PROGRAM_MAIN_FILE_NAME}
}

Delete_firmware()
{
        rm -f /home/root/canlogdir/${PROGRAM_MAIN_FILE_NAME}
}

Delete_firmware_upd()
{
        rm -f /home/root/canlogdir/${PROGRAM_UPDATE_FILE_NAME}
}

Check_firmware()
{
        if [[ -f /home/root/canlogdir/${PROGRAM_UPDATE_FILE_NAME} ]] ; then
                Given_permission
                #Delete_firmware
                Replace_firmware 
                Delete_firmware_upd
        fi
}

Check_init()
{
        if [[ -f /usr/bin/canlogdir/settings.xml ]] ; then
                cp -rf /usr/bin/canlogdir /home/root/
                rm -rf /usr/bin/canlogdir
        fi
        
        if [[ -f /usr/bin/${PROGRAM_MAIN_FILE_NAME} ]] ; then
                cp -f /usr/bin/${PROGRAM_MAIN_FILE_NAME} /home/root/canlogdir/${PROGRAM_MAIN_FILE_NAME}
                rm -f /usr/bin/${PROGRAM_MAIN_FILE_NAME}
        fi
}

start() 
{
        echo -n "Starting $KIND services: "
        Check_init
        Check_firmware
        DATE=$(date +%m%d%H%M%y)
        FILE=/home/root/canlogdir/log${DATE}.log
        /home/root/canlogdir/canlog >> $FILE      
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
