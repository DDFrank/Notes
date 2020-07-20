# 手动装配方式
## @Component 及其衍生注解
- 基本注解
- 只能用于项目中自己编写的类


## @Configuration 和 @Bean
- 提供一个命令式的方式来进行Bean的装配


## @EnableXXX 系列注解 和 @Import
- 通常用于每个模块的注解
- @EnableXXX 通常表明要启用哪个模块, 之后在其上标注 @Import 表示要实际引入哪个配置类来进行具体的配置工作

### @Import 可引入的类有四种类型
- 直接引入普通类
也就是直接将引入的类在注册到IOC工厂

- 引入配置类
直接去解析配置类中配置的Bean, 并将配置类和@Bean标记的方法都注册进IOC工厂

- `ImportSelector`的实现类
方法 `selectImports` 返回一个包含全限定类名的字符串数组，会注册该数组中的类到IOC工厂
不会注册 `ImportSelector` 的实现类本身

- `ImportBeanDefinitionRegistrar`的实现类

```java
public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry)
```
使用 `registry.registerBeanDefinition` 的手段来实现bean手动装配

```java
// 第一个参数可以很方便的获取注解的信息, 因此很适合和注解一起配合使用
// spring-boot 中将 注册启动类作就使用了这个 AutoConfigurationPackages
void registerBeanDefinitions(AnnotationMetadata importingClassMetadata, BeanDefinitionRegistry registry);
```

