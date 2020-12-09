# 事务id
一个事务可以是一个只读事务，或者是一个读写事务:
- 可以通过START TRANSACTION READ ONLY语句开启一个只读事务
在只读事务中不可以对普通的表（其他事务也能访问到的表）进行增、删、改操作，但可以对临时表做增、删、改操作

- 可以通过START TRANSACTION READ WRITE语句开启一个读写事务，或者使用BEGIN、START TRANSACTION语句开启的事务默认也算是读写事务
在读写事务中可以对表执行增删改查操作

如果某个事务执行过程中对某个表执行了增、删、改操作，那么`InnoDB`存储引擎就会给它分配一个独一无二的`事务id`，分配方式如下:
- 对于只读事务来说，只有在它第一次对某个用户创建的临时表执行增、删、改操作时才会为这个事务分配一个`事务id`，否则的话是不分配`事务id`的
- 对于读写事务来说，只有在它第一次对某个表（包括用户创建的临时表）执行增、删、改操作时才会为这个事务分配一个`事务id`，否则的话也是不分配`事务id`的

## 事务id的生成方式
本质上就是一个数字，和`row_id`的生成分配策略类似:
- 服务器会在内存中维护一个全局变量，每当需要为某个事务分配一个`事务id`时，就会把该变量的值当作`事务id`分配给该事务，并且把该变量自增1
- 每当这个变量的值为`256`的倍数时，就会将该变量的值刷新到系统表空间的页号为`5`的页面中一个称之为`Max Trx ID`的属性处，这个属性占用`8`个字节的存储空间
- 当系统下一次重新启动时，会将上边提到的`Max Trx ID`属性加载到内存中，将该值加上`256`之后赋值给前边提到的全局变量（因为在上次关机时该全局变量的值可能大于`Max Trx ID`属性值）

## trx_id 隐藏列
聚簇索引的记录除了会保存完整的用户数据以外，而且还会自动添加名为`trx_id`、`roll_pointer`的隐藏列，如果用户没有在表中定义主键以及`UNIQUE`键，还会自动添加一个名为`row_id`的隐藏列

- `trx_id` 就是这个聚簇索引记录做改动的语句所在的事务对应的`事务id`而已
- `roll_pointer` 详见后文


# undo日志的格式
- 为了实现事务的原子性，InnoDB存储引擎在实际进行增、删、改一条记录时，都需要先把对应的`undo`日志记下来。一般每对一条记录做一次改动，就对应着一条或多条`undo`日志。
- 这些`undo`日志是被记录到类型为`FIL_PAGE_UNDO_LOG`（对应的十六进制是0x0002, 详见表空间章节）的页面中。这些页面可以从系统表空间中分配，也可以从一种专门存放`undo`日志的表空间，也就是所谓的`undo tablespace`中分配

## INSERT操作对应的undo日志
- 向表中插入一条记录时会有`乐观插入`和`悲观插入`的区分，但是不管怎么插入，最终导致的结果就是这条记录被放到了一个数据页中。
- 如果希望回滚这个插入操作，那么把这条记录删除就好了，也就是说在写对应的undo日志时，主要是把这条记录的主键信息记上

### TXR_UNDO_INSERT_REC 的`undo`日志结构
- `end of record`: 本条`undo`日志结束, 下一条开始时在页面中的地址
- `undo type`: 本条`undo`日志类型, 值就是 `TXR_UNDO_INSERT_REC`
- `undo no`: 本条`undo`日志对应的编号
- `table id`: 本条`undo` 日志对应的记录所在表的 `table id`
- `主键各列信息`: 主键的每个列占用的存储空间大小和真实值
- `start of record`: 上一条`undo`日志结束,本条开始时在页面中的地址

### TXR_UNDO_INSERT_REC 的相关注意事项
- `undo no` 在一个事务中是从`0`开始递增的, 也就是说只要事务没提交，每生成一条`undo`日志，那么该条日志的`undo no`就增`1`
- 如果记录中的主键只包含一个列，那么在类型为`TRX_UNDO_INSERT_REC`的`undo`日志中只需要把该列占用的存储空间大小和真实值记录下来;如果记录中的主键包含多个列，那么每个列占用的存储空间大小和对应的真实值都需要记录下来
- 向某个表中插入一条记录时，实际上需要向聚簇索引和所有的二级索引都插入一条记录。不过记录undo日志时，只需要考虑向聚簇索引插入记录时的情况就好了。因为其实聚簇索引记录和二级索引记录是一一对应的，在回滚插入操作时，只需要知道这条记录的主键信息，然后根据主键信息做对应的删除操作，做删除操作时就会顺带着把所有二级索引中相应的记录也删除掉

