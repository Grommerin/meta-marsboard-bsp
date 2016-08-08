#!/bin/sh

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

# все описания обновлений записывать в файле statnet.notes

# версия программы
PROG_VERSION_MAJOR_=2
PROG_VERSION_MINOR_=3
PROG_VERSION_BUILD_=0

# строка с версией программы (для удобства и лаконичности)
PROG_VERSION="v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_}"

# имя скрипта
SCRIPT_NAME="statnet"

# префикс сообщений скрипта
SCRIPT_PREF="STATNET"

# файл с версией скрипта
SCRIPT_VER=/home/root/scripts/${SCRIPT_NAME}.ver

# файл лога работы скрипта
LOG_PROG=/var/log/${SCRIPT_NAME}

# файл лога устройства
LOG_SYSTEM=/home/root/syslog

# файл для записи команды перезагрузки модема
GSM_RESTART_FILE=/sys/class/gpio/gpio43/value

# путь к логу pppd
PPPD_LOG=/var/log/pppdebug

# путь к файлу модема для установки соединения
PPPD_TTY="/dev/ttyGSM2"

# пусть к файлу блокировки модема демоном pppd
PPPD_LOCK="/var/lock/LCK..ttyGSM2"

# статус запуска демона pppd
# 0 - не запущен
# 1 - запущен
PPPD_STAT=0

# адрес для проверки соединения
GSM_PING_IP=8.8.8.8

# лимит потерь пакетов для перезапуска соединения
GSM_PING_LOST_MAX=85

# количество запросов ping в серии для проверки состояния соединения
GSM_PING_COUNT=7

# размер пакета для проверки состояния соединения
GSM_PING_SIZE=8

# время до перезапуска модема при отсутствии соединения
GSM_RESTART_TIME=100

# время между проверками при установленном соединении
CHECK_TIME_CONNECTED=10

# время между проверками при отсутствующем соединении
CHECK_TIME_DISCONNECTED=10

# время последного соединения
CONNECTED_TIME=0

# процент потерянный пакетов
PACKETS_LOST=0

# флаг повтора скрипта
FLAG_REPEATE=1

# режим однократного запуска скрипта (установить в 1 для однократного запуска)
MODE_ONCE=0

# уставновить в 1 для перезапуска программ после каждого разрыва соединения
ALWAYS_RESTART=0

# флаг состояния соединения (изменяется с помощью проверки ping)
# 0 - соединение установлено
# !0 - соединение отсутствует
PING_STAT=0

# флаг предыдущего состояния соединения (для перезапуска программ после разрыва)
# 0 - соединение установлено
# !0 - соединение отсутствует
PING_STAT_OLD=1

# количество прочитанных параметров
PARAMS_COUNT=0

# принятые параметры
PARAMS0=10
PARAMS1=0
PARAMS2=0
PARAMS3=0
PARAMS4=0
PARAMS5=0
PARAMS6=0
PARAMS7=0
PARAMS8=0
PARAMS9=0
PARAMS10=0

Debug_log()             # записывает сообщение в файл лога
{
    export TIME_STAMP=$(date +%d.%m\ %H.%M.%S)  
    
    echo -e "${TIME_STAMP} ${1}" >> ${LOG_PROG}
    echo -e "${TIME_STAMP} ${1}" >> ${LOG_SYSTEM}
}

Set_check_time_c()     # устанавливаем время ожидания при установленном соединении
{
    NEW_TIME=$1
    SEACH_S=$(expr index "${NEW_TIME}" "s")
    if [[ ${SEACH_S} -ne 0 ]] ; then
        NEW_TIME=&{NEW_TIME%?}
    fi
    CHECK_TIME_CONNECTED=${NEW_TIME}
    echo -e "${SCRIPT_PREF}: connected check time: ${CHECK_TIME_CONNECTED}"
}

Set_check_time_d()     # устанавливаем время ожидания при отсутствующем соединении
{
    NEW_TIME=$1
    SEACH_S=$(expr index "${NEW_TIME}" "s")
    if [[ ${SEACH_S} -ne 0 ]] ; then
        NEW_TIME=&{NEW_TIME%?}
    fi
    CHECK_TIME_DISCONNECTED=${NEW_TIME}
    echo -e "${SCRIPT_PREF}: disconnected check time: ${CHECK_TIME_DISCONNECTED}"
}

