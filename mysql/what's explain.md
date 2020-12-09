
# 如何查看 EXPLAIN 执行计划
```sql
mysql> EXPLAIN SELECT 1;
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra          |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
|  1 | SIMPLE      | NULL  | NULL       | NULL | NULL          | NULL | NULL    | NULL | NULL |     NULL | No tables used |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
```

列结构

| 列名            | 描述                                                       |
| --------------- | ---------------------------------------------------------- |
| `id`            | 在一个大的查询语句中每个`SELECT`关键字都对应一个唯一的`id` |
| `select_type`   | `SELECT`关键字对应的那个查询的类型r                        |
| `table`         | 表名                                                       |
| `partitions`    | 匹配的分区信息                                             |
| `type`          | 针对单表的访问方法                                         |
| `possible_keys` | 可能用到的索引                                             |
| `key`           | 实际上使用的索引                                           |
| `key_len`       | 实际使用到的索引长度                                       |
| `ref`           | 当使用索引列等值查询时，与索引列进行等值匹配的对象信息     |
| `rows`          | 预估的需要读取的记录条数                                   |
| `filtered`      | 某个表经过搜索条件过滤后剩余记录条数的百分比               |
| `Extra`         | 一些额外的信息                                             |
|                 |                                                            |

还是使用该表
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

# 执行计划输出中各列详解
## table
不论查询语句有多复杂，里边有多少表，到最后也是需要对每个表进行单表访问的。
所以`EXPLAIN`语句输出的每条记录都对应着某个单表的访问方法，该条记录的table列代表着该表的表名

## id
查询语句中每出现一个 `SELECT` 关键字，就会被分配一个唯一的`id`值

连接查询的时候，一个 `SELECT` 关键字后边的 `FROM` 子句中可以跟随多个表, 所以在连接查询的执行计划中, `每个表对应一条记录，但是这些记录的id值都是相同的`

所以，`在连接查询的执行计划中，每个表都会对应一条记录,这些记录的id列的值是相同的，出现在前辈的表表示驱动表，出现在后边的表表示被驱动表`

```sql
mysql> EXPLAIN SELECT * FROM s1 INNER JOIN s2;
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+---------------------------------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra                                 |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+---------------------------------------+
|  1 | SIMPLE      | s1    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9688 |   100.00 | NULL                                  |
|  1 | SIMPLE      | s2    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9954 |   100.00 | Using join buffer (Block Nested Loop) |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+---------------------------------------+
2 rows in set, 1 warning (0.01 sec)
```
对于包含子查询的查询语句来说，会涉及多个`SELECT`关键字,所以在包含子查询的查询语句的执行计划中，每个`SELECT`关键字都会对应唯一的`id`值

```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 IN (SELECT key1 FROM s2) OR key3 = 'a';
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
| id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra       |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
|  1 | PRIMARY     | s1    | NULL       | ALL   | idx_key3      | NULL     | NULL    | NULL | 9688 |   100.00 | Using where |
|  2 | SUBQUERY    | s2    | NULL       | index | idx_key1      | idx_key1 | 303     | NULL | 9954 |   100.00 | Using index |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
2 rows in set, 1 warning (0.02 sec)
```

注意: 查询优化器可能对涉及子查询的查询语句进行重写，转换为连接查询。
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 IN (SELECT key3 FROM s2 WHERE common_field = 'a');
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+------------------------------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref               | rows | filtered | Extra                        |
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+------------------------------+
|  1 | SIMPLE      | s2    | NULL       | ALL  | idx_key3      | NULL     | NULL    | NULL              | 9954 |    10.00 | Using where; Start temporary |
|  1 | SIMPLE      | s1    | NULL       | ref  | idx_key1      | idx_key1 | 303     | xiaohaizi.s2.key3 |    1 |   100.00 | End temporary                |
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+------------------------------+
2 rows in set, 1 warning (0.00 sec)
```

对于包含 `UNION` 子句的查询语句来说, 因为会需要对多个查询的结果集进行去重，所以会创建一个临时表
`UNION ALL` 因为不需要去重，就不会生成临时表

## select_type
一条大的查询语句里边可以包含若干个`SELECT`关键字, 每个`SELECT`关键字代表着一个小的查询语句，而每个`SELECT`关键字的`FROM`子句中都可以包含若干张表(这些表用来做来连接查询)，每一张表都对应着执行计划输出中的一条记录，对于在同一个 `SELECT`关键字中的表来说，它们的`id`值是相同的

每一个 `SELECT` 关键字代表的小查询都定义了一个称之为 `select_type` 的属性，可以看出该查询在整个大查询中所属的角色

| 名称                   | 描述                                                         |
| ---------------------- | ------------------------------------------------------------ |
| `SIMPLE`               | Simple SELECT (not using UNION or subqueries)                |
| `PRIMARY`              | Outermost SELECT                                             |
| `UNION`                | Second or later SELECT statement in a UNION                  |
| `UNION RESULT`         | Result of a UNION                                            |
| `SUBQUERY`             | First SELECT in subquery                                     |
| `DEPENDENT SUBQUERY`   | First SELECT in subquery, dependent on outer query           |
| `DEPENDENT UNION`      | Second or later SELECT statement in a UNION, dependent on outer query |
| `DERIVED`              | Derived table                                                |
| `MATERIALIZED`         | Materialized subquery                                        |
| `UNCACHEABLE SUBQUERY` | A subquery for which the result cannot be cached and must be re-evaluated for each row of the outer query |
| `UNCACHEABLE UNION`    | The second or later select in a UNION that belongs to an uncacheable subquery (see UNCACHEABLE SUBQUERY) |
|                        |                                                              |
|                        |                                                              |

属性的含义

- `SIMPLE`
查询语句中不包含`UNION`或者子查询的查询都算作是`SIMPLE`类型

- `PRIMARY`, `UNION`
对于包含 `UNION`, `UNION ALL` 或者子查询的大查询来说，它是由几个小查询组成的，其中最左边的那个查询`select_type`值就是`PRIMARY`。其余的都是 `UNION`
```sql
mysql> EXPLAIN SELECT * FROM s1 UNION SELECT * FROM s2;
+----+--------------+------------+------------+------+---------------+------+---------+------+------+----------+-----------------+
| id | select_type  | table      | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra           |
+----+--------------+------------+------------+------+---------------+------+---------+------+------+----------+-----------------+
|  1 | PRIMARY      | s1         | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9688 |   100.00 | NULL            |
|  2 | UNION        | s2         | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9954 |   100.00 | NULL            |
| NULL | UNION RESULT | <union1,2> | NULL       | ALL  | NULL          | NULL | NULL    | NULL | NULL |     NULL | Using temporary |
+----+--------------+------------+------------+------+---------------+------+---------+------+------+----------+-----------------+
3 rows in set, 1 warning (0.00 sec)
```

- `UNION RESULT`
当 `UNION`的查询触发了临时表的去重工作时，针对该临时表的查询的 `select_type` 就是 `UNION RESULT`

- `SUBQUERY`
如果包含子查询的查询语句不能够转为对应的 `semi-join` 的形式，并且该子查询是不相关子查询，并且查询优化器决定采用将该子查询物化的方案来执行该子查询时，该子查询的第一个 `SELECT` 关键字代表的那个查询额 `select_type` 就是 `SUBQuERY`
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 IN (SELECT key1 FROM s2) OR key3 = 'a';
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
| id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra       |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
|  1 | PRIMARY     | s1    | NULL       | ALL   | idx_key3      | NULL     | NULL    | NULL | 9688 |   100.00 | Using where |
|  2 | SUBQUERY    | s2    | NULL       | index | idx_key1      | idx_key1 | 303     | NULL | 9954 |   100.00 | Using index |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
2 rows in set, 1 warning (0.00 sec)
```
外层查询的 `select_type` 就是 `PRIMARY` ，子查询的 `select_type` 就是 `SUBQUERY`。由于 `select_type` 为 `SUBQUERY`的子查询会被物化，所以只需要执行一遍

