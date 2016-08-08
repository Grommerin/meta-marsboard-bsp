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
PROG_VERSION_MINOR_=4
PROG_VERSION_BUILD_=0

# строка с версией программы (для удобства и лаконичности)
PROG_VERSION="v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_}"

# имя скрипта
SCRIPT_NAME="garbcol"

# префикс сообщений скрипта
SCRIPT_PREF="GARBCOL"

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

# режим запуска скрипта только для проверки размера (установить в 1 для запуска)
MODE_CHECK=0

# время между проверками, в секундах
SLEEP_TIME_WORK=600

# максимальный процент занятого места
MAX_USED_SPACE=90

# максимальная глубина поиска в днях от текущего
MAX_FIND_DEEP=30

# минимальная глубина поиска в днях от текущего
MIN_FIND_DEEP=3

# файл со списком удаляемых файлов
DEL_FILE=/var/run/${SCRIPT_NAME}.del

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

Debug_log()             # записывает сообщение в файл лога
{
    export TIME_STAMP=$(date +%d.%m\ %H.%M.%S)
    
    echo -e "${TIME_STAMP} ${1}" >> ${LOG_PROG}
    echo -e "${TIME_STAMP} ${1}" >> ${LOG_SYSTEM}
}

Calc_files_params()   # считает количество и размер удаляемых
{
	FOUND_SIZE=0
    FOUND_COUNT=0
    for FILE in $FOUND_FILES ; do
    	if [[ -e ${FILE} ]] ; then
    	    FOUND_COUNT=$(expr ${FOUND_COUNT} + 1)
    	    FILE_SIZE=$(stat -c %s $FILE)
            FOUND_SIZE=$(expr ${FOUND_SIZE} + ${FILE_SIZE})
    	fi
    done;
#    echo -e "${SCRIPT_PREF}: found ${FOUND_COUNT} files ${FOUND_DEEP:-?} days old. Total size ${FOUND_SIZE}"
}

