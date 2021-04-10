# Type

## Semigroup

### 定义

```scala
trait Semigroup[A] {
  def combine(x: A, y: A): A
}

// 符号
1 |+| 2
```

### rule

```scala
combine(x, combine(y, z)) = combine(combine(x, y), z)
```

### 缺陷

- 没有提供对数据类型的默认值

### 使用

- 可以用来对数据进行聚合,类似于merge两个东西

## Monoid

### 定义

```scala
trait Semigroup[A] {
  def combine(x: A, y: A): A
}

trait Monoid[A] extends Semigroup[A] {
  // 拓展了 Semigroup, 提供了一个空值
  def empty: A
}
```

### 使用

- 对于某些只实现了 semigroup的数据类型，可以将其提升到 Option ，来进入 monoid 的context， None 就是 empty

```scala
import cats.implicits._

implicit def optionMonoid[A: Semigroup]: Monoid[Option[A]] = new Monoid[Option[A]] {
  // 使用 None 作为空值
  def empty: Option[A] = None

  def combine(x: Option[A], y: Option[A]): Option[A] =
    x match {
      // 结合的使用，直接覆盖None
      case None => y
      // 正常的结合
      case Some(xv) =>
        y match {
          case None => x
          case Some(yv) => Some(xv |+| yv)
        }
    }
}

// 所以对于所有的 Semigroup[A], 都有一个对应的 Monoid[Option[A]]
```



## Functor

### 定义

```scala
trait Functor[F[_]] {
  // 变换
  def map[A, B](fa: F[A])(f: A => B): F[B]
  
  // 将某个普通值提升到 F 
  def lift[A, B](f: A => B): F[A] => F[B] =
    fa => map(fa)(f)
}

// Example implementation for Option
implicit val functorForOption: Functor[Option] = new Functor[Option] {
  def map[A, B](fa: Option[A])(f: A => B): Option[B] = fa match {
    case None    => None
    case Some(a) => Some(f(a))
  }
}
```

### rule

```scala
fa.map(f).map(g) = fa.map(f.andThen(g))
fa.map(x => x) = fa
```

### 使用

- functor 提供了在不离开 F 上下文的前提下变换数据的能力,
- 对于嵌套数据的处理, 比如List [Either[String, Future[A]]], 可以使用 Functor的compose

```scala
val listOption = List(Some(1), None, Some(2))
// listOption: List[Option[Int]] = List(Some(1), None, Some(2))

// Through Functor#compose
Functor[List].compose[Option].map(listOption)(_ + 1)
// res1: List[Option[Int]] = List(Some(2), None, Some(3))
```

- 对于更复杂的处理，可以使用NestedData，只是有box的性能开销

```scala
val nested: Nested[List, Option, Int] = Nested(listOption)
nested.map(_ + 1)
```



## Applicative

### 定义

```scala
trait Applicative[F[_]] extends Functor[F] {
  // 自己的方法
  def ap[A, B](ff: F[A => B])(fa: F[A]): F[B]

  // 将一个值包装到上下文中
  def pure[A](a: A): F[A]

  def map[A, B](fa: F[A])(f: A => B): F[B] = ap(pure(f))(fa)
}
```

### 使用

- 可以与多个独立的 effect 工作

```scala
import cats.Applicative
// 指定了effect是 Applicative, 
def product3[F[_]: Applicative, A, B, C](fa: F[A], fb: F[B], fc: F[C]): F[(A, B, C)] = {
  val F = Applicative[F]
  val fabc = F.product(F.product(fa, fb), fc)
  F.map(fabc) { case ((a, b), c) => (a, b, c) }
}
```

