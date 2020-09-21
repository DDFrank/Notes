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