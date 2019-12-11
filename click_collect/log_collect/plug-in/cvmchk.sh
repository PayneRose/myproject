#!/bin/bash
#
# This script checks CVM guest configurations, sees if it is properly
# initialized, rules out some known issues.
#
#
# version 1.1
#[ADD]
#1\checking the numa memory balancing
#[BUG&FIX]
#

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
dir=$(cd `dirname $0`;pwd)

#======================================================================
#				     	 Basic Work
#----------------------------------------------------------------------
#check memory sysctl conf
#check_memory_sysctl()
#{
#	#check free_min_bytes
#	mem_free=`cat /proc/meminfo | awk 'NR==2{print}' | awk '{print$2}'`
#	min_free_kbytes=`cat /proc/sys/vm/min_free_kbytes`
#	echo mem_free:$mem_free
#	echo min_free_kbytes:$min_free_kbytes
#	if [ $((mem_free)) -lt $((min_free_kbytes)) ];then
#	       	echo "[X]starting direct reclaim... mem_free:"$mem_free" min_free_kbytes:"$min_free_kbytes
#	fi
#}

check_os_type()
{
  # ostype: tlinux|opensuse|suse|centos|redhat|ubuntu|debian
  while [ true ];do
    if [ -f /etc/tlinux-release ];then
      echo tlinux
    return
    fi
    if [ -f /etc/SuSE-release ];then
		grep -i "opensuse" /etc/SuSE-release >/dev/null 2>/dev/null && echo "opensuse" || echo "suse"
      return
    fi
    if [ -f /etc/centos-release ];then
      echo centos
    return
    fi
    #centos5 and redhat5
    if [ -f /etc/redhat-release ];then
      grep "Red Hat" /etc/redhat-release >/dev/null
      if [ $? -eq 0 ];then
        echo redhat
        return
      fi
      grep CentOS /etc/redhat-release >/dev/null
      if [ $? -eq 0 ];then
        echo centos
        return
      fi
    fi
    break
  done
  for os in ubuntu debian coreos;do grep ^ID=${os}$ /etc/os-release >/dev/null 2>/dev/null && echo ${os} && return; done
  grep -i =ubuntu /etc/lsb-release >/dev/null 2>/dev/null && echo ubuntu && return
  [ -f /etc/freebsd-update.conf ] && echo FreeBSD
}

# get centos or redhat os version such as 5,6,7
get_redhat_centos_ver()
{
	if [ -f /etc/centos-release ]; then
		echo `sed 's/^.*release \([0-9]\).*$/\1/' /etc/centos-release`
	elif [ -f /etc/redhat-release ]; then
		echo `sed 's/^.*release \([0-9]\).*$/\1/' /etc/redhat-release`
	fi
}

# get redhat and centos os whole version info,such as 6.8,7.3
get_redhat_centos_whole_version()
{
    if [ -f /etc/centos-release ];then
        ver=`grep -o "[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}" /etc/centos-release`
    else
        ver=`grep -o "[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}" /etc/redhat-release`
    fi
    echo "$ver"
    return
}


function get_rc_local_file()
{
    if [ ${ostype} = 'ubuntu' -o ${ostype} = 'debian' -o ${ostype} = 'FreeBSD' ]; then
        file=/etc/rc.local
    else
        file=/etc/rc.d/rc.local
    fi
    echo "$file"
}


get_debian_version() 
{ 
        grep -i "VERSION_ID" "/etc/os-release" >/dev/null 2>/dev/null 
        if [  "$?" == "0"  ];then 
                version=`sed -n 's/VERSION_ID=\"\([0-9]\)\"/\1/p' /etc/os-release` 
                echo $version 
                return 
        elif [  -f /etc/debian_version  ];then 
                version=`sed -n 's/\([0-9]\)\.[0-9].*/\1/p' /etc/debian_version` 
                echo $version 
                return 
        fi  
}



