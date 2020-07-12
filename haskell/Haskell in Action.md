# 十分常用的标准模块API

## Data.List

### intersperse

- 将 指定元 两两插入某个list 中

```haskell
intersperse '.' "MONKEY"
"M.O.N.K.E.Y"
```

### intercalate 

- 将指定 list 两两插入到指定 list中间

```haskell
intercalate " " ["hey", "there", "guys"]
"hey there guys"
```

### transpose 

- 似乎在矩阵计算中有用

```haskell
transpose [[1,2,3], [4,5,6], [7,8,9]]
[[1,4,7],[2,5,8],[3,6,9]]
```

### fold1' 和 foldl1' 

- 标准版的 不lazy 版本,
- lazy 版本可能会在非常巨大的list上调用时出现 stack overflow

### concat 

- 扁平化 一层 list

```haskell
concat ["foo", "bar", "car"]
"foobarcar"
```

### concatMap 

- 先 对 list 应用 map ，然后再 concat

```haskell
concat (replicate 4)[1..3]
[1,1,1,1,2,2,2,2,3,3,3,3]
```

### and

- 判断一个 bool 的 list 是否全部是 true

```haskell
and $ map (>4) [5,6,7,8]
True
```

### or 

- 判断一个 bool 的 list 是否至少有一个 true

```haskell
or $ map (==4) [2,3,4,5,6,1]
```

### any , and

- 用一个 predicate 检查 list 中的元素是否都符合

```haskell
any (==4) [2,3,4,5,6,1,4]
True
all (`elem` ['A'..'Z']) "HEYGUYSwhatsup"
False
```

### iterate

- 接收一个 function 和 初始值，对初始值调用 function 后 对返回值再次调用 function ，产生无限列表

```haskell
take 10 $ iterate (*2) 1
[1,2,4,8,16,32,64,128,256,512]
```

### splitAt 

- 指定 index 将 list 分割为两个，装在一个元祖中返回

```haskell
splitAt 3 "heyman"
("hey","man")
```

### takeWhile 

- 接收一个 predicate 和 一个 list ，会把前 n 个 符合条件的 元素的list返回

```haskell
takeWhile (/=' ') "This is a sentence"
"This"
sum $ takeWhile (<10000) $ map (^3)[1..]
53361
```

### dropWhile

- 跟上面的相反

### span 

- 类似于 takeWhile, 只不过返回一个 pair list, 前者是 符合条件的列表，后者是剩下的

```haskell
span (/=4)[1,2,3,4,5,6,7]
([1,2,3],[4,5,6,7])
```

### break 

- break p <=> span $ not . p

### sort 

- 按自然顺序排序，元素必须是 Ord 的成员

### group

- 接收一个list，把 list 按照其元素是否相等分组

```haskell
group [1,1,1,2,2,2,3,3,3]
[[1,1,1],[2,2,2],[3,3,3]]
```

```haskell
-- 统计某个元素出现了多少次
map (\l@(x:xs) -> (x, length l)) . group . sort $ [1,1,1,1,1,2,2,2,2,3,3,3,3,4,6,1,2,7]
[(1,6),(2,5),(3,4),(4,1),(6,1),(7,1)]
```

### inits tails 

- 类似与 init 和 tail ，只不过它们会把整个list 递归完

```haskell
inits "w00t"
["","w","w0","w00","w00t"]
tails "w00t"
["w00t","00t","0t","t",""]
```

### isInfixOf

- 在一个 list 中寻找 子串

```haskell
"cat" `isInfixOf` "I'm a cat burglar"
True
```

### isPrefixOf isSuffixOf 

- 查看某个subList 是否是某个 list 的开头或结尾

### elem notElem 

- 检查某个元素是否是某个 list 的子元素

### partition

- 接收一个list和一个 predicate, 返回一个 pair, 前者是符合条件的元素，后者是不符合条件的元素

```haskell
partition (`elem` ['A'..'Z']) "BOBsidneyMORGANeddy"
("BOBMORGAN","sidneyeddy")
```

### find

- 找到 list 中第一个符合条件的元素, 但是返回值会包在 Maybe 中

