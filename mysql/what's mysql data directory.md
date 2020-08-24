# MySql数据目录
MySql Server 启动时会到文件系统下的某个目录下加载一些文件，之后在运行过程中产生的数据也都会存储到这个目录下的某些文件中，这便是`数据目录`。

### 如何确定数据目录
由某个系统变量确定系统 `datadir`
```shell
SHOW VARIABLES LIKE `datadir`
```

TODO 不是很重要的样子，待补完