## 基本语法

### 接口声明的格式

```go
type 接口类型名 interface {
  方法名(参数)返回值
  ....
}
```

### 在接口和类型间转换

#### 类型断言基本格式

```go
// i 接口变量
// T 目标类型
// 假如 i 没有完全实现 T 接口的方法，那么ok就会为false
// 可以用于判断是否是某类型
t,ok := i.(T)
```

### 使用类型分支判断基本类型

```go
func printType(v interface{}) {
  switch v.(type) {
    case int:
    	....
    case string:
    	.....
    case bool:
    	....
    default:
    	....
  }
}
```

