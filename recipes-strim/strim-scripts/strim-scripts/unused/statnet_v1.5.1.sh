#!/bin/sh

if [ -f /etc/init.d/functions ] ; then
        . /etc/init.d/functions
elif [ -f /etc/rc.d/init.d/functions ] ; then
        . /etc/rc.d/init.d/functions
else
        exit 0
fi

# все обновления после версии 1.0.0 записывать тут в формате
# DD.MM v1.0.0:
# + что добавлено (функции, параметры, переменные, значения по умолчанию)
# - что удалено (функции, параметры, переменные, значения по умолчанию)
# * что изменено (функции, параметры, переменные, значения по умолчанию)
# ! обратить внимание

# 21.11 v1.1.0:
# + функция сообщения в консоль о запуске скрипта с параметрами Start_message_p
# + сообщение в консоль и лог о запуске скрипта когда он вызывается с параметрами
#   (параметры запуска записываются в лог)
# + добавлены функции обработки сигналов Sig_quit и Sig_int (завершают работу)
# + добавлена обработка сигналов QUIT, INT, TERM
# + добавлены сообщения в лог о прерывании работы скрипта сигналами QUIT, INT, TERM
# + добавлено ожидание при первом запуске 
# * все операции сравнения между числами заменены на верные (-eq вместо == и т.п.)
# * уточнены названия переменных режимов работы, к ним добавлен префикс MODE_
# * уточнено название флага циклической работы, к нему добавлен префикс FLAG_
# * исправлено описание режима MODE_ONCE
# * изменены внешние вызовы на современные в функциях
#   Pppd_kill
#   `pidof pppd` --> $(pidof pppd)
#   `pidof pppd | awk '{print $1}'` --> $(pidof pppd | awk '{print $1}')
#   Cdsm_kill
#   `pidof canlogger` --> $(pidof canlogger)
#   `pidof canlogger | awk '{print $1}'` --> $(pidof canlogger | awk '{print $1}')
#   Debug_log
#   `date +%d.%m\ %H.%M.%S` --> $(date +%d.%m\ %H.%M.%S)
# * изменен алгоритм сна скрипта. Теперь засыпание происходит не на установленный
#   неразрывный промежуток времени T секунд, а на T промежутков длительностью 1 сек
#   (для того что бы сигналы отрабатывались корректно и быстро)
# * все арифметические операции вида $(( $VAR+1 )) и подобные заменены корректными
#   POSIX Shell выражениями &(expr ${VAR} + 1) и подобными
# ! в дальнейшем следить за правильными сравнениями (== и подобные только для строк)
# ! не использовать выражения вида $(()), использовать только $(expr )

# 24.11 v1.2.0:
# + в главный цикл добавлена обработка события "соединение установлено"
# + добавлено сообщение в лог при установке соединения после разрыва

# 28.11 v1.3.0:
# + Добавлена переменная PROG_VERSION, содержащая строку с версией скрипта в виде
#   "v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_}"
# + Добавлена новая поддерживаемая команда
#   -v, --version - Вывод сообщения с версией скрипта
# + Добавлена функция Print_version, выводящая номер версии скрипта
# - Удалена функция Start_message_p за ненадобностью
# - Из функции Start_message убрано сообщение в консоль о запуске скрипта
# * Изменен вывод версии скрипта в Print_help
# * Функция Start_message изменена для поддержки вызовов с параметрами и без них
# * Переименована функция Start_message
#   Start_message --> Print_start_message

# 30.11 v1.4.0:
# + Добавлена переменная PPPD_LOG, содержащая путь к файлу логов pppd
# + В основной цикл добавлен поиск последнего значения уровня сигнала модема
# + Добавлена функция Calc_gsm_signal, рассчитывающая значение GSM сигнала
# * В сообщение лога о востановлении соединения добавлено значение уровня сигнала

# 02.12 v1.4.1:
# * Изменена строка с советом по использованию скрипта в функции Print_help
# * При вызове скрипта с неизвестным параметром он выводит сообщение с 
#   подсказкой и завершает работу

# 03.12 v1.5.0:
# + Добавлена переменная LOG_SYSTEM в которой хранится адрес общего лога системы
# * Изменено имя переменной лог файла
#   LOG_FILE --> LOG_PROG
# * Изменен максимальный размер лог файла
# * Изменена функция Debug_log:
#   функция ведет запись сообщений и в системный лог и в свой собственный
#   изменена проверка максимального размера лог файла (теперь для системного)
#   изменения в алгоритме замены лога после превышения размера (системный лог
#   теперь имеет два резервных файла что увеличит время резервирования в 3 раза
#   изменен порядок действий внутри функции

# 05.15 v1.5.1:
# * Исправление в значении переменной PING_STAT_OLD по умолчанию:
#   PING_STAT_OLD=0 --> PING_STAT_OLD=1

# версия программы
PROG_VERSION_MAJOR_=1
PROG_VERSION_MINOR_=5
PROG_VERSION_BUILD_=0

