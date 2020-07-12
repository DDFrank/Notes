# 基本概念

## 消费者

- 负责订阅 kafka 中的 topic, 并且从订阅的 topic 上拉取消息

## 消费组

- 每个消费者都属于某一个消费组。当消息被投递到主题后，只会被投递给消费组中的某一个消费者,即，单个消费组的所有消费者轮询该topic的消息
- 当消费组中有消费者加入或退出时，会进行分区重排
- 分区分配策略可以用消费者端参数 `partition.assignment.strategy` 来设置消费者与订阅主题之间的分区分配策略
- 消费组的名称用 消费者客户端参数 `group.id ` 来指定，默认为空字符串

# 客户端开发

## 重要的参数配置

### bootstrap.servers

- **,** 隔开的服务器地址, 不需要填写全部地址，因为 kafka 生产者会从初始的服务器中获取整个集群的元数据，但建议至少填2个

### **key.serializer** 和 **value.serializer**

- 必填项，无默认值, key 和 value 的序列化器, 用于将指定结构序列化为 字节数组， 供 broker 接收

### group.id

- 消费组的名称, 默认为`""`

### enable.auto.commit

- 默认值为 `true`, 为 true 时，消费者会定期提交。
-  定期提交的时间间隔由 `auto.commit.interval.ms` 配置，默认值为 5000

### auto.offset.reset

- 默认值为 `"latest"` 
- 当消费者找不到所记录的消费位移时，会根据该配置决定从何处开始消费
- `"lastest" ` : 表示从分区的末尾开始消费，也就是不会去回溯过去的消息
- `"earliest"`: 会从0开始消费消息
- `"none"`: 找不到消费位移时，会抛出 `NoOffsetForPartitionException` 异常

### fetch.min.bytes

- Consumer 一次拉取的最小的消息的size，默认为 `1` B,
- 假如 Broker 收到拉取请求时，能返回的数据的量小于这个值时，那么就会阻塞等待直到超过这个大小

### fetch.max.bytes

- Consumer 一次拉取的最大的消息的size, 默认为 `52428800` B, 也就是50M
- 即使该参数比 任何一条消息的大小都小一些，那么也能至少消费一条消息

### fetch.max.wait.ms

- 设定Consumer等待消息的最大时间，默认为 `500`ms

### max.partition.fetch.bytes

- Consumer 能从单个分区拉取的最大消息数据量, 默认为 `1048576` B, 即 1M

### max.poll.records

- Consumer 在一次拉取请求中拉取的最大消息数，默认值为 `500`条

### connections.max.idle.ms

- 指定多久后关闭空闲连接，默认值是 `540000`(ms), 即9分钟

### exclude.internal.topics

- 用来指定 Kafka的内部主题是否可以公开, 默认值为 `true`
- 设置为 `true` 时，只能使用指定主题名来进行订阅，而不能使用 正则表达式

### receive.buffer.bytes

- 默认值为 `32768` (B) , 32KB，用来设置Socket接收消息缓冲区(SO_RECBUF)大小
- 设置为 -1 的话，就使用系统的默认值

### send.buffer.bytes

- 默认值为 `131072`(B), 即128KB，用来设置 Socket发送消息缓冲区(SO_SNDBUF)的大小
- 设置为-1的话，就是要系统的默认值

### request.timeout.ms

- consumer 等待请求响应的最大时间，默认值 `30000` ms

### metadata.max.age.ms

- 配置元数据的过期时间，默认为 `300000` ms, 即 5分钟

### reconnect.backoff.ms

-  这个参数用来配置尝试重新连接指定主机之前的等待时间（也称为退避时间），避免频繁地连接主机，默认值为`50`（ms）
- 这种机制适用于消费者向 broker 发送的所有请求。

### retry.backoff.ms

- 这个参数用来配置尝试重新发送失败的请求到指定的主题分区之前的等待（退避）时间，避免在某些故障情况下频繁地重复发送，默认值为`100`（ms）



## 订阅主题和分区

主要有以下几个方法

```java
// 使用集合的方式进行订阅
public void subscribe(Collection<String> topics, 
    ConsumerRebalanceListener listener)
public void subscribe(Collection<String> topics)
// 根据正则表达式进行订阅
public void subscribe(Pattern pattern, ConsumerRebalanceListener listener)
public void subscribe(Pattern pattern)
// 指定分区
public void assign(Collection<TopicPartition> partitions)
```

### 使用集合的方式来订阅主题

- 订阅多次时，以最后一次订阅为准

### 使用正则表达式的方式进行订阅

- 订阅后，假如有符合正则表达式的主题被创建，那么就会自动进行订阅

### 直接订阅某些特定主题的特定分区

- 无

- 三种方式的消费者的订阅状态分别是
  - AUTO_TOPICS
  - AUTO_PATTERN
  - USER_ASSIGNED
- 三种订阅状态是互斥的，在一个消费者中只能使用其中的一个



## 反序列化

