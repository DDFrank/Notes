# 基本语法

## For 表达式

- 遍历集合

```scala
for (file <- filesHere)
	println(file)
```

- 过滤: 可以使用多个过滤子句

```scala
for (
	file <- filesHere
  if file.isFile
  if file.getName.endsWith(".scala")
) println(file)

```

- 嵌套迭代

```scala
def grep(pattern: String) =
	for (
  	file <- filesHere
    // 一层嵌套
    if file.getName.endsWith(".scala");
    line <- fileLines(file)
    // 二层嵌套
    if line.trim.matches(pattern)
  ) println(file+ ": " + line.trim)

grep(".*gcd.*")
```

- 中途遍历绑定: 上文中的 line.trim 调用了两遍，可以不用这样

```scala
def grep(pattern: String) = 
	// 使用大括号可以省去部分分号
	for {
    file <- filesHere
    if file.getName.endsWith(".scala")
    line <- fileLines(file)
    // 绑定变量
    trimmed = line.trim
    if trimmed.matches(pattern)
  } println(file + ": " + trimmed)

grep(".*gcd.*")
```

- 产出一个新的集合: 可以在每次迭代的时候产生一个新的值

```scala
// file 的集合
def scalaFiles = 
	for {
    file <- fileHere
    if file.getName.endsWith(".scala")
    // yield 关键字必须出现在整个 代码体之前
  } yield file
```

### For 推导

```scala
for ( seq ) yield expr
/*
seq 是一个序列的生成器，定义和过滤器，以分号隔开
*/

for (
  p <- persons; // 生成器
  n = p.name; // 定义
  if (n startsWith "To") // 过滤器
) yield n

// 生成器
pattern <- expr // expr 通常返回一个列表，列表的元素会被模式匹配
// 定义
pattern = expr
// 过滤器
if expr
```

### For 推导进行查询

- 跟数据库的查询语言类似

### For推导式进行翻译

- 每个 for 表达式都可以用三个高阶函数 map, flatMap 和 withFilter 来表示

```scala
for (x <- expr1) yield expr2 => expr1.map(x => expr2)

for (x <- expr1 if expr2) yield expr3 => for (x <- expr1 withFilter (x => expr2)) yield expr3
=> expr1 withFilter (x => expr2) map (x => expr3)
```

### 让更多类型支持 for 表达式

- 需要实现 map flatMap withFilter 和 foreach 四个方法



## Try 表达式

- 可以抛出异常， throw 是一个表达式，会返回 Nothing

```scala
val half =
	if (n % 2 == 0)
		n/2
	else
	  // 会在 half 初始化之前就抛出
		throw new RuntimeException("n must be even")
```

- catch 子句中可以写模式匹配

```scala
try {
  val f = new FileReader("input.txt")
} catch {
  case ex: FileNotFoundException => // 处理
  case ex: IOException => // 处理
  // 假如不是上述两个异常，那么就会向上抛出
}
```

- 表达式的值

```
def urlFor(path: String) = 
	try {
    new URL(path)
  } catch {
  	// 假如捕获异常，那么就使用这个默认值
    case e: MalformedURIException =>
    	new URL("...")
  }
```

## Match 表达式

- 类似于 switch 的功能, break 是隐含的

```scala
val firstArg = ...
// 也可以得到结果
val friend = firstArg match {
  case "salt" => println("a")
  case "chips" => println("b")
  case "eggs" => println("c")
  case _ => println("huh?")
}
```



## 集合

### List

```scala
// 使用 :: 将元素放到列表前面
val oneTwoThree = 1 :: twoThree

// 可以使用 nil 和 :: 来初始化一个列表
val oneTwoThree = 1 :: 2 :: 3 :: Nil
```





## 提取器

- 提取器是拥有名为 unapply 的成员方法的对象
- unapply 方法的目的是跟某个值做匹配并将它拆解开
- 通常，提取器还会定义一个跟 unapply 相对应的apply方法用于构建值

