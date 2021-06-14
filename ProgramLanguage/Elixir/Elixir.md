# 基础类型

```elixir
iex> 1          # integer
iex> 0x1F       # integer
iex> 1.0        # float
iex> true       # boolean
iex> :atom      # atom / symbol
iex> "elixir"   # string
iex> [1, 2, 3]  # list
iex> {1, 2, 3}  # tuple
```

- / 会返回 float 类型的结果, 可以使用 div 函数来做除法，并返回 整型
- rem 可以返回余数
- round() 四舍五入 浮点数, trunc() 保留浮点数的整数部分
- 匿名函数的调用需要用.
- string 连接使用 <> 
- 比较两个不同的类型时按以下规则来

```elixir
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

- 当使用模式匹配而又不想给变量重新赋值时，可以使用 ^ 符号

- case 的用法 : case .... do  pattern -> pattern ->

```elixir
case {1,2,3} do
	{1,x,3} when x>0 ->
		"Will match"
	_ ->
		"Would match...."
end
```

- 当case 的 pattern 报错的时候，程序不会报错，只会认为条件不满足罢了
- 匿名函数也可以有关卡

```elixir
f = fn
	x,y when x>0 -> x + y
	x,y -> x * y
end
```

- ? 可以转换出 某个字符的字节码

## 模块

```elixir
defmodule Math do
    # 带 ? 号表示该方法会返回 boolean 值
    def zero?(0) do
        true
    end

    def zero?(x) when is_integer(x) do
        false
    end
end

IO.puts Math.sum(1, 2)
```

- 默认参数

```elixir
defmodule Concat do
    def join(a, b, sep \\ "") do
        a <> sep <> b
    end    
end
```

- 多个默认参数

```
defmodule Concat do
    # 专门用来声明多个默认值
    def join(a, b \\ nil, sep \\ " ")
    # _sep 是被忽略的参数
    def join(a, b, _sep) when is_nil(b) do
        a
    end

    def join(a, b, sep) do
        a <> sep <> b
    end
end

IO.puts Concat.join("Hello", "world")      #=> Hello world
IO.puts Concat.join("Hello", "world", "_") #=> Hello_world
IO.puts Concat.join("Hello")               #=> Hello
```

## 函数

- |> : 管道操作符, 连接多个表达式， 将上一个表达式的结果作为下一个函数的第一个参数传入

```elixir
1..100_000 |> Enum.map(&(&1*3)) |> Enum.filter(odd?) |> Enum.sum
```

# 一些实践

- 可以用ExDoc 去试着生成文档