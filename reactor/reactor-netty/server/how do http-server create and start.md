### 创建一个HttpServer 并开始监听端口
```java
HttpServer server = HttpServer.create();
server.bindNow();
```


## TcpServer
Tcp服务器从创建到启动主要分2个阶段
- 创建 `TcpServer`
- 开始监听端口

```java
        TcpServer.create()
                .doOnBind()
                .doOnBound()
                .doOnUnbound()
                .host()
                .port()
                .bindNow()
```

### 默认的 ServerBootstrap 的构造
#### 开始绑定前先构造一个基础的 ServerBootstrap
```java
    public final Mono<? extends DisposableServer> bind() {
		ServerBootstrap b;
		try{
            // 实际调用是在 TcpServerBootstrap.configure()
            // bootstrapMapper.apply(source.configure()), 所以是先 TcpServerBind.configure(), 之后应用给了 HttpServerBind.apply()
            // TcpServerBind.configure() 直接返回了 在 创建阶段创建的 ServerBootstrap的clone(), 此时是缺少 EventLoopGroup 和 SocketChannel 和 Handler
            //  HttpServerBind.apply() 填充了
			b = configure();
		}
		catch (Throwable t){
			Exceptions.throwIfFatal(t);
			return Mono.error(t);
		}
		return bind(b);
	}
```

#### 填充 ServerBootstrap 的过程
`HttpServerBind`
```java
    public ServerBootstrap apply(ServerBootstrap b) {
        // 取出 httpServerConf 属性并将其设置为null
        // 也就是 getAndClean
		HttpServerConfiguration conf = HttpServerConfiguration.getAndClean(b);

        // 设置SSl相关的属性
		SslProvider ssl = SslProvider.findSslSupport(b);
		if (ssl != null && ssl.getDefaultConfigurationType() == null) {
			switch (conf.protocols) {
				case HttpServerConfiguration.h11:
					ssl = SslProvider.updateDefaultConfiguration(ssl, SslProvider.DefaultConfigurationType.TCP);
					SslProvider.setBootstrap(b, ssl);
					break;
				case HttpServerConfiguration.h2:
					ssl = SslProvider.updateDefaultConfiguration(ssl, SslProvider.DefaultConfigurationType.H2);
					SslProvider.setBootstrap(b, ssl);
					break;
			}
		}

		if (b.config()
		     .group() == null) {
            // 获取 HttpResources，用于分配 EventLoopGroup 和 ConnectionProvider
			LoopResources loops = HttpResources.get();

			boolean useNative =
					LoopResources.DEFAULT_NATIVE || (ssl != null && !(ssl.getSslContext() instanceof JdkSslContext));

			EventLoopGroup selector = loops.onServerSelect(useNative);
			EventLoopGroup elg = loops.onServer(useNative);

            // 设置 boostrap 和 worker 的 nioEventLoop
			b.group(selector, elg)
              // 设置 channel 的类型，一般是 NioServerSocketChannel
			 .channel(loops.onServerChannel(elg));
		}

		//remove any OPS since we will initialize below
        // 移除 ops_factory 的属性
		BootstrapHandlers.channelOperationFactory(b);

        // 根据ssl的有无和不同的Http协议执行不同的初始化, 主要就是注册不同的handler
		// 详见注册handler
		if (ssl != null) {
			if ((conf.protocols & HttpServerConfiguration.h2c) == HttpServerConfiguration.h2c) {
				throw new IllegalArgumentException("Configured H2 Clear-Text protocol " +
						"with TLS. Use the non clear-text h2 protocol via " +
						"HttpServer#protocol or disable TLS" +
						" via HttpServer#tcpConfiguration(tcp -> tcp.noSSL())");
			}
			if ((conf.protocols & HttpServerConfiguration.h11orH2) == HttpServerConfiguration.h11orH2) {
				return BootstrapHandlers.updateConfiguration(b,
						NettyPipeline.HttpInitializer,
						new Http1OrH2Initializer(conf.decoder.maxInitialLineLength,
								conf.decoder.maxHeaderSize,
								conf.decoder.maxChunkSize,
								conf.decoder.validateHeaders,
								conf.decoder.initialBufferSize,
								conf.minCompressionSize,
								compressPredicate(conf.compressPredicate, conf.minCompressionSize),
								conf.forwarded,
								conf.cookieEncoder,
								conf.cookieDecoder));
			}
			if ((conf.protocols & HttpServerConfiguration.h11) == HttpServerConfiguration.h11) {
				return BootstrapHandlers.updateConfiguration(b,
						NettyPipeline.HttpInitializer,
						new Http1Initializer(conf.decoder.maxInitialLineLength,
								conf.decoder.maxHeaderSize,
								conf.decoder.maxChunkSize,
								conf.decoder.validateHeaders,
								conf.decoder.initialBufferSize,
								conf.minCompressionSize,
								compressPredicate(conf.compressPredicate, conf.minCompressionSize),
								conf.forwarded,
								conf.cookieEncoder,
								conf.cookieDecoder));
			}
			if ((conf.protocols & HttpServerConfiguration.h2) == HttpServerConfiguration.h2) {
				return BootstrapHandlers.updateConfiguration(b,
						NettyPipeline.HttpInitializer,
						new H2Initializer(
								conf.decoder.validateHeaders,
								conf.minCompressionSize,
								compressPredicate(conf.compressPredicate, conf.minCompressionSize),
								conf.forwarded,
								conf.cookieEncoder,
								conf.cookieDecoder));
			}
		}
		else {
			if ((conf.protocols & HttpServerConfiguration.h2) == HttpServerConfiguration.h2) {
				throw new IllegalArgumentException(
						"Configured H2 protocol without TLS. Use" +
								" a clear-text h2 protocol via HttpServer#protocol or configure TLS" +
								" via HttpServer#secure");
			}
			if ((conf.protocols & HttpServerConfiguration.h11orH2c) == HttpServerConfiguration.h11orH2c) {
				return BootstrapHandlers.updateConfiguration(b,
						NettyPipeline.HttpInitializer,
						new Http1OrH2CleartextInitializer(conf.decoder.maxInitialLineLength,
								conf.decoder.maxHeaderSize,
								conf.decoder.maxChunkSize,
								conf.decoder.validateHeaders,
								conf.decoder.initialBufferSize,
								conf.minCompressionSize,
								compressPredicate(conf.compressPredicate, conf.minCompressionSize),
								conf.forwarded,
								conf.cookieEncoder,
								conf.cookieDecoder));
			}
			if ((conf.protocols & HttpServerConfiguration.h11) == HttpServerConfiguration.h11) {
				return BootstrapHandlers.updateConfiguration(b,
						NettyPipeline.HttpInitializer,
						new Http1Initializer(conf.decoder.maxInitialLineLength,
								conf.decoder.maxHeaderSize,
								conf.decoder.maxChunkSize,
								conf.decoder.validateHeaders,
								conf.decoder.initialBufferSize,
								conf.minCompressionSize,
								compressPredicate(conf.compressPredicate, conf.minCompressionSize),
								conf.forwarded,
								conf.cookieEncoder,
								conf.cookieDecoder));
			}
			if ((conf.protocols & HttpServerConfiguration.h2c) == HttpServerConfiguration.h2c) {
				return BootstrapHandlers.updateConfiguration(b,
						NettyPipeline.HttpInitializer,
						new H2CleartextInitializer(
								conf.decoder.validateHeaders,
								conf.minCompressionSize,
								compressPredicate(conf.compressPredicate, conf.minCompressionSize),
								conf.forwarded,
								conf.cookieEncoder,
								conf.cookieDecoder));
			}
		}
		throw new IllegalArgumentException("An unknown HttpServer#protocol " +
				"configuration has been provided: "+String.format("0x%x", conf
				.protocols));
	}
```

