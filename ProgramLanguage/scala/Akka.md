# 模块划分

- Actor Library: 核心库
- Remote: 帮助actor和远程的actor通信
- Cluster: 帮助构建分布式系统的基础
- Cluster Sharding: 帮助在集群中分享状态
- Cluster Singleton: 帮助在集群中建立单例，比如 主从模式中的主
- Persistence: 提供系统启动或关闭时持久化数据的方法
- Distributed Data: 如何在集群中传递数据
- Streams: 提供 Reactive Stream标准的实现
- HTTP



### 在设计Actor时，最重要是要设计 Message



### Message delivery

- akka 提供了一系列的工具来让用户自己确认消息是否已经送达，而不是在框架层面提供实现
- 因为一个业务的完成与否，只有这个业务所属的领域自己能确认这一点,所以，消息是否已经正确处理这一点需要让领域来确认



### Message Ordering

- 给定一对 actor， 第一个发送给第二个的 消息是保证顺序的
- 其它情况消息无法保证一定是有顺序的