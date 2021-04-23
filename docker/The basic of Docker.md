# Docker的核心组成

## 镜像 Image

- 所谓镜像，可以理解为一个只读的文件包，其中包含了**虚拟环境运行最原始文件系统的内容**。
- 每次对镜像内容的修改，Docker 都会将这些修改铸造成一个镜像层，而一个镜像其实就是由其下层所有的镜像层所组成的。当然，每一个镜像层单独拿出来，与它之下的镜像层都可以组成一个镜像。
- 另外，由于这种结构，Docker 的镜像实质上是无法被修改的，因为所有对镜像的修改只会产生新的镜像，而不是更新原有的镜像

## 容器 Container

- 用来隔离环境的基础设施
- 相当于是镜像的实例
- 包括以下三项内容
  - 一个 Docker 镜像
  - 一个程序运行环境
  - 一个指令集合

## 网络 Network

- 可以对每个容器的网络进行配置,还能在容器间建立虚拟网络，将数个容器包裹其中，同时与其它网络环境相隔离

## 数据卷 Volume

- 通过某些方式进行数据持久化或者数据共享的文件或目录，都称为数据卷



# Docker Engine



# 镜像 和 容器

## Docker 的镜像必须使用 Docker 来打包，也必须通过 Docker 来下载和打包

- 这使得在不同的环境中共享镜像变得方便

## Docker 的镜像层有一个唯一的 hash Id

- 64位长度的字符串，可以保证全球唯一性
- 因为每个镜像的 hash Id 和 对应的内容是一致的，所以可以在镜像之间共享镜像层
  - 比如 elasticsearch 层 和 jenkins 都可以依赖 openjdk 镜像层, 这样可以有效节约空间

## 查看镜像

```shell
docker images
```

## 镜像命名

- hash id 不容易识别, 通过 镜像名更容易识别镜像

### 命名的组成

```txt
cogest/lets-encrypt: 0.14.2
```

- **username**： 主要用于识别上传镜像的不同用户，与 GitHub 中的用户空间类似
  - 没有 username 的话表示是官方维护的
- **repository**：主要用于识别进行的内容，形成对镜像的表意描述
  - 通常使用软件名
- **tag**：主要用户表示镜像的版本，方便区分进行内容的不同细节
  - 识别的关键内容
  - 没有提供 tag 时 默认使用 latest



## 容器的生命周期

![docker state](imgs/docker-container-state.jpg)

- **Created**：容器已经被创建，容器所需的相关资源已经准备就绪，但容器中的程序还未处于运行状态
- **Running**：容器正在运行，也就是容器中的应用正在运行
- **Paused**：容器已暂停，表示容器中的所有程序都处于暂停 ( 不是停止 ) 状态
- **Stopped**：容器处于停止状态，占用的资源和沙盒环境都依然存在，只是容器中的应用程序均已停止
- **Deleted**：容器已删除，相关占用的资源及存储在 Docker 中的管理信息也都已释放和移除

### 主进程

容器的生命周期其实是与容器中 Pid 为 1 的进程紧密联系的

## 写时复制机制

- 通过镜像运行容器时，并不是马上就把镜像里的所有内容拷贝到容器所运行的沙盒文件系统中，而是利用 UnionFS 将镜像以只读的方式挂载到沙盒文件系统中。只有在容器中发生对文件的修改时，修改才会体现到沙盒环境上
- 容器在创建和启动的过程中，不需要进行任何的文件系统复制操作，也不需要为容器单独开辟大量的硬盘空间，与其他虚拟化方式对这个过程的操作进行对比，Docker 启动的速度可见一斑



## 从镜像仓库获取镜像

### 获取镜像

```shell
docker pull
```

- Docker 首先会拉取镜像所基于的所有镜像层
- 之后再单独拉取每一个镜像层并组合成这个镜像
- 当然，如果在本地已经存在相同的镜像层 ( 共享于其他的镜像 )，那么 Docker 就直接略过这个镜像层的拉取而直接采用本地的内容
- 拉取完之后，就可以使用 docker images 看到它了

### 搜索镜像

```shell
docker search
```

- 或者在 docker hub 上查询



### 管理镜像

