# 主题和分区

- 主题是一个逻辑上的概念，一个主题有许多分区，每个分区只属于一个主题
- 同一个主题下的不同分区包含的消息是不一样的。
- 分区在存储层面可以看做是一个日志文件，每一个消息到达分区时，都会被分配一个offset
- offset 是消息在分区中的唯一标识，kafka用 offset 保证消息在每个分区内都是有顺序的。不过不能跨分区
- 通过增加分区的数量可以实现横向拓展
- 从 Kafka 的底层实现来说，主题和分区都是逻辑上的概念，分区可以有一至多个副本，每个副本对应一个日志文件，每个日志文件对应一至多个日志分段（LogSegment），每个日志分段还可以细分为索引文件、日志存储文件和快照文件等

## 主题的管理

### 发送消息和消费消息时自动创建topic

- 当 broker 端的参数 `auto.create.topics.enable` 设置为 true （默认值）时
- 向一个尚未创建的主题 发送消息时会自动创建一个 分区数为 `num.partitions=1` ，副本因子为`default.replication.factor=1` 的topic
- 当一个消费者开始从未知主题开始消费的时候，也会按照上述规则创建一个默认主题

### 使用脚本来创建主题(推荐)

``` shell
bin/kafka-topics.sh --zookeeper localhost:2181/kafka --create --topic topic-create --partitions 4 --replication-factor 2
```



# 分区副本的分配

- 分区分配是指为集群制定创建主题时的分区副本分配方案，即在哪个 broker 中创建哪些分区的副本
- 如果使用了 replica-assignment 参数，那么就按照指定的方案来进行分区副本的创建
- 如果没有使用 replica-assignment 参数，那么就需要按照内部的逻辑来计算分配方案了
- 使用 kafka-topics.sh 脚本创建主题时的内部分配逻辑按照机架信息划分成两种策略：未指定机架信息和指定机架信息
  - 如果集群中所有的 broker 节点都没有配置 broker.rack 参数，或者使用 disable-rack-aware 参数来创建主题，那么采用的就是未指定机架信息的分配策略
  - 否则采用的就是指定机架信息的分配策略

## 未指定机架信息的分配策略

- kafka.admin.AdminUtils.scala#assignReplicasToBrokersRackUnaware()

```scala
private def assignReplicasToBrokersRackUnaware(
    nPartitions: Int,         //分区数
    replicationFactor: Int,  //副本因子
    brokerList: Seq[Int],    //集群中broker列表
    fixedStartIndex: Int,    //起始索引，即第一个副本分配的位置，默认值为-1
    startPartitionId: Int):  //起始分区编号，默认值为-1
Map[Int, Seq[Int]] = { 
  val ret = mutable.Map[Int, Seq[Int]]() //保存分配结果的集合
  val brokerArray = brokerList.toArray    //brokerId的列表
//如果起始索引fixedStartIndex小于0，则根据broker列表长度随机生成一个，以此来保证是
//有效的brokerId
  val startIndex = if (fixedStartIndex >= 0) fixedStartIndex
    else rand.nextInt(brokerArray.length)
  //确保起始分区号不小于0
  var currentPartitionId = math.max(0, startPartitionId)
  //指定了副本的间隔，目的是为了更均匀地将副本分配到不同的broker上
  var nextReplicaShift = if (fixedStartIndex >= 0) fixedStartIndex
    else rand.nextInt(brokerArray.length)
  //轮询所有分区，将每个分区的副本分配到不同的broker上
  for (_ <- 0 until nPartitions) {
    if (currentPartitionId > 0 && (currentPartitionId % brokerArray.length == 0))
      nextReplicaShift += 1
    val firstReplicaIndex = (currentPartitionId + startIndex) % brokerArray.length
    val replicaBuffer = mutable.ArrayBuffer(brokerArray(firstReplicaIndex))
    //保存该分区所有副本分配的broker集合
    for (j <- 0 until replicationFactor - 1)
      replicaBuffer += brokerArray(
        replicaIndex(firstReplicaIndex, nextReplicaShift, 
          j, brokerArray.length)) //为其余的副本分配broker
    //保存该分区所有副本的分配信息
    ret.put(currentPartitionId, replicaBuffer)
    //继续为下一个分区分配副本
    currentPartitionId += 1
  }
  ret
}

private def replicaIndex(firstReplicaIndex: Int, secondReplicaShift: Int, 
                         replicaIndex: Int, nBrokers: Int): Int = {
  val shift = 1 + (secondReplicaShift + replicaIndex) % (nBrokers - 1)
  (firstReplicaIndex + shift) % nBrokers
}
```

- 核心是遍历每个分区 partition，然后从 brokerArray（brokerId的列表）中选取 replicationFactor 个 brokerId 分配给这个 partition， 也就是尽量均匀的分配

## 指定机架信息时的分配策略

TODO(复杂)

# 副本机制

- 同一分区中的不同副本保存的是相同的消息。副本之间是 leader 和 follower 的关系

## leader

- 负责消息的读写

## follower

- 负责同步 leader 的消息，当 leader出现故障时，从 follower 中选举出新的leader

## 消息同步机制

- 所有的副本统称为 AR (Assigned Replicas)
- 所有与 leader 保持同步的副本称为ISR (In-Sync Replicas)
- 与 leader副本消息同步滞后过多的副本称为 OSR (Out-of-Sync Replicas)
- 消息会先发送到 leader 副本，之后 follower 副本从 leader 副本中拉取消息, 同步期间 follower 相对于 leader 副本有一定程度的滞后
- leader 副本负责维护和跟踪 ISR 中所有follower副本的滞后状态
  - 当 follower副本落后太多时，leader会将其从 ISR 转移到 OSR 中
  - 当 OSR 中的 follower 跟上 leader的进度时，leader会将其从OSR中移动ISR中
