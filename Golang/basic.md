# CMD

### go env

查看go 相关的环境参数

# 基本类型

## 基本类型之间相互转换

- 基本格式是 T( ... )

- 字符串

```go
// string to int
int ,err := strconv.Atoi(string)
// string to int64
int64, err := strconv.ParseInt(string, 10, 64)
// int to string
string := strconv.Itoa(int)
// int64 to string
string := strconv.FormatInt(int64, 10)
```

## 特殊的值表示

- 前缀0 表示 8 进制数 : 077
- 0x 表示16进制数
- e 用来表示10的连乘
  - 1e3 = 1000
  - 6.022e23 = 6.022 * 1e23
- 书写 unicode 字符时，需要在16进制数之前加上前缀 \u 或者 \U
  - unicode至少占用2个字节，因此使用 int16 或 int 类型来表示
  - 需要使用 4 字节, 则会加上 \U 前缀
  - 前缀 \u 则总是紧跟着长度为4的16进制数
  - 前缀 \U 紧跟着长度为 8 的 16 进制数

## 常量

- 常量只可以是 布尔 数字 和字符串类型

### iota 的作用

- iota 是一个常量赋值器，只能在常量表达式中使用
- 每次 const 出现时，都会让 iota 初始化为 0

```go
const a = iota // a=0 
const ( 
  b = iota     //b=0 
  c            //c=1   相当于c=iota
)
```

- 可以使用 iota 来完成自增性的常量的声明

```go
type Stereotype int

const ( 
    TypicalNoob Stereotype = iota // 0 
    TypicalHipster                // 1   TypicalHipster = iota
    TypicalUnixWizard             // 2  TypicalUnixWizard = iota
    TypicalStartupFounder         // 3  TypicalStartupFounder = iota
)
```

- 可以使用 _ 跳过部分值

```go
const (
	a = iota + 1 //1
	_
	_
	b //4
	c //5
)
```

- 位掩码

```go
type Allergen int

const (
	IgEggs         Allergen = 1 << iota // 1 << 0 which is 00000001
	IgChocolate                         // 1 << 1 which is 00000010
	IgNuts                              // 1 << 2 which is 00000100
	IgStrawberries                      // 1 << 3 which is 00001000
	IgShellfish                         // 1 << 4 which is 00010000
)
```

- 定义数量级

```go
type ByteSize float64

const (
    _           = iota                   // ignore first value by assigning to blank identifier
    KB ByteSize = 1 << (10 * iota) // 1 << (10*1)
    MB                                   // 1 << (10*2)
    GB                                   // 1 << (10*3)
    TB                                   // 1 << (10*4)
    PB                                   // 1 << (10*5)
    EB                                   // 1 << (10*6)
    ZB                                   // 1 << (10*7)
    YB                                   // 1 << (10*8)
)
```

- 插队的结果

```go
const ( 
    i = iota 
    j = 3.14 
    k = iota 
    l 
)
//那么打印出来的结果是 i=0,j=3.14,k=2,l=3
```

- 定义在一行的结果

```go
const (
    Apple, Banana = iota + 1, iota + 2
    Cherimoya, Durian   // = iota + 1, iota + 2 
    Elderberry, Fig     //= iota + 1,
)
// 只在下一行才自增
// Apple: 1 
// Banana: 2 
// Cherimoya: 2 
// Durian: 3 
// Elderberry: 3 
// Fig: 4
```

### 字符串

- len() 函数返回字符串的字节数 (不是字符数)
- 下标访问操作符 [i] 取得第 i 个字符

```go
s := "天天"
fmt.Println(len(s)) // 6
fmt.Println(s[0], s[5]) // 229 169
```



## 基本语法

### 格式化

| verb     | 描述                               |
| -------- | ---------------------------------- |
| %d       | 十进制整数                         |
| %x,%o,%b | 十六进制，八进制，二进制整数       |
| %f,%g,%e | 无指数浮点数，浮点数，有指数浮点数 |
| %t       | 布尔型                             |
| %c       | 字符(unicode 码点)                 |
| %s       | 字符串                             |
| %q       | 带引号字符串或者字符('c')          |
| %v       | 内置格式的任何值                   |
| %T       | 任何值的类型                       |
| %%       | 百分号本身                         |
|          |                                    |
|          |                                    |
|          |                                    |
|          |                                    |

