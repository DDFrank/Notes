# 基础概念

## 生产者

- 就是投递消息的一方
- 生产者创建消息，然后发布到MQ中
  - 消息分为 label 和 payload
  - label 一般用来描述描述该消息，比如一个交换器的名称和路由键
  - payload 描述业务数据

## 消费者

- 就是接收消息的一方
- 消费者连接到 RabbitMQ 服务器，并订阅到队列上
- 消费者消费一条消息时，只是消费消息的payload。在消息路由的过程中，消息的label会被丢弃

## Broker

- 消息中间件的服务节点



## 队列(Queue)

- RabbitMQ的内部对象，用于存储消息
- RabbitMQ中消息都只能存储在队列中
- 多个消费者可以订阅同一个队列，此时队列中的消息会被平均分摊(轮询)
- RabiitMQ 不支持队列层面的广播消费，如果需要的话必须进行二次开发。不建议这么做



## 交换器(Exchange)

- 生产者将消息发送到 Exchange, 由交换器将消息路由到一个或者多个队列中。
- 如果路由不到，可能丢弃，也可能返回给生产者



## 路由键(RoutingKey)

- 生产者将消息发送给交换器的时候，一般会指定一个 RoutingKey, 用来指定这个消息的路由规则
- Routing Key 需要与交换器类型和绑定键联合使用才能最终生效
- 在交换器类型和绑定键固定的情况下，生产者可以在发送消息给交换器时，通过指定 RoutingKey 来决定消息流向哪里



## 绑定(Binding)

- RabbitMQ 中通过绑定将交换器与队列关联起来，在绑定的时候一般会指定一个绑定键，这样就可以正确的路由了
- 生产者将消息发送给交换器时，需要一个 RoutingKey, 当 BindingKey 和 RoutingKey 相匹配时，消息会被路由到相应的队列时
- 在绑定多个队列到同一个交换器的时候，这些绑定允许使用相同的 BindingKey。
- BindingKey 是否生效依赖于交换器类型



## 交换器类型

### fanout

会把所有发送到该交换器的消息路由到所有与该交换器绑定的队列中

### direct

会把消息路由到那些 BindingKey 和 RoutingKey 完全匹配的队列中

### topic

依据以下规则将 消息路由到 RoutingKey和BindingKey 相匹配的队列中

- RoutingKey 为一个点号 "." 分割的字符串 : "com.frank.rabbitmq"
- BindingKey 和 RoutingKey 一样是点号分隔的字符串
- BindingKey 中可以存在两种特殊字符串 "*" 和 "#" 用于模糊匹配
  - "*" 用于匹配一个单词
  - "#" 用于匹配多个单词

### headers

不依赖于路由键的匹配规则来路由消息，而是根据发送的消息内容中的 headers 属性进行匹配

性能很差，基本不会用



## Connection 和 Channel

- 生产者和消费者均需要与 RabbbitMQ 建立一条TCP连接，也就是 Connection
- Connection 建立后，客户端接着可以创建AMQP信道，也就是 Channel ，每个信道都会被指派一个唯一的ID
- Channel 是建立在 Connection 之上的虚拟连接， RabbitMQ 处理的每条 AMQP 指令都是通过信道完成的

# 基本API学习

## 连接

- Connection 可以用来创建多个 Channel 实例，但是 Channel 实例不能再线程间共享,应当为每一个线程开辟一个 Channel
- Channel 或者 Connection 的 isOpen 方法并不可靠，可以通过捕获 ShutdownSignalException ,IOException, SocketEception 异常来确认是否关闭了

## 使用交换器和队列

- 在使用前需要先声明(declare)

### 声明交换器

- Channel#exchangeDeclare(String exchange, String type, boolean durable, boolean autoDelete, boolean internal, Map<String, Object> arguments) throws IOException

  - exchange: 交换器名称

  - type : 交换器类型

  - durable: 设置是否持久化, 持久化也就是将交换器存盘，服务器重启时不会丢失相关信息

  - autoDelete: 是否自动删除。自动删除的前提是至少有一个队列或者交换器与这个交换器绑定，之后所有与该交换器绑定的队列或交换器都与此解绑

  - Internal: 是否内置。如果是内置的，则无法直接接受客户端消息，只能通过交换器路由到交换器这种形式

  - argument: 其它一些结构化参数

     

### 查看交换器是否存在

- exchangeDeclarePassive(String name) : 用于检测相应的交换器是否存在，如果不存在就抛出异常 :404 channel exception ,同时 channel 也会被关闭

### 删除交换器

- exchangeDelete(String exchange, boolean ifUnused)
  - ifUnused : true 话只有在交换器没有被使用的情况下才会被删除

### 声明队列

