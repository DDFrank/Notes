# redo 日志的基本概念
## redo 日志的定义
- 有时候, 想让已经提交了的事务对数据库中数据所作的修改永久生效，即使后来系统崩溃，在重启后也能把这种修改恢复出来
- `MySQL`会在提交事务时，把`修改了哪些东西记录一下`
```
将第0号表空间的100号页面的偏移量为1000处的值更新为2。
```
- 这样即使系统崩溃了，重启后按照上述内容所记录的步骤重新更新一下数据页，那么该事务对数据库中所做的修改又可以被恢复出来
- 因为在系统崩溃重启时需要按照上述内容所记录的步骤重新更新数据页，所以上述内容也被称之为`重做日志`，英文名为`redo log`

与在事务提交时将所有修改过的内存中的页面刷新到磁盘相比，只将该事务执行过程中产生的 `redo`日志刷新到磁盘的好处如下:
- `redo`日志占用的空间非常小
存储表空间ID、页号、偏移量以及需要更新的值所需的存储空间是很小的
- `redo`日志是顺序写入磁盘的
在执行事务的过程中，每执行一条语句，就可能产生若干条`redo`日志，这些日志是按照产生的顺序写入磁盘的，也就是使用顺序IO

## redo日志格式

`redo`日志本质上只是记录了一下事务对数据库做了哪些修改。 `MySQL`针对事务对数据库的不同修改场景定义了多种类型的redo日志，但是绝大部分类型的redo日志都有一些通用的结构

- `type`: 该条`redo`日志的类型(`5.7.21` 版本中，有53种不同的类型)
- `space ID`: 表空间ID
- `page number`: 页号
- `data`: 该条`redo`日志的具体内容

### 简单的redo日志类型
假如没有为某个表显式的定义主键，并且表中也没有定义`Unique`键，那么`InnoDB`会自动的为表添加一个称之为`row_id`的隐藏列作为主键, 为这个 `row_id`隐藏列赋值的方式如下:
- 服务器会在内存中维护一个全局变量，每当向某个包含隐藏的`row_id`列的表中插入一条记录时，就会把该变量的值当作新记录的`row_id`列的值，并且把该变量自增1
- 每当这个变量的值为`256`的倍数时，就会将该变量的值刷新到系统表空间的页号为`7`的页面中一个称之为`Max Row ID`的属性处 (详见表空间章节)
- 当系统启动时，会将上边提到的`Max Row ID`属性加载到内存中，将该值加上`256`之后赋值给我们前边提到的全局变量（因为在上次关机时该全局变量的值可能大于`Max Row ID`属性值）

这个`Max Row ID`属性占用的存储空间是`8`个字节，当某个事务向某个包含`row_id`隐藏列的表插入一条记录，并且为该记录分配的`row_id`值为`256`的倍数时，就会向系统表空间页号为`7`的页面的相应偏移量处写入`8`个字节的值。
而这个写入实际上是在`Buffer Pool`中完成的，那么这个页面的修改需要记录一条`redo`日志，以便在系统崩溃后能将已经提交的该事务对该页面所做的修改恢复出来。这种情况下对页面的修改是极其简单的，`redo`日志中只需要记录一下在某个页面的某个偏移量处修改了几个字节的值，具体被修改的内容是啥就好了。
这种极其简单的redo日志称之为物理日志，并且根据在页面中写入数据的多少划分了几种不同的redo日志类型：
- `MLOG_1BYTE`（`type`字段对应的十进制数字为`1`）：表示在页面的某个偏移量处写入`1`个字节的`redo`日志类型
- `MLOG_2BYTE`（`type`字段对应的十进制数字为`2`）：表示在页面的某个偏移量处写入`2`个字节的`redo`日志类型
- `MLOG_4BYTE`（`type`字段对应的十进制数字为`4`）：表示在页面的某个偏移量处写入`4`个字节的`redo`日志类型
- `MLOG_8BYTE`（`type`字段对应的十进制数字为`8`）：表示在页面的某个偏移量处写入`8`个字节的`redo`日志类型
- `MLOG_WRITE_STRING`（`type`字段对应的十进制数字为`30`）：表示在页面的某个偏移量处写入一串数据
这个类型因为不能确定写入的具体数据需要占用多少字节,所以需要在日志结构种添加一个`len`字段，表示占用的字节数

