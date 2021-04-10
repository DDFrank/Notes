# 基本概念

## 索引 index

- 类似于 关系数据库 的数据库

## 类型 type

- 类似于 表

## 文档 document

- 类似于一行数据

## field

- 类似于 字段

## mapping

- 描述数据类型

# 操作指令

## 基本操作

- 启动 elasticsearch

```shell

```

# 查询API

## URI Search

- 就是在 URL 中使用查询参数
- 使用 "q" 指定查询字符串

```shell
curl -XGET http://es:9200/kibana_sample_data_econmmerce/_search?q=customer_first_name:Eddie
```

- df 默认字段，不指定时，会对所有字段进行查询
- Sort 排序 / from 和 size 用于分页
- Profile 可以查看查询时如何被执行的 （请求体内）



### 指定字段和泛查询

- q = title:2012 指定 title 字段
- q = 2012 : 会对所有字段查询 2012 



### Term 和 Phrase

- Beautiful Mind  等价于 Beautiful OR Mind (Term Query)

```shell
GET /movies/_search?q=title:Beautiful Mind
```

- "Beautiful Mind" 等价于 Beautiful AND Mind ( Phrase Query, 而且顺序也是固定的)

```shell
GET /movies/_search?q=title:"Beautiful Mind"
```



### 分组和引号

- title : (Beautiful And Mind) (Term Query)
- title : "Beautiful Mind" (Phrase Query)

### 布尔操作

```txt
AND / OR / NOT 或者 && / || / !
```

### 分组

- \+ : must
- \- : must_not

### 范围查询

- 区间表示 : [ ] 闭区间 { } 开区间 

```txt
year: {2019 TO 2018}
year: [* TO 2018]
```

### 算术符号

```txt
year: > 2010
year: (>2010&&<=2018)
year:(+>2010+<2018)
```

### 通配符查询 (效率比较低，内存占用大)

- ? 代表一个字符， * 代表 0 或多个自读
- 不建议使用

```txt
title:mi?d
title:be*
```

### 正则表达式

```txt
title"[bt]oy
```

### 模糊匹配与近似查询

```txt
title:beautifl~1
title:"lord rings"~2
```



## Request Body Search (推荐使用)

- 使用 ES 提供的， 基于 JSON 格式的更加完备的 DSL
- profile 字段 : 获取查询过程
- from / size 字段来分页, 获取靠后的分页结果成本比较高
- sort 字段
  - 最好在数字型或日期型字段上排序

```json
{
	"sort" : [{
    "order_date" : "desc"
  }]
}
```

- 对 _source 进行过滤，只返回需要的 _source
  - 如果 _source 没有存储，那就只返回匹配的文档的元数据
  - _source 支持使用通配符

```json
{
	"_source" : ["order_date", "order_date", "name*"]
}
```

### 脚本字段 (perls)

- 可以组合其它字段作为一个新字段在查询结果中返回

```json
{
	"script_fields": {
    "new_filed": {
 			"script" : {
        "lang" : "painless",
        "source" : "doc['order_date'].value + '_hello'"
      }     
    }
  }
}
```

### 使用查询表达式 - Match

#### term 查询

```json
{
	"query": {
    "match":{
      // 默认是 OR
      "comment":"Last Chirstmas"
      // 可以指定operator
      "operator" : "AND"
    }
  }
}
```

#### Match Phrase

```json
{
  "query": {
    "match_phrase": {
      "comment":{
        // 顺序出现
        "query":"Song Last Chrismas",
        // 可以容许中间多一个 term
        "slop":1
      }
    }
  }
}
```

### Query String

- 类似于 URI Query

```json
{
  "query":{
    "query_string": {
      "fields":["name","about"],
      "query":"(Ruan AND Yiming) OR (Java AND Elasticsearch)"
    }
  }
}
```



### Simple Query String

- 默认的 operator 是 OR

- 类似于 Query String, 但是会忽略错误的语法,同时只支持部分查询语法
- 不支持 AND OR NOT
- Term 之间默认的关系是OR，可以指定 operator
- 支持部分逻辑
  - \+ 替代 AND
  - \| 替代 OR
  - \- 替代 NOT

```json
{
  "query": {
    "simple_query_string": {
      "query": "Ruan - Yiming",
      "fields": ["name"]
      "default_operator": "AND"
    }
  }
}
```



## 指定查询的索引

- / _search : 集群上所有的索引
- / index1/_search : index1
- /index1,index2/_search : index1 和 index2
- /index*/_search : 以 index 开头的索引



## 多字段查询

### bool 查询

- 一个 bool 查询，是一个或多个查询子句的组合
- 有4 种子句
  - must: 必须匹配，贡献算分
  - should: 选择匹配，贡献算分
  - must_not: Filter Context 查询子句，必须不能匹配, 不贡献算分
  - filter: Filter Context 必须匹配，但是不贡献算分