```scala
object Email {
  // 注入方法，可选， 可以像当做构造函数一样使用
	def apply(user: String, domain: String) = user + "@" + domain
  // 提取方法，必选，将 Email 变为提取器的核心方法
  // 是 apply 构造过程的反转
  def unapply(str: String): Option[(String, String)] = {
    val parts = str split "@"
    if (parts.length == 2) Some(parts(0), parts(1)) else None
  }
}


// 结果就可以这样使用
unapply("John@epfl.ch") equals Some("John", "epfl.ch")
unzpply("John Doe") equals None

// 可以用于模式匹配
selectorString match { case EMail(user. domain) => ...}
```

```scala
// 也可以继承函数类型
// 相当于声明了一个 apply 方法
object EMail extends ((String, String) => String) {...}
```

### 提取0或1个变量的模式

- 提取一个变量的模式

```scala
object Twice {
  def apply(s: String): String = s + s
  def unapply(s: String): Option[String] = {
    val length = s.length / 2
    val half = s.substring(0, length)
    if (half == s.substring(length)) Some(half) else None
  }
}
```

- 提取0个变量的模式

```scala
object UpperCase {
  def unapply(s: String): Boolean = s.toUUpperCase == s
}
```

- 可以嵌套使用

```scala
def userTwiceUpper(s: String) = s match {
  case Email(Twice(x @ UpperCase()), domain) =>
  	"match: " + x + " in domain " + domain
  case _ =>
  	"no match"
}
```



### 提取可变长度参数的模式

```scala
object Domain {
  // 注入方法
  def apply(parts: String*): String = parts.reverse.mkString(".")
  // 提取方法, 专门用于接收变长参数
  // 结果类型必须符合 Option[Seq[T]]的要求
  def unapplySeq(whole: String): Option[Seq[String]] = Some(whole.split("\\.").reverse)
}

// 可以用来嵌套使用
def isTomeInDotCom(s: String): Boolean = s match {
  case EMail("tom", Domain("com", _*)) => true
  case _ => false
}
```

- 也可以从 unapplySeq 返回某些固定的元素再加上可变的部分也是可行的
  - 通过将所有的元素放在元祖里返回来实现的，其中可变的部分出现在元祖的最后一位

```scala
object ExpandedEMail {
  def unapplySeq(email: String) : Option[(String, Seq[String])] = {
   	val parts = email split "@"
    if (parts.length == 2)
    	// 可变的部分放在最后
    	Some(parts(0), parts(1).split("\\.").reverse)
    else
    	None
  }
}
```



# 函数

## 重复参数

```scala
def echo(args: String*) = 
	// 在内部其实就是一个数组
	for (arg <- args) println(arg)
```

- 不能直接传入数组，要加上 _* 符号

```scala
echo(arr: _*)
```



## 命名参数

```scala
def speed(distance: Float, time: Float): ....
speed(time = 10, distance = 100)
```



### 默认参数值

```scala
def printTime(out: java.io.PrintStream = Console.out) = out.println("...")
```

- 可以和命名参数一起使用

## 柯里化

```scala
def withPrintWriter(file: File)(op: PrintWriter => Unit) = {
  val writer = new PrintWriter(file)
  try {
    op(writer)
  } finally {
    writer.close()
  }
}
```

- 当函数只有一个参数时，可以使用 {} 而不是 ()
- 柯里化可以帮助类型推导,类型信息会从左往右推导
- 配合柯里化可以实现类似于 groovy 的 {}



## 传名参数

- 当函数值没有参数时，可以使用传名参数来省略 ()

```scala
def byNameAssert(predicate: => Boolean) = 
	if (assertionEnabled && !predicate)
		throw new AssertionError

// 调用
byNameAssert(5 > 3)
// 而不是
myAssert(() => 5 > 3)
```



## 无参方法

- 无参数方法的调用可以省略括号
- 在惯例上，建议在仅仅把无参方法当做访问属性的时候才省略括号
- 而比如进行IO操作时，仍然把括号加上 (有副作用的方法)



# 对象