### 复杂一些的redo日志类型
格式很复杂，没有必要搞清楚

# Mini-Transaction
## 以组的形式写入 redo日志
语句在执行的过程种可能修改若干个页面，可能会产生许多 `redo`日志，为了确保这些日志的执行具有`原子性`, `MySQL`规定 `redo`日志的执行是以`组`为单位的
`组`内的`redo`日志执行要么全部成功，要么全部失败

### 如何标记多条redo日志为一个组
- `MySQL`会为每组种的最后一条`redo`日志后边加上一条特殊类型的`redo`日志。
该类型名称为`MLOG_MULTI_REC_END`，`type`字段对应的十进制数字为`31`，该类型的`redo`日志结构很简单，只有一个`type`字段

- 所以某个需要保证原子性的操作产生的一系列`redo`日志必须要以一个类型为`MLOG_MULTI_REC_END`结尾

- 在系统崩溃重启进行恢复时，只有当解析到类型为`MLOG_MULTI_REC_END`的redo日志，才认为解析到了一组完整的`redo`日志，才会进行恢复。否则的话直接放弃前边解析到的redo日志

### 如何标记一条`redo`日志为一个组
- `redo`日志的`type`字段占用一个字节, 但是只需要7个bit就可以表示全部类型，所以可以节省出一个bit来表示该需要保证原子性的操作只产生单一的一条redo日志

- 如果`type`字段的第一个`bit`为`1`，代表该需要保证原子性的操作只产生了单一的一条`redo`日志，否则表示该需要保证原子性的操作产生了一系列的`redo`日志

## Mini-Transaction的概念
`MySQL`把对底层页面中的一次原子访问的过程称之为一个`Mini-Transaction`, 简称 `mtr`

# redo日志的写入过程
## redo log block
`MySQl` 把通过`mtr`生成的`redo`日志都放在了大小为`512`字节的页中。
为了和前边提到的表空间中的页做区别，这里把用来存储`redo`日志的页称为`block`
### redo log block 的结构
- `log block header`: 全部都是一些管理信息, 12字节
    * `LOG_BLOCK_HDR_NO`：每一个`block`都有一个大于0的唯一标号，本属性就表示该标号值
    * `LOG_BLOCK_HDR_DATA_LEN`：表示`block`中已经使用了多少字节，初始值为`12`（因为`log block body`从第`12`个字节处开始）。随着往`block`中写入的`redo`日志越来越多，本属性值也跟着增长。如果log block body已经被全部写满，那么本属性的值被设置为`512`
    * `LOG_BLOCK_FIRST_REC_GROUP`：一条`redo`日志也可以称之为一条`redo`日志记录（`redo log record`），一个`mtr`会生产多条`redo`日志记录，这些`redo`日志记录被称之为一个`redo`日志记录组（`redo log record group`）。`LOG_BLOCK_FIRST_REC_GROUP`就代表该`block`中第一个`mtr`生成的`redo`日志记录组的偏移量（其实也就是这个`block`里第一个mtr生成的第一条`redo`日志的偏移量）
    * `LOG_BLOCK_CHECKPOINT_NO`：表示所谓的`checkpoint`的序号 (TODO 详细请查看后续章节)
- `log block body`: 数据，`496`字节
- `log block trailer`: 也存有一些管理信息
    * `LOG_BLOCK_CHECKSUM`：表示block的校验值，用于正确性校验

## redo 日志缓冲区
- `redo`日志也不是直接写道磁盘上，而是先通过 `redo log buffer` 的连续内存空间（服务器启动时会向操作系统申请）
- `redo log buffer`的内存空间被划分为若干个连续的`redo log block`
- 可以通过启动参数`innodb_log_buffer_size`来指定`log buffer`的大小，在`MySQL 5.7.21`这个版本中，该启动参数的默认值为16MB

