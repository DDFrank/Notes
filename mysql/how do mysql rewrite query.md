本章主要探讨`查询重写`的问题
介绍一些比较重要的重写规则

# 条件从简
## 移除不必要的括号
```sql
((a = 5 AND b = c) OR ((a > c) AND (c < 5)))
```
这里就有些无用的括号，就会默认去掉

```sql
(a = 5 and b = c) OR (a > c AND c < 5)
```
## 常量传递 (constant_propagation)
有时候某个表达式是和某个常量做等值匹配。
当上述表达式和其它涉及该变量的表达式使用`AND`连接时, 可以直接将变量的值替换为常量

```
a = 5 AND b > a => a = 5 AND b > 5
```

## 等值传递 (equality_propagation)
有时候多个列之间存储等值匹配的关系
```
a = b and b = c and c = 5 => a = 5 and b = 5 and c = 5
```

## 移除没用的条件(trivial_condition_removal)
对于一些明显永远为 `TRUE` 或者 `FALSE` 的表达式，优化器会移除它们
```
(a < 1 and b = b) OR (a = 6 OR 5 != 5) => a < 1 OR a = 6
```

## 表达式计算
查询开始前，如果表达式中只包含有常量的话，它的值会被先计算出来
```
a = 5 + 1 => a = 6
```

注意: 如果某个列并不是以单独的形式作为表达式的操作数时，比如在函数中
```
ABS(a) > 5
```
那么优化器是不会尝试对这些表达式进行化简的

## HAVING子句和WHERE子句的合并
如果查询语句中没有出现诸如`SUM`,`MAX`等等聚集函数以及`GROUP BY`子句，优化器就把`HAVING`子句和`WHERE`子句合并起来。

## 常量表检测
有2种查询是被认为特别快的
- 查询的表种一条记录没有，或者只有一条记录
这个因为依赖于统计数据来判断，而`InnoDB`的统计数据不太准确，所以这一条不能用于`innodb` 的存储引擎的表
- 使用主键等值匹配或者唯一二级索引匹配作为搜索条件来查询某个表

因为这两种查询花费的时间很少，少到几乎可以忽略，所以这两种方式查询的表称之为`常量表(constant tables)`。
优化器在分析一个查询语句时，先首先执行常量表查询，然后把查询中涉及到该表的条件全部替换成常数，然后再分析其余表的查询成本
比如:
```sql
SELECT * FROM table1 INNER JOIN table2
    ON table1.column1 = table2.column2 
    WHERE table1.primary_key = 1;
```
那么最后就会被替换为
```sql
SELECT table1表记录的各个字段的常量值, table2.* FROM table1 INNER JOIN table2 
    ON table1表column1列的常量值 = table2.column2;
```

## 外连接消除
`内连接`的驱动表和被驱动表的位置可以相互连接，而`左(外连接)` 和 `右(外)连接`的驱动表和被驱动表是固定的。
这就导致`内连接`可能通过优化表连接顺序来降低整体的查询成本，而 `外连接`却无法优化表的连接顺序。

在外连接查询中，指定的 `WHERE` 子句中包含被驱动表中的列不为`NULL`值得条件称之为`空值拒绝`(`reject-NULL`)。
- 在 `WHERE` 子句中指定被驱动表的字段不为`NULL`
```sql
SELECT * FROM t1 LEFT JOIN t2 ON t1.m1 = t2.m2 WHERE t2.n2 IS NOT NULL;
```
```sql
SELECT * FROM t1 LEFT JOIN t2 ON t1.m1 = t2.m2 WHERE t2.m2 = 2;
```

在被驱动表的`WHERE`子句符合空值拒绝的条件后，外连接和内连接可以相互转换。
这种转换带来的好处就是`查询优化器可以通过评估表的不同连接顺序的成本，选出成本最低的那种连接顺序来执行查询`

# 子查询优化
## 子查询语法
子查询可以在外层查询的各个位置出现
- `SELECT` 子句
```sql
SELECT (SELECT m1 FROM t1 LIMIT 1)
```

- `FROM` 子句中
```sql
# 查询的结果相当于一个`派生表`
SELECT m, n FROM (SELECT m2 + 1 AS m, n2 AS n FROM t2 WHERE m2 > 2) AS t;
```

- `where` 或 `ON` 子句中
```sql
SELECT * FROM t1 WHERE m1 IN (SELECT m2 FROM t2)
```

- `ORDER BY` 子句和 `GROUP BY` 子句，无意义