## 继承

```scala
package layout

import Element.elem

abstract class Element {
  /**
    * 只要没有实现就是抽象的，无需 abstract 关键字
    *
    * @return 一行字符串
    */
  def contents: Array[String]

  /**
    * 获取长宽
    *
    * @return
    */
  def height: Int = contents.length

  def width: Int = if (height == 0) 0 else contents(0).length

  def above(that: Element): Element =
    // 使用工厂方法来代替 new 关键字
    elem(this.contents ++ that.contents)

  def beside(that: Element): Element = {
    elem(
      for (
        (line1, line2) <- this.contents zip that.contents
      ) yield line1 + line2
    )
  }

  override def toString: String = contents mkString "\n"
}

/**
  * 定义一个伴生对象来提供工厂方法
  */
object Element {

  /**
    * 将子类全部封闭在伴生对象中
    */
  /**
    *
    * @param contents 参数化字段，可以同时作为构造器的参数和类的字段, 同时用字段重写了父类的无参方法
    */
  private class ArrayElement (val contents: Array[String]) extends Element {}
  /**
    *
    * @param s 向超类的构造方法中传入参数
    */
  private class LineElement(s: String) extends Element {
    val contents = Array(s)
    override def width: Int = s.length
    override def height = 1
  }

  private class UniformElement
  (
    ch: Char,
    override val width: Int,
    override val height: Int
  ) extends Element {
    private val line = ch.toString * width

    override def contents: Array[String] = Array.fill(height)(line)
  }

  def elem(contents: Array[String]): Element = new ArrayElement(contents)

  def elem(chr: Char, width: Int, height: Int): Element = new UniformElement(chr, width, height)

  def elem(line: String): Element = new LineElement(line)
}

```

# 特质

- 代码复用的基本单元

- 将方法和字段封装起来，然后通过 混入 的方式来实现复用

- 类可以混入任意数量的接口

- 特质可以做任何类可以做的事情，除了以下两种事不能做

  - 不可以有任何 类参数

  ```scala
  trait NoPoint(x: Int, y:Int) // 这样是不行的
  ```

  - 类中的 super 调用是静态绑定的，而在特质中 super 则是动态绑定的
    - 这个性质是 特质可以实现 stackable modification 的关键
    - 混入多个特质时，调用 super 会依次从左到右，从上到下调用一遍所有的方法



# 断言

## asserting

- 使用 assert(condition) 和 assert(condition, explanation: Any)

```scala
assert(this1.width == that1.width)
```



## ensuring

```scala
private def widen(w:Int): Element = 
if (w <= width)
	this
else {
  ....
  // _ 就是方法的结果
} ensuring (w <= _.width)
```

- 该方法可以被用于任何结果类型,用于确保结果类型



# 测试



# 样例类和模式匹配

## 样例类

```scala
abstract class Expr
/*
* case修饰的就是样例 类
* */
case class Var(name: String) extends Expr
case class Number(num: Double) extends Expr
case class UnOp(operator: String, arg: Expr) extends Expr
case class BinOp(operator: String, left: Expr, right: Expr) extends Expr
```

- 会自动添加一个跟类同名的工厂方法

```scala
val v = Var("x")
```

- 参数类别中的参数当隐式的获得了一个 val, 也就是当做字段来处理
- 编译器会帮助实现 toString hashCode 和 equals 方法
- 添加了 copy 方法用于拷贝
  - 带名字的参数是修改
  - 缺省的参数是被拷贝对象的值
- 样例类最大的用处是用于模式匹配

## 模式匹配

```scala
// 使用 match 关键字
def simplifyTop(expr: Expr): Expr = expr match {
  // 匹配的模式和需要执行的表达式
 	case UnOp("-", UnOp("-", e)) => e
  case BinOp("+", e, Number(0)) => e
  case BinOp("*", e, Number(1)) => e
  // 通配模式
  case _ => expr
}
```

### 模式的种类

