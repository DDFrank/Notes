# 用于在 容器刷新前对 ApplicationContext 做一些初始化配置
## spring 中的应用
- `spring.factories` 中已经定义了许多 `ApplicationContextInitializer`, 可以参考这些类的写法

```
# Application Context Initializers
org.springframework.context.ApplicationContextInitializer=\
org.springframework.boot.context.ConfigurationWarningsApplicationContextInitializer,\
org.springframework.boot.context.ContextIdApplicationContextInitializer,\
org.springframework.boot.context.config.DelegatingApplicationContextInitializer,\
org.springframework.boot.web.context.ServerPortInfoApplicationContextInitializer

# Initializers
org.springframework.context.ApplicationContextInitializer=\
org.springframework.boot.autoconfigure.SharedMetadataReaderFactoryContextInitializer,\
org.springframework.boot.autoconfigure.logging.ConditionEvaluationReportLoggingListener
```
## 如何自定义使用
- 定义一个 `ApplicationContextInitializer` 的实现类，然后在定制的`SpringApplication`的时候加入

```java
SpringApplication springApplication = new SpringApplication(DemoApplication.class);
springApplication.addInitializers(new ApplicationContextInitializerDemo());
springApplication.run(args);
```

- 在 `application.properties` 中进行配置
```txt
context.initializer.classes=com.example.demo.ApplicationContextInitializerDemo
```

- 在 `spring.factories` 中进行配置
```txt
org.springframework.context.ApplicationContextInitializer=com.example.demo.ApplicationContextInitializerDemo
```