# IOC相关
## 加载不同的资源
```
// xml配置的入口,获取上下文
//ApplicationContext applicationContext = new ClassPathXmlApplicationContext("application.xml");
// 注解配置的入口
ApplicationContext applicationContext  = new AnnotationConfigApplicationContext(MainConfig.class);
// 获取Bean
Person bean = applicationContext.getBean(Person.class);
```

## bean的注册
### @Scope
- @Scope("prototype")
多实例的
- 默认是单实例的

request和session的一般不会用到

### 懒加载
@Lazy:
容器启动的时候不创建对象。第一次使用(获取)Bean的时候创建对象，并初始化

### 按照条件来注册Bean @Conditional
- 建一个条件类，实现 @Condition接口，重写matches方法
```
package conditional;

import org.springframework.beans.factory.config.ConfigurableListableBeanFactory;
import org.springframework.beans.factory.support.BeanDefinitionRegistry;
import org.springframework.context.annotation.Condition;
import org.springframework.context.annotation.ConditionContext;
import org.springframework.core.env.Environment;
import org.springframework.core.type.AnnotatedTypeMetadata;


/**
 * @author 016039
 * @Package conditional
 * @Description: 判断是否为Linux系统
 * @date 2018/8/4上午11:50
 */
public class LinuxCondition implements Condition{
    /*
     *  ConditionContext： 判断条件能使用的上下文(环境)
     *  AnnotatedTypeMetadata : 注释信息
     * */
    @Override
    public boolean matches(ConditionContext conditionContext, AnnotatedTypeMetadata annotatedTypeMetadata) {
        // TODO是否是linux系统
        // 1 能获取到ioc使用的beanfactory
        ConfigurableListableBeanFactory beanFactory = conditionContext.getBeanFactory();
        // 2 获取到类加载器
        ClassLoader classLoader = conditionContext.getClassLoader();
        // 3 获取到环境信息
        Environment environment = conditionContext.getEnvironment();
        // 4 获取到bean定义的注册类
        /*
            BeanDefinitionRegistry 可以用来判断容器中是否包含某个bean
        */
        BeanDefinitionRegistry beanDefinitionRegistry = conditionContext.getRegistry();

        // 获取操作系统的名字
        String osName = environment.getProperty("os.name");
        if(osName.contains("windows")){
            return true;
        }

        return false;
    }
}

```

- 在bean上加注解
```
@Bean
    @Scope("prototype")
    // 是linux环境的时候才注册该bean
    @Conditional(LinuxCondition.class)
    public Person person(){
        return new Person(1, "测试名字");
    }
```

该注解可以用在整个配置类上

### 注册组件
#### 直接写在配置类中
#### @Import
```
@Configuration
@Import(Person.class)
public class MainConfig {
}
```

#### ImportSelector 返回需要导入的组件的全类名数组
用于快速导入一组bean
- 建一个类实现ImportSelector
```

public class MyImportSelector implements ImportSelector{
    // 返回值就是要导入到容器中的组件全类名
    /*
    * AnnotationMetadata:当前标注类的所有的注解信息
    * */
    @Override
    public String[] selectImports(AnnotationMetadata annotationMetadata) {

        return new String[]{"com.frank.demo.Person"};
    }
}
```

- 将该类放入@Import中
```
@Configuration
@Import({Person.class, MyImportSelector.class})
public class MainConfig {
}
```

#### ImportBeanDefinitionRegistrar 利用bean注册类来添加容器
- 建一个类实现ImportBeanDefinitionRegistrar
```
public class MyImportBeanDefinitionRegister implements ImportBeanDefinitionRegistrar {
    /*
    * AnnotationMetadata: 当前类的注解信息
    *
    * BeanDefinitionRegistry : bean定义的注册类
    *   把所有需要添加到容器中的bean都可以通过此类来注册
    * */
    @Override
    public void registerBeanDefinitions(AnnotationMetadata annotationMetadata, BeanDefinitionRegistry beanDefinitionRegistry) {
        // 手动注册
        // 判断是否有某个bean的注册信息
        boolean flag = beanDefinitionRegistry.containsBeanDefinition("red");
        if(flag) {
            // 传入名字和bean的定义信息类
            RootBeanDefinition rootBeanDefinition = new RootBeanDefinition(Person.class);
            beanDefinitionRegistry.registerBeanDefinition("person", rootBeanDefinition);
        }
    }
}
```

