# 事务简介
## 事务的特性
### 原子性(Atomicity)
一系列的操作，要么全部成功，要么全部失败

### 隔离性(lsolation)
对于某些操作，不仅要保证这些操作以`原子性`的方式执行完成，而且要保证其它的状态转换不会影响到本次状态转换

### 一致性(Consistency)
数据库中的数据全部符合现实世界中的约束
能从一个正确的状态，转移到另一个正确的状态

### 持久性
当现实世界的一个状态转换完成后，这个变换的结果将永久保留
即，该转换对应的数据库操作所修改的数据都应该在磁盘上保留下来

## 事务的概念
需要保证 `原子性`, `隔离性`,`一致性·`和`持久性`的一个或多个数据库操作称之为一个`事务`(`transaction`)

### 事务的状态
- 活动的（active）
事务对应的数据库操作正在执行过程中时，我们就说该事务处在活动的状态。
- 部分提交的（partially committed）
当事务中的最后一个操作执行完成，但由于操作都在内存中执行，所造成的影响并没有刷新到磁盘时，我们就说该事务处在部分提交的状态
- 失败的（failed）
当事务处在活动的或者部分提交的状态时，可能遇到了某些错误（数据库自身的错误、操作系统错误或者直接断电等）而无法继续执行，或者人为的停止当前事务的执行，我们就说该事务处在失败的状态
- 中止的（aborted）
如果事务执行了半截而变为失败的状态，那么就需要撤销失败事务对当前数据库造成的影响，即`回滚`,那么事务就处于`中止的`状态
- 提交的（committed）
当一个处在部分提交的状态的事务将修改过的数据都同步到磁盘上之后，我们就可以说该事务处在了提交的状态。

## 事务的语法
### 开启事务
有下面两种方式开启事务:
#### `BEGIN [WORK];`
```sql
mysql> BEGIN;
Query OK, 0 rows affected (0.00 sec)

mysql> 加入事务的语句...
```

#### `START TRANSACTION;`
```sql
mysql> START TRANSACTION;
Query OK, 0 rows affected (0.00 sec)

mysql> 加入事务的语句...
```

`START TRANSACTION` 语句后面可以跟随几个`修饰符`:
- `READ ONLY`: 标识当前事务是一个只读事务，也就是属于该事务的数据库操作只能读取数据，而不能修改数据
PS: 其实只读事务中只是不允许修改那些其他事务也能访问到的表中的数据，对于临时表来说（我们使用`CREATE TMEPORARY TABLE`创建的表），由于它们只能在当前会话中可见，所以只读事务其实也是可以对临时表进行增、删、改操作的

- `READ WRITE`: 标识当前事务是一个读写事务，也就是属于该事务的数据库操作既可以读取数据，也可以修改数据

- `WITH CONSISTENT SNAPSHOT`: 启动一致性读(TODO, 后面补完)

假如不显式地指定事务的`访问模式`, 默认是`读写`的
### 提交事务
`COMMIT [WORK]`
```sql
ysql> BEGIN;
Query OK, 0 rows affected (0.00 sec)

mysql> UPDATE account SET balance = balance - 10 WHERE id = 1;
Query OK, 1 row affected (0.02 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> UPDATE account SET balance = balance + 10 WHERE id = 2;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> COMMIT;
Query OK, 0 rows affected (0.00 sec)
```

### 手动中止事务
如果写了几条语句之后发现上边的某条语句写错了，可以手动中止事务
`ROLLBACK [WORK]`

```sql
mysql> BEGIN;
Query OK, 0 rows affected (0.00 sec)

mysql> UPDATE account SET balance = balance - 10 WHERE id = 1;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> UPDATE account SET balance = balance + 1 WHERE id = 2;
Query OK, 1 row affected (0.00 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> ROLLBACK;
Query OK, 0 rows affected (0.00 sec)
```

如果事务在执行过程中遇到了某些错误而无法继续执行的话，事务自身会自动的回滚

