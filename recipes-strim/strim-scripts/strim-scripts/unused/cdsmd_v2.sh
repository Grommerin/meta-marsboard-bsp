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

# имя скрипта
SCRIPT_NAME="cdsmd"

# префикс сообщений скрипта
SCRIPT_PREF="CDSMD"

# файл лога работы скрипта
LOG_FILE=/var/log/${SCRIPT_NAME}

# максимальный размер файла лога
LOG_SIZE_MAX=1024

# флаг повтора скрипта
FLAG_REPEATE=1

# режим однократного запуска скрипта (установить в 1 для однократного запуска)
MODE_ONCE=0

# имя программы и исполняемого файла
PROG_NAME=canlogger

# путь к программе
PROG_DIR_WORK=/home/root/${PROG_NAME}

# путь к временному хранилищу backup файлов
PROG_DIR_BACK=/media/ramdisk

# рабочий файл программы
PROG_FILE_WORK=${PROG_DIR_WORK}/${PROG_NAME}

# файл с обновлением программы
PROG_FILE_UPD=${PROG_DIR_WORK}/${PROG_NAME}_upd

# файл с backup программы
PROG_FILE_BACK=${PROG_DIR_BACK}/${PROG_NAME}.back

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
    echo -e "${TIME_STAMP} ${1}" >> $LOG_FILE

    if [[ $(stat -c %s $LOG_FILE) -ge ${LOG_SIZE_MAX} ]] ; then
        mv -f ${LOG_FILE} ${LOG_FILE}.0
    fi
}

Give_rights()           # выдает файлу права на исполнение
{
	echo -e "${SCRIPT_PREF}: Give_rights()"
	FILE=$1
    if [[ -e ${FILE} ]] ; then
	    chmod +x ${FILE}
    fi
}

Check_backup_file()     # проверяет наличие backup файла
{
	echo -e "${SCRIPT_PREF}: Check_backup_file()"
    if [[ -e ${PROG_FILE_BACK} ]] ; then
        PROG_FILE_BACK_MD5SUM=$(md5sum ${PROG_FILE_BACK} | awk '{print $1}')
        return 0
    fi
    
    return 1
}

Check_update_file()     # проверяет наличие файла обновления
{
	echo -e "${SCRIPT_PREF}: Check_update_file()"
    if [[ -e ${PROG_FILE_UPD} ]] ; then
        PROG_FILE_UPD_MD5SUM=$(md5sum ${PROG_FILE_UPD} | awk '{print $1}')
        Debug_log "${SCRIPT_PREF}: found update file, md5sum ${PROG_FILE_UPD_MD5SUM}"
        return 0
    fi
    
    return 1
}

Backup_work_file()      # делает backup исполняемого файла программы
{
	echo -e "${SCRIPT_PREF}: Backup_work_file()"
    if [[ -e ${PROG_FILE_UPD} ]] ; then
        cp -f ${PROG_FILE_WORK} ${PROG_FILE_BACK}  # бэкапим файл
        # проверяем как прошло 
        if [[ -e ${PROG_FILE_BACK} ]] ; then      # backup готов
            PROG_FILE_WORK_MD5SUM=$(md5sum ${PROG_FILE_WORK} | awk '{print $1}')
            PROG_FILE_BACK_MD5SUM=$(md5sum ${PROG_FILE_BACK} | awk '{print $1}')
       
            # проверяем контрольные суммы
            if [[ ${PROG_FILE_BACK_MD5SUM} == ${PROG_FILE_WORK_MD5SUM} ]] ; then
                echo -n ""
            else
                # жаль, не прокатил backup
                echo -e "${SCRIPT_PREF}: backup file md5sum not valid"
                Debug_log "${SCRIPT_PREF}: backup file damaged, md5sum not valid"
                return 1
            fi
        fi
    fi
    return 0
}