```shell
docker images
```

- 假如想要查看镜像更详细的信息

```shell
docker inspect
```

- 删除镜像

```shell
docker rmi
```



## 容器的管理和运行

### 创建容器

```shell
docker create 镜像名 
```

- 此时 docker 会根据镜像创建容器
- 容器是 Created 状态
- 可以使用 --name 在创建时指定容器名

### 启动容器

```shell
docker start nginx
```

- 可以将 创建 和 运行容器命令合并在一起

```shell
# -d 是后台模式
docker run --name nginx -d nginx:1.12
```

### 管理容器

```shell
# 默认列出运行中的容器，使用 -a 列出全部容器
docker ps
```

### 停止和删除容器

```shell
docker stop nginx
```

- 完全删除容器

```shell
docker rm nginx
```

### 进入容器

```shell
# exec 可以进入容器来执行命令
docker exec nginx more /etc/hostname
```

```shell
# 进入容器并使用 bash
# it 参数不可少
docker exec -it nginx bash
# 退出时需要 ctrl + p + q
```



# 为容器配置网络

## 容器网络

### 沙盒

**沙盒**提供了容器的虚拟网络栈，也就是之前所提到的端口套接字、IP 路由表、防火墙等的内容。其实现隔离了容器网络与宿主机网络，形成了完全独立的容器网络环境

### 网络

**网络**可以理解为 Docker 内部的虚拟子网，网络内的参与者相互可见并能够进行通讯。Docker 的这种虚拟网络也是于宿主机网络存在隔离关系的，其目的主要是形成容器间的安全通讯环境

### 端点

**端点**是位于容器或网络隔离墙之上的洞，其主要目的是形成一个可以控制的突破封闭的网络环境的出入口。当容器的端点与网络的端点形成配对后，就如同在这两者之间搭建了桥梁，便能够进行数据传输了

## 容器互联

- 要让一个容器连接到另外一个容器，我们可以在容器通过 `docker create` 或 `docker run` 创建时通过 `--link` 选项进行配置

```shell
# 创建 mysql 的容器并运行
sudo docker run -d --name mysql -e MYSQL_RANDOM_ROOT_PASSWORD=yes mysql
# 将 webapp和 mysql 容器 连接起来(打通网络)
sudo docker run -d --name webapp --link mysql webapp:latest
```

- 之后就可以使用 容器名 来访问容器了

```java
// 可以直接访问 mysql
String url = "jdbc:mysql://mysql:3306/webapp";
```

- 只有容器自身允许的端口，才能被其它容器访问

  - 在 `docker ps ` 中可以看到容器暴露的端口
  - 暴露的端口可以通过镜像暴露，也可以在创建容器时暴露

  ```shell
  # --expose 暴露端口
  docker run -d --name mysql -e MYSQL_RANDOM_ROOT_PASSWORD=yes --expose 13306 --expose 23306 mysql:5.7
  ```

- 容器之间还允许通过别名进行连接s

```shell
# --link <name>:<alias>
docker run -d --name webapp --link mysql:database webapp:latest
```

这样就可以这样写配置文件

```java
// 使用了别名 database
String url = "jdbc:mysql://database:3306/webapp";
```



## 管理网络

- 容器能够连接的前提是两者同处于一个网络中
- 启动 docker 服务时，会默认创建一个 bridge 网络。而创建的容器在不指定网络的情况都会连接到该网络上，因此可以相互连接
- `docker inspect` 命令可以查看容器的网络部分

### 创建网络

```shell
# 可以创建自己的子网， -d 决定创建的网络驱动的类型
docker network create -d bridge individual
```

```shell
# 可以查看已经创建的网络
docker network ls
```

- 创建容器时，可以通过 `--network` 命令来指定需要加入的网络

```shell
docker run -d --name mysql -e MYSQL_RANDOM_ROOT_PASSWORD=yes --network individual mysql:5.7
```

### 端口映射

- 通过 Docker 端口映射功能，我们可以把容器的端口映射到宿主操作系统的端口上，当我们从外部访问宿主操作系统的端口时，数据请求就会自动发送给与之关联的容器端口

