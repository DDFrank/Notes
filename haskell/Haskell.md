# GHCI

- 启动

```shell
stack ghci
```

- let : 用于定义 name

```shell
let lostNumbers = [1,2,3,4,5]
```

- :t 显示表达式的类型
- :m 导入模块

```shell
:m + Data.List
```

- 加载 模块

```shell
:add Person
```

- 查看 typeclass 的 instances

```shell
:info typeclass
```

- 使用 :{:} 来输入多行代码

```
:{
Prelude Control.Monad Control.Monad.Writer| 1/2 +
Prelude Control.Monad Control.Monad.Writer| 1/3 
Prelude Control.Monad Control.Monad.Writer| :}
0.8333333333333333
```

# Stack



# 基本语法

## 常见类型

### Int

- 有取值范围

### Integer

- 无取值范围, 所以可以用来代表极大的数字,但是性能会略有损失

### Float

### Double

### Bool

### Char

- 使用 '' 来表示 
- 使用 '\\{来表示}' 或者 '\\x{十六进制数字}'

  ```haskell
'\97' '\x61' 'a'
  ```



## Type class

```haskell
:t (==)
(==) :: (Eq a) => a -> a -> Bool
```

-  => 左边表示一个 Type class
- a 必须是 Eq class 的成员 (class constraint)

### 一些基本的 Type class

#### Eq

- 用于检测相等性
- 其成员均实现了 == 和 /= 方法
- 对于一个 type 来说， constructor 定义在前面的会小于定义在后面的, constructor 相等的时候去比较字段

```haskell
class Eq a where
	(==), (/=) :: a -> a -> Bool
	x /= y = not (x == y)
	x == y = not (x /= y)
```



#### Ord

- 用于比较大小
- 其成员实现了 < < >= <=

```haskell
calss Eq a => Ord a where
	compare :: a -> a -> Ordering
	(<), (<=), (>), (>=) :: a -> a -> Bool
	max, min :: a -> a -> -> a
	
	compare x y = if x == y then EQ
									else if x <= y then LT
									else GT
	
	x < y = case compare of  { LT -> True; _ -> False}
	x <= y = case compare of  { GT -> False; _ -> True}
	x > y = case compare of  { GT -> True; _ -> False}
  x >= y = case compare of  { LT -> False; _ -> True}
  
  max x y = if x <= y then y else x
  min x y = if x <= y then x else y
```



```haskell
"Arbrakadabra" `compare` "Zebra"
LT
```

#### Show

- 可以转换为String
- 其成员实现了 show 方法

```haskell
show 3
"3"
```

#### Read

- 跟 Show 相反，读取一个 String, 返回其类型化的值
- 实现了 read 方法

```haskell
read "True" || False
True
read "8.2" + 3.8
-- 无法推断的时候必须显式指定类型
read "5" :: Int
```

#### Enum

- 让某个类型可以被枚举，主要用于 list ranges
- 可以使用 succ 和 pred 方法

```haskell
['a'..'e']
[LT..GT]
succ 'B'
'C'
```

#### Bounded

- 规定上下界

```haskell
minBound::Int
-2147483648
maxBound: Bool
True
```

#### Num

- 成员会具有算式特性
- 其成员必须也是 Show 和 Eq 的成员

#### Integral

- 只有 Int 和 Integer

#### Floating

- 只有 Float, Double

### RandomGen

- 能表现出随机性

### Random

- 可以接收一个随机值

### Fractional 

- 表示分数

## 高级Typeclass

### Functor

```haskell
-- f 是一个 type constructor
class Functor f where  
		-- 接收一个 function 和 一个 functor 产生另一个 functor
    fmap :: (a -> b) -> f a -> f b  
```

- List 是 Functor 的一个成员

```haskell
-- 因为上文说了 f 是 type constrcutor, 所以这里必须写 [] 不能写 [a] 之类的
instance Functor [] where  
    fmap = map 
```

- Maybe 也是 Functor 的一个成员

```haskell
instance Functor Maybe where  
		-- 直接将 f 应用在 Just 包装的 concrete type 上
    fmap f (Just x) = Just (f x)  
    fmap f Nothing = Nothing 
```

- 用 Functor 来实现 Tree

```haskell
instance Functor Tree where
fmap f EmptyTree = EmptyTree
-- Node 是一个 type constructor, 定义是 Node a (Tree a) (Tree a)
-- 左边的括号使用了 pattern match ，取出了一个节点和其左右两边的tree
-- 这里就是分别对 Node x 使用 f, 对 左右节点分别递归使用 调用 fmap
fmap f (Node x leftsub rightsub) = Node (f x) (fmap f leftsub) (fmap f rightsub)

```

````haskell
-- 对 列表使用 foldr 构造了 Tree
-- 然后对每个节点都使用了 (*4)
-- 因为最先构造的是 7 这个节点，所以打印的时候 它也会在最前面
fmap (*4) (foldr treeInsert EmptyTree [5,7,3,2,1,7])
````

- Either 有两个 type constructor, 所以需要先 applied 一下才能成为 Functor 的成员

```haskell
-- 这里 a 已经固定了
instance Functor (Either a) where
	-- 只对右边进行变换
	fmap f (Right x) = Right (f x)
	-- 因为只能接收一个 type parameter ,所以不能对左边进行处理
	fmap f (Left x) = Left x
```

- IO

```haskell
instance Functor IO where
	fmap f action = do
		result <- action
		-- 将 IO 产生的结果作为参数, 并产生一个新的 IO Action 作为结果
		return (f result)
```

```haskell
main = do line <- getLine
	let line' = reverse line
	
-- 用 fmap 改写就是
main = do linet <- fmap reverse getLine

```

```haskell
import Data.Char
import Data.List

main = do 
  -- 将获取都的用户输入转为大写, 反序，并插入字符 -
  line <- fmap (intersperse '-' . reverse . map toUpper) getLine
  putStrLn line
```

- (->) r ： 就是 r -> a 只应用一个 type parameter 的写法

```haskell
instance Functor ((->) r) where
	fmap f g = (\x -> f (g x))
```

```haskell
fmap :: (a -> b) -> f a -> f b
-- 将 f 替换为 (->) r 后
fmap :: (a -> b) -> ((->) r a) -> ((->) r b)
-- 进一步改为 infix 写法后
fmap :: (a -> b) -> (r -> a) -> (r -> b)
-- 整个其实就是 function composition 的定义,所以可以缩写为
instance Functor ((->) r) where
	fmap = (.)
```

```haskell
:t fmap
fmap :: Functor f => (a -> b) -> f a -> f b

:t replicate 3
replicate 3 :: a -> [a]
-- replicate 3 正好填满了 a -> b 这个参数
:t fmap . replicate $ 3
fmap . replicate $ 3 :: Functor f => f a -> f [a]
-- 实际求值时， [1,2,3,4] 相当于是 a
-- replicate 3 相当于是 f a
-- 所以就是 对 [1,2,3,4] 用了 replicate 3, 就变成这样了
fmap (replicate 3) [1,2,3,4]
[[1,1,1],[2,2,2],[3,3,3],[4,4,4]]
```

- 成为 functor 的两个必须遵守的条件

  - 假如要 map id function ，那么返回的 functor 必须跟原来的一样

  ```haskell
  fmap id (Just 3)
  id (Just 3) 
  -- 两个的结果必须相等
  ```

  - fmap (f . g) = fmap f . fmap g 
    - 也可以写为 fmap (f . g) F = fmap f (fmap g F) (F 是任意 Functor)

  ```haskell
  -- 接下来验证 Myabe 是符合这条的
  -- 因为 Nothing 接收什么都是 Nothing ，所以 Nothing 的 情况非常好验证
  fmap (f . g) (Just x) <=> Just ((f . g) x) <=> Just (f (g x))
  fmap f (fmap g (Just x)) <=> fmap f (Just (g x)) <=> Just (f (g x))
  -- 所以二者是相等的
  ```

