# 基础数据结构

## string

可变的字节数组,类似于 ArrayList

最大长度 512M

### 语法

#### 初始化字符串: 变量名称 变量内容

```shell
set ireader baobao.chi.caocao
```

#### 获取字符串内容: 变量名称

```shell
get ireader
```

#### 获取字符串名称: 名字

```shell
strlen ireader
```

#### 获取子串: 名称 开始(0开始) 结束位置(含结尾)

```shell
getrange ireader 7 10
```

#### 覆盖子串: 变量名 开始位置 子串

```shell
setrange 7 yao
baobao.yao.caocao
```

#### 追加子串: 名字 追加的子串

```
append ireader .hao
"baobao.yao.caocao.hao"
```

#### 计数器:整数的话可以做计数器用

```shell
127.0.0.1:6379> set ireader 42
OK
127.0.0.1:6379> incrby ireader 100
(integer) 142
127.0.0.1:6379> decrby ireader 99
(integer) 43
127.0.0.1:6379> incr ireader
(integer) 44
127.0.0.1:6379> decr ireader
(integer) 43
```

计数器不能超过 Long.Max, 也不能小于 Long.Min

#### 过期和删除

- 字符串可以使用 del 指令删除
- 可以使用 expire 指令设置过期时间,到点自动删除
- 可以使用 ttl 指令获取字符串的寿命

```shell
127.0.0.1:6379> expire ireader 60
(integer) 1
127.0.0.1:6379> ttl ireader
(integer) 52
127.0.0.1:6379> del ireader
(integer) 1
```



## list

使用的是双向链表

随机定位性比较弱，首尾插入删除性能较优

### 负下标

使用 0 开始的下标，负数表示倒数



### 队列/堆栈 

使用 rpush rpop lpush lpop 四条指令可以将链表作为队列或堆栈，左向右向均可

```shell
# 右进左出
127.0.0.1:6379> rpush ireader go
(integer) 1
127.0.0.1:6379> rpush ireader java python
(integer) 3
127.0.0.1:6379> lpop ireader
"go"
127.0.0.1:6379> lpop ireader
"java"
127.0.0.1:6379> lpop ireader
"python"
127.0.0.1:6379> get ireader
(nil)
```

在日常中，列表经常作为异步队列来使用

### 长度: llen指令

```shell
127.0.0.1:6379> lpush ireader go java python
(integer) 3
127.0.0.1:6379> llen ireader
(integer) 3
```

### 随机读

- 使用 lindex 指令访问指定位置元素
- lrange 指令获取链表子元素列表，需要 start end 下标参数

```shell
127.0.0.1:6379> lindex ireader 1
"java"
127.0.0.1:6379> lrange ireader 0 -1
1) "python"
2) "java"
3) "go"
4) "go"
5) "java"
6) "python"
```

### 修改元素:lset指令

```powershell
127.0.0.1:6379> lset ireader 1 javascript
OK
127.0.0.1:6379> lrange ireader 0 -1
1) "python"
2) "javascript"
3) "go"
4) "go"
5) "java"
6) "python"
127.0.0.1:6379>
```

### 插入元素

- 使用linsert指令
- 使用方向参数 before/after 来指示从前插入还是从后
- 由于是根据值来判断位置，所以在分布式环境下，元素的下标位置经常变换

```shell
127.0.0.1:6379> linsert ireader before java ruby
(integer) 7
127.0.0.1:6379> lrange ireader 0 -1
1) "python"
2) "javascript"
3) "go"
4) "go"
5) "ruby"
6) "java"
7) "python"
127.0.0.1:6379>
```

假如有多个重复元素，只会找到第一个然后在其前后插入

不常用

### 删除元素

- 不是通过下标
- 需要指定删除的最大个数以及元素的值

```shell
127.0.0.1:6379> lrem ireader 2 go
(integer) 2
127.0.0.1:6379> lrange ireader 0 -1
1) "python"
2) "javascript"
3) "ruby"
4) "ruby"
5) "java"
6) "python"
```

### 定长列表

指令是 ltrim 需要提供 start end两个参数，表示需要保留列表的下标范围

