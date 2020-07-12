# 一些Nginx的通用应用场景
## 反向代理
以代理服务器来接收internet上的连接请求，然后将请求转发给内部网络上的服务器，并将服务器上得到的结果返回给internet上请求连接的客户端，此时代理服务器对外就表现为一个反向代理服务器。
即，真实的服务器不能直接被外部网络访问，所以需要一台代理服务器，而代理服务器能被外部网络访问的同时又跟真实服务器在同一个网络环境，当然也可能是同一台服务器，端口不同而已。

## 负载均衡
当有两台或以上的服务器时，根据规则随机的将请求分发到指定的服务器上处理，负载均衡一般都需要同时配置反向代理，通过反向代理跳转到负载均衡。
Nginx目前支持自带3种负载均衡策略，还有2种常用的第三策略。

### RR(默认)
每个请求按时间顺序逐一分配到不同的后端服务器，如果后端服务器down掉，能自动剔除。
```
    upstream test {
        server localhost:8080;
        server localhost:8081;
    }
```


### 权重
指定轮询几率，weight和访问率成正比，用于后端性能不均的情况
```
    upstream test {
        server localhost:8080 weight=9;
        server localhost:8181 weight=1;
    }
```
10次一般只有一次会访问到8081，有9次会访问到8080

### ip_hash
上面的两种方式都有一个问题，那就是下一个请求来的时候请求可能分发到另外一个服务器，这样当前服务器的Session就丢失了
如果需要一个客户只访问一个服务器，那么就需要用iphash了，iphash的每个请求按访问ip的hash结果分配。
这样每个访客固定访问一个后端服务器
```
    upstream test {
        ip_hash;
        server localhost:8080;
        server localhost:8081;
    }
```

### fair(第三方)
按后端服务器的响应时间来分配请求，响应时间短的优先分配
```
    upstream backend{
        fair;
        server localhost:8080;
        server localhost:8081;
    }
```

### url_hash (第三方)
按访问url的hash结果来分配请求，使每个url定向到同一个后端服务器，后端服务器为缓存时比较有效。
在upstream中加入hash语句，server语句中不能写入weight等其他的参数， hash_method是使用的hash算法
```
    upstream backend {
        hash $request_uri;
        hash_method crc32;
        server localhost:8080;
        server localhost:8081;
    }
```

### HTTP服务器
Nginx 本身也是一个静态资源的服务器，当只有静态资源的时候，就可以使用Nginx来做服务器.

### 动静分离
让动态网站里额动态网页根据一定规则把不变的资源和经常变得资源区分开来，动静资源做好了拆分以后，
就可以根据静态资源的特点将其做缓存操作，这是网站静态化处理的核心思路
```
upstream test{
    server localhost:8080;
    server localhost:8081;
}

server{
    listen 80;
    server_name localhost;

    location / {
        root e:\wwwroot;
        index index.html;
    }

    # 所有静态请求都由nginx处理，存放目录为html
    location ~ \.(gif|jpg|jpeg|png|bmp|swf|css|js)$ {  
        root    e:\wwwroot;  
    }

    # 所有动态请求都转发给tomcat处理  
    location ~ \.(jsp|do)$ {  
        proxy_pass  http://test;  
    }  

    error_page   500 502 503 504  /50x.html;  
    location = /50x.html {  
        root   e:\wwwroot;  
    }   
}
```

# Nginx 的工作原理
## Nginx 的模块与工作原理
Nginx由内核和模块组成。
内核的设计非常微小和简洁，它仅仅通过查找配置文件将客户端请求映射到一个location block，而这个location中所配置的每个指令将会启动不同的模块去完成相应的工作

### 核心模块
- HTTP模块
- EVENT模块
- MAIL模块

### 基础模块
- HTTP Access 模块
- HTTP FastCGI模块
- HTTP Proxy模块
- HTTP Rewrite

### 第三方模块
- HTTP Upstream Request Hash模块
- Notice 模块
- HTTP Access Key模块

### 模块从功能上分为以下三类
- Handlers(处理器模块)
此类模块直接处理请求，并进行输出内容和修改headers信息等操作。
Handlers处理器模块一般只能有一个

- Filters (过滤器模块)
此类模块主要对其它处理器模块输出的内容进行修改操作，最后由Nginx输出

- Proxies(代理类模块)
此类模块是Nginx的HTTP Upstream之类的模块，这些模块主要与后端一些服务比如FastCGI等进行交互

Nginx本身做的工作实际很少，当它接到一个HTTP请求时，它仅仅是通过查找配置文件将此次请求映射到一个location block，而此location中所配置的各个指令则会启动不同的模块去完成工作，因此模块可以看做Nginx真正的劳动工作者。通常一个location中的指令会涉及一个handler模块和多个filter模块（当然，多个location可以复用同一个模块）。handler模块负责处理请求，完成响应内容的生成，而filter模块对响应内容进行处理。

## Nginx的进程模型

- 单工作进程（默认）
除主进程外，还有一个工作进程，工作进程是单线程的
- 多工作进程
在多工作进程模式下，每个工作包含多个线程。

Nginx 在启动之后，会有一个master进程和多个wroker进程

### master进程
主要用来管理worker进程
接收来自外界的信号，向各worker进程发送信号，监控worker进程的运行状态，当worker进程退出后(异常情况下)，会自动重新启动新的worker进程。

master进程充当整个进程组与用户的交互接口，同时对进程进行监护。它不需要处理网络事件，不负责业务的执行，只会通过管理worker进程来实现重启服务、平滑升级、更换日志文件、配置文件实时生效等功能。

### worker进程
而基本的网络事件，则是放在worker进程中来处理了。多个worker进程之间是对等的，他们同等竞争来自客户端的请求，各进程互相之间是独立的。一个请求，只可能在一个worker进程中处理，一个worker进程，不可能处理其它进程的请求。worker进程的个数是可以设置的，一般我们会设置与机器cpu核数一致，这里面的原因与nginx的进程模型以及事件处理模型是分不开的。


# 一些需要注意的点
## alias 和 root指令的区别
```
/*
其后面跟的指定目录是准确的，并且末尾必须加"/", 否则404
*/
location /i/ {
    alias /spool/w3/images/;
}

// 请求 /i/top.gif的话会变成 /spool/w3/images/top.gif

/*
root后面指定的目录是上级目录，并且该上级目录必须含有location后指定的名称的同名目录,否则404
*/
location /test/ {
    root /var/www/;
}

// test/test1 会变成 /var/www/test1的目录
```
