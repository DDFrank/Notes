# spring 是如何进行包扫描的
`AnnotationConfigServletWebServerApplicationContext` 中有定义扫描器
`AnnotatedBeanDefinitionReader` 和 `ClassPathBeanDefinitionScanner`

## ClassPathBeanDefinitionScanner 的扫描方法
```java
  protected Set<BeanDefinitionHolder> doScan(String... basePackages) {
		Assert.notEmpty(basePackages, "At least one base package must be specified");
		Set<BeanDefinitionHolder> beanDefinitions = new LinkedHashSet<>();
		for (String basePackage : basePackages) {
      // 扫码包路径，获取全部的 BeanDefinition
			Set<BeanDefinition> candidates = findCandidateComponents(basePackage);
      // 遍历每个 BeanDefinition, 做一些后置处理
			for (BeanDefinition candidate : candidates) {
				ScopeMetadata scopeMetadata = this.scopeMetadataResolver.resolveScopeMetadata(candidate);
				candidate.setScope(scopeMetadata.getScopeName());
        // 生成bean的名称
				String beanName = this.beanNameGenerator.generateBeanName(candidate, this.registry);
				if (candidate instanceof AbstractBeanDefinition) {
          // 设置默认值
					postProcessBeanDefinition((AbstractBeanDefinition) candidate, beanName);
				}
				if (candidate instanceof AnnotatedBeanDefinition) {
          // 根据 Bean 上标注的注解来获取一些配置，比如 @Lazy @Primary等
					AnnotationConfigUtils.processCommonDefinitionAnnotations((AnnotatedBeanDefinition) candidate);
				}

        // 检查 bean 的名称是否有冲突
				if (checkCandidate(beanName, candidate)) {
          // 都没有问题的话就利用 BeanDefinitionHolder 进行注册了
					BeanDefinitionHolder definitionHolder = new BeanDefinitionHolder(candidate, beanName);
					definitionHolder =
							AnnotationConfigUtils.applyScopedProxyMode(scopeMetadata, definitionHolder, this.registry);
					beanDefinitions.add(definitionHolder);
					registerBeanDefinition(definitionHolder, this.registry);
				}
			}
		}
		return beanDefinitions;
	}
```

### findCandidateComponents
扫码包路径，获取全部的 BeanDefinition
```java
// ResourcePatternResolver
String CLASSPATH_ALL_URL_PREFIX = "classpath*:";

static final String DEFAULT_RESOURCE_PATTERN = "**/*.class";
private String resourcePattern = DEFAULT_RESOURCE_PATTERN;

private Set<BeanDefinition> scanCandidateComponents(String basePackage) {
    Set<BeanDefinition> candidates = new LinkedHashSet<>();
    try {
        // 拼接包扫描路径
        String packageSearchPath = ResourcePatternResolver.CLASSPATH_ALL_URL_PREFIX +
                resolveBasePackage(basePackage) + '/' + this.resourcePattern;
        // 4.2.3,4 包扫描
        Resource[] resources = getResourcePatternResolver().getResources(packageSearchPath);
        for (Resource resource : resources) {
            if (resource.isReadable()) {
                try {
                    MetadataReader metadataReader = getMetadataReaderFactory().getMetadataReader(resource);
                    if (isCandidateComponent(metadataReader)) {
                        ScannedGenericBeanDefinition sbd = new ScannedGenericBeanDefinition(metadataReader);
                        sbd.setResource(resource);
                        sbd.setSource(resource);
                        if (isCandidateComponent(sbd)) {
                            candidates.add(sbd);
                        }
                // log和catch部分省略
    return candidates;
}
```
TODO 这里具体是如何扫描的先略过，后续补完

## TODO 在 spring-boot 是何时开始扫描的?