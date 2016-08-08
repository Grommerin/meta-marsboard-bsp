#!/bin/sh

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

# версия программы
PROG_VERSION_MAJOR_=1
PROG_VERSION_MINOR_=1
PROG_VERSION_BUILD_=0

# строка с версией программы (для удобства и лаконичности)
PROG_VERSION="v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_}"

# имя скрипта
SCRIPT_NAME="backlog"

# префикс сообщений скрипта
SCRIPT_PREF="BACKLOG"

# файл с версией скрипта
SCRIPT_VER=/home/root/scripts/${SCRIPT_NAME}.ver

# файл лога работы скрипта
LOG_PROG=/var/log/${SCRIPT_NAME}

# файл лога устройства
LOG_SYSTEM=/home/root/syslog

# файл лога уровней сигнала
LOG_SIGNAL=/home/root/gsmmonitor/signal.log

# максимальный размер файла лога
LOG_SIZE_MAX=204800

# глубина логирования
LOG_BACKUP_DEEP=11

# флаг повтора скрипта
FLAG_REPEATE=1

# режим однократного запуска скрипта (установить в 1 для однократного запуска)
MODE_ONCE=1

# время между проверками, в секундах
SLEEP_TIME_WORK=30

# количество прочитанных параметров
PARAMS_COUNT=0

# принятые параметры
PARAMS0=10
PARAMS1=0
PARAMS2=0
PARAMS3=0
PARAMS4=0
PARAMS5=0


Backup_log_signal()            # создает и ведет архив лога за много времени
{
    if ! [[ -e ${LOG_SIGNAL} ]] ; then    # проверка есть ли такой файл
        touch ${LOG_SIGNAL}
    fi
    
    if [[ $(stat -c %s ${LOG_SIGNAL}) -ge ${LOG_SIZE_MAX} ]] ; then
        LOGNUM_OLD=$(expr ${LOG_BACKUP_DEEP} - 1)
        LOGNUM_NEW=${LOG_BACKUP_DEEP}
        while [[ ${LOGNUM_OLD} -gt 0 ]] ; do
            if [[ -e ${LOG_SIGNAL}.${LOGNUM_OLD}.gz ]] ; then
                mv -f ${LOG_SIGNAL}.${LOGNUM_OLD}.gz ${LOG_SIGNAL}.${LOGNUM_NEW}.gz
            fi
            LOGNUM_OLD=$(expr ${LOGNUM_OLD} - 1)
            LOGNUM_NEW=$(expr ${LOGNUM_NEW} - 1)
        done
       
        if [[ -e ${LOG_SIGNAL}.0 ]] ; then
            mv -f ${LOG_SIGNAL}.0 /var/log/signal.temp
            tar -czf ${LOG_SIGNAL}.1.gz /var/log/signal.temp >> /dev/null
        fi
        mv -f ${LOG_SIGNAL} ${LOG_SIGNAL}.0
    fi  
}

Backup_log_system()            # создает и ведет архив лога за много времени
{
    if ! [[ -e ${LOG_SYSTEM} ]] ; then    # проверка есть ли такой файл
        touch ${LOG_SYSTEM}
    fi
    
    if [[ $(stat -c %s ${LOG_SYSTEM}) -ge ${LOG_SIZE_MAX} ]] ; then
        LOGNUM_OLD=$(expr ${LOG_BACKUP_DEEP} - 1)
        LOGNUM_NEW=${LOG_BACKUP_DEEP}
        while [[ ${LOGNUM_OLD} -gt 0 ]] ; do
            if [[ -e ${LOG_SYSTEM}.${LOGNUM_OLD}.gz ]] ; then
                mv -f ${LOG_SYSTEM}.${LOGNUM_OLD}.gz ${LOG_SYSTEM}.${LOGNUM_NEW}.gz
            fi
            LOGNUM_OLD=$(expr ${LOGNUM_OLD} - 1)
            LOGNUM_NEW=$(expr ${LOGNUM_NEW} - 1)
        done
       
        if [[ -e ${LOG_SYSTEM}.0 ]] ; then
            mv -f ${LOG_SYSTEM}.0 /var/log/syslog.temp
            tar -czf ${LOG_SYSTEM}.1.gz /var/log/syslog.temp >> /dev/null
        fi
        mv -f ${LOG_SYSTEM} ${LOG_SYSTEM}.0
    fi  
}

