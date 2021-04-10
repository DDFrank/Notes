## 基本语法

很简单

### 带有变量名的返回值

 go 支持多个返回值，因此给返回值命名有助于提高可读性

```go
func named RetValues() (a, b int) {
  a = 1
  b = 2
  return
}

t ,_ = named()
```



### 函数实现接口

- 函数的声明不能直接实现接口,需要将函数定义为类型，使用类型实现结构体

```go
// 函数定义为类型
type FuncCaller func(interface{})
// 实现 Invoker接口的Call方法
func (f FuncCaller) Call(p interface{}) {
  f(p)
}

// 使用
var invoker Invoker

// 将匿名函数转换为 FuncCaller 类型，再赋值给接口
invoker = FuncCaller(func(v interface{}) {
  .....
})

// 使用接口调用 Call
invoker.Call("hello")

```



### 可变参数列表



### 延迟执行

先 defer 的后执行