Rsync Service Configure
=====

一、同步方式
------
1. 本地间数据同步,类似cp命令
2. 远程同步即ssh方式进行数据同步
3. 以服务方式进行数据同步
***
二、rsync参数
-------
***
-v, --verbose 详细模式输出  
-q, --quiet 精简输出模式  
-c, --checksum 打开校验开关，强制对文件传输进行校验  
-a, --archive 归档模式，表示以递归方式传输文件，并保持所有文件属性，等于-rlptgoD  
-r, --recursive 对子目录以递归模式处理  
-R, --relative 使用相对路径信息  
-b, --backup 创建备份，也就是对于目的已经存在有同样的文件名时，将老的文件重新命名为\~filename，可以使用--suffix选项来指定不同的备份文件前缀  
--backup-dir 将备份文件(如~filename)存放在在目录下  
-suffix=SUFFIX 定义备份文件前缀  
-u, --update 仅仅进行更新，也就是跳过所有已经存在于DST，并且文件时间晚于要备份的文件。(不覆盖更新的文件)  
-l, --links 保留软链接  
-L, --copy-links 想对待常规文件一样处理软链结  
--copy-unsafe-links 仅仅拷贝指向SRC路径目录树以外的链结  
--safe-links 忽略指向SRC路径目录树以外的链结  
-H, --hard-links 保留硬链结  
-p, --perms 保持文件权限  
-o, --owner 保持文件属主信息  
-g, --group 保持文件属组信息  
-D, --devices 保持设备文件信息  
-t, --times 保持文件时间信息  
-S, --sparse 对稀疏文件进行特殊处理以节省DST的空间  
-n, --dry-run现实哪些文件将被传输  
-W, --whole-file 拷贝文件，不进行增量检测  
-x, --one-file-system 不要跨越文件系统边界  
-B, --block-size=SIZE 检验算法使用的块尺寸，默认是700字节  
-e, --rsh=COMMAND 指定使用rsh、ssh方式进行数据同步  
--rsync-path=PATH 指定远程服务器上的rsync命令所在路径信息  
-C, --cvs-exclude 使用和CVS一样的方法自动忽略文件，用来排除那些不希望传输的文件  
--existing 仅仅更新那些已经存在于DST的文件，而不备份那些新创建的文件  
--delete 删除那些DST中SRC没有的文件  
--delete-excluded 同样删除接收端那些被该选项指定排除的文件  
--delete-after 传输结束以后再删除  
--ignore-errors 及时出现IO错误也进行删除  
--max-delete=NUM 最多删除NUM个文件  
--partial 保留那些因故没有完全传输的文件，以是加快随后的再次传输  
--force 强制删除目录，即使不为空  
--numeric-ids 不将数字的用户和组ID匹配为用户名和组名  
--timeout=TIME IP超时时间，单位为秒  
-I, --ignore-times 不跳过那些有同样的时间和长度的文件  
--size-only 当决定是否要备份文件时，仅仅察看文件大小而不考虑文件时间  
--modify-window=NUM 决定文件是否时间相同时使用的时间戳窗口，默认为0  
-T --temp-dir=DIR 在DIR中创建临时文件  
--compare-dest=DIR 同样比较DIR中的文件来决定是否需要备份  
-P 等同于 --partial  
--progress 显示备份过程  
-z, --compress 对备份的文件在传输时进行压缩处理  
--exclude=PATTERN 指定排除不需要传输的文件模式  
--include=PATTERN 指定不排除而需要传输的文件模式  
--exclude-from=FILE 排除FILE中指定模式的文件  
--include-from=FILE 不排除FILE指定模式匹配的文件  
--version 打印版本信息  
--address 绑定到特定的地址  
--config=FILE 指定其他的配置文件，不使用默认的rsyncd.conf文件  
--port=PORT 指定其他的rsync服务端口  
--blocking-io 对远程shell使用阻塞IO  
-stats 给出某些文件的传输状态  
--progress 在传输时显示传输过程  
--log-format=formAT 指定日志文件格式  
--password-file=FILE 从FILE中得到密码  
--bwlimit=KBPS 限制I/O带宽，KBytes per second
***
三、本地间数据同步
---
* **rsync  选项 本地目录1  本地目录2**    
* **rsync  选项 本地目录1/ 本地目录2**  

需要注意的是带”/”和不带的区别，带”/”是同步目录下的所有数据，不带”/”是同步全部数据，包括目录。  

**实例操作:**  
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-1.png)  

上面演示是带”/”情况下，只同步/root/test下所有数据到/data/test下  

![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-2.png)  

上面是不带”/”情况下，可以看出/root/tesst整个目录被同步到/data/test下，所以在使用rsync时，要注意是要带”/”还是不带”/”。
***
四、远程同步
---
* **rsync  选项 /路径/目录  用户名@对方IP:/路径/目录    #本地--->远程** 
* **rsync  选项 用户名@对方IP:/路径/对方目录 /路径/目录 #远程--->本地**  

同样需要注意带”/”以及不带”/”的问题，为避免每次需要输入密码，可以进行免密登录，具体操作如下：  

**生成公私钥  
sh-keygen  #一路回车,生成的公私钥存放在用户家目录.ssh/下  
拷贝公钥  
#ssh-copy-id  用户@对方IP #收到所有客户端传来的密钥会放在家目录下的.ssh下的authorized_keys**  

**实时同步:**  

原理就是当检测被同步端的目录或者文件发生改变了如增加了，检测到后自动发起同步，这中间需要个监测工具inotify，  
再自己写个脚本就可以实现这个功能了；可先下载inotify-tools上传到服务器编译安装,下面操作都是在被同步端下操作。  

