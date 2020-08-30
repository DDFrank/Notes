本章主要介绍`InnoDB` 存储引擎的统计数据收集策略

# 两种不同的统计数据存储方式
- 永久性的统计数据
会持久化到磁盘上去
- 非永久性的统计数据
存储在内存中，当服务器关闭时这些统计数据就都被清除掉了

系统变量`innodb_stats_persistent` 控制到底采用哪种方式去统计数据
`5.6.6`之前，默认值是 `OFF`, 之后的版本默认值是 `ON`

`InnoDB` 默认是`以表为单位来收集和存储统计数据的`, 可以把某些表的统计数据存储在磁盘上，把另外一些表的统计数据存储在内存中。
可以在创建和修改表的时候通过指定 `STATS_PERSISTENT` 属性来指明该表的统计数据存储方式

```sql
# 1 表示磁盘
CREATE TABLE 表名 (...) Engine=InnoDB, STATS_PERSISTENT = (1|0);

ALTER TABLE 表名 Engine=InnoDB, STATS_PERSISTENT = (1|0);
```

# 基于磁盘的永久性统计数据
把统计持久化到磁盘，实际上是把这些统计数据存储到了两个表里

```sql
mysql> SHOW TABLES FROM mysql LIKE 'innodb%';
+---------------------------+
| Tables_in_mysql (innodb%) |
+---------------------------+
| innodb_index_stats        |
| innodb_table_stats        |
+---------------------------+
```
- `innodb_index_stats`: 存储了关于表的统计数据,每一条记录对应着一个表的统计数据
- `innodb_index_stats`: 存储了关于索引的统计数据，每一条记录对应着一个索引的一个统计项的统计数据

## innodb_table_stats

| 字段名                      | 描述                                |
| --------------------------- | ----------------------------------- |
| `database_name`             | 数据库名                            |
| `table_name`                | 表名                                |
| `last_update`               | 本条记录最后更新时间                |
| `n_rows`                    | 表中记录的条数 （估计值）           |
| `clustered_index_size`      | 表的聚簇索引占用的页面数量 (估计值) |
| `sum_of_oteher_index_sizes` | 表的其它索引占用的页面数量 (估计值) |

该表的主键是 `database_name, table_name`

### n_rows 统计项的收集方法
按照一定的算法(不是纯粹随机的)选取几个叶子节点页面，计算每个页面中主键值记录数量，然后计算平均一个页面中主键值的记录数量乘以全部叶子节点的数量就算是该表的 `n_rows` 值

所以 `n_rows` 值精确与否取决于统计时采样的页面数量
系统变量`innodb_stats_persistent_sample_pages` 控制`持久化的统计数据，在计算时采样的页面数量`
该值越大，统计出的 `n_rows` 值越精确，但是统计耗时也就最久
该值越小，统计出的 `n_rows` 值越不精确，但是统计耗时少
默认值是`20`

可以单独设置某个表的采样页面数量
```sql
CREATE TABLE 表名 (...) Engine=InnoDB, STATS_SAMPLE_PAGES = 具体的采样页面数量;

ALTER TABLE 表名 Engine=InnoDB, STATS_SAMPLE_PAGES = 具体的采样页面数量;
```

### clustered_index_size 和 sum_of_oteher_index_sizes 统计项的收集
过程如下:
- 从数据字典里找到表的各个索引对应的根页面位置
系统表`SYS_INDEXES`里存储了各个索引对应的根页面信息
- 从根页面的 `Page Header` 里找到叶子节点段和非叶子节点段对应的 `Segment Header`
每个索引的根页面的 `Page Header` 部分都有两个字段
  * `PAGE_BTR_SEG_LEAF`: 表示B+树叶子段的 `Segment Header` 信息
  * `PAGE_BTR_SEG_TOP`: 表示B+树非叶子段的 `Segment Header` 信息

- 从叶子节点段和非叶子节点段的 `Segment Header` 中找到这两个段对应的 `INODE Entry` 结构
- 从对应的 `INODE Entry` 结构中可以找到该段对应所有零散的页面地址以及 `FREE`, `NOT_FULL`,`FULL`链表的基节点
- 直接统计零散的页面有多少，然后从那三个链表的 `List Length` 字段中读出该段占用的区的大小，每个区占用`64`个页，所以就可以统计出整个段占用的页面
- 分别计算聚簇索引的叶子节点段和非叶子节点段占用的页面数，其和就是 `clustered_index_size` 的值，`sum_of_other_index_sizes` 的计算方法也是同样的
  

当一个段的数据比较多的时候，会以`区`为单位申请空间，但是申请的`区中有一些页面可能并没有使用`, 所以统计值可能比实际值会稍微大一些

## innodb_index_stats