- `DEPENDENT SUBQUERY`
如果包含子查询的查询语句不能够转为对应的 `semi-join`的形式，并且该子查询是相关子查询，则该子查询的第一个`SELECT`关键字代表的那个查询的`select_type`就是 `DEPENDENT SUBQUERY`
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 IN (SELECT key1 FROM s2 WHERE s1.key2 = s2.key2) OR key3 = 'a';
+----+--------------------+-------+------------+------+-------------------+----------+---------+-------------------+------+----------+-------------+
| id | select_type        | table | partitions | type | possible_keys     | key      | key_len | ref               | rows | filtered | Extra       |
+----+--------------------+-------+------------+------+-------------------+----------+---------+-------------------+------+----------+-------------+
|  1 | PRIMARY            | s1    | NULL       | ALL  | idx_key3          | NULL     | NULL    | NULL              | 9688 |   100.00 | Using where |
|  2 | DEPENDENT SUBQUERY | s2    | NULL       | ref  | idx_key2,idx_key1 | idx_key2 | 5       | xiaohaizi.s1.key2 |    1 |    10.00 | Using where |
+----+--------------------+-------+------------+------+-------------------+----------+---------+-------------------+------+----------+-------------+
2 rows in set, 2 warnings (0.00 sec)
```
type 为 `DEPENDENT SUBQUERY` 的查询可能被执行多次

- `DEPENDENT UNION`
在包含`UNION`或者`UNION ALL`的大查询中，如果各个小查询都依赖于外层查询的话，那除了最左边的那个小查询之外，其余的小查询的`select_type`的值就是 `DEFENDENT UNION`

```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 IN (SELECT key1 FROM s2 WHERE key1 = 'a' UNION SELECT key1 FROM s1 WHERE key1 = 'b');
+----+--------------------+------------+------------+------+---------------+----------+---------+-------+------+----------+--------------------------+
| id | select_type        | table      | partitions | type | possible_keys | key      | key_len | ref   | rows | filtered | Extra                    |
+----+--------------------+------------+------------+------+---------------+----------+---------+-------+------+----------+--------------------------+
|  1 | PRIMARY            | s1         | NULL       | ALL  | NULL          | NULL     | NULL    | NULL  | 9688 |   100.00 | Using where              |
|  2 | DEPENDENT SUBQUERY | s2         | NULL       | ref  | idx_key1      | idx_key1 | 303     | const |   12 |   100.00 | Using where; Using index |
|  3 | DEPENDENT UNION    | s1         | NULL       | ref  | idx_key1      | idx_key1 | 303     | const |    8 |   100.00 | Using where; Using index |
| NULL | UNION RESULT       | <union2,3> | NULL       | ALL  | NULL          | NULL     | NULL    | NULL  | NULL |     NULL | Using temporary          |
+----+--------------------+------------+------------+------+---------------+----------+---------+-------+------+----------+--------------------------+
4 rows in set, 1 warning (0.03 sec)
```
子查询中的后一个查询的 `select_type`就是`DEPENDENT UNION`

- `DERIVED`
对于采用物化的方式执行的包含派生表的查询，该派生表对应的子查询的`select_type`就是`DERIVED`
```sql
mysql> EXPLAIN SELECT * FROM (SELECT key1, count(*) as c FROM s1 GROUP BY key1) AS derived_s1 where c > 1;
+----+-------------+------------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
| id | select_type | table      | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra       |
+----+-------------+------------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
|  1 | PRIMARY     | <derived2> | NULL       | ALL   | NULL          | NULL     | NULL    | NULL | 9688 |    33.33 | Using where |
|  2 | DERIVED     | s1         | NULL       | index | idx_key1      | idx_key1 | 303     | NULL | 9688 |   100.00 | Using index |
+----+-------------+------------+------------+-------+---------------+----------+---------+------+------+----------+-------------+
2 rows in set, 1 warning (0.00 sec)
```
`id` 为 `2` 的记录就代表子查询的执行方式，它的`select_type`是`DERIVED`，说明该子查询是以物化的方式执行的
`id`为`1` 的记录的`table`字段显示的就是 `派生表`的名称 

- `MATERIALIZED`
当查询优化器在执行包含子查询的语句时，选择将子查询物化之后与外层查询进行连接查询时，该子查询对应的`select_type`的属性就是 `MATERIALIZED`
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 IN (SELECT key1 FROM s2);
+----+--------------+-------------+------------+--------+---------------+------------+---------+-------------------+------+----------+-------------+
| id | select_type  | table       | partitions | type   | possible_keys | key        | key_len | ref               | rows | filtered | Extra       |
+----+--------------+-------------+------------+--------+---------------+------------+---------+-------------------+------+----------+-------------+
|  1 | SIMPLE       | s1          | NULL       | ALL    | idx_key1      | NULL       | NULL    | NULL              | 9688 |   100.00 | Using where |
|  1 | SIMPLE       | <subquery2> | NULL       | eq_ref | <auto_key>    | <auto_key> | 303     | xiaohaizi.s1.key1 |    1 |   100.00 | NULL        |
|  2 | MATERIALIZED | s2          | NULL       | index  | idx_key1      | idx_key1   | 303     | NULL              | 9954 |   100.00 | Using index |
+----+--------------+-------------+------------+--------+---------------+------------+---------+-------------------+------+----------+-------------+
3 rows in set, 1 warning (0.01 sec)
```
`id`为`2`的记录的`select_type`的值为`MATERIALIZED`表名，查询优化器要先把子查询转换为物化表
执行计划的前2条记录的`id`值均为`1`, 说明着2条记录对应的表需要连接。
第二条记录的`table`列的值是`<subquery2>`, 说明该表其实就是`id`为`2`对应的子查询执行之后产生的物化表，然后将`s1`和该物化表进行连接查询