### redo日志写入log buffer
向`log buffer`中写入`redo`日志的过程是顺序的，也就是先往前边的`block`中写，当该`block`的空闲空间用完之后再往下一个`block`中写。
当想往`log buffer`中写入`redo`日志时，第一个遇到的问题就是应该写在哪个`block`的哪个偏移量处，所以`MySQL`提供了一个称之为`buf_free`的全局变量，该变量指明后续写入的`redo`日志应该写入到`log buffer`中的哪个位置

一个`mtr`执行过程中可能产生若干条`redo`日志，这些`redo`日志是一个不可分割的组，所以其实并不是每生成一条`redo`日志，就将其插入到`log buffer`中，而是每个`mtr`运行过程中产生的日志先暂时存到一个地方，当该`mtr`结束的时候，将过程中产生的一组`redo`日志再全部复制到`log buffer`中

不同的事务可能是并发执行的，所以多个事务之间的`mtr`可能是交替执行的。
每当一个`mtr`执行完成时，伴随该`mtr`生成的一组`redo`日志就需要被复制到`log buffer`中，也就是说不同事务的`mtr`可能是交替写入`log buffer`

# redo日志文件
## redo日志刷盘时机
在以下情况下 `log buffer` 的日志会被刷新到磁盘中
- `log buffer` 空间不足时
`log buffer`的大小是有限的（通过系统变量`innodb_log_buffer_size`指定），如果不停的往这个有限大小的`log buffer`里塞入日志，很快它就会被填满。
`MySQL`认为如果当前写入`log buffer`的`redo`日志量已经占满了`log buffer`总容量的大约一半左右，就需要把这些日志刷新到磁盘上。

- 事务提交时
在事务提交时可以不把修改过的`Buffer Pool`页面刷新到磁盘，但是为了保证持久性，必须要把修改这些页面对应的`redo`日志刷新到磁盘

- 后台线程刷新
后台有一个线程，大约每秒都会刷新一次`log buffer`中的`redo`日志到磁盘

- 正常关闭服务器时
- 使用`checkpoint`时
- 其它情况

## redo日志文件组
`MySQL`的数据目录（使用`SHOW VARIABLES LIKE 'datadir'`查看）下默认有两个名为`ib_logfile0`和`ib_logfile1`的文件，`log buffer`中的日志默认情况下就是刷新到这两个磁盘文件中

可以通过启动参数来调节这几个文件的位置:
- `innodb_log_group_home_dir`
该参数指定了`redo`日志文件所在的目录，默认值就是当前的数据目录
- `innodb_log_file_size`
该参数指定了每个`redo`日志文件的大小，在`MySQL 5.7.21`这个版本中的默认值为`48MB`
- `innodb_log_files_in_group`
该参数指定`redo`日志文件的个数，默认值为`2`，最大值为`100`

所以磁盘上的`redo`日志文件不只一个，而是以一个日志文件组的形式出现的。这些文件以`ib_logfile[数字]`（数字可以是0、1、2...）的形式进行命名。在将`redo`日志写入日志文件组时，是从`ib_logfile0`开始写，如果`ib_logfile0`写满了，就接着`ib_logfile1`写，同理，`ib_logfile1`写满了就去写`ib_logfile2`，依此类推。如果写到最后一个文件，那就重新转到ib_logfile0继续写

总共的`redo`日志文件内大小其实就是: `innodb_log_file_size × innodb_log_files_in_group`

## redo日志文件格式
`log buffer`本质上是一片连续的内存空间，被划分成了若干个`512`字节大小的`block`。将`log buffer`中的`redo`日志刷新到磁盘的本质就是把`block`的镜像写入日志文件中，所以`redo`日志文件其实也是由若干个`512`字节大小的`block`组成:
- 前2048个字节，也就是前4个block是用来存储一些管理信息的
- 从第2048字节往后是用来存储log buffer中的block镜像的

