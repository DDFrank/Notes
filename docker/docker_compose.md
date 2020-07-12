# 解决容器管理问题

- Docker Compose 可以理解为将多个容器运行的方式和配置固化下来
- 一般来说，是提供一个配置文件，将所有与应用系统相关的软件及它们对应的容器进行配置，之后使用 Docker Compose 提供的命令进行启动。

# 基本使用逻辑

- 如果需要的话，编写容器所需镜像的 Dockerfile；( 也可以使用现有的镜像 )
- 编写用于配置容器的 docker-compose.yml
- 使用 docker-compose 命令启动应用

## 编写 Docker Compose 配置

- 缺省文件名是 docker-compose.yml

```yaml
# Docker compose 配置的版本
version: '3'

# 核心配置， 每一项都是一个应用集群的配置
services:
  webapp:
    build: ./image/webapp
    ports:
      - "5000:5000"
    volumes:
      - ./code:/code
      - logvolume:/var/log
    links:
      - mysql
      - redis
  redis:
    image: redis:3.2
  mysql:
    image: mysql:5.7
    environment:
      - MYSQL_ROOT_PASSWORD=my-secret-pw
volumes:
  logvolume: {}
```

## 一些常用的 Docker compose 的配置项

### 定义服务

```yaml
version: "3"

# 服务
services:
	# 服务名
  redis:
  	# 直接给出镜像名称
    image: redis:3.2
    networks:
      - backend
    volumes:
      - ./redis/redis.conf:/etc/redis.conf:ro
    ports:
      - "6379:6379"
    command: ["redis-server", "/etc/redis.conf"]

  database:
    image: mysql:5.7
    networks:
      - backend
    volumes:
    # 相对目录是相对于 docker_compose.yaml 文件而言
      - ./mysql/my.cnf:/etc/mysql/my.cnf:ro
      - mysql-data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=my-secret-pw
    #端口映射
    ports:
      - "3306:3306"

  webapp:
    # 使用 docker build 来构建镜像
    build: ./webapp
    networks:
      - frontend:
      		# 可以声明容器的网络别名
	      	aliases:
          - backend.webapp
      - backend
    volumes:
      - ./webapp:/webapp
    # 对依赖进行声明
    depends_on:
      - redis
      - database

  nginx:
    image: nginx:1.12
    networks:
      - frontend
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./webapp/html:/webapp/html
    depends_on:
      - webapp
    ports:
      - "80:80"
      - "443:443"

# 声明网络
networks:
  frontend:
  backend:
# 独立于service 的配置就是用来声明数据卷
volumes:
  mysql-data:
  # 假如数据卷时外部的，那么可以如此声明
  # external: true
  
  
```



## 启动和停止

- `docker-compose up` 类似于 docker engine 的 `run` 命令，会解析配置文件并创建容器并启动

```shell
# 加上 -d 使其能够在后台运行
# -f 是配置文件的位置
# -p 选项定义项目名
docker-compose -f ./compose/docker-compose.yml -p myapp up -d
```

- `docker-compose down` 会停止所有的容器并将其删除

```shell
docker-compose down
```

## 容器命令

- 有许多可以直接操作服务的命令

```shell
# 打印设备中主进程的日志
docker-compose logs nginx
```

