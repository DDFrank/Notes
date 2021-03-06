# 什么是成本
一条查询语句的成本由下边两个方面组成
- `I/O` 成本
    经常使用的 `InnoDB`存储引擎都是将数据和索引存储到磁盘上的，所以需要查询表中的记录时，需要先把数据或索引加载到内存中然后再操作。这个过程损耗的时间称之为`I/O`成本
- `CPU`成本
    读取以及检测记录是否满足对应的搜索条件，对结果集进行排序等这些操作损耗的时间称之为`CPU`成本

对于 `InnoDB` 存储引擎来说，页是磁盘和内存之间交互的基本单位
- 规定读取一个页面花费的成本默认是 `1.0`
- 读取以及检测一条记录是否符合搜索条件的成本默认是 `0.2`
- 还有别的成本常数，这2个比较常用


# 单表查询的成本
以下内容会使用到该表
```sql
CREATE TABLE single_table (
    id INT NOT NULL AUTO_INCREMENT,
    key1 VARCHAR(100),
    key2 INT,
    key3 VARCHAR(100),
    key_part1 VARCHAR(100),
    key_part2 VARCHAR(100),
    key_part3 VARCHAR(100),
    common_field VARCHAR(100),
    PRIMARY KEY (id),
    KEY idx_key1 (key1),
    UNIQUE KEY idx_key2 (key2),
    KEY idx_key3 (key3),
    KEY idx_key_part(key_part1, key_part2, key_part3)
) Engine=InnoDB CHARSET=utf8;
```

## 基于成本的优化步骤

在一条查询语句真正执行之前， `MySQL` 的查询优化器会找出执行该语句所有可能使用的方案，对比之后找出成本最低的方案，即 `执行计划`:
1. 根据搜索条件，找出所有可能使用的索引
2. 计算全表扫描的代价
3. 计算使用不同索引执行查询的代价
4. 对比各种执行方案的代价，找出成本最低的那个

基于实例进行分析

```sql
SELECT * FROM single_table WHERE 
    key1 IN ('a', 'b', 'c') AND 
    key2 > 10 AND key2 < 1000 AND 
    key3 > key2 AND 
    key_part1 LIKE '%hello%' AND
    common_field = '123';
```

1. 根据搜索条件，找到全部的索引
    - `key1 IN ('a', 'b', 'c')` 可以使用二级索引 (idx_key1)
    - `key2 > 10 AND key2 < 1000` 可以使用二级索引 (idx_key2)
    - `key3 > key2` 不能使用索引
    - `key_part1 LIKE '%hello%'`，是通配符开头和结尾的模糊匹配，不能使用索引
    - `common_field` 上没有索引

2. 计算全表扫描的代价
对于 `InnoDB` 存储引擎来说，全表扫描就是把聚簇索引中的记录都依次和给定的搜索条件做一下比较，把符合搜索条件的就加入到结果集。
所以需要将聚簇索引对应的页面加载到内存
所以 查询成本 = `I/O` 成本 + `CPU` 成本，所以为了计算成本，需要知道:
- 聚簇索引占用的页面数
- 该表中的记录数

可以使用 `SHOW TABLE STATUS` 语句来查看表的统计信息

```shell
mysql> SHOW TABLE STATUS LIKE 'single_table'\G
*************************** 1. row ***************************
           Name: single_table
         Engine: InnoDB
        Version: 10
     Row_format: Dynamic
           Rows: 9693
 Avg_row_length: 163
    Data_length: 1589248
Max_data_length: 0
   Index_length: 2752512
      Data_free: 4194304
 Auto_increment: 10001
    Create_time: 2018-12-10 13:37:23
    Update_time: 2018-12-10 13:38:03
     Check_time: NULL
      Collation: utf8_general_ci
       Checksum: NULL
 Create_options:
        Comment:
1 row in set (0.01 sec)
```

- Rows
表示表中的记录数
对于 `MyISAM` 存储引擎来说，该值是准确的。
对于`InnoDB` 存储引擎来说，该值是一个估计值

- `Data_length`
表示占用的存储空间字节数
使用 `MyISAM` 存储引擎来说，该值就是数据文件的大小
使用 `InnoDB` 存储引擎来说，该值就相当于聚簇索引占用的存储空间大小，所以可以这样计算
```
Data_length = 聚簇索引的页面数量 * 每个页面的大小
```
根据上面的公式可以反推出聚簇索引页面的数量