# строка с версией программы (для удобства и лаконичности)
PROG_VERSION="v${PROG_VERSION_MAJOR_}.${PROG_VERSION_MINOR_}.${PROG_VERSION_BUILD_}"

# имя скрипта
SCRIPT_NAME="statnet"

# префикс сообщений скрипта
SCRIPT_PREF="STATNET"

# файл лога работы скрипта
LOG_PROG=/var/log/${SCRIPT_NAME}

# файл лога утсройства
LOG_SYSTEM=/home/root/syslog

# максимальный размер файла лога
LOG_SIZE_MAX=204800

# адрес для записи команды перезагрузки модема
GSM_RESTART_ADDR=/sys/class/gpio/gpio43/value

# путь к логу pppd
PPPD_LOG=/var/log/pppdebug

# количество проваленных проверок соединения перед перезапуском модема
GSM_RESTART_COUNTER=5

# флаг повтора скрипта
FLAG_REPEATE=1

# режим однократного запуска скрипта (установить в 1 для однократного запуска)
MODE_ONCE=0

# уставновить в 1 для перезапуска программ после каждого разрыва соединения
ALWAYS_RESTART=0

# адрес для проверки соединения
PING_IP=8.8.8.8

# время между проверками
SLEEP_TIME_WORK=120

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


Debug_log()             # записывает сообщение в файл лога
{
    export TIME_STAMP=$(date +%d.%m\ %H.%M.%S)
     
    if [[ -e ${LOG_SYSTEM} ]] ; then    # проверка есть ли такой файл
        echo -n ""
    else
        touch ${LOG_SYSTEM}
    fi
    
    if [[ $(stat -c %s ${LOG_SYSTEM}) -ge ${LOG_SIZE_MAX} ]] ; then
        if [[ -e ${LOG_SYSTEM}.0 ]] ; then
            mv -f ${LOG_SYSTEM}.0 ${LOG_SYSTEM}.1
        fi
        mv -f ${LOG_SYSTEM} ${LOG_SYSTEM}.0
    fi
    
    echo -e "${TIME_STAMP} ${1}" >> ${LOG_PROG}
    echo -e "${TIME_STAMP} ${1}" >> ${LOG_SYSTEM}
}

Set_loop_time()         # устанавливаем время цикла
{
    NEW_TIME=$1
    SEACH_S=$(expr index "${NEW_TIME}" "s")
    if [[ ${SEACH_S} -ne 0 ]] ; then
        NEW_TIME=&{NEW_TIME%?}
    fi
    SLEEP_TIME_WORK=${NEW_TIME}
    echo -e "${SCRIPT_PREF}: loop time: ${SLEEP_TIME_WORK}"
}