Set_ping_ip()           # устанавливаем ip адрес проверки соединения
{
    IP=$1
    if [[ ${IP} ]] ; then
        GSM_PING_IP=${IP}
        echo -e "${SCRIPT_PREF}: ping ip: ${GSM_PING_IP}"
    fi
}

Set_packet_size()       # устанавливаем размер пакета для проверки соединения
{
	PSIZE=$1
	if [[ ${PSIZE} ]] ; then
	    GSM_PING_SIZE=${PSIZE}
	    echo -e "${SCRIPT_PREF}: ping pack size: ${GSM_PING_SIZE}"
    fi
}

Set_packet_count()      # устанавливаем количество пакетов в одной проверке
{
    PCOUNT=$1
    if [[ ${PCOUNT} ]] ; then
        GSM_PING_COUNT=${PCOUNT}
        echo -e "${SCRIPT_PREF}: ping pack count: ${GSM_PING_COUNT}"
    fi
}

Set_lost_limit()        # устанавливаем максимальное коичество потерянный пакетов
{
	LIMIT=$1
	if [[ ${LIMIT} -gt 0 && ${LIMIT} -lt 100 ]] ; then
	    GSM_PING_LOST_MAX=${LIMIT}
	    echo -e "${SCRIPT_PREF}: max lost ${GSM_PING_LOST_MAX}% packets"
    else
        echo -e "${SCRIPT_PREF}: ignore bad lost value ${LIMIT}"
    fi
}

Set_always_restart()    # перезапускать ntpd после каждой проверки
{
    ALWAYS_RESTART=1
    echo -e "${SCRIPT_PREF}: force restart: true"
}

Set_once()              # уставновить режим однократной работы
{
    MODE_ONCE=1
    echo -e "${SCRIPT_PREF}: loop mode: false"
}

Set_restart_time()     # установить время проверок до перезапуска модема
{
	RESTART_TIME=$1
    if [[ ${RESTART_TIME} ]] ; then
    	GSM_RESTART_TIME=${RESTART_TIME}
        echo -e "${SCRIPT_PREF}: restart time: ${GSM_RESTART_TIME}"
    fi
}

Gsm_modem_restart()     # перезапустить gsm модем
{
    if [[ -e ${GSM_RESTART_FILE} ]] ; then
        Debug_log "${SCRIPT_PREF}: restart gsm modem"
        echo "1" > ${GSM_RESTART_FILE}
    else
        Debug_log "${SCRIPT_PREF}: restart gsm modem error, no file"
    fi
}

