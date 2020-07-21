# 实现该接口的方法可以在IOC容器的各个生命周期执行自定义的逻辑

```java
public interface SpringApplicationRunListener {

	/**
	 * Called immediately when the run method has first started. Can be used for very
	 * early initialization.
	 */
	void starting();

	/**
	 * Called once the environment has been prepared, but before the
	 * {@link ApplicationContext} has been created.
	 */
	void environmentPrepared(ConfigurableEnvironment environment);

	/**
	 * Called once the {@link ApplicationContext} has been created and prepared, but
	 * before sources have been loaded.
	 */
	void contextPrepared(ConfigurableApplicationContext context);

	/**
	 * Called once the application context has been loaded but before it has been
	 * refreshed.
	 */
	void contextLoaded(ConfigurableApplicationContext context);

	/**
	 * The context has been refreshed and the application has started but
	 * {@link CommandLineRunner CommandLineRunners} and {@link ApplicationRunner
	 * ApplicationRunners} have not been called.
	 */
	void started(ConfigurableApplicationContext context);

	/**
	 * Called immediately before the run method finishes, when the application context has
	 * been refreshed and all {@link CommandLineRunner CommandLineRunners} and
	 * {@link ApplicationRunner ApplicationRunners} have been called.
	 */
	void running(ConfigurableApplicationContext context);

	/**
	 * Called when a failure occurs when running the application.
	 * @param context the application context or {@code null} if a failure occurred before
	 * the context was created
	 */
	void failed(ConfigurableApplicationContext context, Throwable exception);
}
```

## 注册
- 该类的实现类会通过 `getSpringFactoriesInstances` 方法从 `spring.factories` 中注册，因此需要在`spring.factories`中进行注册
- 实现类的构造器必须接收 `SpringApplication application`, `String[] args` 这2个参数


## 使用
- 实际上现在 spring-boot 中也只有一个`EventPublishingRunListener`，用于在IOC容器的各个生命周期中发布事件
  - `EventPublishingRunListener` 在构造的时候会通过 `SpringApplication` 获取事前注册的listener，于是就可以发布事件了