```shell
# -p <ip>:<host-port>:<container-port>
# ip : 宿主操作系统的监听 ip，可以用来控制监听的网卡，默认为 0.0.0.0，也就是监听所有网卡
# host-port : 宿主操作系统的端口
# container-port : 容器的端口
docker run -d --name nginx -p 80:80 -p 443:443 nginx:1.12
```

# 管理和存储数据

## 数据管理实现方式

- 由于 UnionFS 支持挂载不同类型的文件系统到统一的目录结构中，所以我们只需要将宿主操作系统中，文件系统里的文件或目录挂载到容器中，便能够让容器内外共享这个文件。
- 由于通过这种方式可以互通容器内外的文件，那么文件数据持久化和操作容器内文件的问题就自然而然的解决了
- UnionFS 带来的读写性能损失是可以忽略不计的

### 挂载方式

- **Bind Mount** 能够直接将宿主操作系统中的目录和文件挂载到容器内的文件系统中，通过指定容器外的路径和容器内的路径，就可以形成挂载映射关系，在容器内外对文件的读写，都是相互可见的
- **Volume** 也是从宿主操作系统中挂载目录到容器内，只不过这个挂载的目录由 Docker 进行管理，我们只需要指定容器内的目录，不需要关心具体挂载到了宿主操作系统中的哪里
- **Tmpfs Mount** 支持挂载系统内存中的一部分到容器的文件系统里，不过由于内存和容器的特征，它的存储并不是持久的，其中的内容会随着容器的停止而消失

## 挂载文件到容器

- 要将宿主操作系统中的目录挂载到容器之后，我们可以在容器创建的时候通过传递 `-v` 或 `--volume` 选项来指定内外挂载的对应目录或文件

```shell
#使用 -v 或 --volume 来挂载宿主操作系统目录的形式是 -v <host-path>:<container-path> 或 --volume <host-path>:<container-path>，其中 host-path 和 container-path 分别代表宿主操作系统中的目录和容器中的目录。这里需要注意的是，为了避免混淆，Docker 这里强制定义目录时必须使用绝对路径，不能使用相对路径
docker run -d --name nginx -v /webapp/html:/usr/share/nginx/html nginx:1.12
```

- 也可以使用 `docker inspect` 来查看挂载的详情
- 可以创建只读的挂载方式

```shell
# ro 表示 readonly
docker run -d --name nginx -v /webapp/html:/usr/share/nginx/html:ro nginx:1.12
```



## 挂载临时文件目录

- 挂载临时文件目录要通过 `--tmpfs` 这个选项来完成

```shell
docker run -d --name webapp --tmpfs /webapp/cache webapp:latest
```

- 可以通过 `docker inspect` 来查看挂载的临时目录



## 使用数据卷

- 用 `-v` 或 `--volume` 选项来定义数据卷的挂载。

```shell
# 注意这里并未指定 宿主的文件目录
docker run -d --name webapp -v /webapp/storage webapp:latest
# 可以通过 -v <name>:<container-path> 这种形式来命名数据卷
docker run -d --name webapp -v appdata:/webapp/storage webapp:latest
```

### 共用数据卷

```shell
docker run -d --name webapp -v html:/webapp/html webapp:latest
docker run -d --name nginx -v html:/usr/share/nginx/html:ro nginx:1.12
```

- 通过 `docker volume create` 我们可以不依赖于容器独立创建数据卷

```shell
docker volume create appdata
```

- 通过 `docker volume ls` 可以列出当前已创建的数据卷

### 删除数据卷

```shell
# 删除前需保证没有任何容器使用
docker volume rm appdata

# 删除容器时，可以使用 -v 让其一并删除数据卷
docker rm -v webapp
```

- `docker volume prune` 可以找出没有被容器引用的数据卷

### 数据卷容器

所谓数据卷容器，就是一个没有具体指定的应用，甚至不需要运行的容器，我们使用它的目的，是为了定义一个或多个数据卷并持有它们的引用

- 创建的时候，只需要简单找个系统镜像即可

```shell
docker create --name appdata -v /webapp/storage ubuntu
```

- 使用数据卷容器时，不建议再定义数据卷的名称，因为可以通过对数据卷容器的引用来完成数据卷的引用。避免和其它数据卷重名
- 引用数据卷时，使用 `--volumes-from`即可

