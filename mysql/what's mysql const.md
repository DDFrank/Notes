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

