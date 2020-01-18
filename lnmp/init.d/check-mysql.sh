#!/bin/sh

temp_path=$(dirname $0)
cd $temp_path
real_path=$(pwd)
cd $real_path

MYSQL_PWD=`cat /data/.dbp`
export MYSQL_PWD
/usr/local/mysql/bin/mysqladmin --defaults-file=./conf/my.cnf -uroot -Pport ping