| 字段名             | 描述                           |
| ------------------ | ------------------------------ |
| `database_name`    | 数据库名                       |
| `table_name`       | 表名                           |
| `index_name`       | 索引名                         |
| `last_update`      | 本条记录最后的更新时间         |
| `stat_name`        | 统计项的名称                   |
| `stat_value`       | 对应的统计项的值               |
| `sample_size`      | 为生成统计数据而采样的页面数量 |
| `stat_description` | 对应的统计项的描述             |

该表的主键是`data_base_name, table_name, index_name, stat_name`， 其中的 `stat_name` 是指统计项的名称, 也就是说`innodb_index_stats`表的每条记录代表着一个索引的一个统计项。
```shell
mysql> SELECT * FROM mysql.innodb_index_stats WHERE table_name = 'single_table';
+---------------+--------------+--------------+---------------------+--------------+------------+-------------+-----------------------------------+
| database_name | table_name   | index_name   | last_update         | stat_name    | stat_value | sample_size | stat_description                  |
+---------------+--------------+--------------+---------------------+--------------+------------+-------------+-----------------------------------+
| xiaohaizi     | single_table | PRIMARY      | 2018-12-14 14:24:46 | n_diff_pfx01 |       9693 |          20 | id                                |
| xiaohaizi     | single_table | PRIMARY      | 2018-12-14 14:24:46 | n_leaf_pages |         91 |        NULL | Number of leaf pages in the index |
| xiaohaizi     | single_table | PRIMARY      | 2018-12-14 14:24:46 | size         |         97 |        NULL | Number of pages in the index      |
| xiaohaizi     | single_table | idx_key1     | 2018-12-14 14:24:46 | n_diff_pfx01 |        968 |          28 | key1                              |
| xiaohaizi     | single_table | idx_key1     | 2018-12-14 14:24:46 | n_diff_pfx02 |      10000 |          28 | key1,id                           |
| xiaohaizi     | single_table | idx_key1     | 2018-12-14 14:24:46 | n_leaf_pages |         28 |        NULL | Number of leaf pages in the index |
| xiaohaizi     | single_table | idx_key1     | 2018-12-14 14:24:46 | size         |         29 |        NULL | Number of pages in the index      |
| xiaohaizi     | single_table | idx_key2     | 2018-12-14 14:24:46 | n_diff_pfx01 |      10000 |          16 | key2                              |
| xiaohaizi     | single_table | idx_key2     | 2018-12-14 14:24:46 | n_leaf_pages |         16 |        NULL | Number of leaf pages in the index |
| xiaohaizi     | single_table | idx_key2     | 2018-12-14 14:24:46 | size         |         17 |        NULL | Number of pages in the index      |
| xiaohaizi     | single_table | idx_key3     | 2018-12-14 14:24:46 | n_diff_pfx01 |        799 |          31 | key3                              |
| xiaohaizi     | single_table | idx_key3     | 2018-12-14 14:24:46 | n_diff_pfx02 |      10000 |          31 | key3,id                           |
| xiaohaizi     | single_table | idx_key3     | 2018-12-14 14:24:46 | n_leaf_pages |         31 |        NULL | Number of leaf pages in the index |
| xiaohaizi     | single_table | idx_key3     | 2018-12-14 14:24:46 | size         |         32 |        NULL | Number of pages in the index      |
| xiaohaizi     | single_table | idx_key_part | 2018-12-14 14:24:46 | n_diff_pfx01 |       9673 |          64 | key_part1                         |
| xiaohaizi     | single_table | idx_key_part | 2018-12-14 14:24:46 | n_diff_pfx02 |       9999 |          64 | key_part1,key_part2               |
| xiaohaizi     | single_table | idx_key_part | 2018-12-14 14:24:46 | n_diff_pfx03 |      10000 |          64 | key_part1,key_part2,key_part3     |
| xiaohaizi     | single_table | idx_key_part | 2018-12-14 14:24:46 | n_diff_pfx04 |      10000 |          64 | key_part1,key_part2,key_part3,id  |
| xiaohaizi     | single_table | idx_key_part | 2018-12-14 14:24:46 | n_leaf_pages |         64 |        NULL | Number of leaf pages in the index |
| xiaohaizi     | single_table | idx_key_part | 2018-12-14 14:24:46 | size         |         97 |        NULL | Number of pages in the index      |
+---------------+--------------+--------------+---------------------+--------------+------------+-------------+-----------------------------------+
```
如何查看该表
- 先查看 `index_name` 列，该列说明该记录是哪个索引的统计信息
查看上表，发现 `PRIMARY` 索引（主键）占了3条记录,`idx_key_part` 索引占了6条记录
- 针对同一个索引, `stat_name` 表示针对该索引的统计项名称, `stat_value` 展示的是该索引在该统计项上值, `stat_description` 指的是该统计项的含义
- 计算某些索引列中包含多少不重复值时，需要对一些叶子节点页面进行采样，`sample_size`列就表明了采样的页面数量是多少
  - 当需要采样的页面数量大于该索引子节点占用的页面数量的话，就直接全表扫描来计算索引列的不重复值数量了 

