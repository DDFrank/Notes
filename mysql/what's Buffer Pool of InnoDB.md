## 基本定义
为了缓冲磁盘中的`页`，在`MySQL`服务器启动的时候就向操作系统申请了一片连续的内存，就是 `Buffer Pool`
默认大小是`128M`，可以配置

```properties
[server]
innodb_buffer_pool_size = 268435456
```

## 内部组成
- `Buffer Pool` 中默认的缓存页大小和在磁盘上默认的页大小是一样的，都是 `16KB`。
- 为了更好的管理这些`Buffer Pool`中的缓存页，设计者为每一个缓存页都创建了一些`控制信息`
- 每个缓存页对应的控制信息占用的内存大小是相同的，其占用的内存称为`控制块`
- 控制块和缓存页一一对应,都被存放到 `Buffer Pool` 中，其中控制块被存放到 `Bufffer Pool` 的前边，缓存页被存放到 `Buffer Pool`后边
- 每个控制块大约占用缓存页大小的 `5%`, 参数的 `innodb_buffer_pool_size`并不包含这个大小，所以 `MySQL`大概会申请比 `innodb_buffer_pool_size`的值大`5%`左右的内存

## free链表的管理
- 启动`MySQL`服务器的时候，需要完成对`Buffer Pool`的初始化过程。就是先向操作系统申请`Buffer Pool`的内存空间，然后划分成若干对控制块和缓存页
- 初始化刚完成的时候，并没有真实的磁盘空间被缓存到`Buffer Pool`中,随着程序的运行，不断的有磁盘上的页被缓存到`Buffer Pool` 中
-为了记录 `Buffer Pool` 中哪些缓存页是可以用的，`所有空闲的缓存页对应的控制块作为一个节点被放置到了一个链表中`， 这就是`free链表`
- 刚刚完成初始化的`Buffer Pool` 中所有的缓存页都是空闲的，所以每一个缓存页对应的控制块都会被加入到`free链表`中
- 为了方便管理，`free链表`有一个基节点，里边包含着链表的头节点地址，尾节点地址，以及当前链表中节点的数量等信息。
- `基节点`占用的内存空间并不包含在为`Buffer Pool`申请的一大片连续内存空间之内，而是单独申请的一块内存空
- `free`链表成功形成后，每当需要从磁盘中加载一个页到`Buffer Pool` 中时，就从 `free`链表中取一个空闲的缓存页,并且把该缓存页对应的`控制块`的信息填上(就是该页所在的表空间，页号之类)的信息, 再把该缓存页对应的`free链表`节点中链表中移除，表示该缓存页以及被使用了

## 缓存页的哈希处理
- 当需要访问某个页中的数据时，就会把该页从磁盘加载到`Buffer Pool`中
- 那么如何知道要访问的页面是否已经在`Buffer Pool` 了呢？依靠的是`表空间号 + 页号`来定位一个页的, 也就是说 缓存页的 `key` 就是 `表空间号 + 页号`
- 那么访问缓存页的时候，就是先用`表空间号 + 页号` 取哈希表中查看是否有对应的缓存页，如果有，就直接选用。没有，就去`free链表`中选一个空闲的缓存页，然后把磁盘中对应的页加载到该缓存页的位置。

## flush 链表的管理
- 如果修改了`Buffer Pool`中某个缓存页中的数据，那它就和磁盘上的不一致了，这样的缓存页称为`脏页（dirty page）`
- 每次修改缓存页后，不会立即将修改同步到磁盘上，而是在未来某个时间点同步(TODO，后续说明)
- 为了说明哪个缓存页是脏页，凡是修改过的缓存页对应的控制块都会作为一个节点加入到一个链表中,因为该链表节点对应的缓存页都是需要被刷新到磁盘上的，所以叫做`flush`链表
- `flush` 链表的构造和 `free`链表差不多, 也有基节点