### Applicative 

```haskell
-- 必须首先是 Functor 的成员
class (Functor f) => Applicative f where
	-- 均没有默认实现
	pure :: a -> f a
	-- 类似于增强的 fmap
	-- 接受一个 functor (内部有一个 function), 和一个 functor ，然后产生另一个 functor
	(<*>) :: f (a -> b) -> f a -> f b
```

- Maybe 是其成员

```haskell
instance Applicative Mqybe where
  -- 把 pure x = Just x 的参数省略了
	pure = Just
	-- Nothing 中没有内容，所以直接返回 Nothing 即可
	Nothing <*> _ = Nothing
	-- 取出第一个 Just 中的 functor ，然后直接使用 fmap 的定义即可
	(Just f) <*> something = fmap f something
```

```haskell
Just (+3) <*> Just 9
Just 12
Just (++ "haha") <*> Nothing
Nothing
```

```haskell
pure (+) <*> Just 3 <*> Just 5
Just 8
pure (+) <*> Just 3 <*> Nothing
Nothing
```

- pure f <*> x 是等价于 fmap f x 的 (这里的 f 是一个 function)

```haskell
-- (大概是这样) 
pure f <*> x <=> f (a -> b) <*> x <=> (a->b) -> f a <=> fmap f x 
```

- 基于上述，Control.Applicative 提供了一个 function <$> 作为 fmap 的 infix 调用

```haskell
-- 跟 fmap 的定义一样 
(<$>) :: (Functor f) => (a -> b) -> f a -> f b 
f <$> x = fmap f x
```

```haskell
-- 普通的函数调用
(++) "johntra" "volta"
"johntravolta"
-- functor 的连续调用
(++) <$> Just "johntra" <*> Just "volta"
Just "johntravolta"
```

- list 也是 applicative functor

```haskell
instance Applicative [] where
	-- [] 本身就是一个 functor
	pure x = [x]
	-- 两个 list 两两调用
	fs <*> xs = [f x | f <- fs, x <- xs]
```

```haskell
[(+),(*)] <*> [1,2] <*> [3,4]
[4,5,5,6,3,4,6,8]
```

​	- 使用 applicative style 来代替 类别推导式 通常是一个好的习惯

- IO 也是 Applicative 的一个成员

```haskell
instance Applicative IO where
	-- 直接将结果包在 return 中
	pure = return
	-- 
	a <*> b = do 
	  -- 执行第一个 IO Action 去得到 function
		f <- a
		-- 执行第二个 IO Action 去得到 value
		x <- b
		-- 将 调用作为结果包装在 IO Action 中
		return (f x)
```

```haskell
myAction :: IO String
myAction = (++) <$> getLine <*> getLine

-- 等价于
myAction = do
	a <- getLine
	b <- getLine
	return $ a ++ b

-- 这个结果是一个 IO String ,所以也可以和其它 IO Action 结合在一起
main = do
	a <- (++) <$> getLine <*> getLine
	putStrLn $ "The two lines concatenated turn out to be: " ++ a
```

- (-> r) 也是 Applicative 的成员

```haskell
instance Applicative ((->) r) where
  -- 无论参数是什么都返回该值
	pure x = (\_ -> x)
	-- 对于传入的变量 x 会调用 g x 求值， 然后调用 将 x 和 g x 的值 传给 f 
	f <*> g = \x -> f x (g x)	
```

```haskell
-- 相当于这样调用 (+) (+ 5 3) (* 5 100)
-- (+) <$> (+3) 相当于 (+) . (+3)
(+) <$> (+3) <*> (*100) $ 5
508

(\x y z -> [x, y, z]) <$> (+3) <*> (*2) <*> (/2) $ 5
[8.0,10.0,2.5]
```

	- 这种写法不常用

- ZipList  也是 Applicative 的成员，在 Control.Applicative 包下
  - ZipList 只有一个 field, 接收一个 list

```haskell
instance Applicative ZipList where
  -- 会产生一个无限的 list
	pure x = ZipList (repeat x)
	-- 用 fs 的第一个 f 调用 xs 的第一个 x ，第二个 f 调用 xs 的第二个 x, 依次类推
	ZipList fs <*> ZipList xs = ZipList (zipWith (\f x -> f x) fs xs)
```

	- zipList 不是show 的成员，所以要用 getZipList 取出其中的list

```haskell
getZipList $ (+) <$> ZipList [1,2,3] <*> ZipList [100,100,100]
[101,102,103]
```

- liftA2

```haskell
:t liftA2
liftA2 :: Applicative f => (a -> b -> c) -> f a -> f b -> f c
-- 相当于
(a -> b -> c) -> (f a -> f b -> f c)
```

​	- 相当于 lift 多了一次

```haskell
sequenceA :: (Applicative f) => [f a] -> f [a]
-- 将多个 包含 list 的 f 连成一个 f 包含了所有值的 list
sequenceA = foldr (liftA2 (:)) (pure [])
```

```haskell
sequence [Just 3, Just 2, Just 1]
Just [3, 2, 1]
-- 假如是一堆 function ,那么最后会产生一个分别对参数应用每个 function 产生的list
sequenceA [(+3), (*2)] 3
[6,6]
```

```haskell
-- 给定 lambda 的谓词判断
and $ map (\f -> f 7) [(>4), (<10), odd]
True

-- sequenceA 的实现
and sequenceA [(>4), (<10), odd] 7
```

- Applicative functors  laws

  ```haskell
  pure f <*> x = famp f x
  pure id <*> v = v
  pure (.) <*> u <*> v <*> w = u <*> (v <*> w)
  pure f <*> pure x = pure (f x)
  u <*> pure y = pure ($ y) <*> u
  ```

### Monoid

- 在 Data.Monoid 包下

```haskell
-- 只接收 concrete type 作为其成员
class Monoid m where
  -- 只是一个常量
	mempty :: m
	-- 只是一个 二分函数
	mappend :: m -> m -> m
	mconcat :: [m] -> m
	mconcat = foldr mappend mempty
```

- monoid laws

```haskell
mempty `mappend` x = x
x `mappend` mempty = x
(x `mappend` y) `mappend` z = x `mappend` (y `mappend` z)
```

- list 是 monoids 的成员

```haskell
-- 因为 monoid 要求一个 concrete type 所以写成 [a] 而不是 []
instance Monoid [a] where
	mempty = []
	mappend = (++)
```

- 数字类型 在 + 和 * 号上都是 monoid 的，所以Data.Monoid 模块导出了 Product 和 Sum type 来让其成为 Monid 的成员

```haskell
-- 包装 一般 type 是不指定类型的
newtype Product a = Product { getProduct :: a }
	deriving (Eq, Ord, Read, Show, Bounded)
	
--  * 的情况, 在此处指明类型
instance Num a => Monoid (Product a) where
	mempty = Product 1
	Product x `mappend` Product y = Product (x * y)
```

```haskell
-- 这里 $ 符号是必须的，原因没搞懂
getProduct . mconcat . map Product $ [3,4,2]
24
```

	- Sum 的定义方式差不多

- Any 和 All

```haskell
newtype Any = Any { getAny :: Bool }
deriving (Eq, Ord, Read, Show, Bounded)

instance Monoid Any where
	mempty = Any False
	Any x `mappend` Any y = Any (x || y)
```

```haskell
getAny . mconcat . map Any $ [False, False, False, True]
True
```

```haskell
newtype All = All { getAll :: Bool }
	deriving (Eq, Ord, Read, Show, Bounded)
	
instance Monoid All where
	mempty = All true
	All x `mappend` All y = All (x && y)
```

```
getAll . mconcat . map All $ [True, True, True]
```

- Ordering 也是 Monoid 的成员

```haskell
instance Monoid Ordering where
	mempty = EQ
	LT `mappend` _ = LT
	EQ `mappend` y = y
	GT `mappend` _ = GT
```

- Maybe 也是 monoid 的成员

