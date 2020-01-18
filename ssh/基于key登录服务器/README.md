# Configure
## 一、ssh认证方式   
* **基于口令认证**  
基于口令的安全验证的方式就是大家现在一直在用的，只要知道服务器的SSH连接帐号和口令(当然也要知道对应服务器的 IP及开放的 SSH端口，默认为22 ),就可以通过ssh客户端登录到这台远程主机。此时，联机过程中所有传输的数据都是加密的。不过这要求输入的密码具有足够的复杂度才能具有更高的安全性;
* **基于密钥认证**
基于密钥的安全验证必须为用户自己创建一对密钥，并把共有的密钥放在需要访问的服务器上。当需要连接到SSH服务器上时，客户端软件就会向服务器发出请求，请求使用客户端的密钥进行安全验证。服务器收到请求之后，先在该用户的根目录下寻找共有密钥，然后把它和发送过来的公有密钥进行比较。如果两个密钥一致，服务器就用公有的密钥加密“质询”，并把它发送给客户端软件。客户端收到质询之后，就可以用本地的私人密钥解密再把它发送给服务器。这种方式是相当安全的。  
***
## 二、配置  
针对口令方式，这里简单带过去，因为平时大家用到的口令方式居多，安全方面可修改默认端口，防火墙规则控制，sudo权限控制，禁止root登录等方式，下面主要针对密钥认证方式配置讲解，讲到密钥就要顺便提下网络中存在的加密方式，一个是对称加密，一个是非对称加密。  
**对称加密**是最快速、最简单的一种加密方式，加密与解密用的是同样的密钥，这里举个例子假设你把1234加密后黑客拿到密钥解密后还是1234，这里也体现了对称加密的一大缺点密钥的管理与分配，换句话说，如何把密钥发送到需要解密你的消息的人的手里是一个问题。在发送密钥的过程中，密钥有很大的风险会被黑客们拦截，常见的对称加密算法有AES和DES。  
**非对称加密**是用公钥和私钥来加解密的算法。打个比方，A的公钥加密过的东西只能通过A的私钥来解密；同理，A的私钥加密过的东西只能通过A的公钥来解密。顾名思义，公钥是公开的，别人可以获取的到；私钥是私有的，只能自己拥有，假设你把1234加密了，黑客拿到私钥解密后可能是dad45，这样即使拿到了私钥但是文件内容还是安全的，但是非对称加密也是存在漏洞，因为公钥是公开的，如果有C冒充B的身份利用A的公钥给A发消息，这样就乱套了，为了解决这一问题，就有了数字签名，由CA组织签名，这次不展开该内容，后面有专门介绍证书配置会讲到，常见的非对称加密算法有RSA和DSA。
另外顺便提下网络中另外种加密方式，叫做信息摘要，一般用来校验文件的完整性，方法有md5、sha128、sha512、sha256，像平常自己会使用md5sum来校验文件md5值。  

**密钥认证方式的配置**    

生成公私钥:  
#ssh-keygen -t rsa -b 2048 -N '' 
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-70.png)  
此时在用户.ssh下会生成私钥和公钥  
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-71.png)  
颁发公钥：  
#ssh-copy-id  用户@对方IP #这里会输入一次对方IP的密码，后面就可以免密登录了
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-72.png)  
颁发公钥后，测试正常后，后面登录禁止使用口令登录，修改服务端/etc/ssh/sshd_config文件，把PasswordAuthentication的yes改为no，这样一样就只能使用密钥登录，大大提高了ssh的安全性。  
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-73-1024x258.png)  
***
## 三、扩展内容  

上面使用密钥验证方式登录服务器，在这里再讲另一个工具CRT，该工具非常强大，有兴趣的可以去了解下，该工具可生成密钥对，登录方式和上面描述一样，我们只需把公钥内容复制到服务端authorized_keys中就可以实现使用通行语(CRT生成密钥对需要输入通行语即密码，后面登录服务端需要验证)，其他第三方工具如XSHELL以及MobaXterm都可生成密钥对，下面看下CRT如何实现该功能。  
**首先需要创建密钥对，如下图所示：**
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-75.png) 
**选择加密方式,一般选择RSA即可**  
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-76.png)
**接下来需要输入通行语** 
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-77.png)
**密钥对长度默认即可** 
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-78.png)
**选择OpenSSH，保存密钥对位置**  
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-85.png)  
接下来需要把公钥内容复制到目标服务器authorized_keys中，根据自己的内容填写，在文件中需要在开头手动写下ssh-rsa，最后面空格在填个标识符，一般写谁谁谁的公钥，后面方便管理，我这里写user1。  
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-86-1024x63.png)
**新建会话** 
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-82.png)
**配置会话选项，选择公钥然后点击属性** 
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-83.png)
**选择刚才创建的私钥**  
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-89.png)
**连接，出现要输入通行语，输入后即可连接上服务器** 
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-87.png)
![test](https://www.zhengxk.com/wp-content/uploads/2019/07/image-88.png)  
在平时运维工作可采用该方式，一方面大大提高服务器安全性，另一方面如果生产服务器多的话维护密码也是头疼的事情，用密钥方式可大大降低运维工作，再者也避免人员随意上到生产环境服务器。
***
