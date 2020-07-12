- 第一次执行的时候一定要格式化文件系统，之后不要执行

```shell
hdfs namenode -format
```

- 启动 hdfs

```shell
$HADOOP_HOME/sbin/start-dfs.sh
```

- 验证是否启动

```shell
jps # 查看进程是否都启动了
5300 DataNode
5572 Jps
5454 SecondaryNameNode
5183 NameNode
# http://192.168.2.199:50070/ 查看是否能访问，假如不能，可以查看防火墙状态
```



### hadoop-daemons.sh 和 start-dfs.sh 的关系

start-dfs.sh = 

​	hadoop-daemons.sh start namenode

​    hadoop-daemons.sh start datanode

​	hadoop-daemons.sh start secondarynamenode



## HDFS 命令行操作

- fs

```shell
hadoop fs -ls /
```

- put

```shell
hadoop fs -put README.txt /
```

- cat, text

```shell
hadoop fs -cat /README.txt
```

- copyFromLocal

```shell
hadoop fs -copyFromLocal NOTICE.txt /
```

- moveFromLocal (移动，本地会没有)

```shell
hadoop fs -moveFromLocal test.txt /
```

- get
- mkdir
- mv

```shell
hadoop fs -mv /README.txt /hdfs-test/
```

- cp
- getmerge (获取后合并文件)
- rm
- rmdir