### 按返回的结果集区分子查询
- 标量子查询
只返回一个单一值得子查询称之为`标量子查询`
```sql
SELECT (SELECT m1 FROM t1 LIMIT 1);

SELECT * FROM t1 WHERE m1 = (SELECT MIN(m2) FROM t2);
```
也就是仅有一行一列的结果

- 行子查询
返回一条记录的子查询，只不过该条记录需要包含多个列
```sql
SELECT * FROM t1 WHERE (m1, n1) = (SELECT m2, n2 FROM t2 LIMIT 1);
```

- 列子查询
列子查询就是查询出一个列的数据，不过这个列的数据需要包含多条记录
```sql
SELECT * FROM t1 WHERE m1 IN (SELECT m2 FROM t2);
```

- 表子查询
子查询的结果既包含很多记录，又包含很多个列
```sql
SELECT * FROM t1 WHERE (m1, n1) IN (SELECT m2, n2 FROM t2);
```

### 按与外层查询关系来区分子查询
- 不相关子查询
如果子查询可以单独运行出结果，而不依赖于外层查询的值，就可以把这个子查询称之为`不相关子查询`。之前介绍的那些子查询全部可以看作不相关子查询

- 相关子查询
子查询的执行依赖于外层查询的值，称为`相关子查询`
```sql
SELECT * FROM t1 WHERE m1 IN (SELECT m2 FROM t2 WHERE n1 = n2);
```

### 子查询在布尔表达式中的使用
平常使用子查询最多的地方就是把它作为布尔表达式的一部分来作为搜索条件用在`WHERE`或者`ON`子句里
#### 使用 `=, <, <, >=, <=, <>, !=, <=>` 作为布尔表达式的操作符(`comparison_operator`)
子查询组成的布尔表达式就是长这样
```
操作数 comparison_operator (子查询)
```
这里的子查询只能是标量子查询或者行子查询，也就是子查询的结果只能返回一个单一的值或者只能是一条记录
```sql
SELECT * FROM t1 WHERE m1 < (SELECT MIN(m2) FROM t2);

SELECT * FROM t1 WHERE (m1, n1) = (SELECT m2, n2 FROM t2 LIMIT 1);
```

#### \[NOT\] IN/ANY/SOME/ALL子查询
对于列子查询和表子查询来说，它们的结果集中包含很多条记录，相当于是一个集合。
`MySQL` 通过下面的语法来支持某个操作数和一个集合组成一个布尔表达式

- `IN` 或者 `NOT IN`

```sql
SELECT * FROM t1 WHERE (m1, n1) IN (SELECT m2, n2 FROM t2);
```

- `ANY/SOME` (`ANY` 和 `SOME`是同义词)
只要结果集中存在某个值和给定的操作数的 `comparison_operator` 比较结果为`TRUE`，那么整个表达式的结果就为`TRUE`

```sql
SELECT * FROM t1 WHERE m1 > ANY(SELECT m2 FROM t2);

# 本质上等于这个sql
SELECT * FROM t1 WHERE m1 > (SELECT MIN(m2) FROM t2);
```

`=ANY相当于判断子查询结果集中是否存在某个值和给定的操作数相等，它的含义和IN是相同的`

- `ALL`
表示查询结果集中所有的值和给定的操作数做 `comparison_operator` 比较结果为 `TRUE`，那么整个表达式的结果为 `TRUE`

```sql
SELECT * FROM t1 WHERE m1 > ALL(SELECT m2 FROM t2);

# 本质上等于这个sql
SELECT * FROM t1 WHERE m1 > (SELECT MAX(m2) FROM t2);
```

#### EXISTS子查询
有时候仅仅需要判断子查询的结果集中是否有记录，而不在乎它的记录具体是什么，可以使用 `EXISTS` 或者 `NOT EXISTS` 放在子查询语句前边
```
[NOT] EXISTS (子查询)
```

```sql
SELECT * FROM t1 WHERE EXISTS (SELECT 1 FROM t2);
```

### 子查询语法注意事项
- 子查询必须用小括号括起来
- 在 `SELECT` 子句中的子查询必须是标量子查询
- 在想要得到标量子查询或者行子查询，但又不能保证子查询的结果集只有一条记录时，应该使用 `LIMIT 1` 语句来限制记录数量
- 对于 `[NOT] IN/ANY/SOME/ALL` 子查询来说，子查询中不允许 `LIMIT` 语句
- 下面这些语句在子查询中是多余的
    * `ORDER BY` 子句
    * `DISTINCT` 语句
    * 没有聚集函数以及`HAVING`子句的`GROUP BY`子句