- queueDelcare: 创建一个由 RabbitMQ 命名的(匿名队列),排他的，自动删除的，非持久化的队列
- queueDeclare(String queue, boolean durable, boolean exclusive, boolean autoDelete, Map<String, Object> arguments)
  - queue: 队列名称
  - durable: 是否持久化
  - exclusive: 是否排他。如果一个队列是排他的，意味着该队列仅对首次声明它的Connection 可见，并在连接断开时自动删除。这种队列适用于一个客户端同时发送和读取消息的应用场景
  - autoDelete: 是否自动删除。自动删除的前提是: 至少有一个消费者连接到这个队列，之后所有与这个队列连接的消费者都断开时，才会自动删除
  - arguments: 设置队列的其它参数
- 生产者和消费者都能够使用 queueDeclare 来声明一个队列，但是如果消费者在同一个信道上订阅了另一个队列，就无法再声明队列了，必须先取消订阅，然后将信道置为 传输 模式，才能声明队列

### 检测队列是否存在

- queueDeclarePassive(String queue)
  - 不存在的话抛出异常 404 channel exception

### 删除队列的方法

- queueDelete(String queue, boolean ifUnused, boolean ifEmpty)
  - queue: 表示队列的名称
  - ifUnused: 如果在使用则不删除
  - ifEmpty: true的话表示仅在队列为空的情况下才能删除

### 清空队列的内容

- queuePurge(String queue)

### 将队列和交换器绑定的方法

- queueBind(String queue, String exchange, String routingKey, Map<String, Object> arguments)
  - queue: 队列名称
  - exchange: 交换器名称
  - routingKey: 用来绑定队列和交换器的路由键
  - argument: 定义绑定的一些参数

### 将队列和交换器解绑

- queueUnbind(String queue, String exchange, String routingKey, Map<String, Object> arguments)

### 将交换器绑定到交换器

- exchangeBind(String destination, String source, String routingKey, Map<String, Object> arguments)
  - 绑定后，消息从 source 交换器转发到 destination 交换器

### 发送消息

- basicPublish (String exchange, String routingKey, boolean mandatory, boolean immediate, BasicProperties props, byte[] body)
  - exchange : 交换器的名称, 若为空，则发送到 RabbitMQ 默认的交换器中
  - routingKey: 路由键
  - props: 消息的基本属性集
    - contentType
    - contentEncoding
    - headers(Map<String, Object>)
    - deliveryMode 投递模式
    - priority 优先级
    - correlationId
    - replyTo
    - expiration 过期时间
    - messageId
    - timestamp
    - type
    - userId
    - appId
    - clusterId
  - byte[] : 消息体
  - mandatory
  - immediate

### 消费消息

#### 推模式

采用 Basic.Consume 进行消费

- 一般通过实现 Consumer 接口或者继承 DefaultConsumer 类来实现
- 当调用 Consumer 的API时，不同的订阅采用不同的消费者标签(consumerTag) 来区分彼此
- 在同一个 Channel 中的消费者也需要通过唯一的消费者标签以作区分

-  basicConsume(String queue, boolean autoAck, String consumerTag, boolean nolocal, boolean exclusive, Map<String, Object> arguments, Consumer callback)
  - queue: 队列的名称
  - autoAck: 设置是否自动确认，建议设置为false，不要自动确认, 之后调用 basicAck 来确认消息已经被接收
  - consumerTag: 消费者标签
  - noLocal: 为true 则表示不能将同一个Connection 中生产者发送的消息传送给这个 Connection 中的消费者
  - exclusive:  是否排他
  - arguments: 设置消费者的其它参数
  - callback: 设置回调函数

##### 回调函数, 实现 Consumer 后

- handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body)

- handleConsumeOk(String consumerTag)
  - 会在其它方法之前调用，返回消费者标签
- handleCancelOk(String consumerTag)
- handleCancel(String consumerTag)
- handleShutdownSignal(String consumerTag, ShutdownSignalEception sig)
  - 当 Channel 或 Connection 关闭时调用
- handleRecoverOk(String consumerTag)

##### 线程安全问题

- 消费者客户端的 callback 会被分配到 Channel 不同的线程池中，所以消费者客户端可以安全的调用这些阻塞方法
- 每个 Channel 都拥有自己独立的线程。最常用的做法是一个 Channel 对应一个消费者
- 假如 一个Channel对应多个消费者，那么会彼此阻塞



#### 拉模式

- GetResponse basicGet(String queue, boolean autoAck)



### 消费端的确认与拒绝

#### 拒绝消息

- basicReject(long deliveryTag, boolean requeue)
  - deliveryTag: 消息的编号，64 的长整型
  - requeue:  设为true 的话，RabbitMQ会重新将这条消息存入队列，以便可以发送给下一位订阅的消费者
  - 一次只能拒绝一条消息
- basicNack(long deliveryTag, boolean multiple, boolean requeue)
  - Multiple: true 则表示拒绝 deliveryTag 编号之前所有未被当前消费者确认的消息
