#!/bin/sh

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi


# версия программы
PROG_VERSION_MAJOR_=2
PROG_VERSION_MINOR_=0
PROG_VERSION_BUILD_=0

# строка с версией программы (для удобства и лаконичности)
PROG_VERSION="v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_}"

# имя скрипта
SCRIPT_NAME="synctime"

# префикс сообщений скрипта
SCRIPT_PREF="SYNCTIME"

# файл с версией скрипта
SCRIPT_VER=/home/root/scripts/${SCRIPT_NAME}.ver

# файл лога работы скрипта
LOG_PROG=/var/log/${SCRIPT_NAME}

# файл лога устройства
LOG_SYSTEM=/home/root/syslog

# флаг повтора скрипта
FLAG_REPEATE=1

# режим однократного запуска скрипта (установить в 1 для однократного запуска)
MODE_ONCE=0

# уставновить в 1 для перезапуска ntpd после каждой успешной проверки соединения
MODE_FORCE_RESTART=0

# адрес для проверки соединения
GSM_PING_IP=8.8.8.8

# количество запросов ping в серии для проверки состояния соединения
GSM_PING_COUNT=7

# размер пакета для проверки состояния соединения
GSM_PING_SIZE=8

# время между проверками при установленном соединении
CHECK_TIME_CONNECTED=10

# время между проверками при отсутствующем соединении
CHECK_TIME_DISCONNECTED=5

# флаг состояния соединения (изменяется с помощью проверки ping)
# 0 - соединение установлено
# 1 - соединение отсутствует
PING_STAT=1

# флаг предыдущего состояния соединения (для перезапуска ntpd после разрыва)
# 0 - соединение установлено
# 1 - соединение отсутствует
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

Set_ping_ip()          # устанавливаем ip адрес проверки соединения
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

Set_force_restart()    # перезапускать ntpd после каждой проверки
{
    MODE_FORCE_RESTART=1
    echo -e "${SCRIPT_PREF}: force restart: true"
}

Set_once()             # уставновить режим однократной работы
{
    MODE_ONCE=1
    echo -e "${SCRIPT_PREF}: loop mode: false"
}

Check_connect()        # проверка статуса соединения
{
    # проверяем есть ли коннект или само соединение (вернет >0 если нет)
    PING_STAT=$(ping -q -c 1 -s ${GSM_PING_SIZE} ${GSM_PING_IP} -I ppp0 2<&1 | grep -icE 'bad|unknown|expired|unreachable|time out')

    # проверяем состояние соедниения
    if [[ ${PING_STAT} -eq 0 ]] ; then
        ping -q -c ${GSM_PING_COUNT} -s ${GSM_PING_SIZE} ${GSM_PING_IP} &> /dev/null
        PING_STAT=$?
    fi
}

Ntpd_start()           # запустить ntpd
{
	Debug_log "${SCRIPT_PREF}: start ntpd"
    nohup /etc/init.d/ntpd start >> /dev/null &
#    echo "${SCRIPT_PREF}: start ntpd" 
}

Ntpd_restart()         # перезапустить ntpd
{
	Debug_log "${SCRIPT_PREF}: restart ntpd"
    nohup /etc/init.d/ntpd restart >> /dev/null &
#    echo "${SCRIPT_PREF}: restart ntpd" 
}

Ntpd_stop()            # остановить ntpd
{
	Debug_log "${SCRIPT_PREF}: stop ntpd"
    nohup /etc/init.d/ntpd stop >> /dev/null &
#    echo "${SCRIPT_PREF}: stop ntpd" 
}

