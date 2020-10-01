#! /usr/bin/bash

# openssl enc -e -des3 -a -salt -in passwd -out passwd
# true > passwd


password_users='passwdusers'
password_admin='passwdadmin'


read -p "请选择类型: 1:输入密码；2: 管理员账户" usertype
read -p "请输入用户名: " username

if [[ ${usertype} == 2 ]];then
    if [[ -e ${password_admin} ]];then openssl enc -e -des3 -a -salt -in ${password_admin};fi
    if [[ -e ${username} ]];then ln -s ${username} ${password_admin};else echo "没有该用户，请新建用户";fi
fi
    
pass_file=`find /root/shell/${username} -mtime -7 2>/dev/null`

if [[ ${pass_file} == '' ]];then
    pass_file_old=`find /root/shell/${username} -mtime +7 2>/dev/null`
    if  [[ ${pass_file_old} == '' ]];then 
        echo "新增用户"
        openssl enc -e -des3 -a -salt -in ${password_users} -out ${username}
        exit;
    else
        echo "超过七天，请修改密码" &&
        echo "请输入旧密码" &&
        openssl enc -d -des3 -a -salt -in ${pass_file_old} && 
        echo "请输入新密码，并重复确认一次" &&
        openssl enc -e -des3 -a -salt -in passwd -out ${username} &&
        exit;
    fi
fi

end=`openssl enc -d -des3 -a -salt -in ${pass_file} 2>/dev/null`

if [[ $end == 'pass' ]];then
    echo "通过"
elif [[ $end == 'error' ]];then
    echo "不通过"
fi




