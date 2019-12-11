#!/bin/bash

export PATH="$PATH:./"
. common.sh

# Input: logfilename rpm
# Assumes the rpm is installed and $LOG/$RPMFILE has been created
dpkg_verify() {
        PKGPATH=$LOG/$PKGFILE
        LOGFILE=$LOG/$1
        INPUT_PKG=$2
        echo "#==[ Verification ]=================================#" >> $LOGFILE
        if dpkg -s $INPUT_PKG &>/dev/null
        then
                for PKG in $(dpkg -l $INPUT_PKG |grep ii |awk '{print $2}')
                do
                        echo "# dpkg -V $PKG" >> $LOGFILE
                        wait_trace_on "dpkg -V $PKG"
                        dpkg -V $RPM >> $LOGFILE 2>&1
                        ERR=$?
                        wait_trace_off
                        if [ $ERR -gt 0 ]; then
                                echo "# Verification Status: Differences Found" >> $LOGFILE
                        else
                                echo "# Verification Status: Passed" >> $LOGFILE
                        fi
                        echo >> $LOGFILE
                done
                #cat $RPMPATH | grep "^$INPUT_RPM " >> $LOGFILE
                #echo >> $LOGFILE
                return 0
        else
                echo "# PKG Not Installed: $INPUT_PKG" >> $LOGFILE
                echo >> $LOGFILE
                return 1
        fi
}

boot_info() {
        printlog "Boot Files..."
        OF=boot.txt
        log_cmd $OF "uname -a"
        if dpkg -s grub &> /dev/null; then
                conf_files $OF /etc/grub.conf /boot/grub/menu.lst /boot/grub/device.map
        fi

        log_cmd $OF 'last -xF | egrep "reboot|shutdown|runlevel|system"'

        conf_files $OF /proc/cmdline /etc/sysconfig/kernel  /etc/rc.d/rc.local /etc/rc.d/boot.local

        log_cmd $OF 'ls -lR --time-style=long-iso /boot/'
        conf_files $OF /var/log/boot.log /var/log/kern.log
        log_cmd $OF 'dmesg'
        echolog Done
}

dmidecode_info() {
                printlog "dmidecode info..."
                OF=CPMLog.txt
                log_cmd $OF "dmidecode"
                echolog Done
}

cpu_info() {
                printlog "cpu info..."
                OF=CPMLog.txt
                LOGFILE=$LOG/$OF
                log_cmd $OF 'lscpu'
                echo "cpuinfo ===<" >> $LOGFILE
                echo "#==[ Command ]======================================#" >> $LOGFILE
                echo "cat /proc/cpuinfo" >> $LOGFILE
                if [ -f /proc/cpuinfo ];then
                        cat /proc/cpuinfo >> $LOGFILE
                else
                        echo "file /proc/cpuinfo not exist" >> $LOGFILE
                fi
                echo ">===" >> $LOGFILE
                log_cmd $OF 'numactl --hardware'
                log_cmd $OF 'numastat'
                echolog Done
}

lscpu_info() {
                printlog "lscpu info..."
                OF=CPMLog.txt
                log_cmd $OF "lspci -vvv"
                echolog Done
}


ssh_info() {
        printlog "SSH..."
        OF=ssh.txt
        if dpkg_verify $OF openssh-server
        then
                log_cmd $OF "service ssh status"

                conf_files $OF /etc/ssh/sshd_config /etc/ssh/ssh_config /etc/pam.d/sshd
                log_cmd $OF 'netstat -nlp | grep sshd'
                echolog Done
        else
                echolog Skipped
        fi
}

pam_info() {
        printlog "PAM..."
        OF=pam.txt
        dpkg_verify $OF pam
        conf_files $OF /etc/nsswitch.conf /etc/hosts
        conf_files $OF /etc/passwd
        log_cmd $OF 'getent passwd'
        conf_files $OF /etc/group
        log_write $OF "#==[ Files in /etc/security ]=======================#"
        test -d /etc/security && FILES="$(find -L /etc/security/ -type f -name \*conf)" || FILES=""
        conf_files $OF $FILES
        log_write $OF "#==[ Files in /etc/pam.d ]==========================#"
        test -d /etc/pam.d && FILES="$(find -L /etc/pam.d/ -type f)" || FILES=""
        conf_files $OF $FILES
        echolog Done
}