- 不允许在一条语句中增删改某个表的记录时同时还对该表进行子查询
```sql
# 这样是不行的
DELETE FROM t1 WHERE m1 < (SELECT MAX(m1) FROM t1);
```

## 子查询再MySQL中是怎么执行的
接下里使用的s1, s2 表均为该结构
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

### 标量子查询，行子查询的执行方式
经常在以下场景中使用到标量子查询或者行子查询
- `SELECT` 子句中的子查询必须是标量子查询
- 子查询使用`=`,`>`,`<`,`>=`,`<=`,`<>`, `!=`, `<=>` 等操作符和某个操作数组成一个布尔表达式

#### 对于不相关的标量子查询或者行子查询

```sql
SELECT * FROM s1 
    WHERE key1 = (SELECT common_field FROM s2 WHERE key3 = 'a' LIMIT 1);
```

- 先单独执行 `SELECT common_field FROM s2 WHERE key3 = 'a' LIMIT 1` 这个子查询
- 然后将上一步子查询得到的结果当作外层查询的参数再执行外层查询`SELECT * FROM s1 WHERE key1 = ...`

也就是说，`对于包含不相关的标量子查询或者行子查询的查询语句来说，MySQL会分别独立的执行外层查询和子查询,相当于2个单表查询`

#### 对于相关的标量子查询或者行子查询
```sql
SELECT * FROM s1 WHERE 
    key1 = (SELECT common_field FROM s2 WHERE s1.key3 = s2.key3 LIMIT 1);
```
执行方式
- 先从外层查询中获取一条记录 (s1 表中的一条记录)
- 从上一步骤中获取的那条记录中找出子查询中涉及的值，本例中就是从 `s1` 表中获取的那条记录中找出 `s1.key3` 列的值，然后执行子查询
- 最后根据子查询的查询结果来检测外层查询`WHERE`子句的条件是否成立，如果成立，就把外层查询的那条记录加入到结果集，否则丢弃
- 循环往复


### IN子查询优化
#### 物化表
对于不相关的`IN`子查询来说，如果子查询的结果集中的记录条数很少，那么把子查询和外层查询分别看成两个单独的单表查询效率还是蛮高的。但是如果子查询后的结果集中数据太多，就会非常影响性能

当不相关子查询的结果集中数据太多的时候，不会直接将该结果集当作外层查询的参数，而是将该结果集写入到一个临时表
- 该临时表的列就是子查询结果集中的列。
- 写入临时表的记录会被去重(可以减少占用的空间)
- 一般情况下子查询结果集不会特别大，所以会为其建立基于内存的使用 `Memory` 存储引擎的临时表，并为该表建立哈希索引
- 如果子查询的结果集非常大，查过了系统变量 `tmp_table_size` 或者 `max_heap_table_size`, 临时表会转而使用基于磁盘的存储引擎来保存结果集中的记录，索引类型也对应转变为 `B+` 树索引。
这个过程称之为 `物化(Materialize)`
因为`物化表`中的记录都建立了索引，通过索引执行 `IN` 语句执行查询就比较快了

#### 物化表转连接
将子查询的结果集物化后
```sql
SELECT * FROM s1 
    WHERE key1 IN (SELECT common_field FROM s2 WHERE key3 = 'a');

# 就相当于和物化表进行内连接
SELECT s1.* FROM s1 INNER JOIN materialized_table ON key1 = m_val;
```

转换为内连接后，查询优化器可以评估不同连接顺序需要的成本是多少，选取成本最低的那种查询方式执行查询
- 如果使用 `s1` 表作为驱动表的话，总查询成本由下边几个部分组成
    * 物化子查询时需要的成本
    * 扫描 `s1` 表时需要的成本
    * s1 表中的记录数量 x 通过 `m_val = xxx` 对 `materialized_table` 表进行单表访问的成本(物化表中的记录不会重复，而且列都建立了索引，所以这个步骤很快)
- 如果使用 `materialized_table` 表作为驱动表的话，总查询成本由下边几个部分组成:
    * 物化子查询时需要的成本
    * 扫描物化表时的成本
    * 物化表中的记录数量 * 通过 `key1 = xxx` 对 `s1` 表进行单表访问的成本(`key1` 列上建立了索引的话，1这个步骤就比较快)

### 将子查询转换为 semi-join
还是这个
```sql
SELECT * FROM s1 
    WHERE key1 IN (SELECT common_field FROM s2 WHERE key3 = 'a');
```