Check_connect()        # проверка статуса соединения
{
	# проверяем есть ли коннект или само соединение (вернет >0 если нет)
    PING_STAT=$(ping -q -c 1 -s ${GSM_PING_SIZE} ${GSM_PING_IP} -I ppp0 2<&1 | grep -icE 'bad|unknown|expired|unreachable|time out')

    # проверяем состояние соедниения (вернет % потерянных пакетов)
    if [[ ${PING_STAT} -eq 0 ]] ; then
        PACKETS_LOST=$(ping -q -c ${GSM_PING_COUNT} -s ${GSM_PING_SIZE} ${GSM_PING_IP} | grep loss | awk '{print $7}' | sed s/%//)
        if [[ ${PACKETS_LOST} -lt ${GSM_PING_LOST_MAX} ]] ; then  
            PING_STAT=0              # если потеряли меньше xx% - норм
        else                        
            PING_STAT=1              # если потеряли больше xx% - плохо
        fi
    fi
}

Check_pppd()            # проверка статуса демона pppd
{
    if [[ -f ${PPPD_LOCK} ]] ; then
        PPPD_STAT=1
    else
        PPPD_STAT=0
    fi 
}

Pppd_start()            # запустить соединение pppd
{
	nohup /etc/init.d/ppp start > /dev/null 2>&1 &
}

Pppd_kill()             # "убить" процесс pppd
{
    PPPD_PID_C=$(pidof pppd)
    if [[ ${#PPPD_PID_C} -ne 0 ]] ; then
        /etc/init.d/ppp stop  >> /dev/null &
        while [[ -f ${PPPD_LOCK} ]] ; do
            sleep 1s   
        done
    fi
}

Calc_gsm_signal()       # рассчитать значение сигнала GSM 
{
	GSM_SIGNAL=""
    SIGNALS=$(cat ${PPPD_LOG} | grep +CSQ: | sort -r | awk '{print $8}')
    for SIGNAL in $SIGNALS ; do
    	GSM_SIGNAL=${SIGNAL%,*}
        break
    done	
    
    if [[ ${GSM_SIGNAL} -eq 0 ]] ; then
        GSM_SIGNAL="-113 dBm or less (CSQ ${SIGNAL})"
    elif [[ ${GSM_SIGNAL} -eq 1 ]] ; then
        GSM_SIGNAL="-111 dBm (CSQ ${SIGNAL})"
    elif [[ ${GSM_SIGNAL} -ge 2 && ${GSM_SIGNAL} -le 30 ]] ; then
        let "SIG=${GSM_SIGNAL}*2"
        SIG=$(expr ${SIG} - 113)
        GSM_SIGNAL=${SIG}" dBm (CSQ ${SIGNAL})"
    elif [[ ${GSM_SIGNAL} -ge 31 ]] ; then
        GSM_SIGNAL="-51 dBm or greater (CSQ ${SIGNAL})"
    fi
}

Sig_quit()
{
    Debug_log "${SCRIPT_PREF}: signal QUIT received, connection time ${CONNECTED_TIME}s, exit"
    Pppd_kill
   
   exit 0
}

Sig_term()
{
    Debug_log "${SCRIPT_PREF}: signal TERM received, connection time ${CONNECTED_TIME}s, exit"
    Pppd_kill
    exit 0
}

Sig_int()
{
    Debug_log "${SCRIPT_PREF}: signal INT received, connection time ${CONNECTED_TIME}s, exit"
    Pppd_kill
    exit 0
}

Write_version()         # записывает версию скрипта в файл
{
    echo "${SCRIPT_PREF} ${PROG_VERSION}" > ${SCRIPT_VER}
}

Print_def_settings()    # вывести настройки по умолчанию
{
    echo -e "\tDefault settings:"
    echo -en "\t\tLoop mode:               "
    if [[ ${MODE_ONCE} -eq 0 ]] ; then
        echo -e "true"
    else
        echo -e "false"
    fi
    echo -en "\t\tForce restart:           "
    if [[ ${ALWAYS_RESTART} -eq 1 ]] ; then
        echo -e "true"
    else
        echo -e "false"
    fi
    echo -e "\t\tPing ip:                 ${GSM_PING_IP}"
    echo -e "\t\tPing pack count:         ${GSM_PING_COUNT}"
    echo -e "\t\tPing pack size:          ${GSM_PING_SIZE}"
    echo -e "\t\tPing max lost:           ${GSM_PING_LOST_MAX}%"
    echo -e "\t\tLog file:                ${LOG_PROG}"
    echo -e "\t\tSystem log file:         ${LOG_SYSTEM}"
    echo -e "\t\tRestart time:            ${GSM_RESTART_TIME}s"
    echo -e "\t\tConnected check time:    ${CHECK_TIME_CONNECTED}s"
    echo -e "\t\tDisconnected check time: ${CHECK_TIME_DISCONNECTED}s"
}

Print_version()        # выводит сообщение с версией скрипта
{
    echo -e "${SCRIPT_PREF} ${PROG_VERSION} by Strim Ltd."
}

Print_help()            # помощь
{
    echo -e ""
    Print_version
    echo -e "" 
    echo -e "Usage: \t./${SCRIPT_NAME} [-hvof] [-rt -ct -dt -ip -ps -pc -lm] [value]"
    echo -e ""
    echo -e "\tSupported options (not required):"
    echo -e "\t-h, --help"
    echo -en "\t\t\t\t Show this help"
    echo -e ""
    echo -e "\t-v, --version"
    echo -en "\t\t\t\t Print script version"
    echo -e ""
    echo -e "\t-k, --kill"
    echo -en "\t\t\t\t Kill pppd daemon"
    echo -e ""
    echo -e "\t-o, --once"
    echo -en "\t\t\t\t Run the script once"
    echo -e ""
    echo -e "\t-f, --force"
    echo -en "\t\t\t\t Reset connect on each loop"
    echo -e ""
    echo -e "\t-rt, --rtime [value]"
    echo -en "\t\t\t\t Set the time of checks before restarting modem"
    echo -e ""
    echo -e "\t-ct, --ctime [value]s"
    echo -en "\t\t\t\t Set value connected check time"
    echo -e ""
    echo -e "\t-dt, --dtime [value]s"
    echo -en "\t\t\t\t Set value disconnected check time"
    echo -e ""
    echo -e "\t-ip, --ipaddr [value]"
    echo -en "\t\t\t\t Set ping ip value"
    echo -e ""
    echo -e "\t-ps, --psize [value]"
    echo -en "\t\t\t\t Set ping packet size value"
    echo -e ""
    echo -e "\t-pc, --pcount [value]"
    echo -en "\t\t\t\t Set ping packets count value"
    echo -e ""
    echo -e "\t-lm, --lostmax [value]"
    echo -en "\t\t\t\t Set ping limit of lost packets value"
    echo -e ""
    Print_def_settings
    echo -e ""
}

Handle_parameter()      # обрабатываем параметр
{
    if [[ $1 == "-h" || $1 == "--help" ]] ; then
        Print_help 
        exit
    elif [[ $1 == "-v" || $1 == "--version" ]] ; then
        Print_version
        exit
    elif [[ $1 == "-k" || $1 == "--kill" ]] ; then
        Pppd_kill
        exit
    elif [[ $1 == "-o" || $1 == "--once" ]] ; then
        Set_once
    elif [[ $1 == "-f" || $1 == "--force" ]] ; then
        Set_always_restart
    elif [[ $1 == "-rt" || $1 == "--rtime" ]] ; then
        Set_restart_time $2
    elif [[ $1 == "-ct" || $1 == "--ctime" ]] ; then
        Set_check_time_c $2
    elif [[ $1 == "-dt" || $1 == "--dtime" ]] ; then
        Set_check_time_d $2
    elif [[ $1 == "-ip" || $1 == "--ipaddr" ]] ; then
        Set_ping_ip $2
    elif [[ $1 == "-ps" || $1 == "--psize" ]] ; then
        Set_packet_size $2
    elif [[ $1 == "-pc" || $1 == "--pcount" ]] ; then
        Set_packet_count $2
    elif [[ $1 == "-lm" || $1 == "--lostmax" ]] ; then
        Set_lost_limit $2
    else
        echo -e "${SCRIPT_PREF}: unknown parameter: ${1}" 
        echo -e "Try \"${SCRIPT_NAME} -h\" for a more detailed description"
        exit
    fi
}

Check_parameters()      # обработка списка параметров
{
    COUNTER_PAR=0
    while [[ ${COUNTER_PAR} -ne ${PARAMS_COUNT} ]] ; do
        PARAM_VAL=$(eval echo "$"PARAMS${COUNTER_PAR}"")
        Handle_parameter ${PARAM_VAL}
        COUNTER_PAR=$(expr ${COUNTER_PAR} + 1)
    done
}

Print_start_message()    # вывод стартового сообщения при запуске
{ 
    PARAM=$*
    if [[ ${#PARAM} -ne 0 ]] ; then
        Debug_log "${SCRIPT_PREF}: ${PROG_VERSION} started with parameters ${*}"
    else
        Debug_log "${SCRIPT_PREF}: ${PROG_VERSION} started"
    fi
    Write_version
}

Read_script_parameters()  # обработка параметров запуска скрипта
{
    if [[ -z "$*" ]] ; then
        Print_start_message
    else
        Print_start_message $*
        # счетчик параметров (равен количеству переданных скрипту параметров)  
        COUNTER_RD=$#        
        while [[ ${COUNTER_RD} -ne 0 ]] ; do
            SEACH_START=$(expr index "${1}" "-")
            
            if [[ ${SEACH_START} -ne 0 ]] ; then
                # если в результате получен не 0 - значит это параметр
                export PARAMS${PARAMS_COUNT}=${1}
                PARAMS_COUNT=$(expr ${PARAMS_COUNT} + 1) 
                # увеличили счетчик параметров
            else  
                # значит такого знака нет и это не параметр, а его значение
                INDEX=$(expr ${PARAMS_COUNT} - 1)
                PARAM_VAL=$(eval echo "$"PARAMS${INDEX}"")
                export PARAMS${INDEX}=${PARAM_VAL}" "${1}
            fi 
            
            COUNTER_RD=$(expr ${COUNTER_RD} - 1) # декрементируем счетчик                        
            shift 1                              # сдвигаем влево список параметров                  
        done
        
        Check_parameters
    fi
}

##-------------------------##

trap 'Sig_quit' QUIT
trap 'Sig_term' TERM
trap 'Sig_int'  INT

Read_script_parameters $*

RESTART_TIME=${GSM_RESTART_TIME}             # время перезапуска модема
CHECK_TIME=${CHECK_TIME_DISCONNECTED}        # значение таймера сна для изменения интервала согласно статуса соединения

# главный цикл
while [[ ${FLAG_REPEATE} -eq 1 ]] ; do    
    if [[ -e ${PPPD_TTY} ]] ; then          # есть файл модема
        Check_pppd                           # проверка статуса демона pppd
        if ! [[ -f ${PPPD_LOCK} ]] ; then   # нет файла
            Pppd_start                       # запускаем установку соединения
        fi
    fi
    
    Check_connect                            # проверка статуса соединения
    if [[ ${PING_STAT} -ne 0 ]] ; then      # соединение разорвано
        if [[ ${ALWAYS_RESTART} -eq 1 ]] ; then
            PING_STAT_OLD=0                  # типа в прошлый раз все было хорошо и только что оборвалось соединение
        fi
                
        if [[ ${PING_STAT_OLD} -ne 0 ]] ; then  # соединение раньше отсутствовало
            if [[ -e ${PPPD_TTY} ]] ; then      # есть файл модема
                RESTART_TIME=$(expr ${RESTART_TIME} - ${CHECK_TIME_DISCONNECTED})
                if [[ ${RESTART_TIME} -le 0 ]] ; then  # пора перезапустить модем
                    RESTART_TIME=${GSM_RESTART_TIME}
                    Pppd_kill
                    Gsm_modem_restart
                    exit 0
                fi
            
                if ! [[ -f ${PPPD_LOCK} ]] ; then
                    Pppd_start
                fi
            fi
        else                                    # соединение только что разорвалось 
             Debug_log "${SCRIPT_PREF}: link is broken because it lost ${PACKETS_LOST}% from ${GSM_PING_COUNT} packets, connection time ${CONNECTED_TIME}s"
             if [[ -e ${PPPD_TTY} ]] ; then     # есть файл модема
                 Pppd_kill
                 Pppd_start
                 RESTART_TIME=${GSM_RESTART_TIME}
             fi
             CHECK_TIME=${CHECK_TIME_DISCONNECTED}
        fi 
    else                                        # есть соединение
        if [[ ${PING_STAT_OLD} -ne 0 ]] ; then  # если соединение раньше отсутствовало 
            Calc_gsm_signal
            Debug_log "${SCRIPT_PREF}: link is up, gsm signal ${GSM_SIGNAL}"
            CHECK_TIME=${CHECK_TIME_CONNECTED}
            CONNECTED_TIME=0
        fi
    fi
    
    PING_STAT_OLD=${PING_STAT}               # заменяем старое значение состояния новым
   
    if [[ ${MODE_ONCE} -eq 1 ]] ; then      # включен режим однократного запуска
        FLAG_REPEATE=0
    else                                     # уходим спать перед повтором
        SLEEP_TIME=${CHECK_TIME}
        while [[ ${SLEEP_TIME} -ne 0 ]] ; do
            sleep 1s
            SLEEP_TIME=$(expr ${SLEEP_TIME} - 1)
        done
        
        if [[ ${PING_STAT} -eq 0 ]] ; then
            CONNECTED_TIME=$(expr ${CONNECTED_TIME} + ${CHECK_TIME})
        fi
    fi       
done