```shell
docker run -d --name webapp --volumes-from appdata webapp:latest
```

### 备份和迁移数据卷

- 建立一个临时容器，对数据打包来进行备份

```shell
# --rm 表示容器停止后自动删除 
# 在命令后面添上一系列其它的命令，可以直接替换容器的主程序启动命令，这里就是一个打包指令
# 这里就是将 appdata 容器中的 /web/storage 下的内容打包到 /backup/backup.tar(数据卷)
docker run --rm --volumes-from appdata -v /backup:/backup ubuntu tar cvf /backup/backup.tar /webapp/storage
```

- 也可以借助临时容器来恢复数据

```shell
docker run --rm --volumes-from appdata -v /backup:/backup ubuntu tar xvf /backup/backup.tar -C /webapp/storage --strip
```

### 另一个挂载选项

- 可以使用 `--mount` 来挂载, 其中逗号分隔来指定各种参数

```shell
# type 指定各种挂载方式, 不指定的话默认为 volume 类型
docker run -d --name webapp webapp:latest --mount 'type=volume,src=appdata,dst=/webapp/storage,volume-driver=local,volume-opt=type=nfs,volume-opt=device=<nfs-server>:<nfs-path>' webapp:latest
```



# 保存和共享镜像

## 提交容器更改

- docker 可以将某个容器持久化为一个镜像文件

```shell
# 提交后可以在镜像列表中看到它
docker commit webapp -m "first commit"
```

## 为镜像命名

- 可以给镜像命名，或者赋予新的名字

```shell
docker tag 0bc42f7ff218 webapp:1.0
```

- 也可以在 commit 的时候直接给镜像命名

```shell
docker commit -m "Upgrade" webapp webapp：2.0
```

## 镜像的迁移

### 导出镜像

- 使用 `docker save` 命令将镜像内容放入输入流中，这样就可以使用管道来接收了

```shell
docker save webapp:1.0 > webapp-1.0.tar
```

- 或者直接使用 `-o` 选项

```shell
docker save -o ./webapp-1.0.tar webapp:1.0
```

- 可以批量将多个镜像导出为文件

```shell
docker save -o ./images.tar webapp:1.0 nginx:1.12 mysql:5.7
```



### 导入镜像

- 可以将导出的镜像文件导入到本机的 docker 中

```shell
docker load < webapp-1.0.tar
```

- 也可以使用 `-i` 选项

```shell
docker load -i webapp-1.0.tar
```



### 导出和导入容器

- 使用 `docker export` 可以直接导出容器，类似于 commit 后 save

```shell
docker export -o ./webapp.tar webapp
```

- 可以使用 `docker import` 导入导出的容器

```shell
# 这里导入的是一个镜像，而不是容器
docker import ./webapp.tar webapp:1.0
```



# 使用 Dockerfile 创建镜像

Dockerfile 是定义镜像文件自动化构建流程的配置文件

## Dockerfile 的结构

- Dockerfile 就是一个从下往下执行的脚本文件

### 指令的简单分类

- **基础指令**：用于定义新镜像的基础和性质。
- **控制指令**：是指导镜像构建的核心部分，用于描述镜像在构建过程中需要执行的命令。
- **引入指令**：用于将外部文件直接引入到构建镜像内部。
- **执行指令**：能够为基于镜像所创建的容器，指定在启动时需要执行的脚本或命令。
- **配置指令**：对镜像以及基于镜像所创建的容器，可以通过配置指令对其网络、用户等内容进行配置。

## Dockerfile 的常用指令

### FROM

- 可以通过该指令指定一个镜像，接下来所有的指令都是指定该镜像的
- 有三种格式

```dockerfile
FROM <image> [AS <name>]
FROM <image>[:<tag>] [AS <name>]
FROM <image>[@<digest>] [AS <name>]
```

- 当FROM出现两次时，需要将当前的镜像合并到第二次FROM的镜像中去

### RUN

- 用于发出需要向控制台发出的指令

```dockerfile
RUN <command>
RUN ["executable", "param1", "param2"]
```

