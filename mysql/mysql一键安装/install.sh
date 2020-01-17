#!/bin/bash
#Date: 2019-06-21
#Author: Zheng
#Description: service for mysql install shell script by CentOS 7.x x86
#脚本执行路径，后面文件引入会以当前作为相对路径
temp_path=$(dirname $0)
cd $temp_path
real_path=$(pwd)
cd $real_path
alias cp='cp'
#初始化路径
defaults_dir=/usr/local/src
mysql_install_path=/usr/local/mysql
mysql_db=/data/mysqlDB/master
mysql_port=3306
mysql_sock=$mysql_db/$mysql_port/mysql-${mysql_port}.sock
mysql_storage=$mysql_db/$mysql_port/data
mysql_password='123456'
mysql_conf_temp=/tmp/my.cnf
mysql_logs=$mysql_db/$mysql_port/logs
mysql_binlogs=$mysql_db/$mysql_port/binlogs
mysql_conf=$mysql_db/$mysql_port/conf
mysql_version=mysql-5.7.25-linux-glibc2.12-x86_64.tar.gz

main() {
cp $real_path/src/* $defaults_dir
cp $real_path/config/.dbp /data
useradd -r -s /sbin/nologin mysql
mkdir -pv $mysql_db
cd $defaults_dir
tar zxf $mysql_version -C /usr/local
mv /usr/local/`echo "${mysql_version}" | sed 's@.tar.gz@@g'` /usr/local/mysql
mkdir -pv $mysql_storage $mysql_binlogs $mysql_conf $mysql_logs
chown -R mysql. $mysql_db/*
yum install -y libaio
#配置mysql，参数有涉及到binlog以及innodb,本脚本将把mysql安装为主
cat > $mysql_conf_temp << EOF
#MySQL5.7.18#
[client]
default-character-set = utf8mb4
port = ${mysql_port}
socket = ${mysql_sock}
[mysql]
prompt = "\u@master [\d]>"
no-auto-rehash
[mysqld]
#GENERAL#
basedir = ${mysql_install_path}
pid-file = $mysql_db/$mysql_port/mysql-${mysql_port}.pid
socket = ${mysql_sock}
user = mysql
port = ${mysql_port}
server-id = 1
character-set-server = utf8mb4
init-connect = 'SET NAMES utf8mb4'
default_storage_engine = InnoDB
max_allowed_packet = 4M
max_connect_errors = 10000
#DATA STORAGE#
datadir = ${mysql_storage}
#BINARY LOGGING#
binlog_format = mixed
log_bin = ../binlogs/mysql-bin
max_binlog_size = 1024M
expire_logs_days = 7
sync-binlog = 1
#LOGGING#
log-error = ${mysql_logs}/mysql-${mysql_port}.err
slow_query_log = 1
long_query_time = 3
slow_query_log_file = ${mysql_logs}/slow.log
general_log = 1
general_log_file = ${mysql_logs}/general_log.log
EOF
cp $mysql_conf_temp $mysql_conf/master.cnf
rm -f $mysql_conf_temp
sed -i 's@executing mysqld_safe@executing mysqld_safe\nexportLD_PRELOAD=/usr/local/lib/libjemalloc.so@' $mysql_install_path/bin/mysqld_safe
mysql_real_conf=$mysql_conf/master.cnf
cd /usr/local/mysql
chown -R mysql. .
bin/mysqld --defaults-file=$mysql_real_conf --datadir=$mysql_storage --initialize-insecure --user=mysql
chown -R root .
chown -R mysql $mysql_storage
chown mysql: $mysql_db/$mysql_port
$mysql_install_path/bin/mysqld_safe --defaults-file=$mysql_real_conf --user=mysql &
sleep 10
netstat -tunlp | grep $mysql_port
{ echo > /dev/tcp/127.0.0.1/$mysql_port; } 2>/dev/null
if [ $? -eq 0 ];then
$mysql_install_path/bin/mysql --defaults-file=$mysql_real_conf -e "grant all privileges on *.* to root@'127.0.0.1' identified by \"${mysql_password}\" with grant option;"
$mysql_install_path/bin/mysql --defaults-file=$mysql_real_conf -e "grant all privileges on *.* to root@'localhost' identified by \"${mysql_password}\" with grant option;"
$mysql_install_path/bin/mysql --defaults-file=$mysql_real_conf -uroot -p${mysql_password} -e "reset master;"
echo "$mysql_install_path/lib" > /etc/ld.so.conf.d/mysql.conf
ldconfig
$mysql_install_path/bin/mysqladmin --defaults-file=$mysql_real_conf -uroot -p${mysql_password} shutdown
sleep 2
cp $real_path/init.d/*-mysql.sh $mysql_db/$mysql_port/ 
cp -p $real_path/init.d/mysqld.master /etc/init.d/mysqld && chmod +x /etc/init.d/mysqld 
cp -p $real_path/init.d/mysqld.service /lib/systemd/system/mysqld.service 
systemctl daemon-reload 
sleep 1 
sed -i "s@123456@$mysql_password@g" $mysql_db/$mysql_port/*.sh
sed -i "s@my.cnf@master.cnf@g" $mysql_db/$mysql_port/*.sh 
sed -i /-P/"s@port@$mysql_port@g" $mysql_db/$mysql_port/*.sh
sed -i "s@port@$mysql_port@g" /etc/init.d/mysqld
systemctl enable mysqld
systemctl start mysqld
fi
}
main