```
聚簇索引的页面数量 = 1589248 / 16 / 1024 = 97
```
所以，大概计算成本是
```
// I/O成本, 1.1 是微调值
97 x 1.0 + 1.1 = 98.1

// CPU成本, 1.0 是微调值
9693 x 0.2 + 1.0 = 1939.6

// 总成本
98.1 + 1939.6 = 2037.7
```

3. 计算使用不同的索引执行查询的代价
- 查询可能使用到 `idx_key1` 和 `idx_key2` 这两个索引，所以需要分析单独使用这些索引执行查询的成本。
- 先分析单独使用这些索引执行查询的成本，最后还要分析是否可能使用到索引合并
- `MySQL` 查询优化器先分析使用唯一二级索引的成本，再分析使用普通索引的成本

#### 使用 idx_key2 执行查询的成本分析
`idx_key2` 对应的搜索条件是 `key2 > 10 AND key2 < 1000`, 那么范围区间就是 (10, 1000), 所以:
- 先分别定位到 `key2 = 10 ` 和 `key2 = 1000` 的索引记录，找到主键值的集合
- 回表查询用户记录

对于 `二级索引 + 回表` 方式的查询，计算成本就依赖于两个方面的数据:
- 范围区间数量
查询优化器认为读取一个范围区间的`I/O`成本和读取一个页面是相同的。
所以本次查询访问的范围区间的二级索引的代价就是 1.0

- 需要回表的记录
  - 先根据 `key2 > 10` 这个条件访问一下 `idx_key2` 对应的 `B+`树索引，找到满足 `key2 > 10`这个条件的第一条记录，这个是`区间最左记录`, 这个是常数级，损耗不计
  - 根据 `key2 < 1000` 这个条件从 `idx_key2` 的索引中找出最后一条满足条件的记录,称为`区间最后记录`, 性能同上
  - 如果 `区间最左记录` 和 `区间最后记录` 相隔不太远，(MySql 5.7.21 里，是 10 个页面)，那么就可以精确统计出满足 条件的二级索引记录条数，否则只沿着 `区间最左记录` 向右读10个页面，计算平均页面有多少记录，然后用该平均值 乘以 `区间最左，最右记录`之间的页面数量即可
    - 每一条 `目录项记录` 都对应一个`数据页`，所以只要计算 `区间最左记录` 和 `区间最右记录` 的目录项隔着多少记录即可代表有多少页面

所以需要回表的记录的CPU成本是:
```
// 隔着95个页面
95 x 0.2 + 0.01 = 19.01
```

通过二级索引获取到记录之后，还有2步:
- 根据这些记录里的主键值到聚簇索引中做回表操作
`MySql` 里认为每次回表操作都相当于访问一个页面，也就是说二级索引范围区间范围内有多少记录，都需要多少次回表操作, 所以回表的 `I/O`成本就是:
```
95 x 1.0 = 95.0
```

- 回表操作得到的完整用户记录，然后再检测其它搜索条件是否成立
这个就是检测成本，所以 `CPU` 成本是
```
95 x 0.2 = 19.0
```

所以总的成本是:
```
// io成本
1.0 + 95 x 1.0 = 96.0 (范围区间的数量 + 预估的二级索引记录条数)

// cpu成本
95 x 0.2 + 0.01 + 95 x 0.2 = 38.01 （读取二级索引记录的成本 + 读取并检测回表后聚簇索引记录的成本）

// 总成本
96.0 + 38.01 = 134.01
```

#### 使用 idx_key1 执行查询的成本分析
`idx_key1` 对应的搜索条件是 `key1 IN ('a', 'b', 'c')`, 也就是相当于3个单点区间

与上文的分析类似, 总成本是 
```
121.0 + 47.21 = 168.21
```

#### 是否有可能使用索引
上例中 `idx_key1` 和 `idex_key2` 都是范围查询，所以查询到的二级索引记录不一定是主键排序的，不能使用索引合并

4. 对比各种执行方案的代价，找出成本最低的一个

- 全表扫描: 2037.7
- 使用 `idx_key2` 的成本: 134.01
- 使用 `idex_key1` 的成本: 168.21


