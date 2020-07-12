## 线程池的例子
```java

public class HandlerExecutePool {
    private ExecutorService executor = null;

    public HandlerExecutorPool(int maxSize, int queueSize) {
        this.executor = new ThreadPoolExecutor(Runtime.getRuntime().avaliableProcessors().maxSize, 120L, TimeUnit.SECONDS, new ArrayBlockingQuene<Runnable>(queuqSize));
    }

    public void execute(Runnable task){
        executor.execute(task);
    }
}

```

# NIO
## 一些基本的概念
- JDK1.4加入的NIO，为同步非阻塞，即应用程序可以获取已经准备就绪的数据，无需等待
- JDK1.7升级了NIO，支持异步异步非阻塞模型，即NIO2(AIO)
- 同步和异步主要是面向操作系统和应用程序的。
    + 同步
    应用程序会直接参与IO读写操作，并且应用程序会直接阻塞到某一个方法上，直到数据准备完毕(BIO)
    或者采用轮询的方式实时的检查数据的就绪状态，如果就绪就获取数据(NIO)
    + 异步
    所有的IO操作交给操作系统处理，与应用程序无直接关系，应用程序不关系IO读写，当操作系统完成IO读写操作时，会向应用程序发出通知来接收数据。

- Buffer(缓冲区)
包含一组需要写入或读取的数据，所有的操作均使用缓冲区实现
最常用的是 ByteBuffer,当前其它基本类型的也有
- Channel(管道)
网络数据通过 Channel 读写，输入流和输出流是单向的，而Channel是双向的，可用于读，写或同时进行
最重要的是管道可以和多路复用器集合起来，有多种的状态位，方便多路复用器去识别。通常分为两大类
    + SelectableChannel,用于网络读写
    + FileChannel 用于文件操作

- Selector(选择器，多路复用器)
NIO机制的核心，提供选择已经就绪任务的能力（实现轮询机制）。
选择器不断的去轮询注册在其上的Channel，如果某个通道发生了读写操作，这个通道就出于就绪状态。
就会被Selector轮询出来，然后SelectionKey可以取得就绪的Channel集合，从而进行后续的IO操作
只要有一个线程负责Selector的轮询，就可以接入大量的客户端。
Selecotr线程类似一个管理者，管理了成千上万的管道。

- Selecotor模式
当IO事件(管道)注册到选择器以后，Selector会分配给每一个管道一个key。
Selecot选择器轮询查找注册的所有的IO事件(管道)
IO事件(管道)准备就绪之后，Selecotr就会识别，通过key来找到相应的管道，进行相应的数据处理操作（从管道中读写数据到缓冲区中）
每个管道都会对选择器进行注册不同的事件状态以方便查找

- 事件状态
    + SelectionKey.OP_CONNECT
    + SelectionKey.OP_ACCEPT
    + SelectionKey.OP_READ
    + SelectionKey.OP_WRITE

# TCP 粘包/拆包
TCP是一个流协议，也就是没有界限的一串数据，也就是TCP底层并不理解上传业务数据的具体含义。
TCP底层会根据TCP缓冲区的实际情况进行包的划分，所以在业务上认为，一个完整的包可能会被TCP拆分成多个包进行发送，也有可能把多个小的包封装成一个大的数据包发送

## 问题
假设客户端分别发送了两个数据包D1,D2给服务端，由于服务端一次读取到的字节数不确定，所以可能存在问题
- 服务端分两次读取到了两个独立的数据包，分别为D1,D2，那就没问题
- 服务端一次接收到了两个数据包，D1和D2粘合在一起，被称为TCP粘包;
- 服务端分两次读取到了两个数据包，第一次读取到了完整的D1包和D2包的部分内容，第二次读取到了D2包的剩余内容，这被称为TCP拆包;
- 服务端两次读取到了两个数据包，第一次读取到了D1包的部分内容，第二次读取到了D1包的剩余内容和D2包的部分内容，然后。。。 这期间发生多次拆包