```haskell
find (>4) [1,2,3,4,5,6]
Just 5
find (>9) [1,2,3,4,5,6]
Nothing
```

### elemIndex

- 类似于 elem, 但是会返回 找到元素的 index, 假如没有找到 返回 Nothing

### elemIndics

- 类似于 elemIndex, 返回一组 index 的列表, 是 目标 element 出现的所有 index， 没有的话返回 空 list

### findIndex findIndices

- 作用同上，接收一个 predicate

### zip3 ~zip7 , zipWith3 ~zipWith7

- 接收字面上的数量的 list

### lines

- 将 string 按照换行符分割返回一个 list

### unlines

- 上面的相反，将各 行 拼成一个 string

### words unwords

- 分割句子为单词 list , 和 将单词 list 合为一个 string

### nub 

- 去重

### delete

- 删除第一个碰到的单词

### \\\

- 求 两个 list 的差集

```haskell
[1..10] \\ [2,5,9]
[1,3,4,6,7,8,10]
```

### union

- 求 两个 list 的并集

```haskell
"hey man" `union` "man what's up"
"hey manwt'sup"
```

### intersect

- 求两个 list 的合集

```haskell
[1..7] `intersect` [5..10]
[5,6,7]
```

### insert

- 将 接收的元素 插入 list, 位置是 第一个碰到的不小于它的元素的前面

```haskell
insert 4 [3,5,1,2,8,2]
[3,4,5,1,2,8,2]
```

### genericTake

### genericLength

### genericDrop

### genericSplitAt

### genericIndex

### genericReplicate

## Data.Char

### isControl

- 查看是否是 control character

### isSpace

- 是不是空白字符串
- 包括非打印字符

### isLower

- 是不是小写

### isUpper

- 是不是大写

### isAlpha

- 是不是字母

### isAlphaNum

- 是不是字母数字

### isPrint

- 是不是打印字符

### isDigit

- 是不是 digit

### isOctDigit

- 是不是 oct digit

### isHexDigit

- 是不是 hex digit

### isLetter

- 是不是 letter

### isMark

- 是不是 unicode mark characters

### isNumber

- 是不是数字

### isPunctuation

- 是不是 punctuation

### isSymbol

- 是不是数学或通货符号

### isSeparator

- 是不是 unicode spaces 和 separators

### isAscii

- 是不是 unicode 的前 128 个字符

### isLatin1

- 是不是 unicode 的前 256 个字符

### isAsciiUpper

- 是不是大写 Ascii

### isAsciiLower

- 是不是 小写 Ascii

### toUpper

- 将字母转为大写

### toLower

- 将字母转为小写

### toTitle

- 转为 title-case

### digitToInt

- 将 char 转为数字

### intToDigit

- 将数字转为 char

### ord, chr

- 字符和其数字相互转换

```haskell
ord 'a'
97
chr 97
'a'
```

## Data.Map

### 基本用法

- 构造

```haskell
phoneBook = [
	("betty", "555-2938"),
  ("betty", "555-2938"),
  ("betty", "555-2938"),
]
```

- 自定义取出函数

```haskell
findKey :: (Eq k) => k -> [(k,v)] -> Maybe v
findKey key [] = Nothing
findKey key ((k,v):xs) = if key == k
														then Just v
														else findKey key xs
														
-- fold 版本
findKey :: (Eq k) => k -> [(k,v)] -> Maybe v
findKey key = foldr (\(k,v) acc -> if key == k then Just v else acc) Nothing
```

- Data.Map 的方法有很多与标准冲突，所以

```haskell
import qualified Data.Map as Map
```



### fromList

- 假如有重复的键则后者会覆盖前者

```haskell
Map.fromList[(1,2),(3,4)]
fromList [(1,2),(3,4)]
```

### empty

- 返回一个空的map

### insert

- 接收 key,value, map

```haskell
Map.insert 3 100 Map.empty
fromList [(3,100)]
```

### null

- 检查一个 map 是不是空的

### size

- 返回 map 的长度

### singleton

- 接收 key value ，然后返回一个只有一个键值对的 Map