所以即使是`循环`使用`redo`日志文件，其实是从每个日志文件的第2048个字节开始算的

### redo 日志文件的前 2048个字节的格式
#### log file header
描述`redo`日志文件的一些整体属性, 各个属性的释义如下

| 属性名                 | 长度(单位:字节) | 描述                                                         |
| ---------------------- | --------------- | ------------------------------------------------------------ |
| `LOG_HEADER_FORMAT`    | 4               | `redo`日志的版本,在`MySQL 5.7.21`中该值永远为1               |
| `LOG_HEADER_PAD1`      | 4               | 填充用                                                       |
| `LOG_HEADER_START_LSN` | 8               | 标记本`redo`日志文件开始的LSN值，也就是文件偏移量为2048字节初对应的LSN值(LSN请参照后文) |
| `LOG_HEADER_CREATOR`   | 32              | 一个字符串，标记本`redo`日志文件的创建者是谁。正常运行时该值为`MySQL`的版本号，比如：`"MySQL 5.7.21"`，使用`mysqlbackup`命令创建的`redo`日志文件的该值为`"ibbackup"`和创建时间。 |
| `LOG_BLOCK_CHECKSUM`   | 4               | 本block的校验值，所有block都有                               |
|                        |                 |                                                              |

#### checkpoint1
记录关于`checkpoint`的一些属性
结构如下:

| 属性名                        | 长度(单位:字节) | 描述                                                         |
| ----------------------------- | --------------- | ------------------------------------------------------------ |
| `LOG_CHECKPOINT_NO`           | 8               | 服务器做`checkpoint`的编号，每做一次`checkpoint`，该值就加1  |
| `LOG_CHECKPOINT_LSN`          | 8               | 服务器做`checkpoint`结束时对应的`LSN`值，系统崩溃恢复时将从该值开始 |
| `LOG_CHECKPOINT_OFFSET`       | 8               | 上个属性中的`LSN`值在`redo`日志文件组中的偏移量              |
| `LOG_CHECKPOINT_LOG_BUF_SIZE` | 8               | 服务器在做`checkpoint`操作时对应的`log buffer`的大小         |
| `LOG_BLOCK_CHECKSUM`          | 4               | 本block的校验值，所有的block都有                             |
|                               |                 |                                                              |

### block3
这个block没有使用

### checkpoing2
结构跟`checkpoint1` 一致

# Log Sequence Number
- 自系统开始运行，就不断的在修改页面，也就意味着会不断的生成`redo`日志。`redo`日志的量在不断的递增
- `MySQL`中有一个`Log Sequence Number`的全局变量(日志序列号，简称`lsn`), 表示已经写入的`redo`日志量
- `lsn`的初始值为`8704`

向`log buffer`中写入`redo`日志时不是一条一条写入的，而是以一个`mtr`生成的一组`redo`日志为单位进行写入的。而且实际上是把日志内容写在了`log block body`处。但是在统计`lsn`的增长量时，是按照实际写入的日志量加上占用的`log block header`和`log block trailer`来计算的

每一组由`mtr`生成的`redo`日志都有一个唯一的`LSN`值与其对应，LSN值越小，说明`redo`日志产生的越早

## flushed_to_disk_lsn
`redo`日志是首先写到`log buffer`中，之后才会被刷新到磁盘上的`redo`日志文件。所以`MySQL`中有一个`buf_next_to_write`的全局变量，标记当前`log buffer`中已经有哪些日志被刷新到磁盘中了
- `buf_next_to_write` 表示下一个要写盘的`lsn`
- `buf_free` 表示当前 `redo`日志写到的位置
- 也就是 `buf_next_to_write` 到 `buf_free` 之间的log表示已经写入到 `log_buffer` 但是没有写道 `log buffer` 的日志

