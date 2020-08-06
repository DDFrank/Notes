# Bean的后置处理器
它可以在对象实例化但初始化之前，以及初始化之后进行一些后置处理

```java
public interface BeanPostProcessor {
  // 通常用于检测Bean是不是实现了某个特定的接口，也就是 marker interface，假如是，就相应的执行一些操作
  // 比如 spring-boot 在刷新容器前会注册 ApplicationContextAwareProcessor 和 ApplicationListenerDetector
  @Nullable
	default Object postProcessBeforeInitialization(Object bean, String beanName) throws BeansException {
		return bean;
	}

  // 通常用于在bean创建后使用代理包装它
  // AOP主要通过这个来实现
  @Nullable
	default Object postProcessAfterInitialization(Object bean, String beanName) throws BeansException {
		return bean;
	}
}
```

## bean的初始化顺序
- 构造方法
- BeanPostProcessor#postProcessBeforeInitialization()
- @PostConstruct / InitMethod
- `InitializingBean` 的afterPropertiesSet()
- BeanPostProcessor#postProcessAfterInitialization()

## 何时注册到 Bean 工厂
在刷新容器时 `registerBeanPostProcessors` 这个方法会注册进去


## 特殊的子接口
### MergedBeanDefinitionPostProcessor
- 用于在运行时对bean进行merger操作，其实应该就是额外给 bean 实例添加一些属性
- 最重要的实现类是 AutowiredAnnotationBeanPostProcessor, 也就是 setter 注入的时候会填充 bean

## Spring中的重要实现
### AutowiredAnnotationBeanPostProcessor
```java
public AutowiredAnnotationBeanPostProcessor() {
    // 检查 Autowird
		this.autowiredAnnotationTypes.add(Autowired.class);
    // 检查 Value
		this.autowiredAnnotationTypes.add(Value.class);
		try {
      // 检查Inject
			this.autowiredAnnotationTypes.add((Class<? extends Annotation>)
					ClassUtils.forName("javax.inject.Inject", AutowiredAnnotationBeanPostProcessor.class.getClassLoader()));
			logger.trace("JSR-330 'javax.inject.Inject' annotation found and supported for autowiring");
		}
		catch (ClassNotFoundException ex) {
			// JSR-330 API not available - simply skip.
		}
	}
```

```java
  public void postProcessMergedBeanDefinition(RootBeanDefinition beanDefinition, Class<?> beanType, String beanName) {
    // 构建 autowire的元数据
		InjectionMetadata metadata = findAutowiringMetadata(beanName, beanType, null);
		metadata.checkConfigMembers(beanDefinition);
	}

  private InjectionMetadata findAutowiringMetadata(String beanName, Class<?> clazz, @Nullable PropertyValues pvs) {
    // Fall back to class name as cache key, for backwards compatibility with custom callers.
    String cacheKey = (StringUtils.hasLength(beanName) ? beanName : clazz.getName());
    // Quick check on the concurrent map first, with minimal locking.
    // 首先从缓存中取，如果没有才创建
    InjectionMetadata metadata = this.injectionMetadataCache.get(cacheKey);
    // 双重null监测机制
    if (InjectionMetadata.needsRefresh(metadata, clazz)) {
        synchronized (this.injectionMetadataCache) {
            metadata = this.injectionMetadataCache.get(cacheKey);
            if (InjectionMetadata.needsRefresh(metadata, clazz)) {
                if (metadata != null) {
                    metadata.clear(pvs);
                }
                // 开始构建自动装配的信息
                metadata = buildAutowiringMetadata(clazz);
                // 放入缓存
                this.injectionMetadataCache.put(cacheKey, metadata);
            }
        }
    }
    return metadata;
}

private InjectionMetadata buildAutowiringMetadata(final Class<?> clazz) {
    List<InjectionMetadata.InjectedElement> elements = new ArrayList<>();
    Class<?> targetClass = clazz;
    
    // 循环获取父类信息
    do {
        final List<InjectionMetadata.InjectedElement> currElements = new ArrayList<>();

        // 循环获取类上的属性，并判断是否有@Autowired等注入类注解
        // 也就是检查 field 注入
        ReflectionUtils.doWithLocalFields(targetClass, field -> {
            AnnotationAttributes ann = findAutowiredAnnotation(field);
            if (ann != null) {
                if (Modifier.isStatic(field.getModifiers())) {
                    if (logger.isInfoEnabled()) {
                        logger.info("Autowired annotation is not supported on static fields: " + field);
                    }
                    return;
                }
                boolean required = determineRequiredStatus(ann);
                currElements.add(new AutowiredFieldElement(field, required));
            }
        });

        // 循环获取类上的方法，并判断是否有需要依赖的项
        // 也就是检查 setter 注入
        ReflectionUtils.doWithLocalMethods(targetClass, method -> {
            Method bridgedMethod = BridgeMethodResolver.findBridgedMethod(method);
            if (!BridgeMethodResolver.isVisibilityBridgeMethodPair(method, bridgedMethod)) {
                return;
            }
            AnnotationAttributes ann = findAutowiredAnnotation(bridgedMethod);
            if (ann != null && method.equals(ClassUtils.getMostSpecificMethod(method, clazz))) {
                if (Modifier.isStatic(method.getModifiers())) {
                    if (logger.isInfoEnabled()) {
                        logger.info("Autowired annotation is not supported on static methods: " + method);
                    }
                    return;
                }
                if (method.getParameterCount() == 0) {
                    if (logger.isInfoEnabled()) {
                        logger.info("Autowired annotation should only be used on methods with parameters: " +
                                method);
                    }
                }
                boolean required = determineRequiredStatus(ann);
                PropertyDescriptor pd = BeanUtils.findPropertyForMethod(bridgedMethod, clazz);
                currElements.add(new AutowiredMethodElement(method, required, pd));
            }
        });

        elements.addAll(0, currElements);
        targetClass = targetClass.getSuperclass();
    }
    // 一直往上爬到父类是 Object 为止
    while (targetClass != null && targetClass != Object.class);

    return new InjectionMetadata(clazz, elements);
}
```


### ApplicationListenerDetector

```java
public void postProcessMergedBeanDefinition(RootBeanDefinition beanDefinition, Class<?> beanType, String beanName) {
    // 只保存 Bean 是否为单实例的机制
    this.singletonNames.put(beanName, beanDefinition.isSingleton());
}
```