- fmt 的操作技巧

```go
o := 0666
// [1] 表示重复使用第一个操作数
// # 表示输出进制数的前缀 0 0x 0X
fmt.Printf("%d %[1]o %#[1]o\n", o)
//438 666 0666
```



### 声明变量

- 后置类型

```go
var a int
var b string
var c []float32
var d func() bool
var e struct {
  x int
}
```

- 批量声明

```go
var (
  a int
  b string
  c []float32
  d func() bool
  e struct{
    x int
  }
)
```

- 声明假如不赋值则自动赋予 初始值
- 短变量声明并初始化

```go
// 左值变量必须是没有定义过的变量
hp := 100
```

- 多个变量同时赋值

```go
var a int = 100
var b int = 200
b, a = a, b
```

- 匿名变量

  使用 - 

### 指针

- 类型指针
  - 允许对这个指针类型的数据进行修改
  - 传递数据使用指针，无须拷贝数据
  - 不能进行偏移和运算
- 切片
  - 指向起始元素的原始指针
  - 元素数量
  - 容量

#### 指针类型，指针地址

```go
var kk = "123"
// & 是取 kk 变量的指针，也就是取了指针地址
ptr := &kk
// ptr 就是 kk 的指针了， 其类型为 *T，这就是指针类型
// * 是对指针进行取值，所以 tt 的值就是 "123"了
var tt = *ptr
//assert tt == kk

```

#### 使用指针修改值

```go
// a,b的指针类型是 *int ，也即是说 b 是 int变量 的指针
func swap(a, b *int) {
  // 对值进行交换
  t := *a
  *a = *b
  *b = t
}
```

#### 通过 new() 来创建指针

```go
// 被创建的指针指向的值为默认值
str := new(string)
*str = "ninja"
fmt.Println(*str)
```



### 类型别名和类型定义

```go
// 类型定义
type byte uint8
type rune int32

// 类型别名
type byte = uint8
type rune = int32
```

- 类型别名只在编译期存在
- 类型别名不能定义方法，类型定义可以
- 类型别名混入结构体的时候，类型别名会得到保留



# 容器

## 数组

- 数组是值类型

- 声明

```go
var name [size]T
```

- 可以在声明的时候初始化

```go
/*
	数组的长度在声明的时候就必须确定
	数组的长度也是其类型的一部分
*/

var team = [3]string{"hammer", "soldier", "mum"}

// 也可以让编译器决定数组大小
var team = [...]string{"hammer", "soldier", "mum"}
```

- 遍历

```go
// k 为索引
for k, v := range team {
  fmt.Println(k, v)
}
```



## 切片

- 切片是引用类型

- 内部结构包括地址，大小和容量
- 一般用于快速地操作一块数据集合
- 切片的长度可以增加，但是不会减少

#### 从数组或切片生成新的切片

```go
// 不包括 endIndex
// startIndex 和 endIndex 可以缺省
// startIndex 和 endIndex 可以都写 0，表示空切片
slice [startIndex:endIndex]
```

```go
var a = [3]int{1,2,3}
fmt.Println(a, a[1:2])
```

#### 切片声明

```go
var name []T
```

#### 使用 make() 构造切片

```go
// T 切片类型
// size: 分配多少个元素,也就是实际给多少
// cap: 预分配的元素数量,也即是容量大小, 假如不声明，那么跟 size一致
// 一个切片的容量可以被看作是透过这个窗口最多可以看到的底层数组中元素的个数。
make([]T, size, cap)
```

```go
a := make([]int, 2)
b := make([]int, 2, 10)
```

#### 使用 append 函数添加元素

- 使用 append函数时，切片如若容量不够，会扩充为2倍
- 但发生扩容的时候，返回的新切片的底层数组对应的是扩容后产生的新的数组
- 假如增加的元素不至于发生扩容，那么会替换数组右边的元素

```go
var nums []int

for i := 0; i < 10; i++ {
  nums = append(nums, i)
}
```

- 可以一次性添加多个元素

#### 复制切片元素到另一个切片 copy()

```go
// 返回值表示实际copy的元素个数
// 目标切片必须分配过空间且足够承载复制的元素个数
copy(dest, src) int
```

#### 删除切片元素