### roll_pointer隐藏列的含义
- 本质上就是一个指向记录对应的`undo`日志的一个指针
- 像某个表插入记录时，每条记录都有与其对应的一条`undo`日志
- 记录被存储到了类型为`FIL_PAGE_INDEX`的页面中（也就是`数据页`）
- `undo`日志被存放到了类型为`FIL_PAGE_UNDO_LOG`的页面中

## DELETE 操作对应的日志
- 插入到页面中的记录会根据记录头信息中的`next_record`属性组成一个单向链表,称之为`正常记录链表`
- 被删除的记录也会根据记录头信息中的`next_record`属性组成一个链表，只不过这个链表中的记录占用的存储空间可以被重新利用，所以称这个链表为`垃圾链表`
- `Page Header`部分有一个称之为`PAGE_FREE`的属性，它指向由被删除记录组成的垃圾链表中的头节点

### DELETE 语句删除记录的步骤
- 将记录的`delete_mask`标识位设置为1，其他的不做修改（其实会修改记录的`trx_id`、`roll_pointer`这些隐藏列的值）。这个阶段称之为`delete mark`
此时记录处于一个`中间状态`, 没有被加入`垃圾链表`, 在删除语句所在的事务提交之前，被删除的记录一直都处于这种所谓的`中间状态` (这种中间状态是为了实现 `MVCC`的功能)
- 当该删除语句所在的事务提交之后，会有·专门的线程后·来真正的把记录删除掉。即是该记录从正常记录链表中移除，并且加入到垃圾链表中，然后还要调整一些页面的其他信息，比如页面中的用户记录数量`PAGE_N_RECS`、上次插入记录的位置`PAGE_LAST_INSERT`、垃圾链表头节点的指针`PAGE_FREE`、页面中可重用的字节数量`PAGE_GARBAGE`、还有页目录的一些信息。这个阶段称之为`purge`
- 将删除记录加入到`垃圾链表`时, 实际上加入到链表的头节点处，会跟着修改`PAGE_FREE`属性的值

在删除语句所在的事务提交之前，只会经历`delete mark`阶段，
所以只需考虑对删除操作的阶段一做的影响进行回滚）。`InnoDB`为此提供了一种称之为`TRX_UNDO_DEL_MARK_REC`类型的`undo`日志

### TRX_UNDO_DEL_MARK_REC 的结构
- `end of record`: 本条`undo`日志结束, 下一条开始时在页面中的地址
- `undo type`: 本条`undo`日志类型, 值就是 `TXR_UNDO_INSERT_REC`
- `undo no`: 本条`undo`日志对应的编号
- `table id`: 本条`undo` 日志对应的记录所在表的 `table id`
- `info bits`: 记录头信息的前`4`个比特位的值以及`record_type`的值
- `old_trx_id`: 记录旧的`trx_id`值
- `old_roll_pointer`: 记录旧的`roll_pointer`值
- `主键各列信息`: 主键的每个列占用的存储空间大小和真实值
- `index_col_info_len`: 也就是 `索引各列信息`部分和本部分占用的存储空间大小
- `索引各列信息: <pos,len,value>`: 凡是被索引的列的各列信息
- `start of record`: 上一条`undo`日志结束,本条开始时在页面中的地址

### 注意事项
- 在对一条记录进行`delete mark`操作前，需要把该记录的旧的`trx_id`和`roll_pointer`隐藏列的值都给记到对应的`undo`日志中来，就是结构中的的`old trx_id`和`old roll_pointer`属性。这样有一个好处，那就是可以通过`undo`日志的`old roll_pointer`找到记录在修改之前对应的`undo`日志。
所以,执行完`delete mark`操作后，它对应的`undo`日志和`INSERT`操作对应的`undo`日志就串成了一个链表, 这个称之为`版本链`

- 与类型为`TRX_UNDO_INSERT_REC`的`undo`日志不同，类型为`TRX_UNDO_DEL_MARK_REC`的`undo`日志还多了一个索引列各列信息的内容，也就是说如果某个列被包含在某个索引中，那么它的相关信息就应该被记录到这个索引列各列信息部分，所谓的相关信息包括该列在记录中的位置（用`pos`表示），该列占用的存储空间大小（用`len`表示），该列实际值（用`value`表示）。所以索引列各列信息存储的内容实质上就是<`pos`, `len`, `value`>的一个列表。这部分信息主要是用在事务提交后，对该中间状态记录做真正删除的阶段二，也就是`purge`阶段中使用的