**#tar -zxvf inotify-tools-3.13.tar.gz  
#cd  inotify-tools-3.13   
#./configure;make;make install  
#ln -s /root/inotify-tools-3.13/libinotifytools/src/.libs/libinotifytools.so.0 /usr/lib64/libinotifytools.so.0**  

编译完后会生成两个命令，一个inotifywait，一个inotifywatch，下面主要用到inotifywait。  

inotifywait  选项    目标文件夹  
             -m    持续监控（捕获一个事件后不退出）  
             -r    递归监控  
             -q    减少屏幕输出  
             -e    指定监视的modify，move，create，delete，attrib  

**脚本配合:**  
#!/bin/bash  
dir=/opt/  #要同步的目录  
while  inotifywait -rqq $dir  
do
  rsync -az --delete  $dir   root@同步端IP:/mnt/  
done  
**#nohup  sh /data/sh/rsync.sh > /dev/null& #也可使用计划任务**  
***
五、rsync服务同步
---
**服务端配置:**  
#yum install -y rsync  
主配置文件：**/etc/rsyncd.conf**  
该配置文件内容都为注释状态，可根据实际情况配置，下面给出一些参数，仅供参考  
***
#设置进行数据传输时所使用的帐户名或ID号，默认使用nobody  
uid = nobody   
#设置进行数据传输时所使用的组名或GID号，默认使用nobody  
gid = nobody  
#若为yes, rsync会首先进行chroot设置，将根映射在下面的path参数路径下，对客户端而言，系统的根就是path参数指定的路径。  
但这样做需要root权限，并且在同步符号连接资料时只会同步名称，不会同步内容  
use chroot = yes  
#设置服务器监听的端口号，默认是873  
port = 11000  
#设置日志文件名，可通过log format参数设置日志格式  
log file = /var/log/rsyncd.log  
#设置rsync进程号保存文件名称  
pid file = /var/run/rsyncd.pid  
#密码验证文件名，该文件权限要求为只读，建议为600，仅在设置auth users后有效  
secrets file = /etc/rsyncd.db  
#忽略一些IO错误  
ignore errors = true  
timeout = 600      
#开启rsync数据传输日志功能  
transfer logging = true  
#客户端请求显示模块列表时，本模块名称是否显示，默认为true  
list = false  
#不用root用户也可以存储文件的完整属性  
fake super = yes  
#指定那些在传输之前不进行压缩处理的文件  
dont compress = \*.gz \*.tgz \*.zip \*.z \*.rpm \*.deb \*.iso \*.bz2 \*.tbz \*.rar  
#自定义模块名，rsync通过模块定义同步的目录，可定义多个  
[serverapp]  
#同步目录的真是路径通过path指定  
path = /data/update/server-app  
#定义注释说明字串  
comment = server app files   
#是否允许客户端上传数据，yes表示不允许  
read only = no   
#设置允许连接服务器的账户，此账户可以是系统中不存在的用户  
auth users = test1  
***
**创建密码验证文件，格式为用户名:密码**  
#echo test1:123456 >/etc/rsyncd.db  
#chmod 600 /etc/rsyncd.db   
**开启服务**  
#systemctl start rsyncd  
**如果不是使用默认配置文件，则用下面这种**  
#rsync --daemon --config=文件名  

**客户端配置:** 

**创建密码文件**  
#echo 123456 >/data/.rspas  
#chmod 600 /data/.rspas

**实例操作:**  

**#客户端发起#  
第一种方式：注意是双冒号**  
#rsync -avcz --progress --delete --password-file=密码文件 --port=11000 /root/test test1@服务端IP::serverapp  
**第二种方式：**  
#rsync -avcz --progress --delete --password-file=密码文件 --port=11000  /root/test/  rsync://test1@服务端IP/serverapp  

也是需要注意带”/”以及不带”/”问题  
![do](https://www.zhengxk.com/wp-content/uploads/2019/07/image-3-1024x257.png)  
![do](https://www.zhengxk.com/wp-content/uploads/2019/07/image-4.png)  
***
六、异常处理
---
在三种方式中，rsync同步方式遇到的问题会多点，下面的异常都是针对rsync服务同步方式进行。  
***  
问题一:rsync: chgrp "/." (in serverapp) failed: Operation not permitted (1)  
原因:版本更新问题  
处理:服务端主配置文件添加fake super = yes
***
问题二:   
rsync: delete of stat xattr failed for "/." (in serverapp): Permission denied (13)  
rsync: failed to set times on "/." (in serverapp): Operation not permitted (1)   
rsync error: some files/attrs were not transferred (see previous errors) (code 23) at main.c(1178) [sender=3.1.2  
原因:同步目标目录属主问题，权限不足导致没有写的权限，在配置文件中我指定nobody，是权限最小的用户，而同步目标目录属主为root且目录权限为755  
处理一:同步目标目录权限改为777，执行chmod 777 同步目标目录；文件能成功同步，但还是会显示错误  
处理二:主配置文件rsyncd.conf中uid和gid改为root，重启生效，后面可以再改回nobody  
处理三:直接修改同步目标目录属主，执行chown nobody.nobody 同步目标目录，本人推荐使用这种
***
问题三:  
ERROR: password file must not be other-accessible  
rsync error: syntax or usage error (code 1) at authenticate.c(196)[sender=3.1.2]   
原因:客户端密码文件权限不对，必须是600，不能多也不能少    
处理:chmod 600 客户端密码文件
***
问题四:  
@ERROR: auth failed on module serverapp  
rsync error: error starting client-server protocol (code 5) at main.c(1648) [sender=3.1.2]  
原因:服务端密钥文件权限不对，必须是600，不能多也不能少   
处理:chmod 600 服务端秘钥文件
***
