#!/bin/bash
#Script Name:lnmp-cs7.sh
# Create: 2019-05-16 12:05:41
# Modify: 2019-08-05 16:40:24
# Author: Zheng
# Email: zhengxk1997@sina.com
# Description: lnmp shell script by CentOS 7.x x86

#Base functions
#======================================================================
echoColor(){
color=$1
statement=$2
no_wrap=$3
[[ $no_wrap != 'no' ]] && echo -e "\e[1;"$color"$statement \e[0m" || echo -ne "\e[1;"$color"$statement \e[0m"
}

echoTime(){
echo -ne "\e[01;32m倒计时：\e[0m";tput sc;i=3;until [ $i -eq 0 ];do tput rc;tput ed;echo -n $i;let i--;sleep 1;done;echo
}

countdown(){
for((i=3;i>=0;i--));do echo -ne "\r\033[01;32mCountdown: \033[0m$i";sleep 1;done;echo
}
#======================================================================

temp_path=$(dirname $0)
cd $temp_path
real_path=$(pwd)
cd $real_path
alias cp='cp'
#===========================Global values==============================
#Software version
jemalloc_version='jemalloc-4.5.0.tar.bz2'
mysql_version='mysql-boost-5.7.18.tar.gz'
nginx_version='nginx-1.12.0.tar.gz'
php_version='php-7.2.1.tar.gz'
boost_version='boost_1_59_0.tar.bz2'
libiconv_version='libiconv-1.14.tar.gz'
libiconv_patch='libiconv-glibc-2.16.patch'
libmcrypt_version='libmcrypt-2.5.8.tar.gz'
mhash_version='mhash-0.9.9.9.tar.gz'
mcrypt_version='mcrypt-2.6.8.tar.gz'
openssl_version='openssl-1.0.2k.tar.gz'
pcre_version='pcre-8.39.tar.gz'
curl_version='curl-7.52.1.tar.gz'

#Machine
Mem=4096
Memory_limit=512
run_user="www"

#Install path
defaults_dir=/usr/local/src
mysql_install_path=/usr/local/mysql
nginx_install_path=/usr/local/nginx
php_install_path=/usr/local/php

mysql_db=/data/mysqlDB/master
mysql_port=5896
mysql_sock=$mysql_db/$mysql_port/mysql-${mysql_port}.sock
mysql_storage=$mysql_db/$mysql_port/data
mysql_password='123456'
mysql_conf_temp=/tmp/my.cnf

mysql_logs=$mysql_db/$mysql_port/logs
mysql_binlogs=$mysql_db/$mysql_port/binlogs
mysql_conf=$mysql_db/$mysql_port/conf

nginx_html=/data/html
nginx_demo=$nginx_html/web1
nginx_demo_logs=$nginx_demo/logs

