# spring-boot 启动时的加载部分
```java
private void prepareContext(ConfigurableApplicationContext context, ConfigurableEnvironment environment,
			SpringApplicationRunListeners listeners, ApplicationArguments applicationArguments, Banner printedBanner) {
    // 设置运行时环境
		context.setEnvironment(environment);

    // IOC容器后置处理
		postProcessApplicationContext(context);

    // 执行 ApplicationContextInitializer
    // 就是循环一遍，挨个执行 initialize
		applyInitializers(context);

    // 回调监听器的 contextPrepared ,也就是 创建和准备ApplicationContext之后，但在加载之前 的阶段
		listeners.contextPrepared(context);

    // 某个日志处理
		if (this.logStartupInfo) {
			logStartupInfo(context.getParent() == null);
			logStartupProfileInfo(context);
		}
		// Add boot specific singleton beans
		ConfigurableListableBeanFactory beanFactory = context.getBeanFactory();
    // 将 程序参数注册为Bean
		beanFactory.registerSingleton("springApplicationArguments", applicationArguments);
		if (printedBanner != null) {
      // 假如有banner的话，那么也注册banner
			beanFactory.registerSingleton("springBootBanner", printedBanner);
		}
		if (beanFactory instanceof DefaultListableBeanFactory) {
			((DefaultListableBeanFactory) beanFactory)
      // TODO 不知道是啥
					.setAllowBeanDefinitionOverriding(this.allowBeanDefinitionOverriding);
		}
		// Load the sources
    // 加载主启动类, 就是 primarySource
		Set<Object> sources = getAllSources();
		Assert.notEmpty(sources, "Sources must not be empty");

    // 注册主启动类
    // 将 Bean 加载到Bean工厂中, 此时是 BeanDefinition, 也就是还没有实例化的Bean
		// 注意这里只注册了主启动类，没有将全部的 BeanDefinition 都注册进来
		load(context, sources.toArray(new Object[0]));
    // 回调监听器的 contextLoad 方法，ApplicationContext已加载但在刷新之前 的阶段
		listeners.contextLoaded(context);
	}
```

## IOC容器后置处理
也就是注册了一些东西
```java
protected void postProcessApplicationContext(ConfigurableApplicationContext context) {
    // 注册 BeanName 生成器
    // TODO 这是干啥的？
		if (this.beanNameGenerator != null) {
			context.getBeanFactory().registerSingleton(AnnotationConfigUtils.CONFIGURATION_BEAN_NAME_GENERATOR,
					this.beanNameGenerator);
		}

    // 注册资源和class加载器
		if (this.resourceLoader != null) {
			if (context instanceof GenericApplicationContext) {
				((GenericApplicationContext) context).setResourceLoader(this.resourceLoader);
			}
			if (context instanceof DefaultResourceLoader) {
				((DefaultResourceLoader) context).setClassLoader(this.resourceLoader.getClassLoader());
			}
		}
    
    // 注册类型转换器，是在各个容器间共享的
		if (this.addConversionService) {
			context.getBeanFactory().setConversionService(ApplicationConversionService.getSharedInstance());
		}
	}
```

## 将 Bean 加载到Bean工厂中
```java
protected void load(ApplicationContext context, Object[] sources) {
    if (logger.isDebugEnabled()) {
        logger.debug("Loading source " + StringUtils.arrayToCommaDelimitedString(sources));
    }
    // 获取BeanDefinition加载器
    // 从 ApplicationContext 中获取 BeanDefinitionRegistry，然后直接构造 BeanDefinitionLoader
    // BeanDefinitionLoader 的构造器里封装了 AnnotatedBeanDefinitionReader, XmlBeanDefinitionReader, ClassPathBeanDefinitionScanner, GroovyBeanDefinitionReader 等读取器
    BeanDefinitionLoader loader = createBeanDefinitionLoader(getBeanDefinitionRegistry(context), sources);
    // 设置BeanName生成器
    if (this.beanNameGenerator != null) {
        loader.setBeanNameGenerator(this.beanNameGenerator);
    }
    // 设置资源加载器
    if (this.resourceLoader != null) {
        loader.setResourceLoader(this.resourceLoader);
    }
    // 设置运行环境
    if (this.environment != null) {
        loader.setEnvironment(this.environment);
    }
    loader.load();
}
```

