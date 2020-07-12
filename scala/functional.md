# 一些类的用法

## Future 和 Promise

- 必须显式引入 隐式执行上下文才能正常工作

```scala
import scala.concurrent.ExecutionContext.Implicits.global
```

- Future 代表的是异步计算，因此提供了一些轮询方法

```scala
val fut = Future {Thread.sleep(5000); 21 + 21}
// value 返回的是 Option[Try[T]], 也就是可能会有几种情况
/*
	future 没完成 => None
	future 完成但是异常了 => Some(Failure[Throwable])
	future 正常完成 => Some(Success[T])
*/
println(fut.value)
```

- flap 和 map 的结合可以跟 fot 表达式互换

```scala
val fut1 = Future {Thread.sleep(1000); 21 + 21}
    val fut2 = Future {Thread.sleep(1000); 21 + 21}
    val tt = for {
      x <- fut1
      y <- fut2
    } yield x + y
    /*
    * fut1.flap(x => fut2.map(x + y))
    * */
    Thread.sleep(3000)
    println(tt.value)
```

### 创建Future

- 使用 failed successful fromTry
- 使用 Promise ，代表一个异步执行的结果

```scala
val pro = Promise[Int]
val fut = pro.future
// 完成future
pro.complete(Success(1))
pro.complete(Failure(new RuntimeException))
// 失败future
pro.failure(new RuntimeException("测试异常"))
// 成功future
pro.success(1)
```

### 过滤

- filter
  - true的话返回 Success[T]
  - false 的话返回 Failure(NoSuchElementException)
  - 因为提供了 withFilter 方法，所以可以在 for 表达式中使用
- collect 同时完成校验和变换

```scala
val fut = Future {42}
val valid = fut.collect {case res if res >0 => res + 46 }
```

### 处理失败

- failed : 用于希望某个 future 一定会失败的情况，也就是断言其失败的情况

```scala
// 源码
case Failure(t) => Success(t)
case Success(v) => Failure(new NoSuchElementException("Future.failed not completed with a throwable."))
```

- fallbackTo

```scala
val fut = Future {42 / 0}
val success = Future{ 21 + 21}
// 在 fut调用失败后降级到 success 这个future
val expectedFailure = fut.fallbackTo(success)

// 假如两个future都失败了，那么会显示第一个失败的future的异常
val fut = Future {42 / 0}
val fail = Future.failed(new RuntimeException("测试失败"))
val expectedFailure = fut.fallbackTo(fail)
```

- recover 将失败的 future 转换为 成功的 future

```scala
val fut = Future {42 / 0}

val expectedFailure = fut recover {
	case ex : ArithmeticException => -1
}
// 结果是 Success(-1)
// 假如这里的异常不是 ArithmeticException, 那么就该是啥异常就是啥异常

// 假如没失败就是原样输出
```

- recover, 将失败恢复为一个 future

```scala
val fut = Future {42 / 0}

val expectedFailure = fut recoverWith  {
	case ex : ArithmeticException => Future {32 + 18}
}
```

### 同时映射两种可能

- transForm: 接收两个函数，一个用于处理成功，一个用于处理失败, 这个版本不能将成功和失败进行转换

```scala
val fut = Future {42 / 0}

val expectedFailure = fut transform (res => res * -1, ex => new Exception("see cause", ex))
```

- transForm: 任意修改 future 的成功失败状态和值, 接收一个从 Try 到 Try 的函数

```scala
val fut = Future {42 / 0}

val expectedFailure = fut transform {
  case Success(res) => Failure(new Exception("test"))
  case Failure(ex) => Success(1)
}
```

### 组合

- zip 将两个future 组合为一个future，值是两个future的值的元祖

```scala
val fut = Future {42 / 1}
val fut2 = Future {42 / 2}

val expectedFailure = fut zip fut2
// Success((42, 21))
// 当然，任一个失败都会失败
// 两个都失败的时候，包含第一个的异常
```

- foldLeft 累积一个 TraversableOnce 集合中所有 future 的结果, 并交出一个 future 的结果

```scala
val fut = Future {42 / 1}
val fut2 = Future {42 / 2}
val fut3 = Future {42 / 3}

val expectedFailure = Future.foldLeft(List(fut, fut2, fut3))(0){(acc, num) => acc + num}
//  Success(77)
// 有任何一个失败都算失败，包含最先失败的那个异常
```

- reduceLeft 跟 foldLeft 差不多，不过不带零值
- sequence 将一个 future 的集合变为一个 值组成的future

```scala
val fut = Future {42 / 1}
val fut2 = Future {42 / 2}
val fut3 = Future {42 / 3}

val expectedFailure = Future.sequence(List(fut, fut2, fut3))
// Future(Success(List(42, 21, 14)))
```

- traverse 将 List[T] => 变为 Future[List[T]]