- 将该类放入@Import
```
@Configuration
@Import({Person.class, MyImportSelector.class, MyImportBeanDefinitionRegister.class})
public class MainConfig {
}
```

#### 利用FactoryBean(工厂bean)
- 键一个类实现FactoryBean<T>
```
public class PersonFactoryBean implements FactoryBean<Person> {
    // 该对象会添加到容器中,之后获取该工厂类的bean的时候就返回泛型中的bean
    @Override
    public Person getObject() throws Exception {
        return new Person(1, "测试名字");
    }

    @Override
    public Class<?> getObjectType() {
        return null;
    }

    // 控制是否是单例
    @Override
    public boolean isSingleton() {
        return true;
    }
}
```

- 在配置类中注册工厂
```
@Configuration
public class MainConfig {
    @Bean
    public PersonFactoryBean personFactoryBean(){
        return new PersonFactoryBean();
    }
}
```

### Bean的生命周期
#### 自己制定初始化和销毁方法
```
@Bean(initMethod = "init", destroyMethod = "destroy")
    public Person person(){
        return new Person(1, "测试");
    }
```

#### bean 实现InitializingBean, DisposableBean

```
public class Person implements InitializingBean, DisposableBean{

    private Integer id;
    private String name;

    public Person(Integer id, String name) {
        this.id = id;
        this.name = name;
    }

    public Integer getId() {
        return id;
    }

    public Person setId(Integer id) {
        this.id = id;
        return this;
    }

    public String getName() {
        return name;
    }

    public Person setName(String name) {
        this.name = name;
        return this;
    }

    @Override
    public String toString() {
        return "Person{" +
                "id=" + id +
                ", name='" + name + '\'' +
                '}';
    }

    @Override
    public void destroy() throws Exception {

    }

    @Override
    public void afterPropertiesSet() throws Exception {

    }
```

#### 可以使用JSR250规范的注解 @PostConstruct, @PreDestroy
```
public class Person {

    private Integer id;
    private String name;

    public Person(Integer id, String name) {
        this.id = id;
        this.name = name;
    }

    public Integer getId() {
        return id;
    }

    public Person setId(Integer id) {
        this.id = id;
        return this;
    }

    public String getName() {
        return name;
    }

    public Person setName(String name) {
        this.name = name;
        return this;
    }

    @Override
    public String toString() {
        return "Person{" +
                "id=" + id +
                ", name='" + name + '\'' +
                '}';
    }

    @PreDestroy
    public void destroy() throws Exception {

    }

    @PostConstruct
    public void init() throws Exception {

    }
}
```


#### BeanPostProcessor: 后置处理器
在Bean初始化前后进行一些处理工作  

Spring 底层对 BeanPostProcessor 的使用:
包括bean赋值，注入其他组件，@Autowired 等等，都是依托这个完成的

### 属性赋值
#### @Value
- 基本数值
- SPEL:
    + #{20-2} : 表达式
    + ${server.path.ol} : 配置文件中的值

#### @PropertySource
```
// 使用@PropertySource读取外部配置文件中的k/v保存到运行的环境变量中;
//加载完外部的配置文件后使用${}取出
@PropertySource(value = {"classpath:/person.properties"})
```

也可以使用 @PropertySources 指定多个@PropertySource

### 自动装配
Spring 利用依赖注入(DI),完成IOC容器中各个组件的依赖关系赋值;