## 解决策略
由于底层的TCP无法理解上层的业务数据，所以在底层是无法保证数据包不被拆分和重组的，只能通过上层的应用协议栈设计来解决
- 消息定长，比如每个报文的大小固定为200字节，如果不够，空位补空格;
- 在包尾增加回车换行符进行分割，比如FTP协议
- 将消息分为消息头和消息体，消息头中包含表示消息总长度（或者消息体长度）的字段，通常设计思路为消息头的第一个字段使用int32来表示消息的总长度
- 更复杂的应用层协议

## Netty的解决策略
### LineBasedFrameDecoder 和 StringDecoder 的原理解析
- LineBasedFrameDecoder
依次遍历 ByteBuf 中的可读字节，判断看是否有"\n" 或者 "\r\n"，如果有，就以此位置为结束位置
从可读索引到结束位置区间的字节就组成了一行。它是以换行符为结束标志的解码器，支持携带结束符或者不携带结束符两种解码方式，同时支持配置单行的最大长度

- StringDecoder
将接收到的对象转为字符串，然后继续调用后面的Handler。

这两个组合就是按行切换的文本解码器，被设计来解决TCP的粘包和拆包

## 分隔符和定长解码器的应用
### 上层协议对TCP消息区分的四种方式
- 消息长度固定，累计读取到长度总和为定长LEN的报文后，就认为读取到了一个完整的消息:将计数器置位，重新开始读取下一个数据报
- 将回车换行符作为消息结束符，比如FTP，这种方式比较多
- 将特殊的分隔符作为消息的结束标志
- 通过在消息头中定义长度字段来标识消息的总长度。

Netty对上面这四种应用提供了统一的抽象，提供了4中解码器来解决对应的问题

### DelimterBasedFrameDecoder
自动完成以分隔符作为码流结束标识的消息的解码

- 服务端

```java
package niotest.netty.decoder;

import io.netty.bootstrap.ServerBootstrap;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioServerSocketChannel;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;
import io.netty.handler.logging.LogLevel;
import io.netty.handler.logging.LoggingHandler;

/**
 * @author 016039
 * @Package niotest.netty.decoder
 * @Description: DelimiterBasedFrameDecoder的服务端开发
 * @date 2018/5/6下午2:13
 */
public class EchoServer {
    public void bind(int port) throws Exception {
        // 配置服务端的NIO线层组
        EventLoopGroup bossGroup = new NioEventLoopGroup();
        EventLoopGroup workerGroup = new NioEventLoopGroup();

        try{
            ServerBootstrap bootstrap = new ServerBootstrap();
            bootstrap.group(bossGroup, workerGroup)
                    .channel(NioServerSocketChannel.class)
                    .option(ChannelOption.SO_BACKLOG, 100)
                    .handler(new LoggingHandler(LogLevel.INFO))
                    .childHandler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel socketChannel) throws Exception {
                            // 使用 "$_" 作为分隔符
                            ByteBuf delimiter = Unpooled.copiedBuffer("$_".getBytes());
                            /*
                            * 1 消息的最大长度,到达改长度还没找到消息的话会抛出异常
                            * 2 分隔符
                            * */
                            socketChannel.pipeline().addLast(new DelimiterBasedFrameDecoder(1024, delimiter));
                            socketChannel.pipeline().addLast(new StringDecoder());
                            socketChannel.pipeline().addLast(new EchoServerHandler());
                        }
                    });
            // 绑定端口，同步等待成功
            ChannelFuture future = bootstrap.bind(port).sync();
            // 等待服务器监听端口关闭
            future.channel().closeFuture().sync();
        }finally {
            // 退出释放线程资源
            bossGroup.shutdownGracefully();
            workerGroup.shutdownGracefully();
        }
    }

    public static void main(String[] args) throws Exception {
        int port = 8080;
        if(args != null && args.length > 0) {
            try{
                port = Integer.valueOf(args[0]);
            }catch (NumberFormatException e) {
                e.printStackTrace();
            }
        }
        new EchoServer().bind(port);
    }
}

```