对于在 `s1` 表中的某条记录，假如能在 `s2` 表(执行完 WHERE 子句后的结果集)中找到一条或多条记录,这些 `common_field`的值等于 `s1` 表记录的 `key1`列的值，那么该条`s1`表的记录就会被加入2到最终的结果集，所以这个过程挺像连接两个表的
```sql
SELECT s1.* FROM s1 INNER JOIN s2 
    ON s1.key1 = s2.common_field 
    WHERE s2.key3 = 'a';
```
跟连接的场景不一样的是，其实s1表中的某条记录能匹配上s2表中具体多少条记录是不关心的，只要至少有一条，那么就能满足需求。
所以，这里其实`MySQL` 会使用一个叫 `半连接(semi-join)`的语法 
也即是, `对于s1表的某条记录来说，只关心在 s2 表中是否hi存在与之匹配的记录，而不关心具体有多少条记录与之匹配，最终的结果集中只保留s1表的记录`

```sql
SELECT s1.* FROM s1 SEMI JOIN s2
    ON s1.key1 = s2.common_field
    WHERE key3 = 'a';
```

#### 如何实现 semi-join
- Table pullout(子查询中的表上拉)
当`子查询的查询列表处只有主键或者唯一索引列`时, 可以直接把子查询中的表`上拉`到外层查询的`FROM`子句中, 并把子查询中的搜索条件合并到外层查询的搜索条件中
```sql
SELECT * FROM s1 
    WHERE key2 IN (SELECT key2 FROM s2 WHERE key3 = 'a');
```
`key2`列是`s2`表的唯一二级索引列，所以可以直接把 `s2`表上拉到外层查询的 `FROM` 子句中
```sql
# 因为唯一索引中的数据本来就是不重复的，所以不用担心会匹配到多条记录
SELECT s1.* FROM s1 INNER JOIN s2 
    ON s1.key2 = s2.key2 
    WHERE s2.key3 = 'a';
```

- DuplicateWeedout execution strategy (重复值消除)
对于这个查询
```sql
SELECT * FROM s1 
    WHERE key1 IN (SELECT common_field FROM s2 WHERE key3 = 'a');
```

转换为半连接后, `s1` 表中的某条记录可能在 `s2` 表中由多条匹配的记录, 所以需要消除重复
为了消除重复，需要建一个临时表，比如说
```sql
CREATE TABLE tmp (
    id PRIMARY KEY
);
```

每次匹配上的 `s1` 表中的记录要加入结果集时，就先通过临时表去重
这种通过临时表来去重的方式称之为`DuplicateWeedout`

- LooseScan execution strategy (松散扫描)
```sql
SELECT * FROM s1 
    WHERE key3 IN (SELECT key1 FROM s2 WHERE key1 > 'a' AND key1 < 'b');
```
对于`s2`表的访问可以使用到`key1`列的索引，而恰好子查询的查询列表处就是`key1`列，所以可以直接扫描`key1`列的索引
而在 `s2` 的 `idx_key1` 索引值中，如果碰到相同的记录，那么只需要取第一条的值到`s1`表中查找`s1.key3 = 'aa'`的记录
这种虽然时扫描索引，但只取值相同的记录的第一条去做匹配操作的方式称之为`松散扫描`

- FirstMatch execution strategy (首次匹配)
最原始的方式, 先取一条外层查询的记录，然后到子查询的表中寻找符合匹配条件的记录，循环

#### semi-join 的适用条件
- 该子查询必须和 `IN` 语句组成布尔表达式，并且再外层查询的`WHERE`或者`ON`子句中出现
- 外层查询也可以有其它的搜索条件，只不过和`IN`子查询的搜索条件必须使用`AND`连接起来
- 该子查询必须是一个单一的查询，不能是由若干查询由`UNION`连接起来的形式
- 该子查询不能包含`GROUP BY` 或者 `HAVING` 语句或者聚集函数

形如:
```sql
SELECT ... FROM outer_tables 
    WHERE expr IN (SELECT ... FROM inner_tables ...) AND ...

SELECT ... FROM outer_tables 
    WHERE (oe1, oe2, ...) IN (SELECT ie1, ie2, ... FROM inner_tables ...) AND ...
```

#### 不适用于semi-join的情况
- 外层查询的`WHERE`条件中有搜索条件与`IN`子查询组成的布尔表达式使用`OR`连接起来
```sql
SELECT * FROM s1 
    WHERE key1 IN (SELECT common_field FROM s2 WHERE key3 = 'a')
        OR key2 > 100;
```

