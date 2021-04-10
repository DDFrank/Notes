# 基本概念

### producer

消息的生产者

### consumer

消息的消费者

### broker

服务代理节点, 也就是kafka的实例 

# 客户端开发

## 重要参数

### **bootstrap.servers**

- 必填项
- **,** 隔开的服务器地址, 不需要填写全部地址，因为 kafka 生产者会从初始的服务器中获取整个集群的元数据，但建议至少填2个

### **key.serializer** 和 **value.serializer**

- 必填项，无默认值, key 和 value 的序列化器, 用于将指定结构序列化为 字节数组， 供 broker 接收

### retries

-  对于可重试的异常的消息的重试次数，默认为0

### acks

- 分区中必须有多少副本收到这条消息后，生产者才会认为这条消息是成功写入的 （字符串类型）
  - acks = 1: 默认值
    - 只要分区的 leader 副本写入该消息，那么客户端就会收到来自服务器的成功响应
    - 假如leader副本写入后，但是在其它 follow 副本同步完成之前崩溃了，那么该消息就丢失了
    - 这是吞吐量和可靠性的折中方案
  - acks =0: 吞吐量最大，即不需要确认即认为消息发送成功
  - acks = -1 或 all: 可靠性最大
    - 消息发送后，需要等待ISR中的所有副本都成功写入该消息后才能够收到服务器的成功响应
    - 假如 ISR中只有leader副本，那其实就退化为了 acks = 1， 要提高可靠性需配合 min.insync.replicas 参数来使用

### max.request.size

- 这个参数用来限制生产者客户端能发送的消息的最大值，默认值为1048576B，即1MB。一般情况下，这个默认值就可以满足大多数的应用场景了
- 这个参数可能和 其它 参数有联动效应，比如 broker 端的 `message.max.bytes`  参数指定了能接收的最大参数

### retries和retry.backoff.ms

- `retries` 表示客户端在遇到可以重试的异常后，尝试重试发送消息的次数, Integer 类型
- `retry.backoff.ms` 表示重试需要的等待间隔, Integer 类型, ms

### max.in.flight.requests.per.connection 

- 单个连接所能发送的未被ack的消息的最多数量
- 假如该值 大于1， 而且 `retries` 配置也大于1，那么可能会出现消息乱序的现象
  - A 消息和 B 消息处于同一个 batch ,然后 A 消息发送成功了，B消息发送失败了, A消息再去重发，属性就在B消息之后了
- 为了严格避免消息乱序，可以将该值设置为 1 ,当然，这肯定对吞吐量有影响

### compression.type

- 默认值为 `none` 即消息不会被压缩
- 时间换空间的策略，如果对延时有要求，则不推荐消息进行压缩

### connection.max.idle.ms

- 指定多久之后关闭空闲连接，默认值为 `540000`(ms) ，即9分钟

### linger.ms

- 默认值为 `0`, 该参数用于指定生产者发送 ProductBatch 之前等待更多消息 (ProducerRecord) 加入 ProductBatch的时间
- 生产者客户端会在 ProducerBatch 被填满或等待时间超过 `linger.ms` 值时发送出去
- 增加该配置的值可以提高吞吐量，但是同时也会提高消息延时

### receive.buffer.bytes

- 默认值为 `32768` (B) , 32KB，用来设置Socket接收消息缓冲区(SO_RECBUF)大小
- 设置为 -1 的话，就使用系统的默认值

### send.buffer.bytes

- 默认值为 `131072`(B), 即128KB，用来设置 Socket发送消息缓冲区(SO_SNDBUF)的大小
- 设置为-1的话，就是要系统的默认值

### request.timeout.ms

- 默认值为 `30000`(ms),指定生产者等待 Broker 回应的最大时间,假如超时了，可以选择重试
- TODO 注意这个参数要比 Broker 端参数 `replica.lag.time.max.ms` 值要大，这样可以减少因客户端重试引起的消息重复的概率



## 消息发送过程

```txt
拦截器 -> 序列化器 -> 分区器
```

### 拦截器

- 实现 `org.apache.kafka.clients.producer. ProducerInterceptor` 接口

```java
// 消息被发送前调用，谨慎操作修改 topic，key等信息
public ProducerRecord<K, V> onSend(ProducerRecord<K, V> record);
// 在 ack 之前或者发送失败之后，callback 之前运行，运行在 Producer 的IO线程，因此逻辑比较简单比较好
public void onAcknowledgement(RecordMetadata metadata, Exception exception);
// 
public void close();
```

- 指定拦截器: `ProducerConfig.INTERCEPTOR_CLASSES_CONFIG`
- 可以指定多个拦截器，按顺序执行

### 序列化器

- 实现 Serializer 接口, 之后指定 key.serializer 和 value.serializer 参数

### 分区器

- 假如 ProducerRecord 中并未指定 partition 字段，那么就需要依赖分区器，根据 key 这个字段来决定消息发往哪个partition
- 实现 org.apache.kafka.clients.producer.Partitioner 接口，可以自定义分区器

```java
public interface Partitioner extends Configurable, Closeable {
    /**
     * Compute the partition for the given record.
     *
     * @param topic The topic name
     * @param key The key to partition on (or null if no key)
     * @param keyBytes The serialized key to partition on( or null if no key)
     * @param value The value to partition on or null
     * @param valueBytes The serialized value to partition on or null
     * @param cluster The current cluster metadata
     */
    public int partition(String topic, Object key, byte[] keyBytes, Object value, byte[] valueBytes, Cluster cluster);

    /**
     * This is called when partitioner is closed.
     */
    public void close();
}
```

- 指定自定义的分区器 `ProducerConfig.PARTITIONER_CLASS_CONFIG`

