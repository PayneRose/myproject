#!/bin/bash
LOG=/tmp/log_collect
LOGPROC="$LOG/""proc.txt"


CURRENT_SCRIPT=$(basename $0)
CSFILE=${CURRENT_SCRIPT}.txt

VAR_OPTION_WAIT_TRACE=0
ADD_OPTION_LOGS=1

wait_trace_on() {
        if (( $VAR_OPTION_WAIT_TRACE )); then
                OPT=$1
                case $OPT in
                -t) TEE=0; shift ;;
                *) TEE=1 ;;
                esac
                LOGGING="$@"
                WT_START=$(date +%T:%N)
                if (( $TEE )); then
                	printf "%s" "    <$WT_START> $LOGGING  " | tee -a ${LOG}/${CSFILE}
                else
                	printf "%s" "    <$WT_START> $LOGGING  "
                fi
        fi
}

wait_trace_off() {
        if (( $VAR_OPTION_WAIT_TRACE )); then
        OPT=$1
                case $OPT in
                -t) TEE=0 ;;
                *) TEE=1 ;;
                esac
                WT_END=$(date +%T:%N)
                if (( $TEE )); then
                        echo "<$WT_END>" | tee -a ${LOG}/${CSFILE}
                else
                        echo "<$WT_END>"
                fi
        fi
}

os_version() {
        if [ -f /etc/tlinux-release ];then
			os_version_number=$(cat /etc/tlinux-release |awk '{print $4}')
			system="tlinux $os_version_number"
	elif [ -f /etc/centos-release  ] ;then
		if [ "6" = $(cat /etc/centos-release |awk '{print $3}' | awk -F'.' '{print $1}') ] ;then
                        if [ -f /etc/tlinux-release ];then
			        os_version_number=$(cat /etc/tlinux-release |awk '{print $3}')
			        system="centos $os_version_number"
                        else
                                os_version_number=$(cat /etc/centos-release |awk '{print $3}')
			        system="centos $os_version_number"
                        fi
		elif [ "release" = $(cat /etc/centos-release |awk '{print $3}' | awk -F'.' '{print $1}') ] ;then
			os_version_number=$(cat /etc/centos-release |awk '{print $4}')
			system="centos $os_version_number"
		fi
	elif [ -f /etc/lsb-release ] ;then 
		os_version_number=$(cat /etc/lsb-release | sed -n '2p' | awk -F'=' '{print $2}')
		system="ubuntu $os_version_number"
	elif [ -f /etc/SuSE-release ] ;then
		os_version_number=$(cat /etc/SuSE-release | sed -n '2p' | awk -F'=' '{print $2}')
		system="suse $os_version_number"
	elif [ "freebsd" = "uname -n | awk -F'_' '{print $NF}'" ] ;then
		os_version_number="uname -r"
		system="BSDfree $os_version_number"
	elif [[ -f /etc/os-release && `cat /etc/os-release | grep -iw debian` ]];then
		os_version_number="uname -r"
		system="debian $os_version_number"
	elif [[ -f /etc/os-release && `cat /etc/os-release | grep -i suse` ]];then
		os_version_number="uname -r"
		system="opensuse $os_version_number"
	else
		echo "undefined system"
	fi
	
	echo "osversion ===<" 	>> $1
	echo "$system" 			>> $1
	echo ">===" 			>> $1
	echo ""					>> $1
}

# Input: logfilename command
log_cmd() {
        EXIT_STATUS=0
        LOGFILE=$LOG/$1
        shift
        CMDLINE_ORIG="$@"
        CMDBIN=$(echo $CMDLINE_ORIG | awk '{print $1}')
        CMD=$(\which $CMDBIN 2>/dev/null | awk '{print $1}')
        if [ "$CMDLINE_ORIG" = "env" ]; then
			os_version $LOGFILE
        fi
        echo ""$CMDBIN"info ===<" >> $LOGFILE
        echo "#==[ Command ]======================================#" >> $LOGFILE
        if [ -x "$CMD" ]; then
                CMDLINE=$(echo $CMDLINE_ORIG  | sed -e "s!${CMDBIN}!${CMD}!")
                echo "# $CMDLINE" >> $LOGFILE
                wait_trace_on "$CMDLINE"
                echo "$CMDLINE" | bash  >> $LOGFILE 2>&1
                EXIT_STATUS=$?
                wait_trace_off
        else
                if type $CMDBIN  2>/dev/null |grep builtin >/dev/null 2>&1 ;then
                        CMDLINE=$(echo $CMDLINE_ORIG )
                        echo "# $CMDLINE" >> $LOGFILE
                        wait_trace_on "$CMDLINE"
                        echo "$CMDLINE" | bash  >> $LOGFILE 2>&1
                        EXIT_STATUS=$?
                        wait_trace_off
                else

                        echo "# $CMDLINE_ORIG" >> $LOGFILE
                        echo "ERROR: Command not found or not executible" >> $LOGFILE
                        EXIT_STATUS=1
                fi
        fi
        echo ">===" >> $LOGFILE
        echo >> $LOGFILE
        return $EXIT_STATUS
}