- `UNCACHEABLE SUBQUERY`, `UNCACHEABLE UNION`
不常用，略过

## partitions
略过，一般都是`NULL`

## type
执行计划的一条记录就代表着`MySQL`对某个表的执行查询时的访问方法，且其中`type` 列就表明了这个访问方法

- `system`
当表中只有一条记录并且`该表使用的存储引擎的统计数据是精确的，比如MyISAM,Memory`, 那么对该表的访问方法就是`system`

- `const`
根据主键或者唯一二级索引列与常数进行等值匹配时，对单表的访问方法就是`const`
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE id = 5;
+----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
| id | select_type | table | partitions | type  | possible_keys | key     | key_len | ref   | rows | filtered | Extra |
+----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | s1    | NULL       | const | PRIMARY       | PRIMARY | 4       | const |    1 |   100.00 | NULL  |
+----+-------------+-------+------------+-------+---------------+---------+---------+-------+------+----------+-------+
1 row in set, 1 warning (0.01 sec)
```

- `eq_ref`
在连接查询时，如果被驱动表是通过主键或者唯一二级索引列等值匹配的方式将进行访问的, 则对被驱动表的访问方式就是`eq_ref`
```sql
mysql> EXPLAIN SELECT * FROM s1 INNER JOIN s2 ON s1.id = s2.id;
+----+-------------+-------+------------+--------+---------------+---------+---------+-----------------+------+----------+-------+
| id | select_type | table | partitions | type   | possible_keys | key     | key_len | ref             | rows | filtered | Extra |
+----+-------------+-------+------------+--------+---------------+---------+---------+-----------------+------+----------+-------+
|  1 | SIMPLE      | s1    | NULL       | ALL    | PRIMARY       | NULL    | NULL    | NULL            | 9688 |   100.00 | NULL  |
|  1 | SIMPLE      | s2    | NULL       | eq_ref | PRIMARY       | PRIMARY | 4       | xiaohaizi.s1.id |    1 |   100.00 | NULL  |
+----+-------------+-------+------------+--------+---------------+---------+---------+-----------------+------+----------+-------+
```
`s1`作为驱动表，`s2`作为被驱动表, `s2`的访问方法是`eq_ref`,表明在访问`s2`表的时候可以通过主键的等值匹配来进行访问

- `ref`
当通过普通二级索引列与常量进行等值匹配时来查询某个表,那么对该表的访问方法就`可能`是`ref`
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 = 'a';
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref   | rows | filtered | Extra |
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | s1    | NULL       | ref  | idx_key1      | idx_key1 | 303     | const |    8 |   100.00 | NULL  |
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------+
1 row in set, 1 warning (0.04 sec)
```

- `fulltext` 
TODO 全文索引，待补完

- `ref_or_null`
当对普通二级索引进行等值匹配查询,该索引列的值也可以是`NULL`值时，那么对该表的访问方法就`可能`是 `ref_or_null`
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 = 'a' OR key1 IS NULL;
+----+-------------+-------+------------+-------------+---------------+----------+---------+-------+------+----------+-----------------------+
| id | select_type | table | partitions | type        | possible_keys | key      | key_len | ref   | rows | filtered | Extra                 |
+----+-------------+-------+------------+-------------+---------------+----------+---------+-------+------+----------+-----------------------+
|  1 | SIMPLE      | s1    | NULL       | ref_or_null | idx_key1      | idx_key1 | 303     | const |    9 |   100.00 | Using index condition |
+----+-------------+-------+------------+-------------+---------------+----------+---------+-------+------+----------+-----------------------+
1 row in set, 1 warning (0.01 sec)
```

- `index_merge`
一般情况下对于某个表的查询只能使用到一个索引，但是某些场景下可能发生`索引合并`
```sql
EXPLAIN SELECT * FROM s1 WHERE key1 = 'a' OR key3 = 'a';
+----+-------------+-------+------------+-------------+-------------------+-------------------+---------+------+------+----------+---------------------------------------------+
| id | select_type | table | partitions | type        | possible_keys     | key               | key_len | ref  | rows | filtered | Extra                                       |
+----+-------------+-------+------------+-------------+-------------------+-------------------+---------+------+------+----------+---------------------------------------------+
|  1 | SIMPLE      | s1    | NULL       | index_merge | idx_key1,idx_key3 | idx_key1,idx_key3 | 303,303 | NULL |   14 |   100.00 | Using union(idx_key1,idx_key3); Using where |
+----+-------------+-------+------------+-------------+-------------------+-------------------+---------+------+------+----------+---------------------------------------------+
1 row in set, 1 warning (0.01 sec)
```

- `unique_subquery`
类似于两表连接中被驱动表的`eq_ref`访问方法, `unique_subquery`是针对一些包含`IN`子查询的查询语句中,如果查询优化器决定将`IN`子查询转换为`EXISTS`子查询,而且子查询可以使用到主键进行等值匹配的话，那么该子查询执行计划的`type`列的值就是`unique_subquery`
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key2 IN (SELECT id FROM s2 where s1.key1 = s2.key1) OR key3 = 'a';
+----+--------------------+-------+------------+-----------------+------------------+---------+---------+------+------+----------+-------------+
| id | select_type        | table | partitions | type            | possible_keys    | key     | key_len | ref  | rows | filtered | Extra       |
+----+--------------------+-------+------------+-----------------+------------------+---------+---------+------+------+----------+-------------+
|  1 | PRIMARY            | s1    | NULL       | ALL             | idx_key3         | NULL    | NULL    | NULL | 9688 |   100.00 | Using where |
|  2 | DEPENDENT SUBQUERY | s2    | NULL       | unique_subquery | PRIMARY,idx_key1 | PRIMARY | 4       | func |    1 |    10.00 | Using where |
+----+--------------------+-------+------------+-----------------+------------------+---------+---------+------+------+----------+-------------+
2 rows in set, 2 warnings (0.00 sec)
```

