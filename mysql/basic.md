## 一条查询语句的执行

```flow
client=>start: 客户端
connect=>operation: 连接器(管理连接，权限验证)
cache=>condition: 查询缓存(是否命中?)
replay=>operation: 直接返回客户端
resolver=>operation: 分析器（词法和语法分析）
optimization=>operation: 优化器（执行计划生成，选择索引）
executor=>operation: 执行器（操作引擎，返回结果）
persist=>end: 存储引擎（存储数据，提供读写接口）

client->connect->cache
cache(yes)->replay(right)
cache(no)->resolver->optimization->executor->persist

```

### 连接器
- 连接器负责跟客户端建立连接、获取权限、维持和管理连接
- 连接成功后，连接器会到权限表中查询用户的权限，之后就一直使用该权限数据（所以权限的修改对于已经连接的连接不会有影响）
- 连接时间过长会被服务端断开连接，此时需要重新连接
- 长时间占用连接的话，连接上的资源得不到清理，也有可能会造成内存消耗过多
- 5.7以上版本的话，可以使用 mysql_reset_connection 来恢复到刚连接成功的状态 （C API 函数）

### 查询缓存
- 对于更新很频繁的表来说，建议不要开启
- 8.0 已经默认关闭，需要手动开启

### 分析器
词法和语法分析

### 优化器
确定执行方案和选择索引

### 执行器
- 执行前检查权限
- 执行语句，获取结果


## 一条更新语句的执行
基本流程和查询语句的过程差不多，不过更新的时候会清空表的查询缓存

### redo log
- Innodb 引擎特有的日志系统
- 在执行更新操作时，会先把数据写道 redo log 上，并更新内存。此时就算更新完成了
- 之后在适当的时机将 redo log 上的内容写到磁盘上
- 假如 redo log 已经满了，那么此时就需要暂停更新操作，先将一部分的 redo log 写入磁盘

### binlog
- 和 redo log 的三点区别
	* redo log 是 Innodb 引擎独有的，binlog 是 server 层的，所有引擎都可以使用
	* redo log 是物理日志，记录的是 某个数据页上做了什么修改, binlog 是逻辑日志，记录的是语句的原始逻辑，比如"给ID=2的这一行的c字段加1"
	* redo log 是循环写的，空间固定会用完; binlog 是可以追加写入的，也就是不会覆盖

- 更新语句的流程

```flow
st=>start: 取id=2这一行
cache=>condition: 数据页是否在内存中
read=>operation: 磁盘中读取内存
replay=>operation: 返回行数据
update=>operation: 将数据+1
write=>operation: 写入新行
updateMemory=>operation: 新行更新到内存
prepareRedoLog=>operation: 写redo log,处于 prepare 阶段
writreBinlog=>operation: 写binlog
end=>end: 提交事务，处于commit状态

st->cache
cache(yes)->replay
cache(no)->read->replay->update->write->updateMemory->prepareRedoLog->writreBinlog->end
```
- 更新时的两阶段提交是为了保证 redo log 和 binlog 保持一致，避免备份的时候出现异常
- innodb_flush_log_at_trx_commit 设置为1 的时候，可以保证每次事务的 redo log 都直接持久化到磁盘
- sync_binlog 设置为1的时候，可以保证每次事务的 binlog 都直接持久化到磁盘


## 事务隔离级别
- read uncommited: 一个事务尚未被提交，它的变更就能被其它事务看到 
- read commited: 一个事务提交后，它的变更才能被其它事务看到
- repeatable read: 一个事务执行过程中看到的数据，总是跟它启动事务时看到的一样
- serializable: 读加读锁，写加写锁，当出现读写锁冲突时，后面的事务必须等待前面的事务完成

### 实现
- read uncommited: 直接读取最新的记录
- read commited: 每个sql执行的时候启动一个视图，sql执行时从视图读取数据
- repeatable read: 每个事务开启的时候启动一个视图，数据以从视图得到的结果为准
- serializable：直接加锁