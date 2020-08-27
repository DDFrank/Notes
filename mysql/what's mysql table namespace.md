# 独立表空间结构

## 区(extent)的概念
- 区是为了更好的管理大量的`页`
- 对于 16kb 的页来说在物理上连续的64个页就是一个区，也就是一个区默认占用1MB
- 系统表空间和独立表空间，都可以看成是由若干个区组成的，每256个区被划分成一组。

### 为什么需要区
- 如果单以 `页` 为单位来分配存储空间，那么双向链表相邻的两个页之间的物理位置可能离得非常远，那么范围查询时就退化为了 `随机I/O`
- 为了尽量让链表中相邻的页的物理位置也相邻，所以引入了`区`的概念。`区`是在物理位置上连续的64个页
- 在表中数据非常大的时候，为索引分配空间的时候就会按照`区`来分配。


### 每个组的头几个页面的类型都是类似的
#### extent0区 最开始的三个类型固定的页面
- `FSP_HDR`类型: 这个类型的页面是用来登记整个表空间的一些整体属性以及本组所有的`区`的属性(extent0 ~ extent255)。整个表空间只有一个 `FSP_HDR`类型的页面
- `IBUF_BITMAP`类型: 存储本组所有的区的所有页面关于 `INSERT BUFFER`的信息
- `INODE`类型: 存储了大量 `INODE`的数据页面

#### 其它组的固定页面
- `XDES`类型: `extent descriptor`，用于登记本组256个区的属性，跟 `FSP_HDR`的功能类似，不过 `FSP_HDR`会存储更多表空间的属性
- `INBUF_BITMAP`类型: 同上

### 段(segment)的概念
- 范围查询的时候，其实是对 `B+`树叶子节点的记录进行顺序扫描
- 如果不区分叶子节点和非叶子节点，进行范围扫描的效果就变差了
- 存放叶子节点的区 和 存放飞叶子节点的 `区`的集合称为`段`
- 所以一个索引会生成2个段，一个叶子节点段，一个非叶子节点段

### 碎片(fragment)区
- 碎片区中的页可以用于不同的目的，并非只能用于叶子节点或非叶子节点
- 专门为了数据量比较小的表，尽量不浪费分配空间
- 碎片区只属于表空间，不属于任何一个段
- 在刚开始向表中插入数据的时候，段是从某个碎片区以单个页面为单位来分配存储空间的。
- 当某个段已经占用了32个碎片页空间之后，就会以完整的区为单位来分配存储空间

### 区的分类
大体上可以分为4种类型

| 状态名      | 含义                 | 描述                                               |
| ----------- | -------------------- | -------------------------------------------------- |
| `FREE`      | 空闲的区             | 现在还没有用到这个区中的任何页面                   |
| `FREE_FRAG` | 有剩余空间的碎片区   | 表示碎片区中还有可用的页面                         |
| `FULL_FRAG` | 没有剩余空间的碎片区 | 表示碎片区中的所有页面都被使用，没有空闲页面       |
| `FSEG`      | 附属于某个段的区     | 分为叶子节点段和非叶子节点段，还有一些特殊作用的段 |

为了方便管理区，每个区都有一个叫 `XDES Entry`的结构，记录了对应的区的一些属性, 总共有40个字节, 下面是结构

#### Segment ID (8字节)
- 每一个段都有一个唯一的编号
- 这个字段就是表明该区所在的段
- 只有在该区已经被分配给某个段的情况下才有意义

#### List Node(12字节)
- 用于将若干个 `XDES ENtry` 结构串成一个链表
  - `Prev Node Page Number (4字节)` 和 `Prev Node Offset(2字节)` 的组合就是指向前一个 `XDES Entry`的指针
  - `Next Node Page Number(4字节)` 和 `Next Node Offset(2字节)`的组合就是指向后一个 `XDES Entry`的指针

#### State (4字节)
就是指的区的状态，详细内容见上表

#### Page State Bitmap (16字节)
- 16个字节128个 bit。一个区默认有64个页,这128个 bit 就被划分为了64个部分，每个部分2 bit
- 第一个 bit 表示对应的页是否是空闲的，第二个 bit 是保留的

## XDES Entry 链表
往某个段中插入数据的过程