fix_centos6_ttyS0()
{
    [ "$ostype" != "centos" -a "$ostype" != "redhat" -a "$ostype" != "tlinux" ] && return
    local osver=`get_redhat_centos_ver`
    if [ "$osver" == "6" ]; then
        [ -f /etc/init/ttyS0.conf ] || printf "[X]/etc/init/ttyS0.conf not exist, configuring ttyS0 is recommended\n" 
        ps -ef | grep ttyS0 | grep -v grep >/dev/null || printf "[X]ttyS0 not running, configuring ttyS0 is recommended\n"
    fi
}

#------------------------------------------
acpid_check()
{
    # check acpid (used for soft shutdown and reboot)
    ps -fe | grep -w "acpid" | grep -v "grep" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        printf "[X]acpid is not running, it is required for soft shutdown.\n"
    fi
}

get_centos_version_number()
{
	if [ -f /etc/centos-release ]; then
    		version=`sed 's/^.*release \([0-9]\).*$/\1/' /etc/centos-release`
    	elif [ -f /etc/redhat-release ]; then
        	version=`sed 's/^.*release \([0-9]\).*$/\1/' /etc/redhat-release`
    	else
        	version='other'
    	fi  
	echo $version
}

generate_udev_rules()
{
    dest_file=/etc/udev/rules.d/45-virtio-disk-qcloud.rules
    [ -f $dest_file ] || printf "[X]$dest_file not exist\n"
}

generate_acpipahp_file()
{
	dest_file=/etc/sysconfig/modules/acpiphp.modules
	module_name=/lib/modules/$(uname -r)/kernel/drivers/pci/hotplug/acpiphp.ko
	cat >$dest_file <<EOF
#!/bin/bash
modprobe acpiphp >& /dev/null
EOF
	chmod a+x $dest_file
}

set_acpiphp_boot_load()
{
    # 0: loaded, 1: not loaded
    acpiphp_loaded=0
	case ${ostype} in
		"debian")
			local ver=`get_debian_version`
			if [  "$ver" == "6" ];then
				grep -w acpiphp /etc/modules >/dev/null 2>&1
                acpiphp_loaded=$?
			fi
			;;
		"ubuntu")
			local name=`grep ^DISTRIB_CODENAME= /etc/lsb-release |sed 's/.*=//'`
			if [ "${name}" = lucid ];then
				grep -w acpiphp /etc/modules >/dev/null 2>&1
                acpiphp_loaded=$?
			fi
			;;
		"centos")
			if [ -f /etc/centos-release ]; then
				version=`sed 's/^.*release \([0-9]\).*$/\1/' /etc/centos-release`
			elif [ -f /etc/redhat-release ]; then
				version=`sed 's/^.*release \([0-9]\).*$/\1/' /etc/redhat-release`
			else
				return
			fi
			if [  "$version" == "5"  ];then
                [ -f /etc/sysconfig/modules/acpiphp.modules ]
                acpiphp_loaded=$?
			fi
			;;
		"redhat")
			local red_version=`sed -n "s/.*release.*\([0-9]\).[0-9].*/\1/p" /etc/redhat-release`
			if [  "$red_version" == "5"  ];then
                [ -f /etc/sysconfig/modules/acpiphp.modules ]
                acpiphp_loaded=$?
			fi
			;;
		"opensuse")
			open_version=`grep -w VERSION_ID /etc/os-release | sed -n "s/VERSION_ID=\"\(.*\)\"/\1/p"`
			if [  "$open_version" == "12.3"  ];then
                prv=`grep -w MODULES_LOADED_ON_BOOT /etc/sysconfig/kernel | \
                sed -n "s/MODULES_LOADED_ON_BOOT=\"\(.*\)\"/\1/p"`
                echo $prv | grep -w acpiphp >/dev/null 2>&1
                acpiphp_loaded=$?
            fi
			;;
	esac

    if [ $acpiphp_loaded -ne 0 ]; then
        printf "[X]kernel module acpiphp is not loaded\n"
    fi
}

