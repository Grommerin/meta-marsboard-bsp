#!/bin/sh

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

# все обновления после версии 1.0.0 записывать тут в формате
# DD.MM v1.0.1:
# + что добавлено (функции, параметры, переменные, значения по умолчанию)
# - что удалено (функции, параметры, переменные, значения по умолчанию)
# * что изменено (функции, параметры, переменные, значения по умолчанию)
# ! обратить внимание

# версия программы
PROG_VERSION_MAJOR_=1
PROG_VERSION_MINOR_=0
PROG_VERSION_BUILD_=0

# строка с версией программы (для удобства и лаконичности)
PROG_VERSION="v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_}"

# имя скрипта
SCRIPT_NAME="sysupdate"

# префикс сообщений скрипта
SCRIPT_PREF="SYSUPD"

# файл с версией скрипта
SCRIPT_VER=/home/root/scripts/${SCRIPT_NAME}.ver

# файл лога работы скрипта
LOG_PROG=/var/log/${SCRIPT_NAME}

# файл лога утсройства
LOG_SYSTEM=/home/root/syslog

# флаг повтора скрипта
FLAG_REPEATE=0

# адрес для скачивания файлов
UPDATE_IP=0.0.0.0

# расширение файлов для скачивания
SUPPORTED_SCRIPT_EXT=".sh"

# путь к скриптам
SUPPORTED_SCRIPT_PATH=/home/root/scripts


# количество прочитанных параметров
PARAMS_COUNT=0

# принятые параметры
PARAMS0=10
PARAMS1=0
PARAMS2=0
PARAMS3=0
PARAMS4=0
PARAMS5=0


Debug_log()             # записывает сообщение в файл лога
{
    export TIME_STAMP=$(date +%d.%m\ %H.%M.%S)

    echo -e "${TIME_STAMP} ${1}" >> ${LOG_PROG}
    echo -e "${TIME_STAMP} ${1}" >> ${LOG_SYSTEM}
}

Download_scripts()      # скачивание скриптов
{
    Download_file ${SCRIPT_NAME} ${UPDATE_IP}
}

Set_ip()                # установить ip адрес сервера для скачивания файлов
{
    IP=${1}
    if [[ ${#IP} -ge 7 && ${#IP} -le 15	]] ; then
        UPDATE_IP=${IP}
        echo -e "${SCRIPT_PREF}: update ip is ${UPDATE_IP}"
    fi
    
}

Write_version()         # записывает версию скрипта в файл
{
    echo "${SCRIPT_PREF} ${PROG_VERSION}" > ${SCRIPT_VER}
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
    echo -e "Usage: \t./${SCRIPT_NAME} [-hvo] [-lt] [value]"
    echo -e ""
    echo -e "\tSupported options (not required):"
    echo -e "\t-h, --help"
    echo -e "\t\t\t\t Show this help"
    echo -e ""
    echo -e "\t-v, --version"
    echo -en "\t\t\t\t Print script version"
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
    elif [[ $1 == "-ip" ]] ; then
        Set_ip ${2}
    else
        echo -e "${SCRIPT_PREF}: unknown parameter: ${1}"
        echo -e "Try \"${SCRIPT_NAME} -h\" for a more detailed description"
        exit 
    fi
}

Check_parameters()      # обработка списка параметров
{
    COUNTER_PAR=0
    while [ ${COUNTER_PAR} -ne ${PARAMS_COUNT} ] ; do
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
        while [ ${COUNTER_RD} -ne 0 ] ; do
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

Read_script_parameters $*
# тут инициализируются переменные которые могут быть изменены в процессе работы

# главный цикл
while [ ${FLAG_REPEATE} -eq 1 ] ; do 
    # действия

   
done