# Netty的核心组件

### Channel

代表一个实体(比如一个硬件设备，一个文件，一个网络套接字或者一个能够执行一个或者多个不同的I/O操作的程序组)的开放连接，如读操作和写操作

目前，可以把 Channel 看做是传入(Inbound) 或者传出(OutBound) 数据的载体。因此，它可以被打开或关闭，连接或断开。

### 回调

- 一个回调就是一个方法，一个指向已经被提供给另外一个方法的引用。

- 后者可以在适当的时机调用前者
- Netty 内部使用了回调来处理事件

### Future

- 提供了一种在操作完成时通知应用程序的方式.这个对象可以看作是一个异步操作的结果的占位符
- JDK 提供的 Future 只允许手动检查是否已经完成，比较繁琐，所以Netty提供了自己的实现 ChannelFuture
- ChannelFuture 可以注册一个或者多个 ChannelFutureListener 实例。监听器的回调将在合适的时机被调用
- 每个 Netty 的出入栈 I/O 操作 都会返回一个 ChannelFuture，所以是不会阻塞的。

### 事件和ChannelHandler

- Netty使用不同的事件来通知我们状态的改变或者是操作的状态。这使得我们能够基于已经发生的事件来触发适当的动作
- 每个事件都被分发到 ChannelHandler 类中的某个用户实现的方法。
- Netty提供了大量开箱可用的 ChannelHandler 实现

# Netty的组件和设计

## Channel 接口

基本的I/O操作(bind connect read write) 依赖于底层网络传输所提供的原语

## EventLoop 接口

用于处理连接的生命周期中所发生的事件。

- 一个 EventLoopGroup 包含一个或者多个 EventLoop
- 一个EventLoop 在它的生命周期内只和一个 Thread 绑定
- 所有由 EventLoop 处理的 I/O 事件都将在它专有的 Thread 上处理
- 一个 Channel 在它的生命周期内只注册于一个 EventLoop
- 一个EventLoop 可能会被分配给一个或多个 Channel

## ChannelFuture 接口

用于在操作之后的某个时间点确定其结果

利用其 addListener 方法注册 ChannelFutureListener 以便在某个操作完成时得到通知

## ChannelHandler 接口

充当了所有处理Inbound 和 OutBound 数据的应用程序逻辑的容器

里面充满了各种业务逻辑

## ChannelPipeline 接口

ChannelPipeline 提供了 ChannelHandler 链的容器，并定义了用于在该链上传播 InBound 和 OutBound 事件流的API。

当Channel 创建时，会被自动分配到 它专属的 ChannelPipeline 中

### ChannelHandler 安装到 ChannelPipeline 的过程

- 一个 ChannelInitializer 的实现被注册到了 ServerBootstrap 中
- 当 ChannelInitializer.initPipeline() 方法被调用时， ChannelInitializer 将在 ChannelPipeline 中安装一组自定义的 ChannelHandler
- ChannelInitializer 将它自己从 ChannelPipeline 中移除



## Boostrap 接口

- Boostrap : 用于客户端，连接到远程主机和端口
- ServerBootstrap : 用于服务端 绑定到一个本地端口



# 传输

内置的传输

- NIO : 基于Java的 nio 的channels作为基础
- Epoll: 只在linux 上实现，比NIO更快
- OIO: 传统的阻塞式
- Local: 可以在 VM 内部通过管道进行通信的本地传输, 假如不需要网络开销，服务端和客户端都在本地的话可以用
- Embedded: 通常用于测试 ChannelHandler

# ByteBuf

优点

- 可以被用户自定义的缓冲区类型拓展
- 通过内置的复合缓冲区类型实现了透明的零拷贝
- 容量可以按需增长
- 在读和写这两种模式之间切换不需要调用 flip() 方法
- 读和写使用了不同的索引
- 支持方法的链式调
- 支持引用计数
- 支持池化

## ByteBuf 的几种使用模式

几种模式的区别看不懂

API有很多



# ChannelHandler 和 ChannelPipeline

## Channel 的生命周期

- ChannelUnregistered : Channel已经创建，但还未注册到 EventLoop
- ChannelRegistered: Channel 已经被注册到了 EventLoop
- ChannelActive: Channel 处于活动状态(已经连接到它的远程节点)。现在可以收发状态了
- ChannelInActive: Channel 没有连接到远程节点
-  ChannelRegistered -> ChannelActive -> ChannelInActive -> ChannelUnregistered

## ChannelHandler 的生命周期

- handlerAdded: 当把ChannelHandler 添加到ChannelPipline 中时调用
- handlerRemoved: 当把从 ChannelPipeline 中 移除ChannelHandler 时调用
- exceptionCaught: 当处理过程中在 ChannelPipeline 中有错误产生时调用
- ChannelInboundHandler : 处理Inbound 数据以及各种状态变化
- ChannelOutboundHandler: 处理Outbound 数据并且允许拦截所有的操作

## 