## UPDATE操作对应的undo日志
在执行 `UPDATE` 语句时，`InnoDB` 对更新主键和不更新主键这两种情况有不同的处理方案

### 不更新主键的情况
不更新主键，又可以细分为被更新的列占用的存储空间不发生变化和发生变化的情况

- 就地更新(in-place update)
更新记录时，对于被更新的每个列来说，如果更新后的列和更新前的列占用的存储空间都一样大，那么就可以进行就地更新，也就是直接在原记录的基础上修改对应列的值。
必须是每个列在更新前后占用的存储空间一样大，有任何一个被更新的列更新前比更新后占用的存储空间`大`，或者更新前比更新后占用的存储空间`小`都不能进行就地更新

- 先删除掉旧记录，再插入新记录
在不更新主键的情况下，如果有任何一个被更新的列更新前和更新后占用的存储空间大小`不一致`，那么就需要先把这条旧的记录从聚簇索引页面中`删除`掉，然后再根据更新后列的值`创建`一条新的记录插入到页面中。

这里提到的`删除`不是`delete mark`操作,而是真正的删除，也就是把这条记录从`正常记录链表`中移除并加入到`垃圾链表`中，并且修改页面中相应的统计信息（比如`PAGE_FREE`、`PAGE_GARBAGE`等这些信息）
不过这里做真正删除操作的线程不是`DELETE`语句中`purge`操作时使用的专门的线程，而是由用户线程同步执行真正的删除操作，删除后紧接着就要根据各个列更新后的值创建新的记录插入。

这里如果新创建的记录占用的存储空间大小不超过旧记录占用的空间，那么可以直接重用被加入到`垃圾链表`中的旧记录所占用的存储空间，否则的话需要在页面中新申请一段空间以供新记录使用，如果本页面内已经没有可用的空间的话，那就需要进行页面分裂操作，然后再插入新记录

对于不更新主键的`UPDATE`语句，`MySQL`提供了一种类型为`TRX_UNDO_UPD_EXIST_REC`的`undo日志`

#### TRX_UNDO_UPD_EXIST_REC 的结构
- `end of record`: 本条`undo`日志结束, 下一条开始时在页面中的地址
- `undo type`: 本条`undo`日志类型, 值就是 `TXR_UNDO_INSERT_REC`
- `undo no`: 本条`undo`日志对应的编号
- `table id`: 本条`undo` 日志对应的记录所在表的 `table id`
- `info bits`: 记录头信息的前`4`个比特位的值以及`record_type`的值
- `old_trx_id`: 记录旧的`trx_id`值
- `old_roll_pointer`: 记录旧的`roll_pointer`值
- `主键各列信息`: 主键的每个列占用的存储空间大小和真实值
- `n_updated`: 共有多少个列被更新了
- `被更新列更新前信息 <pos, old_len, old_value>列表`: 被更新的列更新前信息 
- `index_col_info_len`: 也就是 `索引各列信息`部分和本部分占用的存储空间大小
- `索引各列信息: <pos,len,value>`: 凡是被索引的列的各列信息
- `start of record`: 上一条`undo`日志结束,本条开始时在页面中的地址

#### 结构的注意事项
- `n_updated`属性表示本条`UPDATE`语句执行后将有几个列被更新，后边跟着的`<pos, old_len, old_value>`分别表示被更新列在记录中的位置、更新前该列占用的存储空间大小、更新前该列的真实值
- 如果在`UPDATE`语句中更新的列包含索引列，那么也会添加`索引列各列信息`这个部分，否则的话是不会添加这个部分的

### 更新主键的情况
在聚簇索引中，记录是按照主键值的大小连成了一个单向链表的，如果我们更新了某条记录的主键值，意味着这条记录在聚簇索引中的位置将会发生改变

针对`UPDATE`语句中更新了记录主键值的这种情况，`InnoDB`在聚簇索引中分了两步处理:
- 将旧记录进行`delete mark`操作
和 不更新主键时的删除旧纪录，再插入新纪录的方式有区别
之所以只对旧记录做`delete mark`操作，是因为别的事务同时也可能访问这条记录，如果把它真正的删除加入到垃圾链表后，别的事务就访问不到了(MVCC功能)

- 根据更新后各列的值创建一条新记录，并将其插入到聚簇索引中（需重新定位插入的位置）
由于更新后的记录主键值发生了改变，所以需要重新从聚簇索引中定位这条记录所在的位置，然后把它插进去

