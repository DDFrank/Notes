下文中会使用到的表
```sql
CREATE TABLE hero (
    number INT,
    name VARCHAR(100),
    country varchar(100),
    PRIMARY KEY (number)
) Engine=InnoDB CHARSET=utf8;
```
# 事务隔离级别
## 事务并发执行时会遇到的问题
- 脏写(`Dirty Write`)
如果`一个事务修改了另一个未提交事务修改过的数据`，那就意味着发生了`脏写`
比如:
`Session A`和`Session B`各开启了一个事务，`Session B`中的事务先将`number`列为`1`的记录的`name`列更新为`'关羽'`，然后`Session A`中的事务接着又把这条`number`列为`1`的记录的`name`列更新为`张飞`。如果之后`Session B`中的事务进行了回滚，那么`Session A`中的更新也将不复存在，这种现象就称之为`脏写`

- 脏读(`Dirty Read`)
如果`一个事务读到了另一个未提交事务修改过的数据`，那就意味着发生了`脏读`
`Session A`和`Session B`各开启了一个事务，`Session B`中的事务先将`number`列为`1`的记录的`name`列更新为`'关羽'`，然后`Session A`中的事务再去查询这条`number`为`1`的记录，如果读到列`name`的值为`'关羽'`，而`Session B`中的事务稍后进行了回滚，那么`Session A`中的事务相当于读到了一个不存在的数据，这种现象就称之为`脏读`

- 不可重复读（`Non-Repeatable Read`）
如果`一个事务只能读到另一个已经提交的事务修改过的数据，并且其他事务每对该数据进行一次修改并提交后，该事务都能查询得到最新值`，那就意味着发生了`不可重复读`
如果在`Session B`中提交了几个隐式事务，这些事务都修改了`number`列为`1`的记录的列`name`的值，每次事务提交之后，如果`Session A`中的事务都可以查看到最新的值，这种现象也被称之为`不可重复读`

- 幻读(`Phantom`)
 如果`一个事务先根据某些条件查询出一些记录，之后另一个事务又向表中插入了符合这些条件的记录，原先的事务再次按照该条件查询时，能把另一个事务插入的记录也读出来`，那就意味着发生了`幻读`

`Session A`中的事务先根据条件`number > 0`这个条件查询表`hero`，得到了`name`列值为`'刘备'`的记录；之后`Session B`中提交了一个隐式事务，该事务向表`hero`中插入了一条新记录；之后`Session A`中的事务再根据相同的条件`number > 0`查询表`hero`，得到的结果集中包含`Session B`中的事务新插入的那条记录，这种现象也被称之为`幻读`

## SQL标准中的四种隔离级别

| 隔离级别                      | 脏读         | 不可重复读   | 幻读         |
| ----------------------------- | ------------ | ------------ | ------------ |
| `READ UNCOMMITTED` (未提交读) | Possible     | Possible     | Possible     |
| `READ COMMITTED` (已提交读)   | Not Possible | Possible     | Possible     |
| `REPEATABLE READ` (可重复读)  | Not Possible | Not Possible | Possible     |
| `SERIALIZABLE` (可串行化)     | Not Possible | Not Possible | Not Possible |

## MySql中支持的四种隔离级别
不同的数据库厂商对`SQL标准`中规定的四种隔离级别支持不一样，比方说`Oracle`就只支持`READ COMMITTED`和`SERIALIZABLE`隔离级别。
MySQL虽然支持4种隔离级别，但与`SQL标准`中所规定的各级隔离级别允许发生的问题却有些出入，`MySQL在REPEATABLE READ隔离级别下，是可以禁止幻读问题的发生的`

MySQL的默认隔离级别为`REPEATABLE READ`

### 如何设置事务的隔离级别
可以通过下边的语句修改事务的隔离级别：
```sql
SET [GLOBAL|SESSION] TRANSACTION ISOLATION LEVEL level;
```

`level`的可选值有4个
```sql
level: {
     REPEATABLE READ
   | READ COMMITTED
   | READ UNCOMMITTED
   | SERIALIZABLE
}
```

- 使用`GLOBAL`关键字（在全局范围影响）:
    * 只对执行完该语句之后产生的会话起作用
    * 当前已经存在的会话无效
```sql
SET GLOBAL TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

- 使用`SESSION`关键字（在会话范围影响）：
    * 对当前会话的所有后续的事务有效
    * 该语句可以在已经开启的事务中间执行，但不会影响当前正在执行的事务。
    * 如果在事务之间执行，则对后续的事务有效
```sql
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

- 上述两个关键字都不用（只对执行语句后的下一个事务产生影响）：
    * 只对当前会话中下一个即将开启的事务有效
    * 下一个事务执行完后，后续事务将恢复到之前的隔离级别
    * 该语句不能在已经开启的事务中间执行，会报错的