get_rps()
{
    if ! command -v ethtool &> /dev/null; then
        source /etc/profile
    fi

    ethtool=`which ethtool 2>/dev/null`
    if [ $? -ne 0 ]; then
        printf "[X]No ethtool found, please install it\n"
        return
    fi

    cpu_nums=`cat /proc/cpuinfo |grep processor |wc -l`
    [ $cpu_nums -le 1 ] && return

    ethSet=`ls -d /sys/class/net/eth*`
    for entry in $ethSet
    do
        is_rfs_set=0
        eth=`basename $entry`

        printf "\n---------rps setting for $eth---------------\n"

        # check if eth has multi-queue
        max_combined=`$ethtool -l $eth 2>/dev/null | grep -i "combined" | head -n 1 | awk '{print $2}'`
        #in case ethtool -l $eth goes wrong:
        [[ ! "$max_combined" =~ ^[0-9]+$ ]] && max_combined=1
        cur_combined=`$ethtool -l $eth 2>/dev/null | grep -i "combined" | tail -n 1 | awk '{print $2}'`
        #in case ethtool -l $eth goes wrong:
        [[ ! "$cur_combined" =~ ^[0-9]+$ ]] && cur_combined=1

        [ $max_combined -ne $cur_combined ] && printf \
            "[X]$eth current multi-queue setting doesn't match H/W pre-set\n"

        nic_queues=`ls -l /sys/class/net/$eth/queues/ |grep rx- |wc -l`
        if (($nic_queues==0)) ;then
            printf "[X]$eth has no rps queue, probably kernel doesn't support it\n"
            if [ $max_combined -le 1 && $cpu_nums -gt 1 ]; then
                printf "   recommend to upgrade kernel to support rps\n"
            else
                printf "   fortunately $eth doesn't need rps\n"
            fi
            continue
        fi

        for (( i=0; i<$nic_queues; i++ ))
        do
            rps_cpus=`cat /sys/class/net/$eth/queues/rx-$i/rps_cpus`
            rpscpus=`echo $rps_cpus |sed 's/,//g' |sed 's/0//g'`
            if [[ ! -z $rpscpus ]]; then
                is_rfs_set=1
                printf "rx-%-3d: rps_cpus=%s rps_flow_cnt=%d\n" $i $rps_cpus \
                    `cat /sys/class/net/$eth/queues/rx-$i/rps_flow_cnt`
            fi
        done

        echo "---------------------------------------------------"
        if [ $is_rfs_set -eq 0 ]; then
            if [ $max_combined -le 1 ]; then
                printf "[X]$eth doesn't set rps.\n   Should set because it's single queue and there are $cpu_nums CPUs\n"
            else
                printf "[I]$eth doesn't set rps. But not necessary because it has rss\n"
            fi
        else
            [ $max_combined -gt 1 ] && printf \
                "[I]$eth supports rss and also set rps(not a problem, just FYI)\n"
        fi
    done

    if [ $is_rfs_set -eq 1 ]; then
        printf "flow_entries=`cat /proc/sys/net/core/rps_sock_flow_entries`\n"
    fi
}

set_rps()
{
	servicePath="/usr/local/qcloud/rps"
	case ${ostype} in
		"debian")
		local version=`get_debian_version`
		if [  "$version" == "6" ];then
			#echo "  ->Debian 6 don't support rps......"
			return
		fi
		;;
		"ubuntu")
		local name=`grep ^DISTRIB_CODENAME= /etc/lsb-release |sed 's/.*=//'`
		if [ "${name}" = lucid ]; then #10
			#echo "  ->Ubuntu 10 don't support rps......"
			return
		fi
		;;
		"centos")
		local version=`get_redhat_centos_ver`
		if [  "$version" == "5" ];then
			#echo "  ->Centos 5 don't support rps......"
			return
		fi
		;;
		"redhat")
		local version=`get_redhat_centos_ver`
		if [  "$version" == "5" ];then
			#echo "  ->Redhat 5 don't support rps......"
			return
		fi
		;;
		"coreos")
		servicePath="/opt/qcloud/rps"
		;;
	esac
	#for sles we can't change its software(we don't have the online repos),and rps can run ok except some ethtool judge

	if [ ${ostype} = 'ubuntu' -o ${ostype} = 'debian' -o ${ostype} = 'FreeBSD' ]; then
		file=/etc/rc.local
	else
		file=/etc/rc.d/rc.local
	fi

    [ -f $servicePath/set_rps.sh ] || printf "[X]$servicePath/set_rps.sh not exist\n"

    grep set_rps\.sh $file |grep -v ^\# > /dev/null 2>&1
    [ $? -eq 0 ] || printf "[X]set_rps.sh not in $file\n"