针对`UPDATE`语句更新记录主键值的这种情况，在对该记录进行`delete mark`操作前，会记录一条类型为`TRX_UNDO_DEL_MARK_REC`的`undo`日志；之后插入新记录时，会记录一条类型为`TRX_UNDO_INSERT_REC`的undo日志，也就是说每对一条记录的主键值做改动时，会记录`2`条`undo`日志。

# 通用链表结构
在写入`undo`日志的过程中会使用到多个链表,很多链表都有同样的节点结构

- `Prev Node Page Number(4字节)`: 前一个节点的页号
- `Prev Node Offset(2字节)`: 前一个节点的偏移量
- `Next Node Page Number(4字节)`: 后一个节点的页号
- `Next Node Offset(2字节)`: 后一个节点的偏移量

在某个表空间内，可以通过一个页的页号和在页内的偏移量来唯一定位一个节点的位置，这两个信息也就相当于指向这个节点的一个指针。所以:
- `Pre Node Page Number` 和 `Pre Node Offset` 的组合就是指向前一个节点的指针
- `Next Node Page Number`和`Next Node Offset`的组合就是指向后一个节点的指针

整个`List Node`占用`12`个字节的存储空间

为了更好的管理链表，`InnoDB`还提供基节点的结构，里边存储了这个链表的`头节点`、`尾节点`以及`链表长度`信息
结构如下:
- `List Length(4字节)`: 表明该链表一共有多少节点
- `First Node Page Number`和`First Node Offset`的组合就是指向链表头节点的指针
- `Last Node Page Number`和`Last Node Offset`的组合就是指向链表尾节点的指针
总共占用 `16` 个字节

# FIL_PAGE_UNDO_LOG页面
`FIL_PAGE_UNDO_LOG`类型的页面是专门用来存储`undo`日志的, 其结构如下
- `File Header`: 通用页头
- `Undo Page Header`: 特有的结构
- `Body`: 存放真正的 `undo` 日志
- `File Trailer`: 通用页尾

## Undo Page Header
结构如下:
- `TRX_UNDO_PAGE_TYPE`: 本页面准备存储什么种类的 `undo日志`
    * `TRX_UNDO_INSERT`（使用十进制`1`表示）：类型为`TRX_UNDO_INSERT_REC`的`undo`日志属于此大类，一般由`INSERT`语句产生，或者在`UPDATE`语句中有更新主键的情况也会产生此类型的undo日志
    *  `TRX_UNDO_UPDATE`（使用十进制`2`表示），除了类型为`TRX_UNDO_INSERT_REC`的`undo`日志，其他类型的`undo`日志都属于这个大类，比如我们前边说的`TRX_UNDO_DEL_MARK_REC`、`TRX_UNDO_UPD_EXIST_REC`啥的，一般由`DELETE`、`UPDATE`语句产生的`undo`日志属于这个大类

PS: 之所以把`undo`日志分成两个大类，是因为类型为`TRX_UNDO_INSERT_REC`的`undo`日志在事务提交后可以直接删除掉，而其他类型的`undo`日志还需要为所谓的`MVCC`服务，不能直接删除掉，对它们的处理需要区别对待

- `TRX_UNDO_PAGE_START`：表示在当前页面中是从什么位置开始存储`undo`日志的，或者说表示第一条`undo`日志在本页面中的起始偏移量

- `TRX_UNDO_PAGE_FREE`：与上边的`TRX_UNDO_PAGE_START`对应，表示当前页面中存储的最后一条`undo`日志结束时的偏移量，或者说从这个位置开始，可以继续写入新的`undo`日志

- `TRX_UNDO_PAGE_NODE`：代表一个`List Node`结构

# Undo页面链表
## 单个事务中的Undo页面链表
因为一个事务可能包含多个语句，而且一个语句可能对若干条记录进行改动，而对每条记录进行改动前，都需要记录`1`条或`2`条的`undo`日志，所以在一个事务执行过程中可能产生很多`undo`日志，这些日志可能一个页面放不下，需要放到多个页面中，这些页面就通过上边介绍的`TRX_UNDO_PAGE_NODE`属性连成了链表

第一个 `Undo页面` 中除了记录`Undo Page Header`之外，还会记录其他的一些管理信息，称之为`first undo page`, 其余的`Undo页面`称之为`normal undo page`

在一个事务执行过程中，可能混着执行`INSERT、DELETE、UPDATE`语句，也就意味着会产生不同类型的`undo`日志。
同一个Undo页面要么只存储`TRX_UNDO_INSERT`大类的`undo`日志，要么只存储`TRX_UNDO_UPDATE`大类的`undo`日志，不能混着存。
所以在一个事务执行过程中就可能需要`2`个`Undo`页面的链表，一个称之为`insert undo`链表，另一个称之为`update undo`链表
另外 `InnoDB`的规定对普通表和临时表的记录改动时产生的undo日志要分别记录, 所以在一个事务中最多有`4`个以`Undo页面`为节点组成的链表