```go
seq := []string{"a", "b", "c", "d", "e"}

// 指定删除位置
index := 2
// 将删除位置前后的两个切片合在一起
seq = append(seq[:index], seq[index+1:])
```

- 很麻烦，删除操作考虑其它容器

## 映射

```go
//map[keyType]valueType
scene := make(map[string]int)

// 声明时填充内容
m := map[string]string{
  "W": "forward",
  "A": "left"
}
```

- key不存在时，默认取出 value的零值

#### 判断key是否存在

```go
// 使用ok 来判断是否存在
v,ok := scene["route"]
```

#### 遍历

```go
for k, v := range scene {
	....
}

// 只遍历键
for k := range scene {
   ....
}
```

- 如果需要按顺序遍历，那么最好先用切片对 map 的key进行排序

#### 删除

```go
delete(map, key)
```

#### 在并发环境使用 sync.Map

```go
// 直接声明，无需初始化
var scene sync.Map

// 保存键值对
scene.Store("green", 97)

// 取值
scene.Load("green")

// 删除键值对
scene.Delete("london")

// 遍历
scene.Range(func(k, v interface{}) bool {
  ...
  //是否继续遍历
  return true
})
```



## 列表

是双向链表

#### 声明和初始化

```go
// 无类型限制
var l := list.New()

var l list.List
```

#### 插入元素

```go
l := list.New()
// 前后插入
l.PushBack("first")
l.PushFront(67)
```

#### 删除元素

插入函数会返回一个 *list.ELement 结果，可以用这个返回值进行快速删除

```go
l := list.New()
element := l.PushBack("canon")
// 在某个元素之后插入
l.InsertAfter("hign", element)

// 删除
l.Remove(element)

```

#### 遍历

```go
l := list.New()

l.PushBack("canon")
// 从头部开始遍历
for i := l.Front(); i != nil; i = i.Next() {
	i.Value
}

```



# 流程控制

## 条件表达式

```go
if ten > 10 {
  fmt.Println(">10")
} else {
  fmt.Println("<=10")
}
```

- 可以进行一次赋值

```go
if err := Connect(); err != nil {
  ....
}
```



## 构建循环

- range 表达式只会在一开始被求值一次
- range表达式的求值结果会被复制，也就是说，被迭代的对象是range表达式结果值的副本而不是原值。

```go

numbers2 := [...]int{1, 2, 3, 4, 5, 6}
maxIndex2 := len(numbers2) - 1
for i, e := range numbers2 {
  if i == maxIndex2 {

    numbers2[0] += e
  } else {
    // 在这里改变数组的内容并不会影响下一次迭代的值，因为 range表达式已经被求值过了, 副本也被保存下来了
    // 但是如果是切片，因为切片是引用类型，所以会影响到每一次迭代的值
    numbers2[i+1] += e
  }
}
fmt.Println(numbers2)
// 打印 [7, 3, 5, 7, 9, 7]
```



### 键值循环

#### 数组，切片，字符串返回索引和值

```go
for k,v := range []int{1,2,3,4} {
	.....
}
```



#### map 返回建和值

```go
for k, v := range m {
  ...
}
```



#### channel 只返回 通道的值

```go
c := make(chan int) 
go func() {
  c <-1
  c <-2
  c <-3
  close(c)
}()

for v := range c {
  .....
}
```



### 分支选择（switch）

switch  中的 case 之间是独立的代码块，无需break

#### 一分支多值

```go
switch a {
  case "mum", "daddy":
  	.....
}
```

#### 跨越case的fallthrough

(主要是为了兼容)

```go
switch {
  case s == "hello":
  	...
  	fallthrough
  case s != "world":
  	....
}
```



### 语句控制

#### 跳出多层循环

```go
func main () {
  for x :=0;x < 10;x ++ {
    for y := 0; y < 10; y++ {
      if y == 2 {
        // 跳转标签
        goto breakHere
      }
    }
  }
  return
  
  breakHere:
  	.....
}
```

#### 统一错误处理

```go
err := first CheckError()
if err != nil {
  goto onExit
}
err = secondCheckError()
if err != nil {
  goto onExit
}

onExit:
  ....
```

#### break跳出循环

coninue 同理

```go
OuterLoop:
for i := 0; i < 2; i++ {
  for j := 0; j < 5; j++ {
    switch j {
      case 2:
      	....
      	break OuterLoop
    }
  }
}
```