```haskell
Map.singleton 3 9
fromList [(3,9)]
```

### lookup

- 根据 key 寻找 value ,找到的话返回 Just ,没找到返回 nothing

### member

- 接收 key map 
- 查看 key 是否存在于 Map

### map , filter

- 跟 list 一样，对 vlaue 生效

### toList

- fromList 的相反

### keys, elems

- 分别返回 key 和 value 的list

### fromListWith

- 类似于 fromList, 但是可以接收一个参数决定面对重复的key的时候怎么做
- 该 function 的参数是两个 val

### insertWith

- 类似于 insert, 但是可以接收一个funciton决定如何处理面对重复key



## Data.Set

### 注意

- set 是有序的，插入删除都比 List快

### 导入模块

```haskell
import qualified Data.Set as Set
```

### fromList

- 将一个list专为Set,

### intersection

- 找到 两个 set 的交集

### defference

- 找到两个 set 的差集

### union

- 找到两个 set 的合集

### null size member empty singleton insert delete

### isSubsetOf

- 检查一个 set 是不是另一个 set 的子集

### map filter

### toList



## Data.Tree.Tree

```haskell
data Tree a = Node { rootLabel :: a, subForest :: Forset a}
type Forest a = [Tree a]
```

- faltten 用于实现 pre-order traversal

```haskell
pictureTree = Node 1 [Node2 [ Node 3 [] , Node 4 [], Node 5 [] ] , Node 6 [] ]

flatten pictureTree 
[1,2,3,4,5,6]
```

- levels 实现 breadth-first traversal

```haskell
levels pictureTree 
[[1],[2,6],[3,4,5]]
```



# 实际应用

## 快排实现

```haskell
quicksort :: (Ord a) => [a] -> [a]
quicksort [] = []
quicksort (x:xs) = 
  let smallerSorted = quicksort (filter (<=x) xs)
      biggerSorted = quicksort (filter (>x) xs)
  in  smallerSorted ++ [x] ++ biggerSorted
```

## 找到 10000 之内能被 3829 整除的最大的数

```haskell
largestDivisible :: (Integral a) => a
largestDivisible = head (filter p [100000, 99999..])
	where p x = x `mod` 3829 == 0
```

## 找到所有二次幂是奇数且二次幂小于 10000 的和

```haskell
sum (takeWhile (<10000) (filter odd (map (^2)[1..])))
```

## On 方法 在 ~By 方法的使用

- Data.Function (on) 方法定义

```haskell
-- 基本作用是将 两个类型相同的参数分别应用一次 g 后再去应用 f
on :: (b -> b -> c) -> (a -> b) -> a -> a -> c
f `on` g = \x y -> f (g x) (g y)
```

- 使用 on 来实现分区

```haskell
let values = [-4.3, -2.4, -1.2, 0.4, 2.3, 5.9, 10.5, 29.1, 5.3, -2.4, -14.5, 2.9, 2.3]
groupBy ((==) `on` (>0)) values
-- 类似于 \x y -> (x>0) == (y>0)
[[-4.3,-2.4,-1.2],[0.4,2.3,5.9,10.5,29.1,5.3],[-2.4,-14.5],[2.9,2.3]]
```

- 使用 on 来实现 自定义排序

```haskell
let xs = [[5,4,5,4,4], [1,2,3], [3,5,4,3], [], [2], [2,2]]
-- 通过 list 的长度来排序
sortBy (compare `on` length) xs
[[],[2],[2,2],[1,2,3],[3,5,4,3],[5,4,5,4,4]]
```

## 实现 Reverse Polish notation

```haskell
import Data.List

solveRPN :: (Num a, Read a) => String -> a
solveRPN = head . foldl foldingFunction [] . words
  -- 使用 pattern match 来实现 不同逻辑
  where foldingFunction (x:y:ys) "*" = (x * y):ys
        foldingFunction (x:y:ys) "+" = (x + y):ys
        foldingFunction (x:y:ys) "-" = (y - x):ys
        -- 碰到普通数字就放到头部
        foldingFunction xs numberString = read numberString:xs
```

