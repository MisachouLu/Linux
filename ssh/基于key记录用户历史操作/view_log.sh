#!/bin/bash
#服务器history按key分离后操作记录查看脚本
cd /var/log/login/histlog/
rm -fr /tmp/usrname.history
ls /var/log/login/histlog/|while read usrname
do
     filename=$usrname
     exec 5<$filename     
     while read line <&5     
     do         
        echo $line|awk '{if ($1 ~/^#[0-9]+/) {split ( $0 , time, "#"); printf (" '$usrname' " strftime("%Y-%m-%d_%H:%M:%S",time[2])"  ")} else print $0 }'>>/tmp/usrname.history
     done
done
sort -k2 /tmp/usrname.history |cat -n