### 索引的统计项
- `n_leaf_pages`: 表示该索引的叶子节点占用多少页面
- `size`: 表示该索引占用多少页面
- `n_diff_pfxNN`: 表示对应的索引列不重复的值有多少, NM 可以替换为 `01, 02, 03 `等数字
  - `n_diff_pfx01` 表示的统计 `key_part1` 这单单一个列不重复的值有多少
  - `n_diff_pfx02` 表示的是统计 `key_part1`, `key_part2` 这两个列组合起来不重复的有多少
  - 以此类推
  
注意, 主键和唯一二级索引本身可以保证索引列是不重复的，因此不需要再统计一遍在索引列后加上主键值的不重复值有多少


## 定期更新统计数据
两种方式
### 开启 `innodb_stats_auto_recalc`
- 该变量决定服务器是否自动重新计算统计数据，默认值是 `ON`
- 每个表维护了一个变量，该变量记录着该对标进行只能删改查的记录条数,假如超过了表大小的`10%`, 并且自动重算的功能是打开的，那么服务器会重新进行一次统计数据的计算,并且更新`innodb_table_stats` 和 `innodb_index_stats` 表
- 表的更新过程是异步的

#### 可以单独为某个表设置是否重新计算的属性
```sql
CREATE TABLE 表名 (...) Engine=InnoDB, STATS_AUTO_RECALC = (1|0);

ALTER TABLE 表名 Engine=InnoDB, STATS_AUTO_RECALC = (1|0);
```

### 手动调用 `ANALYZE TABLE` 语句更新统计信息
如果 `innodb_stats_auto_recalc` 系统变量的值为 `OFF` 的话，也可以手动调用 `ANALYZE TABLE` 语句来重新计算统计数据
```sql
mysql> ANALYZE TABLE single_table;
+------------------------+---------+----------+----------+
| Table                  | Op      | Msg_type | Msg_text |
+------------------------+---------+----------+----------+
| xiaohaizi.single_table | analyze | status   | OK       |
+------------------------+---------+----------+----------+
```
这个过程是同步的,注意不要阻塞业务运行

### 手动更新 `innodb_table_stats` 和 `innodb_index_stats` 表
- 像更新一个普通表一样更新它
- 然后重载更改过的数据
```sql
FLUSH TABLE single_table;
```

# 基于内存的非永久性统计数据
将系统变量`innodb_stats_persistent`的值设备为`OFF`时，之后创建的表的统计数据默认就都是非永久性了。
或者我们直接在创建表或修改表时设置`STATS_PERSISTENT` 属性的值为 `0`, 那么该表的统计数据就是非永久性了

非永久性的统计数据采样的页面数量是由 `innodb_stats_transient_sample_pages` 控制的，默认值为0

由于非永久性的统计数据经常更新，所以导致查询优化器计算查询成本的事实依赖的是经常变化的统计数据，也就会生成`经常变化的执行计划`

# innodb_stats_method 的使用
`索引列不重复的值的数量` 这个统计数据对于 `MySQL` 查询优化器十分重要，通过它可以计算出索引列中平均一个值重复多少行
其主要的应用场景在于
- 单表查询中单点区间太多
```sql
SELECT * FROM tbl_name WHERE key IN ('xx1', 'xx2', ..., 'xxn');
```

查询优化时，当`IN`里的参数数量过多时，采用`index dive` 的方式直接访问 `B+`树索引去统计每个单点区间对应的记录的数量就太耗费性能了，所以直接依赖统计数据中的平均一个值重复多少行来计算单点区间对应的记录数量

- 连接查询时，如果涉及到两个表的等值匹配连接条件，该连接条件对应的被驱动表列又拥有索引时，则可以使用 `ref` 访问方法来对被驱动表进行查询
```sql
SELECT * FROM t1 JOIN t2 ON t1.column = t2.key WHERE ...;
```
查询优化时，`t1.column` 的值是不确定的，所以需要依赖统计数据中平均一个值重复多少行来计算单点区间对应的记录数量

## 索引列中的 NULL
对于索引中会出现的 `NULL` 值，会有三种处理方案
- `NULL`代表一个为确定的值，所以任何和 `NULL` 值做比较的表达式的值都为`NULL`
  - 因为每一个 `NULL`值都是独一无二的，所以统计索引中不重复的值的数量时，应该把 `NULL` 值当做一个独立的值
- `NULL` 代表没有，所以所有的 `NULL` 都是一样的
- `NULL` 不能参与索引统计不重复的值的计算

以上三种方案对应 `MySql`的`innodb_stats_method` 的系统变量, 该变量有三个值
- `nulls_equal`: 认为所有 `NULL` 值都是相等的，这个是默认值
- `nulls_unequal`: 认为所有的 `NULL` 都是不相等的
- `nulls_ignored`: 直接忽略 `NULL` 值


所以，综上所述，最好不要在 索引列中存放 `NULL` 值