- 通配模式

  - 使用 _ 去匹配任何值
  - 也可以使用 _ 来代表某个不关心的局部

  ```scala
  expr match {
    case BinOp(_, _, _) => println(expr + " is a binary operation")
    case _ => println("It's something else")
  }
  ```

- 常量模式

  - 仅匹配自己
  - 任何字面量都可以作为常量模式
  - 任何 val 或单例对象也可以作为常量模式使用

  ```scala
  def describe(x: Any) = x match {
  	case 5 => "five"
    case true => "true"
    // 只能匹配空列表
    case Nil => "the empty Llist"
    case _ => "something"
  }
  ```

- 变量模式

  - 类似于通配模式，但是会将匹配值绑定到对应的变量

  ```scala
  expr match {
  	case 0 => "zero"
    case somethingElse => "not zero " + somethingElse
  }
  ```

  - 大写开头的变量才会被当做常量，小写开头的标识符会被认为是变量
  - 可以给 小写开头的变量 加上 反引号来当做常量

- 构造方法模式

  - 首先检查被匹配的对象是否以是以这个名称命名的样例类的实例
  - 再检查这个对象的构造方法参数是否匹配这些额外给出的模式

- 序列模式

  - 跟样例类匹配类似,比如跟List 或 Array 

  ```scala
  expr match {
  	case List(0, _, _) => println("fount it")
    case _ =>
  }
  ```

  - 想匹配一个序列，但又不想给多长，可以使用 _* 作为模式的最后一个元素

  ```scala
  expr match {
  	case List(0, _*) => println("fount it")
    case _ =>
  }
  ```

  - 元祖模式

  ```scala
  def tupleDemo(expr: Any) =
  	expr match {
      case (a, b, c) => println("matched " + a + b + c)
      case _ =>
    }
  ```

  - 带类型的模式

    - 可以用来替代类型测试和类型转换

    ```scala
    def generalSize(x: Any) = x match {
      case s: String => s.length
      case m: Map[_, _] => m.size
      case _ => -1
    }
    ```

    - 因为运行时类型会被擦除，所以不能对 泛型进行匹配
    - 数组的类型会得到保留，因此，可以对数组进行类型匹配

    ```scala
    def isStringArray(x: Any) = x match {
      case a: Array[String] => "yes"
      case _ => "no"
    }
    ```

  - 变量绑定

    - 可以对任何模式添加变量，用于匹配模式本身

    ```scala
    expr match {
    	case UnOp("abs", e @ UnOp("abs", _)) => e
    }
    ```

    ### 模式守卫

    - 同一个模式变量在模式中只能出现一次

    ```scala
    def simplifyAdd(e: Expr) = e match {
      case BinOp("+", x, x) => BinOp("*", x , Number(2))
      case _ => e
    }
    ```

    - 可以使用模式守卫，对匹配的变量提出要求

    ```scala
    def simplifyAdd(e: Expr) = e match {
      case BinOp("+", x, y) if x == y =>
      	BinOp("*", x, Number(2))
      case _ => e
    }
    ```

  ## 密封类 

  - 将超类标记为 sealed ，那么就不可以在同一个文件之外添加新的子类

  

  ## Option类型

  - 由一个名为 Option 的标准类型来表示可选值
    - Some(x)
    - None
  - 很多集合的库会返回 Option 的类型成员，此时可以使用模式匹配

  ```scala
  def show(x: Option[String]) = x match {
    case Some(s) => s
    case None => "?"
  }
  ```

  

  ## 其它可以使用模式的地方

  - 变量定义中的模式,类似于解构赋值

    - 使用元祖来解开元素并赋值给不同的变量

    ```scala
    val myTuple = (123, "abc")
    val (number, string) = myTuple
    
    val exp = new BinOp("*", Number(5), Number(1))
    val BinOp(op, left, right) = exp
    ```

  - 作为偏函数的序列

    - 用大括号包起来的一系列case，可以当做函数字面量使用

    ```scala
    val withDefault: Option[Int] => Int = {
      case Some(x) => x
      case None => 0
    }
    ```

    - 使用 case 序列得到的是一个偏函数，假如输入了不支持的值，会抛出运行时异常
    - 可以使用 PartialFunction 来指定函数是一个偏函数

    ```scala
    val second: PartialFunction[List[Int], Int] = {
      case x :: y :: _ => y
    }
    ```

    - 可以对 偏函数类型使用 isDefinedAt 来检查对于某个值是否有定义

    ```scala
    second.isDefinedAt(List(5,6,7))
    second.isDefinedAt(List())
    ```

  - for 表达式中的模式

  ```scala
  for ((country, city) <- capitals)
  	println("The capital of" + country + " is " + city)
  ```

  