Set_ping_ip()           # устанавливаем ip адрес проверки соединения
{
    IP=$1
    if [[ $IP ]] ; then
        PING_IP=${IP}
        echo -e "${SCRIPT_PREF}: ping ip: ${PING_IP}"
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

Set_restart_counter()   # установить количество проверок до перезапуска модема
{
	RESTART_COUNTER=$1
    if [[ $RESTART_COUNTER ]] ; then
    	GSM_RESTART_COUNTER=${RESTART_COUNTER}
        echo -e "${SCRIPT_PREF}: restart counter: ${GSM_RESTART_COUNTER}"
    fi
}

Check_connect()         # проверка статуса соединения
{
    ping -q -c5 ${PING_IP} &> /dev/null
    PING_STAT=$?
#    echo -e "${SCRIPT_PREF}: check connect = ${PING_STAT}"
}

Gsm_modem_restart()     # перезапустить gsm модем
{
	if [[ -e $GSM_RESTART_ADDR ]] ; then
		echo -e "${SCRIPT_PREF}: restart gsm modem"
		Debug_log "${SCRIPT_PREF}: restart gsm modem"
        echo "1" > ${GSM_RESTART_ADDR}
        sleep 1s
        echo "0" > ${GSM_RESTART_ADDR}
        sleep 1s
    else
        echo -e "${SCRIPT_PREF}: restart gsm modem error, no file"
        Debug_log "${SCRIPT_PREF}: restart gsm modem error, no file"
    fi
}

Pppd_kill()             # "убить" процесс pppd
{
    PPPD_PID_C=$(pidof pppd)
    if [[ ${#PPPD_PID_C} -ne 0 ]] ; then
        PPPD_PID=$(pidof pppd | awk '{print $1}')
        kill -s HUP ${PPPD_PID}
#        echo -e "${SCRIPT_PREF}: kill pppd"
    else
        echo -n ""
#        echo -e "${SCRIPT_PREF}: pppd not runned"
    fi
}

Cdsm_kill()             # "убить" процесс cdsm
{
    CDSM_PID_C=$(pidof canlogger)
    if [[ ${#CDSM_PID_C} -ne 0 ]] ; then
        CDSM_PID=$(pidof canlogger | awk '{print $1}')
        kill -s HUP ${CDSM_PID}
#        echo -e "${SCRIPT_PREF}: kill canlogger"
    else
        echo -n ""
#        echo -e "${SCRIPT_PREF}: canlogger not runned"
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
        GSM_SIGNAL="-113 dBm or less"
    elif [[ ${GSM_SIGNAL} -eq 1 ]] ; then
        GSM_SIGNAL="-111 dBm"
    elif [[ ${GSM_SIGNAL} -ge 2 && ${GSM_SIGNAL} -le 30 ]] ; then
        let "SIG=${GSM_SIGNAL}*2"
        SIG=$(expr ${SIG} - 113)
        GSM_SIGNAL=${SIG}" dBm"
    elif [[ ${GSM_SIGNAL} -ge 31 ]] ; then
        GSM_SIGNAL="-51 dBm or greater"
    fi
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

Print_def_settings()    # вывести настройки по умолчанию
{
    echo -e "\tDefault settings:"
    echo -en "\t\tLoop mode:       "
    if [[ ${MODE_ONCE} -eq 0 ]] ; then
        echo -e "true"
    else
        echo -e "false"
    fi
    echo -en "\t\tForce restart:   "
    if [[ ${ALWAYS_RESTART} -eq 1 ]] ; then
        echo -e "true"
    else
        echo -e "false"
    fi
    echo -e "\t\tPing ip:         ${PING_IP}"
    echo -e "\t\tLoop time:       ${SLEEP_TIME_WORK}"
    echo -e "\t\tRestart counter: ${GSM_RESTART_COUNTER}"
    echo -e "\t\tLog file:        ${LOG_FILE}"
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
    echo -e "Usage: \t./${SCRIPT_NAME} [-hvof] [-rc -lt -ip] [value]"
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
    echo -en "\t\t\t\t Reset connect on each loop"
    echo -e ""
    echo -e "\t-rc [value]"
    echo -en "\t\t\t\t Set the number of checks before restarting modem"
    echo -e ""
    echo -e "\t-ip [value]"
    echo -en "\t\t\t\t Set ping ip value"
    echo -e ""
    echo -e "\t-lt [value]s"
    echo -en "\t\t\t\t Set value of loop time"
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
        Set_always_restart
    elif [[ $1 == "-rc" ]] ; then
        Set_restart_counter $2
    elif [[ $1 == "-lt" ]] ; then
        Set_loop_time $2
    elif [[ $1 == "-ip" ]] ; then
        Set_ping_ip $2
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

trap 'Sig_quit' QUIT
trap 'Sig_term' TERM
trap 'Sig_int'  INT

Read_script_parameters $*
RESTART_COUNTER=${GSM_RESTART_COUNTER}

SLEEP_TIME=${SLEEP_TIME_WORK}
while [ $SLEEP_TIME -ne 0 ] ; do
	sleep 1s
	SLEEP_TIME=$(expr ${SLEEP_TIME} - 1)
done


# главный цикл
while [ ${FLAG_REPEATE} -eq 1 ] ; do  
    Check_connect                           # проверка статуса соединения

    if [[ ${PING_STAT} -ne 0 ]] ; then      # соединение разорвано
        if [[ ${ALWAYS_RESTART} -eq 1 ]] ; then
            # типа в прошлый раз все было хорошо и только что оборвалось соединение
            PING_STAT_OLD=0
        fi
                
        if [[ ${PING_STAT_OLD} -ne 0 ]] ; then  # проверяем прошлое состояние
            # соединение раньше отсутствовало
            RESTART_COUNTER=$(expr ${RESTART_COUNTER} - 1)
            echo -e "${SCRIPT_PREF}: restart counter = ${RESTART_COUNTER}"
            if [[ $RESTART_COUNTER -eq 0 ]] ; then  # пора перезапустить модем
            	RESTART_COUNTER=${GSM_RESTART_COUNTER}
            	Gsm_modem_restart
            	Pppd_kill
            	Cdsm_kill
            fi
        else # соединение только что разорвалось 
#             echo "${SCRIPT_PREF}: link just down, restart pppd, canlogger"
             Debug_log "${SCRIPT_PREF}: link just down"
             Pppd_kill
             Cdsm_kill
             RESTART_COUNTER=${GSM_RESTART_COUNTER}
        fi 
    else
        # есть соединение
        if [[ ${PING_STAT_OLD} -ne 0 ]] ; then 
            # если соединение раньше отсутствовало 
            Calc_gsm_signal
            Debug_log "${SCRIPT_PREF}: link just up, gsm signal = ${GSM_SIGNAL}"
#            echo "${SCRIPT_PREF} DEBUG: connect just up"
        fi
    fi
    
    PING_STAT_OLD=${PING_STAT}          # заменяем старое значение состояния новым
   
    if [[ ${MODE_ONCE} -eq 1 ]] ; then       # включен режим однократного запуска
        FLAG_REPEATE=0
    else
        # уходим спать перед повтором
        SLEEP_TIME=${SLEEP_TIME_WORK}
#        echo "${SCRIPT_PREF}: sleep ${SLEEP_TIME}s"
        while [ $SLEEP_TIME -ne 0 ] ; do
            sleep 1s
            SLEEP_TIME=$(expr ${SLEEP_TIME} - 1)
        done
    fi       
done
