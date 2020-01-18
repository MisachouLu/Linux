#!/bin/sh

#run_path=/data/mysqlDB/3306
temp_path=$(dirname $0)
cd $temp_path
real_path=$(pwd)
cd $real_path

#[ "$real_path" != "$run_path" ] && echo "The scripts just can run in $run_path" && exit 11

/usr/local/mysql/bin/mysqld_safe --defaults-file=./conf/my.cnf --user=mysql --mysqld-safe-log-timestamps=hyphen --disable-partition-engine-check &