- `index_subquery`
与 `unique_subquery`类似,只不过访问子查询中的表时使用的是普通的索引
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE common_field IN (SELECT key3 FROM s2 where s1.key1 = s2.key1) OR key3 = 'a';
+----+--------------------+-------+------------+----------------+-------------------+----------+---------+------+------+----------+-------------+
| id | select_type        | table | partitions | type           | possible_keys     | key      | key_len | ref  | rows | filtered | Extra       |
+----+--------------------+-------+------------+----------------+-------------------+----------+---------+------+------+----------+-------------+
|  1 | PRIMARY            | s1    | NULL       | ALL            | idx_key3          | NULL     | NULL    | NULL | 9688 |   100.00 | Using where |
|  2 | DEPENDENT SUBQUERY | s2    | NULL       | index_subquery | idx_key1,idx_key3 | idx_key3 | 303     | func |    1 |    10.00 | Using where |
+----+--------------------+-------+------------+----------------+-------------------+----------+---------+------+------+----------+-------------+
2 rows in set, 2 warnings (0.01 sec)
```

- `range`
如果使用索引获取某些`范围区间`的记录，那么就`可能`使用到`range`的访问方法
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 IN ('a', 'b', 'c');
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-----------------------+
| id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra                 |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-----------------------+
|  1 | SIMPLE      | s1    | NULL       | range | idx_key1      | idx_key1 | 303     | NULL |   27 |   100.00 | Using index condition |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-----------------------+
1 row in set, 1 warning (0.01 sec)

mysql> EXPLAIN SELECT * FROM s1 WHERE key1 > 'a' AND key1 < 'b';
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-----------------------+
| id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra                 |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-----------------------+
|  1 | SIMPLE      | s1    | NULL       | range | idx_key1      | idx_key1 | 303     | NULL |  294 |   100.00 | Using index condition |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-----------------------+
1 row in set, 1 warning (0.00 sec)
```

- `index`
当可以使用索引覆盖，但需要扫描全部的索引记录时，该表的访问方法就是`index`
```sql
mysql> EXPLAIN SELECT key_part2 FROM s1 WHERE key_part3 = 'a';
+----+-------------+-------+------------+-------+---------------+--------------+---------+------+------+----------+--------------------------+
| id | select_type | table | partitions | type  | possible_keys | key          | key_len | ref  | rows | filtered | Extra                    |
+----+-------------+-------+------------+-------+---------------+--------------+---------+------+------+----------+--------------------------+
|  1 | SIMPLE      | s1    | NULL       | index | NULL          | idx_key_part | 909     | NULL | 9688 |    10.00 | Using where; Using index |
+----+-------------+-------+------------+-------+---------------+--------------+---------+------+------+----------+--------------------------+
1 row in set, 1 warning (0.00 sec)
```

- `All`
全表扫描

## possible_keys和key
`possible_keys` 列表示在某个查询语句中，对某个表执行单表查询时可能用到的索引有哪些, `key`列表示实际用到的索引有哪些

```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 > 'z' AND key3 = 'a';
+----+-------------+-------+------------+------+-------------------+----------+---------+-------+------+----------+-------------+
| id | select_type | table | partitions | type | possible_keys     | key      | key_len | ref   | rows | filtered | Extra       |
+----+-------------+-------+------------+------+-------------------+----------+---------+-------+------+----------+-------------+
|  1 | SIMPLE      | s1    | NULL       | ref  | idx_key1,idx_key3 | idx_key3 | 303     | const |    6 |     2.75 | Using where |
+----+-------------+-------+------------+------+-------------------+----------+---------+-------+------+----------+-------------+
1 row in set, 1 warning (0.01 sec)
```

上述执行计划的 `possible_keys` 列的值是 `idx_key1, idex_key3`，表示该查询可能使用到`idx_key1, idx_key3`两个索引
然后`key`列的值是`idx_key3`，表示经过查询优化器计算使用不同索引的成本后，最后决定使用`idx_key3`来执行查询比较划算

有一种比较特殊的情况，在使用`index`访问方法来查询某个表时，`possible_keys`列是空的，而`key`列展示的是实际使用到的索引
```sql
mysql> EXPLAIN SELECT key_part2 FROM s1 WHERE key_part3 = 'a';
+----+-------------+-------+------------+-------+---------------+--------------+---------+------+------+----------+--------------------------+
| id | select_type | table | partitions | type  | possible_keys | key          | key_len | ref  | rows | filtered | Extra                    |
+----+-------------+-------+------------+-------+---------------+--------------+---------+------+------+----------+--------------------------+
|  1 | SIMPLE      | s1    | NULL       | index | NULL          | idx_key_part | 909     | NULL | 9688 |    10.00 | Using where; Using index |
+----+-------------+-------+------------+-------+---------------+--------------+---------+------+------+----------+--------------------------+
1 row in set, 1 warning (0.00 sec)
```

注意, possible_keys 列中的值不是越多越好，可能使用的索引越多，查询优化器计算查询成本时就得花费更长时间，所以可能的话，尽量删除哪些用不到的索引。

## key_len
`key_len` 列表示当优化器决定使用某个索引执行查询时，该索引记录的最大长度,它是由这三个部分构成对的:
- 对于使用固定长度类型的索引列来说，实际占用的存储空间的最大长度就是该固定值，对于指定字符集的变长类型的索引列来说，比如某个索引列的类型是`VARCHAR(100)`,使用的是 `utf8` 字符集，那么该列实际占用的最大存储空间就是 `100 * 3 = 300` 个字节
- 如果该索引列可以存储`NULL`值，则`key_len`比不可以存储`NULL`值时多一个字节
- 对于变长字段来说，都会有2个字节的空间来存储该变长列的实际长度

