## spring-boot 是通过 class-path 中的类来判断当前环境的
`SpringApplication` 的构造器中调用 `WebApplicationType.deduceFromClasspath()`

```java
private static final String[] SERVLET_INDICATOR_CLASSES = { "javax.servlet.Servlet",
			"org.springframework.web.context.ConfigurableWebApplicationContext" };

	private static final String WEBMVC_INDICATOR_CLASS = "org.springframework." + "web.servlet.DispatcherServlet";

	private static final String WEBFLUX_INDICATOR_CLASS = "org." + "springframework.web.reactive.DispatcherHandler";

	private static final String JERSEY_INDICATOR_CLASS = "org.glassfish.jersey.servlet.ServletContainer";

	private static final String SERVLET_APPLICATION_CONTEXT_CLASS = "org.springframework.web.context.WebApplicationContext";

	private static final String REACTIVE_APPLICATION_CONTEXT_CLASS = "org.springframework.boot.web.reactive.context.ReactiveWebApplicationContext";

	static WebApplicationType deduceFromClasspath() {
    // 假如 假如没有Servlet和jersey相关的配置,但是有 Webflux 的类，就推测为 WebFlux
		if (ClassUtils.isPresent(WEBFLUX_INDICATOR_CLASS, null) && !ClassUtils.isPresent(WEBMVC_INDICATOR_CLASS, null)
				&& !ClassUtils.isPresent(JERSEY_INDICATOR_CLASS, null)) {
			return WebApplicationType.REACTIVE;
		}
    // 不存在 Servlet的配置，推测为无web环境
		for (String className : SERVLET_INDICATOR_CLASSES) {
			if (!ClassUtils.isPresent(className, null)) {
				return WebApplicationType.NONE;
			}
		}
    // 默认推测为 Servlet环境
		return WebApplicationType.SERVLET;
	}
```

## 实际上这个环境可以通过定制 SpringApplication 来强制指定

```java
SpringApplication springApplication = new SpringApplication(LearnSpringbootApplication.class);
springApplication.setWebApplicationType(WebApplicationType.REACTIVE);
springApplication.run(args);
```