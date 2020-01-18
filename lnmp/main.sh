#!/bin/bash

temp_path=$(dirname $0)
cd $temp_path
real_path=$(pwd)
cd $real_path
alias cp='cp'


sed -i 's@vbell on@vbell off@g' /etc/screenrc
sed -i 's@^#shell -$SHELL@shell -$SHELL@g' /etc/screenrc
screen -ls | grep init_lnmp
if [ $? -eq 0 ];then
    echo "Error!!The host like already run lnmp environment.Please check it."
    exit
else
    cp -a src/* /usr/local/src
    screen -L -md init_lnmp
    screen -S init_lnmp -p0 -X stuff "$(printf '%b' 'sh /data/cs7LNMP/lnmp-cs7.sh\015')"
fi