### 寻找合适的区
- 段中数据较小的时候，先查找 `FREE_FRAG` 的区，也就是找还有空闲空间的碎片区，如果找到了，那么就从该区取一些零散的页把数据插进去
- 假如没有，那么就在表空间下申请一个状态为 `FREE` 的区，将其状态修改为 `FREE_FRAG`，然后插入数据
- 当一个区中没有空闲空间，那么该区的状态就变成了 `FULL_FRAG`

#### 如何知道某个区的状态
- 不可能遍历 `区` 对应的的 `XDES Entry` 结构来获知区的状态，这样效率极低
- 利用 `XDES Entry` 中的 `List Node`
  - 状态为 `FREE` 的区对应的 `XDES Entry` 结构通过 `List Node` 来连接成一个`FREE`链表
  - 状态为 `FREE_FRAG` 的区对应的 `XDES Entry` 结构通过 `List Node` 来连接成一个`FREE_FRAG`链表
  - 状态为 `FULL_FRAG` 的区对应的 `XDES Entry` 结构通过 `List Node` 来连接成一个`FULL_FRAG`链表
- 想查找一个 `FREE_FLAG` 的状态的区的时候，就直接把 `FREE_FLAG` 链表的头结点拿出来使用。
- 当 `FREE_FLAG` 的区用完的时候，就修改一下这个节点的 `State`字段的值，然后直接从 `FREE` 链表中取一个节点移动到 `FREE_FRAG` 链表的头部，并修改其 `State` 然后使用即可

#### 当段中数据已经占满32个零散的页后，就直接申请完整的区来插入数据
此时如何知道哪个区是属于哪个段的呢? 每个段中的区对应的 `XDES Entry` 结构都有三个链表
- `FREE`链表: 所有页面都是空闲的区的`XDES Entry`结构。这个不是直属于表空间的`FREE`链表，此处的`FREE`链表是附属于某个段的
- `NOT_FULL`链表: 同一个段中，仍有空闲空间的区对应的`XDES Entry` 结构
- `FULL` 链表: 同一个段中，已经没有空闲空间的区对应的`XDES Entry` 结构

每一个索引都会维护上述的3个链表

举例:
```sql
CREATE TABLE t (
    c1 INT NOT NULL AUTO_INCREMENT,
    c2 VARCHAR(100),
    c3 VARCHAR(100),
    PRIMARY KEY (c1),
    KEY idx_c2 (c2)
)ENGINE=InnoDB;
```

这个表有一个 聚簇索引，一个二级索引，所以一共有5个段，每个段维护上述3个链表，所以是12个链表
再加上直属于表空间的3个链表，一共是 15 个链表

### 链表基节点
表空间有一个固定的位置存储 `List Base Node` 来维护链表的状态

#### List Base Node 结构
- `List Length`: 表明该链表一共有多少个节点
- `First Node Page Number` 和 `First Node` Offset 表明该链表的头结点在表空间中的位置
- `Last Node Page Number` 和 `Last Node Offset` 表明该链表的尾节点在表空间中的位置

## 段的结构
- 段其实不对应表空间中某一个连续的物理区域，而是一个逻辑上的概念。
由若干个零散的页面以及一些完整的区组成。
- 每个段都有一个 `INODE Entry` 结构来记录段中的属性

### INODE Entry 结构
- `Segment ID`
对应的段编号

- `NOT_FULL_N_USED`
指的是在 `NOT_FULL` 链表中已经使用了多少个页面

- 3个 `List Base Node`
分别为段的 `FREE` 链表，`NOT_FULL`链表, `FULL`链表定义了 `List Base Node`

- `Magic Number`
用来标记这个 `INODE Entry`是否已经被初始化了，如果该值为 `97937874` 那么就已经初始化了

- `Fragment Array Entry`
对应着一个零散的页面，该结构一共4个字节，表示一个零散页面的页号(也就说有多个这个结构)

## 各类型页面的详细情况

### FSP_HDR 类型
- 表空间的第一个页面，页号为`0`。
- 也是表空间第一个组的第一个页面
- 存储了表空间的一些整体属性以及第一个组内256个区的对应的`XDES Entry`结构

`FSP_HDR 结构`

| 名称                | 中文名       | 占用空间大小（字节） | 简单描述                       |
| ------------------- | ------------ | -------------------- | ------------------------------ |
| `File Header`       | 文件头部     | 38                   | 页的一些通用信息               |
| `File Space Header` | 表空间同步   | 112                  | 表空间的一些整体属性信息       |
| `XDES Entry`        | 区描述信息   | 10240                | 存储本组256个区对应的属性信息  |
| `Empty Space`       | 尚未使用空间 | 5986                 | 用于页结构的填充，没有实际意义 |
| `File Trailer`      | 文件尾部     | 8字节                | 校验页是否完整                 |