Ntpd_kill()            # "убить" ntpd
{
	Debug_log "${SCRIPT_PREF}: kill ntpd"
    NTP_PID_C=$(pidof ntpd)
    while [[ ${#NTP_PID_C} -ne 0 ]] ; do
        NTP_PID=$(pidof ntpd | awk '{print $1}')
        kill ${NTP_PID}
        NTP_PID_C=$(pidof ntpd)
    done
}

Refresh_ntpd()         # перезапуск демона ntpd
{
    NTP_PID_C=$(pidof ntpd)
    if [[ ${#NTP_PID_C} -ne 0 ]] ; then
        Ntpd_kill                  # если хоть одна копия запущена убиваем все
    fi

    Ntpd_start                     # запускаем единственную копию ntpd
}

Sig_quit()
{
   Debug_log "${SCRIPT_PREF}: signal QUIT received, exit"
   exit 0
}

Sig_term()
{
   Debug_log "${SCRIPT_PREF}: signal TERM received, exit"
   exit 0
}

Sig_int()
{
   Debug_log "${SCRIPT_PREF}: signal INT received, exit"
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
    if [[ ${MODE_FORCE_RESTART} -eq 1 ]] ; then
        echo -e "true"
    else
        echo -e "false"
    fi
    echo -e "\t\tPing ip:                 ${GSM_PING_IP}"
    echo -e "\t\tPing pack count:         ${GSM_PING_COUNT}"
    echo -e "\t\tPing pack size:          ${GSM_PING_SIZE}"
    echo -e "\t\tLog file:                ${LOG_PROG}"
    echo -e "\t\tSystem log file:         ${LOG_SYSTEM}"
    echo -e "\t\tConnected check time:    ${CHECK_TIME_CONNECTED}s"
    echo -e "\t\tDisconnected check time: ${CHECK_TIME_DISCONNECTED}s"
}

Print_version()        # выводит сообщение с версией скрипта
{
	echo -e "${SCRIPT_PREF} ${PROG_VERSION} by Strim Ltd."
}

Print_help()           # помощь
{
    echo -e ""
    Print_version
    echo -e "" 
    echo -e "Usage: \t./${SCRIPT_NAME} [-hvof] [-ct -dt -ip -ps -pc] [value]"
    echo -e ""
    echo -e "\tSupported options (not required):"
    echo -e "\t-h, --help"
    echo -en "\t\t\t\t Show this help"
    echo -e ""
    echo -e "\t-v, --version"
    echo -en "\t\t\t\t Print script version"
    echo -e ""
    echo -e "\t-o, --once"
    echo -en "\t\t\t\t Run the script once"
    echo -e ""
    echo -e "\t-f, --force"
    echo -en "\t\t\t\t Restart ntpd in each loop"
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
    elif [[ $1 == "-o" || $1 == "--once" ]] ; then
        Set_once
    elif [[ $1 == "-f" || $1 == "--force" ]] ; then
        Set_force_restart
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
    else
        echo -e "${SCRIPT_PREF}: unknown parameter: ${1}" 
        echo -e "Try \"${SCRIPT_NAME} -h\" for a more detailed description"
        exit
    fi
}

Check_parameters()       # обработка списка параметров
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
#    echo -e "${SCRIPT_PREF}: ${PROG_VERSION} started"
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
# значение таймера сна для изменения интервала согласно статуса соединения
CHECK_TIME=${CHECK_TIME_DISCONNECTED}

Refresh_ntpd # остановим ntpd и запустим его вновь (проще работать дальше)

# главный цикл
while [[ ${FLAG_REPEATE} -eq 1 ]] ; do	
    Check_connect                           # проверка статуса соединения
    
    if [[ ${PING_STAT} -eq 0 ]] ; then      # соединение установлено
        if [[ ${MODE_FORCE_RESTART} -eq 1 ]] ; then
            # типа в прошлый раз все было плохо и только что запустилось соединение
            PING_STAT_OLD=1
        fi
                
        if [[ ${PING_STAT_OLD} -ne 0 ]] ; then  # проверяем прошлое состояние    
            # соединение только что установилось 
            CHECK_TIME=${CHECK_TIME_CONNECTED}
            
            # проверяем запущен ли демон ntpd
            NTP_PID_C=$(pidof ntpd)
            if [[ ${#NTP_PID_C} -ne 0 ]] ; then   # ntpd запущен, перезапускаем
#                Ntpd_restart  
                Refresh_ntpd
            else                            # чего-то он не был запушен, стартуем
                Ntpd_start    
            fi
            
            # заново проверяем статус демона ntpd на случай сбоя перезапуска
            NTP_PID_C=$(pidof ntpd)
            if ! [[ ${#NTP_PID_C} -ne 0 ]] ; then
                # упс, что-то не сработало, новая попытка
                Ntpd_start
                Debug_log "${SCRIPT_PREF}: ntpd does't restart on the first try"
            fi  
        fi 
    else                                         # соединение разорвано
        if [[ ${PING_STAT_OLD} -eq 0 ]] ; then 
            # если соединение только что разорвалось
            CHECK_TIME=${CHECK_TIME_DISCONNECTED}
        fi
    fi
    
    PING_STAT_OLD=${PING_STAT}          # заменяем старое значение состояния новым
   
    if [[ ${MODE_ONCE} -eq 1 ]] ; then       # включен режим однократного запуска
        FLAG_REPEATE=0
    else
        # уходим спать перед повтором
        SLEEP_TIME=${CHECK_TIME}
#        echo "${SCRIPT_PREF}: sleep ${SLEEP_TIME}s"
        while [[ ${SLEEP_TIME} -ne 0 ]] ; do
            sleep 1s
            SLEEP_TIME=$(expr ${SLEEP_TIME} - 1)
        done
    fi       
done