- basicRecovery(boolean requeue)
  - 该方法用来请求 RabbitMQ 重新发送还未被确认的消息
  - requeue: 为false 的话 同一条消息会被分配给与之前相同的消费者

#### 关闭连接

可以通过 addShutdownListener 添加监听器，在回调中获取关闭的原因



# 进阶用法

## 消息

### mandatory 参数

- 设为 true 的时候，交换器无法根据自身的类型和路由键找到一个符合条件的队列，那么 RabbitMQ 会调用 Basic.Return 将消息返回给生产者
- 生产者可以通过调用 addReturnListener 来添加监听器(ReturnListener)

### 备份交换器

- 如果不想使用 mandatory 参数,又不想消息丢失，可以使用备份交换器。
- 将未被路由的消息存储在 RabbitMQ 中，需要的时候再去处理这些消息
- 可以在声明交换器时，通过 alternamte-exchange 参数来实现

```java
Map<String, Object> args = new HashMap<>();
    args.put("alternate-exchange", "myAe");
    channel.exchangeDeclare("normalExchange", "direct", true, false, args);
    channel.exchangeDeclare("myAe", "fanout", true, false, false, null);
    channel.queueDeclare("normalQueue", true, false, false, null);
    channel.queueBind("normalQueue", "normalExchange", "normalKey");
    channel.queueDeclare("unroutedQueue", true, false, false, null);
    channel.queueBind("unroutedQueue", "myAe", "");
```



## 过期时间(TTL)

可以对消息和队列设置 TTL

#### 设置消息的TTL

- 假如设置队列的TTL的话，那么整个队列的所有消息都有相同的TTL
- 也可以给消息单独设置，假如两个都设置，会采用较小的那个值
- 消息在队列中的生存时间一旦超过设置的TTL值时，会变成 死信
- 通过队列设置是在 channel,queueDeclare 方法中加入 x-message-ttl 参数实现的，这个参数的单位是毫秒
- 如果不设置，表示消息不会过期
- 假如设置为0，表示如果消费者不能马上接收消息的话就抛弃消息
- 针对每条消息设置TTL 的方法是 channel.basicPublish 方法中加入 expiration 的属性参数,单位为毫秒

#### 设置队列的 TTL 

- 通过 channel.queueDeclare 方法钟表的x-expires 参数可以控制队列被自动删除前处于未使用状态的时间
- 未使用的意思是队列上没有任何消费者，队列也没有被重新声明，并且在过期时间段内也未吊用过 Basic.GET 命令
- RabbitMQ 重启后，持久化的队列的过期时间会被重新计算
- 不能设置为0



## 死信队列(DLX)

当一个消息在一个队列中变成死信之后，它能被重新被发送到另一个交换器，也就是DLX

绑定DLX的队列就是死信队列

### 消息变成死信的原因

- 消息被拒绝，而且设置 requeue 参数为 false
- 消息过期
- 队列达到最大长度

### 应用

- 通过 channel.queueDeclare 方法中的设置 x-dead-letter-exchange 参数来为这个队列添加 DLX

- 也可以为DLX指定路由键，如果没有特殊指定，则使用原队列的路由键 也就是参数中添加 x-dead-letter-routing-key

  

## 延迟队列

#### 利用 DLX 和 TTL 模拟出延迟队列的功能

- 设置消息的延迟时间，消息过时了就进入死信队列
- 消费者订阅死信队列
- 这样就实现延迟队列

#### 使用插件 

- 插件会提供一个 x-delayed-message 类型的exchange
- 发送消息时会通过在header提供 x-delay 参数来控制延时时间

## 优先级队列

- 具有高优先级的队列具有高的优先权，优先级高的消息具备优先被消费的特权

- 可以通过设置队列的 x-max-priority 参数来实现
- 这个只对消息积压的情况有用



## RPC

主要流程如下

- 客户端启动时，创建一个匿名的回调队列
- 客户端为 RPC 请求设置两个属性: 
  - replyTo 用来告知RPC 服务端回复请求时的目的队列，即回调队列
  - correlationId 用来标记一个请求
- 请求被送到 rpc_queue 队列
- 服务端监听 rpc_queue 队列中的请求。当请求到来时，服务端会处理并且把带有结果的消息发送给客户端。接收的队列就是 replyTo 设定的回调队列
- 客户端监听回调队列，当有消息时，检查 correlationId 属性，如果与请求匹配，那就是结果了

TODO 代码待补完

```java

```



## 持久化

- 交换器的持久化是在声明时将参数 durable 设置为 true 实现的

- 队列的持久化也是将 durable 设置为 true 实现的

- 要确保消息不会丢失，需要将 其设置持久化，也就是消息的投递模式设置为 2

   

## 生产者确认