```shell
127.0.0.1:6379> rpush ireader go java python javascript ruby erlang rust cpp
(integer) 8
127.0.0.1:6379> ltrim ireader -3 -1
OK
127.0.0.1:6379> lrange ireader 0 -1
1) "erlang"
2) "rust"
3) "cpp"
```

- 再添加元素就不是原来的那个长度了
- 假如 end 对应的真实下标小于 start 效果等价于 del

### 快速列表

Redis 的底层特性,待补完



## hash

- 类似于 Java 的 HashMap
- 使用二维结构，一维是数组，二维是链表
- hash 的内容key和value放在链表汇总
- 数组里存放链表的头指针

### 增加元素

- hset 一次增加一个键值对
- Hmset 一次增加多个键值对

```shell
127.0.0.1:6379> hset ireader go fast
(integer) 1
127.0.0.1:6379> hmset ireader java fast python slow
OK
```

### 获取元素

- hget 定位具体 key对应的value
- hmget 根据多个key获取value
- hgetall 获取所有的键值对
- hkeys 获取 key 列表
- Hvals 获取 value列表

```shell
127.0.0.1:6379> hmset ireader go fast java fast python slow
OK
127.0.0.1:6379> hget ireader go
"fast"
127.0.0.1:6379> hmget ireader go python
1) "fast"
2) "slow"
127.0.0.1:6379> hgetall ireader
1) "go"
2) "fast"
3) "java"
4) "fast"
5) "python"
6) "slow"
127.0.0.1:6379> hkeys ireader
1) "go"
2) "java"
3) "python"
127.0.0.1:6379> hvals ireader
1) "fast"
2) "fast"
3) "slow"
127.0.0.1:6379>
```

### 删除元素

- hdel 删除指定key ,支持同时删除多个



### 判断元素是否存在

- 通常使用 hget 判断获取的是否为空即可
- 如果 value 的字符串特别大，通过这种方式来判断就不太好,使用 hexists 指令

```shell
127.0.0.1:6379> hmset ireader go fast java fast python slow
OK
127.0.0.1:6379> hexists ireader go
(integer) 1
```

### 计数器

- 内部的每一个 key 都可以当做独立的计数器，如果 value 不是整数，就会出错

```shell
127.0.0.1:6379> hset ireader go 1
(integer) 1
127.0.0.1:6379> hincrby ireader go 1
(integer) 2
```

###  扩容和缩容

Redis 的底层优化机制,待补完



## set

跟 Java的 HashSet 实现类似

### 增加元素

- sadd 可以一次增加多个元素

### 读取元素

- 使用 smembers 列出所有元素
- 使用 scard 获取集合长度
- 使用 srandmember 获取随机count个元素,默认为1, 不会删除元素

```shell
127.0.0.1:6379> sadd ireader go java python
(integer) 3
127.0.0.1:6379> smembers ireader
1) "go"
2) "python"
3) "java"
127.0.0.1:6379> scard ireader
(integer) 3
127.0.0.1:6379> srandmember ireader
"python"
```

### 删除元素

- srem 删除 一到多个元素
- spop 删除随机一个元素

```shell
127.0.0.1:6379> srem ireader go java
(integer) 2
127.0.0.1:6379> spop ireader
"python"
```

###  判断元素是否存在

- 使用 sismember ，只能判断单个元素



## sortedset

- 等价于 Map<String, Double> Double(是权重)
- 内部按照 score 排序
- zset 使用hash和跳跃列表两个数据结构，后者用于排序

###  增加元素

- zadd 增加一到多个 value/score,score放在前面

```shell
127.0.0.1:6379> zadd ireader 4.0 python
(integer) 1
127.0.0.1:6379> zadd ireader 4.0 java 1.0 go
(integer) 2
```

### 长度

- zcard 指令

### 删除元素

- zrem 可以一次删除多个, 返回值 是 被删除的数量
  - 假如被删除的元素不在 集合中，会忽略
  - 假如不是 有序集合，会报错

###  计数器

- 同 hash 结构

```shell
127.0.0.1:6379> zadd ireader 4.0 python 4.0 java 1.0 go
(integer) 3
127.0.0.1:6379> zincrby ireader 1.0 python
"5"
```

