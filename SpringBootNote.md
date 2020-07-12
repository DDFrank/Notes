
## 想要自动设定中的某部分失效的话
```java
@Configuration
// 使用exclude属性
@EnableAutoConfiguration(exclude={DataSourceAutoConfiguration.class})
public class MyConfiguration {
}
```

## Springboot ApplicationEvent 和 Registe 研究一下如何业务解耦

## 可以实现 ApplicationRunner 或者 CommandLineRunner 来在Run()方法完成后执行一些代码


## 组件注册
### Servlet注册
- 继承 HttpServlet
- 用Java自带的 @WebServlet 标记Servlet
- 使用Spring的 ServletScan 去获取servlet并注册

### Filter注册
- 继承 Spring的 OncePerRequestFilter
- 标记 @WebFilter , filter 可以指定需要过滤的 servlet名字，也可以指定需要过滤的路径

### 监听器
- 实现接口
超多..

- 标记 @WebListener

## Springboot API的方式去注册
### Servlet组件注册
- 拓展 Servlet
    + HttpServlet
    + FrameworkServlet
- 组装Servlet
    + orr.springframework.......ServletRegistrationBean (1.4 开始有, 1.5开始就没有了)
- 暴露为SpringBean
@Bean


```
@Bean
public static ServletRegistrationBean servletRegistrationBean() {
    ServletRegistrationBean servletRegistrationBean = new ServletRegistrationBean();

    servletRegistrationBean.setServlet(new MyServlet());
    servletRegistrationBean.addUrlMappings("....");
    servletRegistrationBean.addInitParameter(... , ...);

    return servletRegistrationBean;
}

@Bean
public static FilterRegistrationBean filterRegistration() {
    FilterRegistrationBean filterRegistrationBean = new FilterRegistrationBean();

    filterRegistrationBean.setFilter(new MyFilter());
    filterRegistrationBean.addServletNames();

    filterRegistrationBean.setDispatcherTypes(DispatcherType.Request, .....);

}

// 监听器也是差不多的
ServletListenerRegistrationBean
```