`lsn`是表示当前系统中写入的`redo`日志量，这包括了写到`log buffer`而没有刷新到磁盘的日志，相应的，`MySQL`中有一个刷新到磁盘中的`redo`日志量的全局变量，称之为`flushed_to_disk_lsn`。系统第一次启动时，该变量的值和初始的`lsn`值是相同的，都是`8704`。随着系统的运行，`redo`日志被不断写入`log buffer`，但是并不会立即刷新到磁盘，`lsn`的值就和`flushed_to_disk_lsn`的值拉开了差距

所以, 当有新的`redo`日志写入到`log buffer`时，首先`lsn`的值会增长，但`flushed_to_disk_lsn`不变，随后随着不断有`log buffer`中的日志被刷新到磁盘上，`flushed_to_disk_lsn`的值也跟着增长。如果两者的值相同时，说明`log buffer`中的所有`redo`日志都已经刷新到磁盘中了

注意: 应用程序向磁盘写入文件时其实是先写到操作系统的缓冲区中去，如果某个写入操作要等到操作系统确认已经写到磁盘时才返回，那需要调用一下操作系统提供的`fsync`函数。其实只有当系统执行了`fsync`函数后，`flushed_to_disk_lsn`的值才会跟着增长，当仅仅把`log buffer`中的日志写入到操作系统缓冲区却没有显式的刷新到磁盘时，另外的一个称之为`write_lsn`的值跟着增长。不过为了大家理解上的方便，我们在讲述时把`flushed_to_disk_lsn`和`write_lsn`的概念混淆了起来

## lsn 值和 redo日志文件偏移量的对应关系
因为`lsn`的值是代表系统写入的`redo`日志量的一个总和，一个`mtr`中产生多少日志，`lsn`的值就增加多少（当然有时候要加上`log block header`和`log block trailer`的大小），这样`mtr`产生的日志写到磁盘中时，很容易计算某一个`lsn`值在`redo`日志文件组中的偏移量

## flush链表中的LSN
一个`mtr`代表一次对底层页面的原子访问，在访问过程中可能会产生一组不可分割的`redo`日志，在`mtr`结束时，会把这一组`redo`日志写入到`log buffer`中。除此之外，在`mtr`结束时还有一件非常重要的事情要做，就是把在mtr执行过程中可能修改过的页面加入到`Buffer Pool`的`flush`链表

当第一次修改某个缓存在`Buffer Pool`中的页面时，就会把这个页面对应的控制块插入到`flush`链表的头部，之后再修改该页面时由于它已经在`flush`链表中了，就不再次插入了。也就是说`flush`链表中的脏页是按照页面的第一次修改时间从大到小进行排序的。在这个过程中会在缓存页对应的控制块中记录两个关于页面何时修改的属性:
- `oldest_modification`: 如果某个页面被加载到Buffer Pool后进行第一次修改，那么就将修改该页面的`mtr`开始时对应的`lsn`值写入这个属性
- `newest_modification`: 每修改一次页面，都会将修改该页面的`mtr`结束时对应的`lsn`值写入这个属性。也就是说该属性表示页面最近一次修改后对应的系统`lsn`值

总的来说: `flush链表中的脏页按照修改发生的时间顺序进行排序，也就是按照oldest_modification代表的LSN值进行排序，被多次更新的页面不会重复插入到flush链表中，但是会更新newest_modification属性的值`

## checkpoint
`redo日志只是为了系统崩溃后恢复脏页用的，如果对应的脏页已经刷新到了磁盘，也就是说即使现在系统崩溃，那么在重启后也用不着使用redo日志恢复该页面了，所以该redo日志也就没有存在的必要了，那么它占用的磁盘空间就可以被后续的redo日志所重用`。也就是说：`判断某些redo日志占用的磁盘空间是否可以覆盖的依据就是它对应的脏页是否已经刷新到磁盘里`

`MySQL`中有一个全局变量`checkpoint_lsn`来代表当前系统中可以被覆盖的`redo`日志总量是多少，这个变量初始值也是`8704`