```java
package niotest.netty.decoder;

import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;

/**
 * @author 016039
 * @Package niotest.netty.decoder
 * @Description: ${todo}
 * @date 2018/5/6下午3:36
 */
public class EchoServerHandler extends ChannelInboundHandlerAdapter {
    private int counter;

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
        // 由于DelimiterBasedFrameDecoder 自动对请求消息进行了解码，msg应该是一个完整的消息包
        String body = (String) msg;
        // 每收到一次消息，就记一次数，然后发送应答消息给客户端
        System.out.println("This is " + ++counter + " time receive client:[" + body + "]");
        body += "$_";

        ByteBuf echo = Unpooled.copiedBuffer(body.getBytes());
        ctx.writeAndFlush(echo);
    }

    @Override
    public void channelReadComplete(ChannelHandlerContext ctx) throws Exception {
        // 将消息发送队列中的消息写入到SocketChannel中发送给对方
        // 平常出于性能考虑Netty的write方法只是把待发送的消息放到发送缓冲数组中，所以需要flush
        ctx.flush();
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        ctx.close();
    }
}

```

- 客户端
```java
package niotest.netty.decoder;

import io.netty.bootstrap.Bootstrap;
import io.netty.buffer.ByteBuf;
import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelFuture;
import io.netty.channel.ChannelInitializer;
import io.netty.channel.ChannelOption;
import io.netty.channel.EventLoopGroup;
import io.netty.channel.nio.NioEventLoopGroup;
import io.netty.channel.socket.SocketChannel;
import io.netty.channel.socket.nio.NioSocketChannel;
import io.netty.handler.codec.DelimiterBasedFrameDecoder;
import io.netty.handler.codec.string.StringDecoder;

/**
 * @author 016039
 * @Package niotest.netty.decoder
 * @Description: ${todo}
 * @date 2018/5/6下午3:46
 */
public class EchoClient {
    public void connect(int port, String host) throws Exception {
        // 配置客户端NIO线层组
        EventLoopGroup group = new NioEventLoopGroup();

        try {
            Bootstrap bootstrap = new Bootstrap();
            bootstrap
                    .group(group)
                    .channel(NioSocketChannel.class)
                    .option(ChannelOption.TCP_NODELAY, true)
                    .handler(new ChannelInitializer<SocketChannel>() {
                        @Override
                        protected void initChannel(SocketChannel socketChannel) throws Exception {
                            ByteBuf delimiter = Unpooled.copiedBuffer("$_".getBytes());
                            socketChannel.pipeline().addLast(new DelimiterBasedFrameDecoder(1024, delimiter));
                            socketChannel.pipeline().addLast(new StringDecoder());
                            socketChannel.pipeline().addLast(new EchoClientHandler());
                        }
                    });

            // 发起异步连接操作
            ChannelFuture future = bootstrap.connect(host, port).sync();
            // 等待客户端链路关闭
            future.channel().closeFuture().sync();

        } finally {
            group.shutdownGracefully();
        }
    }

    public static void main(String[] args) throws Exception {
        int port = 8080;
        if(args != null && args.length > 0) {
            try{
                port = Integer.valueOf(args[0]);
            }catch (NumberFormatException e) {
                e.printStackTrace();
            }
        }
        new EchoClient().connect(port, "127.0.0.1");
    }
}
```

```java
package niotest.netty.decoder;

import io.netty.buffer.Unpooled;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;

/**
 * @author 016039
 * @Package niotest.netty.decoder
 * @Description: ${todo}
 * @date 2018/5/6下午3:50
 */
public class EchoClientHandler extends ChannelInboundHandlerAdapter {
    private int counter;

    public static final String ECHO_REQ = "Hi, Lilinfeng.Welcome toNetty.$_";

    public EchoClientHandler() {
    }

    // 客户端和服务端的TCP链路建立成功之后，Netty的NIO线程会调用channelActive方法，发送查询时间的指令给服务端
    @Override
    public void channelActive(ChannelHandlerContext ctx) throws Exception {
        // 循环发送一百次消息
        for(int i=0;i<10;i++) {
            ctx.writeAndFlush(Unpooled.copiedBuffer(ECHO_REQ.getBytes()));
        }
    }

    // 服务端返回应答消息的时候，该方法被调用
    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {

        System.out.println("This is " + ++counter + " times receive server: [" + msg + "]");
    }

    @Override
    public void channelReadComplete(ChannelHandlerContext ctx) throws Exception {
        ctx.flush();
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
        cause.printStackTrace();
        //释放资源
        ctx.close();
    }
}
```