## LRU链表的管理
### 基本使用
- 为了淘汰掉部分最近很少使用的缓存页，按照`最近最少原则(LRU)`原则建立了一个 `LRU链表`来淘汰缓存页
- 当需要访问某个页时:
    * 如果该页不在`Buffer Pool`中，在把该页从磁盘加载到 `Buffer Pool` 中的缓存页时，就把该缓存页对应的`控制块`作为节点塞到链表的头部
    * 如果该页已经缓存在 `Buffer Pool`中，则直接把该页对应的`控制块`移动到`LRU`链表的头部
- 总的来说，就是`只要使用到某个缓存页,就把缓存页调整到LRU链表的头部，这样 LRU链表的尾部就是最近最少使用的缓存页了`

### 划分区域的LRU链表
`MySQL`中存在某些情况，会让`LRU链表`的缓存命中率大大降低

#### 预读 (read ahead)
`预读`是指，当 `InnoDB` 认为执行的当前的请求可能之后会读取某些页面，就预先把它们加载到`Buffer Pool`中。根据触发方式的不同，`预读`又可以细分为下面两种
- 线性预读
`InnoDB`预先提供了一个系统变量`innodb_read_ahead_threshold`，如果顺序访问了某个区(`extent`)的页面超过这个系统变量的值，就会触发一次`异步`读取下一个区中全部的页面到`Buffer Pool`的请求
该变量的默认值是`56`,可以在启动参数或者服务器运行过程中直接调整该系统变量的值
该值是一个全局变量，需要使用 `SET GLOBAL` 命令来修改

- 随机预读
如果`Buffer Pool`中已经缓存了某个区的13个连续的页面，不论这些页面是不是顺序读取的，都会触发一次`异步`读取本区中所有其它页面到`Buffer Pool`的请求
这个也有一个系统变量`innodb_random_read_ahead`系统变量来控制，默认值为`OFF`

假如预读触发了，那么会读取大量的页数据到缓存中，这些预读的页都会被放到`LRU`链表的头部，但是如果此时`Buffer Pool`的容量不太大而且很多预读的页面都没有用到的话，就会导致处在`LRU`链表尾部的一些缓存页很快就被淘汰掉

#### 全表扫描
全表扫码时，假如记录特别多，表就会占用特别多的`页`,当需要访问这些页的时候，就会统统加载到`Buffer Pool`中，所以相当于`Buffer Pool`中的所有页都被换了一次血。影响到了其它的查询语句的`缓存命中率`

鉴于在上述情况下，`LRU`链表的`缓存命中率`会大大降低，专门按区域对 `LRU`链表进行了划分
- 一部分存储使用频率非常高的缓存页，这一部分链表叫做`热数据`,或者称`young区域`
- 另一部分存储使用频率不是很高的缓存页,称之为`冷数据`, 或者称之为`old区域`

区域的划分是按照某个比例来的，并不是固定某些节点。
随着程序的运行，某个节点所属的区域是有可能发生变化的。
对于`InnoDB`存储引擎来说，可以通过查询系统变量`innodb_old_blocks_pct`的值来确定`old`区域在`LRU`链表中所占的比例
```sql
mysql> SHOW VARIABLES LIKE 'innodb_old_blocks_pct';
+-----------------------+-------+
| Variable_name         | Value |
+-----------------------+-------+
| innodb_old_blocks_pct | 37    |
+-----------------------+-------+
1 row in set (0.01 sec)
```
这个是全局变量

有了被划分为`young`和`old`区域的`LRU`链表之后，之前的`缓存命中率降低`问题就可以进行优化了
- 针对预读的页面可能不进行后续访问情况的优化
当磁盘上的某个页面在初次加载到`Buffer Pool`中的某个缓存页时，该缓存页对应的控制块会被放到`old区域`的头部
这样针对预读到`Buffer Pool`却不进行后续访问的页面就会被逐渐从`old区域`逐出，而不会影响`young`区域中被使用比较频繁的缓存页

- 针对全表扫描时，短时间内访问大量使用频率非常低的页面情况的优化
首次被加载到`Biffer Pool`的页被放到了`old区域`的头部，但是后续会被马上访问到，每次进行访问的时候又会把该页放到`yong区域`的头部，这样仍然会把那些使用频率比较高的页面给顶下去

