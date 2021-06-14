* 自动装配的一般过程
spring-boot 利用 `@EnableAutoConfiguration` 来开启自动装配
```java
// 保存根包的路径
@AutoConfigurationPackage
// 真正开启自动配置的注解
@Import(AutoConfigurationImportSelector.class)
public @interface EnableAutoConfiguration {
  ....
}
```

## AutoConfigurationPackage 的作用
```java
// 被标注的类应该被注册到 AutoConfigurationPackages 中去
// 这个 Registrar 会保存被标注的类作为根路径，供之后进行包扫描来注册Bean
@Import(AutoConfigurationPackages.Registrar.class)
public @interface AutoConfigurationPackage {

}
```

```java
// 是 ImportBeanDefinitionRegistrar 的实现类
static class Registrar implements ImportBeanDefinitionRegistrar ... {
  public void registerBeanDefinitions(AnnotationMetadata metadata, BeanDefinitionRegistry registry) {
      // 将被标注的类注册到工厂中
      // 具体怎么注册需要查看其实现
			register(registry, new PackageImport(metadata).getPackageName());
		}
  ....
}

// 
public static void register(BeanDefinitionRegistry registry, String... packageNames) {
    // 查看 AutoConfigurationPackages 是否已经被注册
		if (registry.containsBeanDefinition(BEAN)) {
			BeanDefinition beanDefinition = registry.getBeanDefinition(BEAN);
      // 这里的步骤和 else 分支里的作用是一样的，将这个包名 加入 构造器的参数中
			ConstructorArgumentValues constructorArguments = beanDefinition.getConstructorArgumentValues();
			constructorArguments.addIndexedArgumentValue(0, addBasePackages(constructorArguments, packageNames));
		}
    // spring-boot 在刚开始启动时，Bean工厂里并没有这个类，因此会进入这个分支，注册该Bean
		else {
			GenericBeanDefinition beanDefinition = new GenericBeanDefinition();
			beanDefinition.setBeanClass(BasePackages.class);
			beanDefinition.getConstructorArgumentValues().addIndexedArgumentValue(0, packageNames);
			beanDefinition.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
			registry.registerBeanDefinition(BEAN, beanDefinition);
		}
	}
```

`AutoConfigurationPackage` 在保存好的根包的路径后，除了内部使用，也可以供有需要的其它第三方库使用
```java
// 在 ImportBeanDefinitionRegistrar 的实现类中
public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry) {
        if (!AutoConfigurationPackages.has(this.beanFactory)) {
          // 获取所有的跟路径
        List<String> packages = AutoConfigurationPackages.get(this.beanFactory);
        //...
    }
```

## AutoConfigurationImportSelector 的作用

```java
// DeferredImportSelector 表示本 ImportSelector 会在所有 @Configuration 处理完毕后再进行处理，非常适合用可选的配置
public class AutoConfigurationImportSelector implements DeferredImportSelector, BeanClassLoaderAware,
		ResourceLoaderAware, BeanFactoryAware, EnvironmentAware, Ordered {
      @Override
      public String[] selectImports(AnnotationMetadata annotationMetadata) {
        // 判定 spring.boot.enableautoconfiguration 是不是true，默认是 true
        if (!isEnabled(annotationMetadata)) {
          return NO_IMPORTS;
        }
        AutoConfigurationMetadata autoConfigurationMetadata = AutoConfigurationMetadataLoader
            .loadMetadata(this.beanClassLoader);
        // 获取全部的自动配置类的全限定类名， 这个最终是通过 SpringFactoriesLoader.loadFactoryNames 来实现的
        AutoConfigurationEntry autoConfigurationEntry = getAutoConfigurationEntry(autoConfigurationMetadata,
            annotationMetadata);
        return StringUtils.toStringArray(autoConfigurationEntry.getConfigurations());
      }
    }
```
### Spring如何通过自定义的SPI机制来加载自动配置类

```java
// 最终的执行过程
private static Map<String, List<String>> loadSpringFactories(@Nullable ClassLoader classLoader) {
    // 查看缓存，有就直接返回，说明这个过程只会加载一遍
		MultiValueMap<String, String> result = cache.get(classLoader);
		if (result != null) {
			return result;
		}

		try {
			Enumeration<URL> urls = (classLoader != null ?
          // 加载 META-INF/spring.factories 文件
					classLoader.getResources(FACTORIES_RESOURCE_LOCATION) :
					ClassLoader.getSystemResources(FACTORIES_RESOURCE_LOCATION));
			result = new LinkedMultiValueMap<>();
      // 遍历这个所有的枚举
			while (urls.hasMoreElements()) {
				URL url = urls.nextElement();
				UrlResource resource = new UrlResource(url);
        // 将KV形式的内容转换为Property
        // spring.factories 文件的内容都是 key = v1, v2,v3 等这种形式
				Properties properties = PropertiesLoaderUtils.loadProperties(resource);
				for (Map.Entry<?, ?> entry : properties.entrySet()) {
					String factoryClassName = ((String) entry.getKey()).trim();
					for (String factoryName : StringUtils.commaDelimitedListToStringArray((String) entry.getValue())) {
						result.add(factoryClassName, factoryName.trim());
					}
				}
			}
			cache.put(classLoader, result);
      // 返回自动配置类，之后这些类就会通过 @ImportSelector 的机制进行装配
			return result;
		}
		catch (IOException ex) {
			throw new IllegalArgumentException("Unable to load factories from location [" +
					FACTORIES_RESOURCE_LOCATION + "]", ex);
		}
	}
```

简单来说，spring-boot的自动装配就是提前在 模块中的 `META-INF/spring.factories` 文件汇总以KV形式写好要自动加载的配置类的吗名称
之后通过 `@EnableAutoConfiguration` 注解来进行装配