#Install information log
install_log=$(pwd)/install.log
>$install_log
cp $real_path/src/* $defaults_dir

#Compiled thread
thread=`cat /proc/cpuinfo | grep processor | wc -l`
let thread=$thread/2

[ `whoami` != "root" ] && echo "Please run as root" && exit 3

cat<<EOF
Check software version:
jemalloc————-${jemalloc_version}
mysql—————-${mysql_version}
nginx—————-${nginx_version}
php——————${php_version}
boost—————-${boost_version}
libiconv————-${libiconv_version}
libmcrypt————${libmcrypt_version}
mhash—————-${mhash_version}
mcrypt—————${mcrypt_version}
openssl————--${openssl_version}
pcre—————--${pcre_version}
curl—————--${curl_version}
EOF

#===========================All functions==============================

log_func() {
if [ "$resval" -eq 0 ];then
echo "[$(date "+%F %T")]" $1 install completed! >> $install_log
return 0
else
echo "[$(date "+%F %T")]" $1 install failed! >> $install_log
return 11
fi
}
package_install() {
list="cmake ncurses-devel libcurl-devel bzip2 patch gcc gcc-c++ make libicu libicu-devel freetype-devel libxslt libxslt-devel libpng libpng-devel openssl-devel libxml2-devel libaio"
yum install -y $list
}

jemalloc_install() {
cd $defaults_dir
tar xf $jemalloc_version
cd `echo "${jemalloc_version}" | sed 's@.tar.*@@g'`
LDFLAGS="${LDFLAGS} -lrt" ./configure
make -j $thread && make install
if [ $? -eq 0 ];then
ln -svf /usr/local/lib/libjemalloc.so.2 /usr/lib/libjemalloc.so.1
echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
ldconfig
echo "[$(date "+%F %T")] jemalloc install completed!" >> $install_log
else
echo "[$(date "+%F %T")] jemalloc install failed,exit!" >> $install_log
kill -9 $$
fi
}

mysql_install() {
cp $real_path/config/.dbp /data/
useradd -r -s /sbin/nologin mysql
mkdir -pv $mysql_db
cd $defaults_dir
tar xf $mysql_version
cd `echo "${mysql_version}" | sed 's@.tar.*@@g' | sed 's@-boost@@g'`
cmake . -DCMAKE_INSTALL_PREFIX=${mysql_install_path} \
-DDEFAULT_CHARSET=utf8mb4 \
-DDEFAULT_COLLATION=utf8mb4_general_ci \
-DWITH_EXTRA_CHARSETS=complex \
-DDOWNLOAD_BOOST=1 \
-DWITH_BOOST=./boost/boost_1_59_0 \
-DCMAKE_EXE_LINKER_FLAGS='-ljemalloc'
make -j $thread && make install

resval=$?
log_func mysql
[ $? -ne 0 ] && return 12

#initialization mysql
mkdir -pv $mysql_storage $mysql_binlogs $mysql_conf $mysql_logs
chown -R mysql. $mysql_db/*

cat > $mysql_conf_temp << EOF
# MySQL5.7.18 #
[client]
default-character-set = utf8mb4
port = ${mysql_port}
socket = ${mysql_sock}

[mysql]
prompt = "\\u@master [\\d]>"
no-auto-rehash

[mysqld]

# GENERAL #
basedir = ${mysql_install_path}
pid-file = $mysql_db/$mysql_port/mysql-${mysql_port}.pid
socket = ${mysql_sock}
user = mysql
port = ${mysql_port}
server-id = 1
character-set-server = utf8mb4
init-connect = 'SET NAMES utf8mb4'
default_storage_engine = InnoDB

# MyISAM #
key_buffer_size = 16M

# SAFETY #
bind-address = 0.0.0.0
skip-name-resolve
back_log = 300
max_allowed_packet = 4M
max_connect_errors = 10000

# DATA STORAGE #
datadir = ${mysql_storage}

# BINARY LOGGING #
binlog_format = mixed
log_bin = ../binlogs/mysql-bin
max_binlog_size = 1024M
expire_logs_days = 7
sync-binlog = 1

# CACHES AND LIMITS #
tmp_table_size = 32M
max_heap_table_size = 32M
query_cache_type = 1
query_cache_size = 16M
query_cache_limit = 2M
max_connections = 1000
thread_cache_size = 16
open_files_limit = 65535
table_definition_cache = 512
table_open_cache = 512

# INNODB #
#innodb_flush_method = O_DIRECT
innodb_log_files_in_group = 4
innodb_log_file_size = 32M
innodb_flush_log_at_trx_commit = 1
innodb_file_per_table = 1
innodb_buffer_pool_size = 256M
innodb_data_file_path = ibdata1:128M:autoextend
innodb_doublewrite = 1
innodb_open_files = 500
innodb_write_io_threads = 8
innodb_read_io_threads = 8
innodb_thread_concurrency = 0
innodb_purge_threads = 1
innodb_log_buffer_size = 4M
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120

# LOGGING #
log-error = ${mysql_logs}/mysql-${mysql_port}.err
slow_query_log = 1
long_query_time = 3
slow_query_log_file = ${mysql_logs}/slow.log
#general_log = 1
general_log_file = ${mysql_logs}/general_log.log

# OTHERS #
core-file
#performance_schema = 0
explicit_defaults_for_timestamp
skip-external-locking
join_buffer_size = 2M
sort_buffer_size = 8M
read_buffer_size = 2M
read_rnd_buffer_size = 8M
bulk_insert_buffer_size = 8M
myisam_sort_buffer_size = 16M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1
ft_min_word_len = 4
log_bin_trust_function_creators = 0
interactive_timeout = 28800
wait_timeout = 28800
log_timestamps = SYSTEM

[mysqldump]
quick
max_allowed_packet = 16M

[myisamchk]
key_buffer_size = 16M
sort_buffer_size = 8M
read_buffer = 4M
write_buffer = 4M
EOF

sed -i "s@max_connections.*@max_connections = $(($Mem/2))@" $mysql_conf_temp
if [ $Mem -gt 1500 -a $Mem -le 2500 ];then
sed -i 's@^thread_cache_size.*@thread_cache_size = 16@' $mysql_conf_temp
sed -i 's@^query_cache_size.*@query_cache_size = 16M@' $mysql_conf_temp
sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 16M@' $mysql_conf_temp
sed -i 's@^key_buffer_size.*@key_buffer_size = 16M@' $mysql_conf_temp
sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 128M@' $mysql_conf_temp
sed -i 's@^tmp_table_size.*@tmp_table_size = 32M@' $mysql_conf_temp
sed -i 's@^table_open_cache.*@table_open_cache = 256@' $mysql_conf_temp
elif [ $Mem -gt 2500 -a $Mem -le 3500 ];then
sed -i 's@^thread_cache_size.*@thread_cache_size = 32@' $mysql_conf_temp
sed -i 's@^query_cache_size.*@query_cache_size = 32M@' $mysql_conf_temp
sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 32M@' $mysql_conf_temp
sed -i 's@^key_buffer_size.*@key_buffer_size = 64M@' $mysql_conf_temp
sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 512M@' $mysql_conf_temp
sed -i 's@^tmp_table_size.*@tmp_table_size = 64M@' $mysql_conf_temp
sed -i 's@^table_open_cache.*@table_open_cache = 512@' $mysql_conf_temp
elif [ $Mem -gt 3500 ];then
sed -i 's@^thread_cache_size.*@thread_cache_size = 64@' $mysql_conf_temp
sed -i 's@^query_cache_size.*@query_cache_size = 64M@' $mysql_conf_temp
sed -i 's@^myisam_sort_buffer_size.*@myisam_sort_buffer_size = 64M@' $mysql_conf_temp
sed -i 's@^key_buffer_size.*@key_buffer_size = 256M@' $mysql_conf_temp
sed -i 's@^innodb_buffer_pool_size.*@innodb_buffer_pool_size = 1024M@' $mysql_conf_temp
sed -i 's@^tmp_table_size.*@tmp_table_size = 128M@' $mysql_conf_temp
sed -i 's@^table_open_cache.*@table_open_cache = 1024@' $mysql_conf_temp
fi

cp $mysql_conf_temp $mysql_conf/master.cnf
rm -f $mysql_conf_temp
sed -i 's@executing mysqld_safe@executing mysqld_safe\nexport LD_PRELOAD=/usr/local/lib/libjemalloc.so@' $mysql_install_path/bin/mysqld_safe
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
echo "[$(date "+%F %T")] mysql start ok!" >> $install_log
$mysql_install_path/bin/mysql --defaults-file=$mysql_real_conf -e "grant all privileges on *.* to root@'127.0.0.1′ identified by \"${mysql_password}\" with grant option;"
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
chmod +x $mysql_db/$mysql_port/*.sh
systemctl enable mysqld
systemctl start mysqld
else
echo "[$(date "+%F %T")] mysql start failed!" >> $install_log
fi
}

nginx_install() {
cd $defaults_dir
useradd -M -s /sbin/nologin ${run_user}
tar xf $nginx_version
tar xf $openssl_version
tar xf $pcre_version
cd `echo "${nginx_version}" | sed 's@.tar.*@@g'`
# close debug
sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc
./configure --prefix=${nginx_install_path} --user=${run_user} --group=${run_user} --with-http_stub_status_module \
--with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_realip_module \
--with-http_flv_module --with-http_mp4_module --with-openssl=../`echo "${openssl_version}" | sed 's@.tar.*@@g'` \
--with-pcre=../`echo "${pcre_version}" | sed 's@.tar.*@@g'` --with-pcre-jit --with-ld-opt='-ljemalloc'
make -j $thread && make install

resval=$?
log_func nginx
[ $? -ne 0 ] && return 12

#initialization nginx
mkdir -pv $nginx_html
mkdir -pv $nginx_demo
mkdir -pv $nginx_demo_logs
chown -R $run_user. $nginx_html

cp $real_path/config/nginx.conf $nginx_install_path/conf/
mkdir $nginx_install_path/conf/vhost
cp $real_path/config/{web1.conf,status} $nginx_install_path/conf/vhost
cp $real_path/config/nginx /etc/init.d/nginx
chmod +x /etc/init.d/nginx
chkconfig --add nginx ; chkconfig nginx on
/etc/init.d/nginx start
netstat -tunlp | grep 81
{ echo > /dev/tcp/127.0.0.1/81; } 2>/dev/null
if [ $? -eq 0 ];then
echo "[$(date "+%F %T")] nginx start ok!" >> $install_log
else
echo "[$(date "+%F %T")] nginx start failed!" >> $install_log
fi
}
other_install(){

#compile libiconv
cd $defaults_dir
tar xf $libiconv_version
patch -d `echo "${libiconv_version}" | sed 's@.tar.*@@g'` -p0 < $defaults_dir/$libiconv_patch
cd `echo "${libiconv_version}" | sed 's@.tar.*@@g'`
./configure --prefix=/usr/local
make -j $thread && make install
resval=$?
log_func libiconv
[ $? -ne 0 ] && return 12
#compile curl
cd $defaults_dir
tar xf $curl_version
cd `echo "${curl_version}" | sed 's@.tar.*@@g'`
./configure --prefix=/usr/local
make -j $thread && make install
resval=$?
log_func curls
[ $? -ne 0 ] && return 12

#compile libmcrypt
cd $defaults_dir
tar xf $libmcrypt_version
cd `echo "${libmcrypt_version}" | sed 's@.tar.*@@g'`
./configure
make -j $thread && make install
ldconfig
cd libltdl
./configure --enable-ltdl-install
make -j $thread && make install
resval=$?
log_func libmcrypt
[ $? -ne 0 ] && return 12

#compile mhash
cd $defaults_dir
tar xf $mhash_version
cd `echo "${mhash_version}" | sed 's@.tar.*@@g'`
./configure
make -j $thread && make install
resval=$?
log_func mhash
[ $? -ne 0 ] && return 12

echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf
ldconfig

#compile mcrypt
ln -sv /usr/local/bin/libmcrypt-config /usr/bin/libmcrypt-config
ldconfig
cd $defaults_dir
tar xf $mcrypt_version
cd `echo "${mcrypt_version}" | sed 's@.tar.*@@g'`
./configure
make -j $thread && make install
resval=$?
log_func mcrypt
[ $? -ne 0 ] && return 12

ldconfig
}
php_install() {
#compile php
cd $defaults_dir
tar xf $php_version
cd `echo "${php_version}" | sed 's@.tar.*@@g'`

./configure --prefix=$php_install_path --with-config-file-path=$php_install_path/etc --with-config-file-scan-dir=$php_install_path/etc/php.d --with-fpm-user=$run_user --with-fpm-group=$run_user --enable-fpm --enable-opcache --disable-fileinfo --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir=/usr/local --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-exif --enable-sysvsem --with-curl --enable-mbregex --enable-inline-optimization --enable-mbstring --with-gd --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-ftp --enable-intl --with-xsl --with-gettext --enable-zip --enable-soap --disable-ipv6 --disable-debug
#为了防止make时候报错，remove libcurl-devel
yum remove -y libcurl-devel
make ZEND_EXTRA_LIBS='-liconv' -j $thread
make install

resval=$?
log_func php
[ $? -ne 0 ] && return 12

#initialization php
[ ! -e "$php_install_path/etc/php.d" ] && mkdir -pv $php_install_path/etc/php.d
cp php.ini-production $php_install_path/etc/php.ini

#setting php
sed -i "s@^memory_limit.*@memory_limit = ${Memory_limit}M@" ${php_install_path}/etc/php.ini
sed -i 's@^output_buffering =@output_buffering = On\noutput_buffering =@' ${php_install_path}/etc/php.ini
sed -i 's@^;cgi.fix_pathinfo.*@cgi.fix_pathinfo=0@' ${php_install_path}/etc/php.ini
sed -i 's@^short_open_tag = Off@short_open_tag = On@' ${php_install_path}/etc/php.ini
sed -i 's@^expose_php = On@expose_php = Off@' ${php_install_path}/etc/php.ini
sed -i 's@^request_order.*@request_order = "CGP"@' ${php_install_path}/etc/php.ini
sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' ${php_install_path}/etc/php.ini
sed -i 's@^post_max_size.*@post_max_size = 100M@' ${php_install_path}/etc/php.ini
sed -i 's@^upload_max_filesize.*@upload_max_filesize = 50M@' ${php_install_path}/etc/php.ini
sed -i 's@^max_execution_time.*@max_execution_time = 600@' ${php_install_path}/etc/php.ini
sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket,popen@' ${php_install_path}/etc/php.ini
sed -i 's@^max_input_time.*@max_input_time = 300@' ${php_install_path}/etc/php.ini
[ -e /usr/sbin/sendmail ] && sed -i 's@^;sendmail_path.*@sendmail_path = /usr/sbin/sendmail -t -i@' ${php_install_path}/etc/php.ini

#setting opcache
cat > $php_install_path/etc/php.d/opcache.ini << EOF
[opcache]
zend_extension=opcache.so
opcache.enable=0
opcache.enable_cli=1
opcache.memory_consumption=$Memory_limit
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=100000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=60
opcache.save_comments=0
opcache.fast_shutdown=1
opcache.consistency_checks=0
;opcache.optimization_level=0
EOF

#setting php-fpm
cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm

cat > ${php_install_path}/etc/php-fpm.conf << EOF
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]
pid = run/php-fpm.pid
error_log = log/php-fpm.log
log_level = warning

emergency_restart_threshold = 30
emergency_restart_interval = 60s
process_control_timeout = 5s
daemonize = yes

;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ;
;;;;;;;;;;;;;;;;;;;;

[$run_user]
listen = /dev/shm/php-cgi.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = $run_user
listen.group = $run_user
listen.mode = 0666
user = $run_user
group = $run_user

pm = dynamic
pm.max_children = 12
pm.start_servers = 8
pm.min_spare_servers = 6
pm.max_spare_servers = 12
pm.max_requests = 2048
pm.process_idle_timeout = 10s
request_terminate_timeout = 120
request_slowlog_timeout = 0

pm.status_path = /php-fpm_status
slowlog = log/slow.log
rlimit_files = 51200
rlimit_core = 0

catch_workers_output = yes
;env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF

[ -d "/run/shm" -a ! -e "/dev/shm" ] && sed -i 's@/dev/shm@/run/shm@' $php_install_path/etc/php-fpm.conf $nginx_install_path/conf/nginx.conf

if [ $Mem -le 3000 ];then
sed -i "s@^pm.max_children.*@pm.max_children = $(($Mem/3/20))@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.start_servers.*@pm.start_servers = $(($Mem/3/30))@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = $(($Mem/3/40))@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = $(($Mem/3/20))@" ${php_install_path}/etc/php-fpm.conf
elif [ $Mem -gt 3000 -a $Mem -le 4500 ];then
sed -i "s@^pm.max_children.*@pm.max_children = 50@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.start_servers.*@pm.start_servers = 30@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 20@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 50@" ${php_install_path}/etc/php-fpm.conf
elif [ $Mem -gt 4500 -a $Mem -le 6500 ];then
sed -i "s@^pm.max_children.*@pm.max_children = 60@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.start_servers.*@pm.start_servers = 40@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 30@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 60@" ${php_install_path}/etc/php-fpm.conf
elif [ $Mem -gt 6500 -a $Mem -le 8500 ];then
sed -i "s@^pm.max_children.*@pm.max_children = 70@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.start_servers.*@pm.start_servers = 50@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 40@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 70@" ${php_install_path}/etc/php-fpm.conf
elif [ $Mem -gt 8500 ];then
sed -i "s@^pm.max_children.*@pm.max_children = 80@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.start_servers.*@pm.start_servers = 60@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 50@" ${php_install_path}/etc/php-fpm.conf
sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 80@" ${php_install_path}/etc/php-fpm.conf
fi

/etc/init.d/php-fpm start
if [ $? -eq 0 ];then
echo "[$(date "+%F %T")] php start ok!" >> $install_log
/etc/init.d/php-fpm stop
chkconfig --add php-fpm
systemctl daemon-reload
systemctl start php-fpm
echo "export PATH=$PATH:/usr/local/mysql/bin:/usr/local/php/bin:/usr/local/nginx/sbin" > /etc/profile.d/lnmp.sh
source /etc/profile.d/lnmp.sh
else
echo "[$(date "+%F %T")] php start failed!" >> $install_log
fi
}

############Execute Functions#################

echo "——--3 seconds after the start———"
countdown
start_time=`date "+%F %T"`
echo "start_time: [$start_time]" > $install_log
package_install
jemalloc_install
mysql_install
nginx_install
other_install
php_install
end_time=`date "+%F %T"`
echo "end_time: [$end_time]" >> $install_log
echo 3 > /proc/sys/vm/drop_caches