### 根据 主启动类 的类型，调用不同的加载器进行加载
```java
// load 三连
public int load() {
    int count = 0;
    for (Object source : this.sources) {
        count += load(source);
    }
    return count;
}

private int load(Object source) {
    Assert.notNull(source, "Source must not be null");
    // 根据传入source的类型，决定如何解析
    // spring-boot 里走的是这个，因为是启动类
    if (source instanceof Class<?>) {
        return load((Class<?>) source);
    }
    if (source instanceof Resource) {
        return load((Resource) source);
    }
    if (source instanceof Package) {
        return load((Package) source);
    }
    if (source instanceof CharSequence) {
        return load((CharSequence) source);
    }
    throw new IllegalArgumentException("Invalid source type " + source.getClass());
}

private int load(Class<?> source) {
		if (isGroovyPresent() && GroovyBeanDefinitionSource.class.isAssignableFrom(source)) {
			// Any GroovyLoaders added in beans{} DSL can contribute beans here
			GroovyBeanDefinitionSource loader = BeanUtils.instantiateClass(source, GroovyBeanDefinitionSource.class);
			load(loader);
		}
    // 最终是通过 注解读取器进行主启动类的注册
    // 主启动类本质上是 @Configuration, 所以肯定是这个
		if (isComponent(source)) {
			this.annotatedReader.register(source);
			return 1;
		}
		return 0;
	}
```

### 注册主启动类
```java
// 启动时只有一个参数 beanClass, 也就是主启动类
<T> void doRegisterBean(Class<T> beanClass, @Nullable Supplier<T> instanceSupplier, @Nullable String name,
			@Nullable Class<? extends Annotation>[] qualifiers, BeanDefinitionCustomizer... definitionCustomizers) {

    // 将Bean封装为 AnnotatedGenericBeanDefinition ,这个表示类的元数据信息都在注解上
		AnnotatedGenericBeanDefinition abd = new AnnotatedGenericBeanDefinition(beanClass);
    // 这里判断该类是否应该跳过，各种 Condition 就在这里发挥作用
		if (this.conditionEvaluator.shouldSkip(abd.getMetadata())) {
			return;
		}

    // 这个应该是看是否有能够直接提供实例化办法的 supplier
		abd.setInstanceSupplier(instanceSupplier);
    // 解析 @Scope注解, 注册 scope 信息, 默认是 单例
		ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(abd);
		abd.setScope(scopeMetadata.getScopeName());

    // 假如没有名称，那么使用名称生成器去, 生成bean的名称
		String beanName = (name != null ? name : this.beanNameGenerator.generateBeanName(abd, this.registry));

    // 检查Bean上面是否有以下注解，有的话，注册到元数据中
    // Lazy Primary DependsOn Role Description
		AnnotationConfigUtils.processCommonDefinitionAnnotations(abd);
    // 检查是否传递了 某些修饰符
		if (qualifiers != null) {
			for (Class<? extends Annotation> qualifier : qualifiers) {
				if (Primary.class == qualifier) {
					abd.setPrimary(true);
				}
				else if (Lazy.class == qualifier) {
					abd.setLazyInit(true);
				}
				else {
					abd.addQualifier(new AutowireCandidateQualifier(qualifier));
				}
			}
		}

    // 假如有自定义的配置，那么逐个调用
		for (BeanDefinitionCustomizer customizer : definitionCustomizers) {
			customizer.customize(abd);
		}

    // 包装为 BeanDefinitionHolder
		BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(abd, beanName);
    // TODO 不知道是什么代理
		definitionHolder = AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
    // 利用 BeanDefinitionHolder 注册 BeanDefinition
    // BeanDefinitionRegistry#registerBeanDefinition() 来注册的
		BeanDefinitionReaderUtils.registerBeanDefinition(definitionHolder, this.registry);
	}
```