## 支持事务的存储引擎
`MySQL`目前只有`InnoDB`和`NDB`存储引擎支持

## 自动提交
`MySQL`有一个系统变量`autocommit`
```sql
mysql> SHOW VARIABLES LIKE 'autocommit';
+---------------+-------+
| Variable_name | Value |
+---------------+-------+
| autocommit    | ON    |
+---------------+-------+
1 row in set (0.01 sec)
```
默认值为ON，也就是说默认情况下，如果我们不显式的使用`START TRANSACTION`或者`BEGIN`语句开启一个事务，那么每一条语句都算是一个独立的事务，这种特性称之为事务的`自动提交`(每一条语句执行完之后就commit)

如果想关闭`自动提交`的功能
- 显式的的使用`START TRANSACTION`或者`BEGIN`语句开启一个事务
- 把系统变量`autocommit`的值设置为`OFF`
这样的话，我们写入的多条语句就算是属于同一个事务了，直到我们显式的写出`COMMIT`语句来把这个事务提交掉，或者显式的写出`ROLLBACK`语句来把这个事务回滚掉

## 隐式提交
某些特殊的语句会导致事务被提交
- 定义或修改数据库对象的数据定义语言（Data definition language，缩写为：`DDL`）
所谓的数据库对象，指的就是`数据库、表、视图、存储过程`等等这些东西。当我们使用`CREATE、ALTER、DROP`等语句去修改这些所谓的数据库对象时，就会隐式的提交前边语句所属于的事务
```sql
BEGIN;

SELECT ... # 事务中的一条语句
UPDATE ... # 事务中的一条语句
... # 事务中的其它语句

CREATE TABLE ... # 此语句会隐式的提交前边语句所属于的事务
```
- 隐式使用或修改`mysql`数据库中的表
当我们使用`ALTER USER、CREATE USER、DROP USER、GRANT、RENAME USER、REVOKE、SET PASSWORD`等语句时也会隐式的提交前边语句所属于的事务

- 事务控制或关于锁定的语句
当我们在一个事务还没提交或者回滚时就又使用`START TRANSACTION`或者`BEGIN`语句开启了另一个事务时，会隐式的提交上一个事务
```sql
BEGIN;

SELECT ... # 事务中的一条语句
UPDATE ... # 事务中的一条语句
... # 事务中的其它语句

BEGIN; # 此语句会隐式的提交前边语句所属于的事务
```
或者当前的`autocommit`系统变量的值为`OFF`，我们手动把它调为`ON`时，也会隐式的提交前边语句所属的事务。

或者使用`LOCK TABLES`、`UNLOCK TABLES`等关于锁定的语句也会隐式的提交前边语句所属的事务

- 加载数据的语句
比如我们使用`LOAD DATA`语句来批量往数据库中导入数据时，也会隐式的提交前边语句所属的事务

- 关于`MySQL`复制的一些语句
使用`START SLAVE、STOP SLAVE、RESET SLAVE、CHANGE MASTER TO`等语句时也会隐式的提交前边语句所属的事务

- 其它语句
使用`ANALYZE TABLE、CACHE INDEX、CHECK TABLE、FLUSH、 LOAD INDEX INTO CACHE、OPTIMIZE TABLE、REPAIR TABLE、RESET`等语句也会隐式的提交前边语句所属的事务

## 保存点
可以在事务对应的数据库语句中打几个点,在调用`ROLLBACK`语句时可以指定会滚到哪个点，而不是最初的原点
```
SAVEPOINT 保存点名称;
```
当我们想回滚到某个保存点时，可以使用下边这个语句（下边语句中的单词`WORK`和`SAVEPOINT`是可有可无的）：
```
ROLLBACK [WORK] TO [SAVEPOINT] 保存点名称;
```
如果我们想删除某个保存点，可以使用这个语句：
```
RELEASE SAVEPOINT 保存点名称;
```