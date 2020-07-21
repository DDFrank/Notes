# 自动配置类
```java
@Configuration
//当前环境必须是WebMvc（Servlet）环境
@ConditionalOnWebApplication(type = Type.SERVLET)
//当前运行环境的classpath中必须有Servlet类，DispatcherServlet类，WebMvcConfigurer类
@ConditionalOnClass({ Servlet.class, DispatcherServlet.class, WebMvcConfigurer.class })
//如果没有自定义WebMvc的配置类，则使用本自动配置
@ConditionalOnMissingBean(WebMvcConfigurationSupport.class)
@AutoConfigureOrder(Ordered.HIGHEST_PRECEDENCE + 10)
// 必须在这三个配置之后执行
@AutoConfigureAfter({ DispatcherServletAutoConfiguration.class, TaskExecutionAutoConfiguration.class,
		ValidationAutoConfiguration.class })
public class WebMvcAutoConfiguration{}
```

- `DispatcherServletAutoConfiguration` 主要是配置`DispatcherServlet` 和内嵌Web容器的,详情见下文
- 使用了 `WebMvcConfigurer` 的子类来进行 MVC的基本配置, 中间有大量mvc的配置，可以仔细看源码


```java
	@Configuration
	// 核心配置
	@Import(EnableWebMvcConfiguration.class)
	@EnableConfigurationProperties({ WebMvcProperties.class, ResourceProperties.class })
	@Order(0)
	public static class WebMvcAutoConfigurationAdapter implements WebMvcConfigurer {
		// 中有大量相关配置
	}
```

- `EnableWebMvcConfiguration` 的配置
	- 处理器适配器
	- 处理器映射器
	- 校验器
	- 全局异常处理器

## DispatcherServletAutoConfiguration 的作用
```java
@AutoConfigureOrder(Ordered.HIGHEST_PRECEDENCE)
@Configuration
@ConditionalOnWebApplication(type = Type.SERVLET)
// 主要是进行对于 DispatcherServlet 的配置, 
@ConditionalOnClass(DispatcherServlet.class)
// 该配置类需要保证有一个内嵌的web容器，或者 使用了 `SpringBootServletInitializer` 的可部署程序(WAR包)
// 具体查看 ServletWebServerFactoryAutoConfiguration 的作用
@AutoConfigureAfter(ServletWebServerFactoryAutoConfiguration.class)
public class DispatcherServletAutoConfiguration {

}
```
DispatcherServletAutoConfiguration 中有几大配置类

- DispatchServlet的配置
```java
@Configuration
	@Conditional(DefaultDispatcherServletCondition.class)
	// Servlet 3.0 的规范中Servlet注册类
	@ConditionalOnClass(ServletRegistration.class)
	@EnableConfigurationProperties({ HttpProperties.class, WebMvcProperties.class })
	protected static class DispatcherServletConfiguration {
		//.....
		// 注入 spring.http 和 spring.mvc 开头的配置
		public DispatcherServletConfiguration(HttpProperties httpProperties, WebMvcProperties webMvcProperties) {
			this.httpProperties = httpProperties;
			this.webMvcProperties = webMvcProperties;
		}
		// 默认就是 dispatcherServlet 
		@Bean(name = DEFAULT_DISPATCHER_SERVLET_BEAN_NAME)
		public DispatcherServlet dispatcherServlet() {
			DispatcherServlet dispatcherServlet = new DispatcherServlet();
			// 是否传递 Options方法到 doService
			dispatcherServlet.setDispatchOptionsRequest(this.webMvcProperties.isDispatchOptionsRequest());
			// 是否传递 Trace方法到 doService
			dispatcherServlet.setDispatchTraceRequest(this.webMvcProperties.isDispatchTraceRequest());
			// 没找到handler时是否要抛出 NoHandlerFoundException 异常
			dispatcherServlet
					.setThrowExceptionIfNoHandlerFound(this.webMvcProperties.isThrowExceptionIfNoHandlerFound());
			// 是否打印 Request的debug和trace级别的日志
			dispatcherServlet.setEnableLoggingRequestDetails(this.httpProperties.isLogRequestDetails());
			return dispatcherServlet;
		}
		//...
	}
```

- MultiPart解析器的配置

```java
@Bean
@ConditionalOnBean(MultipartResolver.class)
@ConditionalOnMissingBean(name = DispatcherServlet.MULTIPART_RESOLVER_BEAN_NAME)
public MultipartResolver multipartResolver(MultipartResolver resolver) {
	// Detect if the user has created a MultipartResolver but named it incorrectly
	return resolver;
}
```

- 将DispatcherServlet注册为Servlet的配置类

