

## 依赖的配置 : (dependency下的配置说明)

### groupId, artifactId 和 version

依赖的基本坐标

### type

- 依赖的类型，对应项目坐标定义的packageing。
- 大部分时候不用声明，默认为jar

### scope

- 依赖范围, 参见下文的依赖范围的说明

### optional

- 标记依赖是否可选, 见下文可选依赖

### exclusions

- 用来排除传递性依赖



## 依赖范围

依赖范围是用来控制依赖和几种 classpath 的关系，主要要以下几种

- compile: 编译依赖范围，默认值
  - 使用此范围的话，对于编译，测试，运行三种 classpath 都有效。比如 spring-core
- test: 测试依赖范围
  - 只对测试的 classpath 有效。比如 JUint
- provided: 已提供依赖范围
  - 对于编译和测试 classpath 有效，但是运行时无效，比如 lombak
- runtime:运行时依赖范围。
  - 对于测试和运行 classpath 有效，但在编译主代码时无效。
  - 比如JDBC 驱动实现，项目主代码的编译只需要JDK提供的JDBC接口，只有在执行测试或者运行项目时才需要上述接口的具体JDBC驱动
- system: 系统依赖范围,与 classpath 的关系和 provided 一样。
  - 使用时必须通过 systemPath 元素显式地指定依赖文件的路径
  - 此类依赖不是通过 Maven 仓库解析的，而且往往与本机系统绑定，应该谨慎使用(可以使用环境变量)
- import: 导入依赖范围。对三种 classpath 没有实际影响
  - 导入指向的 pom 的文件的 dependencyManagement 的配置

## 可选依赖

- 项目A 依赖于项目B， 项目B依赖于项目X和Y， B 对于X和Y的依赖都是可选依赖
- 假如三个依赖的范围都是 compile, 那么 X, Y 就是 A 的 compile 范围传递性依赖，然而，由于这里X, Y 是可选依赖，依赖将不会得以传递

# 生命周期

Maven 有三套相互独立的生命周期:

- clean: 清理项目
- default: 构建项目
- site: 建立项目站点

每个生命周期包含一些阶段，这些阶段是有顺序的，并且后面的阶段依赖于前面的阶段

## clean 生命周期

主要是用来清理项目,包含三个阶段

- pre-clean: 执行一些清理前需要完成的工作。
- clean: 清理上一次构建生成的文件。
- post-clean: 执行一些清理后需要完成的工作。

## default生命周期

真正构建时所需要执行的所有步骤，是所有生命周期中最核心的部分

- validate
- initialize
- generate-sources
- process-sources: 处理项目主资源文件。一般来说，是对 src/main/resources 目录进行变量替换等工作后，复制到项目输出的主 classpath 目录中。
- generate-resources
- process-resources
- compile: 编译项目的主源码。一般来说，是编译 src/main/java 目录下的java文件至项目输出的主 classpath 目录中
- process-classes
- generate-test-sources
- process-test-sources: 处理项目测试资源文件。
- generate-test-resources
- process-test-resources
- test-compile: 编译项目的测试代码。一般来说，是编译 src/test/java 目录下的java文件至项目输出的测试 classpath 目录中
- process-test-classes:
- test: 使用单元测试框架运行测试，测试代码不会被打包或部署
- prepare-package
- package: 接受编译好的代码，打包成可发布的格式，如JAR
- pre-integration-test
- integration-test
- post-integration-test
- verify
- install: 将包安装到Maven本地仓库，供本地其它Maven项目使用
- deploy: 将最终的包复制到远程仓库，供其他开发人员和Maven项目使用

## site 生命周期

目的是建立和发布项目站点，Maven能够基于POM所包含的信息，自动生成一个友好的站点

- pre-site: 执行一些在生成项目站点之前需要完成的工作
- site: 生成项目站点文档
- post-site: 执行一些在生成项目站点之后需要完成的工作
- site-deploy: 将生成的项目站点发布到服务器上

# 编写自定义的Maven插件

## 主要步骤

### 创建一个 maven-plugin 项目

- 插件本身也是 Maven 项目，特殊的地方在于它的 packageing 必须是 maven-plugin

### 为插件编写目标

- 每个插件都必须包含一个或者多个目标, Maven 称之为 Mojo

- 编写插件的时候必须提供一个或者多个继承自 AbstractMojo 的类

### 为目标提供配置点

- 大部分Maven插件及其目标都是可配置的，因此在编写 Mojo 的时候需要提供可配置的参数

### 编写代码实现目标行为

- 根据实际的需要实现Mojo

### 错误处理及日志

- 当 Mojo 发生异常时，根据情况控制Maven 的运行状态，编写合适的日志提供信息

### 测试插件

- 编写自动化的测试代码测试行为，然后再实际运行插件以验证其行为





# 常用命令

- 查看某个jar包的引用关系

```
mvn dependency:tree -Dverbose -Dincludes=org.springframework.boot:spring-boot-starter-web
```