# 关于列表

## 列表类型

- 列表是协变的
  - 假如 S 是 T的子类型，那么 List[S] 就是 List[T] 的子类型
- 空列表类型是 List[None]

## 构建列表

- 所有的列表都构建于两个基本单元 :Nil 和 ::
  - 空列表
  - 在列表前追加元素
- 所以列表的值也可以定义

```scala
val nums = 1 :: (2 :: (3 :: (4 :: Nil)))
val nums = List(1, 2, 3, 4)
// :: 是右结合的
val nums = 1 :: 2 :: 3 :: 4 :: Nil
```

## 列表的基本操作

- head : 返回第一个元素
- tail : 返回列表中的除第一个元素外的所有元素
- isEmpty ；返回列表是否是空列表

## 列表模式

- 可以使用 List(...) 也可以使用 :: :: :: 来匹配
- 使用模式匹配实现的插入排序

```scala
def issort (xs: List[Int]) : List[Int] = xs match {
  case List() => List()
  case x :: xs1 => insert(x, isort(xs1))
}
def insert(x: Int, xs: List[Int]): List[Int] = xs match {
  case List() => List(x)
  // 检查列表中的第一个元素和待插入元素的关系
  case y :: ys => if (x <= y) x :: xs
  									else y :: insert(x, ys)
}
```

## 列表的初阶方法

- 拼接两个列表 ::: (也是右结合的)

```scala
List(1, 2) ::: List(3, 4, 5)
```



## 列表的高阶方法

- 左折叠 /: 右折叠 \:

```scala
def sum(xs: List[Int]): Int = (0 /: xs) (_ + _)
// (z /: List(a, b, c))(op) => op(op(op(z,a), b), c)
def sum(xs: List[Int]): Int = (xs \: 0)(_ + _)
// (List(a, b, c) :\ z)(op) => op(a, op(b, op(c, z)))
```



# 集合

## 序列

- 用来处理依次排列分组的数据
- 元素是有次序的

### 列表

- 不可变链表
- 支持在头部快速添加和移除条目

### 数组

- 支持随机访问

### 列表缓冲(list buffer)

- 可变对象
- 可以高效的往元素前后追加元素
- += 向后追加元素
- +=: 向前追加元素

### 数组缓冲 (ArrayBuffer)

- 可以额外地从序列头部或尾部添加或移除元素
- 创建时不需要知道长度

### 字符串(StringOps)

- Predef 有一个从 String 到 StringOps 的隐式转换，可以将任何字符串当做序列来处理



## 集合和映射

### Set

- 同一时刻，以 == 为标准，集里的每个对象最多出现一次
- 使用 Set.empty() 方法创建一个空集
- 默认是可变的对象

### 映射

- 可以对某个集的每个元素都关联一个值
- 默认是可变的对象





# 抽象成员

```scala
trait Abstract {
  // 抽象类型
  type T
  // 抽象方法
  def transform(x: T):T
  val initial: T
  var current: T
}

// 实现
class Concrete extends Abstract {
  type T = String
  def transform(x: String) = x + x
  val initial = "hi"
  var current = initial
}
```

## 类型成员

- 用 type 关键字声明为某个类或特质的成员的类型
- 可以给含义不明显或真名很长的类型定义一个短小且描述性强的别名
- 声明子类必须定义的抽象类型

## 抽象的val

