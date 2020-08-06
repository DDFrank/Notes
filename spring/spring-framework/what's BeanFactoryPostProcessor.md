# Bean工厂后置处理器
- 可以用于调整 BeanFactory
- 在 ApplicationContext 一般初始化后被调用，
- 此时 ApplicationContext 中有所有的BeanDefinition
- 可以用来覆盖或添加属性，甚至可以初始化 bean


## 子接口 BeanDefinitionRegistryPostProcessor
- 可以用于调整 BeanDefinitionRegistry 
- 在 BeanFactory 后置处理器的调用前先被调用
- 可以用于添加更多的 BeanDefinition


# spring 使用的 例子
## ConfigurationClassPostProcessor
- 用于标注了 @Configuration 的类
- 会扫描所有的Bean方法，将其解析为 BeanDefinition 并注册到 容器中
详见 `how do spring parse @Configuration`