```java
	@Configuration
	@Conditional(DispatcherServletRegistrationCondition.class)
	@ConditionalOnClass(ServletRegistration.class)
	@EnableConfigurationProperties(WebMvcProperties.class)
	// DispatcherServletConfiguration 已经被标注为 Configuration 了，为啥这里还需要 @Import? TODO
	@Import(DispatcherServletConfiguration.class)
	protected static class DispatcherServletRegistrationConfiguration {

		private final WebMvcProperties webMvcProperties;

		private final MultipartConfigElement multipartConfig;

		public DispatcherServletRegistrationConfiguration(WebMvcProperties webMvcProperties,
				ObjectProvider<MultipartConfigElement> multipartConfigProvider) {
			this.webMvcProperties = webMvcProperties;
			this.multipartConfig = multipartConfigProvider.getIfAvailable();
		}

		@Bean(name = DEFAULT_DISPATCHER_SERVLET_REGISTRATION_BEAN_NAME)
		@ConditionalOnBean(value = DispatcherServlet.class, name = DEFAULT_DISPATCHER_SERVLET_BEAN_NAME)
		public DispatcherServletRegistrationBean dispatcherServletRegistration(DispatcherServlet dispatcherServlet) {
			/*
				DispatcherServletRegistrationBean 这个类继承了 ServletRegistrationBean，在构造器中通过调用
				addUrlMappings 将 DispatcherServlet 的 urlMapping 注册到了 webMvcProperties 中的配置值，默认为/
			*/ 
			DispatcherServletRegistrationBean registration = new DispatcherServletRegistrationBean(dispatcherServlet,
					this.webMvcProperties.getServlet().getPath());
			registration.setName(DEFAULT_DISPATCHER_SERVLET_BEAN_NAME);
			registration.setLoadOnStartup(this.webMvcProperties.getServlet().getLoadOnStartup());
			if (this.multipartConfig != null) {
				registration.setMultipartConfig(this.multipartConfig);
			}
			return registration;
		}

	}
```

## ServletWebServerFactoryAutoConfiguration 的作用
```java
@Configuration
//在自动配置中具有最高优先级执行
@AutoConfigureOrder(Ordered.HIGHEST_PRECEDENCE)
@ConditionalOnClass(ServletRequest.class)
@ConditionalOnWebApplication(type = Type.SERVLET)
// 加载 spring.server 相关的配置
@EnableConfigurationProperties(ServerProperties.class)
// 加载如下Bean，主要是对内嵌web容器的配置
@Import({ ServletWebServerFactoryAutoConfiguration.BeanPostProcessorsRegistrar.class,
				// 必须有 Tomcat 类 配置才会生效
        ServletWebServerFactoryConfiguration.EmbeddedTomcat.class,
				// 必须有 Jetty 相关的配置
        ServletWebServerFactoryConfiguration.EmbeddedJetty.class,
				// 必须有 Undertow 相关的配置
        ServletWebServerFactoryConfiguration.EmbeddedUndertow.class })
public class ServletWebServerFactoryAutoConfiguration
```

本配置类主要是对内嵌的web容器进行配置

### ServletWebServerFactoryAutoConfiguration.BeanPostProcessorsRegistrar 的作用

```java
public static class BeanPostProcessorsRegistrar implements ImportBeanDefinitionRegistrar, BeanFactoryAware {
    // ......
    @Override
    public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata,
            BeanDefinitionRegistry registry) {
        if (this.beanFactory == null) {
            return;
        }
        // 编程式注入组件
				// Bean的后置处理器，它将 Bean 工厂中的所有 WebServerFactoryCustomizer 类型的 Bean 应用于 WebServerFactory 类型的 Bean
				// Customizer的作用详见下文
        registerSyntheticBeanIfMissing(registry, "webServerFactoryCustomizerBeanPostProcessor",
                WebServerFactoryCustomizerBeanPostProcessor.class);
				// Bean的后置处理器，它将Bean工厂中的所有 ErrorPageRegistrars 应用于 ErrorPageRegistry 类型的Bean
				// 也即是 将所有设置的错误页跳转规则注册到错误处理器中
        registerSyntheticBeanIfMissing(registry, "errorPageRegistrarBeanPostProcessor",
                ErrorPageRegistrarBeanPostProcessor.class);
    }

    private void registerSyntheticBeanIfMissing(BeanDefinitionRegistry registry, String name, Class<?> beanClass) {
        if (ObjectUtils.isEmpty(this.beanFactory.getBeanNamesForType(beanClass, true, false))) {
            RootBeanDefinition beanDefinition = new RootBeanDefinition(beanClass);
						// 设置为不是由 application 本身来定义,即这是一个helper类，不会开发口子给外部定义
            beanDefinition.setSynthetic(true);
            registry.registerBeanDefinition(name, beanDefinition);
        }
    }
}
```
ServletWebServerFactoryAutoConfiguration 类中还注册了2个 ServletWebServerFactoryCustomizer，用于实现自动化配置
```java
	@Bean
	public ServletWebServerFactoryCustomizer servletWebServerFactoryCustomizer(ServerProperties serverProperties) {
		// 利用配置文件中的 spring.server 配置来覆盖默认配置
		return new ServletWebServerFactoryCustomizer(serverProperties);
	}

	@Bean
	@ConditionalOnClass(name = "org.apache.catalina.startup.Tomcat")
	public TomcatServletWebServerFactoryCustomizer tomcatServletWebServerFactoryCustomizer(
			ServerProperties serverProperties) {
		// 针对tomcat的自定义配置
		return new TomcatServletWebServerFactoryCustomizer(serverProperties);
	}

```

### WebServerFactoryCustomizer 类的作用
在 SpringMVC 中，可以通过 WebServerFactoryCustomizer 的实现类来对部分配置进行编程式的修改

```java
// 通过设置执行顺序，可以覆盖某些自动配置
@Order(0)
@Component
public class WebMvcCustomizer implements WebServerFactoryCustomizer<TomcatServletWebServerFactory>, Ordered {
    
    @Override
    public void customize(TomcatServletWebServerFactory factory) {
				// 修改端口
        factory.setPort(9090);
        factory.setContextPath("/demo");
    }
    
    @Override
    public int getOrder() {
        return 0;
    }
    
}
```
