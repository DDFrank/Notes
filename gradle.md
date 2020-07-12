```groovy
//plugins {
//    id 'java'
//}
//
//group 'com.frank'
//version '1.0-SNAPSHOT'
//
//// 设置 JDK 版本
//sourceCompatibility = 1.8
//targetCompatibility = 1.8
//
//// 指定 maven 仓库为 maven 中央仓库
//repositories {
//    mavenCentral()
//}
//
//// 设置项目的依赖库
//dependencies {
//    compile group: 'com.google.code.gson', name: 'gson', version: '2.8.0'
//    testCompile group: 'junit', name: 'junit', version: '4.12'
//}
//
//// 指定 jar 包的名称
//jar {
//    baseName = 'first-gradle'
//    version = '0.1.0'
//}

// 定义一个叫 hello 的任务
task hello {
    // 添加了一个action
    doLast {
        // 可以访问现有任务的属性值
        println "Hello world! from the $hello.name task."
    }
}

// 任务的依赖关系
task build {
    doLast {
        println "i 'm build task"
    }
}

// 执行该任务之前会先执行 build
task release(dependsOn: build) {
    doLast {
        println "i 'm release task"
    }
}

// 也可以对现有任务添加依赖关系
release.dependsOn build

// 可以对现有的任务添加动作行为
hello.doFirst {
    println 'Hello doFirst'
}

// 在 doLast 动作中添加
hello.doLast {
    println 'Hello doLast1'
}

// 在 doLast 动作中添加
hello {
    doLast {
        println 'Hello doLast2'
    }
}

// 可以为任务设置属性，主要通过 ext.myProperty 来初始化值
task myTask {
    ext.myProperty = "myValue"
}

task printTaskproperties {
    doLast {
        println myTask.myProperty
    }
}

// 在任务中调用 groovy 方法
task groovyMethod {
    doLast {
        int a = 1, b =2
        int result = add(a,b)
        println "a add b is =" + result
    }

}
// 定义 groovy 方法
int add(int a, int b) {
    a + b
}

/*
* 任务的定义形式
* */
// 第一种
task task1 {
    doLast {
        println "Hello World!"
    }
}

// 第二种， 以字符串的形式定义
task('hello') {
    doLast {
        println "hello"
    }
}

// 第三种, 以字符串形式定义,类型为 copy 类型
task('copy', type:Copy) {
    from(file('srcDir'))
    into(buildDir)
}

// 第四种，使用 create创建
tasks.create(name: 'hello') {
    doLast {
        printLn "hello"
    }
}

// 对任务进行配置
task myCopy(type: Copy) {
    /*
    * 该任务实现了把 resources 目录下的所有 .txt, .xml 和 .properties
    * 文件全部拷贝到 target 目录下
    * from : 源目录
    * into: 目标目录
    * include: 只拷贝指定的文件格式
    * */
    from 'resources'
    into 'target'
    include('**/*.txt', '**/*.xml', '**/*.properties')
}

// 对任务的重写
/*
* 可以通过指定 overwrite 属性为 true 来实现对人物类的覆盖重写
* */

task secondCopy(type:Copy)

task secondCopy(overwrite: true) {
    doLast {
        println('overwrite the copy')
    }
}

// 跳过任务或禁用某个任务
task skipTask {
    doLast {
        println 'hello world'
    }
}
// 跳过
skipTask.onlyIf { !projects.hasProperty('skipTask')}
// 禁用
skipTask.enabled = false

```

## 自定义任务

任务分两种

- 简单任务类型: 行为是定义在一个动作闭包方法中的，这种简单类型的任务适合在一个编译脚本中实现一种功能
- 增强的任务类型: 任务的行为被提前构建在了任务里，只是提供一些配置属性让使用者设置

### 实现自定义的任务类型

- 直接在 build.gradle 中写，最简单方便，但是无法复用

```groovy
// 使用默认的属性值
task hello(type: GreetingTask)

// 自定义设置的属性值
task greeting(type:GreetingTask) {
    greeting = 'greetings from GreetingTask'
}

class GreetingTask extends DefaultTask {
    String greeting = 'hello from GreetingTask'
    // 标记为一个action
    @TaskAction
    def greet() {
        println greeting
    }
}
```

- 在我们构建项目的rootProjectDir/buildSrc/src/main/groovy 目录下编写，Gradle 会自动编译到当前项目的 classpath 中，该项目下所有编译脚本都可以使用，但是除了当前项目之外的都无法复用。
- 以单独的工程方式编写，这个工程最终编译发布为一个 JAR 包，它可以在多个项目或不同的团队中共享使用。

## 实现自定义插件

跟自定义任务差不多

## 组织代码的逻辑

- **从父级继承属性和方法**。在编译多工程的项目中，子工程可以从父工程继承属性和方法
- **配置注入**。在编译多工程的项目中，一个工程（通常是 root 工程）可以向另一个工程注入属性和方法
- **工程的 buildSrc 目录**。可以把你的脚本类文件放到指定的目录下，Gradle 能自动的编译并加载到工程的类路径中
- **共享脚本**。在外部的编译文件中定义公共的配置，可以在多个工程中或多个编译脚本中加载使用
- **自定义任务**。把你的编译逻辑封装到自定义的任务中，然后在不同的地方重复使用这些任务
- 把你的编译逻辑封装到自定义的插件中，可以在不同的工程中应用该插件。这个插件必须在脚本的类路径中，我们可以通过 buildSrc 方式或者添加包含该插件的外部库来实现
- **执行外部脚本**。在当前编译脚本中执行另一个 Gradle 脚本
- **使用第三方的类库**。在当前编译脚本中直接使用第三方的类库

## 文件操作类型



# 官方文档的笔记







