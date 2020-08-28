本章关注 MySql 是如何执行单表查询的

本章分析时使用的表
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
- 为 `id` 建立聚簇索引
- 为 `key1` 列建立的 `idx_key1` 二级索引
- 为 `key2` 列建立的 `idx_key2` 唯一二级索引
- 为 `key3` 列建立的 `idx_key3` 二级索引
- 为 `key_part1 key_part2, key_part3`列建立的 `idx_key_part` 二级联合索引

# 访问方法(access method)的概念
执行查询语句的方式称之为 `访问方法`, 同一个查询语句可以使用多种不同的访问方法来执行

下面是分类
## const 
- 直接使用主键在聚簇索引中查找
- 用唯一二级索引列与常数值的比较

这种情况速度很快，可以认为是常数级的查询

假如主键或者唯一二级索引是由多个列构成的，索引中的每一个列都需要与常数进行等值比较，才是 `const` 类型的

```sql
SELECT * FROM single_table WHERE key2 IS NULL;
```
唯一二级索引列并不限制 NULL 值得数量，所以上述访问语句可能找到多条语句，所以这个是不能使用 `const` 访问方法来执行得。

## ref
普通二级索引与常数进行等值比较
```sql
SELECT * FROM single_table WHERE key1 = 'abc';
```
这种搜索条件为二级索引与常数等值比较，采用二级索引来执行查询得访问方法称为 `ref`
因为 这种方法对于普通得二级索引来说，可能匹配到多条连续得记录，而不是像主键或者唯一二级索引那样最多只能匹配搭配1条记录，所以效率会低一点
但是如果二级索引匹配到的记录比较少的话，效率还行
### 注意
- 二级索引为 `NULL` 的时候
不论是普通的二级索引，还是唯一的二级索引，索引列对 `NULL`值得数量都不限制。所以采用 `key is NULL` 这种形式的搜索条件最多只能使用 `ref`的访问方法

- 对于某些包含多个索引列的二级索引来说，只要是最左边的连续索引列是与常数的等值比较就可能采用 `ref`的访问方法
```sql
SELECT * FROM single_table WHERE key_part1 = 'god like';

SELECT * FROM single_table WHERE key_part1 = 'god like' AND key_part2 = 'legendary';

SELECT * FROM single_table WHERE key_part1 = 'god like' AND key_part2 = 'legendary' AND key_part3 = 'penta kill';
```
这种则不行， 因为最左边的连续索引列并不全是等值比较
```sql
SELECT * FROM single_table WHERE key_part1 = 'god like' AND key_part2 > 'legendary';
```

## ref_of_null
不仅想找出某个二级索引列的值等于某个常数的记录，还想把该列的值为`NULL`的记录也找出来时
```sql
SELECT * FROM single_table WHERE key1 = 'abc' OR key1 IS NULL;
```
当使用二级索引而不是全表扫描的方式执行该查询时，这种类型的查询使用的访问方法就称为`ref_or_null`

## range
当搜索条件比较复杂的时候
```sql
SELECT * FROM single_table WHERE key2 IN (1438, 6328) OR (key2 >= 38 AND key2 <= 79);
```
除了全表扫描，也可以使用 `二级索引+回表`的方式执行
这种理由索引进行范围匹配的访问方法称之为 `range`

## index
```sql
SELECT key_part1, key_part2, key_part3 FROM single_table WHERE key_part2 = 'abc';
```
`key_part2` 并不是 `idex_key_part` 最左边的索引，所以无法使用 `ref` 或者 `range` 访问方法来执行这个语句，但是这个查询符合这2个条件
- 查询子句只有三个列: `key_part1, key_part2, key_part3`，都包括在 `idx_key_part` 索引内
- 搜索条件中只有`key_part2`列，这个列也包含在索引`idx_key_part`中

那么就可以直接遍历二级索引而不用回表。
这种直接遍历二级索引记录的方式就称为 `index`

## all
全表扫描就是 `all`


# 注意事项
## 二级索引 + 回表
一般情况下只能利用单个二级索引执行查询 （有特殊情况, 见 `索引合并`）
```sql
SELECT * FROM single_table WHERE key1 = 'abc' AND key2 > 1000;
```
查询优化器会识别到这个查询中的两个搜索条件:
- key1 = 'abc'
- key2 > 1000

优化器之后就会根据 `single_table` 表的统计数据来判断到底使用哪个条件到对应的二级索引中查询扫描的行数更少 
TODO （后文地址）
一般来说，等值查找(`ref`)会比范围扫描(`range`)的行数更少
所以这里会分2个阶段
- 使用二级索引定位记录的阶段： 根据条件`key1='abc'` 从 `idx_key1` 索引代表的`B+`树中找到对应的二级索引记录
- 回表阶段: 根据上一步步骤找到的记录的主键值进行`回表`操作，之后再根据 `key2 > 1000`到完整的用户记录继续过滤

## 明确range访问方法使用的范围区间

对于 `B+` 树索引来说，只要索引列和常数使用 `=`, `<=>`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `>`, `<`, `>=`, `<=`, `BETWEEN`, `!=`或者 `LIKE`操作符连接起来，就可以产生一个所谓的`区间`

