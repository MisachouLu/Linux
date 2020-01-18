# FTP Configure
## 一、FTP工作模式  

FTP有两种工作模式，一种为主动模式，一种为被动模式。   
**主动模式(port)下**，客户机端口(>1024的随机端口号)与FTP服务端的21号端口建立连接关系(登录) ， 建立好连接后，进行数据传输，客户端端口 (>1024的随机端口号) 与FTP服务端的20端口进行连接，数据开始传输。   
**被动模式(pasv)下**，客户机端口(>1024的随机端口号)与FTP服务端的21号端口建立连接关系(登录)， 建立好连接后，进行数据传输，客户端端口 (>1024的随机端口号) 与FTP服务端的端口(>1024的随机端口号)进行连接，数据开始传输。  

通常客户端是以被动模式去访问FTP服务端的，当FTP服务端上开防火墙时，在FTP服务端的vsftpd.conf和防火墙上要指定放行的被动模式端口范围的最小值和最大值。  

FTP服务中存在三类用户：本地用户、匿名用户、虚拟用户。  
**本地用户**：服务器上存在的用户，访问的是用户自己的家目录(如user1用户访问的是/home/user1目录)；  
**匿名用户**：匿名用户实际上有一个与之对应的系统用户ftp这个用户默认是匿名用户所对应的用户,匿名用户映射为ftp用户，匿名用户访问的是/var/ftp目录；  
**虚拟用户**：是FTP专有用户，有两种方式实现虚拟用户，本地数据文件和数据库服务器。
***
## 二、安装

#yum install -y vsftpd  
#systemctl start vsftpd  
#systemctl enable vsftpd
***
## 三、配置文件说明  

FTP服务端配置文件目录为/etc/vsftpd，下面默认存在三个文件，**ftpusers**、**user_list**以及主配置文件**vsftpd.conf**，下面看下三个文件的说明。  

ftpusers相当于一份黑名单，不受任何配置影响，总是有效，该文件存放的是一个禁止访问FTP的用户列表，通常为了安全考虑，管理员不希望一些拥有过大权限的帐号（比如root)登入FTP，以免通过该帐号从FTP上传或下载一些危险位置上的文件从而对系统造成损坏。  

userlist_enable和userlist_deny两个选项联合起来针对的是本地全体用户(除去ftpusers中的用户)和出现在user_list文件中的用户以及不在user_list文件中的用户这三类用户集合进行的设置。  
当且仅当userlist_enable=YES时，userlist_deny项的配置才有效，user_list文件才会被使用；当其为NO时，无论userlist_deny项为何值都是无效的，本地全体用户(除去ftpusers中的用户)都可以登入FTP。  
当userlist_enable=YES时，userlist_deny=YES时，user_list是一个黑名单，即所有出现在名单中的用户都会被拒绝登入；  
当userlist_enable=YES时，userlist_deny=NO时，user_list是一个白名单，即只有出现在名单中的用户才会被准许登入(user_list之外的用户都被拒绝登入)；另外需要特别提醒的是，使用白名单后，匿名用户将无法登入，除非显式在user_list中加入一行anonymous。  

主配置文件vsftpd.conf配置列举了一些常用配置项，可根据实际情况选择配置。
***
## 四、主动模式配置  

添加：port_enable=YES #开启主动模式  
修改：anonymous_enable=NO #禁用匿名登录  
重启服务：systemctl restart vsftpd  

使用FTP客户端测试连接，注意需要看下客户端配置是为主动模式还是被动模式，一般默认都为主动模式。
***
## 五、被动模式配置 

关闭主动模式，把被动模式开起来，添加被动模式下端口范围，如果有防火墙记得打开端口范围。   

port_enable=NO  
pasv_enable=YES  
pasv_min_port=5000  
pasv_max_port=6000  
#systemctl restart vsftpd  
注意需要配置客户端为被动模式。