## ref
当使用索引列等值匹配的条件去执行查询时，也就是在访问方法是`const`, `eq_ref`, `ref`,`ref_or_null`,`unique_subquery`,`index_subquery`其中之一时，`ref` 展示的就是与索引列作等值匹配的是什么，比如只是一个常数或者时某个列

```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 = 'a';
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref   | rows | filtered | Extra |
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------+
|  1 | SIMPLE      | s1    | NULL       | ref  | idx_key1      | idx_key1 | 303     | const |    8 |   100.00 | NULL  |
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------+
1 row in set, 1 warning (0.01 sec)
```
`ref`列的值是`const`, 表明在使用 `idx_key1` 索引执行查询时，与 `key1`列作等值匹配的对象是一个常数


```sql
mysql> EXPLAIN SELECT * FROM s1 INNER JOIN s2 ON s1.id = s2.id;
+----+-------------+-------+------------+--------+---------------+---------+---------+-----------------+------+----------+-------+
| id | select_type | table | partitions | type   | possible_keys | key     | key_len | ref             | rows | filtered | Extra |
+----+-------------+-------+------------+--------+---------------+---------+---------+-----------------+------+----------+-------+
|  1 | SIMPLE      | s1    | NULL       | ALL    | PRIMARY       | NULL    | NULL    | NULL            | 9688 |   100.00 | NULL  |
|  1 | SIMPLE      | s2    | NULL       | eq_ref | PRIMARY       | PRIMARY | 4       | xiaohaizi.s1.id |    1 |   100.00 | NULL  |
+----+-------------+-------+------------+--------+---------------+---------+---------+-----------------+------+----------+-------+
2 rows in set, 1 warning (0.00 sec)
```

可以看到对被驱动表`s2`的访问方法是`eq_ref`，而对应的`ref`列的值是`xiaohaizi.s1.id`,说明对被驱动表进行访问时会用到`PRIMARY`索引。
也就是聚簇索引与一个列进行等值匹配的条件，于`s2`表的`id`作等值匹配的对象就是`xiaohaizi.s1.id`

```sql
mysql> EXPLAIN SELECT * FROM s1 INNER JOIN s2 ON s2.key1 = UPPER(s1.key1);
+----+-------------+-------+------------+------+---------------+----------+---------+------+------+----------+-----------------------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref  | rows | filtered | Extra                 |
+----+-------------+-------+------------+------+---------------+----------+---------+------+------+----------+-----------------------+
|  1 | SIMPLE      | s1    | NULL       | ALL  | NULL          | NULL     | NULL    | NULL | 9688 |   100.00 | NULL                  |
|  1 | SIMPLE      | s2    | NULL       | ref  | idx_key1      | idx_key1 | 303     | func |    1 |   100.00 | Using index condition |
+----+-------------+-------+------------+------+---------------+----------+---------+------+------+----------+-----------------------+
2 rows in set, 1 warning (0.00 sec)
```
`ref`的值是`func`,说明`s2`表的`key1`列进行等值匹配的对象是一个函数

## rows
如果查询优化器决定使用全表扫描的方式对某个表执行查询时，执行计划的`rows`列就代表预计扫描的行数
如果使用索引来执行查询时，执行计划的`rows`列就代表预计扫描的索引记录行数
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 > 'z';
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-----------------------+
| id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra                 |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-----------------------+
|  1 | SIMPLE      | s1    | NULL       | range | idx_key1      | idx_key1 | 303     | NULL |  266 |   100.00 | Using index condition |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-----------------------+
1 row in set, 1 warning (0.00 sec)
```

## filtered
在 `what's mysql const`章节，提出过一个 `condition filtering` 的概念
即 `MySQL`在计算驱动表扇出时采用的一个策略
- 如果使用的是全表扫描的方式执行的单表查询，那么计算驱动表时需要估计出满足搜索条件的记录到底有多少条
- 如果使用的是索引执行的单表扫描，那么计算驱动表扇出的时候需要估计出满足除使用到对应索引的搜索条件外的其他搜索条件的记录有多少条

```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 > 'z' AND common_field = 'a';
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+------------------------------------+
| id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra                              |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+------------------------------------+
|  1 | SIMPLE      | s1    | NULL       | range | idx_key1      | idx_key1 | 303     | NULL |  266 |    10.00 | Using index condition; Using where |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+------------------------------------+
1 row in set, 1 warning (0.00 sec)
```
从执行计划的`key`列中可以看出,该查询使用`idx_key1`索引来执行查询，从 `rows`列可以看除满足`key1 > 'z'`的记录有`266`条
执行计划的`filtered`列就代表查询优化器预测在这`266`条记录中，有多少条记录满足其余的搜索条件，也就是 `common_field='a'`这个条件的百分比
此处的 `filtered`列的值是 `10.00`，说明查询优化器预测在 `266`条记录中有`10.00%`的记录满足`common_field='a'`这个条件

注意对于单表查询来讲，这个`filtered`列的值没什么意义
```sql
mysql> EXPLAIN SELECT * FROM s1 INNER JOIN s2 ON s1.key1 = s2.key1 WHERE s1.common_field = 'a';
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+-------------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref               | rows | filtered | Extra       |
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+-------------+
|  1 | SIMPLE      | s1    | NULL       | ALL  | idx_key1      | NULL     | NULL    | NULL              | 9688 |    10.00 | Using where |
|  1 | SIMPLE      | s2    | NULL       | ref  | idx_key1      | idx_key1 | 303     | xiaohaizi.s1.key1 |    1 |   100.00 | NULL        |
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+-------------+
2 rows in set, 1 warning (0.00 sec)
```
从执行计划中可以看出 `s1`是驱动表, `s2`是被驱动表
可以看出驱动表`s1`表的执行计划的`rows`列为`9688`, `filtered`列为`10.00`, 意味着驱动表`s1`的扇出值是`9688 * 10.00% = 968.8`, 这说明还要对被驱动表执行约 `968`次查询 

## Extra
`Extra`列是用来说明一些额外信息的，可以通过额外信息来准确的理解`MySQl`到底将如何执行给定的查询语句
下面介绍一些常用的
- `No tables used`
查询语句没有 `FROM`子句时会提示该额外信息

- `Impossible WHERE`
查询语句的`WHERE`子句永远为`FALSE`时将会提示该额外信息

- `No matching min/max row`
当查询列表处有 `MIN` 或者 `MAX` 聚集函数，但是并没有符合`WHERE`子句中的搜索条件的记录时，将会提示额外信息