### 做 checkpoint的过程
分为2个步骤
- 计算一下当前系统中可以被覆盖的`redo`日志对应的`lsn`值最大是多少
`redo`日志可以被覆盖，意味着它对应的脏页被刷到了磁盘，只要我们计算出当前系统中被最早修改的脏页对应的`oldest_modification`值，那凡是在系统`lsn`值小于该节点的`oldest_modification`值时产生的`redo`日志都是可以被覆盖掉的，我们就把该脏页的`oldest_modification`赋值给`checkpoint_lsn`

- 将`checkpoint_lsn`和对应的`redo`日志文件组偏移量以及此次`checkpint`的编号写到日志文件的管理信息（就是`checkpoint1`或者`checkpoint2`）中

`MySQL`中维护了一个变量`checkpoint_no`, 每做一次`checkpoint`，该变量的值就加1
计算一个`lsn`值对应的`redo`日志文件组偏移量是很容易的，所以可以计算得到该`checkpoint_lsn`在`redo`日志文件组中对应的偏移量`checkpoint_offset`，然后把这三个值都写到`redo`日志文件组的管理信息中
每一个`redo`日志文件都有`2048`个字节的管理信息，但是上述关于`checkpoint`的信息只会被写到日志文件组的第一个日志文件的管理信息中.
当`checkpoint_no`的值是偶数时，就写到`checkpoint1`中，是奇数时，就写到`checkpoint2`中

## 批量从flush链表中刷出脏页
一般情况下都是后台的线程在对`LRU链表`和`flush链表`进行刷脏操作，这主要因为刷脏操作比较慢，不想影响用户线程处理请求。但是如果当前系统修改页面的操作十分频繁，这样就导致写日志操作十分频繁，系统`lsn`值增长过快。如果后台的刷脏操作不能将脏页刷出，那么系统无法及时做`checkpoint`，可能就需要用户线程同步的从`flush`链表中把那些最早修改的脏页（`oldest_modification`最小的脏页）刷新到磁盘，这样这些脏页对应的`redo`日志就没用了，然后就可以去做`checkpoint`了

## 查看系统中的各种LSN值
可以使用`SHOW ENGINE INNODB STATUS`命令查看当前`InnoDB`存储引擎中的各种`LSN`值的情况
```sql
mysql> SHOW ENGINE INNODB STATUS\G

(...省略前边的许多状态)
LOG
---
Log sequence number 124476971
Log flushed up to   124099769
Pages flushed up to 124052503
Last checkpoint at  124052494
0 pending log flushes, 0 pending chkp writes
24 log i/o's done, 2.00 log i/o's/second
----------------------
(...省略后边的许多状态)
```
- `Log sequence number`：代表系统中的`lsn`值，也就是当前系统已经写入的`redo`日志量，包括写入`log buffer`中的日志
- `Log flushed up to`：代表`flushed_to_disk_lsn`的值，也就是当前系统已经写入磁盘的`redo`日志量
- `Pages flushed up to`：代表`flush`链表中被最早修改的那个页面对应的`oldest_modification`属性值
- `Last checkpoint at`：当前系统的`checkpoint_lsn`值

## innodb_flush_log_at_trx_commit的用法
了保证事务的持久性，用户线程在事务提交时需要将该事务执行过程中产生的所有`redo`日志都刷新到磁盘上。这一条要求太狠了，会很明显的降低数据库性能。
如果有对事务的持久性要求不是那么强烈的话，可以选择修改一个称为`innodb_flush_log_at_trx_commit`的系统变量的值，该变量有3个可选的值:
- `0`：当该系统变量值为`0`时，表示在事务提交时不立即向磁盘中同步`redo`日志，这个任务是交给后台线程做的
这样很明显会加快请求处理速度，但是如果事务提交后服务器挂了，后台线程没有及时将`redo`日志刷新到磁盘，那么该事务对页面的修改会丢失
- `1`：当该系统变量值为`1`时，表示在事务提交时需要将`redo`日志同步到磁盘，可以保证事务的持久性。`1`也是`innodb_flush_log_at_trx_commit`的默认值
- `2`: 当该系统变量值为2时，表示在事务提交时需要将`redo`日志写到操作系统的缓冲区中，但并不需要保证将日志真正的刷新到磁盘