`File Header` 和 `File Trailer` 见 `how do innodb save data`

#### File Space Header 部分
用于存储表空间的一些整体属性

| 名称                                      | 占用空间大小(字节) | 描述                                                         |
| ----------------------------------------- | ------------------ | ------------------------------------------------------------ |
| `Space ID`                                | 4                  | 表空间的ID                                                   |
| `Not Used`                                | 4                  | 未被使用，可以忽略                                           |
| `Size`                                    | 4                  | 当前表空间占有的页面数                                       |
| `FREE Limit`                              | 4                  | 尚未被初始化的最小页号，大于或等于这个页号的区对应的`XDES Entry`结构都没有被加入`FREE`链表 |
| `Space Flags`                             | 4                  | 表空间的一些占用存储空间比较小的属性                         |
| `FRAG_N_USED`                             | 4                  | `FREE_FRAG`链表中已使用的页面数量                            |
| `List Base Node For FREE List`            | 16                 | `FREE`链表的基节点（直属于表空间的）                         |
| `List Base Node For FREE_FRAG List`       | 16                 | `FREE_FRAG`链表的基节点(直属于表空间的)                      |
| `List Base Node for FULL_FRAG List`       | 16                 | `FULL_FRAG`链表的基节点(直属于表空间的)                      |
| `Next Unused Segment ID`                  | 8                  | 当前表空间中下一个个未使用的 Segment ID                      |
| `List Base Node for SEG_INODES_FULL List` | 16                 | `SEG_INODES_FULL`链表的基节点                                |
| `List Base Node for SEG_INODES_FREE List` | 16                 | `SEG_INODES_FREE`链表的基节点                                |
|                                           |                    |                                                              |
|                                           |                    |                                                              |
|                                           |                    |                                                              |

- `FRAG_N_USED`
表明在 `FREE_FRAG` 链表中已经使用的页面数量

- `FREE Limit`
  - 表空间对应着具体的磁盘文件。
  - 一开始创建表空间的时候磁盘文件是没有数据的，但是申请表空间的时候申请了一个比较大的空间，所以大部分空间是有空闲的
  - 在`FREE Limit`页号之前的页是已经被初始化的，并且其对应的 `XDES Entry` 结构已经加入了 `FREE`链表，之后的则没有初始化
  - 在需要的时候，会增加这个页号并将没有使用的页初始化并加入到`FREE`链表

- `Next Unused Segment ID`
  - 表中的每个索引都对应两个段，每个段都有一个唯一的ID。
  - 当需要为段确定一个唯一的id的时候，就可以从这里获取
  - 该字段表明当前表空间中最大的段ID的下一个ID，所以直接使用即可

- `Space Flags`
  表空间的一些布尔类型的属性，或者只需要几个比特位的属性都放在这里了


| 标志名称        | 占用空间(bit) | 描述                                     |
| --------------- | ------------- | ---------------------------------------- |
| `POST_ANTELOPE` | 1             | 表示文件格式是否大于`ANTELOPE`           |
| `ZIP_SSIZE`     | 4             | 表示压缩页面的大小                       |
| `ATOMIC_BLOBS`  | 1             | 表示是否自动把值非常长的字段放到BLOB页里 |
| `PAGE_SSIZE`    | 4             | 页面大小                                 |
| `DATA_DIR`      | 1             | 表示表空间是否是从默认的数据目录中获取的 |
| `SHARED`        | 1             | 是否为共享表空间                         |
| `TEMPORARY`     | 1             | 是否为临时表空间                         |
| `ENCRYPTION`    | 1             | 表空间是否加密                           |
| `UNUSED`        | 18            | 没有使用到的比特位                       |

- `List Base Node for SEG_INODES_FULL List` 和 `List Base Node for SEG_INODES_FREE List`
每个段对应的 `INODE ENtry` 结构会集中到一个类型为 `INODE` 的页中
如果表空间的段特别多，则会有多个`INNODE Entry`结构，可能一个页放不下，那么这些`INODE` 类型的页会组成两种列表:
 - `SEG_INODES_FULL` 链表，该链表中的 `INODE` 类型的页面都已经被 `INODE ENtry`结构填充满了，没空闲空间存放额外的 `INODE Entry`了。
 - `SEG_INODES_FREE` 链表，该链表中的`INODE`类型的页面仍有空闲空间来存放`INODE Entry`结构