environment_info() {
	printlog "Environment..."
	OF=env.txt
	log_cmd $OF 'hostname'
        log_cmd $OF 'uname -a'
        log_cmd $OF 'date +"%Y-%m-%d %H:%M"'
        log_cmd $OF 'uptime'
	log_item $OF 'ntpdate_q' 'ntpdate -q'
	log_cmd $OF 'ulimit -a'

	conf_files $OF /etc/sysctl.conf /boot/sysctl.conf-* /lib/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/sysctl.d/*.conf /run/sysctl.d/*.conf
	
	log_cmd $OF 'sysctl -a'
	log_cmd $OF 'getconf -a'
	log_item $OF "ipcs_l" 'ipcs -l'
	log_item $OF "ipcs_a" 'ipcs -a'
	log_cmd $OF 'env'
	
	conf_files $OF /etc/profile /etc/profile.local /etc/profile.d/*
	conf_files $OF /etc/bash.bashrc /etc/csh\.* /root/.bash_history 
	log_item $OF "chk_default_parainfo" "sh plug-in/cvmchk.sh"
	sed -i -e 's/\r//g' $LOG/$OF
	uuid_flag $LOG/$OF
	ip_addr $LOG/$OF
	echolog Done
}

cron_info() {
	printlog "CRON..."
	OF=cron.txt
	if dpkg_verify $OF cron
	then
		log_item $OF "systemctl_crond_service" "service cron status"
		log_item $OF "crontab_info" "crontab -l"
		conf_files $OF /var/spool/cron/allow /var/spool/cron/deny
		log_write $OF "### Individual User Cron Jobs ###"
		test -d /var/spool/cron/tabs && FILES=$(find -L /var/spool/cron/tabs/ -type f) || FILES=""
		conf_files $OF $FILES
		CRONS="cron.d cron.hourly cron.daily cron.weekly cron.monthly"
		log_write $OF "### System Cron Job File List ###"
		count_tmp=0
		for CRONDIR in $CRONS
		do
			count_tmp=$[ $count_tmp+1 ]
			log_item $OF "find_crondir_files_$count_tmp" "find -L /etc/${CRONDIR}/ -type f"
		done
		log_write $OF "### System Cron Job File Content ###"
		conf_files $OF /etc/crontab
		for CRONDIR in $CRONS
		do
			FILES=$(find -L /etc/${CRONDIR}/ -type f)
			conf_files $OF $FILES
		done
		echolog Done
	else
		echolog Skipped
	fi
}

chkconfig_info() {
        printlog "System Daemons..."
        OF=chkconfig.txt
        log_cmd $OF 'chkconfig --list'
        LOGFILE=$LOG/$OF
        log_item $OF "ls_lR_etc_init_d" 'ls -lR --time-style=long-iso /etc/init.d/'
        log_item $OF "ls_lR_etc_xinetd_d" 'ls -lR --time-style=long-iso /etc/xinetd.d/'
        FILES=$(find /etc/xinetd.d/ -type f)
        conf_files $OF $FILES
        echolog Done
}

systemd_info() {
	printlog "SystemD..."
	OF=systemd.txt
	rpm_verify $OF systemd
	log_item $OF "systemctl_failed" 'systemctl --failed'
	log_cmd $OF 'busctl --no-pager --system list'
	log_cmd $OF 'systemd-analyze --no-pager blame'
	log_cmd $OF 'systemd-cgtop --batch --iterations=1'
	log_cmd $OF 'systemd-cgls --no-pager --all --full'
	FILES=''
	[[ -d /etc/systemd ]] && FILES=$(find -L /etc/systemd -maxdepth 1 -type f)
	log_cmd $OF 'systemctl --no-pager show'
	conf_files $OF $FILES
	log_item $OF "systemctl_units" 'systemctl --no-pager --all list-units'
	log_item $OF "systemctl_sockets" 'systemctl --no-pager --all list-sockets'
	log_item $OF "systemctl_files" 'systemctl --no-pager list-unit-files'
	for i in $(systemctl --no-pager --all list-units | egrep -v '^UNIT |^LOAD |^ACTIVE |^SUB |^To |^[[:digit:]]* ' | awk '{print $1}')
	do
		if [[ -z "$i" ]]
		then
			break
		else
			log_item $OF "systemctl_show" "systemctl show '$i'"
		fi
	done
	log_item $OF "ls_alR_etc_systemd" 'ls -alR /etc/systemd/'
	log_item $OF "ls_alR_usr_lib_systemd" 'ls -alR /usr/lib/systemd/'
	echolog Done
}
open_files() {
        printlog "Open Files..."
        OF=open-files.txt
	log_item $OF "list_barad_logs" "ls -l /usr/local/qcloud/monitor/barad/log"
        if dpkg_verify $OF lsof
        then    
                log_cmd $OF "lsof -b +M -n -l"
                echolog Done 
        else            
                echolog Skipped
        fi              
}
lvm_info() {
	printlog "LVM..."
	OF=lvm.txt
	if dpkg_verify $OF lvm2
	then
		VGBIN="vgs"
		LVBIN="lvs"
		log_cmd $OF "vgs"
		log_cmd $OF "lvs"
		conf_files $OF $FILES
		log_item $OF "dmsetup_ls_tree" 'dmsetup ls --tree'
		log_item $OF "dmsetup_table" 'dmsetup table'
		log_item $OF "dmsetup_info" 'dmsetup info'
		log_item $OF "ls_l_etc_lvm_backup" 'ls -l --time-style=long-iso /etc/lvm/backup/'
		conf_files $OF /etc/lvm/backup/*
		log_item $OF "ls_l_etc_lvm_archive" 'ls -l --time-style=long-iso /etc/lvm/archive/'
		conf_files $OF /etc/lvm/archive/*
		log_write $OF
		log_write $OF "###[ Detail Scans ]###########################################################################"
		log_write $OF
		log_cmd $OF 'pvdisplay -vv'
		log_cmd $OF 'vgdisplay -vv'
		log_cmd $OF 'lvdisplay -vv'
		log_cmd $OF 'pvs -vvvv'
		log_cmd $OF 'pvscan -vvv'
		log_cmd $OF "$VGBIN -vvvv"
		log_cmd $OF "$LVBIN -vvvv"
		echolog Done
	else
		echolog Skipped
	fi
}

runtime_check() {
	# This is a minimum required function, do not exclude
	printlog "runtime check..."
	OF=runtime_check.txt

	log_cmd $OF 'cat /etc/lsb-release'
	log_cmd $OF 'uptime'
	log_cmd $OF 'vmstat 1 4'
	log_cmd $OF 'free -k'
	log_item $OF "df_h" 'df -h'
	log_item $OF "df_i" 'df -i'


	for MODULE in $(cat /proc/modules | awk '{print $1}')
	do
		LIST_MODULE=0
		modinfo -l $MODULE &>/dev/null
		if [ $? -gt 0 ]; then
			log_write $OF "$(printf "%-25s %-25s %-25s" module=$MODULE ERROR "Module info unavailable")"
		else
			wait_trace_on "modinfo -l $MODULE"
			LIC=$(modinfo -l $MODULE | head -1)
			SUP=$(modinfo -F supported $MODULE | head -1)
			test -z "$LIC" && LIC=None
			test -z "$SUP" && SUP=no
			GPLTEST=$(echo $LIC | grep GPL)
			test -z "$GPLTEST" && ((LIST_MODULE++))
			test "$SUP" != "yes" && ((LIST_MODULE++))
			test $LIST_MODULE -gt 0 && log_write $OF "$(printf "%-25s %-25s %-25s" "module=$MODULE" "license=$LIC" "supported=$SUP")"
			LIST_MODULES_ANY=$((LIST_MODULES_ANY + LIST_MODULE))
			wait_trace_off
		fi
	done

	PSPTMP=$(mktemp $LOG/psout.XXXXXXXX)
	PSTMP=$(basename $PSPTMP)

	log_cmd $PSTMP 'ps axwwo user,pid,ppid,%cpu,%mem,vsz,rss,stat,time,cmd'

	log_write $OF "#==[ Checking Health of Processes ]=================#"
	log_write $OF "# egrep \" D| Z\" $PSPTMP"
	log_write $OF "$(grep -v ^# "$PSPTMP" | egrep " D| Z")"

	TOPTMP=$(mktemp $LOG/top.XXXXXXXX)
	log_write $OF "#==[ Summary ]======================================#"
	log_write $OF "# Top 10 CPU Processes"
	ps axwwo %cpu,pid,user,cmd | sort -k 1 -r -n | head -11 | sed -e '/^%/d' > $TOPTMP
	log_write $OF "%CPU   PID USER     CMD"
	log_write $OF "$(< $TOPTMP)"

	log_write $OF "#==[ Summary ]======================================#"
	log_write $OF "# Top 10 Memory Processes"
	ps axwwo %mem,pid,user,cmd | sort -k 1 -r -n | head -11 | sed -e '/^%/d' > $TOPTMP
	log_write $OF "%MEM   PID USER     CMD"
	log_write $OF "$(< $TOPTMP)"
	rm -f $TOPTMP

	

	MCE_LOG='/var/log/mcelog'
	FILES=$MCE_LOG
	if [[ -s $MCE_LOG ]]; then
		log_cmd $OF "ls -l --time-style=long-iso $MCE_LOG"
		test $ADD_OPTION_LOGS -gt 0 && log_files $OF 0 $FILES || log_files $OF $VAR_OPTION_LINE_COUNT $FILES
	fi

	cat $PSPTMP >> $LOG/$OF
	rm $PSPTMP

	echolog Done
}
memory_info() {
	printlog "Memory Details..."
	OF=memory.txt
	log_cmd $OF "vmstat 1 4"
	log_cmd $OF "free -k"
	conf_files $OF /proc/meminfo /proc/vmstat
	log_cmd $OF 'sysctl -a 2>/dev/null | grep ^vm'
	[ -d /sys/kernel/mm/transparent_hugepage/ ] && FILES=$(find /sys/kernel/mm/transparent_hugepage/ -type f) || FILES=''
	conf_files $OF /proc/buddyinfo /proc/slabinfo /proc/zoneinfo $FILES
	if dpkg -s numactl &>/dev/null; then
		log_cmd $OF 'numactl --hardware'
		log_cmd $OF 'numastat'
	fi
	if [ -x /usr/bin/pmap ]; then
		for I in $(ps axo pid)
		do
			log_cmd $OF "pmap $I"
		done
	fi
	echolog Done
}

net_info() {
	printlog "Networking..."
	OF=network.txt
	dpkg_verify $OF sysconfig
	log_cmd $OF "service networking status"
	log_cmd $OF 'ifconfig -a'
	log_item $OF "ip_addr" "ip addr"
	log_item $OF "ip_route" "ip route"
	log_item $OF "ip_s_link" "ip -s link"
	conf_files $OF /proc/sys/net/ipv4/ip_forward /etc/HOSTNAME /etc/services
	log_cmd $OF 'hostname'
	IPADDRS=$(ip addr | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
	for IPADDR in $IPADDRS
	do
		ping_addr $OF 'Local Interface' $IPADDR
	done

	IPADDR=$(route -n | awk '$1 == "0.0.0.0" {print $2}')
	ping_addr $OF 'Default Route' $IPADDR

	test -e /etc/resolv.conf && IPADDRS=$(grep ^nameserver /etc/resolv.conf | cut -d' ' -f2) || IPADDRS=""
	for IPADDR in $IPADDRS
	do
		ping_addr $OF 'DNS Server' $IPADDR
	done

	log_cmd $OF 'route'
	log_item $OF "route_n" 'route -n'
	log_item $OF "netstat_as" 'netstat -as'
	log_item $OF "netstat_nlp" 'netstat -nlp'
	log_item $OF "netstat_nr" 'netstat -nr'
	log_item $OF "netstat_i" 'netstat -i'
	log_cmd $OF 'arp -v'
	for NIC in /sys/class/net/*
	do
		if [[ -e ${NIC}/type ]]; then
			[[ "`cat ${NIC}/type`" = 772 ]] && continue
			NIC="${NIC##*/}"
			log_cmd $OF "ethtool $NIC"
			log_item $OF "ethtool_l" "ethtool -l $NIC"
			log_item $OF "ethtool_k" "ethtool -k $NIC"
			log_item $OF "ethtool_i" "ethtool -i $NIC"
			log_item $OF "ethtool_S" "ethtool -S $NIC"
			log_cmd $OF "mii-tool -v $NIC"
		fi
	done
	log_cmd $OF "nscd -g"
	conf_files $OF /etc/hosts /etc/host.conf /etc/resolv.conf /etc/nsswitch.conf /etc/nscd.conf /etc/hosts.allow /etc/hosts.deny
	for TABLE in filter nat mangle raw
	do
		if grep iptable_$TABLE /proc/modules &>/dev/null
		then
			log_cmd $OF "iptables -t $TABLE -nvL"
			log_cmd $OF "iptables-save -t $TABLE"
		else
			log_write $OF "# NOTE: The iptable_$TABLE module is not loaded, skipping check"
			log_write $OF
		fi
	done
	test -d /etc/sysconfig/network && FILES=$(find -L /etc/sysconfig/network/ -maxdepth 1 -type f) || FILES=""
	conf_files $OF /etc/sysconfig/proxy $FILES 
	sed -i -e 's/.*_PASSWORD[[:space:]]*=.*/*REMOVED BY SUPPORTCONFIG*/g' $LOG/$OF
	conf_files $OF $FILES
	if [ -d /proc/net/bonding ]; then
		FILES=$(find /proc/net/bonding/ -type f)
		conf_files $OF $FILES 
	fi
	FILES=$(grep logfile /etc/nscd.conf 2> /dev/null | grep -v ^# | awk '{print $2}' | tail -1)
	test -n "$FILES" || FILES="/var/log/nscd.log"
	log_files $OF 0 $FILES
	echolog Done
}