###  获取排名和分数

- 通过 zscore 指令获取指定元素的权重
- 通过 zrank 获取指定元素的正向排名
- 通过 zrevrank 获取指定元素的反向排名

```shell
127.0.0.1:6379> zadd ireader 4.0 python 4.0 java 1.0 go
(integer) 3
127.0.0.1:6379> zrank ireader go
(integer) 0
127.0.0.1:6379> zrank ireader java
(integer) 1
127.0.0.1:6379> zrank ireader python
(integer) 2
127.0.0.1:6379> zrevrank ireader python
(integer) 0
```

### 根据排名范围获取元素列表

- 通过 zrange 指令指定排名范围参数获取对应的元素列表,系列 withscores 可以一并获取权重

- 通过 zrevrange 指令按负向排名获取元素列表

  ```shell
  127.0.0.1:6379> zrange ireader 0 -1 # 获取全部
  1) "go"
  2) "java"
  3) "python"
  127.0.0.1:6379> zrange ireader 0 -1 withscores
  1) "go"
  2) "1"
  3) "java"
  4) "4"
  5) "python"
  6) "4"
  127.0.0.1:6379> zrevrange ireader 0 -1 withscores
  1) "python"
  2) "4"
  3) "java"
  4) "4"
  5) "go"
  6) "1"
  ```

  ### 根据 score 范围获取列表

  - 通过 zrangebyscore 指令指定 score 范围获取对应的元素列表
  - 通过 zrevrangebyscore 指令获取倒排元素列表。 参数 -inf 表示负无穷, +inf 表示正无穷

  ```shell
  127.0.0.1:6379> zrangebyscore ireader 0 5
  1) "go"
  2) "java"
  3) "python"
  127.0.0.1:6379> zrangebyscore ireader -inf +inf withscores
  1) "go"
  2) "1"
  3) "java"
  4) "4"
  5) "python"
  6) "4"
  127.0.0.1:6379> zrevrangebyscore ireader +inf -inf withscores
  1) "python"
  2) "4"
  3) "java"
  4) "4"
  5) "go"
  6) "1"
  ```

  ### 根据 范围移除元素列表

  可以通过排名范围，也可以通过score范围来一次性移除多个元素

  ```shell
  127.0.0.1:6379> zadd ireader 4.0 python 3.0 java 1.0 go
  (integer) 3
  127.0.0.1:6379> zremrangebyrank ireader 0 1
  (integer) 2
  127.0.0.1:6379> zadd ireader 4.0 java 1.0 go
  (integer) 2
  127.0.0.1:6379> zremrangebyscore ireader -inf 4
  (integer) 3
  127.0.0.1:6379> zrange ireader 0 -1
  (empty list or set)
  ```

  ### 跳跃列表

  复杂，待补完



  # 分布式锁

  本质上需要在 Redis 中加锁,当别的进程要操作统一数据时等待锁释放

  - 加锁使用 setnx

  - 使用完毕后使用 del 指令删除锁

  ```shell
  127.0.0.1:6379> setnx lock true
  (integer) 1
  127.0.0.1:6379> del lock
  (integer) 1
  ```

  - 假如中间执行逻辑出问题了， del 指令没有调用,锁就无法释放,所以1

  - 所以需要给锁加上过期时间

  ```shell
  127.0.0.1:6379> setnx lock true
  (integer) 1
  127.0.0.1:6379> expire lock 5
  (integer) 1
  127.0.0.1:6379> get lock
  ```

  - 以上方法不安全，因为 setnx 和 expire 也不是原子操作

## 使用 set 的拓展指令参数让加锁和过期成为一个原子操作

```shell
> set lock true ex 5 nx
```

## 超时问题

假如加锁和释放锁之间的逻辑执行时间超过了锁的超时限制，就会造成锁被提前释放了

所以 分布式锁不要用于过长时间的任务

## 可重入性

指线程在持有锁的情况下再次请求加锁，如果一个锁支持同一个线程的多次加锁

那么就是可重入的。

需要客户端实现，比较复杂，尽量别用。

分布式锁可以用 zookeeper来实现exi



# 延时队列

Redis 可以适用于一些简单的消息队列场景

