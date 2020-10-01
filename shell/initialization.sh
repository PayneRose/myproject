#! /bin/bash
#coding=utf-8
#writer:pangfaheng
#start date : I don't remember
#Subsequent modification times : 
#first:/2017/04/03   
#second:/2017/09/10  
#third:/2017/10/23 : 加入一些循环语句，配置防火墙、优化系统、增加巡检策略、配置基础服务
#foutth:/2018/01/11: 将阿里云镜像改为清华大学镜像
#The role of this script: you can modify some of the basic system configuration 
#你可以修改一些基本的系统配置

#自定义选项，对应下面的每一个选项
option='f=firewalld | t=Modification time | i=Modify IP | n=Modify hostname | y=Configure Yum source | v=set number | s=selinux | init=init(1..5)'



read -p "Can I help you?" yn
#下面三行是该脚本的执行选项的开始，对应最后面两行结束
	if [ "$yn" =  "y" -o "$yn" =  "Y" ];then
		read -p  "Please input one letter : $option  : "    X
			case	$X	in
#以下选项从a开始，z结束		
				f)  #关闭防火墙
firewalld6(){
sed -i 's/^SELINUX=.*/SELINUX=disabled/'  /etc/sysconfig/selinux 
setenforce 0
iptables -F
/etc/init.d/iptables save
chkconfig iptables off

}
firewalld7(){
	systemctl stop firewalld
	systemctl disable firewalld
	setenforce	0
	getenforce
	sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
}

					el=`uname -a |awk -F "." '{print $6}'|tr -cd "[0-9]"`
					if [ $el -eq 7 ]; then
					firewalld7
					elif [ $el -eq 6 ]; then
					firewalld6
					else
						echo "sorry"
					fi
				;;
				i)
                                        read -p "Have you changed your IP? 'y/n' " IP
                                                case    $IP     in  
                                                        y)
							read -p "Please input your IP address configuration file (ifcfg-......) : "	ifcfg
															scr=/etc/sysconfig/network-scripts/    

echo "TYPE-----------------------网络类型,默认:Ethernet
BOOTPROTO------------------启动协议,默认:dhcp,建议:none
NM_CONTROLLED--------------yes or no 设备是否可以由Network Manager图形管理工具托管,连接外网必须启用
ONBOOT---------------------yes or no 系统启动时是否激活网卡，默认可是没开的哦
DEVICE---------------------指定网卡设备名称
NAME-----------------------指定网卡设备名称
IPADDR---------------------0.0.0.0
NETMASK--------------------255.255.255.0
GATEWAY--------------------0.0.0.0
DNS1-----------------------0.0.0.0
DNS2-----------------------0.0.0.0
or Ethernet none yes yes eth0 eth0 192.168.1.10 255.255.255.0 192.168.1.1 8.8.8.8 223.5.5.5 "
							read -p  "Please enter the parameters, you can refer to the following data: "  parameter
parameter=($parameter)
echo "TYPE=${parameter[0]}" 		>  $scr$ifcfg
echo "BOOTPROTO=${parameter[1]}"	>> $scr$ifcfg
echo "NM_CONTROLLED=${parameter[2]}" 	>> $scr$ifcfg
echo "ONBOOT=${parameter[3]}"		>> $scr$ifcfg
echo "DEVICE=${parameter[4]}"		>> $scr$ifcfg
echo "NAME=${parameter[5]}"		>> $scr$ifcfg
echo "IPADDR=${parameter[6]}"		>> $scr$ifcfg
echo "NETMASK=${parameter[7]}"		>> $scr$ifcfg
echo "GATEWAY=${parameter[8]}"		>> $scr$ifcfg
echo "DNS1=${parameter[9]}"		>> $scr$ifcfg
echo "DNS2=${parameter[10]}" 		>> $scr$ifcfg

								;;
							n)
								echo "Thank you"
								exit
								;;
#目前只能为一台服务器配置ip，而且所有的选项必须手写上去，不够智能化，日后需要为多台服务器配置ip的时候就很麻烦。需要将一些填空题改为选择题
						esac	
					;;
				init)  #！
					read -p "What is your system version? " version
						case	$version	in
							6)
							read -p "Do you want to modify the running system level as (1..5)? " init6
								echo "Please wait for subsequent updates" #等待后续更新，不过估计不会有了~~~~~
							;;
							7)   #设置启动级别，暂时保留
							read -p "Do you want to modify the running system level as \"3 or 5\"? " init7
								case	$init7	in
									3)
								systemctl set-default multi-user.target
									;;
									5)
								systemctl set-default graphical.target
									;;
								esac	
						esac
							read -p "Do you want to reboot now? y/n" reboot
								case	$reboot	in
									y)
										reboot
									;;

									n)
										exit
									;;	
								esac
					;;
				n)
	 				read -p "Have you switched to root users? y/n " h
						case	$h	in 
							y)
								read -p "Please input your new name " n
	  							echo   $n  >   /etc/hostname
								cat /etc/hostname		
								;;
							n)
								echo "	Please su root"
								;;
						esac
					;;
				t)
					date
					cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
					echo "OK"
					date
					;;
				v)
					read -p "Have you set number? y/n "  v
						case	$v	in
							y)
								echo "set nu" >> ~/.vimrc
							;;
							n)
								echo "Thank you"
								exit
							;;
						esac
					;;
#
#				s)	
#					read -p "Have you close you selinux? y/n " s
#						case	$s	in
#							y)
#								systemctl   stop  firewalld
#						systemctl   disable  firewalld
#						setenforce   0   
#						sed -i 's/^SELINUX=.*/SELINUX=disabled/'  /etc/selinux/config 
#						getenforce 
#							;;
#							n)
#								echo "good bye"
#							;;
#						esac
#					;;
				y)
					read -p "Do you need to configure yum? y/n " yumyes
#yum install vsftpd --enablerepo=os
						case	$yumyes	in
							y)
						read -p "what type is you want to configure?  os/local/epel/mysql/zabbix: "  type	
							if  [ "$type" =   "local" ]; then 
									mkdir /source
									mount -o loop /dev/cdrom /source
									echo ' /dev/cdrom   source    iso9660   ro,loop  0 0 '    >>    /etc/fstab
mount -a
yum clean all
echo "[iso]
name=cdrom
baseurl=file:///source
enabled=1
gpgcheck=0
"	> /etc/yum.repos.d/iso.repo
								
							elif	[ "$type" = "os" ]; then
echo "[os]
name=os
baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos/7/os/\$basearch
gpgcheck=0
enabled=0
"	> /etc/yum.repos.d/os.repo
								
							elif	[ "$type" = "epel" ]; then
echo "[epel]
name=epel
baseurl=https://mirrors.tuna.tsinghua.edu.cn/epel/7/\$basearch
failovermethod=priority
enabled=0
gpgcheck=0
"	> /etc/yum.repos.d/epel.repo
							elif	[ "$type" = "mysql" ]; then
echo "[mysql]
name=mysql
baseurl=https://mirrors.tuna.tsinghua.edu.cn/mysql/yum/mysql57-community-el7/
gpgcheck=0
enabled=0
"	> /etc/yum.repos.d/mysql.repo
							elif	[ "$type" = "zabbix" ]; then
echo "[zabbix]
name=zabbix
baseurl=https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/3.5/rhel/7/\$basearch
gpgcheck=0
enabled=0
"	> /etc/yum.repos.d/zabbix.repo
							fi
yum clean all
yum makecache --enablerepo=$type
						;;

							n)
								echo "Thank you"
								exit
							;;
						esac
 
					;;
#对应最上面的参数，是该脚本的结尾
			esac
	fi