Find_older_files()     # получить список самых старый файлов с данными
{
	FOUND_DEEP=0
	FIND_DEEP=${MAX_FIND_DEEP}
#	echo -e "${SCRIPT_PREF}: FIND_DEEP=${FIND_DEEP}"
	while [[ ${FIND_DEEP} -ge ${MIN_FIND_DEEP} ]] ; do
		FILE_LIST=$(find /home/root/canlogger/ -mtime +${FIND_DEEP} -name *z_z*)
		if [[ ${#FILE_LIST} -ne 0 ]] ; then
#		    echo -e "${SCRIPT_PREF}: files found"
			FOUND_DEEP=${FIND_DEEP}
            FOUND_FILES=${FILE_LIST}
#			echo -e "${SCRIPT_PREF}: ${FOUND_FILES}"
			FIND_DEEP=0
        else
            FIND_DEEP=$(expr ${FIND_DEEP} - 1)
        fi
	done

    if [[ ${FOUND_DEEP} -ge ${MIN_FIND_DEEP} ]] ; then # найдены старые файлы
#        echo -e "${SCRIPT_PREF}: calc files parameters"
        Calc_files_params      # определяем параметры найденных файлов
    fi
}

Remove_files()         # удаляет полученный список файлов
{
	REMOVED_FILES=""
    for FILE in $FOUND_FILES ; do
    	if [[ -e ${FILE} ]] ; then
            rm -f -- ${FILE}
            NAME=$(basename ${FILE})
            if [[ ${#REMOVED_FILES} -ne 0 ]] ; then
                REMOVED_FILES=${REMOVED_FILES}","
            fi
            REMOVED_FILES=${REMOVED_FILES}${NAME}
    	fi
    done
    Debug_log "${SCRIPT_PREF}: remove ${FOUND_COUNT} files ${FOUND_DEEP} days old. Total size ${FOUND_SIZE}"
    Debug_log "${SCRIPT_PREF}: filenames ${REMOVED_FILES}" 
}

Check_space()          # проверяем занятое место на диске
{
    USED_SPACE=$(df -h /home/ | grep dev | awk '{print $5}' | sed '{s/.$//;}')
}

Set_min_find_deep()    # устанавливает минимальную глубину поиска файлов
{
    DEEP=$1
    if [[ ${DEEP} -le ${MAX_FIND_DEEP} && ${DEEP} -gt 0 ]] ; then
        MIN_FIND_DEEP=${DEEP} 
        echo -e "${SCRIPT_PREF}: min deep to find files: ${MIN_FIND_DEEP}"
    else
        echo -e "${SCRIPT_PREF}: ignore bad min deep value ${DEEP}"
    fi
}

Set_max_find_deep()    # устанавливает максимальную глубину поиска файлов
{
    DEEP=$1
    if [[ ${DEEP} -ge ${MIN_FIND_DEEP} ]] ; then
        MAX_FIND_DEEP=${DEEP} 
        echo -e "${SCRIPT_PREF}: max deep to find files: ${MAX_FIND_DEEP}"
    else
        echo -e "${SCRIPT_PREF}: ignore bad max deep value ${DEEP}"
    fi
}

Set_max_used_space()   # устанавливает максимальный процент заполнения диска
{
	SPACE=$1
    if [[ ${SPACE} -gt 0 && ${SPACE} -lt 100 ]] ; then
        MAX_USED_SPACE=${SPACE}	
        echo -e "${SCRIPT_PREF}: max used space: ${MAX_USED_SPACE}"
    else
        echo -e "${SCRIPT_PREF}: ignore bad space value ${SPACE}"
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

Set_check()             # уставновить режим однократной работы
{
    MODE_CHECK=1
    echo -e "${SCRIPT_PREF}: check mode: true"
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
    echo -en "\t\tLoop mode:        "
    if [[ ${MODE_ONCE} -eq 0 ]] ; then
        echo -e "true"
    else
        echo -e "false"
    fi
    echo -en "\t\tCheck mode:       "
    if [[ ${MODE_CHECK} -eq 0 ]] ; then
        echo -e "false"
    else
        echo -e "true"
    fi
    echo -e "\t\tCheck time:       ${SLEEP_TIME_WORK}s"
    echo -e "\t\tMax used space:   ${MAX_USED_SPACE}%"
    echo -e "\t\tMin deep to find: ${MIN_FIND_DEEP}days"
    echo -e "\t\tMax deep to find: ${MAX_FIND_DEEP}days"
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
    echo -e "Usage: \t./${SCRIPT_NAME} [-hvocs] [-dl -dh -ct] [value]"
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
    echo -e "\t-c, --check"
    echo -e "\t\t\t\t Run the script in only check mode"
    echo -e ""
    echo -e "\t-ct, --ctime [value]"
    echo -e "\t\t\t\t Set value (sec) time between checks (s)"
    echo -e ""
    echo -e "\t-s [value], --space [value]"
    echo -e "\t\t\t\t Set max used space (%)"
    echo -e ""
    echo -e "\t-dl [value], --deepl [value]"
    echo -e "\t\t\t\t Set min deep to find files (days)"
    echo -e ""
    echo -e "\t-dh [value], --deeph [value]"
    echo -e "\t\t\t\t Set max deep to find files (days)"
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
    elif [[ $1 == "-c" || $1 == "--check" ]] ; then
        Set_check
    elif [[ $1 == "-s" || $1 == "--space" ]] ; then
        Set_max_used_space $2
    elif [[ $1 == "-dh" || $1 == "--deeph" ]] ; then
        Set_max_find_deep $2
    elif [[ $1 == "-dl" || $1 == "--deepl" ]] ; then
        Set_min_find_deep $2
    elif [[ $1 == "-ct" || $1 == "--ctime" ]] ; then
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
    Check_space                    # проверяем занятое место
    
    if [[ ${MODE_CHECK} -eq 1 ]] ; then # включен режим только проверки диска
        echo -e "${SCRIPT_PREF}: used ${USED_SPACE}% of space"
        USED_SPACE=0
    fi
    
    if [[ ${USED_SPACE} -ge ${MAX_USED_SPACE} ]] ; then # диск переполнен
        Debug_log "${SCRIPT_PREF}: used ${USED_SPACE}% of space, is greater than border ${MAX_USED_SPACE}%"
        
        Find_older_files           # ищем старейшие файлы с данными
        if [[ ${FOUND_COUNT} -ne 0 && ${FOUND_SIZE} -ne 0 ]] ; then # найдены файлы
            Remove_files           # нещадно удаляем бедолаг
        else
            Debug_log "${SCRIPT_PREF}: can't find files older than ${MAX_FIND_DEEP} days to remove"
        fi
    fi

    if [[ ${MODE_ONCE} -eq 1 ]] ; then       # включен режим однократного запуска
        FLAG_REPEATE=0
    else
        # уходим спать перед повтором
        SLEEP_TIME=${SLEEP_TIME_WORK}
#        echo "${SCRIPT_PREF}: sleep ${SLEEP_TIME}s"
        while [[ ${SLEEP_TIME} -ne 0 ]] ; do
            sleep 1s
            SLEEP_TIME=$(expr ${SLEEP_TIME} - 1)
        done
    fi       
done