#### @Autowired
- 优先默认安装组件的类型去容器中找，找到就赋值
- 如果找到多个相同类型的组件，再将属性的名称作为组件的id去容器中查找
- 可以使用@Qualifier("...") 明确指定需要装配的组件id,而不是使用属性名
- 可以使用 required=false 属性，如果没有该bean 会给一个null
- @Primary: 让Spring进行自动装配的使用，默认使用首选的Bean(也就是标注@Primary的Bean)

- 可以标注在构造器，属性，set方法上

#### Spring支持 @Resource(JSR250) 和 @Inject(JSR330)
- @Resource
默认按照组件名称来进行装配,没有@Autowired其他功能
- @Inject
和@Autowired功能一样


AutowiredAnnotationBeanProcesser : 它来完成自动装配

#### 自定义组件想要使用Spring容器底层的一些组件(ApplicationContext, BeanFactory, xxx)
自定义组件实现xxxxAware: 在创建对象时，会调用接口规定的方法注入相关组件: Aware
把Spring 底层的一些组件注入到自定义的Bean中;

```
public class Red implements ApplicationContextAware, BeanNameAware
    , EmbeddedValueResolverAware{

    private ApplicationContext applicationContext;

    @Override
    public void setApplicationContext(ApplicationContext applicationContext) throws BeansException {
        this.applicationContext = applicationContext;
    }

    @Override
    public void setBeanName(String name) {
        System.out.println("当前bean的名字:" + name);
    }

    /*
    * 用来解析字符串中的诸如 # $ {} 的占位符的方法
    * */
    @Override
    public void setEmbeddedValueResolver(StringValueResolver stringValueResolver) {
        String resolvedString  = stringValueResolver.resolveStringValue("你好 ${os.name} 我是#{}");
        System.out.println("解析后的值:" + resolvedString);
    }
}
```

#### @Profile
    可以根据当前环境，动态的激活和切换一系列组件的功能:
    比如区分开发环境，测试环境，生产环境
    默认是default环境
- 如何指定环境
    + 使用命令行参数: 在虚拟机参数位置加载 -Dspring.profiles.active=test
    + 代码的形式
```

```
    + springboot的话，配置文件中指定



# AOP:动态代理
指在程序运行期间动态的将某段代码切入到指定方法指定位置进行运行的编程方式
## 基本步骤
- 定义一个业务逻辑类
- 定义一个切面类，切面类里的方法需要动态感知到业务逻辑类的方法运行,参数里可以指定joinPoint来获取连接点(必须是第一个参数)
    + @Before 前置
    + @After 后置
    + @AfterReturning 返回后
        * retuing属性来指定返回值封装的形参名
    + @AfterThrowing 异常后
        * throwing属性来指定抛出异常的形参名
    + @Around 动态代理:手动推进目标方法运行 (joinPoint.procced())

- 给切面类的目标方法决定何时执行(标通知注解)
    + 可用@Poincut() 抽取公用的表达式
- 将切面类和业务逻辑类都加入容器中
- 标记切面类为 @Aspect 
- 配置类开启 @EnbableAspectJAutoProxy

## 原理分析
### @EnableAspect
- 该注解上标注了@Import({AspectJAutoProxyRegistrar.class}),也就是引入了该类到容器中
- AspectJAutoProxyRegistrar 实现了 ImportBeanDefinitionRegistrar,也就是可以自由注册组件到容器中的接口
- 接下来分析这个接口的注册方法，看都注册了什么
```
    // 第一行似乎是想看看是否需要注册 AspectJAnnotationAutoProxyCreator
    45 : AopConfigUtils.registerAspectJAnnotationAutoProxyCreatorIfNecessary(registry);
```
跟进该方法,层层跟进到