- 子查询可以以任意的顺序出现
- 可以嵌套多个查询
- 如果 bool 查询中，没有 must 条件，那么 should 中必须至少满足一条查询

```json
// POST /products/_search
{
  "query": {
    "bool": {
      "must": {
        "term": {"price":"30"}
      },
      // 对于算分无影响
      "filter": {
        "term": {"avaliable":"true"}
      },
      "must_not": {
        "range": {
          "price":{"lte":10}
        }
      },
      "should":[
        {"term" : {"productId.keyword" : "JODL-X-1937-#pV7"}},
        {"term" : {"productId.keyword" : "XHDK-X-1293-#fj3"}},
      ],
      "minimum_should_match": 1
    }
  }
}
```

- 查询语句的结构，会对相关度算分产生影响
  - 同一层级下的竞争字段，具有相同的权重
  - 通过嵌套 bool 查询，可以改变对算分的影响





# Mapping

- 类似于 数据库中 schemea 的定义
  - 定义索引中的字段的名称
  - 定义字段的数据类型，比如字符串，数字，布尔....
  - 字段，倒排索引的相关配置
- Mapping 会把 JSON 文档映射为 Lucene 所需要的扁平格式
- 一个 Mapping 属于一个索引的 Type
  - 每个文档都属于一个 Type
  - 一个 Type 有一个 Mapping 定义
  - 7.0 开始，不需要在 Mapping 定义中指定 type 的信息

## 定义Mapping

- 使用 PUT API 可以建立 index 的Mapping

### 控制当前字段是否被索引

```json
{
  "mappings" : {
    "properties" : {
      "firstname" : {
        "type" : "text"
      },
				"mobile" : {
          "type":"text",
          // 不希望被索引的话，可以设置为 false, 默认为 true
          "index":false
        }
    }
  }
}
```

### Index Options

- 四种不同级别的配置，可以控制倒排索引记录的内容

- 是 跟 index 同级别的配置
  - docs : 记录 doc id
  - freqs : 记录 doc id 和 term frequencies
  - positions : 记录 doc id / term frequencies / term position
  - offsets : doc id / term frequencies / term positions / character offsets
- Text 类型默认记录 positions 其它默认为 docs
- 记录内容越多，占用空间越多

### null_value

- 只有 keyword 类型支持 设定 null_value

### copy_to 设置

- copy_to 将字段的数值拷贝的目标字段，所以可以用目标字段来进行搜索
- copy_to 的目标字段不出现在 _source 中

### 数组类型

- 没有专门的数组类型，但是任何字段都可以包含相同类型的值作为数组



## Exact Values 和 Full Text

- Exact Values : 包括数字/ 日期/具体一个字符串
  - ES中的keyword
  - 不需要分词，ES 为每一个字段生成倒排索引
- 全文本, 非结构化的文本数据
  - ES 中的 text
  - 一般需要分词



## 自定义分词

- 可以在创建索引时自定义 分词器

```json
{
  "settings": {
    "analysis": {
      "analyzer": {
        "my_english": {
          "type": "english",
          "stem_exclusion": ["organization", "organizations"],
          "stopwords": ["a", "an"...]
        }
      }
    }
  }
}
```

- 使用 这个命令来调试

```json
//POST _analyze
{
	"tokenizer": "standard"
	"char_filter": ["html_strip"],
	"text": "<b>hello world</b>"
}
```



### Character Filter

- 在 Tokenizer 之前对文本进行处理，比如增加删除以及替换字符
- 可以配置多个 Character Filters。
- 会影响 Tokenizer 的 position 和 offset 信息

#### 自带的 Character

- HTML strip ； 去除 html 标签
- Mapping : 字符串替换
- Pattern replace: 正则匹配替换

### Tokenizer

- 将原始的文本按照一定的规则，切为分词 (term or token)

#### 内置的 Tokenizer

- whitespace
- standard
- uax_url_email
- pattern
- keyword
- path hieratchy

### Token Filter

- 将 Tokenizer 输出的单词 (term) ，进行增删改

#### 内置的 Token Filters

- Lowercase
- stop
- synonym (近义词)







## 字段的数据类型

### 简单类型

- Text / Keyword
- Date
- Integer / Floating
- Boolean
- IPV4 & IPV6

### 复杂类型

- 对象类型/嵌套类型

### 特殊类型

- geo_point
- geo_shape
- precolator

## Dynamic Mapping

- 写入文档时，如果索引不存在，会自动创建索引
- Dynamic Mapping 的机制，可以自动生成 Mappings, 推算字段的类型
- 不能保证其正确性
- 如果类型设置的不对，有些功能就会无法使用，比如 Range 查询
- 使用 get /index/mappings 查看 mappings

