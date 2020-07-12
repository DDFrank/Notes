# 函数式的各种写法

## Fold

```scala
object Bus {
  def number(busStops: List[(Int, Int)]): Int =
    busStops.foldLeft(0) { (acc, pair) => acc + pair._1 - pair._2 }
}
```

# 数学题的解法

## N皇后问题

```scala
/*
  * n 是棋盘大小
  *
  * */
  def queens(n: Int): List[List[(Int, Int)]] = {
    /*
    * 以列表形式生成所有长度为 k 的部分解
    * */
    def placeQueens(k: Int): List[List[(Int, Int)]] =
      if (k == 0)
        // 由空列表来表示不放皇后的单个解
        List(List())
      else
        for {
          queens <- placeQueens(k - 1)
          // 所有皇后可能出现的列
          column <- 1 to n
          // 皇后可能出现的位置
          queen = (k, column)
          // 检查是否和已经生成的 queen 有互吃现象
          if isSafe(queen, queens)
          // 将生成的皇后位置加入已存在的皇后位置列表
        } yield queen :: queens

    def isSafe(queen: (Int, Int), queens: List[(Int, Int)]) =
      queens forall (q => !inCheck(queen, q))
    def inCheck(q1: (Int, Int), q2: (Int, Int)) =
      q1._1 == q2._1 || // 同一行
      q1._2 == q2._2 || // 同一列
      (q1._1 - q2._1).abs == (q1._2 - q2._2).abs // 同一斜线

    // 开始生成解
    placeQueens(n)
  }
```