disk_info() {
	printlog "Disk I/O..."
	OF=fs-diskio.txt
	log_cmd $OF 'fdisk -l 2>/dev/null | grep Disk'
	conf_files $OF /proc/partitions /etc/fstab
	log_cmd $OF "mount"
	log_cmd $OF 'df -hT'
	conf_files $OF /proc/mounts /etc/mtab


	log_item $OF "ls_lR_dev_disk" 'ls -lR --time-style=long-iso /dev/disk/'
	log_item $OF "ls_l_sys_block" 'ls -l --time-style=long-iso /sys/block/'


	log_cmd $OF 'iostat -x 1 4'
	log_cmd $OF 'sg_map -i -x'
	if [ -d /sys/block ]; then
		SCSI_DISKS=$(find /sys/block/ -maxdepth 1 | grep sd\.)
	else
		SCSI_DISKS=""
	fi

	if [ -n "$SCSI_DISKS" ]; then
		log_write $OF "#==[ SCSI Detailed Info ]===========================#"
		log_write $OF "#---------------------------------------------------#"
		log_cmd $OF 'lsscsi'
		log_item $OF "lsscsi_H" 'lsscsi -H'
		[[ -x /bin/lsblk ]] && log_cmd $OF "lsblk -o 'NAME,KNAME,MAJ:MIN,FSTYPE,LABEL,RO,RM,MODEL,SIZE,OWNER,GROUP,MODE,ALIGNMENT,MIN-IO,OPT-IO,PHY-SEC,LOG-SEC,ROTA,SCHED,MOUNTPOINT'"
		if log_cmd $OF 'scsiinfo -l'
		then
			FILES=$(scsiinfo -l)
			for DEVICE in $FILES
			do
				log_cmd $OF "scsiinfo -i $DEVICE"
			done
		fi
		log_item $OF "lsscsi_v" 'lsscsi -v'
		test -d /proc/scsi && SCSI_DIRS=$(find /proc/scsi/ -type d) || SCSI_DIRS=""
		for SDIR in $SCSI_DIRS
		do
			test "$SDIR" = "/proc/scsi" -o "$SDIR" = "/proc/scsi/sg" -o "$SDIR" = "/proc/scsi/mptspi" && continue
			FILES=$(find ${SDIR}/ -maxdepth 1 -type f 2>/dev/null)
			conf_files $OF $FILES
		done
	fi

	echolog Done
}