### 类型的自动识别

- 字符串
  - 匹配日期格式: Date
  - 数字匹配为 float 或 long, 该功能默认关闭
  - 设置为 Text, 并且增加 keyword 子字段
- 布尔值 : boolean
- 浮点数: float
- 整数: long
- 对象 : Object
- 数组: 由第一个非空数字的类型所决定
- 空值: 忽略

### 能否更改 Mapping 的字段类型

#### 对于新增加字段

- Dynamic 设置为 true 时，一旦有新增字段的文档写入， Mapping 也同时被更新
- Dynamic 设为 false, Mapping 不会被更新，新增字段的数据无法被索引,但是信息会出现在 _source 中
- Dynamic 设置为 Strict, 文档写入失败

#### 对于已有字段，一旦已经有数据写入，就不再支持修改字段定义

#### 如果希望改变字段类型，必须 使用 Reindex APi, 重建索引



### Dynamic Mappings 的设置

```json
//PUT movies
{
	"mappings" : {
    "_doc": {
      "dynamic":"false"
    }
  }
}
```



## Index Template

- 帮助设定 Mappings 和 Settings ，并按照一定的规则，自动匹配到新创建的索引之上
  - 仅在一个新的索引被创建时，才会产生作用。修改 index template 不会影响已创建的索引
  - 可以设定多个index template，这些设置会被merge 在一起
  - 可以指定 order 的数值，控制 mergering 的过程

```json
// PUT _template/template_default
{
  //适用 index 的范围
  "index_patterns":["*"],
  "order":0,
  "version":1,
  "settings": {
    "number_of_shards":1,
    "number_of_replicas":1
  }
}

// PUT _template/template_test
{
  "index_patterns": ["test*"],
  "order": 1,
  "settings" : {
    ....
  },
  "mappings": {
    "date_detection":false,
    "numeric_detection":true
  }
}
```

### Index Template 的工作方式

- 当一个索引被新创建时:
  - 应用 ES 默认的 settings 和 mappings
  - 按 order 升序排列应用 Index Template 中的设定，高的覆盖低的
  - 应用创建索引时，用户所指定的 Settings 和 Mappings ，并覆盖之前模板的设定



## Dynamic Template

- 根据 ES 识别的数据类型，结合字段名称，来动态设定字段类型， 比如可以
  - 所有的字符串类型都设定为 Keyword, 或者关闭 keyword 字段
  - is 开头的字段都设置为 boolean
  - long_ 开头的都设置为 long 类型
- 定义在某个索引的 Mapping 中
  - template 有一个名称
  - 匹配规则是一个数组
  - 为匹配到字段设置 Mapping

```json
// PUT my_test_index
{
  "mappings" : {
    "dynamic_templates":[
      {
        "full_name": {
          "path_match": "name.*",
          "path_unmatch": "*.middle",
          "mapping" : {
            "type": "text",
            "copy_to": "full_name"
          }
        }
      }
    ]
  }
}
```



## 单字符串多字段查询

### Disjunction max query

- 将任何与任一查询匹配的文档作为结果返回
- 采用字段上最匹配的评分最终返回

```json

```



### Multi match query

#### 三种场景

- 最佳字段 (Best Fields) : 字段之间相互竞争，又相互关联， 比如 title 和 body
- 多数字段(Most Fields) : 相同的文本，加入子字段，以提供更加精确的匹配。其它字段作为匹配文档相关度的信号，匹配字段越多越好
- 混合字段 (Cross Field) : 对于某些实体，比如 人名，地址等。需要在多个字段中确定信息，单个字段只能作为整体的一部分。希望在任何这些列出的字段中找到尽可能多的词

### 

```json
// POST blogs/_search
{
  "query": {
    "multi_match":{
      // 默认类型，可以不用指定
      "type": "best_fields",
     // 查询文本
      "query": "Quick pets",
      // 在什么字段中查询
      "fields": ["title", "body"]
      "tie_breaker": 0.2,
      //
      "minimum_should_match": "20%"
    }
  }
}
```



# Aggregation

- ES 提供的 对数据进行统计分析的功能
  - 实时性高
- 通过聚合, 可以得到一个数据的概览，是分析和总结全套的数据
- 性能强劲
- Kibana 的可视化包表也是这么实现的

## 分类

- Bucket Aggregation ： 一些列满足特定条件的文档的集合
- Metric Aggregation : 一些数学运算,可以对文档字段进行统计分析
- Pipeline Aggregation: 对其他的聚合结果进行二次聚合
- Matrix Aggregation: 支持对多个字段的操作并提供一个结果矩阵



# 结构化搜索

- 指对结构化数据的搜索
  - 日期，布尔类型和数字都是结构化的
  - 可以使用 range 查询
- 文本也可以是结构化的
  - Term 查询 / Prefix 前缀查询