```scala
val expectedFailure = Future.traverse(List(1, 2, 3)){i => Future(i)}
// Future(Success(List(1, 2, 3)))
```

### 执行副作用

- foreach :执行成功后, 执行一个副作用, 也可以使用 for 表达式

```scala
val fut = Future {42 / 1}

fut.foreach(i => println(i))

for (res <- success) println(res)
```

- onComplete : 注册一个成功失败都会执行的回调, 参数是一个 Try， 该回调不会保证执行顺序
- andThen:保证执行完一个future的回调后再去执行, 会返回一个 future, 该方法不会用于继续传递结果，只能用于执行副作用

### 其它方法

- flatten : Future[Future[Int]] => Future[Int]

```scala
val fut = Future {Future {42 / 1}}
val tt = fut.flatten
//Future(Success(42))
```

- zipWith: 将两个 Future zip 一下，然后对结果的元祖进行map

```scala
val f1 = Future { 12 + 12 }
val f2 = Future { "aaa" }
val tt = f1.zipWith(f2) {case (num, str) => s"$num is the $str"}
// Future(Success(24 is the aaa))
```

- transFormWith: 可以用一个从 try 到 future 的函数对 future 进行变换



### 阻塞future

- 可以使用 Await

```scala
import scala.concurrent.duration._

 val f1 = Future { 12 + 12 }
 Await.result(f1, 15.seconds)
```

- 可以使用 futureValue 来阻塞，适合导入 org.scalatest.concurrent.ScalaFutures._

```scala
import org.scalatest.concurrent.ScalaFutures._
fut.futureValue should be (42)
```

- ScalaTest 3.0 之后有了新的测试风格，可以不用等待future阻塞完成



# 函数式的数据结构

- 只能被纯函数操作，纯函数一定不会修改原始数据或产生副作用
- 函数式数据结构被定义为不可变的



# Lift 提升的概念

- 可以将已存在的普通函数包装为函数式的数据结构，而不用去大幅度的修改代码库

```scala
/*
	把一个普通函数的提升为在 Option 上下文进行的函数

*/
def lift[A, B](f: A => B): Option[A] => Option[B] = _ map f
```





# 不使用异常来处理错误

- 使用值的方式返回错误
  - 使用 Option作为返回值来告知是否处理成功
- 一个通用的模式是使用 map flatMap 和 filter 来转换 Option, 最后使用 getOrElse 来处理错误
- 也可以 o.getOrElse(throw new Exception("FAIL"))来让程序失败,针对无法处理的错误

## Option 的组合面向异常的API包装

- 一些有用的函数和参考实现

```scala
object Option {
  /*
  假如有一个 为None，则返回值为None
  否则，在Option的上下文中计算两个值
  */
  def map2[A,B,C](a: Option[A], b: Option[B])(f: (A, B) => C): Option[C] =
    a flatMap (aa => b map (bb => f(aa, bb)))
	
  /*
  将Option列表转为 一个包含列表的Option
  */
  def sequence[A](a: List[Option[A]]): Option[List[A]] =
    a match {
      case Nil => Some(Nil)
      case h :: t => h flatMap (hh => sequence(t) map (hh :: _))
    }
/*
	对一个列表转为 Option 后串成一个包含列表的 Option
*/
  def traverse[A, B](a: List[A])(f: A => Option[B]): Option[List[B]] =
    a match {
      case Nil => Some(Nil)
      case h::t => map2(f(h), traverse(t)(f))(_ :: _)
    }

}
```

- 任何使用 flapMap 和 map 的地方都可以使用 for 推导式互换

```scala
def map2[A,B,C](a: Option[A], b: Option[B])(f: (A, B) => C): Option[C] =
    a flatMap (aa => b map (bb => f(aa, bb)))

def map2[A,B,C](a: Option[A], b: Option[B])(f: (A, B) => C): Option[C] =
	for {
    aa <- a
    bb <- b
  } yield f(aa, bb)
```



## Either 的数据类型

- 可以提供失败情况的信息



# 非严格求值

- 非严格求值是函数的一种属性，称一个函数是非严格求值的意思是这个函数可以选择不对它的一个或多个参数求值
- 严格求值的函数总是对它的参数求值

### scala 中的非严格求值

```scala
/*
 :=> 的写法会让 scala自动创建一个 tunk 来包住值
 也就是 () => onTrue, 使用的时候才会去求值
*/
def if2[A] (cond: Boolean, onTrue: => A, onFalse: => A): A = if (cond) onTrue else onFalse
```

- 可以使用 lazy 关键字来缓存一个计算结果,这样的话值只会被计算一次
  - 可以用于希望某些副作用只出现一次的场合

# 纯函数式状态

- 函数式的状态通常都是在方法调用中传递，因此，状态通常都作为入参和返回值
- 可以利用 type 定义一个类型别名，来表示对状态的封装