## 基于索引统计数据的成本计算
有时候使用索引执行查询时会有许多单点区间, 比如使用 `IN` 语句的时候很容易产生非常多的单点区间
```sql
SELECT * FROM single_table WHERE key1 IN ('aa1', 'aa2', 'aa3', ... , 'zzz');
```
需要通过 `index dive` (直接访问索引对应的 `B+`树来计算某个范围区间对应的索引记录条数的方式) 的方式来计算出单点区间的记录数

但是假如 需要 `index dive` 的操作次数太多了，那么性能损耗就很可怕

`MySql` 中使用系统变量 `eq_range_index_dive_limt` 来限制这个最大数量

```shell
mysql> SHOW VARIABLES LIKE '%dive%';
+---------------------------+-------+
| Variable_name             | Value |
+---------------------------+-------+
| eq_range_index_dive_limit | 200   |
+---------------------------+-------+
1 row in set (0.08 sec)
```
所以，如果 超过 200 次的话那么就不使用 `index dive` 了，而是使用所谓的统计数据来估算

### 使用统计数据估算
`MySql` 会为每个索引维护一份统计数据

```shell
mysql> SHOW INDEX FROM single_table;
+--------------+------------+--------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| Table        | Non_unique | Key_name     | Seq_in_index | Column_name | Collation | Cardinality | Sub_part | Packed | Null | Index_type | Comment | Index_comment |
+--------------+------------+--------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
| single_table |          0 | PRIMARY      |            1 | id          | A         |       9693  |     NULL | NULL   |      | BTREE      |         |               |
| single_table |          0 | idx_key2     |            1 | key2        | A         |       9693  |     NULL | NULL   | YES  | BTREE      |         |               |
| single_table |          1 | idx_key1     |            1 | key1        | A         |        968 |     NULL | NULL   | YES  | BTREE      |         |               |
| single_table |          1 | idx_key3     |            1 | key3        | A         |        799 |     NULL | NULL   | YES  | BTREE      |         |               |
| single_table |          1 | idx_key_part |            1 | key_part1   | A         |        9673 |     NULL | NULL   | YES  | BTREE      |         |               |
| single_table |          1 | idx_key_part |            2 | key_part2   | A         |        9999 |     NULL | NULL   | YES  | BTREE      |         |               |
| single_table |          1 | idx_key_part |            3 | key_part3   | A         |       10000 |     NULL | NULL   | YES  | BTREE      |         |               |
+--------------+------------+--------------+--------------+-------------+-----------+-------------+----------+--------+------+------------+---------+---------------+
7 rows in set (0.01 sec)
```



| 属性名          | 描述                                                         |
| --------------- | ------------------------------------------------------------ |
| `Table`         | 索引所属表的名称                                             |
| `Non_unique`    | 索引列的值是否是唯一的，聚簇索引和唯一二级索引的该列值为`0`, 普通二级索引该列值为 `1` |
| `Key_name`      | 索引的名称                                                   |
| `Seq_in_index`  | 索引列在索引中的位置，从1开始计数                            |
| `Column_name`   | 索引列的名称                                                 |
| `Collation`     | 排序方式，值为`A`表示升序，`NULL`表示降序存放                |
| `Cardinality`   | 索隐裂中不重复值的数量，后面会重点看该属性                   |
| `Sub_part`      | 对于存储字符串或者字节串的列来说，有时只想对这些串前`n`个字符或字节建立索引，那这个属性就是`n`的值，如果是完整的列的话，就是`NULL` |
| Packed          | 索引是如何被压缩的,`NULL`表示未被压缩                        |
| `NULL`          | 该索引列是否允许存储`NULL`值                                 |
| `Index_type`    | 使用索引的类型，最常见的就是 `BTREE` ,也就是 `B+`树索引      |
| `Comment`       | 索引列注释信息                                               |
| `Index_comment` | 索引注释信息                                                 |
|                 |                                                              |

`Cardinality` 表示基数的值，如果为1的话，就表示没有重复的

对于 `InnoDB`来说，该值是一个估算值，并不精确
所以，当 `index_dive` 不适用的时候，会使用这2个统计数据
- 使用 `SHOW TABLES STATUS` 的 `Rows` 值，即一个表中有多少记录
- 使用 `SHOW INDEX` 语句展示出的 `Cardinality` 属性

结合这2个数据，可以计算出该索引列，平均一个值重复多少次
```
// 一个值的重复次数 ≈ Rows ÷ Cardinality
9693 ÷ 968 ≈ 10（条）
```