crash_info() {
        printlog "Crash Info..."
        # Call fslist_info first to search for core files
        OF=crash.txt
        if  dpkg -s kexec-tools >/dev/null 2>&1 ;then


           KDUMP_CONFIG_FILE="/etc/default/kdump-tools"
           DUMPDIR=`grep ^KDUMP_COREDIR /etc/default/kdump-tools |head -n 1| cut -d '"' -f2`
           [[ -z $DUMPDIR ]] && DUMPDIR=/var/crash

           dpkg_verify $OF kexec-tools
           log_cmd $OF "uname -r"
           if [ -d "$DUMPDIR" ]; then
                log_cmd $OF "find -L ${DUMPDIR}/"
                #rsync -avq  --exclude='*vmcore' ${DUMPDIR}/   ${LOG}/
		curr_dir_jw=`pwd`
		cd ${DUMPDIR}/ 2>/dev/null
		cp `ls | grep -v *vmcore | xargs` "${LOG}/" >/dev/null 2>&1	
		cd "$curr_dir_jw" 2>/dev/null
           else
		echo ""
                echo ""log_entry $OF conf "KDUMP_SAVEDIR not found: "${DUMPDIR}""
           fi
           echolog Done
        else
                echolog Skipped
        fi
}


messages_file() {
        # This is a minimum required function, do not exclude
        printlog "System Logs..."
        OF=messages.txt
        MSG_COMPRESS="\.gz"
        FILES="$(ls -1 /var/log/auth.log 2>/dev/null) $(ls -1 /var/log/syslog 2>/dev/null)"
        for CMPLOG in $FILES
        do
                FILE=$CMPLOG
                file_size=$(du $FILE |awk '{print $1}')
                if [ $file_size -le 524288 ] ;then
                        cp $CMPLOG ${LOG}
                fi

        done

        #FILES="$(find /var/log/ -name "secure*" -mtime -30 2>/dev/null) $(find /var/log/ -name "syslog*"  -mtime 30 2>/dev/null)" "find /var/log/ -name "kern.log*"  -mtime 30 2>/dev/null"
        log_files $OF 0 /var/log/auth.log  /var/log/kern.log
        log_item $OF "tail_messages" "tail -n 50000  /var/log/syslog"
	log_files $OF 0 /var/log/cloud-init.log
        log_item $OF "tail_barad_excutelog" "tail -n 500 /usr/local/qcloud/monitor/barad/log/executor.log"
	for CMPLOG in $FILES
        do
                FILE=$CMPLOG
                file_size=$(du $FILE |awk '{print $1}')
                if [ $file_size -le 524288 ] ;then
                        cp $CMPLOG ${LOG}
                fi

        done
        echolog Done
}


##main


os_ver=$(cat /etc/os-release | grep PRETTY_NAME | awk -F '=' '{ print $2}')

mkdir -p $LOG

boot_info
ssh_info
pam_info
environment_info
open_files
lvm_info
cron_info
net_info
disk_info
runtime_check
memory_info
crash_info
messages_file
cron_info
proc_info
etc_info
sysconfig_info
rpm_info



echo "========================================================"
echo "creating tar ball ....."
TARBALL=$(hostname)_$(date +%F-%H%M).tgz

cd $LOG
cd ..
wait_trace_on -t "tar zvcf ${TARBALL} ${LOG}/*"
tar zvcf ${TARBALL}  ${LOG}/* >/dev/null 2>&1
LOGSIZE=$(ls -lh ${TARBALL} | awk '{print $5}')
wait_trace_off -t
wait_trace_on -t "md5sum $TARBALL"
md5sum $TARBALL | awk '{print $1}' > ${TARBALL}.md5
LOGMD5=$(cat ${TARBALL}.md5)
wait_trace_off -t

[ -f $TARBALL ] && echo "the log is saved at $(pwd)/$TARBALL,please send it to support engineer."


rm -rf $LOG

