#!/bin/sh

PING_IP=8.8.8.8
SLEEP_TIME_WAIT=20s
SLEEP_TIME_WORK=60s

ping -q -c5 ${PING_IP} &> /dev/null
REPEATE=$?
while [[ ${REPEATE} != "0" ]]
    do
        sleep ${SLEEP_TIME_WAIT}
        ping -q -c3 ${PING_IP} &> /dev/null
        REPEATE=$?
done

echo "PPP link up. Restart ntpd for sync time"
export NTP_PID=$(pidof ntpd)
if [[ `pidof ntpd` ]] ; then
    `/etc/init.d/ntpd restart`
    echo "SYNCTIME: restart ntpd"
else
    `/etc/init.d/ntpd start`
    echo "SYNCTIME: start ntpd"
fi
sleep 2s
export NTP_PID=$(pidof ntpd)
if [[ `pidof ntpd` ]] ; then
	echo -n ""
else
    `/etc/init.d/ntpd stop`
    echo "SYNCTIME: stop ntpd"
    sleep 2s
    if [[ `pidof ntpd` ]] ; then
    	echo -n ""
    else
        `/etc/init.d/ntpd start`
        echo "SYNCTIME: start ntpd normaly"
    fi
fi

sleep ${SLEEP_TIME_WAIT}

ping -q -c5 ${PING_IP} &> /dev/null
REPEATE=$?
while [[ ${REPEATE} == "0" ]]
    do
        sleep ${SLEEP_TIME_WORK}
        ping -q -c5 ${PING_IP} &> /dev/null
        REPEATE=$?
done