假设 `IN` 语句中有 20000个参数的话，那么大概需要回表的记录是
```
2000 * 10 = 200000
```

使用统计数据来计算的方式比较简单，但是很不精确

# 连接查询的成本
准备一个跟 `single_table` 一样的表，称为 `s2`，原来的表就是 `s1`

## Condition filtering
因为连接查询采用的是嵌套循环连接算法，驱动表会被访问一次，被驱动表可能会被访问多次，所以对于两表连接查询来说，查询成本由下边两个部分组成:
- 单词查询驱动表的成本
- 多次查询驱动表的成本(取决于对驱动表查询的结果集中有多少条记录)

对驱动表进行查询后得到的记录条数称之为驱动表的 `扇出(fanout)`,显然驱动表的扇出值越小，查询成本越低。

### 扇出的计算
- 比较容易判定的查询

```sql
// s1 作为驱动表，这里只能全表扫描，所以就是s1有多少记录就要扇出多少
SELECT * FROM single_table AS s1 INNER JOIN single_table2 AS s2;
```

```sql
// s1 是驱动表，那么可以使用 `idx_key2` 索引进行查询，那么扇出的范围就是 `idx_key2` 的范围区间 (10, 1000) 的记录
SELECT * FROM single_table AS s1 INNER JOIN single_table2 AS s2 
WHERE s1.key2 >10 AND s1.key2 < 1000;
```

- 比较难判断的场景
```sql
// 多了一个 common_filed 的判定条件，这个不是索引也不是主键所以无法判断
SELECT * FROM single_table AS s1 INNER JOIN single_table2 AS s2 
    WHERE s1.common_field > 'xyz';

// 同上
SELECT * FROM single_table AS s1 INNER JOIN single_table2 AS s2 
WHERE s1.key2 > 10 AND s1.key2 < 1000 AND
        s1.common_field > 'xyz';
```

所以，比较难判断的场景下计算扇出值需要猜测
- 如果是全表扫描的方式执行的单表查询，那么计算驱动表扇出时需要猜测满足搜索条件的记录到底有多少
- 如果是索引执行的单表扫描，那么计算驱动表扇出的时候需要猜测满足除使用到的对应索引的搜索条件外的其它搜索条件的记录有多少条

这个猜测的过程就称之为 `condition filtering`, 具体过程不表

## 两表连接的成本分析
计算方法
```txt
连接查询总成本 = 单次访问驱动表的成本 + 驱动表扇出数 x 单次访问被驱动表的成本
```
对于左右连接查询来说，驱动表是固定的，所以想要得到最优的查询方案只需要:
- 分别为驱动表和被驱动表选择成本最低的访问方法。

可是对于内连接来说，驱动表和被驱动表的位置是可以互换的，所以需要考虑两个方面的问题:
- 不同的表作为驱动表最终的查询成本可能是不同的，需要考虑最优的表连接顺序
- 分别为驱动表和被驱动表选择成本最低的访问方法。

### 优化的重点
- 尽量减少驱动表的扇出
- 对被驱动表的访问成本尽量低

## 多表连接的成本分析
首先需要考虑一下多表连接时可能产生出多少种连接顺序
其实就是 `n!` 的连接顺序, n是表的数量

设计上会有许多减少计算非常多连接顺序的成本的方法

- 提前结束某种顺序的成本评估
计算各种连接顺序的成本之前，会维护一个全局的变量，表示当前最小的连接查询成本
如果在分析某个连接顺序的成本时，已经超过了最小成本，那就不用继续分析了。

- 系统变量 `optimizer_search_depth`
该变量可以控制要不要继续分析连接的成本，如果连接表小于该个数，就分析，不然，就只分析到这个数量为止

- 根据某些规则排除某些连接顺序
有一些启发性规则，凡是不满足这些规则的连接顺序就不分析，可以通过系统变量 `optimizer_prune_level` 来控制到底是不是用这些规则

# 调节成本常数

存储成本常数的字段都被存储在 `mysql` 数据库中
```sql
SHOW TABLES FROM mysql LIKE '%cost%';
```

一条语句的执行分为2层:
- `server` 层
进行连接管理，查询缓存，语法解析，查询优化等操作
所以一条语句在 `server` 层中执行的成本是和它操作的表使用的存储引擎是没关系的
所以关于这些操作对应的 `成本常数` 就存储在了 `server_const` 表中
- 存储引擎层
执行具体的数据存取操作
`成本常数` 存储在 `engine_cost` 表中

