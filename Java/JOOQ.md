# JOOQ的作用
## JOOQ可以利用它的DSL用来生成SQL语句
- SQL building
- Code generation

## JOOQ可以直接用作代码中的sql语句来执行，来获取查询结果
- SQL building
- Code generation
- SQL execution
- Fetching

## JOOQ 可以用来做增删改查
- SQL building
- Code generation
- SQL execution

## 用这个命令生成文件
 java -cp jooq-3.11.7.jar:jooq-meta-3.11.7.jar:jooq-codegen-3.11.7.jar:mysql-connector-java-5.1.47.jar:. org.jooq.codegen.GenerationTool library.xml

 java -classpath jooq-3.11.7.jar:jooq-meta-3.11.7.jar:jooq-codegen-3.11.7.jar:mysql-connector-java-5.1.47-bin.jar:.org.jooq.codegen.GenerationTool library.xml

# SQL Building
## JOOQ 可以往配置里注入一些自定义参数 参考 Custom data