### 注册handler BootstrapHandlers#updateConfiguration
```java
	// name 是
	public static ServerBootstrap updateConfiguration(ServerBootstrap b,
			String name,
			BiConsumer<ConnectionObserver, ? super Channel> c) {
		Objects.requireNonNull(b, "bootstrap");
		Objects.requireNonNull(name, "name");
		Objects.requireNonNull(c, "configuration");
		// 设置了一个 childHandler, 实际上只是保存了 handler 的注册信息，使用的handler是
		// c 会调用 Channel 的pipline() 注册各种处理器
		b.childHandler(updateConfiguration(b.config().childHandler(), name, c));
		return b;
	}
```


### 真正执行 服务器启动并监听端口的地方 
```java
    public Mono<? extends DisposableServer> bind(ServerBootstrap b) {
        // SSL 相关配置，之后补完
		SslProvider ssl = SslProvider.findSslSupport(b);
		if (ssl != null && ssl.getDefaultConfigurationType() == null) {
			ssl = SslProvider.updateDefaultConfiguration(ssl, SslProvider.DefaultConfigurationType.TCP);
			SslProvider.setBootstrap(b, ssl);
		}

        // 假如没有设置 EventLoopGroup，那么就配置一个
		if (b.config()
		     .group() == null) {

			TcpServerRunOn.configure(b, LoopResources.DEFAULT_NATIVE, TcpResources.get());
		}

		return Mono.create(sink -> {
            // 用本 ServerBootstrap 的配置新建一个 ServerBootstrap
			ServerBootstrap bootstrap = b.clone();

			// TODO 不清楚这些类的关系
			ConnectionObserver obs = BootstrapHandlers.connectionObserver(bootstrap);
			ConnectionObserver childObs =
					BootstrapHandlers.childConnectionObserver(bootstrap);
			ChannelOperations.OnSetup ops =
					BootstrapHandlers.channelOperationFactory(bootstrap);

			convertLazyLocalAddress(bootstrap);

			BootstrapHandlers.finalizeHandler(bootstrap, ops, new ChildObserver(childObs));

			// 开始绑定端口
			ChannelFuture f = bootstrap.bind();

			// 绑定一些处理器
			DisposableBind disposableServer = new DisposableBind(sink, f, obs, bootstrap);
			f.addListener(disposableServer);
			sink.onCancel(disposableServer);
		});
	}

```