这种情况下如果数据库挂了，操作系统没挂的话，事务的`持久性`还是可以保证的，但是操作系统也挂了的话，那就不能保证`持久性`了

# 崩溃恢复
服务器down机时，可以根据 `redo`日志来恢复页面数据
## 确定恢复的起点
- `checkpoint_lsn`之前的`redo`日志都可以被覆盖，也就是说这些`redo`日志对应的脏页都已经被刷新到磁盘中了，既然它们已经被刷盘，就没必要恢复它们了
- `checkpoint_lsn`之后的`redo`日志，它们对应的脏页可能没被刷盘，也可能被刷盘了不能确定，所以需要从`checkpoint_lsn`开始读取`redo`日志来恢复页面

`redo`日志文件组的第一个文件的管理信息中有两个`block`都存储了`checkpoint_lsn`的信息，要在其中选取最近发生的那次checkpoint的信息。
衡量`checkpoint`发生时间早晚的信息就是所谓的`checkpoint_no`，我们只要把`checkpoint1`和`checkpoint2`这两个`block`中的`checkpoint_no`值读出来比一下大小，哪个的`checkpoint_no`值更大，说明哪个`block`存储的就是最近的一次`checkpoint`信息。这样我们就能拿到最近发生的`checkpoint`对应的`checkpoint_lsn`值以及它在`redo`日志文件组中的偏移量`checkpoint_offset`

## 确定恢复的终点
普通`block`的`log block header`部分有一个称之为`LOG_BLOCK_HDR_DATA_LEN`的属性，该属性值记录了当前`block`里使用了多少字节的空间。对于被填满的`block`来说，该值永远为`512`。如果该属性的值不为`512`，那么就是它了，它就是此次崩溃恢复中需要扫描的最后一个`block`

## 怎么恢复
因为 `checkpoint_lsn` 的前面的`redo`日志表示是可以覆盖的，所以恢复`checkpoint_lsn`后面的`redo`日志就可以了
有一些办法可以加快这个过程
- 使用哈希表
根据`redo`日志的`space ID`和`page number`属性计算出散列值，把`space ID`和`page number`相同的`redo`日志放到哈希表的同一个槽里，如果有多个`space ID`和`page number`都相同的redo日志，那么它们之间使用链表连接起来，按照生成的先后顺序链接起来的
之后就可以遍历哈希表，因为对同一个页面进行修改的`redo`日志都放在了一个槽里，所以可以一次性将一个页面修复好（避免了很多读取页面的`随机IO`），这样可以加快恢复速度

- 跳过已经刷新到磁盘的页面
`checkpoint_lsn`之前的`redo`日志对应的脏页确定都已经刷到磁盘了，但是`checkpoint_lsn`之后的`redo`日志我们不能确定是否已经刷到磁盘，主要是因为在最近做的一次`checkpoint`后，可能后台线程又不断的从`LRU链表`和`flush链表`中将一些脏页刷出`Buffer Pool`。这些在`checkpoint_lsn`之后的`redo`日志，如果它们对应的脏页在崩溃发生时已经刷新到磁盘，那在恢复时也就没有必要根据`redo`日志的内容修改该页面了

那在恢复时怎么知道某个`redo`日志对应的脏页是否在崩溃发生时已经刷新到磁盘了呢？每个页面都有一个称之为`File Header`的部分，在`File Header`里有一个称之为`FIL_PAGE_LSN`的属性，该属性记载了最近一次修改页面时对应的`lsn`值（其实就是页面控制块中的`newest_modification`值）。如果在做了某次`checkpoint`之后有脏页被刷新到磁盘中，那么该页对应的`FIL_PAGE_LSN`代表的`lsn`值肯定大于`checkpoint_lsn`的值，凡是符合这种情况的页面就不需要重复执行`lsn`值小于`FIL_PAGE_LSN`的redo日志了，所以更进一步提升了崩溃恢复的速度