- 不知道某个变量正确的值，但是明确地知道在当前类的每个实例中该变量都会有一个不可变更的值时使用
- 任何实现都必须是一个 val 定义
- 子类中的val 定义是在超类初始化之后被求值

### 预初始化字段

- 可以在超类初始化之前初始化子类的字段
- 将字段定义放在超类的构造方法之前的花括号中即可

```scala
trait RationalTrait {
  val numberArg: Int
  val denomArg: Int
}
new {
	val numberArg = 1 * x
  val denomArg = 2 * x
} with RationalTrait
```

- 也可以用在具名类中

```scala
object twoThirds extends {
	val numberArg = 2
  val denomArg = 3
} with RationalTrait

class RationalClass(n: Int, d: Int) extends {
  val numberArg = n
  val denomArg = d
} with RationalTrait {
  def + (that: RationalClass) = new RationalClass (
  	number * that.denom + that.number * denom,
    denom * that.denom
  )
}
```

- 由于预初始化字段在超类的构造方法被调用之前初始化，它们的初始化代码不能引用那个正在被构造的对象
- 假如使用了 this, 那么 this 将指向包含当前构造的类或对象的对象，而不是被构造的对象本身

### 惰性的val

- 可以使用 lazy关键字，这样 val 只会在第一次使用时被求值
- 最好在初始化代码不存在副作用的时候使用，因为这样初始化的顺序就是不重要的

## 抽象的var

- 也会定义抽象的 getter setter

## 抽象类型

```scala
class Food
abstract class Animal {
  // 提供了抽象类型供子类确定传给参数的到底是什么类型
  type SuitableFood <: Food
  def eat(food: SuitableFood)
}

class Grass extends Food
class Cow extends Animal {
  // 子类限定了参数类型
  type SuitableFood = Grass
  override def eat (food: Grass) = {}
}
```

### 路径依赖类型

- 类名 + 类型名称

## 改良类型

- 当一个类从另一个类继承时，将前者称为另一个的名义子类型(nominal)
  - 因为类型的名称被显式的声明为存在子类型关系
- 只要两个类型有兼容的成员，就可以说它们之间存在子类型关系，就是结构子类型(structural)
  - 用改良类型来实现结构子类型 (refinement type)

## 枚举

- 可以使用 路径依赖类型来实现枚举

```scala
object Color extends Enumeration {
  // Value 是 Enumeration 定义的内部类, 构造参数有许多重载，可以用来传值
  val Red, Green, Blue = Value
}

// 可以使用 _ 来全部导入
import Color._

// 使用 values 方法返回的集来遍历
for (d <- Direction.values) print(d + " ")

// 枚举值从 0 开始编号，可以通过枚举值的 id 属性来获取编号，也可以通过编号获取枚举值
Color.Red.id
Color(1)
```



# 隐式转换

- 隐式定义指的是允许编译器插入程序以解决类型错误的定义

## 规则

- 只有被标记为 implicit 的定义才可用
- 可以标记任何变量，函数和对象定义
- 作用域规则: 被插入的隐式转换必须是当前作用域的单个标识符，或者跟隐式转换的源类型或目标类型有关联

```scala
// 这种不会被编译器展开, 因为 someVariable.convert 不是单个标识符
x + y => someVariable.convert(x) + y

// 常见的做法是提供一个包含隐式转换的 Preamble 对象
```

```scala
// 编译器会在隐式转换的源类型或目标类型的伴生对象中查找隐式定义
object Dollar {
  implicit def dollarToEuro(x: Dollar): Euro = ....
}
class Dollar { ... }
```

- 每次一个规则: 每次只能有一个隐式定义被插入

```scala
// 这不会发生
x + y => convert1(convert2(x)) + y
```

- 显式优先原则: 如果代码按编写的样子能通过类型检查，就不会去尝试隐式定义
- 隐式转换可以用任何名称

## 三种常用的场景

### 隐式转换到一个预期的类型

- 当编译器看见一个 x 但是它需要一个 y 的时候，就会去查找能将 x 转换为 y 的隐式转换