### Undo页面4个链表的分配策略
- 刚刚开启事务时，一个`Undo`页面链表也不分配
- 当事务执行过程中向普通表中插入记录或者执行更新记录主键的操作之后，就会为其分配一个`普通表的insert undo链表`
- 当事务执行过程中删除或者更新了普通表中的记录之后，就会为其分配一个`普通表的update undo链表`
- 当事务执行过程中向临时表中插入记录或者执行更新记录主键的操作之后，就会为其分配一个`临时表的insert undo链表`
- 当事务执行过程中删除或者更新了临时表中的记录之后，就会为其分配一个`临时表的update undo链表`
总结就是按需分配

## 多个事务中的Undo页面链表
为了尽可能提高undo日志的写入效率，不同事务执行过程中产生的undo日志需要被写入到不同的Undo页面链表中

举个例子

说现在有事务`id`分别为`1`、`2`的两个事务，我们分别称之为`trx 1`和`trx 2`，假设在这两个事务执行过程中:
- trx 1对普通表做了DELETE操作，对临时表做了INSERT和UPDATE操作,会分配3个链表
    * 针对普通表的`update undo链表`
    * 针对临时表的`insert undo链表`
    * 针对临时表的`update undo链表`

- trx 2对普通表做了INSERT、UPDATE和DELETE操作，没有对临时表做改动,会分配2个链表
    * 针对普通表的`insert undo链表`
    * 针对普通表的`update undo`链表

所以综上，`InnoDB` 就需要为这2个事务分配5个`Undo页面`链表

# undo 日志具体写入过程
## Segment
详见 表空间那章关于段的
## Undo Log Segment Header
`InnoDB` 规定: 
- 每一个`Undo页面`链表都对应着一个`段`，称之为`Undo Log Segment`。
- 链表中的页面都是从上述`段`中申请的
- `Undo页面`链表的第一个页面，也就是上边提到的`first undo page`中设计了一个称之为`Undo Log Segment Header`的部分，这个部分中包含了该链表对应的段的`segment header`信息以及其他的一些关于这个段的信息

### Undo Log Segment Header 页面的结构
- `TRX_UNDO_STATE`: 本`Undo页面`链表处于什么状态
    * `TRX_UNDO_ACTIVE`：活跃状态，也就是一个活跃的事务正在往这个段里边写入`undo`日志 
    * `TRX_UNDO_CACHED`：被缓存的状态。处在该状态的`Undo`页面链表等待着之后被其他事务重用
    * `TRX_UNDO_TO_FREE`：对于`insert undo`链表来说，如果在它对应的事务提交之后，该链表不能被重用，那么就会处于这种状态
    * `TRX_UNDO_TO_PURGE`：对于`update undo`链表来说，如果在它对应的事务提交之后，该链表不能被重用，那么就会处于这种状态
    * `TRX_UNDO_PREPARED`：包含处于`PREPARE`阶段的事务产生的`undo`日志 (分布式事务才会用到，此处不会涉及)   

- `TRX_UNDO_LAST_LOG`：本`Undo页面`链表中最后一个`Undo Log Header`的位置
- `TRX_UNDO_FSEG_HEADER`: 本`Undo页面`链表对应的段的`Segment Header`信息
- `TRX_UNDO_PAGE_LIST`: `Undo页面`链表的基节点

上边说`Undo页面`的`Undo Page Header`部分有一个12字节大小的`TRX_UNDO_PAGE_NODE`属性，这个属性代表一个`List Node`结构。每一个`Undo`页面都包含`Undo Page Header`结构，这些页面就可以通过这个属性连成一个链表。这个`TRX_UNDO_PAGE_LIST`属性代表着这个链表的基节点，当然这个基节点只存在于`Undo页面`链表的第一个页面，也就是`first undo page`中

## Undo Log Header
- 一个事务在向`Undo`页面中写入`undo`日志时的方式是很直接的，写完一条紧接着写另一条，各条undo日志之间是紧密相连的。
- 写完一个`Undo页面`后，再从段里申请一个新页面，然后把这个页面插入到`Undo页面`链表中，继续往这个新申请的页面中写。
- 同一个事务向一个`Undo页面`链表中写入的`Undo`日志算是一个组