全表扫描的特点在于,执行的频率是非常低的，而且在执行全表扫描的过程中，即使某个页面中很多记录，也就是去多次访问这个页面所花费的时间也是比较少的
所以,对某个处在 `old区域`的缓存页进行第一次访问时就在它对应的`控制块`中记录下来这个访问时间，如果后续的访问时间与第一次访问的时间在`某个时间间隔`内，那么该页面就不会被从`old区域`移动到`young区域`的头部，否则将它移动到`young区域`的头部。
上述这个`时间间隔`是由`innodb_old_blocks_time`控制的
```sql
mysql> SHOW VARIABLES LIKE 'innodb_old_blocks_time';
+------------------------+-------+
| Variable_name          | Value |
+------------------------+-------+
| innodb_old_blocks_time | 1000  |
+------------------------+-------+
1 row in set (0.01 sec)
```
默认值是100

### 更进一步优化LRu链表
TODO ，还有很多优化措施，是拔高内容

### 其它的一些链表
还有很多链表
- `unzip LRU链表`用于管理解压页
- `zip clean链表`用于管理没有被解压的压缩页
- `zip free数组`中的每一个元素都代表一个链表，组成`伙伴系统`来为压缩页提供内存空间

## 刷新脏页到磁盘
后台由专门的线程每隔一段时间负责把脏页刷新到磁盘,这样可以不影响用户线程处理正常的请求，主要有两种刷新路径:
- 从 `LRU链表`的冷数据中刷新一部分页面到磁盘
后台线程会定时从`LRU链表`尾部开始扫描一些页面，扫描的页面数量可以通过系统变量`innodb_lru_scan_depth`来指定，如果从里边儿发现脏页，会把它们刷新到磁盘。这种刷新页面的方式被称之为`BUF_FLUSH_LRU`

- 从 `flush链表`中刷新一部分页面到磁盘
后台线程也会定时从`flush链表`中刷新一部分页面到磁盘，刷新的速率取决于当时系统是不是很繁忙。这种刷新页面的方式被称之为`BUF_FLUSH_LIST`

有时候后台线程刷新脏页的进度比较慢，导致用户线程在准备加载一个磁盘页到`Buffer Pool`时没有可用的缓存页，这时就会尝试看看LRU链表尾部有没有可以直接释放掉的未修改页面，如果没有的话会不得不将`LRU链表`尾部的一个脏页同步刷新到磁盘（和磁盘交互是很慢的，这会降低处理用户请求的速度）。这种刷新单个页面到磁盘中的刷新方式被称之为`BUF_FLUSH_SINGLE_PAGE`。

当然，有时候系统特别繁忙时，也可能出现用户线程批量的从flush链表中刷新脏页的情况，很显然在处理用户请求过程中去刷新脏页是一种严重降低处理速度的行为（毕竟磁盘的速度慢的要死）。

## 多个 Buffer Pool 实例
`Buffer Pool`本质是`InnoDB`向操作系统申请的一块连续的内存空间，在多线程环境下，访问`Buffer Pool`中的各种链表都需要加锁处理啥的，在`Buffer Pool`特别大而且多线程并发访问特别高的情况下，单一的`Buffer Pool`可能会影响请求的处理速度。所以在`Buffer Pool`特别大的时候，我们可以把它们拆分成若干个小的`Buffer Pool`，每个`Buffer Pool`都称为一个实例，它们都是独立的，独立的去申请内存空间，独立的管理各种链表等，所以在多线程并发访问时并不会相互影响，从而提高并发处理能力。
我们可以在服务器启动的时候通过设置innodb_buffer_pool_instances的值来修改Buffer Pool实例的个数
```sql
[server]
innodb_buffer_pool_instances = 2
```

每个`Buffer Pool`实际占用的内存空间可以用公式进行推算
```
# 总共的大小除以实例1的个数
innodb_buffer_pool_size/innodb_buffer_pool_instances
```