#### XDES Entry 部分
- 一个 `XDES Entry` 结构的大小是40字节，但是一个页面的大小有限
- 所以需要将256个区划分为一个组，每组的第一个页面存放 256个 `XDES Entry`结构
- 具体请查看上文对 `XDES Entry` 的介绍

### XDES 类型
- `FSP_HDR` 是表空间第一个组的第一个页的类型
- 为了和 `FSP_HDR` 类型区分，也就是表空间第二个组开始的第一个页面就是 `XDES`类型
- 因为 `FSP_HDR` 已经记录了表空间的属性了，所以 `XDES` 类型只需要记录 本组内所有`XDES Entry` 记录即可
- 结构和 `FSP_HDR` 很类似
  - File Header
  - 很多 XDES Entry
  - Empty Space
  - File Trailer

### `IBUF_BITMAP` 类型
- 每个分组的第二个页面的类型都是 `IBUF_BITMAP`
- 该类型的页是为了存储 `Change Buffer`。
- `Change Buffer` 的内容放到后文详解

### `INODE`类型和结构
- 第一个分组的第三个页面的类型是 `INODE`
- 该页是为了存储 记录了段的相关属性的 `INODE Entry`

#### 结构

| 名称                          | 中文名       | 占用空间大小(字节) | 简单描述                                   |
| ----------------------------- | ------------ | ------------------ | ------------------------------------------ |
| File Header                   | 文件头部     | 38                 | 页的一些通用信息                           |
| List Node For INODE Page List | 通用链表节点 | 12                 | 存储上一个INODE页面和下一个INODE页面的指针 |
| INODE Entry                   | 段描述信息   | 16320字节          |                                            |
| Empty Space                   | 尚未使用空间 | 6                  | 用于页结构的填充，没啥实际意义             |
| File Trailer                  | 文件尾部     | 8字节              | 校验页是否完整                             |

`File Header` ，`Empty Space` 和 `File Trailer` 跟之前一样

###### `List Node For INODE Page List` 

- 一个 `INODE ENtry`结构占用192个字节，一个页面里可能存储 `85`个这样的结构
- 因为一个表空间中可能存在超过85个段，所以可能一个 `INODE`类型的页面不足以存储所有的段对应的`INODE Entry`结构，所以需要额外的 `INODE` 类型的页面来存储
- 所以有专门用于链接 `INODE`类型的页面的链表
  - `SEG_INODES_FULL` 链表: 该链表中的 `INODE` 类型的页面中已经没有空闲空间来存储 `INODE Entry` 结构
  - `SEG_INDOES_FREE`: 该链表中的 `INODE` 类型的页面中还有空闲空间来存储 `INODE Entry` 结构
- 这2个链表的基节点就存储在 `File Space Header` 的固定位置， 也就是 `FSP_HDR` 类型的页的一个属性里

## Segment Header  结构的应用

- 一个索引分2个段，分别为叶子节点段和非叶子节点段，每个段都会对应一个 `INODE Entry` 结构
- 那么如何知道某个段是对应哪个 `INOD Entry` 结构呢?
- 记录在数据页 (`INDEX` 类型)的 `Page Header` 的 `PAGE_BTR_SEG_LEAF` 和 `PAGE_BTR_SEG_TOP` 属性里
- 这2个属性都是对应一个较 `Segment Header` 的结构

### Segment Header 的结构

| 名称                             | 占用字节数 | 描述                               |
| -------------------------------- | ---------- | ---------------------------------- |
| `Space ID of the INODE Entry`    | 4          | INODE Entry 结构所在的表空间ID     |
| `Page Number of the INODE ENtry` | 4          | INDOE Entry 结构所在的页面页号     |
| `Byte Offset of the INODE Ent`   | 2          | INODE Entry 结构在该页面中的偏移量 |

所以可知

- `PAGE_BTR_SEG_LEAF` 记录着叶子节点段对应的 `INODE Entry`结构的地址是哪个表空间的哪个页面的哪个偏移量
- `PAGE_BTR_SEG_TOP` 记录着非叶子节点段对应的 `INODE Entry`结构的地址是哪个表空间的哪个页面的哪个偏移量
- 这样索引和其对应的段的关系就建立起来了



# 系统表空间