## mysql.server_cost 表
```shell
mysql> SELECT * FROM mysql.server_cost;
+------------------------------+------------+---------------------+---------+
| cost_name                    | cost_value | last_update         | comment |
+------------------------------+------------+---------------------+---------+
| disk_temptable_create_cost   |       NULL | 2018-01-20 12:03:21 | NULL    |
| disk_temptable_row_cost      |       NULL | 2018-01-20 12:03:21 | NULL    |
| key_compare_cost             |       NULL | 2018-01-20 12:03:21 | NULL    |
| memory_temptable_create_cost |       NULL | 2018-01-20 12:03:21 | NULL    |
| memory_temptable_row_cost    |       NULL | 2018-01-20 12:03:21 | NULL    |
| row_evaluate_cost            |       NULL | 2018-01-20 12:03:21 | NULL    |
+------------------------------+------------+---------------------+---------+
```
### 列的含义
- `const_name` : 表示成本常数的名称
- `const_value`: 表示成本常数对应的值。如果为`NULL`，意味着对应的成本常数会采用默认值
- `last_update`: 表示最后更新记录的时间
- `comment`: 注释

### 主要成本常数

| 成本常数名称                   | 默认值 | 描述                                                         |
| ------------------------------ | ------ | ------------------------------------------------------------ |
| `disk_template_create_cost`    | 40.0   | 创建基于磁盘的临时表的成本，如果增大这个值的话会让优化器尽量少的创建基于磁盘的临时表 |
| `disk_template_row_cost`       | 1.0    | 向基于磁盘的临时表写入或读取一条记录的成本，如果增大这个值的话会让优化器尽量少的创建基于磁盘的临时表 |
| `key_compare_cost`             | 0.1    | 两条记录做比较操作的成本，多用在排序操作上，如果增大这个值的话会提升`filesort`的成本，让优化器可能更倾向于使用索引完成排序而不是`filesort`。 |
| `memory_temptable_create_cost` | 2.0    | 创建基于内存的临时表的成本，如果增大这个值的话会让优化器尽量少的创建基于内存的临时表 |
| `memory_temptable_row_const`   | 0,2    | 向基于内存的临时表写入或读取一条记录的成本，如果增大这个值的话会让优化器尽量少的创建基于内存的临时表 |
| `row_evaluate_cost`            | 0.2    | 这个就是我们之前一直使用的检测一条记录是否符合搜索条件的成本，增大这个值可能让优化器更倾向于使用索引而不是直接全表扫描 |

这些成本常数的初始值都是 `NULL`,所以优化器会使用默认值来计算

## mysql.engine_cost 表
```shell
mysql> SELECT * FROM mysql.engine_cost;
+-------------+-------------+------------------------+------------+---------------------+---------+
| engine_name | device_type | cost_name              | cost_value | last_update         | comment |
+-------------+-------------+------------------------+------------+---------------------+---------+
| default     |           0 | io_block_read_cost     |       NULL | 2018-01-20 12:03:21 | NULL    |
| default     |           0 | memory_block_read_cost |       NULL | 2018-01-20 12:03:21 | NULL    |
+-------------+-------------+------------------------+------------+---------------------+---------+

```
### 列的含义

跟 `server_cost` 相比，多了2个列
- `engine_name`: 成本常数适用的存储引擎名称。如果该值为`default`,说明适用于全部的存储引擎
- `device_type`: 存储引擎使用的设备类型，主要是为了区分机械和固态硬盘，默认值为0

### 主要内容

| 成本常数名称             | 默认值 | 描述                                                         |
| ------------------------ | ------ | ------------------------------------------------------------ |
| `io_block_read_cost`     | `1.0`  | 从磁盘上读取一个块对应的成本。请注意我使用的是`块`，而不是`页`这个词儿。对于`InnoDB`存储引擎来说，一个`页`就是一个块，不过对于`MyISAM`存储引擎来说，默认是以`4096`字节作为一个块的。增大这个值会加重`I/O`成本，可能让优化器更倾向于选择使用索引执行查询而不是执行全表扫描 |
| `memory_block_read_cost` | `1.0`  | 与上一个参数类似，只不过衡量的是从内存中读取一个块对应的成本。 |
|                          |        |                                                              |