### FixedLengthFrameDecoder应用开发
固定长度解码器

- 服务端
```java
    // 就是换一个解码器而已
    socketChannel.pipeline().addLast(new FixedLengthFrameDecoder(20));
```

# 编解码技术
## 基础概念
- Java的对象输入输出流 ObjectInputStream / ObjectOutputStream 可以直接把Java对象作为可存储的字节数组写入文件，也可以传输到网络上

- Java序列化的目的主要有两个
    + 网络传输
    + 对象持久化

- Java对象编解码技术
当进行远程跨进程服务调用时，需要把被传输的Java对象编码为字节数组或者ByteBuffer对象。
而当远程服务读取到ByteBuffer 对象或者字节数组时，需要将其解码为发送时的 Java 对象

- Java序列化的缺点
    + 无法跨语言，目前流行的Java RPC框架中都没有使用Java序列化作为编解码框架的
    + 序列化后额码流太大了
    + 序列化性能太低
- 业界主流的编解码框架
    + Google Protobuf 性能很好
    + Facebook Thrift 支持多种语言,适用于静态的数据交换（即要先确定好数据结构）,适用于大型数据交换及存储的通用工具
    + JBoss Marshalling 无须实现 Serializable 接口，即可实现序列化，通过缓存技术提升对象的序列化性能，不过这个多是在JBoss内部使用

## MessagePack 序列化开发

# Netty的核心组件
## Bootstrap 和 ServerBootstrap
Netty 通过设置bootstrap类的开始，提供了一个用于应用程序网络层配置的容器

### ServerBootstrap
有两个Channel集合
- 包含一个单例ServerChannel,代表持有一个绑定了本地端口的socket
- 包含所有创建的Channel，处理服务器所接收到的客户端进来的连接
## Channel
Channel提供了与socket丰富交互的操作集:bind,close,config,connect等
Netty提供了大量的使用供使用
## ChannelHandler
ChannelHandler 支持很多协议，并且提供用于数据处理的容器
比较常用的接口有 ChannelInboundHandler
ChannelInboundHandler 和 ChannelOutboundHandler
就好像拦截器的进出一样，顺序也是按被添加的顺序来的

Netty提供了许多适配器类，可以减少编写自定义ChannelHandlers的逻辑

### 编码器解码器
java对象与字节相互转化的方法

### SimpleChannelHandler
如果只是需要接收到解码后的消息并应用一些业务逻辑到这些数据，继承该类即可
最常用的方法时 channelRead(ChannelHandlerContext, T) T是将要处理的消息
只要注意不要使用阻塞方法即可

## ChannelPipeline
提供了一个容器给 ChannelHandler 链并提供了一个API用于管理沿着链入栈和出栈事件的流动
每个Channel都有自己的ChannelPipeline，当Channel创建时自动创建的
ChannelHandler通过实现ChannelInitializer并调用其方法 initChannel 安装自定义的 ChannelHandler集成到pipeline。
## EventLoop
用于处理Channel 的 I/O操作。
一个单一的EventLoop通常会处理过个Channel事件
一个EventLoopGroop 可以含有多于一个的EventLoop和提供了一种迭代用于检索清单中的下一个。
## ChannelFuture
所有的IO操作都是异步的，所以需要办法在以后确定其结果
Netty提供了接口ChannelFuture,它的addListener 方法注册了一个ChannelFutureListener,当操作完成时，可以被通知