### 转换接收端

- 可以用于方法被调用的对象， 也就是方法调用的接收者

  - 可以更平滑地将新类集成到已有的类继承关系图谱中

  ```scala
  // 已有类
  class Rational(n: Int, d: Int) {
    ...
    def + (that: Rational): Rational = ...
    def + (that: Int): Rational = ...
  }
  
  // 定义一个隐式转换
  implicit def intToRational(x: Int) = new Rational(x, 1)
  // 之后就可以调用 1 + Rational 了
  ```

  

  - 支持在语言中编写DSL

  ```scala
  // map 中的构造方法即使用了这个特性
  Map(1 -> "one", 2 -> "two", 3 -> "three")
  // 将 键 转换为 ArrowAssoc
  package scala
  object Predef {
    class ArrowAssoc[A](x: A) {
   		def -> [B](y: B): Tuple2[A, B] = Tuple2(x, y)   
    }
    implicit def any2ArrowAssoc[A](x: A): ArrowAssoc[A] = new ArrowAssoc(x)
    ///
  }
  ```

### 隐式类

- 为了简化富包装类而出现，特征是以 implicit 关键字打头的类
- 对于这样的类，编译器会生成一个从类的构造方法参数到类本身的隐式转换

```scala
case class Rectangle(width: Int, height: Int)
// 隐式类, 不能是样例类，构造方法有且仅有一个参数
// 隐式类必须存在于另一个对象，类或特质里面
implicit class RectangleMaker(width: Int) {
  def x (height: Int) = Rectangle(width, height)
}

// 会自动生成隐式转换
implicit def RectangleMaker(width: Int) = new RectangleMaker(width)

// 那么就可以这样调用
val myRectangle = 3 x 4
```

## 隐式参数

- 会在参数列表中插入隐式定义, 通过追加一个参数的方式来完成某个函数调用

```scala
someCall(a) => someCall(a)(b)
```

- 提供的是整个最后一组柯里化的参数列表，而不仅仅是最后一个参数

```scala
// b, c,d 必须被标记为 implicit, someCall 的最后一个参数列表也得表示为implicit
someCall(a) => someCall(a)(b,c,d)
```

- 隐式参数通常会选择一些 稀有或者独特的类型，避免意外的匹配
- 隐式参数最常用的场景是提供关于更靠前的参数列表中已经显式地提到的类型的信息，类似于 Haskell 的 type class

```scala
def maxListImpParm[T](elements: List[T])
	// 将第二个参数定义为隐式的, 这样一些通用的排序 String Int 就不用传递参数了
	// 这里补充了第一个参数类别中 T 的类型信息
	(implicit ordering: Ordering[T]) : T = 
	elements match {
    case List() =>
    	throw new IllegalArgumentException("empty list!")
    case List(x) => x
    case x :: rest =>
     // 由于编译器把 ordering参数当做隐式定义了，这里的 ordering 也可以省略
    	val maxRest = maxListImpParm(rest)(ordering)
    	if (ordering.gt(x, maxRest)) x
    	else maxRest
  }
```

- 在给隐式参数的类型命名时，至少使用一个能确定其职能的名字，而不是使用过于泛化的类型

## 上下文界定

- 标准库中有这么一个方法

```scala
/*
调用时，编译器会去查找一个类型为 T 的隐式类型，然后使用它来调用 implicitly 方法，返回该对象
这方法可以用来在想要当前作用域找到类型为Foo的隐式对象时直接写 implicitly[Foo]
*/
def implicitly[T](implicit t: T) = t
```

```scala
def maxListImpParm[T](elements: List[T])
	(implicit ordering: Ordering[T]) : T = 
	elements match {
    case List() =>
    	throw new IllegalArgumentException("empty list!")
    case List(x) => x
    case x :: rest =>
    // 插入了隐式参数 ordering
    	val maxRest = maxListImpParm(rest)
    	// 这里就完全消除了 ordering的使用
    	if (implicitly[Ordering[T]].gt(x, maxRest)) x
    	else maxRest
  }
```