#$servicePath/set_rps.sh >/tmp/setRps.log 2>&1
}

get_net_affinity()
{
    is_kvm_vm
    if [ $? -ne 0 ];then
        irqSet=`awk -F ":" '/eth/{print $1}' /proc/interrupts`
    else
        irqSet=`grep "LiquidIO.*rxtx" /proc/interrupts \
                | awk -F ':' '{print $1}'`
        [[ -z $irqSet ]] && irqSet=`grep -i ".*virtio.*put.*" /proc/interrupts \
                | awk -F ':' '{print $1}'`
    fi

    [[ -z $irqSet ]] && return

    printf "\n---------Current irq affinity---------------\n"
    printf "%4s %-18s| %s\n" "irq" "name" "Affinity CPU list"
    echo "--------------------------------------------"
    for irq in $irqSet
    do
        irqName=`basename \`ls -d /proc/irq/$irq/*/\``
        printf "%4d %-18s: %s\n" $irq $irqName "`cat /proc/irq/$irq/smp_affinity_list`"
    done
    echo "--------------------------------------------"
}

###shutdown irqbalance and bind virtio-input irq to last cpu
set_net_irq_bind()
{
	if [ ${ostype} = 'ubuntu' -o ${ostype} = 'debian' -o ${ostype} = 'FreeBSD' ]; then
		file=/etc/rc.local
	else
		file=/etc/rc.d/rc.local
	fi
	[ "$ostype" == "coreos" ] && service_dir="/opt/qcloud/irq" || service_dir="/usr/local/qcloud/irq"

    [ -f $service_dir/net_smp_affinity.sh ] || printf "[X]$service_dir/net_smp_affinity.sh not exist\n"

    grep net_smp_affinity\.sh $file |grep -v ^\# >/dev/null 2>&1
    [ $? -eq 0 ] || printf "[X]net_smp_affinity.sh not in $file\n"
}

disable_irqbalance()
{
	ps -ef | grep irqbalance | grep -v grep >/dev/null 2>&1
    [ $? -eq 0 ] && printf "[X]irqbalance is running, we recommend to disable it\n"
}

set_virtio_net_bind()
{
	disable_irqbalance
	set_net_irq_bind
}


disable_ipv6()
{
    [ -d /proc/sys/net/ipv6 ] || return
    if [[ `cat /proc/sys/net/ipv6/conf/all/disable_ipv6` -eq 0 || \
         `cat /proc/sys/net/ipv6/conf/default/disable_ipv6` -eq 0 ]]; then 
        printf "[X]ipv6 is not disabled, pls ensure if it is enabled on purpose\n"
    fi
}

# recover centos7(7.0,7.1,7.3) watchdog_thresh to default value
function centos7_wathdog_thresh_fix()
{
    [ "$ostype" == "centos" ] || return # effect only on centos 
    local osver=`get_redhat_centos_ver`
    [ "$osver" == "7" ] || return #only effect on centos7

    local tmpfs_key="/proc/sys/kernel/watchdog_thresh"
    local value=10 #default value

    if [ `cat $tmpfs_key` -gt $value ]; then
        printf "[X]kernel.watchdog_thresh higher than default 10\n   This may have issues on some kernel versions, see:\n   https://access.redhat.com/solutions/1354963\n"
    fi
}

# config centos7.3 overcommit_memory to 1
centos73_config_overcommit_memory()
{
    [ "$ostype" == "centos" ] || return # effect only on centos 
    ver=`grep -o "[[:digit:]]\{1,\}\.[[:digit:]]\{1,\}" /etc/centos-release`
    [ "$ver" == "7.3" ] || return # only effect on centos7.3

    [ `cat /proc/sys/vm/overcommit_memory` -ne 1 ] && printf \
    "[X]kernel parameter vm.overcommit_memory is recommended to be 1 for CentOS7.3\n"
}

