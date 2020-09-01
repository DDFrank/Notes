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
## 子查询再MySQL中是怎么执行的