##  异步消息队列

- list常被用来做消息队列， rpush/lpush 操作入队列，lpop rpop出队列

## 队列延迟

- 客户端休眠方法会导致消息延迟
- 使用 blpop/brpop，阻塞读，也就是队列没有数据时休眠，数据来时立刻醒

### 空闲时自动断开

- 假如线程一直阻塞，Redis的客户端就成了闲置连接,服务器可能会断开连接
- 所以客户端需要捕获异常，还需要有重试的机制

### 锁冲突处理

假如客户端加锁没成功，一般有三种处理方式

- 直接抛出特定异常
- sleep 一会再重试,这个会阻塞当前线程，不太好
- 将请求转移至延时队列，过一会再试,这个比较适合异步消息处理

### 延时队列的实现

延时队列可以通过 Redis 的 zset 来实现

- 将消息序列化为一个字符串 作为 zset 的 value
- 消息的到期处理时间为 score
- 多个线程轮询 zset 获取到期的任务进行处理,多个线程是为了保障可用性
  - 也就是每次都 以zrangeByScore  0 ~ 当前时间 取出可以消费的消息
  - 要是没有可以消费的，那就 sleep 一会
  - 要是有可以消费的，就使用 zrem 查看任务是不是被自己抢到了,是的话就消费消息

### 思考

- 多个线程争抢同一个任务，有一些资源浪费，可以考虑使用 lua 将 zrangbyscore 和 zrem 一同挪到服务器端进行原子化操作
- 完全没有考虑 ack，不适合可靠性要求比较高的场合
- 感觉不如用RabbitMQ监听算了



# 位图

- 为了存储bool型数据，提供了 位图结构 (比如用户的签到数据)
- 位图其实就是 byte 数组,可以使用 get/set 直接获取和设置整个位图的内容,也可以使用 getbit/setbit 等将 byte 数组看成 位数组来处理

## 基本使用

- 使用 setbit 和 getbit
- 位数组是自动扩容的，如果设置了某个偏移位置超过了现有的内容范围，就会自动将位数组进行零扩充
- 位数组的顺序和字符的位顺序是相反的
- 以下为零存整取

```shell
# h 是 01101000 e 是 01100101
127.0.0.1:6379> setbit s 1 1
(integer) 0
127.0.0.1:6379> setbit s 2 1
(integer) 0
127.0.0.1:6379> setbit s 4 1
(integer) 0
127.0.0.1:6379> setbit s 9 1
(integer) 0
127.0.0.1:6379> setbit s 10 1
(integer) 0
127.0.0.1:6379> setbit s 13 1
(integer) 0
127.0.0.1:6379> setbit s 15 1
(integer) 0
127.0.0.1:6379> get s
"he"
```

- 以下为零存零取

```shell
127.0.0.1:6379> setbit w 1 1
(integer) 0
127.0.0.1:6379> setbit w 2 1
(integer) 0
127.0.0.1:6379> setbit w 4 1
(integer) 0
127.0.0.1:6379> getbit w 1
(integer) 1
127.0.0.1:6379> getbit w 2
(integer) 1
127.0.0.1:6379> getbit w 4
(integer) 1
127.0.0.1:6379> getbit w 5
(integer) 0
```

- 以下为整存零取

```shell
127.0.0.1:6379> set w h
OK
127.0.0.1:6379> getbit w 1
(integer) 1
127.0.0.1:6379> getbit w 2
(integer) 1
127.0.0.1:6379> getbit w 4
(integer) 1
127.0.0.1:6379> getbit w 5
(integer) 0
```

## 统计和查找

- 位图统计指令：bitcount 统计指定位置范围内 1 的个数, 后接 start end 参数，是字节的索引,也就是指定的位范围必须是 8的倍数，而不能任意指定
- 位图查找指令: bitpos 查找指定范围内出现的第一个0或1