disable_numa_balancing()
{
    [ `cat /proc/sys/kernel/numa_balancing` -eq 0 ] || printf \
    "[X]/proc/sys/kernel/numa_balancing is enabled, we recommend to disable\n"
}

# os specific config
os_specific_config()
{
    case $ostype in
        "centos")
            osver=`get_redhat_centos_ver`
            os_whole_ver=`get_redhat_centos_whole_version`
            case $osver in
                "7")
                    disable_numa_balancing
                    ;;
            esac
            ;;
    esac
}

set_centos_shmmax()
{
	if [ "$ostype" != "centos" ]; then
		return
	fi
	[ -f /etc/sysctl.conf.first ] && file="/etc/sysctl.conf.first" || file="/etc/sysctl.conf"
	[ $arch -eq 64 ] && value=68719476736 || value=1073741824
	current_value=`cat /proc/sys/kernel/shmmax`
	[ $current_value -lt $value ] && printf \
    "[X]kernel parameter shmmax=$current_value, recommend $value for CentOS\n"
}

centos6_close_mtu_detect()
{
	if [ "$ostype" != "centos" ]; then
		return
	fi
	local ver=`get_redhat_centos_ver`
	if [ "$ver" == "6" ]; then
		[ `cat /proc/sys/net/ipv4/ip_no_pmtu_disc` -eq 1 ] || printf "[X]/proc/sys/net/ipv4/ip_no_pmtu_disc is 0, recommend 1 for CentOS6\n"
	fi	
}

disable_mtu_detect_in_jr()
{
    if [ "$idc" == "szjr" -o "$idc" == "shjr" -o "$idc" == "szjrvpc" -o "$idc" == "shjrvpc" ];then
        centos6_close_mtu_detect
    fi
}


