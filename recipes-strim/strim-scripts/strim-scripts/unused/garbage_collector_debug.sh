#!/bin/sh

FILES=""
MAX_USED_SPACE_PERSENT=90

get_file_list()
{
	FILES_2=`find /home/root/canlogger/ -mtime +2 -name z_z*`
	FILES_1=`find /home/root/canlogger/ -mtime +1 -name z_z*`
	echo "length +2 day = ${#FILES_2}"
	echo "length +1 day = ${#FILES_1}"
    if [[ ${#FILES_2} != 0 ]] ; then
    echo "32"
    	FILES=`find /home/root/canlogger/ -mtime +2 -name z_z*`
        echo "2 days ago files:"
        echo ${#FILES}
    elif [[ '`find /home/root/canlogger/ -mtime +1 -name z_z*`' ]] ; then
    echo "33"
        FILES=`find /home/root/canlogger/ -mtime +1 -name z_z*`
        echo "1 days ago files:"
    fi
        echo "$FILES"
    echo "34"
}


write_list()
{
	echo "$FILES" > /media/ramdisk/delfiles
}


#remove_files()
#{
#	RESULT=`cat /media/ramdisk/delfiles | xargs rm -f`
#}


check_space()
{
	echo "0"
    USED_PERSENT=`df -h /home/ | grep dev | awk '{print $5}' | sed '{s/.$//;}'`
    echo "1"
	if [[ ${USED_PERSENT} -ge ${MAX_USED_SPACE_PERSENT} ]] ; then
	echo "2"
	   get_file_list
	   echo "35"
	   echo "Used spase (${USED_PERSENT}%) greatest than maximum (${MAX_USED_SPACE_PERSENT}%). Delete files:"
	   echo "36"
	   echo "$FILES"
	   echo "37"
	   write_list  
	   echo "38"
#	   remove_files
	fi
}


check_space

# работаем
#FLAG=1
#while [[ ${FLAG} == 1 ]]
#    do
#    check_space	
#    sleep 600s	
#done