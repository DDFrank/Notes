# 主要是使用 AnnotationBeanNameGenerator 类的策略来生成
- 准备解析 @ComponentScan 的扫描时，会 新建 ClassPathBeanDefinitionScanner，这个类的构造器里会新建 AnnotationBeanNameGenerator
- 大体上就是 看注解上是否有 value属性，没有的话 将 类的全称的首字母取小写后当做名称