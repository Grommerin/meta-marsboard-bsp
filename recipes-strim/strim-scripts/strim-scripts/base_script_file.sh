#!/bin/sh

# Заготовка для скриптов всяких проверщиков, следильщиков и прочих демонов.
# 
# При старте выводит сообщение с текущей версией скрипта
# 
# Умеет принимать n параметров со значениями. Порядок произвольный. 
# Для увеличения n надо только наплодить переменных PARAMSn сколько нужно
# Из коробки поддерживаются следующие параметры и возможности:
# - вывод помощи (и настроек по умолчанию)
# - однократный запуск скрипта (без зацикливания работы)
# - изменение времени ожидания по окончании петли цикла
# 
# Скрипт может записывать важные сообщения в лог файл, расположеный в $LOG_FILE
# Имеется ограничение размера лога в $LOG_SIZE_MAX байт. 
# После превышения размера старый файл переносится в $LOG_FILE.0
# Для того что бы добавлять запись в лог нужно использовать функцию Debug_log
# Функция принимает строку и записывает ее в лог с меткой времени DD.MM hh.mm.ss
# 
# Для расширения функционала нужно:
# - добавить функцию действия (ниже функции Debug_log)
# - выбрать настройку для действия, если необходимо, задать переменную
# - добавить обработчик действия и условия выполнения в главный цикл
# - если переменная может менять значения, выбрать параметр и записать 
#   функцию его обработки в Handle_parameter
# - добавить описание параметра в Print_help и Print_def_settings
# 
# Не забываем изменять номер версии скрипта при внесении изменений и отслеживать их


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
PROG_VERSION_MAJOR_=0
PROG_VERSION_MINOR_=0
PROG_VERSION_BUILD_=1

# строка с версией программы (для удобства и лаконичности)
PROG_VERSION="v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_}"

# имя скрипта
SCRIPT_NAME="script"

# префикс сообщений скрипта
SCRIPT_PREF="SCRIPT"

# файл с версией скрипта
SCRIPT_VER=/home/root/scripts/${SCRIPT_NAME}.ver

# файл лога работы скрипта
LOG_PROG=/var/log/${SCRIPT_NAME}

# файл лога утсройства
LOG_SYSTEM=/home/root/syslog

# флаг повтора скрипта
FLAG_REPEATE=1

# режим однократного запуска скрипта (установить в 1 для однократного запуска)
MODE_ONCE=0

# время между проверками, в секундах
SLEEP_TIME_WORK=10

# тут записывать свои переменные

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

Set_once()             # уставновить режим однократной работы
{
    MODE_ONCE=1
    echo -e "${SCRIPT_PREF}: loop mode: false"
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
    echo -en "\t\tLoop mode:       "
    if [[ ${MODE_ONCE} -eq 0 ]] ; then
        echo -e "true"
    else
        echo -e "false"
    fi
    echo -e "\t\tLoop time:       ${SLEEP_TIME_WORK}"
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
    echo -e "\t-o, --once"
    echo -e "\t\t\t\t Run the script once"
    echo -e ""
    echo -e "\t-lt [value]"
    echo -e "\t\t\t\t Set value (sec) of loop time"
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
    elif [[ $1 == "-lt" ]] ; then
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
# тут инициализируются переменные которые могут быть изменены в процессе работы
SLEEP_TIME=${SLEEP_TIME_WORK}

# главный цикл
while [[ ${FLAG_REPEATE} -eq 1 ]] ; do 
    # действия

    if [[ ${MODE_ONCE} -eq 1 ]] ; then       # включен режим однократного запуска
        FLAG_REPEATE=0
    else
#        echo "${SCRIPT_PREF}: sleep ${SLEEP_TIME}s"
        # уходим спать перед повтором
        SLEEP_TIME=${SLEEP_TIME_WORK}
        while [[ ${SLEEP_TIME} -ne 0 ]] ; do
            sleep 1s
            SLEEP_TIME=$(expr ${SLEEP_TIME} - 1)
        done
    fi       
done