# Sequence

- 有序
-  可以使用符号进行元素的添加

```scala
val s = Seq(1,2,3)
println(s :+ 4)
println(0 +: s)
```

## List extends Seq

- 单向链表

## Stack extends Seq

## Vector extends Seq

## Queue extends Seq

## Array extends Seq



# Map

- 可以使用 + 号来添加元素

```scala
val m = Map(1 -> "one", 2 -> "two")
println(m + (3 -> "three"))
```

- 可以使用 - 号来减少元素

```scala
val m = Map(1 -> "one", 2 -> "two")
println(m - 1)
```

- mutable 的map可以使用 += 和 -=

## ListMap

- 保证 key 的顺序的Map



# Set



# Range

- 可以使用 to 和 until
- 使用 by 确定步长