- 假如一行写不下，可以使用 `\` 来换行

### ENTRYPOINT 和 CMD

- 通过这两个指令可以定义启动容器中 pid 为1 的程序的启动

```dockerfile
ENTRYPOINT ["executable", "param1", "param2"]
ENTRYPOINT command param1 param2

CMD ["executable","param1","param2"]
CMD ["param1","param2"]
CMD command param1 param2
```

- 当 当 ENTRYPOINT 与 CMD 同时给出时，CMD 中的内容会作为 ENTRYPOINT 定义命令的参数，最终执行容器启动的还是 ENTRYPOINT 中给出的命令

### EXPOSE

- 为镜像指定需要暴露的端口

```dockerfile
EXPOSE <port> [<port>/<protocol>...]
```

### VOLUME

- 提供了 VOLUME 指令来定义基于此镜像的容器所自动建立的数据卷

```dockerfile
VOLUME ["/data"]
```

### COPY和ADD

- 在制作新的镜像的时候，我们可能需要将一些软件配置、程序代码、执行脚本等直接导入到镜像内的文件系统里，使用 COPY 或 ADD 指令能够帮助我们直接从宿主机的文件系统里拷贝内容到镜像里的文件系统中

```dockerfile
COPY [--chown=<user>:<group>] <src>... <dest>
ADD [--chown=<user>:<group>] <src>... <dest>

COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]
ADD [--chown=<user>:<group>] ["<src>",... "<dest>"]
```

- ADD 能够支持使用网络端的 URL 地址作为 src 源，并且在源文件被识别为压缩包时，自动进行解压，而 COPY 没有这两个能力

## 构建镜像

- 构建镜像的指令为 `docker build`

```shell
# 参数的这个目录会作为 构建的基础路径
docker build ./webapp
```

- 可以使用 `-f` 指定 Dockerfile 的位置
- 也可以使用 `-t` 参数指明新生成的镜像的名称

```
docker build -t webapp:latest -f ./webapp/a.Dockerfile ./webapp
```



## Dockerfile 使用技巧

### 构建中使用变量

- 可以通过 ARG 指令定一个变量, 然后在 build 时传入参数

```dockerfile
FROM debian:stretch-slim

## ......

ARG TOMCAT_MAJOR
ARG TOMCAT_VERSION

## 接下来的命令就可以使用变量了

RUN wget -O tomcat.tar.gz "https://www.apache.org/dyn/closer.cgi?action=download&filename=tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"
```

- 然后 build 的时候传入参数

```shell
# 传入参数
docker build --build-arg TOMCAT_MAJOR=8 --build-arg TOMCAT_VERSION=8.0.53 -t tomcat:8.0 ./tomcat
```

### 环境变量

- 通过 ENV 指令可以设置此容器的环境变量

```dockerfile
FROM debian:stretch-slim

## ......

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.0.53

## ......

RUN wget -O tomcat.tar.gz "https://www.apache.org/dyn/closer.cgi?action=download&filename=tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"
```

- 在创建容器时使用 `-e` 或是 `--env `，可以对环境变量的值进行修改
- ENV 指令设置的变量的优先级高于 ARG 指令定义的变量

### 合并命令

- 将指令尽可能的聚合起来，有利于减少镜像层的数量，减少启动容器的次数，提高了镜像构建的速度

### 构建缓存

- 由于镜像是多个指令所创建的镜像层组合而得，那么如果判断出新编译的镜像层与已经存在的镜像层未发生变化，那么完全可以直接利用之前构建的结果，而不需要再执行这条构建指令
- 不容易发生变化的搭建过程放到 Dockerfile 的前部的话,可以充分利用构建缓存提高镜像构建的速度
- 假如不希望开启缓存，可以使用 `--no-cache`参数

```shell
docker build --no-cache ./webapp
```

## 搭配 ENTRYPOINT 和 CMD

- ENTRYPOINT 指令主要用于对容器进行一些初始化
- CMD 指令则用于真正定义容器中主程序的启动命令
- CMD 的命令会作为 ENTRYPOINT 的参数传入，然后很多 ENTRYPOINT 脚本最后一句就是 `exec "$@"` 也就是直接指向 CMD 定义命令