- 由于 ordering 参数的名称被省掉了，所以方法最后可以被定义为

```scala
// 指明 T 的类型 Ordering
def maxListImpParm[T : Ordering](elements: List[T]): T = 
	elements match {
    case List() =>
    	throw new IllegalArgumentException("empty list!")
    case List(x) => x
    case x :: rest =>
	    // 插入了隐式参数 ordering
    	val maxRest = maxListImpParm(rest)
    	// 这里就完全消除了 ordering的使用
    	if (implicitly[Ordering[T]].gt(x, maxRest)) x
    	else maxRest
  }
```

- 当有多个类型转换可选时，会检查哪个转换更严格
  - 前者的入参类型是后者入参类型的子类型
  - 两者都是方法，而前者所在的类拓展自后者所在的类
  - 满足的话，就说明前者的隐式转换更加具体





# 注解

- 可以用在各种声明或定义上, 包括 val,var,def,class,object,trait 和 type
- 注解也可以用在表达式上

```scala
(e: @unchecked) match {
  // ....
}
```

- 注解也可以有入参, 支持任意的表达式，也可以引用当前作用域内的其它变量

```scala
@cool val normal = "Hello"
@coolerThan(normal) val fonzy = "Heeyyy"
```

- scala 内部仅仅只是将注解表示为对某个注解类的构造方法的调用
- 假如要把注解作为另一个注解的入参，那么就需要 new

```scala
// 无效
@strategy(@delayed) def f() = {}
// 有效
@strategy(new delayed) def f() = {}
```



## 标准注解

- deprecated : 过时
- valatile: 跟 java 的差不多
- tralirec：标注该方法需要尾递归优化
- unchecked: 不进行检查



## Variance

### Invariant

- Foo[T] 中的 T 是 Invariant, 那么 Foo[A] 和 Foo[B] 之间并没有任何关系

### covariant

- Foo[+T] 的 T是 covariant, 那么 如果 A 是 B 的子类, Foo[A] 也是 Foo[B] 的子类

- 大多数 scala的集合都使用 covariant

### contravariant

- Foo[-T] 的 T 是 contravariant，那么，假如 A 是 B 的超类，Foo[A] 就是 Foo[B] 的子类
- contravariant只会用于函数签名



### 函数的可变性

```scala
case class Box[A](value: A) {
  /**
    * 思考一下map能接收的func的类型
    * A => B 是肯定可以的
    * A => B 的子类是可以的，因为 B的子类肯定有B的全部能力
    * A的超类 => B 也是可以的, 因为这个函数需要A的超类，那么把 A传进去肯定能满足这个函数
    * A的子类 => B 是不行的, 因为 A 可能没有这个子类的能力，所以满足不了这个函数
    *
    * @param func
    * @tparam B
    * @return
    */
  def map[B](func: Function1[A, B]): Box[B] =
    Box(func(value))
}
```

### Contravariant Position

```scala
case class Box[+A](value: A) {
  def set(a: A): Box[A] = Box(a)
}
// 这样写会报编译警报
/*
covariant type A occurs in contravariant position in type A of value a
  def set(a: A): Box[A] = Box(a)
          ^
          A 是 covariant 的，但是 set 的入参是以一个 contravariant 的位置，
          所以报出警告
*/
```

- 解决方案

```scala
case class OtherBox[+A](value: A) {
  /**
    * A 是 covariant的
    * 那么 可能会有 A 的子类型存在
    * set 方法不能接收 A 的子类型
    * 所以要引入一个A的超类型的AA作为参数
    *
    * @param a
    * @tparam AA AA 是 A的超类型
    * @return
    */
  def set[AA >: A](a: AA): Box[AA] = Box(a)
}
```

```scala
case class A[+T]() {
  def f[TT >: T](t: TT): A[TT] = ???
}
```

### Type Bounds

- A <: Type ： A 必须是Type的子类
- A >: Type： A 必须是Type的父类

# 