```shell
127.0.0.1:6379> set w hello
OK
127.0.0.1:6379> bitcount w
(integer) 21
127.0.0.1:6379> bitcount w 0 0 # 第一个字符中 1 的位数
(integer) 3
127.0.0.1:6379> bitcount w 0 1 # 前两个字符中 1 的位数
(integer) 7
127.0.0.1:6379> bitpos w 0
(integer) 0
127.0.0.1:6379> bitpos w 1
(integer) 1
127.0.0.1:6379> bitpos w 1 1 1 # 从第二个字符算起，第一个 1 位
(integer) 9
127.0.0.1:6379> bitpos w 1 2 2 # 从第三个字符算起，第一个 1 位
(integer) 17
127.0.0.1:6379> bitpos w 1 2 3
(integer) 17
127.0.0.1:6379> bitpos w 1 2 10
(integer) 17
127.0.0.1:6379> bitpos w 1 3 10
(integer) 25
```

## 魔术指令 bitfield

- setbit 和 getbit 指定位的值都是单个位的。如果要一次操作多个位，就必须使用管道来处理
- 3.2 以后增加了新功能 bitfield ，它有三个子指令
  - get
  - set
  - incrby
- 三个指令都可以对指定位片段进行读写，但是最多只能处理64个连续的位，如果超过64位，就得使用多个指令, bitfield 可以使用多个指令

```shell
127.0.0.1:6379> set w hello
OK
127.0.0.1:6379> bitfield w get u4 0 # 从第一位开始取4位，结果当作无符号数, 0110 => 6
1) (integer) 6
127.0.0.1:6379> bitfield w get u5 0 # 从第一位开始取5位, 无符号 01101 => 13 
1) (integer) 13
127.0.0.1:6379> bitfield w get u3 2
1) (integer) 5
127.0.0.1:6379> bitfield w get i4 2 # 从第三位开始取4位，有符号 1010 按位取反并补码 1110 = -6
1) (integer) -6
127.0.0.1:6379> bitfield w get i3 2 # 从第三位开始取3位，有符号 101 按位取反并补码为(通用处理方法) 111 = -3
1) (integer) -3
# 一次执行多个指令
127.0.0.1:6379> bitfield w get u4 0 get u3 2 get i4 0 get i3 2
1) (integer) 6
2) (integer) 5
3) (integer) 6
4) (integer) -3
```

- 使用 set 指令将第二个字符 e 改为 a, a的 ASCII 码是 97，返回旧值

```shell
127.0.0.1:6379> bitfield w set u8 8 97 # 从第9位开始，将接下来的8个为用无符号数 97 替换
1) (integer) 101
127.0.0.1:6379> get w
"hallo"
```

- incrby 自增的话可能会出现溢出，默认的处理是折返
- 如果出现了溢出，就把溢出的符号位丢掉。比如8位无符号数 255, 加 1 就会溢出，会全部变为0
- 如果 8 位有符号数 127, 加 1后就会溢出变成 -128

```shell
127.0.0.1:6379> set w hello # h 的二进制 01101000
OK
127.0.0.1:6379> bitfield w incrby u4 2 1 # 从第三个位开始，对接下来的 4 位无符号数 + 1 
# 从 1010 变为 1011 1011 就是11
1) (integer) 11
127.0.0.1:6379> bitfield w incrby u4 2 1
# 
1) (integer) 12
127.0.0.1:6379> bitfield w incrby u4 2 1
1) (integer) 13
127.0.0.1:6379> bitfield w incrby u4 2 1
1) (integer) 14
127.0.0.1:6379> bitfield w incrby u4 2 1
1) (integer) 15
127.0.0.1:6379> bitfield w incrby u4 2 1
# 1111 加1 后溢出了，根据折返策略变为了 0000
1) (integer) 0
127.0.0.1:6379> get w # 此时 @ 的二进制 01000000 只是将 1111 转为了 0000
"@ello"
```

- Bitfield 指令提供了溢出策略子指令 用户可以选择其行为
  - 默认是折返 wrap
  - fail 报错不执行
  - sat 饱和截断 超过了范围就停留在最大最小值
  - 该指令只影响接下来的第一条指令

### 

# HyperLogLog

##  使用方法

- pfadd 增加计数 跟 zadd 挺像,但是这个会判断重复元素，如果是重复元素就不让加
- pfcount 直接获取计数 跟 scard 用法一致
- pfmerge 用于将多个 pf 计数值加在一起形成一个新的 pf 值