比方说上边介绍的`trx 1`由于会分配`3`个`Undo页面`链表，也就会写入`3`个组的`undo`日志；`trx 2`由于会分配`2`个`Undo`页面链表，也就会写入`2`个组的`undo`日志。
在每写入一组`undo`日志时，都会在这组`undo`日志前先记录一下关于这个组的一些属性，`InnoDB`把存储这些属性的地方称之为`Undo Log Header`。
所以`Undo`页面链表的第一个页面在真正写入`undo`日志前，其实都会被填充`Undo Page Header`、`Undo Log Segment Header`、`Undo Log Header`这3个部分

### Undo log Header 的结构
- `TRX_UNDO_TRX_ID`: 生成本组undo日志的事务id
- `TRX_UNDO_TRX_NO`: 事务提交后生成的一个需要序号，使用此序号来标记事务的提交顺序（先提交的此序号小，后提交的此序号大）
- `TRX_UNDO_DEL_MARKS`: 标记本组`undo`日志中是否包含由于`Delete mark`操作产生的`undo`日志
- `TRX_UNDO_LOG_START`: 表示本组`undo`日志中第一条`undo`日志的在页面中的偏移量
- `TRX_UNDO_XID_EXISTS`: 本组`undo`日志是否包含`XID`信息(不会涉及)
- `TRX_UNDO_DICT_TRANS`: 标记本组`undo`日志是不是由`DDL`语句产生的
- `TRX_UNDO_TABLE_ID`: 如果`TRX_UNDO_DICT_TRANS`为真，那么本属性表示`DDL`语句操作的表的`table id`
- `TRX_UNDO_NEXT_LOG`: 下一组的`undo`日志在页面中开始的偏移量
- `TRX_UNDO_PREV_LOG`: 上一组的`undo`日志在页面中开始的偏移量
一般来说一个`Undo页面`链表只存储一个事务执行过程中产生的一组`undo`日志，但是在某些情况下，可能会在一个事务提交之后，之后开启的事务重复利用这个`Undo页面`链表，这样就会导致一个`Undo页面`中可能存放多组Undo日志，`TRX_UNDO_NEXT_LOG`和`TRX_UNDO_PREV_LOG`就是用来标记下一组和上一组`undo`日志在页面中的偏移量的

- `TRX_UNDO_HISTORY_NODE`：一个`12`字节的`List Node`结构，代表一个称之为`History`链表的节点

# 重用Undo页面
某了避免页面浪费，在事务提交后在某些情况下重用该事务的`Undo页面`链表
## 一个Undo页面链表是否可以被重用的条件:
- 该链表中只包含一个`Undo页面`

如果一个事务执行过程中产生了非常多的`undo`日志，那么它可能申请非常多的页面加入到`Undo`页面链表中。在该事务提交后，如果将整个链表中的页面都重用，那就意味着即使新的事务并没有向该`Undo`页面链表中写入很多`undo`日志，那该链表中也得维护非常多的页面，那些用不到的页面也不能被别的事务所使用，这样就造成了另一种浪费

- 该`Undo`页面已经使用的空间小于整个页面空间的3/4
    * `insert undo`链表
    `insert undo`链表中只存储类型为`TRX_UNDO_INSERT_REC`的`undo`日志，这种类型的`undo`日志在事务提交之后就没用了，就可以被清除掉。所以在某个事务提交后，重用这个事务的`insert undo`链表（这个链表中只有一个页面）时，可以直接把之前事务写入的一组`undo`日志覆盖掉，从头开始写入新事务的一组`undo`日志

    * `update undo`链表
    在一个事务提交后，它的`update undo`链表中的`undo`日志也不能立即删除掉（这些日志用于`MVCC`，详见相关章节）。所以如果之后的事务想重用`update undo`链表时，就不能覆盖之前事务写入的`undo`日志。这样就相当于在同一个`Undo`页面中写入了多组的`undo`日志

# 回滚段
## 概念
一个事务在执行过程中最多可以分配`4`个`Undo页面`链表，在同一时刻不同事务拥有的`Undo页面`链表是不一样的，所以在同一时刻系统里其实可以有许许多多个`Undo页面`链表存在。为了更好的管理这些链表，`InnoDB`设计了一个称之为`Rollback Segment Header`的页面，在这个页面中存放了各个`Undo页面`链表的`frist undo page`的页号，他们把这些页号称之为`undo slot`

## `Rollback Segment Header`的页面及结构
- 每个`Rollback Segment Header` 页面都对应着一个段，这个段就称为`Rollback Segment`，即`回滚段`
- 这个`Rollback Segment`中其实只有一个页面