Debug_log()             # записывает сообщение в файл лога
{
    export TIME_STAMP=$(date +%d.%m\ %H.%M.%S)
    
    echo -e "${TIME_STAMP} ${1}" >> ${LOG_PROG}
    echo -e "${TIME_STAMP} ${1}" >> ${LOG_SYSTEM}
}

Set_log_size()         # устанавливаем максимальный размер лога
{
	SIZE=$1
	if [[ ${SIZE} ]] ; then
	    LOG_SIZE_MAX=${SIZE}
	    echo -e "${SCRIPT_PREF}: log size max: ${LOG_SIZE_MAX}"
    fi
}

Set_loop_time()        # устанавливаем время цикла
{
    NEW_TIME=$1
    SEACH_S=$(expr index "${NEW_TIME}" "s")
    if [[ ${SEACH_S} -ne 0 ]] ; then
        NEW_TIME=&{NEW_TIME%?}
    fi
    SLEEP_TIME_WORK=${NEW_TIME}
    echo -e "${SCRIPT_PREF}: loop time: ${SLEEP_TIME_WORK}"
}

Set_repeate()             # установить режим циклической работы
{
    MODE_ONCE=0
    echo -e "${SCRIPT_PREF}: loop mode: true"
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
    echo -e "\t\tLog file:                ${LOG_PROG}"
    echo -e "\t\tSystem log file:         ${LOG_SYSTEM}"
    echo -e "\t\tSystem log max size:     ${LOG_SIZE_MAX}"
    echo -e "\t\tSystem log back deep:    ${LOG_BACKUP_DEEP}"
    echo -e "\t\tLoop time:               ${SLEEP_TIME_WORK}"
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
    echo -e "Usage: \t./${SCRIPT_NAME} [-hvr] [-lt] [value]"
    echo -e ""
    echo -e "\tSupported options (not required):"
    echo -e "\t-h, --help"
    echo -e "\t\t\t\t Show this help"
    echo -e ""
    echo -e "\t-v, --version"
    echo -en "\t\t\t\t Print script version"
    echo -e ""
    echo -e "\t-r, --repeate"
    echo -e "\t\t\t\t Run the script in repeate mode"
    echo -e ""
    echo -e "\t-ls, --logsize [value]"
    echo -e "\t\t\t\t Set value of max log size (bytes)"
    echo -e ""
    echo -e "\t-lt, --ltime [value]"
    echo -e "\t\t\t\t Set value of loop time (sec)"
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
    elif [[ $1 == "-r" || $1 == "--repeate" ]] ; then
        Set_repeate
    elif [[ $1 == "-ls" || $1 == "--logsize" ]] ; then
        Set_log_size $2
    elif [[ $1 == "-lt" || $1 == "--ltime" ]] ; then
        Set_loop_time $2
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

# главный цикл
while [[ ${FLAG_REPEATE} -eq 1 ]] ; do 
    if [[ ${MODE_ONCE} -ne 0 ]] ; then     # включен режим однократного запуска
        FLAG_REPEATE=0
    fi
    
#    echo "${SCRIPT_PREF}: sleep ${SLEEP_TIME}s"
    # уходим спать для задержки
    SLEEP_TIME=${SLEEP_TIME_WORK}
    while [[ ${SLEEP_TIME} -ne 0 ]] ; do
        sleep 1s
        SLEEP_TIME=$(expr ${SLEEP_TIME} - 1)
    done   
    
    Backup_log_system                              # бэкапим лог системы
    Backup_log_signal                              # бэкапим лог сигналов
done