```haskell
-- Maybe 中必须也是 monoid 的成员
instance Monoid a => Monoid (Maybe a) where
	mempty = Nothing
	Nothing `mappend` m = m
	m `mappend` Nothing = m
	Just m1 `mappend` Just m2 = Just (m1 `mappend` m2)
```

- First, 在 不知道是否双方都是 monoid 的时候使用 （弥补 Maybe 的缺陷）

```haskell
newtype First a = First { getFirst :: Maybe a }
	deriving (Eq, Ord, Read, Show)
	
instance Monoid (First a) where
	mempty = First Nothing
	First (Just x) `mappend` _ = First (Just x)
	First Nothing `mappend` x = x
```

```haskell
-- 在一堆 First 中检查是否有一个 Just
getFirst . mconcat . map First $ [Nothing, Just 9, Just 10]
Just 9
```

- 还提供了一个 Last, 会保留住最后一个 非空的 Just

```haskell
getLast . mconcat . map Last $ [Nothing, Just 9, Just 10]
Just 10
```

### Foldable

```haskell
class Foldable t where
	foldMap :: Monoid m => (a -> m) -> t a -> m
	foldr :: (a -> b -> b) -> b -> t a -> b
	-- 直接结合装满了 monoid 的容器
	fold :: Monoid m => t m -> m
	foldr' :: (a -> b -> b) -> b -> t a -> b
	foldl :: (a -> b -> a) -> a -> t b -> a
	foldl' :: (a -> b -> a) -> a -> t b -> a
	foldr1 :: (a -> a -> a) -> t a -> a
	foldl1 :: (a -> a -> a) -> t a -> a
```



```haskell
import qualified Data.Foldable as F
```

```haskell
:t foldr
-- 只针对 list
foldr :: (a -> b -> b) -> b -> [a] -> b

:t F.foldr
-- 接收任意类型而不只是list
F.foldr :: Foldable t => (a -> b -> b) -> b -> t a -> b
```

```haskell
F.foldl (+) 2 (Just 9)
11
Prelude F> F.foldr (||) False (Just True)
True
```

- 实现 foldMap 来称为 Foldable 的成员

```haskell
-- (a -> m) : 接受一个 foldable 的结构包含的值并返回一个 monoid
-- t a : 可 foldable 的结构包含的值
foldMap :: (Monoid m, Foldable t) => (a -> m) -> t a -> m
```

```haskell
instance F.Foldable Tree where
  -- 假如只有 empty ，那么返回 mempty 即可
	foldMap f Empty = mempty
	-- 利用 `mappend` 将 左边的书，中间的节点和右边树三者合并为一个 monoid
	foldMap f (Node x l r) = F.foldMap f l `mappend`
													 	 f x `mappend`
													 	 F.foldMap f r
```

```haskell
-- 把所有节点的数字加起来
F.foldl (+) 0 testTree
42
```

```haskell
-- Any $ x == 3 是一个 function, 接收一个 number 返回一个 包含了 Bool 值的 Monoid (Any)
getAny $ F.foldMap (\x -> Any $ x == 3) testTree
True
```



### Monad

```haskell
-- 虽然没有 class constraint 但是其实每个 Monad 都是一个 Applicative
class Monad m where
	{-
		跟 pure 是一样的
		接收一个值，然后将其包装在 monad 中
		IO 中经常出现的 return 就是它
	-}
	return :: a -> m a
	{-
		类似于 $
		接收一个 monadic value
		将它喂给 接收 normal value 的 function
		然后返回一个 monadic value
	-}
	(>>=) :: m a -> (a -> m b) -> m b
	{-
		大部分时候不会重写这个实现

	-}
	(>>) :: m a -> m b -> m b
	x >> y = x >>= \_ -> y
	{-
		基本不会在代码中显式调用
		haskell 会在某些 syntactic 结构中使用它来表达失败
	-}
	fail :: String -> m a
	fail msg = error msg
```

- Maybe 是 Monad 的成员

```haskell
instance Monad Maybe where
	{-
		跟 pure 的一样
	-}
	return x = Just x
	{-
		假如是 Just 那么就对其内部的值应用 f 即可
	-}
	Nothing >>= f = Nothing
	Just x >>= f = f x
	fail _ = Nothing
```

```haskell
return "What" :: Maybe String
Just "What"

Just 9 >>= \x -> return (x*10)
Just 90

Nothing >>= \x -> return (x*10)
Nothing
```

- 左右落鸟的问题

```haskell
-- 鸟的数量
type Birds = Int
-- 左右和右边的鸟的数量
type Pole = (Birds, Birds)

{-
  鸟落到左边或者右边
  检查左右是否不平衡，不平衡的话要失败
-}
landLeft :: Birds -> Pole -> Maybe Pole
landLeft n (left, right) 
  | abs ((left + n) - right) < 4 = Just (left + n, right)
  | otherwise                    = Nothing

landRight :: Birds -> Pole -> Maybe Pole
landRight n (left, right)
  | abs (left - ( right + n)) < 4 = Just (left, right + n)
  | otherwise                     = Nothing



{-
	landLeft 和 landRight 都不能简单链式调用，因为接收的是一个 normal value ,但是返回值是一个 monad value
	所以可以使用 >>=
-}

landRight 1 (0,0) >>= landLeft 2
Just (2,1)
```

- do 也可以用在 monad 里面, guling together monadic values  in sequence

```haskell
-- 正常写是这样
foo :: Maybe String
foo = Just 3 >>= (\x ->
			Just "!" >>= (\y ->
			Just (show x ++ y)))
 
 
-- 使用 do 语法来连接值
foo :: Maybe String
-- do 写法中，下面每一行都是一个 monadic value
foo = do
  -- 从 monad 中获取值
	x <- Just 3
	y <- Just "!"
	Just (show x ++ y)
```

```haskell
-- 也可以使用 pattern match
justH :: Maybe Char
justH = do
  -- 假如 pattern match 失败了，就会 调用 monad 的 fail 函数
	(x:xs) <- Just "hello"
	return x
```

- list monad

```haskell
instance Monad [] where
	return x = [x]
	xs >>= f = concat (map f xs)
	fail _ = []
```

```haskell
[3,4,5] >>= \x -> [x, -x]
[3, -3, 4, -4, 5, -5]

[] >>= \x -> ["bad", "mad", "rad"]
[]

-- 注意这个 n 的值一直被带到了最后，相当于成了一个闭包
[1,2] >>= \n -> ['a', 'b'] >>= \ch -> return (n, ch)

```

```haskell
-- 使用 do notation
listOfTuples :: [(Int, Char)]
listOfTuples = do
	n <- [1,2]
	ch <- ['a', 'b']
	return (n, ch)
	-- list comprehensions 只是 monad list 的语法糖
```

### MonadPlus

- 为了 monad 能表现出 monoids 的特性

````haskell
class Monad m => MonadPlus m where
  -- 跟 mempty 是一样的
	mzero :: m a
	-- 跟 mappend 是一样的
	mplus :: m a -> m a -> m a
````

- list 是 MonadPlus 的成员

```haskell
instance MonadPlus [] where
	mzero = []
	mplus = (++)
```

- guard 函数的定义

```haskell
-- () 是元祖
guard :: (MonadPlus m) => Bool -> m ()
guard True = return ()
guard Flase = mzero
```

```haskell
guard (5 > 2) :: Maybe ()
Just ()
guard (1 > 2) :: Maybe ()
guard (5 > 2) :: [()]
[()]
guard (1 > 2) :: [()]
[]
```

```haskell
-- 可以用这个特性对 list 进行过滤
{-
	原理
	假如 guard 的值是 true
	那么就会返回一个 (),() >> 的时候就会直接返回 >> 右边的值，所以这里返回 ["cool"]
-}
guard (5 > 2) >> return "cool" :: [String]
["cool"]
guard (1 > 2) >> return "cool" :: [String]
[]
```

```haskell
-- do notation
sevensOnly :: [Int]
sevensOnly = do
	x <- [1..50]
	guard ('7' `elem` show x)
	return x
```