#======================================================================
#   set Persistence-M for nvidia gpu driver(eg. nvidia-smi -pm 1)
#----------------------------------------------------------------------
is_nv_gpu_host()
{
    gpu_info=$(lspci | grep NVIDIA)
    if [ ${#gpu_info} -gt 0 ];then
        return 1
    fi  

    return 0
    # return 1: gpu host. return 0: not gpu host.
}



set_nv_gpu_pm()
{
    is_nv_gpu_host
    [ $? -eq 0 ] && return # not gpu host

    if [ ${ostype} = 'ubuntu' -o ${ostype} = 'debian' -o ${ostype} = 'FreeBSD' ]; then 
        file=/etc/rc.local
    else 
        file=/etc/rc.d/rc.local
    fi   
    [ "$ostype" == "coreos" ] && service_dir="/opt/qcloud/gpu" || service_dir="/usr/local/qcloud/gpu"
    [ -f $service_dir/nv_gpu_conf.sh ] || printf \
    "[X]$service_dir/nv_gpu_conf.sh not exist\n"
    #$service_dir/nv_gpu_conf.sh >/tmp/nv_gpu_conf.log 2>&1 
    grep 'nv_gpu_conf\.sh' $file |grep -v ^\# >/dev/null 2>&1
    [ $? -eq 0 ] || printf "[X]nv_gpu_conf.sh not in $file\n"
}

#======================================================================

#======================================================================
#    set udev trigger to config rps & irq bind for nic hotplugin
#----------------------------------------------------------------------

set_nic_hotplugin_support()
{
    [ "$ostype" == "coreos" ] && base_dir=/opt/qcloud || base_dir=/usr/local/qcloud
    local service_dir=$base_dir/udev_run
    local udev_run_file=$service_dir/udev_run.sh

    if [ ! -f $udev_run_file ]; then
        printf "[X]$udev_run_file not exist, seems NIC hotplug not configured\n"
        return
    fi

    if [ ! -f /etc/udev/rules.d/80-qcloud-nic.rules ]; then
        printf "[X]/etc/udev/rules.d/80-qcloud-nic.rules not exist, seems NIC hotplug not configured\n"
        return
    fi

    grep "net_smp_affinity\.sh" $udev_run_file |grep -v ^\# >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        printf "[X]net_smp_affinity.sh not in $udev_run_file\n"
    else
        [ -f $base_dir/irq/net_smp_affinity.sh ] || printf "[X]$base_dir/irq/net_smp_affinity.sh not exist\n"
    fi

    grep "set_rps\.sh" $udev_run_file |grep -v ^\# >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        printf "[X]set_rps.sh not in $udev_run_file\n"
    else
        [ -f $base_dir/rps/set_rps.sh ] || printf "[X]$base_dir/rps/set_rps.shnot exist\n"
    fi
}


#======================================================================
#   Set NVMe support
#----------------------------------------------------------------------

set_nvme_irq_bind()
{
    [ "`ls /dev|grep nvme`" == "" ] && return
    [ "$ostype" != "suse" -a "$ostype" != "centos" -a "$ostype" != "opensuse" ] \
        && return
    
    if [ ${ostype} = 'ubuntu' -o ${ostype} = 'debian' -o ${ostype} = 'FreeBSD' ]; then
        rclocal=/etc/rc.local
    else
        rclocal=/etc/rc.d/rc.local
    fi
    
    [ "$ostype" == "coreos" ] && service_dir="/opt/qcloud/irq" || service_dir="/usr/local/qcloud/irq"

    [ -f $service_dir/nvme_smp_affinity.sh ] || printf "[X]$service_dir/nvme_smp_affinity.sh not exist\n"
    grep 'nvme_smp_affinity\.sh' $rclocal |grep -v ^\# >/dev/null 2>&1
    [ $? -eq 0 ] || printf "[X]nvme_smp_affinity.sh not in $rclocal\n"
}

#===============================================================================
#  Prohibit AMD machine centos6 system upgrade kernel to kernel-2.6.32-696.30.1 version 
#-------------------------------------------------------------------------------
exclude_kernel()
{
    #Vendor ID, AMD: AuthenticAMD; Intel: GenuineIntel
    vendorid=$(lscpu | grep -i "Vendor ID" | awk -F " " '{print $3}')
    
    if [[ "$vendorid" =~ "AMD" ]]; then

        if [ "$ostype" != "centos" ]; then 
            return
        fi

        local osver=`get_redhat_centos_ver`
        if [ "$osver" == "6" ]; then 
            if [[ "`uname -r`" =~ "2.6.32-696.30.1" ]]; then
                printf "[X]kernel-2.6.32-696.30.1 is unsupported for AMD\n"
            fi
        fi
    fi
}

#======================================================================
check_swap()
{
    if [ `cat /proc/swaps |wc -l` -gt 1 ]; then
        printf "[X]swap is configured, note that under certain circumstances swapping may\n   result in vCPU latency:\n   http://tapd.oa.com/VirsualSuite_document/markdown_wikis/#1010139721005779845\n   Tecent Cloud does not provide swap by default:\n   https://cloud.tencent.com/document/product/362/3597\n"
    fi
}
#======================================================================

numa_usage()
{
	PATH_TO_NODE="/sys/devices/system/node"
	nodes_num=`ls -d $PATH_TO_NODE/node* 2>/dev/null | wc -w`
	[ $nodes_num -le 1 ] && return

	min_memfree=`grep MemFree $PATH_TO_NODE/node0/meminfo |awk '{print $(NF-1)}'`
	memtotal=`grep MemTotal $PATH_TO_NODE/node0/meminfo |awk '{print $(NF-1)}'` 
	max_memfree=$min_memfree
	((min_freepct=memtotal/min_memfree))
	for ((i=1; i<nodes_num; i++)); do
		memfree=`grep MemFree $PATH_TO_NODE/node$i/meminfo |awk '{print $(NF-1)}'`
		((memfree > max_memfree)) && max_memfree=$memfree
		((memfree < min_memfree)) && min_memfree=$memfree
		memtotal=`grep MemTotal $PATH_TO_NODE/node$i/meminfo |awk '{print $(NF-1)}'` 
		((freepct=memtotal/memfree))
		((freepct > min_freepct)) && min_freepct=$freepct
	done

	# any node free<=5%, and gap between different nodes >5x
	if (( min_freepct>20 && max_memfree>(min_memfree*5) )); then
		printf "[X]NUMA nodes memory usage is unbalanced, one of the nodes has <5% free\n   run \"numactl -H\" to get details\n"
	fi
}
#======================================================================

# baremetal specail config
basic_install_public_cloud_init_bm()
{
    [ -f /etc/img_version ] || fix_centos6_ttyS0
    acpid_check
    set_acpiphp_boot_load
    set_rps
    set_virtio_net_bind
    generate_udev_rules
    disable_ipv6
    os_specific_config
    disable_mtu_detect_in_jr
    exclude_kernel
    check_swap
}

# return 0: yes, I'm a kvm vm
# return 1: no, I'm not
is_kvm_vm()
{
    local ret1
    local ret2

    lscpu 2>/dev/null | grep -i kvm >/dev/null 2>&1
    ret1=$?

    cat /sys/devices/system/clocksource/clocksource0/available_clocksource 2>/dev/null  | grep -i kvm >/dev/null 2>&1
    ret2=$?

    if [ "$ret1" == "0" -o "$ret2" == "0" ];then
        return 0
    else
        return 1
    fi
}
#======================================================================

#======================================================================
#   MAIN logic of basic_install_agent
#======================================================================

basic_install_public_cloud_init()
{
    acpid_check
    set_acpiphp_boot_load
    set_rps
    set_virtio_net_bind
    set_nvme_irq_bind
    set_nic_hotplugin_support #have to call after set_rps & set_virtio_net_bind
    generate_udev_rules
    disable_ipv6
    centos7_wathdog_thresh_fix # recover centos7(7.0,7.1,7.3) watchdog_thresh to default value
    centos73_config_overcommit_memory # config vm.overcommit_memory=1 (only for centos 7.3)
    os_specific_config
    set_centos_shmmax
    disable_mtu_detect_in_jr
    set_nv_gpu_pm
    exclude_kernel
}

basic_install_custom_cloud_init()
{
    acpid_check
    set_acpiphp_boot_load
    set_rps
    set_virtio_net_bind
    set_nvme_irq_bind
    set_nic_hotplugin_support
    generate_udev_rules
    disable_mtu_detect_in_jr
    set_nv_gpu_pm
    exclude_kernel
}



basic_install_main()
{
    is_kvm_vm
    if [ $? -ne 0 ];then
        #printf "This seems to be a baremetal box...\n"
        basic_install_public_cloud_init_bm
        return 0
    fi

    #printf "This seems to be a KVM guest "
    if [ "${mirror_type}" == public ];then
            basic_install_public_cloud_init
    else #custom and market
            basic_install_custom_cloud_init
    fi
    check_swap
    numa_usage
    get_net_affinity
    get_rps
    check_memory_sysctl
}

#======================================================================

# running from here
echo "-- checking CVM configurations --"

#Load Params: idc && mirror_type
if [ -f /etc/qcloudzone ];then
	idc=`head /etc/qcloudzone`
else
	idc=' '
fi
idc=`head /etc/qcloudzone 2>/dev/null`
[ -z $idc ] && idc="unknown"

if [ -f /etc/img_version ];then
    mirror_type=public
else
    mirror_type=unknown
fi


ostype=`check_os_type`
arch=`getconf LONG_BIT`

printf "\t~~~~~~~~~~~~~~~~~~~~~~\n"
is_kvm_vm
if [ $? -ne 0 ];then
    printf "\tbaremetal box\n"
else
    printf "\tKVM guest\n"
fi
printf "\tOS: $ostype\n"
printf "\tIDC: $idc\n"
[ -f /etc/img_version ] && printf "\tPublic image: `head /etc/img_version`\n"
printf "\t"
[ -f /var/lib/cloud/instance/vendor-cloud-config.txt ] || printf "Not "
printf "Initialized by cloud-init\n"
printf "\t~~~~~~~~~~~~~~~~~~~~~~\n"

basic_install_main

echo "-- Done --"
#======================================================================