- `Using index`
当查询列表以及搜索条件中只包含属于某个索引的列，也就是在可以使用索引覆盖的情况下，在 `Extra`列将会提示该额外信息。
```sql
mysql> EXPLAIN SELECT key1 FROM s1 WHERE key1 = 'a';
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref   | rows | filtered | Extra       |
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------------+
|  1 | SIMPLE      | s1    | NULL       | ref  | idx_key1      | idx_key1 | 303     | const |    8 |   100.00 | Using index |
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------------+
1 row in set, 1 warning (0.00 sec)
```
该查询只需要用到`idx_key1`而不需要回表操作

- `Using index condition`
有些搜索条件中虽然出现了索引列，但是却不能使用索引
```sql
SELECT * FROM s1 WHERE key1 > 'z' AND key1 LIKE '%a';
```
其中的`key1 > 'z'`可以使用到索引，但是`key1 LIKE '%a'` 却无法使用到索引。所以执行步骤如下:
    * 先根据 `key1 > 'z'`这个条件, 定位到二级索引`idx_key1`中对应的二级索引记录
    * 对于指定的二级索引记录，先不急着回表，而是先检测一下该记录是否能满足`key1 LIKE '%a'` 这个条件，如果不满足，那就不用回表了
    * 回表操作

这个操作称为 `索引条件下推(Index Condition Pushdown)`
假如查询语句的执行过程中将要使用`索引条件下推这个特性`,在 `Extra` 列中将会显示 `Using index condition`

- `Using where`
当使用全表扫描来执行对某个表的查询，并且该语句的`WHERE`子句中有针对该表的搜索条件时，在 `Extra`列中会提示上述额外信息
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE common_field = 'a';
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra       |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------------+
|  1 | SIMPLE      | s1    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9688 |    10.00 | Using where |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+-------------+
1 row in set, 1 warning (0.01 sec)
```

当使用索引访问来执行对某个表的查询，并且该语句的`WHERE`子句中有除了该索引包含的列之外的其它搜索条件时，在`Extra`列中也会提示上述额外信息
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 = 'a' AND common_field = 'a';
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref   | rows | filtered | Extra       |
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------------+
|  1 | SIMPLE      | s1    | NULL       | ref  | idx_key1      | idx_key1 | 303     | const |    8 |    10.00 | Using where |
+----+-------------+-------+------------+------+---------------+----------+---------+-------+------+----------+-------------+
1 row in set, 1 warning (0.00 sec)
```
因为搜索条件中有 `common_field` 的字段，因此会出现 `Using where` 的提示

- `Using join buffer(Block Nested Loop)`
参见 `how do query multi table` 中的 `基于块的嵌套循环算法`
```sql
mysql> EXPLAIN SELECT * FROM s1 INNER JOIN s2 ON s1.common_field = s2.common_field;
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------------------------------------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra                                              |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------------------------------------------+
|  1 | SIMPLE      | s1    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9688 |   100.00 | NULL                                               |
|  1 | SIMPLE      | s2    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9954 |    10.00 | Using where; Using join buffer (Block Nested Loop) |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------------------------------------------+
2 rows in set, 1 warning (0.03 sec)
```

对 `s2`的表的访问不能有效利用索引，只好退而求其次,使用 `join buffer`
查询语句中有一个 `s1.common_field = s2.common_field` 条件,因为`s1`是驱动表，`s2`是被驱动表，所以在访问`s2`表时，`s1.common_field`的值以及确定下来了。实际上查询`s2`表的条件就是`s2.common_field = 一个常数`

- `Not exists`
当使用左外连接时，如果 `WHERE`子句中包含要求被驱动表的某个列等于`NULL`值的搜索条件，而且这个列又不允许存储`NULL`值，那么在该表的执行计划的`Extra`列就会提示 `Not exists` 额外信息

```sql
mysql> EXPLAIN SELECT * FROM s1 LEFT JOIN s2 ON s1.key1 = s2.key1 WHERE s2.id IS NULL;
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+-------------------------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref               | rows | filtered | Extra                   |
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+-------------------------+
|  1 | SIMPLE      | s1    | NULL       | ALL  | NULL          | NULL     | NULL    | NULL              | 9688 |   100.00 | NULL                    |
|  1 | SIMPLE      | s2    | NULL       | ref  | idx_key1      | idx_key1 | 303     | xiaohaizi.s1.key1 |    1 |    10.00 | Using where; Not exists |
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+-------------------------+
2 rows in set, 1 warning (0.00 sec)
```
`s1`表是驱动表， `s2`是被驱动表, `s2.id`不允许存 `NULL`,但是搜索条件中又指定了该条件
所以这个查询的意思是要找到所有的不符合 `s1.key1 = s2.key1`的`s1`表的记录
所以对于某条驱动表中的记录来说,如果能在被驱动表中找到一条符合`ON`子句条件的记录，那么该驱动表的记录就不会被加入到最终的结果集，
也即是 `没有必要到被驱动表中找到全部符合ON子句条件的记录`

右连接可以被转化为左连接，所以是一样的

- `Using intersect(...)`, `Using union(...)`, `Using sort_union(...)`
如果执行计划的 `Extra` 列出现了 `Using intersect(...)`提示，说明准备使用 `Intersect` 索引合并的方式执行查询，括号中的 `...` 表示需要进行索引合并的索引名称
如果出现了`Using union(...)`提示,说明准备使用 `Union` 索引合并那个的方式执行查询
如果出现了`Using sort_union(...)`提示，说明准备使用 `Sort-Union` 索引合并的方式执行查询

```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 = 'a' AND key3 = 'a';
+----+-------------+-------+------------+-------------+-------------------+-------------------+---------+------+------+----------+-------------------------------------------------+
| id | select_type | table | partitions | type        | possible_keys     | key               | key_len | ref  | rows | filtered | Extra                                           |
+----+-------------+-------+------------+-------------+-------------------+-------------------+---------+------+------+----------+-------------------------------------------------+
|  1 | SIMPLE      | s1    | NULL       | index_merge | idx_key1,idx_key3 | idx_key3,idx_key1 | 303,303 | NULL |    1 |   100.00 | Using intersect(idx_key3,idx_key1); Using where |
+----+-------------+-------+------------+-------------+-------------------+-------------------+---------+------+------+----------+-------------------------------------------------+
1 row in set, 1 warning (0.01 sec)
```
`Using intersect(idx_key3,idx_key1)` 表明准备使用`idx_key3` 和 `idx_key1` 这两个索引进行`Intersect`索引合并的方式执行查询