- 当 leader挂掉的时候，只会从ISR中选举出新的leader

## HW 和 LEO

- HW(High Watermark) ，高水位，它标识了一个offset的位置，消费者只能拉取到这个offset之前的消息
- LEO(LogStartOffset), 代表下一条即将写入的消息的offset。所以其大小相当于该分区日志的最后一条消息的 offset + 1
- 分区ISR集合中的中每个副本都会维护自己的LEO，而 ISR 集合中最小的 LEO 即为分区的 HW，对消费者而言只能消费 HW 之前的消息。



# 优先副本的选举



# 分区重分配

- 节点突然宕机下线时，Kakfa 不会自动将 失效节点上的副本自动迁移到集群中剩余的可用 broker 节点上
- 当要对集群中的一个节点进行有计划的下线操作时，为了保证分区及副本的合理分配，也希望通过某种方式能够将该节点上的分区副本迁移到其他的可用节点上
- 当集群中新增 broker 节点时，只有新创建的主题分区才有可能被分配到这个节点上，而之前的主题分区并不会自动分配到新加入的节点中，因为在它们被创建时还没有这个新节点，这样新节点的负载和原先节点的负载之间严重不均衡
- 可以使用 分区重分配来解决上述问题

## 步骤

- 创建一个包含主题清单列表的 JSON 文件
- 根据主题清单列表和 broker 节点清单生成一份重分配方案
- 根据上述步骤生成的方案执行重分配

## 示例

- 假设现在在一个3个节点(broker0, 1, 2)组成的集群中创建一个主题 topic-reassign, 主题中包含4个分区和2个副本

```shell
[root@node1 kafka_2.11-2.0.0]# bin/kafka-topics.sh --zookeeper localhost:2181/ kafka --create --topic topic-reassign --replication-factor 2 --partitions 4
Created topic "topic-reassign".

[root@node1 kafka_2.11-2.0.0]# bin/kafka-topics.sh --zookeeper localhost:2181/ kafka --describe --topic topic-reassign
# 主题 分区 和 副本 所在 的broker 情况
Topic:topic-reassign	PartitionCount:4	ReplicationFactor:2	Configs: 
    Topic: topic-reassign	Partition: 0	Leader: 0	Replicas: 0,2	Isr: 0,2
    Topic: topic-reassign	Partition: 1	Leader: 1	Replicas: 1,0	Isr: 1,0
    Topic: topic-reassign	Partition: 2	Leader: 2	Replicas: 2,1	Isr: 2,1
    Topic: topic-reassign	Partition: 3	Leader: 0	Replicas: 0,1	Isr: 0,1
```

- 假如想要下线 broker 1 ，那么首先，先创建一个 包含主题清单的 JSON 文件

```json
{
        "topics":[
                {
                        "topic":"topic-reassign"
                }
        ],
        "version":1
}
```

- 根据 主题清单列表的JSON文件来生成 分配方案, 在 --broker-list 中指定 修改后的 broker 列表

```shell
[root@node1 kafka_2.11-2.0.0]# bin/kafka-reassign-partitions.sh --zookeeper localhost:2181/kafka --generate --topics-to-move-json-file reassign.json --broker-list 0,2
# 当前的情况，可以
Current partition replica assignment
{"version":1,"partitions":[{"topic":"topic-reassign","partition":2,"replicas":[2,1],"log_dirs":["any","any"]},{"topic":"topic-reassign","partition":1,"replicas":[1,0],"log_dirs":["any","any"]},{"topic":"topic-reassign","partition":3,"replicas":[0,1],"log_dirs":["any","any"]},{"topic":"topic-reassign","partition":0,"replicas":[0,2],"log_dirs":["any","any"]}]}

Proposed partition reassignment configuration
{"version":1,"partitions":[{"topic":"topic-reassign","partition":2,"replicas":[2,0],"log_dirs":["any","any"]},{"topic":"topic-reassign","partition":1,"replicas":[0,2],"log_dirs":["any","any"]},{"topic":"topic-reassign","partition":3,"replicas":[0,2],"log_dirs":["any","any"]},{"topic":"topic-reassign","partition":0,"replicas":[2,0],"log_dirs":["any","any"]}]}
```

- 执行分配方案， 这个 project.json 就是重分配的方案

```shell
[root@node1 kafka_2.11-2.0.0]# bin/kafka-reassign-partitions.sh --zookeeper localhost:2181/kafka --execute --reassignment-json-file project.json 
Current partition replica assignment

{"version":1,"partitions":[{"topic":"topic-reassign","partition":2,"replicas":[2,1],"log_dirs":["any","any"]},{"topic":"topic-reassign","partition":1,"replicas":[1,0],"log_dirs":["any","any"]},{"topic":"topic-reassign","partition":3,"replicas":[0,1],"log_dirs":["any","any"]},{"topic":"topic-reassign","partition":0,"replicas":[0,2],"log_dirs":["any","any"]}]}

Save this to use as the --reassignment-json-file option during rollback
Successfully started reassignment of partitions.
```

- 也可以自定义重分配方案, 然后直接执行分配方案
- 重分配的基本过程是增加新的副本，然后从老的leader副本上复制副本数据，完成后再删掉老的副本
- 对整个集群的性能影响是比较大的