Update_work_file()      # заменяет исполняемый файл программы на обновленный
{   
	echo -e "${SCRIPT_PREF}: Update_work_file()"
	if [[ -e ${PROG_FILE_UPD} ]] ; then
        cp -f ${PROG_FILE_UPD} ${PROG_FILE_WORK}     # заменяем исполняемый файл
	    PROG_FILE_WORK_MD5SUM=$(md5sum ${PROG_FILE_WORK} | awk '{print $1}')
	    # проверяем как прошло
	    if [[ ${PROG_FILE_WORK_MD5SUM} == ${PROG_FILE_UPD_MD5SUM} ]] ; then
	        echo -n ""
        else
            # все плохо
            echo -e "${SCRIPT_PREF}: replace file error, checksum will not match"
            Debug_log "${SCRIPT_PREF}: replace file error, checksum will not match"
            return 1
        fi
    fi

    return 0
}

Restore_backup_file()  # востанавливает backup файл
{
	echo -e "${SCRIPT_PREF}: Restore_backup_file()"
	if [[ -e ${PROG_FILE_BACK} ]] ; then
	    PROG_FILE_BACK_MD5SUM=$(md5sum ${PROG_FILE_BACK} | awk '{print $1}')
	    cp -f ${PROG_FILE_BACK} ${PROG_FILE_WORK}
	    PROG_FILE_WORK_MD5SUM=$(md5sum ${PROG_FILE_WORK} | awk '{print $1}')
	    # проверяем как прошло
        if [[ ${PROG_FILE_WORK_MD5SUM} == ${PROG_FILE_BACK_MD5SUM} ]] ; then
            echo -n ""
        else
            # уже не просто плохо, а прям жопа 
            Debug_log "${SCRIPT_PREF}: restore file error, checksum will not match"
            return 1
        fi
    fi
    
    return 0
}


Remove_file()          # удаляет файл
{
	echo -e "${SCRIPT_PREF}: Remove_file() ${1}"
	FILE=$1
    if [[ -e ${FILE} ]] ; then
        rm -f ${FILE}
    fi
}