- `Zero limit`
假如`Limit`子句的参数为`0`时，会出现该提示
```sql
mysql> EXPLAIN SELECT * FROM s1 LIMIT 0;
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra      |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+------------+
|  1 | SIMPLE      | NULL  | NULL       | NULL | NULL          | NULL | NULL    | NULL | NULL |     NULL | Zero limit |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+------------+
1 row in set, 1 warning (0.00 sec)
```

`Using filesort`
某些情况下对结果集中的记录进行排序是可以使用到索引的
```sql
mysql> EXPLAIN SELECT * FROM s1 ORDER BY key1 LIMIT 10;
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------+
| id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref  | rows | filtered | Extra |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------+
|  1 | SIMPLE      | s1    | NULL       | index | NULL          | idx_key1 | 303     | NULL |   10 |   100.00 | NULL  |
+----+-------------+-------+------------+-------+---------------+----------+---------+------+------+----------+-------+
1 row in set, 1 warning (0.03 sec)
```
这个查询语句可以直接利用`idx_key1`索引直接取出`key1`列的10条记录，然后再进行回表操作就好了。

但是很多时候排序操作无法用到索引。只能在内存中(记录较小的时候)或者磁盘中(记录较多的时候)进行排序, 这个排序方式称之为文件排序(`filesort`)
假如某个查询需要使用文件跑徐的方式执行查询，就会在执行计划的`Extra`列中显示`Using filesort`
```sql
mysql> EXPLAIN SELECT * FROM s1 ORDER BY common_field LIMIT 10;
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra          |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
|  1 | SIMPLE      | s1    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9688 |   100.00 | Using filesort |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+----------------+
1 row in set, 1 warning (0.00 sec)
```
如果使用`filesort`方式进行排序的记录非常多，那这个过程时非常耗费性能的，最后想办法将使用`文件排序`的执行方式改为使用索引进行排序

- `Using temporary`
在许多查询的执行过程中,`MySQL`可能会借助临时表来完成一些功能，比如去重，排序之类的
比如我们在执行许多包含`DISTINCT`, `GROUP BY`,`UNION`等子句的查询过程中，如果不能有效利用索引来完成查询，那么就很有可能会利用到临时表

假如用到了临时表，那么 `Extra`上就会显示`Using temporary`
```sql
mysql> EXPLAIN SELECT common_field, COUNT(*) AS amount FROM s1 GROUP BY common_field;
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+---------------------------------+
| id | select_type | table | partitions | type | possible_keys | key  | key_len | ref  | rows | filtered | Extra                           |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+---------------------------------+
|  1 | SIMPLE      | s1    | NULL       | ALL  | NULL          | NULL | NULL    | NULL | 9688 |   100.00 | Using temporary; Using filesort |
+----+-------------+-------+------------+------+---------------+------+---------+------+------+----------+---------------------------------+
1 row in set, 1 warning (0.00 sec)
```

`GROUP BY`子句默认会加上`ORDER BY` 子句
如果不想要，需要显式指定 `ORDER BY NULL`

出现 `Using temporary` 往往不是好兆头，如果可以的话尽量利用到索引\

- `Start temporary, End temporary`
查询优化器会优先尝试将 `IN` 查询转换为 `semi-join`，而 `semi-join` 又有好多种执行策略。
当执行策略为 `DuplicateWeedout`时，也就是通过建立临时表来实现为外层查询中的记录进行去重操作，驱动表的查询执行计划的 `Extra`列将显示`Start temporary`, 被驱动表查询执行计划的`Extra`列将显示`End temporary`提示
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key1 IN (SELECT key3 FROM s2 WHERE common_field = 'a');
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+------------------------------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref               | rows | filtered | Extra                        |
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+------------------------------+
|  1 | SIMPLE      | s2    | NULL       | ALL  | idx_key3      | NULL     | NULL    | NULL              | 9954 |    10.00 | Using where; Start temporary |
|  1 | SIMPLE      | s1    | NULL       | ref  | idx_key1      | idx_key1 | 303     | xiaohaizi.s2.key3 |    1 |   100.00 | End temporary                |
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+------------------------------+
2 rows in set, 1 warning (0.00 sec)
```

- `LooseScan`
在将 `In` 子查询转为 `semi-join`时，如果采用的是 `LooseScan` 执行策略，则在驱动表执行计划的`Extra`列显示 `LooseScan`
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE key3 IN (SELECT key1 FROM s2 WHERE key1 > 'z');
+----+-------------+-------+------------+-------+---------------+----------+---------+-------------------+------+----------+-------------------------------------+
| id | select_type | table | partitions | type  | possible_keys | key      | key_len | ref               | rows | filtered | Extra                               |
+----+-------------+-------+------------+-------+---------------+----------+---------+-------------------+------+----------+-------------------------------------+
|  1 | SIMPLE      | s2    | NULL       | range | idx_key1      | idx_key1 | 303     | NULL              |  270 |   100.00 | Using where; Using index; LooseScan |
|  1 | SIMPLE      | s1    | NULL       | ref   | idx_key3      | idx_key3 | 303     | xiaohaizi.s2.key1 |    1 |   100.00 | NULL                                |
+----+-------------+-------+------------+-------+---------------+----------+---------+-------------------+------+----------+-------------------------------------+
2 rows in set, 1 warning (0.01 sec)
```

- FirstMatch(tbl_name)
在将 `In` 子查询转为 `semi-join` 时，如果采用的是`FirstMatch`执行策略，则在驱动表执行计划的 `Extra`列就是显示`FirstMatch(tbl_name)`
```sql
mysql> EXPLAIN SELECT * FROM s1 WHERE common_field IN (SELECT key1 FROM s2 where s1.key3 = s2.key3);
+----+-------------+-------+------------+------+-------------------+----------+---------+-------------------+------+----------+-----------------------------+
| id | select_type | table | partitions | type | possible_keys     | key      | key_len | ref               | rows | filtered | Extra                       |
+----+-------------+-------+------------+------+-------------------+----------+---------+-------------------+------+----------+-----------------------------+
|  1 | SIMPLE      | s1    | NULL       | ALL  | idx_key3          | NULL     | NULL    | NULL              | 9688 |   100.00 | Using where                 |
|  1 | SIMPLE      | s2    | NULL       | ref  | idx_key1,idx_key3 | idx_key3 | 303     | xiaohaizi.s1.key3 |    1 |     4.87 | Using where; FirstMatch(s1) |
+----+-------------+-------+------------+------+-------------------+----------+---------+-------------------+------+----------+-----------------------------+
2 rows in set, 2 warnings (0.00 sec)
```

