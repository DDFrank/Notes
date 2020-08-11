# LoopResources 接口，负责管理 EventLoopGroup 的线程资源
```java
/**
 * An {@link EventLoopGroup} selector with associated
 * {@link io.netty.channel.Channel} factories.
 *
 * @author Stephane Maldini
 * @since 0.6
 */
@FunctionalInterface
public interface LoopResources extends Disposable {
    /**
     * 用于获取 netty 使用的 EventLoopGroup
	 * Callback for server {@link EventLoopGroup} creation.
	 *
	 * @param useNative should use native group if current {@link #preferNative()} is also
	 * true
	 *
	 * @return a new {@link EventLoopGroup}
	 */
	EventLoopGroup onServer(boolean useNative);
}
```

- `EventLoop` 线程都实现了 `NonBlocking` 的标记接口

## NonBlocking 接口
```java
/**
 * A marker interface that is detected on {@link Thread Threads} while executing Reactor
 * blocking APIs, resulting in these calls throwing an exception.
 * <p>
 * See {@link Schedulers#isInNonBlockingThread()}} and
 * {@link Schedulers#isNonBlockingThread(Thread)}
 *
 * @author Simon Baslé
 */
public interface NonBlocking { }
```

- 用于标记线程为非阻塞线程
- 当该线程执行 `reactor core` 的阻塞操作时，就会抛出异常
- `EventLoop implements NonBlocking`

## getOrDefault 创建或获取 LoopResources 资源
```java
    protected static <T extends TcpResources> T getOrCreate(AtomicReference<T> ref,
			@Nullable LoopResources loops,
			@Nullable ConnectionProvider provider,
			BiFunction<LoopResources, ConnectionProvider, T> onNew,
			String name) {
		T update;
		for (; ; ) {
			T resources = ref.get();
			if (resources == null || loops != null || provider != null) {
                // 首次进来会创建一个 DefaultLoopResources 和 PooledConnectionProvider 的 HttpResources
				update = create(resources, loops, provider, name, onNew);
                // TODO 这里不晓得是干嘛的
				if (ref.compareAndSet(resources, update)) {
					if(resources != null){
						if(loops != null){
							resources.defaultLoops.dispose();
						}
						if(provider != null){
							resources.defaultProvider.dispose();
						}
					}
					return update;
				}
				else {
					update._dispose();
				}
			}
			else {
				return resources;
			}
		}
	}
```

## 如何获取 EventLoop
- 创建 DefaultLoopResources 的时候就新建了
```java
DefaultLoopResources(String prefix,
			int selectCount,
			int workerCount,
			boolean daemon) {
		this.running = new AtomicBoolean(true);
		this.daemon = daemon;
		this.workerCount = workerCount;
		this.prefix = prefix;
        // 直接新建
		this.serverLoops = new NioEventLoopGroup(workerCount,
				threadFactory(this, "nio"));

		this.clientLoops = LoopResources.colocate(serverLoops);

		this.cacheNativeClientLoops = new AtomicReference<>();
		this.cacheNativeServerLoops = new AtomicReference<>();

		if (selectCount == -1) {
			this.selectCount = workerCount;
			this.serverSelectLoops = this.serverLoops;
			this.cacheNativeSelectLoops = this.cacheNativeServerLoops;
		}
		else {
			this.selectCount = selectCount;
			this.serverSelectLoops =
					new NioEventLoopGroup(selectCount, threadFactory(this, "select-nio"));
			this.cacheNativeSelectLoops = new AtomicReference<>();
		}
	}
```
```java
    // 委托给 DefaultLoopResources 进行获取
    public EventLoopGroup onServer(boolean useNative) {
		if (useNative && preferNative()) {
            // 使用 native 的时候，会使用 native的创建方法
			return cacheNativeServerLoops();
		}
		return serverLoops;
	}
    
    EventLoopGroup cacheNativeServerLoops() {
		EventLoopGroup eventLoopGroup = cacheNativeServerLoops.get();
		if (null == eventLoopGroup) {
			DefaultLoop defaultLoop = DefaultLoopNativeDetector.getInstance();
			EventLoopGroup newEventLoopGroup = defaultLoop.newEventLoopGroup(
					workerCount,
					threadFactory(this, "server-" + defaultLoop.getName()));
			if (!cacheNativeServerLoops.compareAndSet(null, newEventLoopGroup)) {
				newEventLoopGroup.shutdownGracefully();
			}
			eventLoopGroup = cacheNativeServerLoops();
		}
		return eventLoopGroup;
	}
```