- 和独立表空间的结构基本类似
- MySQL进程内只有一个系统表空间
- 系统表空间中会额外记录一些有关整个系统信息的页面，所以会比独立表空间多一些页面来记录整个系统信息
- 系统表空间的 `Space ID` 是 `0`

## 整体结构

- 系统表空间和独立表空间的前三个页面(`0`, `1`, `2`, `FSP_HDR`, `IBUF_BITMAP`, `INODE`)的类型是一致的
- 页号为 `3` ~ `7` 的页面是系统表空间独有的

| 页号 | 页面类型  | 英文描述               | 描述                          |
| ---- | --------- | ---------------------- | ----------------------------- |
| `3`  | `SYS`     | Insert Buffer Header   | 存储 Insert Buffer 的头部信息 |
| `4`  | `INDEX`   | Insert Buffer Root     | 存储 `Insert Buffer` 的根页面 |
| `5`  | `TRX_SYS` | Transction System      | 事务系统的相关信息            |
| `6`  | `SYS`     | First Rollback Segment | 第一个回滚段的页面            |
| `7`  | `SYS`     | Data Dictionary Header | 数据字典头部信息              |

- 除了上述记录系统属性的页面外，系统表空间的 `extent 1` 和 `extent 2` 2个区，也就是 `64` ~ `191` 这128个页面被称为 `Doublewrite buffer`, 双写缓冲区

## InnoDB 数据字典