### 结构
- `File Header`(38字节): 通用页头
- `TRX_RSEG_MAX_SIZE`(4字节)：本`Rollback Segment`中管理的所有`Undo页面`链表中的`Undo页面`数量之和的最大值。即，本`Rollback Segment`中所有`Undo页面`链表中的`Undo页面`数量之和不能超过`TRX_RSEG_MAX_SIZE`代表的值(默认值不限，只受4个字节大小限制)
- `TRX_RSEG_HISTORY_SIZE：History`(4字节): `History`链表占用的页面数量
- `TRX_RSEG_HISTORY`(16字节): `History`链表的基节点
- `TRX_RSEG_FSEG_HEADER`(10字节): 本`Rollback Segment`对应的`10`字节大小的`Segment Header`结构，通过它可以找到本段对应的`INODE Entry`
- `TRX_RSEG_UNDO_SLOTS`(4096字节): 各个`Undo`页面链表的`first undo page`的页号集合，也就是`undo slot`集合
- 空余空间,即无用空间
- `File Trailer`(8字节): 通用页尾

## 从回滚段中申请Undo页面链表
- 初始情况下，由于未向任何事务分配任何`Undo页面`链表, 所以对于一个`Rollback Segment Header`页面来说，它的各个`undo slot`都被设置成了一个特殊的值: `FIL_NULL`（十六进制就是`0xFFFFFFFF`）, 表示该`undo slot` 不指向任何页面

- 需要分配`Undo页面`链表时，就开始遍历`回滚段`的`undo slot`, 看看该`undo slot`的值是不是`FIL_NULL`:
    * 如果是 `FIL_NULL`, 那么在表空间中新创建一个段(即`Undo Log Segment`), 然后从段里申请一个页面作为`Undo页面`链表的`first undo page`, 然后把该`undo slot`的值设置为刚刚申请的这个页面的页号，这样也就意味着这个`undo slot`被分配给了这个事务
    * 如果不是`FIL_NULL`，说明该`undo slot`已经指向了一个`undo`链表，也就是说这个`undo slot`已经被别的事务占用了，那就跳到下一个`undo slot`，判断该`undo slot`的值是不是`FIL_NULL`，重复上边的步骤

一个`Rollback Segment Header`页面中包含`1024`个`undo slot`，如果这`1024`个`undo slot`的值都不为`FIL_NULL`，这就意味着这1024个`undo slot`都已被分配给了某个事务，此时由于新事务无法再获得新的`Undo`页面链表，就会回滚这个事务并且给用户报错
```txt
Too many active concurrent transactions
```

## 事务提交时，undo slot 的变化
- 如果该`undo slot`指向的`Undo页面`链表符合被重用的条件(参见上文)
该`undo slot`就处于被缓存的状态，`InnoDB`的规定这时该`Undo`页面链表的`TRX_UNDO_STATE`属性（该属性在`first undo page`的`Undo Log Segment Header`部分）会被设置为`TRX_UNDO_CACHED`

被缓存的`undo slot`都会被加入到一个链表，根据对应的`Undo页面`链表的类型不同，也会被加入到不同的链表
* 如果对应的`Undo页面`链表是`insert undo`链表，则该`undo slot`会被加入`insert undo cached`链表
* 如果对应的`Undo页面`链表是`update undo`链表，则该`undo slot`会被加入`update undo cached`链表

- 如果该undo slot指向的Undo页面链表不符合被重用的条件
    * 如果对应的`Undo页面`链表是`insert undo`链表，则该`Undo页面`链表的`TRX_UNDO_STATE`属性会被设置为`TRX_UNDO_TO_FREE`，之后该`Undo页面`链表对应的段会被释放掉（也就意味着段中的页面可以被挪作他用），然后把该`undo slot`的值设置为`FIL_NULL`
    * 如果对应的`Undo页面`链表是`update undo`链表，则该`Undo页面`链表的`TRX_UNDO_STATE`属性会被设置为`TRX_UNDO_TO_PRUGE`，则会将该`undo slot`的值设置为`FIL_NULL`，然后将本次事务写入的一组`undo`日志放到所谓的`History`链表中

## 多个回滚段
- `InnoDB` 中一共定义了`128`个回滚段, 所以一共支持`128 × 1024 = 131072`个`undo slot`
- 每个回滚段都有一个`Rollback Segment Header`页面，有`128`个回滚段，自然就要有`128`个`Rollback Segment Header`页面
- 这些`回滚段`的引用存在系统表空间的`5`号页面的某个区域中(128个8字节的空间)

8字节的空间的结构
- `4`字节大小的`Space ID`，代表一个表空间的ID (说明不同的回滚段可能分布在不同的表空间中)
- `4`字节大小的`Page number`，代表一个页号

