#!/bin/sh
    
CDSM_PID_C=$(pidof canlogger)
if [[ ${#CDSM_PID_C} -ne 0 ]] ; then
    CDSM_PID=$(pidof canlogger | awk '{print $1}')
    nohup kill -s HUP ${CDSM_PID} > /dev/null 2>&1 &

fi
exit 0