为了更好的管理用户数据，需要记录一些额外的元数据。为此，InnoDB引擎特意定义了一些内部系统表 (internal system table),来记录这些元数据`

| 表名             | 描述                                                   |
| ---------------- | ------------------------------------------------------ |
| SYS_TABLES       | 整个InnoDB引擎中所有的表的信息                         |
| SYS_COLUMNS      | 整个InnoDB引擎中所有的列的信息                         |
| SYS_INDEXES      | 整个InnoDB引擎中所有的索引的信息                       |
| SYS_FIELDS       | 整个InnoDB引擎中所有的索引对应的列的信息               |
| SYS_FOREIGN      | 整个InnoDB引擎中所有的外键的信息                       |
| SYS_FOREIGN_COLS | 整个InnoDB引擎中所有的外键对应的列的信息               |
| SYS_TABLESPACES  | 整个InnoDB引擎中所有的表空间信息                       |
| SYS_DATAFILES    | 整个InnoDB引擎中所有的表空间对应文件系统的文件路径信息 |
| SYS_VIRTUAL      | 整个InnoDB引擎中所有的虚拟生成列的信息                 |

`SYS_TABLES`, `SYS_COLUMNS`, `SYS_INDEXES`, `SYS_FILELDS`这四个表尤其重要，称之为基本系统表(basic system tables)

### SYS_TABLES 表

| 列名         | 描述                                             |
| ------------ | ------------------------------------------------ |
| `NAME`       | 表的名称                                         |
| `ID`         | InnoDB存储引擎中每一个表都有一个唯一的ID         |
| `N_COLS`     | 该表拥有的列的个数                               |
| `TYPE`       | 表的类型，记录了一些文件格式，行格式，压缩等信息 |
| `MIX_ID`     | 已过时，忽略                                     |
| `MIX_LEN`    | 表的一些额外属性                                 |
| `CLUSTER_ID` | 未使用，忽略                                     |
| `SPACE`      | 该表所属表空间的ID                               |
|              |                                                  |

- 该表有2个索引
  - `NAME`为主键的聚簇索引
  - `ID`为列建立的二级索引

### SYS_COLUMNS 表的列

| 列名       | 描述                                                         |
| ---------- | ------------------------------------------------------------ |
| `TABLE_ID` | 该列所属表对应的ID                                           |
| `POS`      | 该列在表中是第几列                                           |
| `NAME`     | 该列的名称                                                   |
| `MTYPE`    | main data type，主数据类型 (INT, CHAR, VARCHAR, FLOAT, DOUBLE) |
| `PRTYPE`   | precise type, 精确数据类型，描述主数据类型的(是否允许NULL，是否允许负数) |
| LEN        | 该列最多占用存储空间的字节数                                 |
| PREC       | 该列的精度，不过貌似没有使用，都是0                          |
|            |                                                              |

- 只有一个聚簇索引 (`TABLE_ID, POS`)

### SYS_INDEXES

| 列名       | 描述                                                     |
| ---------- | -------------------------------------------------------- |
| `TABLE_ID` | 该索引所属表对应的ID                                     |
| `ID`       | InnoDB存储引擎中每个索引都有一个唯一的ID                 |
| `NAME`     | 该索引的名称                                             |
| `N_FIELDS` | 该索引包含列的个数                                       |
| `TYPE`     | 该索引的类型，比如聚簇索引，唯一索引，更改缓冲区的索引等 |
| `SPACE`    | 该索引根页面所在的表空间ID                               |
| `PAGE_NO`  | 该索引根页面所在的页面号                                 |
|            |                                                          |

- 只有一个`TABLE_ID, ID` 列为主键的聚簇索引



### SYS_FIELDS表

| 列名       | 描述                       |
| ---------- | -------------------------- |
| `INDEX_ID` | 该索引列所属的索引的ID     |
| `POS`      | 该索引在某个索引中是第几列 |
| `COL_NAME` | 该索引列的名称             |

#### Data Dictionary Header 页面

只要有了上述4个基本系统表，就意味着可以获取其它系统表以及用户定义的表的所有元数据

比如:

- 到 `SYS_TABLES` 表中根据表名定位到具体的记录，就可以获取到 `SYS_TABLESPACES`表的 `TABLE_ID`
- 使用整个 `TABLE_ID` 到 `SYS_COLUMNS` 表中就可以获取到属于该表的所有列的信息。
- 使用该 `TABLE_ID` 还可以到 `SYS_INDEXES`表中获取所有的索引的信息，索引的信息中包括对应的`INDEX_ID`，还记录着该索引对应的 `B+`树根页面是哪个表空间的哪个页面。
- 使用 `INDEX_ID` 就可以到 `SYS_FIELDS` 表中获取所有索引列的信息。

但是这4个表的`元数据`只能硬编码到代码中

这个就是 页号为 `7` 的页面，也就是 类型为 `SYS` 的 `Data Dictionary Header`，也就是数据字典的头部信息

| 名称                    | 中文名           | 占用空间大小(字节) | 简单描述                                                     |
| ----------------------- | ---------------- | ------------------ | ------------------------------------------------------------ |
| `File Header`           | 文件同步         | 38                 | 页的通用信息                                                 |
| `Data Dictionay Header` | 数据字典头部信息 | 56                 | 记录一些基本系统表的根页面位置以及InnoDB存储引擎的一些全局信息 |
| `Segment Header`        | 段头部信息       | 10                 | 记录本页面所在段对应的INODE Entry 位置的信息                 |
| Empty Space             | 尚未使用空间     | 16272              | 用于页结构的填充，无实际意义                                 |
| File Trailer            | 文件尾部         | 8                  | 校验页是完整                                                 |

`Segment Header`部分说明数据字典的信息也可以被视为一个段，在该段的数据信息比较少的时候，可能就只有本页一个碎片页

###### Data Dictionary Header 部分的各个字段

- `Max Row ID`: 全局共享的 `row_id`，无论哪个表插入时，需要 `row_id`的时候，就会自增
- `Max Table ID`: InnoDB 存储引擎中的所有的表对应一个唯一的ID, 每次新建一个表，就会从这里取值并自增
- `Max Index ID`: InnoDB 存储引擎中的所有的索引都对应一个唯一的ID，每次新建一个索引时，就会从这里取值并自增
- `Max_Space_id`: InnoDB 存储引擎中的所有的表空间都对应一个唯一的ID, 每次新建一个表空间，就会从这里取值并自增
- `Mix ID Low(Unused)`: 无用字段
- `Root of SYS_TABLES clust index`: 本字段代表`SYS_TABLES`表聚簇索引的根页面的页号
- `Root of SYS_TABLE_IDS sec index`: 本字段代表 `SYS_TABLES` 表为ID列建立的二级索引的根页面的页号
- `Root of SYS_COLUMNS clust index`: 本字段代表 `SYS_COLUMNS` 表聚簇索引的根页面的页号
- `Root of SYS_INDEXES clust index`: 本字段代表 `SYS_INDEXES` 表聚簇索引的根页面的页号
- `Root of SYS_FIELDS clust index`: 本字段代表 `SYS_FIELDS` 表聚簇索引的根页面的页号
- `Unused`: 这4个字节没有用处。

##### information_schema系统数据库

系统库 `information_schema` 中提供了一些以 `innodb_sys` 开头的库，可以查看

SHOW TABLE LIKE `innodb_sys%`



要注意数据是 存储引擎启动的时候读取并填充的，所以和运行时的数据可能并不一致