```java
private static BeanDefinition registerOrEscalateApcAsRequired(Class<?> cls, BeanDefinitionRegistry registry, Object source) {
        // cls = AnnotationAwareAspectJAutoProxyCreator
        Assert.notNull(registry, "BeanDefinitionRegistry must not be null");
        /*
            看看是否包含这个 AUTO_PROXY_CREATOR_BEAN_NAME : org.springframework.aop.config.internalAutoProxyCreator
        */ 
        if (registry.containsBeanDefinition(AUTO_PROXY_CREATOR_BEAN_NAME)) {
            BeanDefinition apcDefinition = registry.getBeanDefinition(AUTO_PROXY_CREATOR_BEAN_NAME);
            if (!cls.getName().equals(apcDefinition.getBeanClassName())) {
                int currentPriority = findPriorityForClass(apcDefinition.getBeanClassName());
                int requiredPriority = findPriorityForClass(cls);
                if (currentPriority < requiredPriority) {
                    apcDefinition.setBeanClassName(cls.getName());
                }
            }
            return null;
        }
        // 如果没有注册的话，就要注册这个 AnnotationAwareAspectJAutoProxyCreator

        RootBeanDefinition beanDefinition = new RootBeanDefinition(cls);
        beanDefinition.setSource(source);
        beanDefinition.getPropertyValues().add("order", Ordered.HIGHEST_PRECEDENCE);
        beanDefinition.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
        // 注册了这个 internalAutoProxyCreator
        registry.registerBeanDefinition(AUTO_PROXY_CREATOR_BEAN_NAME, beanDefinition);
        return beanDefinition;
    }
```

总之这个ImportBeanDefinitionRegistrar 就是往容器中注册了一个 AnnotationAwareAspectJAutoProxyCreator

- AnnotationAwareAspectJAutoProxyCreator 是干什么的
    AnnotationAwareAspectJAutoProxyCreator
    -> AspectJAwareAdvisorAutoProxyCreator
        -> AbstractAdvisorAutoProxyCreator
            -> AbstractAutoProxyCreator
                implements SmartInstantiationAwareBeanPostProcessor, (后置处理器)
                BeanFactoryAware (自动装配)
                (重点关心后置处理器,在bean初始化完成前后做的事情以及自动装配器)
    

AbstractAutoProxyCreator.setBeanFactory()
有后置处理器的逻辑
AbstractAutoProxyCreator.postProcessBeforeInstantiation()
AbstractAutoProxyCreator.postProcessAfterInitialization()

AbstractAdvisorAutoProxyCreator.setBeanFactory() => initBeanFactory

AspectJAwareAdvisorAutoProxyCreator 没啥

AnnotationAwareAspectJAutoProxyCreator.initBeanFactory()

流程:
1 初始化IOC容器
2 注册配置类, 调用 refresh() 刷新容器
3 registerBeanPostProcessors(beanFactory); 注册bean的后置处理器，来方便拦截bean的创建
    - 现获取IOC容器中已经定义了的需要创建对象的所有BeanPostProcessor
    - 给容器中加别的BeanPostProcessor
    - 优先注册实现了PriorityOrdered 的BeanPostProcessor
    - 再注册实现了 Order的BeanPostProcessor
    - 最后注册普通的BeanPostProcessor
    - 注册BeanPostProcessor, 实际上就是创建BeanPostProcessor对象，然后保存在容器中
      创建internalAutoProxyCreator的BeanPostProcessor(=AnnotationAwareAspectJAutoProxyCreator)
      + 创建Bean的实例
      + populateBean : 给Bean的各种属性赋值
      + initializeBean: 初始化Bean
          * invokeAwareMethods ； 处理Aware接口的方法回调
          * applyBeanPostProcessorsBeforeInitialization():执行后置处理器的postProcessBeforeInitialization(这里就是后置处理器的调用)
          * invokeInitMethods() : 执行自定义的初始化方法
          * applyBeanPostProcessorsAfterInitialization() : 执行后置处理器的执行后置处理器的postProcessAfterInitialization():
    - BeanPostProcessor(AnnotationAwareAspectJAutoProxyCreator)创建成功: => aspectJAdvisorsBuilder















