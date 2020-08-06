# 准备IOC容器, 也就是构造 SpringApplication
```java
public SpringApplication(ResourceLoader resourceLoader, Class<?>... primarySources) {
    // resourceLoader为null
    this.resourceLoader = resourceLoader;
    Assert.notNull(primarySources, "PrimarySources must not be null");
    // 将传入的DemoApplication启动类放入primarySources中，这样应用就知道主启动类在哪里，叫什么了
    // SpringBoot一般称呼这种主启动类叫primarySource（主配置资源来源）
    this.primarySources = new LinkedHashSet<>(Arrays.asList(primarySources));
    // 3.1 判断当前应用环境, 也就是区分是 Reactive 还是 Servlet 还是None
    this.webApplicationType = WebApplicationType.deduceFromClasspath();
    // 3.2 设置初始化器, 这些初始化器会在容器刷新前被调用
    setInitializers((Collection) getSpringFactoriesInstances(ApplicationContextInitializer.class));
    // 3.3 设置监听器, 监听 容器发布的事件的类
    setListeners((Collection) getSpringFactoriesInstances(ApplicationListener.class));
    // 3.4 确定主配置类, 也就是 main 方法所在的类
    this.mainApplicationClass = deduceMainApplicationClass();
}
```

# 准备好IOC容器后，接下来就是 springApplication.run()
## 准备IOC运行时环境
### 创建时间性能监控器 : StopWatch
```java
// 就是监控一下启动花了多少时间
StopWatch stopWatch = new StopWatch();
stopWatch.start();
```

### 创建空的IOC容器，和一组异常报告器
```java
ConfigurableApplicationContext context = null;
// 这个 SpringBootExceptionReporter 似乎是可以对容器创建期间出现的异常进行过滤，然后报告给用户的类
// 具体写法可以参考 spring.factories 中的类
Collection<SpringBootExceptionReporter> exceptionReporters = new ArrayList<>();
```

### configureHeadlessProperty：设置awt相关
```java
// 似乎就是为了 设置应用在启动时，即使没有检测到显示器也允许其继续启动，不深究
configureHeadlessProperty();
```

### getRunListeners：获取SpringApplicationRunListeners
```java
// 这里 spring-boot 默认就注册了 EventPublishingRunListener ,同时获取上文中注册的 ApplicationListener, 用于给 EventPublishingRunListener发布事件来监听
SpringApplicationRunListeners listeners = getRunListeners(args);
// 这里已经开始调用 starting 生命周期的回调
listeners.starting();
```

### prepareEnvironment：准备运行时环境
此时并没有加载配置参数
```java
ApplicationArguments applicationArguments = new DefaultApplicationArguments(args);
ConfigurableEnvironment environment = prepareEnvironment(listeners, applicationArguments);

///////////////////
private ConfigurableEnvironment prepareEnvironment(SpringApplicationRunListeners listeners,
        ApplicationArguments applicationArguments) {
    // Create and configure the environment
    //创建运行时环境
    // 就是根据Web应用类型返回环境类型
    ConfigurableEnvironment environment = getOrCreateEnvironment();
    // 配置运行时环境
    // 主要就是在 environment 中添加一个 ConversionService, ConversionService 用来实现各种数据类型的转换
    configureEnvironment(environment, applicationArguments.getSourceArgs());
    // 【回调】SpringApplicationRunListener的environmentPrepared方法（Environment构建完成，但在创建ApplicationContext之前）
    // 执行回调Listener，发布事件
    listeners.environmentPrepared(environment);
    //TODO 环境与应用绑定, 非常复杂，不知道是干啥的
    // 大概是把配置内容绑定到指定的属性配置类上
    bindToSpringApplication(environment);
    if (!this.isCustomEnvironment) {
        environment = new EnvironmentConverter(getClassLoader()).convertEnvironmentIfNecessary(environment,
                deduceEnvironmentClass());
    }
    ConfigurationPropertySources.attach(environment);
    return environment;
}
```

### 设置系统参数，打印Beanner
```java
// 设置系统参数
// 设置 spring.beaninfo.ignore 参数，默认值 true， 是否打印banner
configureIgnoreBeanInfo(environment);
// 打印Beanner
// banner 的过程不是很重要，略过
Banner printedBanner = printBanner(environment);
```

### 创建IOC容器
```java
// 主要也是根据Web容器类型来决定新建什么类型的IOC容器
// Default => AnnotationConfigApplicationContext
// Servlet => AnnotationConfigServletWebServerApplicationContext
// Reactive => AnnotationConfigReactiveWebServerApplicationContext
// 这里m默认的Bean工厂是 DefaultListableBeanFactory
context = createApplicationContext();
```

### 初始化异常报告器
```java
exceptionReporters = getSpringFactoriesInstances(SpringBootExceptionReporter.class,
                new Class[] { ConfigurableApplicationContext.class }, context);
```

### 初始化IOC容器
```java
// IOC容器，运行时环境, SpringApplicationRunListeners, 程序参数, 打印的Banner
// 详见专门章节, 主要是注册 BeanDefinition的
prepareContext(context, environment, listeners, applicationArguments, printedBanner);
```

### 刷新容器-BeanFactory的预处理
```java
refreshContext(context);


private void refreshContext(ConfigurableApplicationContext context) {
		refresh(context);
    // 注册JVM关闭时调用的钩子
		if (this.registerShutdownHook) {
			try {
        // 比如在JVM关闭时关闭数据库连接
				context.registerShutdownHook();
			}
			catch (AccessControlException ex) {
				// Not allowed in some environments.
			}
		}
	}

  // 
  protected void refresh(ApplicationContext applicationContext) {
		Assert.isInstanceOf(AbstractApplicationContext.class, applicationContext);
    // 详情请见专门章节 ，how do spring refresh IOC container
		((AbstractApplicationContext) applicationContext).refresh();
	}
```