## 注意

hyperLogLog 在数据比较多时，会占据 12k 左右的空间

## 实现原理

看不懂，待补完,估计以后也很难看懂

## 使用场景

- 统计UV





# 布隆过滤器

- 专门用来做去重的
- 是一个不怎么精确的 set 结构，当使用其 contains 方法判断某个对象是否存在时，可能会误判
- 当布隆过滤器说某个值存在时，这个值可能不存在，当它说不存在时，是肯定不存在的

## 基本使用(4.0 以后才有, 需安装插件)

- bf.add 添加元素
- bf.exists 查询元素是否存在
- bf.madd 一次添加多个元素
- bf.mexists 一次查询多个元素是否存在

##  自定义参数

Redis 提供了自定义参数的布隆过滤器,需要在 add 之前使用 bf.reserve 指令显式创建

它有三个参数

- key
- error_rate 错误率越低，需要的空间越大 默认是 0.01
- intial_size 表示预计放入的元素数量, 默认是 100, 小了错误率飙升，大了占空间

## 使用场景

- 比如推送新闻的去重

# 简单限流

- 当系统的处理能力有限时，应当阻止计划外的请求继续对系统施压
- 除了控制流量，还可以用于控制用户行为，比如发帖，点赞，回复等行为都需要规定在一定时间的次数，超过即非法行为

## 解决方案

- 每个用户对应的一种需要约束的行为建一个 zset
- 用户的该次行为发生的 timestamp 作为 value 和 score 存入 zset
- 每次发生的时候做如下判断
  - 清除规定时间内的过期记录（比如1分钟内只能回复五次，那么就把当前时间一分钟前的数据都删掉）
  - 根据 score 得到 zset 内的数据数量
  - 给 zset 设置超时时间(避免用户长时间不操作还留着这个 zset)
  - 判断次数是否过多

- 可以使用 pipline 优化存取效率
- 假如规定的限制量比较大，那么就不太适合(比如 60s 内不超过 100W次)

# 漏斗限流

- 最常用的限流算法

## 解释

- 漏斗的容量是有限的
- 假如漏嘴流水的速率大于灌水的速率,那么漏斗永远都装不满
- 假如漏嘴流水速率小于灌水的速率，那么一旦满了，灌水就需要暂停
- 漏斗的剩余空间就代表着当前行为可以持续进行的数量
- 漏嘴的流水速率代表着系统允许该行为的最大频率

## Redis-cell模块用法

- 只有一条指令 cl.throttle,下面是参数

  - key 的名字
  - 漏斗容量
  - 多少个操作 (次)
  - 允许的时间(秒)
  - 可选，默认为1

  ```shell
  clthrottle baobao:reply 15 30 60 1
  # 用户包包的行为频率为 每 60s 最多30次，
  # 初始容量为15，也就是一开始可以进行15次，然后开始漏水
  ```

- 以下是返回值
  - 0 / 1 允许 / 拒绝
  - 漏斗容量
  - 漏斗剩余空间
  - 如果拒绝了，需要多长时间再试
  - 多长时间后，漏斗完全空出来

- 这个模块好像挺难安装的



# GeoHash

- 是一个算法, Redis 基于此实现了一个Geo模块
- 可以用来实现类似 附近的餐馆 之类的功能

## 算法原理

很复杂，看不懂

## Geo指令的使用

- 只是一个普通的 zst

### 增加

- 携带集合名称以及多个维度名称，可以加入多个s

```shell

```

### 删除

- 可以使用 zset 的指令

### 距离

- geolist 计算两个元素之间的距离，携带集合名称 2个名称和距离单位

```shell

```

### 获取元素位置

- geopos 可以同时获取多个

```shell

```

### 获取元素的hash值

- geohash 是base32编码

### 附近的公司

- georadiusbymember 参数如下
  - 



# Scan

- 用于从海量的 key 中找出满足特定前缀的 key 列表
- keys 利用正则来找

## Scan 的使用

- 三个参数
  - curor，游标，第一次为0，然后将返回结果中的第一个整数值作为下一次遍历的 cursor,一直到返回0为止
  - key 的正则模式
  - 遍历的 limit hint
