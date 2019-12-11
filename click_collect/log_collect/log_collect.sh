#!/bin/bash

export PATH="$PATH:./"
. common.sh

mkdir -p $LOG  

if [ `whoami` != "root" ];then
        echo " only root can run me"
	exit 1
fi
space=$(df -hm / | tail -n 1  |awk '{print $(NF-2) }')

[ $space -gt 100 ] || ( echo "no enough space at /" && exit 1 )

echo -e "\033[41;33m This script is used as a tencentcloud daily troubleshooting and does not involve collecting relevant privacy data \033[0m"

##physical host
if which dmidecode > /dev/null 2>&1 ;then

        if ! dmidecode |grep "Product Name" |grep Bochs > /dev/null ;then
			read -r -p "This project will collect hardware information, do you agree ? [Y/n]" input
			case $input in
			[yY][eE][sS]|[yY])
				echo -e "\033[32m Your choice is yes, log collection continues \033[0m"
				./hardware.sh
			;;
			[nN][oO]|[nN])
				echo -e "\033[31m Your choice not is yes, harewall log collection skip \033[0m"
				;;
			*)
				echo -e "\033[31m Your choice not is yes, harewall log collection skip \033[0m"
			;;
			esac	
        fi
fi
if  [ -f /etc/tlinux-release ];then
        ./tlinux.sh
elif [ -f /etc/centos-release ] ;then
	./centos.sh
elif [ -f /etc/lsb-release ] ;then 
	./ubuntu.sh
elif [[ -f /etc/os-release && `cat /etc/os-release | grep -iw debian` ]];then
	./debian.sh
elif [[ -f /etc/os-release && `cat /etc/os-release | grep -i suse` ]];then
        ./opensuse.sh
elif [ -f /etc/SuSE-release ] ;then
	./suse.sh
fi

echo "$0 succeed."