```haskell
import Control.Monad

type KnightPos = (Int, Int)

-- 检查某个地方是否能在三步内到达
canReachIn3 :: KnightPos -> KnightPos -> Bool
canReachIn3 start end = end `elem` in3 start

-- 三步内可能到达的地方
in3 :: KnightPos -> [KnightPos]
in3 start = do
  first <- moveKnight start
  second <- moveKnight first
  moveKnight second

-- 预测出骑士下一步的所有可能性
moveKnight :: KnightPos -> [KnightPos]
moveKnight (c, r) = do
    (c', r') <- [
      (c+2, r-1),(c+2, r+1),(c-2, r-1),(c-2, r+1),
      (c+1, r-2),(c+1, r+2),(c-1, r-2),(c-1, r+2)]
    -- 判断是不是超出边界了
    guard (c' `elem` [1..8] && r' `elem` [1..8])
    return (c',r')
```

- Monad laws

  - left identity

  ```haskell
  return x >>= f <=> f x
  ```

  - right identity

  ```haskell
  m >>= return <=> m
  ```

  - Associativity : 多个嵌套使用的 monadic function 的顺序是无所谓的

  ```haskell
  (m >>= f) >>= g <=> m >>= (\x -> f x >>= g)
  ```

- monad 的 function composition

```haskell
(<=<) :: Monad m => (b -> m c) -> (a -> m b) -> a -> m c
f <=< g = (\x -> g x >>= f)
```

```haskell
let f x = [x, -x]
let g x = [x*3, x*2]
let h = f <=< g
h 3
[9,-9,6,-6]
```

### Writer

- 用描述 一个 value attached a monoid value

```haskell
-- a 代表 normal value, w 代表 monoid value
newtype Writer w a = Writer { runWriter :: (a, w) }
```

```haskell
instance (Monoid w) => Monad (Writer w) where
	return x = Writer (x, mempty)
	(Writer (x, v)) >>= f = let (Writer (y, v')) = f x in Writer (y, v `mappend` v')
```

```haskell
runWriter (return 3 :: Writer String Int)
(3, "")

runWriter (return 3 :: Writer (Sum Int) Int)
(3, Sum {getSum = 0})
```

- 使用 do 语法













## Kind

- 是 type 的 type

```haskell
:k Int
-- * 代表 concrete type
Int :: *
```

```haskell
:k Maybe
-- Maybe 是一个 type constructor 接收一个 concrete ,返回一个 concrete
Maybe :: * -> *

-- 接收了参数后就是一个 concrete 了
:k Maybe Int
Maybe Int :: *
```







## 模式匹配

### View Patterns

