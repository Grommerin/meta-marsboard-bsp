#!/bin/sh

sleep ${SLEEP_TIME}
ping -q -c3 ${PING_IP} &> /dev/null
REPEATE=$?

while [[ ${REPEATE} == "0" ]]
    do
        sleep ${SLEEP_TIME}
        ping -q -c3 ${PING_IP} &> /dev/null
        REPEATE=$?
done

if [[ ${REPEATE} != "0" ]]
    then
        echo "PPP link down. Restart pppd, canlogger"
        export PPPD_PID=$(pidof pppd)
        kill -s HUP $PPPD_PID
        export CDSM_PID=$(pidof canlogger)
        kill -s INT $CDSM_PID
fi