PS: `LIKE`操作符只有在匹配完整字符串或者匹配字符串前缀时才可以利用索引
`IN` 操作符的效果和若干个等值匹配操作符`=`之间用`OR连接起来是一样的

当想使用 `range` 访问方法执行一个查询语句时，重点就是找出该查询可用的索引以及这些索引对应额范围区间
下边分两种情况看一下怎么从由`AND`或`OR`组成的复杂搜索条件中提取出正确的范围区间
TODO 方法论，看情况补完，也就是分析会不会使用索引查询，会使用哪个索引进行查询

## 索引合并
在某些特殊情况下，也有可能在一个查询中使用到多个所及索引
这种使用到多个索引来完成一次查询的执行方法称为 `index merge`, 具体的索引合并算法有下边三种

### Intersection 合并
也就是某个查询可以使用多个二级索引，将从多个二级索引中查询到的结果取交集
```sql
SELECT * FROM single_table WHERE key1 = 'a' AND key3 = 'b';
```
使用 `Intersection` 合并的方式执行的过程是这样的
- 从 `idx_key1` 二级索引对应的 `B+`树中取出`key1 = 'a'`的相关记录
- 从 `idx_key3` 二级索引对应的 `B+` 树中取出 `key3='b'`的相关记录
- 取上述2个步骤的结果的主键交集
- 根据上一步得到的id的集合进行回表操作

那么为什么不再使用一个索引后直接回表呢？
读取二级索引的操作是 `顺序I/O`， 而回表操作是 `随机I/O`
因为如果只读取一个二级索引后，需要回表的记录特别多，而读取两个二级索引之后取交集的记录数非常少，那么 `节省的回表操作`会比多发生的一次`二级索引查询`损耗的性能更多，所以可以使用多个二级索引

#### MySql 在某些特定的情况下才会使用 `Intersection` 索引合并

- 二级索引列是等值匹配的情况，对于联合索引来说，在联合索引中的每个列都必须等值匹配，不能出现只匹配部分列的情况
```sql
# 这个可以
SELECT * FROM single_table WHERE key1 = 'a' AND key_part1 = 'a' AND key_part2 = 'b' AND key_part3 = 'c';

# 这2个不行
# 这个是范围匹配，而不是等值匹配
SELECT * FROM single_table WHERE key1 > 'a' AND key_part1 = 'a' AND key_part2 = 'b' AND key_part3 = 'c';

# 联合索引 idx_key_part 中的 key_part2 和 key_part3 列没有出现在搜索条件中，因此不行
SELECT * FROM single_table WHERE key1 = 'a' AND key_part1 = 'a';
```

- 主键列可以是范围匹配
```sql
# 这个查询可能用到主键和 `idx_key1` 进行 `Intersection` 索引合并的操作
SELECT * FROM single_table WHERE id > 100 AND key1 = 'a';
```
`InnoDB`的二级索引是按照 `索引列 + 主键` ，所以当索引列的值是相同的时候, 这些记录最后就会按照`主键`顺序排序。
所以，之所以二级索引列都是在等值匹配的情况下才可能使用 `Intersection`索引合并，是因为`只有在这种情况下根据二级索引查询出的结果集是按照主键值排序的`

主键值在已经排好序的情况下，求交集的效率很高，不然就要排序再取交集

上述的两种情况只是发生 `Intersection` 索引合并的必要条件
就算是上面2种情况，也只有在，根据某个搜索条件从二级索引中取出的记录数太多，回表开销很大，而通过 `Intersection` 索引合并

### Union合并

使用 `OR` 关系的搜索条件，并用到不同的索引的情况
```sql
SELECT * FROM single_table WHERE key1 = 'a' OR key3 = 'b'
```

#### 使用`UNION`合并 的情况
- 二级索引列是等值匹配的情况，对于联合索引来说，在联合索引中的每个列都必须等值匹配，不能出现只匹配部分列的情况

```sql
# 用到了 idx_key1 和 idex_key_part 这两个索引，所以可以
SELECT * FROM single_table WHERE key1 = 'a' OR ( key_part1 = 'a' AND key_part2 = 'b' AND key_part3 = 'c');

# 不是等值匹配，所以不行
SELECT * FROM single_table WHERE key1 > 'a' OR (key_part1 = 'a' AND key_part2 = 'b' AND key_part3 = 'c');

# idx_key_part 未用到全部索引列，所以不行
SELECT * FROM single_table WHERE key1 = 'a' OR key_part1 = 'a';
```

- 主键列可以范围匹配, 索引列还是必须是等值匹配
- 使用 `Intersection` 索引合并的搜索条件
```sql
# 搜索条件的某些部分使用 Intersection 索引合并
# 索引合并后得到了主键集合
# 再和其它方式得到的主键集合取交集
SELECT * FROM single_table WHERE key_part1 = 'a' AND key_part2 = 'b' AND key_part3 = 'c' OR (key1 = 'a' AND key3 = 'b');
```

在上述情况下设备也不一定会按照 `Union` 索引合并。
只有在单独根据搜索条件从某个二级索引中获取的记录数较小，通过 `Union`索引合并后进行访问的代价比全表扫描少时才会使用。

### Sort-Union 合并
使用很苛刻，比较保证各个二级索引在进行等值匹配的条件下才可能被用到

```sql
# 这个不会使用 `Union`查询，因为，两个条件查询出的的记录并不是按照主键排序的
# 但是可以分别查询出来后进行排序，再 `UNION`
SELECT * FROM single_table WHERE key1 < 'a' OR key3 > 'z'
```

就是比 `Union` 多了一步 排序

#### 为什么没有 Sort-Intersection
Sort-Union的适用场景是单独根据搜索条件从某个二级索引中获取的记录数比较少，这样即使排序成本也不会太高，就可以使用

intersection 合并的适用场景是单独根据搜索条件从某个二级索引里记录太多，合并后可以减少回表成本才使用，所以既然记录很多，那排序成本就太高了。

### 索引合并注意事项
#### 联合索引替代 Intersection 索引合并

```sql
SELECT * FROM single_table WHERE key1 = 'a' AND key3 = 'b';
```
假如 key1 和 key3 是一个联合索引，那就不需要索引合并了，可以考虑