`Buffer Pool`的实例并不是越多越好，分别管理各个`Buffer Pool`也是需要性能开销的，所以规定: `当innodb_buffer_pool_size的值小于1G的时候设置多个实例是无效的，InnoDB会默认把innodb_buffer_pool_instances 的值修改为1`
所以在`Buffer Pool`大于或等于`1G`的时候设置多个`Buffer Pool`实例是比较好的。

## innodb_buffer_pool_chunk_size
`MySQL 5.7.5`之后，`Buffer Pool`实例向操作系统申请空间的时候是以`chunk`为单位的,也就是说一个`Buffer Pool`实例其实是由若干个`chunk`组成的, 一个`chunk`就代表一片连续的内存空间，里边包含了若干缓存页与其对应的控制块

服务器运行期间调整`Buffer Pool`的大小时就是以`chunk`为单位增加或者删除内存空间，而不需要重新向操作系统申请一片大的内存，然后进行缓存页的复制。
这个所谓的`chunk`的大小是我们在启动操作MySQL服务器时通过`innodb_buffer_pool_chunk_size`启动参数指定的，它的默认值是`134217728`，也就是`128M`。不过需要注意的是，`innodb_buffer_pool_chunk_size`的值只能在服务器启动时指定，在服务器运行过程中是不可以修改的。

## 配置Buffer Pool时的注意事项
- `innodb_buffer_pool_size`必须是`innodb_buffer_pool_chunk_size` × `innodb_buffer_pool_instances`的倍数（这主要是想保证每一个`Buffer Pool`实例中包含的chunk数量相同）

假设我们指定的`innodb_buffer_pool_chunk_size`的值是128M，`innodb_buffer_pool_instances`的值是16，那么这两个值的乘积就是2G，也就是说`innodb_buffer_pool_size`的值必须是2G或者2G的整数倍

如果我们指定的`innodb_buffer_pool_size`大于2G并且不是2G的整数倍，那么服务器会自动的把`innodb_buffer_pool_size`的值调整为2G的整数倍

- 如果在服务器启动时，`innodb_buffer_pool_chunk_size` × `innodb_buffer_pool_instances`的值已经大于`innodb_buffer_pool_size`的值，那么`innodb_buffer_pool_chunk_size`的值会被服务器自动设置为`innodb_buffer_pool_size/innodb_buffer_pool_instances`的值

## Buffer Pool中存储的其它信息
`Buffer Pool`的缓存页除了用来缓存磁盘上的页面以外，还可以存储锁信息、自适应哈希索引等信息

### 查看Buffer Pool的状态信息
可以使用`SHOW ENGINE INNODB STATUS`语句来查看关于`InnoDB`存储引擎运行过程中的一些状态信息，其中就包括`Buffer Pool`的一些信息。
以下只包括`Buffer Pool`的部分
```sql
mysql> SHOW ENGINE INNODB STATUS\G

(...省略前边的许多状态)
----------------------
BUFFER POOL AND MEMORY
----------------------
Total memory allocated 13218349056;
Dictionary memory allocated 4014231
Buffer pool size   786432
Free buffers       8174
Database pages     710576
Old database pages 262143
Modified db pages  124941
Pending reads 0
Pending writes: LRU 0, flush list 0, single page 0
Pages made young 6195930012, not young 78247510485
108.18 youngs/s, 226.15 non-youngs/s
Pages read 2748866728, created 29217873, written 4845680877
160.77 reads/s, 3.80 creates/s, 190.16 writes/s
Buffer pool hit rate 956 / 1000, young-making rate 30 / 1000 not 605 / 1000
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read ahead 0.00/s
LRU len: 710576, unzip_LRU len: 118
I/O sum[134264]:cur[144], unzip sum[16]:cur[0]
--------------
(...省略后边的许多状态)

mysql>
```

简单描述一下这些状态的意思
- `Total memory allocated`：代表`Buffer Pool`向操作系统申请的连续内存空间大小，包括全部控制块、缓存页、以及碎片的大小。