# Input: logfilename itemname  command
log_item() {
        EXIT_STATUS=0
        LOGFILE=$LOG/$1
        shift
        CMDLINE_ORIG="$2"
        CMDBIN=$(echo $CMDLINE_ORIG | awk '{print $1}')
        CMD=$(\which $CMDBIN 2>/dev/null | awk '{print $1}')
        echo ""$1"info ===<" >> $LOGFILE
        echo "#==[ Command ]======================================#" >> $LOGFILE
        if [ -x "$CMD" ]; then
                CMDLINE=$(echo $CMDLINE_ORIG  | sed -e "s!${CMDBIN}!${CMD}!")
                echo "# $CMDLINE" >> $LOGFILE
                wait_trace_on "$CMDLINE"
                echo "$CMDLINE" | bash  >> $LOGFILE 2>&1
                EXIT_STATUS=$?
                wait_trace_off
        else
                if type $CMDBIN  2>/dev/null |grep builtin >/dev/null 2>&1 ;then
                        CMDLINE=$(echo $CMDLINE_ORIG )
                        echo "# $CMDLINE" >> $LOGFILE
                        wait_trace_on "$CMDLINE"
                        echo "$CMDLINE" | bash  >> $LOGFILE 2>&1
                        EXIT_STATUS=$?
                        wait_trace_off
                else

                        echo "# $CMDLINE_ORIG" >> $LOGFILE
                        echo "ERROR: Command not found or not executible" >> $LOGFILE
                        EXIT_STATUS=1
                fi
        fi
        echo ">===" >> $LOGFILE
        echo >> $LOGFILE
        return $EXIT_STATUS
}


# Input: logfilename "text"
log_write() {
        LOGFILE=$LOG/$1
        shift
        echo "$@" >> $LOGFILE
}

printlog() {
        CSLOGFILE=$LOG/${CSFILE}
        printf "  %-45s" "$@" | tee -a $CSLOGFILE
}

echolog() {
        CSLOGFILE=$LOG/${CSFILE}
        echo "$@" | tee -a $CSLOGFILE
}

timed_progress() {
        CSLOGFILE=$LOG/${CSFILE}
        printf "." | tee -a $CSLOGFILE
}