Check_program_state()  # проверяет статус работы программы
{
    echo -e "${SCRIPT_PREF}: Check_program_state()"
    PROG_PID=$(pidof ${PROG_NAME})
    if [[ ${#PROG_PID} -eq 0 ]] ; then
        return 1
    fi
    
    return 0
}

Start_program()        # запускает программу на исполнение
{
	echo -e "${SCRIPT_PREF}: Start_program()"
	PROG_PID=$(pidof ${PROG_NAME})
	if [[ ${#PROG_PID} -eq 0 ]] ; then
        ${PROG_FILE_WORK} &
        sleep 1s
    fi
}


Stop_program() 
{
	echo -e "${SCRIPT_PREF}: Stop_program()"
	PROG_PID=$(pidof ${PROG_NAME})
	echo -e "${SCRIPT_PREF}: PROG_PID = ${PROG_PID:-null}"
	if [[ ${#PROG_PID} -ne 0 ]] ; then
        kill -s SIGTERM $(pidof ${PROG_NAME})
        
        SLEEP_TIME=10
        echo -e "${SCRIPT_PREF}: SLEEP_TIME = ${SLEEP_TIME}"
        while [[ ${SLEEP_TIME} -ne 0 && ${#PROG_PID} -ne 0 ]] ; do
            sleep 1s
            SLEEP_TIME=$(expr ${SLEEP_TIME} - 1)
            PROG_PID=$(pidof ${PROG_NAME})
            echo -e "${SCRIPT_PREF}: SLEEP_TIME = ${SLEEP_TIME}"
        done
        
        PROG_PID=$(pidof ${PROG_NAME})
        if [[ ${#PROG_PID} -ne 0 ]] ; then
            kill -s SIGKILL $(pidof ${PROG_NAME})
        fi
    fi
    echo
}   

Restart_program() 
{ 
	echo -e "${SCRIPT_PREF}: Restart_program()"
    Stop_program
    echo
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

Handle_parameter()      # обрабатываем параметр
{
    if [[ $1 == "-h" || $1 == "--help" ]] ; then
        Print_help 
        exit
    elif [[ $1 == "-o" || $1 == "--once" ]] ; then
        Set_once
    elif [[ $1 == "-start" ]] ; then
        echo -n ""
    elif [[ $1 == "-restart" ]] ; then
        Restart_program
    elif [[ $1 == "-stop" ]] ; then
        Stop_program
        exit 0
    else
        echo -e "${SCRIPT_PREF}: unknown parameter: ${1}" 
    fi
}

Print_def_settings()    # вывести настройки по умолчанию
{
    echo -e "\tDefault settings:"
    echo -en "\t\tLoop mode:          "
    if [[ ${MODE_ONCE} -eq 0 ]] ; then
        echo -e "true"
    else
        echo -e "false"
    fi
    echo -e "\t\tProgram name:       ${PROG_NAME}"
    echo -e "\t\tProgram work file:  ${PROG_FILE_WORK}"
    echo -e "\t\tProgram upd file:   ${PROG_FILE_UPD}"
    echo -e "\t\tProgram back file:  ${PROG_FILE_BACK}"
}

Print_help()           # помощь
{
    echo -e ""
    echo -e "Usage: \t./${SCRIPT_NAME} [-ho lt] [value]"
    echo -e ""
    echo -e "\tSupported options (not required):"
    echo -e "\t-h, --help"
    echo -e "\t\t\t\t Show this help"
    echo -e ""
    echo -e "\t-o, --once"
    echo -e "\t\t\t\t Run the script once"
    echo -e ""
    echo -e "\t-start"
    echo -e "\t\t\t\t Start work daemon and program"
    echo -e ""
    echo -e "\t-stop"
    echo -e "\t\t\t\t Stop work program and stop daemon"
    echo -e ""
    echo -e "\t-restart"
    echo -e "\t\t\t\t Restart program and daemon"
    echo -e ""
    Print_def_settings
    echo -e ""
    echo -e "\tCurrent daemon version: ${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_}"
    echo -e ""
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

Start_message()           # вывод стартового сообщения при запуске
{ 
    echo -e "${SCRIPT_PREF}: v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_} started"
    Debug_log "${SCRIPT_PREF}: v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_} started"
}

Start_message_p()         # вывод стартового сообщения при запуске с параметрами
{ 
    echo -e "${SCRIPT_PREF}: v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_} started at mode ${*}"
    Debug_log "${SCRIPT_PREF}: v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_} started with parameters ${*}"
}

Read_script_parameters()  # обработка параметров запуска скрипта
{
    if [[ -z "$*" ]] ; then
        Start_message
    else
        Start_message_p $*
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

trap 'Sig_quit' QUIT
trap 'Sig_term' TERM
trap 'Sig_int'  INT

Read_script_parameters $*
# тут инициализируются переменные которые могут быть изменены в процессе работы
FLAG_UPDATE=0          # флаг готовности обновления программы

# главный цикл
while [ ${FLAG_REPEATE} -eq 1 ] ; do 
    Check_update_file                       # проверяем есть ли файл с обновлениями
    if [[ $? -eq 0 ]] ; then               # есть такой файл
    	echo -e "${SCRIPT_PREF}: return $?"
    	Give_rights ${PROG_FILE_UPD}        # выдаем ему прав на исполнение
        Backup_work_file                    # делаем backup старого файла
        if [[ $? -eq 0 ]] ; then           # сделано
        	echo -e "${SCRIPT_PREF}: return $?"
            Update_work_file                # заменяем рабочий файл обновленным
        fi
    fi
    
    Remove_file ${PROG_FILE_UPD}            # удаляем файл обновления
    
    Start_program                           # запускаем программу в работу
    Check_program_state                     # проверяем статус программы
    if [[ $? -ne 0 ]] ; then               # программа не запустилась
    	echo -e "${SCRIPT_PREF}: return $?"
        Check_backup_file                   # проверяем есть ли backup файл
        if [[ $? -eq 0 ]] ; then           # есть
        	echo -e "${SCRIPT_PREF}: return $?"
            Restore_backup_file
            if [[ $? -eq 0 ]] ; then       # есть
            	echo -e "${SCRIPT_PREF}: return $?"
                Start_program
                Check_program_state         # проверяем статус программы
                if [[ $? -eq 0 ]] ; then   # программа запустилась
                	echo -e "${SCRIPT_PREF}: return $?"
                    Remove_file ${PROG_FILE_BACK}
                fi
            fi
        fi
    fi

    if [[ ${MODE_ONCE} -eq 1 ]] ; then       # включен режим однократного запуска
        FLAG_REPEATE=0
    else
        # ждем завершения процесса
        wait $(pidof ${PROG_NAME})
    fi       
done