- 实现 `org.apache.kafka.common.serialization.Deserializer` 接口
- 指定 `key.deserializer` 和 `value.deserializer` 为自定义的反序列器即可

## 

## 消息消费

- Kafka 的消息是基于拉模式的, 是一个不断轮询的过程

```java
// 当消费者的接收缓冲区中没有数据时，会发生阻塞, timeout 是最大的阻塞时间
// 超时时，会返回一个空集合
public ConsumerRecords<K, V> poll(final Duration timeout)
```

- 可以根据获取 指定 topic 的消息集合，也可以获取指定 topic 和 分区的消息列表



## 位移提交

- 消费位移存储在 kafka 的内部主题 `__consumer_offsets` 中
- 假如用 x 表示某个消费者一次拉取的分区消息中的最大偏移量，那么其本次提交的消费位移为 x + 1 
- consumner 中有API可以获取

```java
// 获取消费者需要拉取的下一条消息的偏移量
public long position(TopicPartition partition)
// 获取消费者上一次提交的消费位移
public OffsetAndMetadata committed(TopicPartition partition)
```

### 自动提交

- 处理起来比较简单，但是有可能造成重复消费和消息丢失

### 手动提交

#### 同步提交

- 同步提交会根据 poll 拉取到的最大的位移值进行提交
- 假如需要细粒度的控制提交的位移,那么

```java
public void commitSync(final Map<TopicPartition, OffsetAndMetadata> offsets)
```

#### 异步提交

- 会在回调里告知处理结果，性能较好

### 控制和关闭消费

- consumer 中可以控制消费速度

```java
// 暂停拉取对某个主题分区的消息的拉取
public void pause(Collection<TopicPartition> partitions)
// 开启对某个主题分区的消息的拉取
public void resume(Collection<TopicPartition> partitions)
// 被暂停的主题分区
public Set<TopicPartition> paused()
```



## 指定位移消费

- 使用 `seek` 方法

```java
public void seek(TopicPartition partition, long offset)
```

- `seek()` 方法中的参数 partition 表示分区，而 offset 参数用来指定从分区的哪个位置开始消费。seek() 方法只能重置消费者分配到的分区的消费位置，而分区的分配是在 `poll()` 方法的调用过程中实现的。也就是说，在执行 `seek()` 方法之前需要先执行一次 `poll()` 方法，等到分配到分区之后才可以重置消费位置
- 可以直接指定消费分区的开头和分区的末尾的消息

```java
// 将消费位移指定到分区的开头
public void seekToBeginning(Collection<TopicPartition> partitions)
// 将消费位移指定到分区的末尾
public void seekToEnd(Collection<TopicPartition> partitions)
```

- 获取某个时间点后的第一条消息的位移

```java
public Map<TopicPartition, OffsetAndTimestamp> offsetsForTimes(
            Map<TopicPartition, Long> timestampsToSearch)
public Map<TopicPartition, OffsetAndTimestamp> offsetsForTimes(
            Map<TopicPartition, Long> timestampsToSearch, 
            Duration timeout)
```

### 位移越界

- 位移越界是指直到消费位置，但是无法在实际的分区中找到
- 此时会根据 `auto.offset.reset` 参数来决定消费位移是什么



## Reblance

- 分区的所属权从一个消费者转移到另一消费者的行为

- 为消费组具备高可用性和伸缩性提供保障，可以既方便又安全地删除消费组内的消费者或往消费组内添加消费者

- 再均衡发生期间，消费组内的消费者是无法读取消息的

- 当一个分区被重新分配给另一个消费者时，消费者当前的状态也会丢失, 所以可能出现重复消费

  

### Reblance 监听器

ConsumerRebalanceListener` 在订阅的接口可以提供一个 监听器，用来在发生 Reblance 的时候执行一些自定义的逻辑

```java
Map<TopicPartition, OffsetAndMetadata> currentOffsets = new HashMap<>();
@Override
public void onPartitionsRevoked(Collection<TopicPartition> partitions) {
  // 发生 Reblance 之前提交 消费位移
  consumer.commitSync(currentOffsets);
  currentOffsets.clear();
}
@Override
public void onPartitionsAssigned(Collection<TopicPartition> partitions) {
  //do nothing.
}
```

## 拦截器

- 实现 `org.apache.kafka.clients.consumer. ConsumerInterceptor` 接口

```java
// 在 poll 方法返回前对消息进行定制
public ConsumerRecords<K, V> onConsume(ConsumerRecords<K, V> records)；
// 提交完消费位移后调用
public void onCommit(Map<TopicPartition, OffsetAndMetadata> offsets)；
public void close()
```

- 通过 `INTERCEPTOR_CLASSES_CONFIG` 配置来指定拦截器
- 在消费者中也有拦截链的概念，和生产者的拦截链一样，也是按照 interceptor.classes 参数配置的拦截器的顺序来一一执行的（配置的时候，各个拦截器之间使用逗号隔开）。同样也要提防“副作用”的发生。如果在拦截链中某个拦截器执行失败，那么下一个拦截器会接着从上一个执行成功的拦截器继续执行



## 



