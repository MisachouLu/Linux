# Configure  

测试环境或者生产环境可能有不同人上去操作，比如开发人员，测试人员以及运维人员，如果使用分配账号登录显得很难管理，而且另一方面操作者的记录很难区分是开发人员具体那个人操作，所以可能会有后面服务器出问题没有明确详细的人员操作日志，那就只得运维背锅了，为了更安全更规范地记录操作记录，有了我们之前[基于key登录服务器操作](https://github.com/zhengxuekang/CentOS/tree/master/ssh/%E5%9F%BA%E4%BA%8Ekey%E7%99%BB%E5%BD%95%E6%9C%8D%E5%8A%A1%E5%99%A8)，现在，我们延续这个操作，详细记录每个登录人员的操作记录。  

## 一、配置   

这里引入脚本[user_log.sh](https://github.com/zhengxuekang/CentOS/blob/master/ssh/%E5%9F%BA%E4%BA%8Ekey%E8%AE%B0%E5%BD%95%E7%94%A8%E6%88%B7%E5%8E%86%E5%8F%B2%E6%93%8D%E4%BD%9C/user_log.sh)，将脚本放在/etc/profile.d下，适用于centos7+，用户登录时候会执行该目录下的脚本文件，所以该目录可定制一些操作，这里不展开说明。  
***
## 二、测试  
~/.ssh/authorized_keys文件中需要有内容，并按照"**ssh-rsa 公钥内容 用户**"格式排列好，使用不同用户的私钥登录到服务器，查看目录/var/log/login/histlog/下是否有生成对应以用户名命名的日志文件。  
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-92-1024x291.png)  
如上图所示，使用不同私钥登录到服务器后都有生成对应的文件，再看下对应文件内容，发现正是刚才的历史操作。  
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-93.png)  
文件中的时间格式不是正常的时间格式而是具体的时间戳，可使用[view_log.sh](https://github.com/zhengxuekang/CentOS/blob/master/ssh/%E5%9F%BA%E4%BA%8Ekey%E8%AE%B0%E5%BD%95%E7%94%A8%E6%88%B7%E5%8E%86%E5%8F%B2%E6%93%8D%E4%BD%9C/view_log.sh)脚本进行查看，效果如下图所示:  
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-94-1024x277.png)
***