- 可以使用 （function -> pattern） 的语法，先对 value 应用 function ,再进行匹配
- 需要在 模块最前面加上 {-# LANGUAGE ViewPatterns #-} 来开启支持

```haskell
responsibility :: CLient -> String
responsibility (Company _ _ _ r) = r
responsibility _ = "Unknown"

specialClient :: Client -> Bool
specialClient (clientName -> "Mr. Alejandro") = True
specialClient (responsibility -> "Director") = True
specialClient _ = False
```



## if  then else 表达式

```haskell
-- if then else 都必须出现
-- if then else 两个子句返回的类型必须相同
main = do
	line <- getLine
	-- 假如输入了空行，就结束
	if null line
		then return ()
		-- 这个 else 是必须有的
		else do
			putStrLn $ reverseWords line
			main

reverseWords :: String -> String
-- 省略了参数 x , 其实等价于 unwords (map reverse (words x))
reverseWords = unwords . map reverse . words
```



## Guard

### 基本用法

```haskell
bmiTell :: (RealFloat a) => a -> String
bmiTell bmi
-- 布尔表达式
  | bmi <= 18.5 = "111"
  | bmi <= 25.0 = "222"
  | bmi <= 30.0 = "333"
  | otherwise = "444"
```

```haskell
myCompare :: (Ord a) => a -> a -> a -> Ordering
  a `myCompare` b
    | a > b = GT
    | a == b = EQ
    | otherwise = LT
```

### 使用 where

```haskell
bmiTell :: (RealFloat a) => a -> String
bmiTell weight height
  | bmi <= skinny = "111"
  | bmi <= normal = "222"
  | bmi <= fat = "333"
  | otherwise = "444"
	where bmi = weight / height ^ 2
        (skinny, normal, fat) = (18.5, 25.0, 30.0)
```

- where 可以被嵌套，比如在里面定义一些别的 helper function

### 使用 let binding

```haskell
	cylinder :: (RealFloat a) => a -> a -> a
  cylinder r h =
    let sideArea = 2 * pi * r * h
        topArea = pi * r ^ 2
    in  sideArea + 2 * topArea
```

- 与 where 的区别是 let binding 是一个表达式
- 可以在内部 定义 function 并使用

```haskell
[let square x = x * x in (square 5, square 3, square 2)]
[(25,9,4)]
```

- 可以连续绑定多个变量，用 分号 隔开即可

```haskell
(let a = 100;b = 200; c = 300 in a * b * c, let foo = "Hey "; bar = "there!" in foo ++ bar)
(6000000,"Hey there!")
```

- 可以在 let bindings 中使用 pattern match, 从元祖中取值的时候很有用

```haskell
(let (a,b,c) = (1,2,3) in a+b+c) * 100
```

- 也可以用在 列表推导中

```haskell
calcBmis :: (RealFloat a) => [(a, a)] -> [a]
calcBmis xs = [bmi | (w, h) <- xs, let bmi = w / h ^ 2]
```

- let  bindings 无法 跨 guard 使用

## Case 表达式

### 基本用法

```haskell
case expression of pattern -> result
										pattern -> result
										pattern -> result
										...
```

- function 的子句定义就是 case 表达式的语法糖



## List

### 存取

- String 也是一个 list, list 内的元素必须是一个类型
- 使用 ++ 连接 两个 list, 必须遍历前一个 list, 可能造成性能问题
- : 符号可以从头取 List 的元素, !! 可以根据下标取数据

```haskell
'A' : "SMALL CAR"
"Steve Buscemi" !! 6
```

- 假如 list 中的元素可以被比较，那么 list 就可以被比较, 从第一个元素开始依次比较大小

### 基本操作方法

```haskell
head [5,4,3,2,1]
5

tail [5,4,3,2,1]
[4,3,2,1]

last [5,4,3,2,1]
1

init [5,4,3,2,1]
[5,4,3,2]

length [5,4,3,2,1]
5
-- 使用这个来判空
null []
True

reverse [5,4,3,2,1]

take 3 [5,4,3,2,1]
[5,4,3]

take 5 [1,2]
[1,2]

take 0 [6,6,6]
[]

drop 3 [8,4,2,1,5,6]
[1,5,6]

drop 0 [1,2,3,4]
[1,2,3,4]
drop 100 [1,2,3,4]
[]

minimum [8,4,2,1,5,6]
1

maximum [1,9,2,3,4]
9

sum [5,2,1,6,3,2,5,7]
31
-- 相乘的积
product [6,2,1,2]
24

4 `elem` [3,4,5,6]
True
10 `elem` [3,4,5,6]
False

```

### Folds

```haskell
foldr :: (a -> b -> b) -> b -> [a] -> b
foldr f intial [] = initial
foldr f initial (x:xs) = f x (foldr f initial xs)
```

```haskell
foldl :: (a -> b -> a) -> a -> [b] -> a
foldl _ initial [] = initial
foldl f initial (x:xs) = foldl f (f initial x) xs
```





## Ranges

### 基本

```haskell
[1..20]
['a'..'z']
['K'..'Z']
```

### 设定 step

```haskell
[2,4..20]
```

### 倒数

```haskell
[20,19..1]
```

### 不要在使浮点数用

### 无限Range

```haskell
-- 不设定上限
take 24 [13,26..]
-- 使用 cycle
take 10 (cycle[1,2,3])
[1,2,3,1,2,3,1,2,3,1,2,3]
-- 使用 repeat
take 10 (repeat 5)
[5,5,5,5,5,5,5,5,5,5]
-- 使用 replicate
replicate 3 10
[10,10,10]
```



## 列表推导式

### 基本

```haskell
[x*2 | x <- [1..10]]
```

### 过滤 

```haskell
[x*2 | x <- [1..10], x*2 >= 12]
```

### 多个 取值范围 : 逐个匹配

```haskell
[x*y | x <- [2,5,10], y <- [8,10,11]]
[16,20,22,40,50,55,80,100,110]
```

### 嵌套 推导式

```haskell
let xxs = [[1,3,5,2,3,1,2,4,5], [1,2,3,4,5,6,7,8,9], [1,2,3,2,1,6,3,1,3,2,3,6]]
[[ x | x <- xs, even x] | xs <- xxs]
[[2,2,4],[2,4,6,8],[2,2,6,2,6]]
```

### 可以使用 let 来绑定本地变量

```haskell
[ sqrt v | (x,y) <- [(1,2),(3,8)], let v = x*x + y*y]
[2.23606797749979,8.54400374531753]
```

### 支持使用 guard 来过滤

```haskell
[(x,y) | x <- [1..6], y <- [1..6], x <= y]
[(1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(2,2),(2,3),(2,4),(2,5),(2,6),(3,3),(3,4),(3,5),(3,6),(4,4),(4,5),(4,6),(5,5),(5,6),(6,6)]
```

### TransformListComp

- 可以使用 then f 来对最后生成的 list 应用一次 f

```haskell
[x*y | x <- [-1, 1, -2], y <- [1,2,3], then reverse]
[-6,-4,-2,3,2,1,-3,-2,-1]
```

- 使用 then f by e ，来对列表进行排序

```haskell
*Main Chapter3.Example Lib> import GHC.Exts
*Main Chapter3.Example Lib GHC.Exts> :{
*Main Chapter3.Example Lib GHC.Exts| [x*y | x <- [-1,1,-2], y <- [1,2,3]
*Main Chapter3.Example Lib GHC.Exts| , then sortWith by x]
*Main Chapter3.Example Lib GHC.Exts| :}
[-2,-4,-6,-1,-2,-3,1,2,3]
```

- 使用 group by e using f 来对列表进行分组
- f 的类型是 (a -> b) -> [a] -> [[a]]

```haskell
*Main Chapter3.Example Lib GHC.Exts> :{
*Main Chapter3.Example Lib GHC.Exts| [ (the p, m) | x <- [-1,1,2]
*Main Chapter3.Example Lib GHC.Exts| , y <- [1,2,3]
*Main Chapter3.Example Lib GHC.Exts| , let m = x * y
*Main Chapter3.Example Lib GHC.Exts| , let p = m > 0
-- 将所有 p 相等的 值全部收集到一起
*Main Chapter3.Example Lib GHC.Exts| , then group by p using groupWith ]
*Main Chapter3.Example Lib GHC.Exts| :}
[(False,[-1,-2,-3]),(True,[1,2,3,2,4,6])]

-- 假如不使用 the 的话是这样的结果
[ (p, m) | x <- [-1,1,2], y <- [1,2,3], let m = x * y, let p = m > 0, then group by p using groupWith]
[([False,False,False],[-1,-2,-3]),([True,True,True,True,True,True],[1,2,3,2,4,6])]
```

- 使用 ParallelListComp 来对多个list进行一一匹配而不是两两匹配

```haskell
[x*y | x <- [1,2,3], y <- [1,2,3]]
[1,2,3,2,4,6,3,6,9]

[x*y | x <- [1,2,3] | y <- [1,2,3]]
[1,4,9]
```





## 元祖

### 基本

```haskell
[(1,2),(3,4)]
```

有用的方法

```haskell
-- 获取 pair的第一个和第二个元素
fst (8,11)
8

snd (8,11)
11

-- zip 结合两个 list 去产生 pair, 会用短的list去匹配长的list
zip [1..5]["one","two","three","four","five"]

```

### 生产元祖的特殊lambda

```haskell
(,,) <=> \x y z -> (x, y, z)
(,) <=> \x y -> (x,y)
```



## 高阶函数

### 柯里化

- 中继函数可以简化其写法

```haskell
divideByTen :: (Floating a) => a -> a
divideByTen = (/10)

isUpperalphanum :: Char -> Bool
isUpperalphanum (`elem` ['A'..'Z'])
```

- 类型声明时，函数类型必须用 括号

```haskell
zipWith' :: (a -> b -> c) -> [a] -> [b] -> [c]
zipWith' _ [] _ = []
zipWith' _ _ [] = []
zipWith' f (x:xs) (y:ys) = f x y : zipWith' f xs ys
```



## Lambda 表达式

### 基本语法

- 以 \ 开头， 参数列表空格隔开 -> 后是方法体

```haskell
numLongChains :: Int
numLongChains = length (filter (\xs -> length xs > 15) (map chain [1..100]))
```

- 不能对同一个 参数应用多个 模式匹配, 只能使用 case 来模拟

### LambdaCase

可以使用 LambdaCase 来简化 case 的判断

```haskell
sayHello names = map (\case "Alehandro" -> "Hello, writer";
																name -> "Welcome, " ++ name
) names
```



## Function Application 中使用 $

- Function Application 是 左结合的， $ 是 右结合的

```haskell
($) :: (a -> b) -> a -> b
```

- 为了不写那么多括号

```txt
sum (map sqrt [1..130]) <=> sum $ map sqrt [1..130]
```

- 可以把 Function Application 变为 Function 使用

```haskell
-- 给 list 中的每一个函数都传一个参数 3
map ($ 3)[(4+), (10*), (^2), sqrt]
[7.0,30.0,9.0,1.7320508075688772]
```



## Function compositon, 使用 . 号

- 使用 . 号来 结合 function

```haskell
(.) :: (b -> c) -> (a -> b) -> a -> c
f . g = \x -> f (g x)
```

- . 号是右结合的

```txt
f(g(z x)) <=> (f.g.z) x
```



## combinators

- 针对 function 进行各种操作的函数

```haskell
uncurry :: (a -> b -> c) -> (a, b) -> c
uncurry f = \(x,y) = f x y

curry :: ((a,b) -> c) -> a -> b -> c
curry f = \x y -> f (x, y)

flip :: (a-> b -> c) -> (b -> a -> c)
```

- 这种场景下可以使用 uncarry

```haskell
map (uncurry max) [(1,2),(2,1),(3,4)]
[2,2,4]
```



## Modules

### 模块的导入

```txt
import <module name>
```

```haskell
import Data.List
```

- 只导入某个模块的某些函数

```haskell
import Data.List (nub, sort)
```

- 只排除某些方法

```haskell
import Data.List hiding (nub)
```

- 当 命名出现冲突时

```haskell
import qualified Data.Map as M
```

### 模块的声明和导出函数

```haskell
module Geometry
( sphereVolume
, sphereArea
, cubeVolume
, cubeArea
, cuboidArea
, cuboidVolume
) where

 -- 球体积公式
sphereVolume :: Float -> Float
sphereVolume radius = (4.0/3.0) * pi * (radius ^ 3)
-- 球的面积公式
sphereArea :: Float -> Float
sphereArea radius = 4 * pi * (radius ^ 2)
-- 正方体体积
cubeVolume :: Float -> Float
cubeVolume side = cuboidVolume side side side
-- 正方体面积
cubeArea :: Float -> Float
cubeArea side = cuboidArea side side side
-- 立方体体积
cuboidVolume :: Float -> Float -> Float -> Float
cuboidVolume a b c = rectangleArea a b * c
-- 立方体面积
cuboidArea :: Float -> Float -> Float -> Float
cuboidArea a b c = rectangleArea a b * 2 + rectangleArea a c * 2 + rectangleArea c b * 2
-- 矩形面积
rectangleArea :: Float -> Float -> Float
rectangleArea a b = a * b

```

- 也可以用 . 声明子模块

### 导出类型及其构造器

```haskell
module Shapes
(
	-- 导出全部构造器
	Point(..)
	-- 导出这两个构造器
, Shape(Rectangle, Circle)
	-- 也可以只导出某些类型
,	Range()
	-- 导出这个方法
, surface

) where
```

### Smart Constructor

```haskell
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns #-}

module Chapter3.Ranges (
  Range(),
  -- 导出这个和r 是为了 方便模式匹配
  RangeObs(R),
  -- 相当于只导出了类型和工厂函数
  range,
  r
  
)
where 

data Range = Range Integer Integer deriving Show
data RangeObs = R Integer Integer deriving Show

r :: Range -> RangeObs
r (Range a b) = R a b


-- 为了限制输入输出，规定这么个函数
range a b = if a <= b then Range a b else error "a must be <= b"

-- 定义匹配模式
--pattern R :: Integer -> Integer -> Range
-- 模式匹配的 pattern ，也就是 R a b 可以匹配 Range a b
--pattern R a b <- Range a b
  -- 定义 使用 R a b 就等于使用 range a b
  --where R a b = range a b
```

```haskell
--导出之后可以这么匹配 Range
prettyRange rng = case rng of (r -> R a b) -> "[" ++ show a ++ "," ++ show b ++ "]"
```



### Pattern Synonyms

- 用来定义某个匹配模式，使用 PatternSynonyms

```haskell
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE ViewPatterns #-}

module Chapter3.Ranges (
  Range(),
  -- 相当于只导出了类型和工厂函数
  range,
  -- 给外部使用的话需要导出
  pattern R
)
where 

data Range = Range Integer Integer deriving Show

-- 为了限制输入输出，规定这么个函数
range a b = if a <= b then Range a b else error "a must be <= b"

-- 定义匹配模式
pattern R :: Integer -> Integer -> Range
-- 模式匹配的 pattern ，也就是 R a b 可以匹配 Range a b
pattern R a b <- Range a b
  -- 定义 使用 R a b 就等于使用 range a b
  where R a b = range a b
```

```haskell
---外部可以使用 R 来进行模式匹配
prettyRange rng = case rng of (R a b) -> "[" ++ show a ++ "," ++ show b ++ "]"
```





## Types And Typeclasses

### data

- 使用 data 关键字类定义类型

```haskell
-- 前面是类型，后面是构造器
data Bool = False | True
-- 接收参数的构造器
data Shape = Circle Float Float Float | Rectangle Float Float Float Float
```

- 构造器可以用于模式匹配

```haskell
-- 求面积的公式
surface :: Shape -> Float
surface (Circle _ _ r) = pi * r ^ 2
surface (Rectangle x1 y1 x2 y2) = (abs $ x2 - x1) * (abs $ y2 -y1)
```

- 可以让类型 成为 其它 typeclass 的成员，比如 Show

```haskell
data Shape = Circle Float Float Float | Rectabgle Float Float Float Float deriving (Show)
Circle 10 20 5
Circle 10.0 20.0 5.0
```

- 递归数据类型 (二叉树的实现)

```haskell

data Tree a = EmptyTree | Node a (Tree a) (Tree a) deriving (Show, Read, Eq)

-- 构造一个只有一个节点的 tree
singleton :: a -> Tree a
singleton x = Node EmptyTree EmptyTree

treeInsert :: (Ord a) => a -> Tree a -> Tree a
-- 插入空树的时候返回一颗单节点树
treeInsert x EmptyTree = singleton x
treeInsert x (Node a left right)
  | x == a = Node x left right
  | x < a = Node a (treeInsert x left) right
  | x > a = Node a left (treeInsert x right)
```

### 自定义 Typeclasses

- 使用 class 关键字

```haskell
class Eq a where
-- 不必写函数体,写出类型声明即可
(==) :: a -> a-> Bool
(/=) :; a -> -> Bool
x == y = not (x /= y)
x /= y = not (x == y)
```

- 使用 instance 关键字自定义 typeclass 的实现

```haskell
data TrafficLight = Red | Yellow | Green

instance Eq TrafficLight where
  Red == Red = True
  Green == Green = True
  Yellow == Yellow = True
  _ == _ = False

instance Show TrafficLight where
  show Red = "Red Light"
  show Yellow = "Yellow light"
  show Green = "Green light"
```

- 可以定义 typeclass 的 子类型

```haskell
class (Eq a) => Num a where
...
```

- 使用 typeconstructor 定义 typeclass 成员的时候，不能省略type parameter

```haskell
instance (Eq m) => (Mqybe m) where
...
```



### newtype

- 当想把 别的 type 包装一下 封装为一个新的 type 的时候，使用该关键字

```haskell
-- 效率比 data 更好
-- 不过只能 有一个 value constructor ，也只有能 有一个 field
newtype ZipList a = ZipList { getZipList :: [a] }
```

- 可以使用 deriving 关键字, 但是要保证 包装的 type 已经是其成员

```haskell
newtype CharList = CharList { getCharList :: [Char] } deriving (Eq, Show)
```

- 在某些场合，可以使用 newtype 来创建 type class 的 instance

```haskell
-- 将 (a,b) 包装进去
newtype Pair b a = Pair { getPair :: (a,b) }

-- 成为 functor 的成员
instance Functor (Pair c) where
  -- 只对第一个成员应用 f 
	fmap f (Pair (x, y)) = Pair (f x, y)
	
-- 因为 (a, b) 不好直接去成为 functor 的成员

```

```haskell
getPair $ fmap (*100)(Pair (2,3))
(200, 3)
```

### type vs. newtype vs. data

- type 只是某个已经存在的类型的同义词，使用主要是为了增强可读性
- 对某个 已经存在的 type 的封装，封装之后就不是原来的type了，可以当做是只有一个 value constructor 的 data
- 定义数据类, 定义一个完全全新的类型



## Record

### 基本语法

```haskell
data Person = Person { firstName :: String  
                     , lastName :: String  
                     , age :: Int  
                     , height :: Float  
                     , phoneNumber :: String  
                     , flavor :: String  
                     } deriving (Show)
```

- 之后 定义的每一个属性都是一个 function

```haskell
:t flavor
flavor :: Person -> String
```

- 在需要给字段命名时使用 Record

- 使用 NamedFieldPuns 可以开启 命名匹配

```haskell
-- 可以直接使用 firstName 的字段名作为匹配的变量
greet Indidual {person = PersonR { firstName }} = "Hi, " ++ firstName 
```

- 可以使用 RecordWildCards 开始自动绑定全部变量

```haskell
greet Indidual {person = PersonR { .. }} = "Hi, " ++ firstName 
```



### 更新 record

- 可以使用 r { field name = new value } 的语法去创建一个新的 copy

```haskell
nameInCpitals :: PersonR -> PersonR
nameInCapitals p@(PersonR { firstName = initial:rest }) = 
	-- 将姓名的首字母改为大写
	let newName = (toUpper initial):rest
	-- 创建一个新的 record, 数据照搬 p ，除了将其 firstName 改为 首字母大写后的值
	in p { firstName = newName }
-- 假如 名字为空就直接返回
nameInCapitals p@(PersonR { firstName = "" }) = p
```



## Type parameter

- 类型参数，可以传给 type constructor 成为一个新的类型
- *never add typeclass constraints in data declarations.* 在类型声明的时候，永远不要加上 typeclass 的约束

```haskell
-- 这样没什么好处
data (Ord k) => Map k v = ...  
```



## Type synonyms

- 主要是为了可读性, 相当于是某个类型的别名

```haskell
type String = [Char]  
```

- 也可以使用类型参数

```haskell
type AssocList k v = [(k,v)] 
```



## Input 和 Output

### IO Action

```haskell
:t putStrLn
-- 这里的就是一个 IO Action () 表示一个空的元祖
putStrLn :: String -> IO ()
```

### do 语法

```haskell
main = do 
	putStrLn "Hello, what's your name?"
	name <- getLine
	putStrLn ("Hey " ++ name ++ ", your rock!")
```

- do 可以粘合一系列的 IO Action，其 type 由最后一个 IO Action 决定

### 左箭头操作符

```haskell
t getLine
getLine :: IO String

name <- getLine
```

- 等待用户输入一行, 并将其绑定到对应的 name 上去

### IO 操作不能和其它 pure function 混用

- IO操作属于有副作用的操作，因此最好不要和其它 pure function 混用

```haskell
-- 这样是不行的因为 getLine 的类型是 IO String 不能被 ++ 支持
nameTag = "Hello, my name is" ++ getLine
```

### 在 IO Action 中使用 let binding

```haskell
import Data.char
main = do
	putStrLn "What's your first name?"
	firstName <- getLine
	putStrLn "What's your lst name?"
	lastName <- getLine
	let bigFirstName = map toUpper firstName
			bigLastName = map toUpper lastName
	putStrLn $ "hey " ++ bigFirstName ++ " " ++ bigLastName ++ ", how are you?"
```

### IO Action 中的return

```haskell
main = do
  return ()
  return "HAHAHA"
  line <- getLine
  return "BLAH BLAH BLAH"
  return 4
  putStrLn line
```

- renturn 只是将一个值包装到一个 box 中, 假如没有接收，那就被丢弃了

### 一些常用的IO操作

- putStr: 不会换行的 putStrLn

- putChar: 打印字符

  - putStr 可以用这个来定义

  ```haskell
  putStr :: String -> IO()
  putStr [] = return ()
  putStr (x:xs) = do
  	putChar x
  	putStr xs
  ```

- print : 接收全部 Show 的成员, 然后按照 Show 的方式打印

  - 等价于 putStrLn . show

- getChar : 从输入中读取一个字符

  - getChar :: IO Char

  ```haskell
  main = do
  	c <- getChar
  	if c /= ' '
  		then do
  			putChar c
  			main
  		else return ()
  ```

- when : 在 Control.Monad 包中

  - when 接收一个 boolean 和 IO Action, 假如是true，就执行 IO Action, 不然就 return ()

```haskell
import Control.Monad

main = do
	c <- getChar
	when (c /= ' ') $ do
		putChar c
		main
```

- sequence: 接收一个 list 的 IO Action, 并逐个执行， 返回一个结果的 list

```haskell
sequence (map print [1,2,3,4,5])
```

- mapM: 接收一个 function 和 list, map function list 后 sequence 

- mapM_ : 跟上面一样，除了不要结果以外

- forever: 在 Control.Monad 包中

  - 无限执行某个 IO Action

  ```haskell
  import Control.Monad
  import Data.Char
  
  main = forever $ do
  	putStr "Give me some input: "
  	l <- getLine
  	putStrLn $ map toUpper l
  ```

- forM: 在 Control.Monad 包下

  - 第一个参数是 list, 第二个参数是 function, map后sequence
  - 有时候 function 特别长的时候比较有用, 尤其是 do 块的时候

  

- getContents : 从标准输入中获取全部文本

- interact : 接收一个 type 是 String -> String 的 function ，返回一个 IO Action

  ```haskell
  main = interact shortLinesOnly
  
  shortLinesOnly :: String -> String
  shortLinesOnly input =
  	let allLines = lines input
  		shortLines = filter (\line -> length line < 10) allLines
  		result = unline shortLines
  	in result
  	
  -- 以上可以缩写为
  main = interact $ unlines . filter ((<10) . length) . lines
  ```

  ```haskell
  main = interact respondPalindromes
  
  respondPalindromes contents = unlines 
    (map (\xs -> if isPalindrome xs then "palindrome" else "not a palindrome") (lines contents)) 
      where isPalindrome xs = xs == reverse xs
      
  -- 下面的使用 . 语法的话
  respondPalindromes = unlines 
     . map (\xs -> if isPalindrome xs then "palindrome" else "not a palindrome") . lines
      where isPalindrome xs = xs == reverse xs
  ```

  - 

- openFile : 打开文件

```haskell
openFile :: FilePath -> IOMode -> IO Handle
type FilePath = string
data IOMode = ReadMode | WriteMode | AppendMode | ReadWriteMode
```

```haskell
import System.IO

main = do
  -- 打开文件，获取句柄
  handle <- openFile "girlfriend.txt" ReadMode
  -- hGetContents 接收一个文件句柄 返回一个 IO String
  contents <- hGetContents handle
  putStr contents
  -- 关闭句柄
  hClose handle
```

- withFile:

```
withFile :: FilePath -> IOMode -> (Handle -> IO a) -> IO a
```

```haskell
import System.IO

main = do
	withFile "girlfriend.txt" ReadMode (\handle -> do
		contents <- hGetContents handle
		putStr contents)
```

- hGetLine, hPutStr, hPutStrLn,hGetChar : 都是接收一个 handle

- readFile

```haskell
readFile:: FilePath -> IO String
```

- writeFile

```haskell
writeFile :: FilePath -> String -> IO ()
```

​		- 假如文件已存在会把已存在的内容全部覆盖掉	

	-  appendFile : 跟 writeFile 类型一致, 但是不会覆盖掉文件内容，而是接着后面写
	-  hSetBuffering ： 可以设置 缓冲区的大小

```haskell
hSetBuffering :: Handle -> BufferMode -> IO ()
data BufferMode = NoBuffering | LineBuffering | BlockBuffering (Maybe Int)
```

```haskell
main = do 
	withFile "something.txt" ReadMode (\handle -> do
		hSetBuffering handle $ BlockBuffering (Just 2048)
		contents <- hGetContents handle
		putStr contents)
```

- hFlush: 立即刷新缓冲区

```haskell
import System.IO
import System.Directory
import Data.List

main = do
  -- 以 ReadMode 打开文件并保存其句柄
  handle <- openFile "todo.txt" ReadMode
  -- openTempFile, 接收一个临时路径和一个临时文件名 . 代表当前目录
  -- 返回一个 文件名 和 该文件的引用
  (tempName, tempHandle) <- openTempFile "." "temp"
  -- 把 todo.txt 文件的内容 bind 到 contents 上去
  contents <- hGetContents handle
  --  将内容按行分割为 list
  let todoTasks = lines contents
      -- 给任务编号, 便成为 0-task1, 1-task2 的形式
      numbredTasks = zipWith (\n line -> show n ++ " - " ++ line) [0..] todoTasks
  putStrLn "These are your TO-DO items:"
  -- 展示 编号后的任务, 也可以写为 mapM putStrLn numberedTasks
  putStr $ unlines numbredTasks
  putStrLn "Which one do you want to delete"
  -- 获取用户的输入
  numberString <- getLine
  -- read 读取一个 string, 返回其类型化后的值
  let number = read numberString
      -- !! 根据 下标取值, 也就是删除对应的 todo
      newTodoItems = delete (todoTasks !! number) todoTasks
  -- 将 新的 todo 的内容写入临时文件
  hPutStr tempHandle $ unlines newTodoItems
  -- 将两个 handle 都关闭掉
  hClose handle
  hClose tempHandle
  -- 将原来的文件删掉
  removeFile "todo.txt"
  -- 把临时文件命名为原来的文件
  renameFile tempName "todo.txt"
```



### Command Line Arguments

- getArgs :: IO [String] 获取程序运行的参数列表
- getProgName :: IO String 获取运行的程序的名字

```haskell
import System.Environment
import Data.List

main = do
  args <- getArgs
  progName <- getProgName
  putStrLn "The arguments are:"
  mapM putStrLn args
  putStrLn "the program name is:"
  putStrLn progName
```

```shell
stack runhaskell arg-test.hs first second w00t "multi word arg"
The arguments are:
first
second
w00t
multi word arg
the program name is:
arg-test.hs
```

```haskell
import System.Environment
import System.Directory
import System.IO
import Data.List

main = do
    -- 获取参数， : command 表示取第一个, args 表示剩下的
    (command:args) <- getArgs
    -- 从 dispatch 中寻找对应 command
    let (Just action) = lookup command dispatch
    -- 执行对应的 command
    action args

-- 提供的API
dispatch :: [(String, [String] -> IO ())]
dispatch = [
    ("add", add),
    ("view", view),
    ("remove", remove),
    ("bump",  bump)
    ]

-- 添加
add :: [String] -> IO ()
add [fileName, todoItem] = appendFile fileName (todoItem ++ "\n")

-- 查看
view :: [String] -> IO ()
view [fileName] = do
    contents <- readFile fileName
    let todoTasks = lines contents
        numberTasks = zipWith (\n line -> show n ++ " - " ++ line) [0..] todoTasks
    putStr $ unlines numberTasks

-- 移除
remove :: [String] -> IO ()
remove [fileName, numberString] = do
    -- 打开 todo 的文件
    handle <- openFile fileName ReadMode
    -- 准备一个临时文件来接收 删除后的结果
    (tempName, tempHandle) <- openTempFile "." "temp"
    contents <- hGetContents handle
    let number = read numberString
        todoTasks = lines contents
        newTodoItems = delete (todoTasks !! number) todoTasks
    hPutStr tempHandle $ unlines newTodoItems
    hClose handle
    hClose tempHandle
    removeFile fileName
    renameFile tempName fileName

-- 将指定的项目提升到第一位
bump :: [String] -> IO ()
bump [numberString] = do
    todoTasks <- lines $ readFile fileName
    let number = read numberString
        removedTask = todoTasks !! number
        newTodoItems = delete removedTask todoTasks
        


```



## 随机值

- random 接受一个 随机值生成器, 可以指定随机值的类型

```haskell
Prelude System.Random> random (mkStdGen 100) :: (Float, StdGen)
(0.6512469,651872571 1655838864)
Prelude System.Random> random (mkStdGen 100) :: (Bool, StdGen)
(True,4041414 40692)
Prelude System.Random> random (mkStdGen 100) :: (Integer, StdGen)
(-3633736515773289454,693699796 2103410263)
```

- 抛硬币三次的结果

```haskell
threeCoins :: StdGen -> (Bool, Bool, Bool)
threeCoins gen = 
	let (firstCoin, newGen) = random gen
			(secondCoin, newGen') = random newGen
			(thirdCoin, newGen'') = random newGen'
	in (firstCoin, secondCoin, thirdCoin)
```

- randoms: 接收一个 随机值生成器, 返回一个基于该生成器的无限列表

```haskell
take 5 $ randoms (mkStdGen 11) :: [Int]
[5260538044923710387,4361398698747678847,-8221315287270277529,7278185606566790575,1652507602255180489]
Prelude System.Random> take 5 $ randoms (mkStdGen 11) :: [Bool]
[True,True,True,True,False]
Prelude System.Random> take 5 $ randoms (mkStdGen 11) :: [Float]
[0.26201087,0.1271351,0.31857032,0.1921351,0.31495118]
```

```haskell
randoms' :: (RandomGen g, Random a) => g -> [a]
-- 递归生成随机数列表
randoms' gen = let (value, newGen) = random gen in value:randoms' newGen
```

- 生成一个有限随机数列表

```haskell
finiteRandoms :: (RandomGen g, Random a, Num n) => n -> g -> ([a], g)
finiteRandoms 0 gen = ([], gen)
finiteRandoms n gen =
	let (value, newGen) = random gen
			(restOfList, finalGen) = finiteRandoms (n-1) newGen
	in	(value:restOfList, finalGen)
```

- randomR : 在一个范围中产生随机值

```haskell
randomR (1,6) (mkStdGen 359353)

```

- randomRs: 在某一个范围中产生无限随机列表

```haskell
take 10 $ randomRs ('a', 'z') (mkStdGen 3) :: [Char]
```

- getStdGen : 获取一个IO StdGen, 如果在一个程序中调用两次就会获得相同的值

```haskell
import System.Random

main = do
    gen <- getStdGen
    putStr $ take 20 (randomRs ('a', 'z') gen)
```

- newStdGen: 会更新全局 随机值生成器, 并返回一个新的随机值生成器

```haskell
import System.Random

main = do
    gen <- getStdGen
    putStr $ take 20 (randomRs ('a', 'z') gen)
    gen' <- newStdGen
    putStr $ take 20 (randomRs ('a', 'z') gen')
```

- 让用户猜数字的程序

```haskell
mport System.Random
import Control.Monad(when)

main = do
  gen <- getStdGen
  askForNumber gen

askForNumber :: StdGen -> IO()
askForNumber gen = do
  -- 产生一个 1-10 的随机值
  let (randNumber, newGen) = randomR (1, 10) gen :: (Int, StdGen)
  putStr "Which number in the range from 1 to 10 am I thinking of? "
  -- 接收用户输入
  numberString <- getLine
  -- 如果用户输入不为空的话
  when (not $ null numberString) $ do
    -- 将输入转为 string
    let number = read numberString
    -- 判断是否相等
    if randNumber == number
      then putStrLn "You are correct!"
      else putStrLn $ "Sorry, it was " ++ show randNumber
    askForNumber newGen
```

## 

## Bytestrings

- 有很多API 跟 Data.List 是重合的，所以需要 qualified 一下

```haskell
import qualified Data.ByteString.Lazy as B
import qualified Data.ByteString as S
```

- pack: 接收一个 byte list 返回一个 ByteString

```haskell
-- Word8 的取值范围是 0-255, 也是 Num 的成员
pack :: [Word8] -> ByteString

Prelude B S> B.pack [99, 97, 110]
"can"
Prelude B S> B.pack [98..120]
"bcdefghijklmnopqrstuvwx"
```

- unpack : 与 pack 相反
- fromChunks ： 接收一个严格的 bytestring 列表将其转换为一个 lazy 的 bytestrings 列表
- toChunks: 接收一个 lazy 的 bytestrings 列表并将其转换为一个 严格的 bytestrings 列表
- cons  : 接收一个 byte 和一个 bytestring 并将 byte 放到 bytestring 开头, 总是会产生一个 新的 chunk, 所以用 严格的 cons' 比较好

- empty: 产生一个空的 bytestring
- 有许多 bytestings 版本的 Data.List 方法
- 也有许多 bytestring 版本的 IO 方法

```haskell
import System.Environment
import qualified Data.ByteString.Lazy as B

main = do
  (fileName:fileNam2:_) <- getArgs
  copyFile fileNam1 fileName2

  copyFile :: FilePath -> FilePath -> IO ()
  copyFile source dest  = do
    contents <- B.readFile source
    B.writeFile dest contents
```



- 都需要处理大量的 string 的时候， 使用 bytestring 比较合适





## Exceptions

- catch : 接收一个 IO Action 和一个 (IOError -> IO a)

```haskell
import System.Environment
import System.IO
import System.IO.Error

main = toTry `catch` handler

toTry :: IO ()
toTry = do (fileName:_) <- getArgs
            contents <- readFile fileName
            putStrLn $ "The file has " ++ show (length (lines contents)) ++ " lines!"

handler :: IOError -> IO ()
handler e = putStrLn "Whoops, had some trouble！"
```

- 可以检查 获取到的 Exception 的类型

```haskell
handler :: IOError -> IO ()
handler e 
	| isDoesNotExistError e =  putStrLn "Whoops, had some trouble！"
	| otherwise = ioError e
```

- isDoesNotExistError 接受一个 IOError 返回一个 Bool, 查看改异常是否是 文件不存在的异常
- ioError : IOException -> IO a 
  - 接受一个 异常并在 IO Action 中抛出它
- userError: 可以产生一个自定义信息的 异常

```haskell
ioError $ userError "remote computer unplugged!"
```

