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

### 