- 使用`NOT IN` 而不是 `IN`的情况
```sql
SELECT * FROM s1 
    WHERE key1 NOT IN (SELECT common_field FROM s2 WHERE key3 = 'a')
```

- 在 `SELECT` 子句中的`IN`子查询的情况
```sql
SELECT key1 IN (SELECT common_field FROM s2 WHERE key3 = 'a') FROM s1 ;
```

- 子查询中包含`GROUP BY`, `HAVING`或者聚集函数的情况
```sql
SELECT * FROM s1 
    WHERE key2 IN (SELECT COUNT(*) FROM s2 GROUP BY key1);
```

- 子查询中包含`UNION`的情况
```sql
SELECT * FROM s1 WHERE key1 IN (
    SELECT common_field FROM s2 WHERE key3 = 'a' 
    UNION
    SELECT common_field FROM s2 WHERE key3 = 'b'
);
```

#### 不适用于 `semi-join`的优化策略
- 对于不相关子查询来说，可以尝试物化之后再参与查询
```sql
SELECT * FROM s1 
    WHERE key1 NOT IN (SELECT common_field FROM s2 WHERE key3 = 'a')
```
这个即使物化了也不能转化为连接，因为是 `NOT IN`

- 对于任意的`IN`子查询来说，都可以转为`EXISTS`子查询
```sql
outer_expr IN (SELECT inner_expr FROM ... WHERE subquery_where)
```
可以被转为
```sql
EXISTS (SELECT inner_expr FROM ... WHERE subquery_where AND outer_expr=inner_expr)
```

### ANY/ALL子查询优化
如果ANY/ALL子查询是不相关子查询的话，很多场合都能转换为属性的方式去执行
可以转换为 `MAX` 或 `MIN` 函数

### [NOT] EXISTS子查询的执行
如果 `[NOT] EXISTS` 子查询是不相关子查询，可以先执行子查询，得出该`[NOT] EXISTS` 子查询的结果是 `TRUE`还是 `FALSE`, 并重写原先的查询语句
```sql
SELECT * FROM s1 
    WHERE EXISTS (SELECT 1 FROM s2 WHERE key1 = 'a') 
        OR key2 > 100;

# 假设子查询的结果为 true
SELECT * FROM s1 
    WHERE TRUE OR key2 > 100;

# 进一步简化为
SELECT * FROM s1
    WHERE TRUE;
```

相关的子查询则不能如此进行，不过还是可以尽量使用索引

### 派生表的优化

假如把子查询放在外层查询的`FROM`子句后，那么这个子查询的结果相当于一个`派生表`
```sql
SELECT * FROM  (
        SELECT id AS d_id,  key3 AS d_key3 FROM s2 WHERE key1 = 'a'
    ) AS derived_s1 WHERE d_key3 = 'a';
```
对于含有`派生表`的查询，`MySQL`提供了两种执行策略

#### 派生表物化
对派生表的物化并不是直接物化，而是`延迟物化`，真正用到的时候才去尝试物化派生表
```sql
SELECT * FROM (
        SELECT * FROM s1 WHERE key1 = 'a'
    ) AS derived_s1 INNER JOIN s2
    ON derived_s1.key1 = s2.key1
    WHERE s2.key2 = 1;
```
执行时会先到 `s2`表中找出满足`s2.key2 = 1` 的记录，如果找不到，那么就没必要物化了

#### 合并派生表和外层的表
也即是重写为没有派生表的形式
```sql
SELECT * FROM (SELECT * FROM s1 WHERE key1 = 'a') AS derived_s1;

# 会被重写为
SELECT * FROM s1 WHERE key1 = 'a';
```

比较复杂的
```sql
SELECT * FROM (
        SELECT * FROM s1 WHERE key1 = 'a'
    ) AS derived_s1 INNER JOIN s2
    ON derived_s1.key1 = s2.key1
    WHERE s2.key2 = 1;
```

重写为
```sql
SELECT * FROM s1 INNER JOIN s2 
    ON s1.key1 = s2.key1
    WHERE s1.key1 = 'a' AND s2.key2 = 1;
```

当派生表中有这些语句就不可以和外层查询合并:
- 聚集函数，比如 MAX(), MIN(), SUM()
- DISTINCT
- GROUP BY
- HAVING
- LIMIT
- UNION 或者 UNION ALL
- 派生表对应的子查询子句中有另一个子查询