# Json 格式的执行计划
在 `EXPLAIN` 单词和真正的查询语句中间加上 `FORMAT=JSON`
```sql
mysql> EXPLAIN FORMAT=JSON SELECT * FROM s1 INNER JOIN s2 ON s1.key1 = s2.key2 WHERE s1.common_field = 'a'\G
*************************** 1. row ***************************

EXPLAIN: {
  "query_block": {
    "select_id": 1,     # 整个查询语句只有1个SELECT关键字，该关键字对应的id号为1
    "cost_info": {
      "query_cost": "3197.16"   # 整个查询的执行成本预计为3197.16
    },
    "nested_loop": [    # 几个表之间采用嵌套循环连接算法执行
    
    # 以下是参与嵌套循环连接算法的各个表的信息
      {
        "table": {
          "table_name": "s1",   # s1表是驱动表
          "access_type": "ALL",     # 访问方法为ALL，意味着使用全表扫描访问
          "possible_keys": [    # 可能使用的索引
            "idx_key1"
          ],
          "rows_examined_per_scan": 9688,   # 查询一次s1表大致需要扫描9688条记录
          "rows_produced_per_join": 968,    # 驱动表s1的扇出是968
          "filtered": "10.00",  # condition filtering代表的百分比
          "cost_info": {
            "read_cost": "1840.84",     # 稍后解释
            "eval_cost": "193.76",      # 稍后解释
            "prefix_cost": "2034.60",   # 单次查询s1表总共的成本
            "data_read_per_join": "1M"  # 读取的数据量
          },
          "used_columns": [     # 执行查询中涉及到的列
            "id",
            "key1",
            "key2",
            "key3",
            "key_part1",
            "key_part2",
            "key_part3",
            "common_field"
          ],
          
          # 对s1表访问时针对单表查询的条件
          "attached_condition": "((`xiaohaizi`.`s1`.`common_field` = 'a') and (`xiaohaizi`.`s1`.`key1` is not null))"
        }
      },
      {
        "table": {
          "table_name": "s2",   # s2表是被驱动表
          "access_type": "ref",     # 访问方法为ref，意味着使用索引等值匹配的方式访问
          "possible_keys": [    # 可能使用的索引
            "idx_key2"
          ],
          "key": "idx_key2",    # 实际使用的索引
          "used_key_parts": [   # 使用到的索引列
            "key2"
          ],
          "key_length": "5",    # key_len
          "ref": [      # 与key2列进行等值匹配的对象
            "xiaohaizi.s1.key1"
          ],
          "rows_examined_per_scan": 1,  # 查询一次s2表大致需要扫描1条记录
          "rows_produced_per_join": 968,    # 被驱动表s2的扇出是968（由于后边没有多余的表进行连接，所以这个值也没啥用）
          "filtered": "100.00",     # condition filtering代表的百分比
          
          # s2表使用索引进行查询的搜索条件
          "index_condition": "(`xiaohaizi`.`s1`.`key1` = `xiaohaizi`.`s2`.`key2`)",
          "cost_info": {
            "read_cost": "968.80",      # 稍后解释
            "eval_cost": "193.76",      # 稍后解释
            "prefix_cost": "3197.16",   # 单次查询s1、多次查询s2表总共的成本
            "data_read_per_join": "1M"  # 读取的数据量
          },
          "used_columns": [     # 执行查询中涉及到的列
            "id",
            "key1",
            "key2",
            "key3",
            "key_part1",
            "key_part2",
            "key_part3",
            "common_field"
          ]
        }
      }
    ]
  }
}
1 row in set, 2 warnings (0.00 sec)
```

`read_cost`的解释
- `read_cost` 是由下边这两部分组成的:
    * `IO`成本
    * 检测`rows * (1 - filter)` 条记录的 `CPU`成本
- `eval_cost` 是这样计算的:
    检测 `rows_filter` 条记录的成本
- `prefix_cost` 就是单独查询`s1`表的成本,即 `read_cost + eval_cost`
- `data_read_per_join` 表示在此次查询中需要读取的数据量

由于`s2`表是被驱动表，所以可能被读取多次。
这里的`read_cost` 和 `eval_cost` 是访问多次`s2`表后累加起来的值

# Extented EXPLAIN
在使用了 `EXPLAIN` 语句查看了某个查询的执行计划后，紧接着还可以使用 `SHOW WARNINGS` 语句查看与这个查询的执行计划有关的一些拓展信息

```sql
mysql> EXPLAIN SELECT s1.key1, s2.key1 FROM s1 LEFT JOIN s2 ON s1.key1 = s2.key1 WHERE s2.common_field IS NOT NULL;
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+-------------+
| id | select_type | table | partitions | type | possible_keys | key      | key_len | ref               | rows | filtered | Extra       |
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+-------------+
|  1 | SIMPLE      | s2    | NULL       | ALL  | idx_key1      | NULL     | NULL    | NULL              | 9954 |    90.00 | Using where |
|  1 | SIMPLE      | s1    | NULL       | ref  | idx_key1      | idx_key1 | 303     | xiaohaizi.s2.key1 |    1 |   100.00 | Using index |
+----+-------------+-------+------------+------+---------------+----------+---------+-------------------+------+----------+-------------+
2 rows in set, 1 warning (0.00 sec)

mysql> SHOW WARNINGS\G
*************************** 1. row ***************************
  Level: Note
   Code: 1003
Message: /* select#1 */ select `xiaohaizi`.`s1`.`key1` AS `key1`,`xiaohaizi`.`s2`.`key1` AS `key1` from `xiaohaizi`.`s1` join `xiaohaizi`.`s2` where ((`xiaohaizi`.`s1`.`key1` = `xiaohaizi`.`s2`.`key1`) and (`xiaohaizi`.`s2`.`common_field` is not null))
1 row in set (0.00 sec)
```

最常见的就是 `Code` 值为 `1003`
此时， `Message` 字段展示的信息`类似于`查询优化器将我们的查询语句重写后的语句

这个仅供参考