## 回滚段的分类
- 第`0`号,第`33~127`号回滚段属于一类。其中第`0`号回滚段必须在系统表空间中, 第`33~127`回滚段既可以在系统表空间中，也可以在自己配置的`undo`表空间中
如果一个事务在执行过程中由于对普通表的记录做了改动需要分配`Undo`页面链表时，必须从这一类的段中分配相应的`undo slot`

- 第`1～32`号回滚段属于一类。这些回滚段必须在临时表空间（对应着数据目录中的`ibtmp1`文件)中
如果一个事务在执行过程中由于对临时表的记录做了改动需要分配`Undo`页面链表时，必须从这一类的段中分配相应的`undo slot`

即如果一个事务在执行过程中既对普通表的记录做了改动，又对临时表的记录做了改动，那么需要为这个记录分配`2`个回滚段，再分别到这两个回滚段中分配对应的`undo slot`

在修改针对普通表的回滚段中的`Undo`页面时，需要记录对应的`redo`日志，而修改针对临时表的回滚段中的`Undo`页面时，不需要记录对应的`redo`日志, 所以要区分开

## 为事务分配Undo页面链表详细过程
- 事务在执行过程中对普通表的记录首次做改动之前，首先会到系统表空间的第`5`号页面中分配一个回滚段（其实就是获取一个`Rollback Segment Header`页面的地址）。一旦某个回滚段被分配给了这个事务，那么之后该事务中再对普通表的记录做改动时，就不会重复分配了

- 在分配到回滚段后，首先看一下这个回滚段的两个`cached链表`有没有已经缓存了的`undo slot`
比如如果事务做的是`INSERT`操作，就去回滚段对应的`insert undo cached链表`中看看有没有缓存的`undo slot`；如果事务做的是`DELETE`操作，就去回滚段对应的`update undo cached`链表中看看有没有缓存的`undo slot`。如果有缓存的`undo slot`，那么就把这个缓存的`undo slot`分配给该事务

- 如果没有缓存的`undo slot`可供分配，那么就要到`Rollback Segment Header`页面中找一个可用的`undo slot`分配给当前事务
从`Rollback Segment Header`页面中分配可用的`undo slot`的方式就是简单的遍历，就是从第`0`个`undo slot`开始，如果该`undo slot`的值为`FIL_NULL`，意味着这个`undo slot`是空闲的，就把这个`undo slot`分配给当前事务，否则查看第`1`个`undo slot`是否满足条件，依次类推，直到最后一个`undo slot`。如果这`1024`个`undo slot`都没有值为`FIL_NULL`的情况，就直接报错

- 找到可用的`undo slot`后，如果该`undo slot`是从`cached`链表中获取的，那么它对应的`Undo Log Segment`已经分配了，否则的话需要重新分配一个`Undo Log Segment`，然后从该`Undo Log Segment`中申请一个页面作为`Undo页面`链表的`first undo page`

- 然后事务就可以把`undo日志`写入到上边申请的`Undo页面`链表了

如果一个事务在执行过程中既对普通表的记录做了改动，又对临时表的记录做了改动，那么需要为这个记录分配`2`个回滚段。并发执行的不同事务其实也可以被分配相同的回滚段，只要分配不同的`undo slot`就可以了


## 回滚段相关的配置
### 配置回滚段数量
- 系统中一共有`128`个回滚段，这只是默认值。
- 可以通过启动参数`innodb_rollback_segments`来配置回滚段的数量，可配置的范围是`1~128`
- 这个参数并不会影响针对临时表的回滚段数量，针对临时表的回滚段数量一直是`32`

### 配置undo表空间
默认情况下，针对普通表设立的回滚段（第`0`号以及第`33~127`号回滚段）都是被分配到系统表空间的。其中的第`0`号回滚段是一直在系统表空间的，但是第`33~127`号回滚段可以通过配置放到自定义的`undo`表空间中。但是这种配置只能在系统初始化（创建数据目录时）的时候使用，一旦初始化完成，之后就不能再次更改了
- 通过`innodb_undo_directory`指定`undo表空间`所在的目录，如果没有指定该参数，则默认`undo表空间`所在的目录就是数据目录
- 通过`innodb_undo_tablespaces`定义`undo表空间`的数量。该参数的默认值为`0`，表明不创建任何`undo表空间`

第`33~127`号回滚段可以平均分布到不同的`undo`表空间中

设立undo表空间的一个好处就是在`undo表空间`中的文件大到一定程度时，可以自动的将该`undo表空间`截断（truncate）成一个小文件。而系统表空间的大小只能不断的增大，却不能截断