conf_files() {
        LOGFILE=$LOG/$1
        shift
        for CONF in $@
        do
		a=`echo "$CONF" | awk -F'/' '{print $(NF-1)}'`
		a=${a//./_}
		b=`echo "$CONF" | awk -F'/' '{print $NF}'`
		c=${b//./_}
		if [ "X""$a" = "X" ];then
			echo "cat_"$c"""info ===<" >> $LOGFILE
		else
			echo "cat_"$a"_"$c"""info ===<" >> $LOGFILE
		fi
                echo "#==[ Configuration File ]===========================#" >> $LOGFILE
                if [ -f $CONF ]; then
                        echo "# $CONF" >> $LOGFILE
			#cat $CONF 2>> $LOG/$CSFILE | sed -e 's/\r//g' >> $LOGFILE 2>> $LOG/$CSFILE
			sed -e '/^[[:space:]]*#/d;/^[[:space:]]*;/d;s/\r//g;/^[[:space:]]*$/d' $CONF >> $LOGFILE 2>> $LOG/$CSFILE
                        wait_trace_on "$CONF"
                        echo >> $LOGFILE
                        wait_trace_off
                else
                        echo "# $CONF - File not found" >> $LOGFILE
                fi
		echo ">==="  >> $LOGFILE
                echo >> $LOGFILE
        done
}

log_files() {
        LOGFILE=$LOG/$1
        shift
        LOGLINES=$1
        shift
        for CONF in $@
        do
                BAD_FILE=$(echo "$CONF" | egrep "\.tbz$|\.bz2$|\.gz$|\.zip$|\.xz$")
                if [ -n "$BAD_FILE" ]; then
                        continue
                fi
                CONF=$(echo $CONF | sed -e "s/%7B%20%7D%7B%20%7D/ /g")
		a=`echo "$CONF" | awk -F'/' '{print $(NF-1)}'`
		a=${a//./_}
		b=`echo "$CONF" | awk -F'/' '{print $NF}'`
		c=${b//./_}
		if [ "X""$a" = "X" ];then
			echo "cat_"$c"""info ===<" >> $LOGFILE
		else
			echo "cat_"$a"_"$c"""info ===<" >> $LOGFILE
		fi
		echo "#==[ Log File ]=====================================#" >> $LOGFILE
                if [ -f "$CONF" ]; then
                        wait_trace_on "$CONF"
                        if [ $LOGLINES -eq 0 ]; then
                                echo "# $CONF" >> $LOGFILE
                                sed -e 's/\r//g' "$CONF" >> $LOGFILE
                        else
                                echo "# $CONF - Last $LOGLINES Lines" >> $LOGFILE
                                tail -$LOGLINES "$CONF" | sed -e 's/\r//g' >> $LOGFILE
                        fi
                        echo >> $LOGFILE
                        wait_trace_off
                else
                        echo "# $CONF - File not found" >> $LOGFILE
                fi
				echo ">==="  >> $LOGFILE
                echo >> $LOGFILE
        done
}

ping_addr() {
        OF=$1
        ADDR_STRING="$2"
        ADDR_PING=$3
        if [ -n "$ADDR_PING" ]; then
                if log_cmd $OF "ping -n -c1 -W1 $ADDR_PING"; then
                        log_write $OF "# Connectivity Test, $ADDR_STRING $ADDR_PING: Success"
                else
                        log_write $OF "# Connectivity Test, $ADDR_STRING $ADDR_PING: Failure"
                fi
        else
                log_write $OF "# Connectivity Test, $ADDR_STRING: Missing"
        fi
        log_write $OF
}

file_log() {
	if [ ! -f "$1" ];then
		return 1
	fi
	if [[ "$1" = "/proc/acpi/event" || "$1" = "/proc/sys/fs/binfmt_misc/register" || "$1" = "/proc/sys/net/ipv4/route/flush" || "$1" = "/proc/sys/vm/compact_memory" || "$1" = "/proc/sysrq-trigger" ]];then
		return 1
	fi
	echo "$1"" ===<" >> $LOGPROC
	timeout 1 cat $1 >> $LOGPROC 2>/dev/null
	echo ">===" >> $LOGPROC
	echo " "  >> $LOGPROC
}

dir_log() {
	if [ ! -d "$1" ];then
		return 1
	fi
	num=`echo $1 | awk -F'/' '{print NF}'`
	if [ $num -gt 9 ];then
		return 1
	fi
	
	cd $1
	for i in `ls -l 2>/dev/null | awk -F' ' '{print $1"#"$9}'`
	do
		a=`echo $i | awk -F'#' '{print $1}'`
		b=`echo $i | awk -F'#' '{print $2}'`
		#if [[ "$b" == "PCIe" ]];then
		#	continue
		#fi
		if [[ "${a:0:1}" = "-" ]];then
			file_log "$1""/""$b"
		elif [[ "${a:0:1}" = "d" ]];then
			dir_log "$1""/""$b"
		fi 
	done
}
proc_info() {
        printlog "PROC..."
        OF=proc.txt
        FILES=$(find /proc/ -maxdepth 1 -type f 2>/dev/null | egrep -iv "kcore$|kpagecount$|kpagecgroup|kpageflags$|vmcore$|config.gz$|kmsg$|sysrq-trigger$|kallsyms$|mm$|ssstm" | sort -f)
        conf_files $OF $FILES
        #conf_files $OF /proc/mounts /proc/zoneinfo
        ADDPROCS="/proc/sys/kernel/ /proc/scsi/ /proc/net/ /proc/dasd/"
        for PROCDIR in $ADDPROCS
        do
                FILES=$(find $PROCDIR -maxdepth 1 -type f 2>/dev/null | egrep -iv "rt_acct$" | sort -f)
                conf_files $OF $FILES
        done
        FULLPROCS="/proc/irq/ /proc/sys/"
        for PROCDIR in $FULLPROCS
        do
                FILES=$(find $PROCDIR -type f 2>/dev/null | sort -f)
                conf_files $OF $FILES
        done
        echolog Done
}
etc_info() {
	printlog "ETC..."
	OF=etc.txt
	conf_files $OF /etc/hostname 
	conf_files $OF $(find /etc/ -type f | grep conf$)
	[ -d /etc/logrotate.d ] && conf_files $OF /etc/logrotate.d/*
	[ -d /etc/network ] && conf_files $OF /etc/network/*
	conf_files $OF /etc/rc.dialout /etc/ppp/options /etc/ppp/ioptions /etc/ppp/peers/pppoe
	echolog Done
}
sysconfig_info() {
	printlog "SYSCONFIG..."
	OF=sysconfig.txt
	if [ -d /etc/sysconfig ];then
		for FILE in $(find /etc/sysconfig/ -maxdepth 1 -type f | sort -f)
		do
			conf_files $OF $FILE
		done
		for FDIR in $(find /etc/sysconfig/ -maxdepth 1 -type d | grep -v "/etc/sysconfig/$" | sort)
		do
			for FILE in $(find ${FDIR}/ -type f | sort)
			do
				conf_files $OF $FILE
			done
		done
		sed -i -e 's/.*_PASSWORD[[:space:]]*=.*/*REMOVED BY SUPPORTCONFIG*/g' $LOG/$OF
	else
		log_write $OF "no /etc/sysconfig dir, other info maybe in etc.txt"
	fi
	echolog Done
}
rpm_info() {
	# This is a minimum required function, do not exclude
	printlog "RPM or APT Database..."
	OF=rpm.txt
	if [ -e /usr/bin/dpkg ];then
		log_write $OF "#==[ Command ]======================================#"
		log_write $OF '# dpkg -l'
		dpkg -l >>  $LOG/$OF 2>&1
	else
		# rpm list of all files
		log_write $OF "#==[ Command ]======================================#"
		log_write $OF '# rpm -qa --queryformat "%-35{NAME} %-35{DISTRIBUTION} %{VERSION}-%{RELEASE}\n" | sort -k 1,2 -t " " -i'
		printf "%-35s %-35s %s\n" NAME DISTRIBUTION VERSION >> $LOG/$OF
		rpm -qa --queryformat "%-35{NAME} %-35{DISTRIBUTION} %{VERSION}-%{RELEASE}\n" | sort -k 1,2 -t " " -i >> $LOG/$OF 2>&1
		log_cmd $OF "rpm -qa --last"
	fi
	echolog Done
}
uuid_flag() {
        if [ -f /etc/uuid ];then
                uuid=`cat /etc/uuid | awk -F'=' '{print $2}' | awk '{print $1}'`
                echo "uuid_flag ===<"   >> $1
                echo "$uuid"            >> $1
                echo ">==="             >> $1
                echo ""                 >> $1
        fi
}

ip_addr() {
    flag=1
    ipaddr=`ip route | grep src | awk -F' ' '{print $NF}'`
	for i in $ipaddr
	do
		a=`echo $i | awk -F'.' '{print $1}'`
		if [ "$a" == "10" ];then
			echo "ipaddress_flag ===<" 		>> $1
			echo "$i"                    	>> $1
			echo ">==="                		>> $1
			flag=0
			break
		fi
	done
    if [ "$flag" = "1" ];then
		for i in $ipaddr
		do
			a=`echo $i | awk -F'.' '{print $1}'`
			if [[ $a != "10"&&$a != "127" ]];then
				echo "ipaddress_flag ===<" 		>> $1
				echo "$i"                    		>> $1
				echo ">==="                		>> $1
				break
			fi
		done
	fi
	echo ""								>>$1
}

ip_addr_opensuse() {
	a=`ifconfig eth0 | grep inet | awk -F' ' '{print$2}' | awk -F':' '{print$2}'`
        echo "ipaddress_flag ===<"              >> $1
        echo "$a"                       	>> $1
        echo ">==="                             >> $1
}