- `Dictionary memory allocated`：为数据字典信息分配的内存空间大小，注意这个内存空间和`Buffer Pool`没啥关系，不包括在`Total memory allocated`中。

- `Buffer pool size`：代表该`Buffer Pool`可以容纳多少`缓存页`，注意，单位是`页`！

- `Free buffers`：代表当前`Buffer Pool`还有多少空闲缓存页，也就是`free链表`中还有多少个节点。

- `Database pages`：代表`LRU链表`中的页的数量，包含`young`和`old`两个区域的节点数量。

- `Old database pages`：代表LRU链表`old区域`的节点数量。

- `Modified db pages`：代表脏页数量，也就是`flush`链表中节点的数量。

- `Pending reads`：正在等待从磁盘上加载到`Buffer Pool`中的页面数量。
当准备从磁盘中加载某个页面时，会先为这个页面在`Buffer Pool`中分配一个缓存页以及它对应的控制块，然后把这个控制块添加到LRU的`old`区域的头部，但是这个时候真正的磁盘页并没有被加载进来，`Pending reads`的值会跟着加1。

- `Pending writes LRU`：即将从LRU链表中刷新到磁盘中的页面数量。

- `Pending writes flush list`：即将从`flush链表`中刷新到磁盘中的页面数量。

- `Pending writes single page`：即将以单个页面的形式刷新到磁盘中的页面数量。

- `Pages made young`：代表LRU链表中曾经从`old`区域移动到`young`区域头部的节点数量。
这里需要注意，一个节点每次只有从`old`区域移动到`young`区域头部时才会将`Pages made young`的值加1，也就是说如果该节点本来就在`young`区域，由于它符合在`young`区域1/4后边的要求，下一次访问这个页面时也会将它移动到`young`区域头部，但这个过程并不会导致`Pages made young`的值加1。

- `Page made not young`：在将`innodb_old_blocks_time`设置的值大于`0`时，首次访问或者后续访问某个处在`old`区域的节点时由于不符合时间间隔的限制而不能将其移动到`young`区域头部时，`Page made not young`的值会加1。
这里需要注意，对于处在`young`区域的节点，如果由于它在`young`区域的1/4处而导致它没有被移动到`young`区域头部，这样的访问并不会将`Page made not young`的值加1。

- `youngs/s`：代表每秒从`old`区域被移动到`young`区域头部的节点数量。

- `non-youngs/s`：代表每秒由于不满足时间限制而不能从old区域移动到young区域头部的节点数量。

- `Pages read、created、written`：代表读取，创建，写入了多少页。后边跟着读取、创建、写入的速率。

- `Buffer pool hit rate`：表示在过去某段时间，平均访问`1000`次页面，有多少次该页面已经被缓存到`Buffer Pool`了。

- `young-making rate`：表示在过去某段时间，平均访问1000次页面，有多少次访问使页面移动到young区域的头部了。
需要大家注意的一点是，这里统计的将页面移动到`young`区域的头部次数不仅仅包含从old区域移动到young区域头部的次数，还包括从`young`区域移动到`young`区域头部的次数（访问某个young区域的节点，只要该节点在young区域的1/4处往后，就会把它移动到young区域的头部）。

- `not (young-making rate)`：表示在过去某段时间，平均访问1000次页面，有多少次访问没有使页面移动到young区域的头部。
需要大家注意的一点是，这里统计的没有将页面移动到`young`区域的头部次数不仅仅包含因为设置了`innodb_old_blocks_time`系统变量而导致访问了old区域中的节点但没把它们移动到`young`区域的次数，还包含因为该节点在`young`区域的前1/4处而没有被移动到`young`区域头部的次数。

- `LRU len`：代表LRU链表中节点的数量。

- `unzip_LRU`：代表unzip_LRU链表中节点的数量（由于我们没有具体唠叨过这个链表，现在可以忽略它的值）。

- `I/O sum`：最近50s读取磁盘页的总数。

- `I/O cur`：现在正在读取的磁盘页数量。

- `I/O unzip sum`：最近50s解压的页面数量。

- `I/O unzip cur`：正在解压的页面数量。