# 基础语法

## 基本类型

### 数字

- 没有隐式转换，需要调用函数来转换

### 数组

- 用 Array 类表示, 使用 [] 重载了 get set 方法
- 可以使用库函数 arrayOf 来创建数组并传递值给它 : arrayOf(1, 2, 3)
- arrayOfNulls 创建一个都是 null 的数组
- 也可以用库函数

```kotlin
fun main() {
//sampleStart
    // 创建一个 Array<String> 初始化为 ["0", "1", "4", "9", "16"]
    val asc = Array(5) { i -> (i * i).toString() }
    asc.forEach { println(it) }
//sampleEnd
}
```

- kotlin 的数组时不型变的
- Kotlin 也有不使用开装箱的原生类型数组 ： ByteArray`、 `ShortArray`、`IntArray



### 字符串

- 字符串是不可变的，可以使用 [] 来访问元素，也可以 for 迭代
- 可以用 """ 来输出原始字符串，并通过 trimMargin 去除前导空格

## 方便的语法

### 字符串模板

```kotlin
fun main() {
//sampleStart
    var a = 1
    // 模板中的简单名称：
    val s1 = "a is $a" 

    a = 2
    // 模板中的任意表达式：
    val s2 = "${s1.replace("is", "was")}, but now is $a"
//sampleEnd
    println(s2)
}
```

### if 表达式

```kotlin
//sampleStart
fun maxOf(a: Int, b: Int) = if (a > b) a else b
//sampleEnd

fun main() {
    println("max of 0 and 42 is ${maxOf(0, 42)}")
}
```

### null 检测

- 当某个变量可能为 null 的时候，可以在变量后加一个 ? 标识

```kotlin
fun parseInt(str: String): Int? {
    return str.toIntOrNull()
}

//sampleStart
fun printProduct(arg1: String, arg2: String) {
    val x = parseInt(arg1)
    val y = parseInt(arg2)

    // 直接使用 `x * y` 会导致编译错误，因为他们可能为 null
    if (x != null && y != null) {
        // 在空检测后，x 与 y 会自动转换为非空值（non-nullable）
        println(x * y)
    }
    else {
        println("either '$arg1' or '$arg2' is not a number")
    }    
}
```



### 类型检测

- 使用 is 可以判断某类是否是某类型，判断后会进行类型的自动转换

```kotlin
//sampleStart
fun getStringLength(obj: Any): Int? {
    // `obj` 在 `&&` 右边自动转换成 `String` 类型
    if (obj is String && obj.length > 0) {
      return obj.length
    }

    return null
}
//sampleEnd


fun main() {
    fun printLength(obj: Any) {
        println("'$obj' string length is ${getStringLength(obj) ?: "... err, is empty or not a string at all"} ")
    }
    printLength("Incomprehensibilities")
    printLength("")
    printLength(1000)
}
```



### when 表达式

- 基本用法

```kotlin
//sampleStart
fun describe(obj: Any): String =
    when (obj) {
        1          -> "One"
        "Hello"    -> "Greeting"
        is Long    -> "Long"
        !is String -> "Not a string"
        else       -> "Unknown"
    }
//sampleEnd

fun main() {
    println(describe(1))
    println(describe("Hello"))
    println(describe(1000L))
    println(describe(2))
    println(describe("other"))
}
```

- 可以复用结果的条件可以用逗号隔开写一起

```kotlin
when (x) {
    0, 1 -> print("x == 0 or x == 1")
    else -> print("otherwise")
}
```

- 1.3 开始，可以使用类似于 erlang when case 的用法

```kotlin
fun Request.getBody() =
        when (val response = executeRequest()) {
            is Success -> response.body
            is HttpError -> throw HttpException(response.status)
        }
```



### 使用 区间

- 使用 in 来查看是否在某个区间

```kotlin
fun main() {
//sampleStart
    val x = 10
    val y = 9
    if (x in 1..y+1) {
        println("fits in range")
    }
//sampleEnd
}
```

- 可以查看是否再区间外

```kotlin
fun main() {
//sampleStart
    val list = listOf("a", "b", "c")

    if (-1 !in 0..list.lastIndex) {
        println("-1 is out of range")
    }
    if (list.size !in list.indices) {
        println("list size is out of valid list indices range, too")
    }
//sampleEnd
}
```

- 数列迭代

```kotlin
fun main() {
//sampleStart
    for (x in 1..10 step 2) {
        print(x)
    }
    println()
    for (x in 9 downTo 0 step 3) {
        print(x)
    }
//sampleEnd
}
```



### 标签与跳转

- Kotlin 里所有表达式前都可以加一个标签 格式为 标识符+@
- 这些标签可以跟 break 等跳转命令配合使用

```kotlin
loop@ for (i in 1..100) {
    for (j in 1..100) {
        if (……) break@loop
    }
}
```

- 可以利用 标签处返回 从一个lambda 表达式中返回 类似于 continue

```kotlin
//sampleStart
fun foo() {
    listOf(1, 2, 3, 4, 5).forEach {
        if (it == 3) return@forEach // 局部返回到该 lambda 表达式的调用者，即 forEach 循环
        print(it)
    }
    print(" done with implicit label")
}
//sampleEnd

fun main() {
    foo()
}
```

- 也可以利用匿名函数来实现

```kotlin
fun foo() {
    listOf(1, 2, 3, 4, 5).forEach(fun(value: Int) {
        if (value == 3) return  // 局部返回到匿名函数的调用者，即 forEach 循环
        print(value)
    })
    print(" done with anonymous function")
}
//sampleEnd

fun main() {
    foo()
}
```

- 要想真的跳出 lambda 表达式可以模拟

```kotlin
//sampleStart
fun foo() {
    run loop@{
        listOf(1, 2, 3, 4, 5).forEach {
            if (it == 3) return@loop // 从传入 run 的 lambda 表达式非局部返回
            print(it)
        }
    }
    print(" done with nested loop")
}
//sampleEnd

fun main() {
    foo()
}
```



## 函数与Lambda 表达式

### 函数

- 基本类型

```kotlin
//sampleStart
fun sum(a: Int, b: Int): Int {
    return a + b
}
//sampleEnd

fun main() {
    print("sum of 3 and 5 is ")
    println(sum(3, 5))
}
```

- 将表达式作为函数体、返回值类型自动推断的函数

```kotlin
//sampleStart
fun sum(a: Int, b: Int) = a + b
//sampleEnd

fun main() {
    println("sum of 19 and 23 is ${sum(19, 23)}")
}
```

- 

### Lambda 表达式

# 类和面向对象

## 构造函数

## 继承

## 字段与属性

- 声明一个属性的的完整语法是

```kotlin
var <propertyName>[: <PropertyType>] [= <property_initializer>]
    [<getter>]
    [<setter>]
```

- initializer、getter 和 setter 都是可选的
- 自定义 getter 和 setter

```kotlin
var stringRepresentation: String
    get() = this.toString()
    set(value) {
        setDataFromString(value) // 解析字符串并赋值给其他属性
    }
```

- 如果你需要改变一个访问器的可见性或者对其注解，但是不需要改变默认的实现， 你可以定义访问器而不定义其实现

```kotlin
var setterVisibility: String = "abc"
    private set // 此 setter 是私有的并且有默认实现

var setterWithAnnotation: Any? = null
    @Inject set // 用 Inject 注解此 setter
```

### 编译期常量

已知值的属性可以使用 ***const*** 修饰符标记为 *编译期常量*。 这些属性需要满足以下要求：

- 位于顶层或者是 [***object*** 声明](https://hltj.gitbooks.io/kotlin-reference-chinese/content/txt/object-declarations.html#%E5%AF%B9%E8%B1%A1%E5%A3%B0%E6%98%8E) 或 [***companion object***](https://hltj.gitbooks.io/kotlin-reference-chinese/content/txt/object-declarations.html#%E4%BC%B4%E7%94%9F%E5%AF%B9%E8%B1%A1) 的一个成员
- 以 `String` 或原生类型值初始化
- 没有自定义 getter



## 拓展

### 拓展函数

- 声明一个扩展函数，我们需要用一个 *接收者类型* 也就是被扩展的类型来作为他的前缀

```kotlin
// 这个 MutableList 既是接收者类型
fun MutableList<Int>.swap(index1: Int, index2: Int) {
    // this 会代表接收者类型的实例
    val tmp = this[index1] // “this”对应该列表
    this[index1] = this[index2]
    this[index2] = tmp
}

val l = mutableListOf(1, 2, 3)
l.swap(0, 2) // “swap()”内部的“this”得到“l”的值
```

- 拓展是静态解析的，而不是运行时确定值
- 假如拓展函数与成员函数冲突，那么总是会取成员函数
- 拓展函数的接收者可以为空

```kotlin
fun Any?.toString(): String {
    if (this == null) return "null"
    // 空检测之后，“this”会自动转换为非空类型，所以下面的 toString()
    // 解析为 Any 类的成员函数
    return toString()
}
```

### 拓展属性

- 拓展属性没有将成员实际插入类中，所以不能使用 幕后字段，也不能有初始化器，只能提供 getter/setter

```kotlin
val <T> List<T>.lastIndex: Int
    get() = size - 1
```

### 拓展的作用域

- 一般会在顶层定义拓展，也就是 直接在包里

```kotlin
package foo.bar

fun Baz.goo() { …… }
```

- 要使用所定义包之外的拓展，需要在调用方导入



## 数据类

- 使用 data 标记只为传递数据的类, 会自动有以下功能
  - equals / hashCode
  - toStirng
  - componentN
  - copy
- 数据类必须满足以下要求
  - 主构造函数需要至少有一个参数
  - 主构造函数的所有参数需要标记为 `val` 或 `var`；
  - 数据类不能是抽象、开放、密封或者内部的
  - 1.1 以前，数据类只能 实现 接口
- 对于那些自动生成的函数，编译器只使用在主构造函数内部定义的属性。如需在生成的实现中排除某个属性，请将其该属性声明在类体中

### 复制

```kotlin
val jack = User(name = "Jack", age = 1)
// 只改变 年龄属性，其余属性保持一致
val olderJack = jack.copy(age = 2)
```

### Component函数

- 可以使用解构声明

```kotlin
val jane = User("Jane", 35)
val (name, age) = jane
println("$name, $age years of age") // 输出 "Jane, 35 years of age"
```



## 密封类

- 密封类用来表示受限的类继承结构：当一个值为有限集中的类型、而不能有任何其他类型时。在某种意义上，他们是枚举类的扩展：枚举类型的值集合也是受限的，但每个枚举常量只存在一个实例，而密封类的一个子类可以有可包含状态的多个实例。
- 用 sealed 来标记密封类
- 密封类的子类必须在与密封类自身相同的文件中声明
- 一个密封类是自身抽象的，它不能直接实例化并可以有抽象 abstract 成员。
- 使用密封类的关键好处在于使用 when 表达式的时候,如果能够验证语句覆盖了所有情况，就不需要为该语句再添加一个 `else` 子句了

```kotlin
sealed class Expr
data class Const(val number: Double) : Expr()
data class Sum(val e1: Expr, val e2: Expr) : Expr()
object NotANumber : Expr()


fun eval(expr: Expr): Double = when(expr) {
    is Const -> expr.number
    is Sum -> eval(expr.e1) + eval(expr.e2)
    NotANumber -> Double.NaN
    // 不再需要 `else` 子句，因为我们已经覆盖了所有的情况
}
```



## 泛型

### 声明处型变

- 我们可以标注 `Source` 的**类型参数**`T` 来确保它仅从 `Source<T>` 成员中**返回**（生产），并从不被消费。 为此，我们提供 **out** 修饰符

```kotlin
/*
	也即是假如类型被声明为 out, 那么这个 T 就只能用来返回，不能作为参数
*/
interface Source<out T> {
    fun nextT(): T
}

fun demo(strs: Source<String>) {
    /*
    	类似于 Java 的 extends, 此时，取出元素 T 及其子类是安全的
    */
    val objects: Source<Any> = strs // 这个没问题，因为 T 是一个 out-参数
    // ……
}
```

- 另外除了 **out**，Kotlin 又补充了一个型变注释：**in**。它使得一个类型参数**逆变**：只可以被消费而不可以被生产

```kotlin
interface Comparable<in T> {
    operator fun compareTo(other: T): Int
}

fun demo(x: Comparable<Number>) {
    x.compareTo(1.0) // 1.0 拥有类型 Double，它是 Number 的子类型
    // 因此，我们可以将 x 赋给类型为 Comparable <Double> 的变量
    val y: Comparable<Double> = x // OK！
}
```

todo 太复杂，留待以后理解



## 枚举类

- 跟 Java 差不多



### 对象表达式

- 有时候，我们需要创建一个对某个类做了轻微改动的类的对象，而不用为之显式声明新的子类。 Java 用*匿名内部类* 处理这种情况。 Kotlin 用*对象表达式*和*对象声明*对这个概念稍微概括了下。
- 对象表达式需要 继承父类的情况

```kotlin
open class A(x: Int) {
    public open val y: Int = x
}

interface B { …… }

val ab: A = object : A(1), B {
    override val y = 15
}
```

- 对象表达式不需要 继承或实现的情况

```kotlin
fun foo() {
    val adHoc = object {
        var x: Int = 0
        var y: Int = 0
    }
    print(adHoc.x + adHoc.y)
}
```

- 匿名对象可以用作 本地或私有作用域中的声明，假如用做公开函数的返回值或者公开属性的值，那么类型会是超类型，假如没有超类型，就是 Any,其中的成员将无法访问

```kotlin
class C {
    // 私有函数，所以其返回类型是匿名对象类型
    private fun foo() = object {
        val x: String = "x"
    }

    // 公有函数，所以其返回类型是 Any
    fun publicFoo() = object {
        val x: String = "x"
    }

    fun bar() {
        val x1 = foo().x        // 没问题
        val x2 = publicFoo().x  // 错误：未能解析的引用“x”
    }
}
```



## 对象声明

- object 关键字标记，可以用来作为单例模式的实现

```kotlin
object DataProviderManager {
    fun registerDataProvider(provider: DataProvider) {
        // ……
    }

    val allDataProviders: Collection<DataProvider>
        get() = // ……
}
```



## 伴生对象

- 感觉跟静态内部类差不多



## 类型别名

- 类型别名为现有类型提供替代名称。 如果类型名称太长，你可以另外引入较短的名称，并使用新的名称替代原类型名。

```kotlin
typealias NodeSet = Set<Network.Node>

typealias FileTable<K> = MutableMap<K, MutableList<File>>
```



## 内联类

- 实验性质，暂不了解



## 委托

- 由 by 关键字来实现 委托模式

```kotlin
interface Base {
    fun print()
}

class BaseImpl(val x: Int) : Base {
    override fun print() { print(x) }
}

class Derived(b: Base) : Base by b

fun main() {
    val b = BaseImpl(10)
    // 会调用 BaseImpl 的 println() 方法
    Derived(b).print()
}
```

- 可以通过 override 重写委托对象的方法

```kotlin
interface Base {
    fun printMessage()
    fun printMessageLine()
}

class BaseImpl(val x: Int) : Base {
    override fun printMessage() { print(x) }
    override fun printMessageLine() { println(x) }
}

class Derived(b: Base) : Base by b {
    override fun printMessage() { print("abc") }
}

fun main() {
    val b = BaseImpl(10)
    // 这里会输出 abc ，即使用自己的方法
    Derived(b).printMessage()
    Derived(b).printMessageLine()
}
```

- 以这种方式重写的成员不会在委托对象的成员中调用 ，委托对象的成员只能访问其自身对接口成员实现

```kotlin
interface Base {
    val message: String
    fun print()
}

class BaseImpl(val x: Int) : Base {
    override val message = "BaseImpl: x = $x"
    override fun print() { println(message) }
}

class Derived(b: Base) : Base by b {
    // 在 b 的 `print` 实现中不会访问到这个属性
    override val message = "Message of Derived"
}

fun main() {
    val b = BaseImpl(10)
    val derived = Derived(b)
    // 这里 print 会打印 BaseImple 的 message, 因为委托类不会访问被委托的类成员对象
    derived.print()
    println(derived.message)
}
```



## 委托属性



# 函数

- ## 使用 fun 关键字声明

```kotlin
fun double(x: Int): Int {
    return 2 * x
}
```

### 默认参数

- 可以定义参数的默认值，用 =
  - 覆盖方法总是使用与基类型方法相同的默认参数值。 当覆盖一个带有默认参数值的方法时，必须从签名中省略默认参数值
  - 如果一个默认参数在一个无默认值的参数之前，那么该默认值只能通过使用 命名参数 调用该函数来使用：
  - 如果在默认参数之后的最后一个参数是 lambda 表达式，那么它既可以作为命名参数在括号内传入，也可以在括号外传入

```kotlin
fun foo(bar: Int = 0, baz: Int = 1, qux: () -> Unit) { …… }

foo(1) { println("hello") }     // 使用默认值 baz = 1
foo(qux = { println("hello") }) // 使用两个默认值 bar = 0 与 baz = 1
foo { println("hello") }        // 使用两个默认值 bar = 0 与 baz = 1
```

## 命名参数

- 可以在调用函数时使用命名的函数参数。当一个函数有大量的参数或默认参数时这会非常方便
  - 一个函数调用混用位置参数与命名参数时，所有位置参数都要放在第一个命名参数之前。例如，允许调用 `f(1, y = 2)` 但不允许 `f(x = 1, 2)`。
  - 调用 Java 函数时不能使用命名参数语法
- 可以使用 星号操作符将可变数量参数 以命名形式传入

```kotlin
fun foo(vararg strings: String) { …… }

foo(strings = *arrayOf("a", "b", "c"))

```

## 单表达式函数

- 当函数返回单个表达式时，可以省略花括号并且在 = 符号之后知道代码体即可

```kotlin
fun double(x: Int): Int = x * 2
```



## 可变数量的参数 (Varargs)

- 函数的参数 （通常是最后一个） 可以用 vararg 修饰符标记, 允许将可变数量的参数传递给函数

```
fun <T> asList(vararg ts: T): List<T> {
    val result = ArrayList<T>()
    for (t in ts) // ts is an Array
        result.add(t)
    return result
}

val list = asList(1, 2, 3)
```

- 只有一个参数可以被命名为 vararg



## 中缀表示法

- 可以用 infix 关键字标记 让 函数使用 中缀表示,需满足以下条件
  - 必须是成员函数或者拓展函数
  - 必须只有一个参数
  - 其参数不得接受可变数量的参数且不能有默认值

```kotlin
infix fun Int.shl(x: Int): Int { …… }

// 用中缀表示法调用该函数
1 shl 2

// 等同于这样
1.shl(2)
```

- 中缀函数调用的优先级低于算术操作符、类型转换以及 `rangeTo` 操作符
  - `1 shl 2 + 3` 与 `1 shl (2 + 3)`
  - `0 until n * 2` 与 `0 until (n * 2)`
  - `xs union ys as Set<*>` 与 `xs union (ys as Set<*>)`
- 另一方面，中缀函数调用的优先级高于布尔操作符 `&&` 与 `||`、`is-` 与 `in-` 检测以及其他一些操作符。这些表达式也是等价的
  - `a && b xor c` 与 `a && (b xor c)`
  - `a xor b in c` 与 `(a xor b) in c`
- 中缀函数总是要求指定接收者与参数。当使用中缀表示法在当前接收者上调用方法时，需要显式使用 this

```kotlin
class MyStringCollection {
    infix fun add(s: String) { …… }

    fun build() {
        this add "abc"   // 正确
        add("abc")       // 正确
        add "abc"        // 错误：必须指定接收者
    }
}
```



## 函数作用域

- 函数可以在文件顶层声明，也可以在局部作用域声明

## 局部函数

- 一个函数在另一个函数内部
- 局部函数可以访问外部函数的局部变量（闭包）

```kotlin
fun dfs(graph: Graph) {
    val visited = HashSet<Vertex>()
    fun dfs(current: Vertex) {
        if (!visited.add(current)) return
        for (v in current.neighbors)
            dfs(v)
    }

    dfs(graph.vertices[0])
}
```

## 尾递归函数

- 可以用 tailrec 修饰符标记函数，编译器会优化该递归。可以用来写一些尾递归风格的函数

```kotlin
val eps = 1E-10 // "good enough", could be 10^-15

tailrec fun findFixPoint(x: Double = 1.0): Double
        = if (Math.abs(x - Math.cos(x)) < eps) x else findFixPoint(Math.cos(x))
```

- 使用 tailrec 修饰符的话
  - 函数必须将其自身调用作为它指向的最后一个操作
  - 递归调用后有更多代码时，不能使用尾递归
  - 不能用在 try/catch/finally 块中
  - 尾递归只在 JVM 后端中支持



# 高阶函数与 lambda 表达式

## 函数类型



## 函数类型实例化





## 





# 习惯用法

## 创建 DTO

- 可以用 data 关键字，除了 lombok 注解外还提供了 元祖构造器的功能

## 