### 查看当前会话默认的隔离级别
```sql
mysql> SHOW VARIABLES LIKE 'transaction_isolation';
+-----------------------+-----------------+
| Variable_name         | Value           |
+-----------------------+-----------------+
| transaction_isolation | REPEATABLE-READ |
+-----------------------+-----------------+
1 row in set (0.02 sec)

# 更简便的写法
mysql> SELECT @@transaction_isolation;
+-------------------------+
| @@transaction_isolation |
+-------------------------+
| REPEATABLE-READ         |
+-------------------------+
1 row in set (0.00 sec)
```

# MVCC 原理
## 版本链
对于使用`InnoDB`存储引擎的表来说，它的聚簇索引记录中都包含两个必要的隐藏列
- `trx_id`: 每次一个事务对某条聚簇索引记录进行改动时，都会把该事务的`事务id`赋值给`trx_id`隐藏列
- `roll_pointer`：每次对某条聚簇索引记录进行改动时，都会把旧的版本写入到`undo日志`中，然后这个隐藏列就相当于一个指针，可以通过它来找到该记录修改前的信息

对某条记录每次更新后，都会将旧值放到一条`undo`日志中，就算是该记录的一个旧版本，随着更新次数的增多，所有的版本都会被`roll_pointer`属性连接成一个链表。
这个链表称之为版本链，版本链的头节点就是当前记录最新的值。另外，每个版本中还包含生成该版本时对应的`事务id`

## ReadView
- 对于使用`READ UNCOMMITTED`隔离级别的事务来说，由于可以读到未提交事务修改过的记录，所以直接读取记录的最新版本就好了
- 对于使用`SERIALIZABLE`隔离级别的事务来说，`InnoDB`规定使用加锁的方式来访问记录
- 对于使用`READ COMMITTED`和`REPEATABLE READ`隔离级别的事务来说，都必须保证读到已经提交了的事务修改过的记录, 也就是事务未提交的时候，不能直接读取最新版本的记录，所以`需要判断一下版本链中的哪个版本是当前事务可见的`，这里就会用到`ReadView`
### ReadView 的内容
下面4个内容比较重要
- `m_ids`: 表示在生成`ReadView`时当前系统中活跃的读写事务的`事务id`列表
- `min_trx_id`: 表示在生成`ReadView`时当前系统中活跃的读写事务中最小的`事务id`，也就是`m_ids`中的最小值
- `max_trx_id`: 表示生成`ReadView`时系统中应该分配给下一个事务的`id`值
- `creator_trx_id`：表示生成该`ReadView`的事务的`事务id`

### 访问某条记录时，利用ReadView来判断记录的某个版本是否可见
- 如果被访问版本的`trx_id`属性值与`ReadView`中的`creator_trx_id`值相同，意味着当前事务在访问它自己修改过的记录，所以该版本可以被当前事务访问
- 如果被访问版本的`trx_id`属性值小于`ReadView`中的`min_trx_id`值，表明生成该版本的事务在当前事务生成`ReadView`前已经提交(因为已经不是活跃事务了)，所以该版本可以被当前事务访问
- 如果被访问版本的`trx_id`属性值大于或等于`ReadView`中的`max_trx_id`值，表明生成该版本的事务在当前事务生成`ReadView`后才开启，所以该版本不可以被当前事务访问
- 如果被访问版本的`trx_id`属性值在`ReadView`的`min_trx_id`和`max_trx_id`之间，那就需要判断一下`trx_id`属性值是不是在`m_ids`列表中，如果在，说明创建`ReadView`时生成该版本的事务还是活跃的，该版本不可以被访问；如果不在，说明创建`ReadView`时生成该版本的事务已经被提交，该版本可以被访问。

如果某个版本的数据对当前事务不可见的话，那就顺着版本链找到下一个版本的数据，继续按照上边的步骤判断可见性，依此类推，直到版本链中的最后一个版本。如果最后一个版本也不可见的话，那么就意味着该条记录对该事务完全不可见，查询结果就不包含该记录

### ReadView 的生成策略
`READ COMMITTED`和`REPEATABLE READ`隔离级别的的一个非常大的区别就是它们生成ReadView的时机不同

- 使用`READ COMMITTED`隔离级别的事务在每次查询开始时都会生成一个独立的ReadView

- 对于使用`REPEATABLE READ`隔离级别的事务来说，只会在第一次执行查询语句时生成一个`ReadView`，之后的查询就不会重复生成了

### MVCC
所谓的`MVCC`（Multi-Version Concurrency Control ，多版本并发控制）指的就是在使用`READ COMMITTD`、`REPEATABLE READ`这两种隔离级别的事务在执行普通的`SELECT`操作时访问记录的版本链的过程，这样子可以使不同事务的`读-写`、`写-读`操作`并发执行`，从而提升系统性能。`READ COMMITTD`、`REPEATABLE READ`这两个隔离级别的一个很大不同就是：生成`ReadView`的时机不同，`READ COMMITTD`在每一次进行普通`SELECT`操作前都会生成一个`ReadView`，而`REPEATABLE READ`只在第一次进行普通`SELECT`操作前生成一个`ReadView`，之后的查询操作都重复使用这个`ReadView`就好了


