#!/bin/bash
#filename:user_log.sh
#sshd_config需要设置LogLevel DEBUG,SyslogFaciliity AUTHPRIV
#脚本放在/etc/profile.d/目录下即可, 适用CentOS 7+
#由于CentOS7的ssh日志记录方式不同, 还需要收集对应登录用户的私钥md5指纹
common() {
echo
}
admin() {
if [ ! -d /var/log/login/histlog ];then
         mkdir -p /var/log/login/histlog
         chmod 777 /var/log/login/histlog
fi
chattr +a -R /var/log/login/histlog/
file=/tmp/ssh.log
journalctl -r -u sshd.service --no-pager | head -n1000 > ${file}
sshkey=$HOME/.ssh/authorized_keys
login_ip=echo $SSH_CLIENT|awk '{print $1}'
login_ip_port=echo $SSH_CLIENT|awk '{print $2}'
test -z $login_ip -o -z $login_ip_port && return 3
get_line=$(grep -C2 $login_ip $file | grep -C2 $login_ip_port | grep 'matching key found' \
| grep -oE 'line [0-9]+' | awk '{print $NF}' | sort | uniq)
if [ ! -z $get_line ];then
     login_user=$(sed -n "$get_line p" $sshkey | awk '{print $NF}')
     test -z $login_user && login_user=$(whoami)
else
     login_user=$(whoami)
fi
shopt -s histappend
history -a
echo  HISTFILE="/var/log/login/histlog/$login_user"
export HISTSIZE=1000
export HISTFILESIZE=1000
export HISTFILE="/var/log/login/histlog/$login_user"
export PROMPT_COMMAND='history -a;history -w'
unset login_ip
unset login_ip_port
unset login_user
unset get_line
unset file
unset sshkey
}
[ whoami != root ] && common || admin
export HISTTIMEFORMAT='%F %T '
