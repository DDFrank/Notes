## 列表推导

- 格式 :  [X || Qua1, Qua2, Qua3.....]， Qua可以是以下表达式
  - 生成器: Pattern <- ListExpr ListExpr 必须是一个可以得出列表的表达式
  - 位串生成器: BitStringPattern <= BitStringExpr, BitStringExpr 必须是一个能够得出位串的表达式
  - 过滤器: 可以是判断函数也可以是布尔表达式

- 快速排序

```erlang
-module (lib_sort).
-export ([qsort/1]).

qsort([]) -> [];
qsort([Pivot | T]) ->
	qsort([X || X <- T, X < Pivot])
	++ [Pivot] ++
	qsort([X || X <- T, X >= Pivot]).
```

- 毕达哥拉斯三元数组

```erlang
-module (lib_three).
-export ([pythag/1]).

pythag(N) -> 
		[ {A,B,C} ||
			% 返回一个 1到N的所有整数的列表
			A <- lists:seq(1,N),
			B <- lists:seq(1,N),
			C <- lists:seq(1,N),
			% 要满足下面两个条件
			A+B+C =< N,
			A*A + B*B =:= C*C
		].
```

- 回文构词

```erlang
-module (lib_perms).
-export ([perms/1]).

perms([]) -> [[]];
% X -- Y 是列表移除操作符，它从X里移除Y中的元素 
perms(L) -> [[H|T] || H <- L, T <- perms(L -- [H])].
```

## 构建自然顺序的列表

- 总是向列表头部添加元素
- 从 输入列表 的头部提取元素，然后把它们添加到 输出列表的头部，形成结果是与 输入列表 顺序相反的 输出列表
- 如果顺序很重要,就调用 lists:reverse/1 这个高度优化的函数
- 避免违反以上的建议

## 归集器

```erlang
-module (lib_evenodd).
-export ([odds_and_evens2/1]).

odds_and_evens2(L) ->
	odds_and_evens_acc(L, [], []).

odds_and_evens_acc([H|T], Odds, Evens) ->
	case (H rem 2) of
		1 -> odds_and_evens_acc(T, [H|Odds], Evens);
		0 -> odds_and_evens_acc(T, Odds, [H|Evens])
	end;
% 空列表说明奇偶已经分配完毕
odds_and_evens_acc([], Odds, Evens) ->
	{lists:reverse(Odds), lists:reverse(Evens)}.
```

- 只遍历了一次列表，就找到了奇数列表和偶数列表

## 记录

- 记录其实就是元组的另一种形式

### 何时使用

- 当你可以用一些预先确定且数量固定的原子来表示数据时
- 当记录里的元素数量和元素名称不会随时间而改变时
- 当存储空间是个问题时，典型的案例是有一大堆元组，而且每个元组都有相同的结构。

### 语法

```erlang
-record(Name, {
    %% 以下两个 key 带有默认值
    key1 = Default1,
    key2 = Default2,
    ...
    %% 下一行相当于 key3 = undefinded
    key3,
    ...
}).
```

- key1,kye2 是记录各个字段的名称，必须是原子
- 每个字段都可以有一个默认值

### 更新和创建

- #Name{} 就可以创建。没有指定的字段使用默认值
-  X1#todo : 复制一个类型为 todo 的纪录 X1 ,也就是创建X1 的副本

###  提取

- 可以使用模式匹配来提取 #todo{who=W, text=Txt} = X2. W 和 Txt 就是提取的值
- 也可以使用 点语法: X2#todo.text

### 赋值

- 直接使用 = 号即可

## 映射组

### 何时使用

- 当键不能预先知道时用来表示 键-值数据结构
- 当存在大量不同的键时用来表示数据
- 当方便使用很重要而效率无关紧要时作为万能的数据结构
- 用作 “自解释型” 的数据结构，也就是说，用户容易从键名猜出值的含义;
- 用来表示 键 - 值解析树，比如 XML 或配置文件
- 用 JSON 和其它编程语言通信。

### 语法

```erlang
#{key1 op val1, key2 op val2, ..., keyn op valn}
```

- op 是 => 或 := 两个符号中的一个
  - 用于更新时， => 要么将现有键 的值更新为新值，要么添加一个全新的 键值对
  - 用于更新时, := 将现有键的值更新为新值，如果现有键不存在，那就报错
  - 所以新增的时候使用 => , 更新的时候使用 := 为最佳实践
- 键和值可以是任何有效的 Erlang 数据类型
- 映射组在系统内容是作为有序集合存储的，打印时总是使用各键排序后的顺序
- 键不能包含未绑定变量，但是值可以包含未绑定变量(在模式匹配成功后绑定)。
- 模式匹配取值只能使用 :=

### 模式匹配映射字段

```erlang
-module (count_characters).
-export ([count_characters/1]).

count_characters(Str) ->
	count_characters(Str, #{}).

count_characters([H|T], X) ->
	% 判断 H 是否是 X的key 
	case maps:is_key(H,X) of
		% 键不存在的话，添加，并将出现次数置为1
		false -> count_characters(T, X#{ H => 1});
		% 键存在的话，先模式匹配一下获取 Count 数
		true -> #{ H := Count } =X,
			count_characters(T, X#{ H := Count+1 })
	end;
count_characters([], X) ->
	X.
```

### 操作映射组的内置函数

- maps:new() -> #{} :返回一个新的空映射组
- erlang: is_map(M) -> bool() : 判断M是否是映射组
- maps: to_list(M) -> [{K1,V1},....,{Kn,Vn}] : 把映射组里的键值对转换为一个键值列表。键升序排列
- maps: from_list([{K1,V1},...,{Kn,Vn}]) -> M ：把一个包含键值对的列表转换成映射组M。如果同样的键不止一次出现，使用第一次出现的值，后续都忽略
- maps:map_size(Map) -> NumberOfEntries
- maps:is_key(Key,Map) -> bool()
- maps:get(Key, Map) -> Val :找不到会报错
- maps:find(Key,Map) -> {ok, Value} | error : 找不到返回 error
- maps:keys(Map -> [key1..keyn]) : 返回映射组所包含的键列表，按升序排列
- maps:remove(Key, M) -> M1 : 返回一个删除了指定键值对的新的映射组
- maps:without([key1,...keyn], M) -> M1 ； 返回删除了指定键值对的新映射组
- maps: difference(M1,M2) -> M3 : 返回 在M1和M2的差集的映射组

### 和JSON之间互换

- maps:from(Bin) -> Map: 把一个包含JSON数据的二进制型转换为映射组
- maps:safe_from_json(Bin) -> Map:  Bin内的任何原子必须事先存在，不然就会报错

- 上面定义的 Map 必须是 json_map() 类型的实例

```erlang
-type json_map = [{json_key(), json_value()}].
-type json_key() = 
	atom() | binary() | io_list().
-type json_value() =
	integer() | binary() | float() | atom() | [json_value()] | json_map()
```

# 错误处理

## 抛出错误

- exit(Why) : 想要终止进程时抛出
- throw(Why) : 抛出一个调用者可能想要捕捉的异常错误
- error(Why): 指示崩溃性错误，跟系统内部生成的错误差不多

## try...catch 捕捉异常

```erlang
-module (try_test).
-export ([demo1/0]).

generate_exception(1) -> a;
generate_exception(2) -> throw(a);
generate_exception(3) -> exit(a);
generate_exception(4) -> {'EXIT', a};
generate_exception(5) -> error(a).

demo1() ->
	[catcher(I) || I <- [1,2,3,4,5]].

catcher(N) ->
    % 表达式
	try generate_exception(N) of
        % 没抛出异常就执行这个
		Val -> {N, normal, Val}
	catch
        % 抛出异常在这里进行匹配
		throw:X -> {N, caught, thrown, X};
		exit:X -> {N, caugtht, exited, X};
		error:X -> {N, caught, error, X}
    %after 可以在这里写一定会执行的表达式
    % AfterExpressions                
	end.
```

- 返回值可以忽略

## 用catch 捕捉异常错误

- 异常错误如果发生在 catch 语句里，就会被转换成一个描述此错误的 {'EXIT', ...} 元祖

```erlang
-module (catch_test).
-export ([demo1/0]).

generate_exception(1) -> a;
generate_exception(2) -> throw(a);
generate_exception(3) -> exit(a);
generate_exception(4) -> {'EXIT', a};
generate_exception(5) -> error(a).

demo1() ->
	[catch generate_exception(I) || I <- [1,2,3,4,5]].

```

- 输出结果会提供丰富的堆栈调试信息

## 通常的异常处理方式

### 改进错误消息

- error/1 的一种用途是改进错误消息的质量

```erlang
-module (error_test).
-export ([sqrt/1]).

sqrt(X) when X <0 ->
	error({squareRootNegativeArgument, X});
sqrt(X) ->
	math:sqrt(X).
```

- 提供更多的错误消息

### 经常返回错误时的代码

好像没什么用

### 错误可能有但罕见时的代码

- 通常要编写能处理偶无的代码(try ... catch)

### 捕捉一切可能的异常错误

- 使用 _ 来捕捉一切可能的错误

```erlang
try Expr
catch
	_:_ -> ...... 具体的处理代码...
end.
```

## 栈跟踪

- 使用 erlang:get_stacktrace() 来找到最近的堆栈跟踪信息

## 操作二进制型

- list_to_binary(L) -> B ： 将列表的元素扁平化后形成
- split_binary(Bin, Pos) -> {Bin1, Bin2} : 在pos处将Bin 一分为二
- term_to_binary(Term) -> Bin : 能将任何Erlang 数据类型转换为一个二进制型
- binary_to_term(Bin) -> Term : 上面的逆向
- byte_size(Bin) -> Size :返回字节数

## 位语法表达式

- 位语法表达式被用来构建二进制型或位串。

```
<< E1, E2, ...., En >>
```

- 每个 Ei 元素都标识出二进制型或位串里的一个片段。每个 Ei 元素可以有四种形式
  - Value |
  - Value: Size |
  - Value/TypeSpecifierList |
  - Value:Size/TypeSpecifierList
- 如果表达式的总位数是 8 的倍数，就会构建一个二进制型，否则构建一个位串。

### Value

- Value 必须是已绑定变量，字符串，或是能得出整数，浮点数或二进制型的表达式。
- 当被用于模式匹配操作时，Value可以是绑定或未绑定的变量，整数，字符串，浮点数或二进制型。

### Size

- 必须是一个能得出整数的表达式
- 模式匹配里，Size必须是一个整数，或者是值为整数的已绑定变量。
- 二进制型里某个 Size 的值可以通过之前的模式匹配获得
- Size的值指明了片段的大小。默认值取决于不同的数据类型
  - 整数 ； 8
  - 浮点数: 64
  - 二进制型 : 该二进制型的大小

### TypeSpecifierList

- 形式为 End-Sign-Type-Unit.顺序无关，省略会使用默认值
- End : 指机器的字节顺序
  - big : 默认值
  - little
  - native: 运行时根据机器的CPU来确定 

- Sign : 只用于模式匹配
  - signed:
  - unsigned : 默认值
- Type
  - integer 默认值
  - float
  - binary
  - bytes
  - bitstring
  - bits
  - utf8
  - utf16
  - utf32
- Unit : 写法是 unit:1|2|...256
  - integer. float和bitstring 的默认值是 1
  - binary :8
  - utf8,utf16和utf32 无需提供

## 位串: 处理位级数据

位推导的语法 自行了解

## apply

- 是一个内置函数
- 语法: apply(Mod, Func, [arg1,arg2,.....,argn])
- apply 能调用某个模块的某个函数，并传递参数
- 与直接调用函数的区别在于模块名或函数名可以是动态的
- 内置函数都是基于 erlang 模块的，因而也可以调用
- 应当尽量少用

## 算术表达式



## 属性

- 模块属性的语法是 -AtomTag(...), 被用来定义文件的某些属性

### 预定义的模块属性

必须放在任何函数定义之前

- -module(modname): 模块声明
  - modname : 必须是一个原子。此属性必须是文件里的第一个属性
- -import(Mod, [Name1/Arity1, Name2/Arity2,....]): 声明列举了哪些函数需要导入到模块中。
  - 一旦导入后，调入的时候就无需指定模块名了
- -export([Nam1/Arity1, Name2/Arity2,....]).
- -compile(Options) : 添加 Options 到编译器选项列表中,可以是单个选项，也可以是一个编译器选项列表
- -vsn(Version). 指定模块的版本号，没有什么特别的语法含义

### 用户定义的模块属性

- -SomeTag(Value) 
  - SomeTah 必须是一个原子，Value必须是一个字面数据类型
  - 模块属性的值会被编译进模块，可以在运行时提取
  - 可以使用 module_info(attributes) 来导出定义的属性

## 块表达式

- begin ... end 整合多个表达式为一个

## 包含文件

- -include(Filename) 
  - Filename 应当包含一个绝对或相对的路径，使预处理器能找到正确的文件
- -include_lib(Name)
  - 包含库的头文件

## 列表操作

- A ++ B 是使 A和B相加
- A -- B 是从列表A中移除列表B
  - 如果符号 X 在B里只出现了K次，那么A只会移除前K个X。
- 这些都是右结合的

```erlang
[1,2,3] -- [1,2] --[3].
%% [3]
```



## 宏

### 语法

- -define(Constant, Replacement).
- -define(Func(Var1, Var2,..., Var), Replacement).
- 当预处理器碰到一个 ?MacroName 形式的表达式的时候，就会展开这个宏。宏定义里出现的变量会匹配对应宏调用为止的完整形式。

```erlang
-define(macro1(X,Y), {a, X,Y}).

foo(A) -> 
    ?macro1(A+10, b)
%% 展开后就是
foo(A) ->
    {a, A+10, b}.
```



### 预定义宏

- ?FILE 展开当前的文件名
- ?MODULE 展开成当前的模块名
- ?LINE 展开成当前的行号

### 宏控制流

模块的内部支持下列指令，可以用其来控制宏的展开

- -undef(Macro). : 取消宏的定义，此后就无法调用该宏
- -ifdef(Macro). : 仅当Macro 有过定义时才执行后面的代码
- -ifndef(Macro). : 仅当Macro未被定义时才执行后面的代码
- -else. : 可用于 ifdef 或 ifndef 语句之后。如果条件为否， else 后面的语句就会被执行
- -endif. : 标记 ifdef 或 ifndef 语句的结尾

```erlang
-module (m1).
-export ([loop/1]).


-ifdef(debug_flag).
% 假如有 debug_flag ,就打印这种语句, 编译的时候设置 debug_flag
-define(DEBUG(X), io:format("DEBUG ~p:~p ~p~n", [?MODULE, ?LINE, X])).
-else.
% 假如没有，就啥也不干
-define(DEBUG(X), void).
-endif.

loop(0) ->
	done;
loop(N) ->
	?DEBUG(N),
	loop(N-1).

% 启动 debug 的编译 : c(m1, {d, debug_flag})
```

## 数字

### 整数

整数的运算时精确的，而且用来表示整数的位数只受限于可用的内存.

- 传统，大家都知道的
- K进制整数 : K#Digits 这种写法, 最高的进制数是 36
- $ 写法 : $C 代表了 ASCII字符C的整数代码，比如 $a 是 97 的简写

### 浮点数

由五部分组成

- 可选的正负号
- 整数部分
- 小数点
- 分数部分
- 可选的指数部分

## 进程字典

每个 Erlang 进程都有一个 进程字典的私有数据存储区域，由键值对组成，每个键对应一个值

- put(Key, Value) -> OldValue ；返回旧值，没有的话返回 undefined
- get(Key) -> Value. 
- get() -> [{Key, Value}]. 返回整个字典
- get_keys(Value) -> [Key] : 返回一个列表，内含字典里所有值为Value的键。
- erase(Key) -> Value : 返回 Key 的关联值，然后删除 key 的关联值
- erase() -> [{Key,Value}]: 删除整个字典并返回

- 进程字典应当尽量少使用

## 比较数据类型

- 尽量使用 =:= ,少用 ==
- == 只有在比较浮点数和整数时才有用

### 类型之间的大小比较

number < atom < reference < fun < port < pid < tuple < list < bit string



## 类型

```erlang
-module (walks).
-export ([plan_route/2]).

% 如果调用 plan_route/2 函数的时候使用了两个类型为 point() 的参数时，
% 此函数就会返回一个类型 route() 的对象.
-spec plan_route(From :: point(),To :: point()) -> route().
% 引入一个名为 direction() 的新类型，它的值时下列原子之一 : north,south,east,west
-type direction() :: north | south | east | west.
% ponit() 类型是一个包含两个整数的元组
-type point() :: {integer(), integer()}.
% route() 类型定义为一个三元组构成的列表,每个元组都包含一个原子 go, 一个类型为 direction 的对象和一个整数
-type route() :: [{go, direction(), integer()}].
```

### 语法

#### 非正式语法:

- T1 :: A | B | C....
- 意思是 T1 被定义为 A, B 或 C 其中之一。

#### 定义新的类型

- -type NewTypeName(TVar1, Tvar2, ... TvarN) :: Type

- TVar1 至 TVarN 是可选的类型变量, Type 是一个类型表达式

#### 预定义类型

- -type term() :: any().
- -type boolean() :: true | false.
- -type byte() :: 0..255.
- -type char() :: 0..16#10ffff.
- -type number() :: integer() | float().
- -type list() :: [any()].
- -type maybe_improper_list() :: maybe_improper_list(any(), any()).
  - 指定带有非空最终列表尾的列表类型。比较少用
- -type maybe_improper_list(T) :: may_improper_list(T, any()).
- -type string() :: [char()].
- -type nonempty_string() :: [char(),...].
- -type iolist() :: maybe_improper_list(byte() | binary() | iolist(), binary() | []).
- -type module() :: {atom(), atom(), atom()}.
- -type node() :: atom().
- -type timeout() :: infinity | non_neg_integer().
- -type no_return() :: none().

### 指定函数的输入输出类型

#### 语法

-spec functionName (T1, T2, ..., Tn) -> Tret when

​	Ti :: Typei,

​	Tj :: Typej,

​	....

-  T1 ,T2 .... 表示函数的参数类型
- Tret 表示函数的返回值
- when 是可选的, 可以用来引入额外的类型变量

### 导出类型和本地类型

- 使用 -export_type 导出类型

```erlang
-export_type([rich_text/0, font/0]).
```

- 在别的模块使用全限定名来使用

```erlang
-spec rich_text_length(a:rich_text()) -> integer().
```

### 不透明类型

```erlang
-opaque rich_text() :: [{font(), char()}].
```

- 不透明一味着其它模块在使用的时候不应该知道其内部结构

# 编译和运行程序

### .erlang 文件

- 在 erl 下可以通过 init:get_argument(home). 找到系统的主目录
- 在主目录下 的 .erlang 文件的代码会在 erlang 启动时执行

### 编译代码

- 在 shell 里可以用 c 来编译
- 可以在命令行里编译和运行

```shell
erlc hello.erl

# -s 调用 apply(M,F) 函数
erl -noshell -s hello start -s init stop
```

- 作为 Escript 执行

```erlang
#!/usr/local/bin escript

main(Args) ->
  io:format("Hello world~n").
```

# 并发编程

- 创建和销毁进程是非常快速的
- 在进程之间发送消息是非常快速的
- 进程在所有的操作系统上都具有相同的行为方式
- 可以拥有大量进程
- 进程完全不共享内存
- 进程之间唯一的交互方式是消息传递

## 基本函数

### Pid = spawn(Mod, Func, Args).

- 创建一个新的并发进程来 apply(Mod, Func, Args)。
- 该进程和调用进程并行
- 可以利用 返回的 Pid 来给进程发送消息
- Func函数必须从 Mod 模块导出

### Pid = spawn(Fun)

- 创建一个新的并发进程来执行 Fun()。
- 总是使用被执行 fun 的当前值，所以无需导出

### Pid!Message

- 向标识符为 Pid 的进程发送消息Message。
- 消息发送是异步的
- Pid1!Pid2!Pid3!M 是说把消息M发送给 Pid1 Pid2 Pid3

### Receive .... end

- 接收发送给某个进程的消息

```erlang
receive
	Pattern1 [when Guard1] ->
		Expressions1;
	Pattern2 [when Guard2] -> 
		Expressions;
	...
end
```

- 当某个消息到达进程后，系统会尝试将其与 Pattern1 匹配
- 简单服务器/客户端 例子

```erlang
-module (area_server_final).
-export ([start/0, area/2, loop/0]).

% 开始一个进程，并无限循环监听
start() -> spawn(area_server_final, loop, []).
% 客户端调用的API
area(Pid, What) ->
	rpc(Pid, What).
	
rpc(Pid, Request) ->
	Pid ! {self(), Request},
	receive
		% 绑定发送消息的 Pid, 避免响应收到其它无关的消息
		{Pid, Response} ->
			Response
	end.
% 无限循环的服务端
loop() ->
	receive
		{From, {rectangle, Width, Ht}} ->
			% 回复消息,指定是由本进程回复的
			From ! {self(), Width*Ht},
			loop();
		{From, {circle, R}} ->
			From ! {self(),3.14159 * R * R},
			loop();
		{From, Other} ->
			% 对其它任何消息回复错误
			From ! {self(), {error, Other}},
			loop()
	end.
```

### 带超时的接收

```erlang
receive
	Pattern1 [when Guard1] ->
		Expressions1;
	Pattern2 [when Guard2] ->
		Expressions2;
	...
% 超过该毫秒数进程会停止等待，执行 Expressions
after Time ->
	Expressions
end
```

### 只带超时的接收

- 可以通过这种方式让进程 sleep 一会

### 超时值为0

- 超时值为0 会让(超时)主体部分立即发生, 在这之前，系统会尝试对邮箱里的消息进行匹配

### 超时值为无穷大

- 如果是原子 infinity ,那么永远不会触发超时

### 实现一个定时器

```erlang
-module (stimer).
-export ([start/2, cancel/1]).

start(Time, Fun) -> spawn(fun() -> timer(Time, Fun) end).
% 用来取消定时器
cancel(Pid) -> Pid ! cancel.
% 设定定时器
timer(Time, Fun) ->
	receive
		cancel -> 
			void
	% 超时后执行真正需要的逻辑
	after Time ->
			Fun()
	end.
```

### 注册进程

- Erlang 中有能与任何进程都通信的进程，称为注册进程，其API如下
  - register(AnAtom, Pid)
    - 用 AnAtom(一个原子) 作为名称来注册进程 Pid。如果 AnAtom 已被用于注册某个进程，这次注册就失败了
    - 也就是说，注册之后，就可以通过 这个注册的原子名 AnAtom 来通信
  - unregister(AnAtom)
    - 移除与 AnAtom 关联的所有注册信息
  - whereis(AnAtom) -> Pid|undefined
    - 检查AnAtom是否注册。如果是就返回进程标识符
  - registered() -> [AnAtom::atom()]
    - 返回一个包含系统里所有注册进程的列表

### 并发编程模板

```erlang
-module(ctemplate).
-compile(export_all).

start() ->
  spawn(?MODULE, loop, []).

rpc(Pid, Request) ->
  Pid ! {self(), Request},
  receive
    {Pid, Response} ->
      Response
  end.

loop(X) ->
  receive
    Any ->
      io:format("Received:~p~n", [Any]),
      loop(X)
  end.
```



### 动态升级

- 如果能够确保 程序在未来不会修改，那么使用 spawn(Fun)
- 如果不，需要动态升级，使用 spawn(MFA)



## 错误处理

### 名词解释

- 进程: 分为普通和系统。 spawn 创建的是普通进程。
  - 普通进程可以通过执行内置函数 process_flag(trap_exit, true) 变成系统进程
- 连接: 进程可以相互连接
  - 假如A B进程相互连接，A终止了，就会向B发出一个错误信号
- 连接组: 进程P的连接组是指与P相连的一组进程
- 监视: 跟连接很像，但是是单向的
- 消息和错误信号: 进程协作的方式是交换消息或错误信号。
  - 消息通过 send 函数发送
  - 进程崩溃或终止时会发送错误信号给连接组
- 错误信号的接收
  - 收到时，会被转换为 {'EXIT', Pid, Why} 形式的消息
  - 如果进程是无错误终止， Why是原子 normal
  - 普通进程收到错误信号时，如果退出原因不是normal，那么它也会终止，且向连接组发送退出信号
- 显式错误信号: 任何执行 exit(Why) 的进程都会终止（代码不是在 catch 或 try的范围内），并向其连接组广播退出信号
- 不可捕捉的退出信号: 调用 exit(Pid, kill)
  - 这种信号会绕过常规的错误信号处理机制，不会被转换为消息
  - 只应该用在其它错误处理机制无法终止的顽固进程上。

### 基本错误处理函数

- -spec spawn_link(Fun) ->Pid
- -spec spawn_link(Mod, Fnc, Args) -> Pid
  - 类似于 spwan 函数的两个，同时还会在父子进程之间创建连接

- -spec spawn_monitor(Fun) -> {Pid, Ref}
- -spec spawn_monitor(Mod, Func, Args) -> {Pid, Ref}
  - 创建的是监视而非连接
  - Pid 是新创建进程的进程标识符
  - Ref 是该进程的引用
- -spec process_flag(trap_exit, true)
  - 会把当前进程转变为系统进程，系统进程是一种能接收和处理错误信号的进程
- -spec link(Pid) -> true
  - 会创建一个与进程Pid 的连接
  - 进程不存在的话抛出一个 noproc 退出异常
- -spec unlink(Pid) -> true
  - 会移除当前进程和进程Pid 之间的所有连接
- -spec monitor(process, item) -> Ref
  - 会设立一个监视。Item可以是进程的Pid, 也可以是它的注册名称。
- -spec demonitor(Ref) -> true
  - 会移除以Ref作为引用的监视
- -spec exit(Why) -> none()
  - 会使当前进程因为 Why的原因终止。
  - 如果执行这一语句的子句不在 catch 语句的范围内，此进程就会向当前连接的所有进程广播一个带有参数 Why 的退出信号
  - 会向所有监视它的进程广播一个DOWN消息
- -spec exit(Pid, Why) -> true
  - 它会向进程Pid发送一个带有原因Why 的退出信号
  - 执行这个函数的进程本身不会终止，所以可以用来伪造退出信号

### 容错式编程

```erlang
-module(exit_monitor).
-export([on_exit/2, keep_alive/2]).

%% 会监视进程Pid, 如果它因为原因Why退出了，就会执行 Fun(Why)。
on_exit(Pid, Fun) ->
  spawn(fun() ->
		%% 对 Pid 创建了一个监视。
		Ref = monitor(process, Pid),
		receive
			%% 当该进程终止时，监视进程就会接收一个DOWN消息
			{'DOWN', Ref, process, Pid, Why} ->
				%% 并调用 Fun(Why)
				Fun(Why)
		end
	end).

%% 生成一个名为Name 的注册进程，并执行 spawn(Fun)。如果该进程出于任何原因挂了，就会被重启。
keep_alive(Name, Fun) ->
	register(Name, Pid = spawn(Fun)),
	on_exit(Pid, fun(_Why) -> keep_alive(Name, Fun) end).
```

# 分布式编程

## 两种分布式模型

### 分布式 Erlang

```erlang
-module(dist_demo).
-export([rpc/4, start/1]).
%% 创立远程节点
start(Node) ->
  spawn(Node, fun() -> loop() end).

rpc(Pid, M, F, A) ->
  Pid ! {rpc, self(), M, F, A},
  receive
    {Pid, Response} ->
      Response
  end.

loop() ->
  receive
    {rpc, Pid, M, F, A} ->
      Pid!{self(), (catch apply(M, F, A))},
      loop()
  end.
```



### 基于套接字的分布式模型

## 分布式编程的库和内置函数

查看 官网的编程手册



### cookie 保护系统

- 每个节点都有一个 cookie, 如果想与其它节点通信，它的cookie 就必须和对方节点的 cookie 相同
- 分布式Erlang 系统里的所有节点都必须以相同的 cookie启动，或者通过执行 erlang:set_cookie 把它们的 cookie 修改成相同的值
- Erlang 集群的定义就是一组带有相同 cookie 的互连节点

- 设置相同cookie 的三种方法
  - 在 $HOME/.erlang.cookie 里存放相同的 cookie
  - erl 启动时，使用命令行参数 -setcookie C 来把 cookie 设成 C
  - 内置函数 erlang:set_cookie(node(), C) 能把本地节点的 cookie 设成原子C



# 文件编程

## 操作文件的模块

- file : 包含打开，关闭，读取和写入文件的方法，还有列出目录等
- filename: 该模块的方法能够以跨平台的方式操作文件名，可以保证在不同的操作系统上运行相同的代码
- filelib: file模块的拓展。包含许多有用的工具函数
- io: 该模块有一些操作已打开文件的方法。它包含的方法能够解析文件里的数据，或者把格式化的数据写入文件。

## 读取文件的几种方法

### 读取文件里的所有数据类型

- file:consult(File)

假定 File 包含一个由 erlang 数据类型组成的序列。如果能读取文件的所有数据类型，就会返回 {ok, [Term]}, 否则返回{error, Reason}。

### 分次读取文件里的数据类型

- file:open 打开文件

file:open(File, read) -> {ok, IoDevice} | {error, Why}

- io:read 逐个读取数据类型，知道文件末尾

io:read(IoDevice, Prompt) -> 

​	{ok, Term} | 

​	{error, Why} | 

​	eof :  文件 已经读完了

- file: close 关闭文件

### 分次读取文件里的行

io:get_line: 会一直读取字符，直到遇上换行符或者文件尾

### 读取整个文件到二进制型中

file:read_file(File) 把整个文件读入一个二进制型，这是一个原子操作

这是最为高效的文件读取方式

### 通过随机访问读取文件

如果要读取的文件非常大，或者包含某种外部定义格式的二进制数据，就可以用 raw 模式打开这个文件

然后用 file:pread 读取它的任意部分。

file:pread(IoDevice, Start, Len) ：会从 IoDevice 读取 Len 个字节的数据，读取起点是字节Start处(文件里的字节会被编号，所以文件里第一个字节的位置是0)。会返回 {ok, Bin} 或者 {error, Why}。



## 写入文件的各种方式

### 把数据列表写入文件

```erlang
-module (lib_misc).
-export ([unconsult/2]).

unconsult(File, L) ->
	% 以 write 模式打开
	{ok, S} = file:open(File, write),
	% 调用 io:format(S, "~p.~n", [X]) 来把数据类型写入文件
	lists:foreach(fun(X) -> io:format(S, "~p.~n", [X]) end, L),
	file:close(S).
```

- io:format(IoDevice, Format, Args) -> ok
  - ioDevice : I/O对象（以 write 模式打开）
  - Format : 是一个包含格式代码的字符串
  - Args : 待输出的项目列表。每一项都必须符合格式字符串里的某个格式命令。格式命令以一个波浪字符(~)开头
    - ~n 输出一个换行符
    - ~p 把参数打印为美观的形式
    - ~s 参数是一个字符串, I/O列表或原子，打印时不带引号。
    - ~w 用标准语法输出数据。它被用于输出各种Erlang 数据类型。
    - 还存在大量的格式字符串需要查询手册

### 把各行写入文件

也是使用 io:format 方法

### 一次性写入整个文件

最高效的写入文件方式

file:write_file(File, IO) 会把IO里的数据写入File

```erlang
-module (scavenge_urls).
-export([urls2htmlFile/2, bin2urls/1, gather_urls/2]).
-import (lists, [reverse/1, reverse/2, map/2]).

% 接受一个URL列表并创建HTML文件,在文件里为每个URL创建一个可点击链接
urls2htmlFile(Urls, File) ->
	% 使用 该方法时 I/O系统会自动扁平化列表
	file:write_file(File, urls2html(Urls)).

% 遍历一个二进制型，然后返回一个包含该二进制型内所有URL的列表
bin2urls(Bin) -> gather_urls(binary_to_list(Bin), []).
% 生成 h1 标题和一个有序列表
urls2html(Urls) -> [h1("Urls"), make_list(Urls)].
% 生成一个 h1 的标题
h1(Title) -> ["<h1>", Title, "</h1>\n"].
% 生成有序列表
make_list(L) ->
	[
		"<ul>\n",
		map(fun(I) -> ["<li>", I, "</li>\n"] end, L),
		"</ul>\n"
	].
% <a href ++ T， T为 href 之后的剩下的列表
gather_urls("<a href" ++ T, L) ->
	% reverse 也会返回一个列表
	{Url, T1} = collect_url_body(T, reverse("<a href")),
	gather_urls(T1, [Url|L]);
% 匹配到这个说明该项里没有 <a href 的字符串，所以就直接遍历下一个项
gather_urls([_|T], L) ->
	gather_urls(T, L);
% 匹配到这个说明已经没用数据了，就直接返回列表
gather_urls([], L) ->
	L.

% 这里的T是</a> 之后剩下的文本,
% 这里的L 已经是一个倒着的 <a href 了，所以就翻转一下顺序再补一个 </a>
collect_url_body("</a>" ++ T, L) -> {reverse(L, "</a>"), T};
% 这里的L一开始为倒着的 <a href,即上面传递的参数
% [H|T] 为剩下的列表，假如无法匹配 </a>, 就将H 拼在L前面
% 重复该行为直到能匹配到 </a>
collect_url_body([H|T], L) -> 
	collect_url_body(T, [H|L]);
collect_url_body([], _) -> {[], []}.
```

### 写入随机访问文件

- 在随机访问模式下写入某个文件和读取它很相似。
- 必须用 write 模式打开这个文件
- 使用 file:pwrite(IoDev, Position, Bin) 写入文件



## 目录和文件操作

- file:list_dir(Dir) 用来生成一个 Dir里的文件列表
- make_dir(Dir) 创建一个新目录
- del_dir(Dir) 删除一个目录

### 查找文件信息

- file:read_file_info(F)
- 如果F是合法的文件或目录名，会返回 {ok, Info}
- Info 是一个 #file_info 类型的纪录
- 具体查文档

### 复制和删除

- file:copy(Source, Destination)
- file:delete(File)

## 一个查找工具函数

```erlang
-module (lib_find).
-export ([files/3, files/5]).
-import (lists, [reverse/1]).

-include_lib ("kernel/include/file.hrl").

% 简易版本
files(Dir, Re, Flag) -> 
	Rel = xmerl_regexp:sh_to_awk(Re),
	% 处理函数的意思是找到文件就放到列表中去
	reverse(files(Dir, Rel, Flag, fun(File, Acc) -> [File|Acc] end, [])).


% Dir : 文件搜索的起点
% RegExp : shell风格的正则表达式
% Recursive = true | false : 搜索是否应该层层深入当前搜素目录的子目录
% Fun(File, AccIn) -> AccOut : 如果 regExp 匹配 File, 这个函数就会被应用到 File上。
%% Acc 是一个初始值为Acc0 的归集器。Fun在每次调用后必定会返回一个新的归集值，这个值
%% 在下次调用 Fun 时会传递给它。归集器最终的值就是函数的返回值
files(Dir, RegExp, Recursive, Fun, Acc) ->
	% 查找一个文件夹下的所有文件名
	case file:list_dir(Dir) of
		{ok, Files} -> find_files(Files, Dir, RegExp, Recursive, Fun, Acc);
		{error, _} -> Acc
	end.

	% File 从文件列表里找到的第一个文件
	find_files([File|T], Dir, Reg, Recursive, Fun, Acc0) ->
		% 将文件路径和文件名合并为一个字符串
		FullName = filename:join([Dir, File]),
		% 判断文件是文件夹还是一般的文件
		case file_type(FullName) of
			% 假如是普通的文件的话
			regular ->
				% 执行正则表达式的匹配
				case re:run(FullName, Reg, [{capture, none}]) of
					% 假如匹配上了
					match -> 
						% 调用回调,并将回调的返回值作为参数继续传递下去
						Acc = Fun(FullName, Acc0),
						find_files(T, Dir, Reg, Recursive, Fun, Acc);
					nomatch ->
						find_files(T, Dir, Reg, Recursive, Fun, Acc0)
				end;
			% 假如是文件夹的话
			directory ->
				case Recursive of
						% 假如需要则继续深入搜索
						true ->
							Acc1 = files(FullName, Reg, Recursive, Fun, Acc0),
							find_files(T, Dir, Reg, Recursive, Fun, Acc1);
						false ->
							find_files(T, Dir, Reg, Recursive, Fun, Acc0)
				end;
			error ->
				find_files(T, Dir, Reg, Recursive, Fun, Acc0)
		end;
	% 当文件夹已经没用文件时就返回归集器
	find_files([], _, _, _, _, A) ->
		A.

	% 判断文件类型
	file_type(File) ->
		case file:read_file_info(File) of
			{ok, Facts} ->
				case Facts#file_info.type of
					% 常规文件
					regular -> regular;
					% 文件夹
					directory -> directory;
					_ -> error
				end;
			_ ->
				error
		end.
```



# 用WebSocket 和 Erlang 进行浏览 

待补完



# 用ETS和DETS存储数据

- ETS : Erlang 数据存储
  - 常驻内存
- DETS : 磁盘ETS
  - 常驻磁盘
- ETS或DETS就是Erlang元组的集合

## 表的类型

### 异键表

- 表里所有的键都是唯一的

### 有序异键

- 元组会被排序

### 同键表

- 允许多个元素拥有相同的键
- 不允许完全相同的元组

### 副本同键表

- 可以用多个元组拥有相同的键
- 同一张表里可以存在多个相同的元组

### 基本操作

- 创建一个新表或打开现有的表
  - ets:new
  - dets:open_file
- 向表里插入一个或多个元组
  - insert(TableID, X), 其中X是一个元组或元组列表。ETS 和 DETS 是一样的。
- 在表里查找某个元组
  - lookup(TableID, Key)。得到的结果是一个匹配 Key 的元组列表。ETS  和 DETS 中均有定义
  - lookup 的返回值始终是一个元组列表，这样就能对异键表和同键表使用同一个查找函数
    - 表的类型是同键，那么多个元组可以拥有相同的键
    - 表的类型是异键，那么查找成功后的列表里只会有一个元素
- 丢弃某个表
  - dets:close(TableId)
  - ets:delete(TableId)

```erlang
-module (ets_test).
-export ([start/0]).

start() ->
	lists:foreach(fun test_ets/1, [set, ordered_set, bag, duplicate_bag]).

test_ets(Mode) ->
	TableId = ets:new(test, [Mode]),
	ets:insert(TableId, {a, 1}),
	ets:insert(TableId, {b, 2}),
	ets:insert(TableId, {a, 1}),
	ets:insert(TableId, {a, 3}),
	% 将表转为list
	List = ets:tab2list(TableId),
	io:format("~-13w => ~p~n", [Mode, List]),
	ets:delete(TableId).


```

## 影响ETS表效率的因素

- 尽可能用二进制型来表示字符串和大块的无类型内存

## 创建一个ETS表

- ets:new(Name, [Opt]) -> TableId
- Name 是一个原子
- [Opt] 是一列选项
  - set | ordered_set | bag | duplicate_bag (表的类型)
  - private : 创建一个私有表，只有主管进程才能读取和写入它
  - public : 创建一个公共表，任何直到此表标识符的进程都能读写它
  - protected: 创建一个受保护表，读是公共的，但写只有主管进程能写
  - named_table : 如果设置了该选项，Name 就可以被用于后续的表操作
  - {keypos, k} : 用K作为键的位置。通常键的位置是1。基本上唯一需要使用这个选项的场合是保存 Erlang 记录,并且记录的第一个元素包含记录名的时候
  - 默认是 [set, protected, {keypos, 1}]
- 创建表的进程被称为该表的主管，创建表时所设置的一组选项在以后是无法更改的.
- 如果主管进程挂了，表空间就会被自动释放

## 创建一个Dets 表

```erlang
-module (lib_filenames_dets).
-export ([open/1, close/0, test/0, filename2index/1, index2filename/1]).

open(File) ->
	io:format("dets opened:~p~n", [File]),
	% 检查 File 是否存在
	Bool = filelib:is_file(File),
	case dets:open_file(?MODULE, [{file, File}]) of
		{ok, ?MODULE} ->
			case Bool of
				% 文件已经存在的话啥也不做
				true -> void;
				% 创建新表的话插入 {free, 1} 元组, 这里的 1 表示第一个空白索引
 				false -> ok = dets:insert(?MODULE, {free, 1})
			end,
			true;
		{error, Reason} ->
			io:format("cannot open dets table~n"),
			exit({eDetsOpen, File, Reason})
	end.

close() -> dets:close(?MODULE).

% 这里的 when 表示一个关卡,当文件名是二进制型的时候才执行
% 根据文件名找到索引
filename2index(FileName) when is_binary(FileName) ->
	case dets:lookup(?MODULE, FileName) of
		% 假如没找到
		[] ->
			% 找到空白索引
			[{_, Free}] = dets:lookup(?MODULE, free),
			% insert 的第二个参数可以是元组或者元组列表
			% 插入 索引和文件名的两个元组，并自增空白索引
			ok = dets:insert(?MODULE,
					[{Free, FileName}, {FileName, Free}, {free, Free+1}]),
			Free;
		[{_, N}] ->
		% 找到的话就直接返回索引
			N
	end.

% 根据索引找到文件名
index2filename(Index) when is_integer(Index) ->
	case dets:lookup(?MODULE, Index) of
		[] -> error;
		[{_,Bin}] -> Bin
	end.
```



# Mnesia: Erlang数据库

### 命令行配置

启动时指定 mnesia 的存储位置

```
elr -mnesia dir '"/tmp/mnesia_store"' -name mynode
```



## 基本操作

```erlang
-module (test_mnesia).
-export ([do_this_once/0]).

-record (shop, {item, quantity, cost}).
-record (cost, {name, price}).
-record (design, {id, plan}).

% 只运行一次，创建数据库
do_this_once() ->
	mnesia:create_schema([node()]),
	mnesia:start(),
	mnesia:create_table(shop, [{attributes, record_info(fields, shop)}]),
	mnesia:create_table(cost, [{attributes, record_info(fields, cost)}]),
	mnesia:create_table(design, [{attributes, record_info(fields, design)}]),
	mnesia:stop().

%% SELECT * FROM shop;
% 为了方便调用，使用demo
demo(select_shop) -> 
	% qlc:q() 会把其参数编译成一种用于查询数据库的内部格式
	% 将上述的结果传递给 do() 函数, 它会在接近 test_mnesia 底部的位置进行定义，负责运行查询并返回结果
	do(qlc:q([X || X <- mnesia:table(shop)]));

%% SELECT item, quantity FROM shop;
% 
demo(select_some) ->
	do(qlc:q([{X#shop.item, X#shop.quantity} || X <- mnesia:table(shop)]));

% SELECT shop.item FROM shop
% WHERE shop.quantity < 250;
demo(reorder) ->
	do(qlc:q([X#shop.item || X <- mnesia:table(shop), X#shop.quantity < 250]));

% SELECT shop.item
% FROM shop, cost
% WHERE shop.item = cost.name
% 	AND cost.price < 2
%	AND shop.quantity < 250
demo(join) -> 
	do(qlc:q([X#shop.item || X < mnesia:table(shop),
								X#shop.quantity < 250,
								Y <- mnesia:table(cost),
								X#shop.item =:= Y#cost.name,
								Y#cost.price < 2
									])).
% 创建一个shop 记录并存在数据库
add_shop_item(Name, Quantity, Cost) ->
	Row = #shop{item=Name, quantity=Quantity, cost=Cost},
	F = fun() ->
			mnesia:write(Row)
		end,
	mnesia:transaction(F).

% 移除某一行，需要知道 OID 对象ID。由表名和主键的值构成
remove_shop_item(Item) ->
	Oid = {shop, Item},
	F = fun() ->
			mnesia:delete(Oid)
		end,
	mnesia:transaction(F).

% mnesia 采用悲观锁,所以传递给 事务的方法不能有副作用
% mnesia:write 和 mnesia:delete 的调用只应该出现在 mnesia:transaction 内部
% 不要捕捉上述函数的异常错误

% 载入测试数据
example_tables() ->
	[%% shop表
		{shop, apple, 20, 2.3},
		{shop, orange, 100, 3.8},
		{shop, pear, 200, 3.6},
		{shop, banana, 420, 4.5},
		{shop, potato, 2456, 1.2},
	%% cost 表
		{cost, apple, 1.5},
		{cost, orange, 2.4},
		{cost, pear, 2.2},
		{cost, banana, 1.5},
		{cost, potato, 0.6},
	].

reset_tables() ->
	mnesia:create_table(shop),
	mnesia:create_table(cost),
	F = fun() ->
			foreach(fun mnesia:write/1, example_tables())
		end.
	mnesia:transaction(F).

do(Q) ->
	% Q 是一个已经编译的QLC查询
	% qlc:e 会执行该查询
	F = fun() -> qlc:e(Q) end,
	% atomic 表示事务成功并得到了 Val 值
	{atomic, Val} = mnesia:transaction(F),
	Val.



```

## 创建表

- mnesia:create_table(Name, ArgS) -> {atomic, ok} | {aborted, Reason}
  - Name 表名称
  - ArgS是一个由 {Key, Val} 元组构成的列表
    - {type, Type} : 指定了表的类型 set ordered_set bag
    - {disc_copies, NodeList } : NodeList 是一个 Erlang 节点列表，这些节点将保存表的磁盘副本
    - {ram_copies, NodeList } : NodeList 是一个 Erlang 节点列表，这些节点将保存表的内存副本
    - {disc_only_copies, NodeList} : 节点将只保存表的磁盘副本。这些表没有磁盘副本
    - {attributes, AtomList} : 这些列表包含各个值的列名
    - 还有别的选项 

# 套接字编程

## TCP

### 一个简单的客户端

```erlang
-module (socket_examples).
-export ([nano_get_url/0, nano_get_url/1]).

nano_get_url() ->
	nano_get_url("www.baidu.com").
% binary 通过二进制模式打开套接字,把所有数据用二进制型传给应用程序
% {packet, 0} 把未经修改的TCP数据直接传给应用程序
nano_get_url(Host) ->
	{ok, Socket} = gen_tcp:connect(Host, 80, [binary, {packet, 0}]),
	% 发送 "GET / HTTP/1,0\r\n\r\n" 给套接字，等待回复
	ok = gen_tcp:send(Socket, "GET / HTTP/1,0\r\n\r\n"),
	receive_data(Socket, []).


receive_data(Socket, SoFar) ->
	receive
		% 收到这中消息，说明是服务器返回的数据片段，放到列里里去继续接收下一个片段
		{tcp, Socket, Bin} ->
			receive_data(Socket, [Bin|SoFar]);
		% 收到该消息说明数据发送完成
		{tcp_closed, Socket} ->
			% 顺序是错的，所以需要反转一下
                list_to_binary(lists:reverse(SoFar))
	end.
```

### 一个顺序的服务器

```erlang
-module (server_examples).
-export ([start_nano_server/0]).

% 阻塞式的服务器
start_nano_server() ->
	% {packet, 4} 每个应用程序消息前部都有一个 4 字节的长度包头
	{ok, Listen} = gen_tcp:listen(2345, [binary, {packet, 4},
											{reuseaddr, true},
											{active, true}]),
	seq_loop(Listen).

seq_loop(Listen) ->
	% 将监听成功的返回值用作 accpet的参数
	% accpet调用后，程序会挂起等待连接
	% 返回的 Socket 绑定了可以与连接客户端通信的套接字
	{ok, Socket} = gen_tcp:accept(Listen),
	loop(Socket),
	% 再次调用，等待下一个连接
	seq_loop(Listen).

loop(Socket) ->
	receive
		{tcp, Socket, Bin} ->
			io:format("server received binary = ~p~n", [Bin]),
			% 解码输入数据
			Str = binary_to_term(Bin),
			io:format("Server (unpacked) ~p~n", [Str]),
			% 创建回复的字符串消息
			Reply = lib_misc:string2value(Str),
			io:format("Server replying = ~p~n", [Reply]),
			% 将回复编码并发回
			gen_tcp:send(Socket, term_to_binary(Reply)),
			loop(Socket);
		{tcp_closed, Socket} ->
			io:format("Server socket closed-n")
	end.
```

### 并行的服务器

```erlang
-module (server_parallel_server).
-export ([start_parallel_server/0]).

% 并行式的服务器
start_parallel_server() ->
	% {packet, 4} 每个应用程序消息前部都有一个 4 字节的长度包头
	{ok, Listen} = gen_tcp:listen(2345, [binary, {packet, 4},
											{reuseaddr, true},
											{active, true}]),

	spawn(fun () -> par_connect(Listen) end).

par_connect(Listen) ->
	% 将监听成功的返回值用作 accpet的参数
	% accpet调用后，程序会挂起等待连接
	% 返回的 Socket 绑定了可以与连接客户端通信的套接字
	{ok, Socket} = gen_tcp:accept(Listen),
	% 收到一个新连接后立即分裂一个新进程
	spawn(fun () -> par_connect(Listen) end),
	loop(Socket),

loop(Socket) ->
	receive
		{tcp, Socket, Bin} ->
			io:format("server received binary = ~p~n", [Bin]),
			% 解码输入数据
			Str = binary_to_term(Bin),
			io:format("Server (unpacked) ~p~n", [Str]),
			% 创建回复的字符串消息
			Reply = lib_misc:string2value(Str),
			io:format("Server replying = ~p~n", [Reply]),
			% 将回复编码并发回
			gen_tcp:send(Socket, term_to_binary(Reply)),
			loop(Socket);
		{tcp_closed, Socket} ->
			io:format("Server socket closed-n")
	end.
```

## 主动和被动套接字

- 通过调用 gen_tcp:connect(Address, Port, Options) 或 gen_tecp:listen(Port, Options) 的 Options 参数里加入
  - {active, true} : 主动消息接收（非阻塞式）
  - {active, false} : 被动消息接收(阻塞式)
  - {active, once} : 混合消息接收(非阻塞式)

### 主动消息接收

- 该进程无法控制通往服务器循环的消息流。

### 被动消息接收

- 每次想要接收数据时调用 gen_tcp:recv。
- 客户端会一直阻塞，直到服务器调用 recv 为止

### 混合模式

- 在该模式下是主动的，但只针对一个消息。
- 当控制进程收到一个消息后，必须显式调用 inet:setopts 才能重启下一个消息的接收，在此之前系统会处于阻塞状态





# OTP

## 编写 gen_server 回调模块的简要步骤

### 确定回调模块名

就随便取个名字，比如要制作一个简单的支付模块，叫 my_bank

### 编写接口方法

```erlang
-module (my_bank).

% 打开银行
%% gen_server:start_link 会启动一个本地服务器
%% 假如第一个参数是 global ，就会启动一个能被Erlang 节点集群访问的全局服务器
%% 第二个参数是模块名， Y额就是回调的模块名
start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
%% call 方法用来对服务器进行远程过程调用
stop() -> gen_server:call(?MODULE, stop).

% 创建新账号
new_account(Who) -> gen_server:call(?MODULE, {new, Who}).
% 钱存入银行
deposit(Who, Amount) -> gen_server:call(?MODULE, {add, Who, Amount}).
% 钱取出来
withdraw(Who, Amount) -> gen_server:call(?MODULE, {remove, Who, Amount}).


```



### 编写回调方法

```erlang
-module (my_bank).
-export([start/0, stop/0, new_account/1, deposit/2, withdraw/2]).
% gen_server 迷你模板
-behaviour(gen_server).
%% gen_server回调函数
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

% 定义宏
-define (SERVER, ?MODULE).
% 接口方法
% 打开银行
%% gen_server:start_link 会启动一个本地服务器
%% 假如第一个参数是 global ，就会启动一个能被Erlang 节点集群访问的全局服务器
%% 第二个参数是模块名， Y额就是回调的模块名
start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
%% call 方法用来对服务器进行远程过程调用
stop() -> gen_server:call(?MODULE, stop).

% 创建新账号
new_account(Who) -> gen_server:call(?MODULE, {new, Who}).
% 钱存入银行
deposit(Who, Amount) -> gen_server:call(?MODULE, {add, Who, Amount}).
% 钱取出来
withdraw(Who, Amount) -> gen_server:call(?MODULE, {remove, Who, Amount}).

% 回调方法
% SERVER 宏需要自己定义一下
init([]) -> {ok, ets:new(?MODULE, [])}.
% 处理创建新账号的请求
handle_call({new, Who}, _From, Tab) -> 
	Reply = case ets:lookup(Tab, Who) of
				[] -> ets:insert(Tab, {Who,0}),
						{welcome, Who};
				[_] -> {Who, you_already_are_a_customer}
			end,
	{reply, Reply, Tab};
% 处理存钱的请求
handle_call({add, Who, X}, _From, Tab) ->
	Reply = case ets:lookup(Tab, Who) of
				[] -> not_a_customer;
				[{Who, Balance}] ->
					NewBalance = Balance + X,
					ets:insert(Tab, {Who, NewBalance}),
					{thanks, Who, your_balance_is, NewBalance}
			end,
	{reply, Reply, Tab};
% 处理取钱的请求
handle_call({remove, Who, X}, _From, Tab) ->
	Reply = case ets:lookup(Tab, Who) of
				[] -> not_a_customer;
				[{Who, Balance}] when X =< Balance ->
					NewBalance = Balance - X,
					ets:insert(Tab, {Who, NewBalance}),
					{tnaks, Who, your_balance_is, NewBalance};
				[{Who, Balance}] ->
					{sorry, Who, you_only_have, Balance, in_the_bank}
			end,
	{reply, Reply, Tab};
% 处理停止服务器的请求
handle_call(stop, _From, Tab) ->
	{stop, normal, stopped, Tab}.
handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, Extra) -> {ok, State}.
```



## gen_server 的回调结构

### 启动服务器

- gen_server:start_link(Name, Mod, InitArgs, Opts)
- 创建一个名为Name的通用服务器，回调模块是Mod, Opts 则控制通用服务器的行为
- 其它参数要参照文档

### 调用服务器

- gen_server:call(Name, Request)
- 该函数最终调用的是回调模块里的 handle_call(Request, From, State)
- Request (call 的第二个参数) 作为 handle_call/3 的第一个参数出现
- From 是发送请求的客户端进程的Pid, State 则是客户端的当前状态。
  - 返回 {reply, Reply, State} Reply 是返回值， State 是服务器接下来的状态
  - 返回 {noreply,...} 是让服务器继续工作，客户端会继续等待回复，所以服务器必须把回复的任务委派给其它进程
  - 返回 {stop,...} 表示服务器停止

### 调用和播发

- gen_server:cast(Name, Msg) ：没有返回值的调用
- 返回 {noreply, NewState}: 改变服务器的状态
- 返回 {stop, ....}: 后者停止服务器

### 发给服务器的自发性消息

- handle_info(Info, State) : 用来处理发给服务器的自发性消息
- 自发性消息就是一切未经显式调用 gen_server:call 或 gen_server:cast 而到达服务器的消息。
- 返回值同 cast

### 终止

- 所有其它情况导致服务器终止时，调用 terminate(Reason, NewState)
- 因为服务器已经终止，所以不需要返回值
- 假如想让服务器重启，必须编写 terminate/2 触发的函数

### 代码更改

- code_change : 查文档

```erlang
-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore | 启动失败，但不想影响当前 supervisor 启动的其它进程
%%                     {stop, Reason} 彻底失败
%% @end
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
  {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([]) ->
  {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
  {reply, Reply :: term(), NewState :: #state{}} |
  {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @end
%%--------------------------------------------------------------------
-spec(handle_cast(Request :: term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_cast(_Request, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
  {noreply, NewState :: #state{}} |
  {noreply, NewState :: #state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #state{}}).
handle_info(_Info, State) ->
  {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
  ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
  {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

```



### 实例

```erlang
-module (my_bank).
-export([start/0, stop/0, new_account/1, deposit/2, withdraw/2]).
% gen_server 迷你模板
-behaviour(gen_server).
%% gen_server回调函数
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

% 定义宏
-define (SERVER, ?MODULE).
% 接口方法
% 打开银行
%% gen_server:start_link 会启动一个本地服务器
%% 假如第一个参数是 global ，就会启动一个能被Erlang 节点集群访问的全局服务器
%% 第二个参数是模块名， Y额就是回调的模块名
start() -> gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).
%% call 方法用来对服务器进行远程过程调用
stop() -> gen_server:call(?MODULE, stop).

% 创建新账号
new_account(Who) -> gen_server:call(?MODULE, {new, Who}).
% 钱存入银行
deposit(Who, Amount) -> gen_server:call(?MODULE, {add, Who, Amount}).
% 钱取出来
withdraw(Who, Amount) -> gen_server:call(?MODULE, {remove, Who, Amount}).

% 回调方法
% SERVER 宏需要自己定义一下
init([]) -> {ok, ets:new(?MODULE, [])}.
% 处理创建新账号的请求
handle_call({new, Who}, _From, Tab) -> 
	Reply = case ets:lookup(Tab, Who) of
				[] -> ets:insert(Tab, {Who,0}),
						{welcome, Who};
				[_] -> {Who, you_already_are_a_customer}
			end,
	{reply, Reply, Tab};
% 处理存钱的请求
handle_call({add, Who, X}, _From, Tab) ->
	Reply = case ets:lookup(Tab, Who) of
				[] -> not_a_customer;
				[{Who, Balance}] ->
					NewBalance = Balance + X,
					ets:insert(Tab, {Who, NewBalance}),
					{thanks, Who, your_balance_is, NewBalance}
			end,
	{reply, Reply, Tab};
% 处理取钱的请求
handle_call({remove, Who, X}, _From, Tab) ->
	Reply = case ets:lookup(Tab, Who) of
				[] -> not_a_customer;
				[{Who, Balance}] when X =< Balance ->
					NewBalance = Balance - X,
					ets:insert(Tab, {Who, NewBalance}),
					{tnaks, Who, your_balance_is, NewBalance};
				[{Who, Balance}] ->
					{sorry, Who, you_only_have, Balance, in_the_bank}
			end,
	{reply, Reply, Tab};
% 处理停止服务器的请求
handle_call(stop, _From, Tab) ->
	{stop, normal, stopped, Tab}.
handle_cast(_Msg, State) -> {noreply, State}.
handle_info(_Info, State) -> {noreply, State}.
terminate(_Reason, _State) -> ok.
code_change(_OldVsn, State, Extra) -> {ok, State}.
```

# OTP 构建系统

## 通用事件处理

```erlang
-module (event_handler).
-export ([make/1,add_handler/2, event/2]).
%% 制作一个名为Name的新事件处理器, 即开启一个进程来监听消息
%% 处理函数是 no_op ,代表不对事件做任何处理
make(Name) ->
	register(Name, spawn(fun() -> my_handler(fun no_op/1) end)).

% 给名为 Name 的事件处理器替换一个处理函数 Fun 
add_handler(Name, Fun) -> Name ! {add, Fun}.

%% 发送消息到名为Name的事件处理器
event(Name, X) -> Name ! {event, X}.

my_handler(Fun) ->
	receive
		{add, Fun1} ->
			my_handler(Fun1);
		{event, Any} ->
			(catch Fun(Any)),
			my_handler(Fun)
	end.
no_op(_) -> void.


```

- 一个回调函数的例子

```erlang
-module (motor_controller).
-export ([add_event_handler/0]).

add_event_handler() ->
	event_handler:add_handler(errors, fun controller/1).
controller(too_hot) ->
	io:format("Turn off the motor~n");
controller(X) ->
	io:format("~w ignored event: ~p~n", [?MODULE, X]).
```



## 错误处理

查询文档 error_logger

## 警报管理

## 监督者

### 启动

- start_link/3 调用的 [] 表示的是发送到 init/1 回调的参数, 而不是 Options
- 回调 init/1 函数



```erlang
-module(sellaprime_supervisor).
-behaviour(supervisor).
-export([start/0, start_in_shell_for_testing/0, start_link/1, init/1]).

start() ->
    spawn(fun() ->
            supervisor:start_link({local, ?MODULE}, ?MODULE, _Arg = [])
            end).

start_in_shell_for_testing() ->
    {ok, Pid} = supervisor:start_link({local, ?MODULE}, ?MODULE, _Arg = []),
    unlink(Pid).
start_link(Args) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, Args).
init([]) ->
    %% 安装自己的错误处理器
    gen_event:swap_handler(alarm_handler,
                            {alarm_handler, swap},
                            {my_alarm_handler, xyz}),
    %% 定义监控策略
    {ok, 
        {
            {one_for_one, 3, 10},
            [
                {tag1,
                    {area_server, start_link, []},
                    permanent,
                    10000,
                    worker,
                    [area_server]
                },
                {tag2,
                    {prime_server, start_link, []},
                    permanent,
                    10000,
                    worker,
                    [prime_server]
                }
            ]
        }
    }.
```

最后的监控策略

```erlang
{Tag, {Mod, Func, ArgList},
	Restart,
	Shutdown,
	Type,
    [Modl]
}
```

- Tag: 一个原子类型的标签，将来可以用它指代工作进程
- {Mod, Func, ArgList}: 定义了监控器用于启动工作器的函数，以及其参数列表
- Restart = permanent | transient | temporary
  - 进程总是会被重启
  - 只有在以非正常退出值终止时才会被重启
  - 进程不会被重启
- Shutdown: 关闭时间，也就是工作器终止过程允许耗费的最长时间。如果超过这个时间，工作进程就会被杀掉(还有其它值)
- Type = worker | supervisor
  - 被监控的类型。可以用监控进程代替工作进程来构建一个由监控器组成的树
- \[Modl\] 如果子进程是监控器或者 gen_server 行为的回调模块，就在这里指定回调模块名。（还有其他值）

#### 关于监督树的 监督策略

- one_for_one: 监督者会负责重启子进程，适用于需要长期在线的进程
- simple_one_for_one: 子进程不会自动启动，需要调用API去启动，子进程的模板代码需要保持一致，适用于快速生成快速消灭的进程(类似于servlet 中的 request)





### simple_one_for_one 需要使用



## gen_event

- 一个gen_event 模块通常会包含两个部分

- 所有的通用部分，称作 事件管理器

  - 事件管理器可以接收 零个或多个 事件处理器

- 所有的专用部分，称为事件处理器

  - 每个事件处理器负责完成一个特定的，事件驱动的任务

  - 多个事件处理器都会运行在一个事件管理器中

    

### API函数

### 添加事件处理器

- gen_event:add_handler(Name, Mod, Args) --> {'EXIT, Reason'} | ok | Term

- 调用该方法的时候会回调下面那个方法，也就是 Mod 模块里的 init 方法，来完成事件处理器添加到事件管理器的过程

- Mod:init(Args) -> {ok, loopData}. | {error, Reason}
- loopData 不返回的话事件处理器不会被添加
- 不但可以在一个事件管理器添加多个事件处理器，而且可以把同一个事件处理器重复添加多次
- 添加不存在的事件处理器会导致事件管理器调用 Mod:init/1 失败, 

#### 删除事件处理器

- gen_event:delete_handler(Name, Mod, Args) 函数调用时会回调下面的方法
  - Name 指明了事件处理器注册于哪一个事件管理器， 是 pid 或注册进程的名字
  - Mod 表明了想要删除的事件处理器
- terminate(Args, loopData)
  - 该函数的返回值会成为 API函数的返回值
- 尝试移除一个没有注册过的事件处理器将导致返回值 {error, module_not_found}
- 向不存在的事件管理器添加或移除事件处理器都会返回 noproc

### 发送同步的或异步的事件

- 事件发送给事件管理器后会被转移给事件处理器，这一过程可以是同步或者异步的
- 这一API 会发送事件给所有的事件处理器,不管是同步的还是异步的
- gen_event:notify/2 函数发送异步的事件给所有的事件处理器后立刻返回 ok。每个 Mod:handle_event/2 函数会被依次调用
- gen_event:sync_notify/2 会以同步的方式触发 Mod:handle_event/2 的回调，只有当所有事件处理器的回调都被调用才会返回ok。
- handle_event 如果返回 remove_handler 的话就移除事件处理器并回调 terminate 函数

### 获取数据

- gen_event:call(NameScope, Mod, Request, [Timeout])  -> Reply | {error, bad_module} | {error, {'EXIT', Reason}} | {error, Term}
- 会回调 Mod:handle_call(Event, Data) -> {ok, Reply, NewData} 假如返回值出错，那么该事件处理器会被移除

### 对错误以及无效返回值的处理

- 任何回调函数导致非正常终止都会进而导致事件处理器被移除,不会影响其它事件处理器
- 不管是程序运行错误，还是返回值不匹配导致的错误，都不会有运行时错误出现，也没有 EXIT 信号, 发送事件只是默默的出错
- 为了绕开上点提到的问题，可以调用 gen_event:add_sup_handler/3 函数把事件处理器和发起该调用的进程连接起来
- gen_event:add_sup_handler 的工作方式类似于 add_handler, 副作用在于发起调用的进程从此就开始监视事件处理器了
- 当事件处理器异常终止时，一条格式为 {gen_event_EXIT, Mod, Reason} 的消息会被发送给添加给该事件处理器的进程。 Reason 可以表述为:
  - normal : 当回调函数返回 remove_handler 或者处理器被 delete_handler/3 移除
  - shutdown: 如果事件管理器被其 supervisor 停止，或者被 stop/1 调用停止
  - {'EXIT', Term} 如果发生了运行时错误
  - Term : 如果回调返回了任何 {ok, LoopData} 或者 {ok, Reply, LoopData} 之外的东西
  - {swapped, NewMod, Pid}: 其中的 Pid 指代的进程交换了当前处理器
- 监视是双向的。如果添加该事件处理器的进程终止了，则该事件处理器会被以 {stop, Reason} 作为原因开除。这种做法能够确保 同一处理器的多个实例不会被意外地反复加入管理器

### 交换事件处理器

- 事件管理器提供了相应的功能可以用于在运行时交换事件处理器。
- 可以把当前事件处理器的状态传递给新的事件处理器，保证进程中的事件不会出现丢失。
- gen_event:swap_handler(Name, {OldMod, OldArgs}, {NewMod, NewArgs}) ->
  - OldMod 会调用 terminate(OldArgs, Data) -> Res
  - NewMod 会调用({NewArgs, Res}) -> {ok, NewData}
- 假如希望在交换事件处理器的同时启动监督, 就使用 gen_event:swap_sup_handler/3 ，正要被换掉的事件处理器此时不要求已经处于被监督状态。



# OTP application

## 分为两类

### Normal application

- 会启动一个顶级监督者，该监督者负责启动子进程，监督者负责启动子进程

### Library application

- 提供库模块给外部使用，但自身不启动监督者或进程
- 它们导出的函数可供运行于不同 application 中的 worker 或监督进程调用。
- 一个典型的例子是 stdlib

## 一些说明

- Erlang VM 内部会为每一个节点启动一个 application controller(应用控制器) 的进程。
- 针对每个OTP application。 该控制器会启动以对名为 application master 的进程，负责启动和监视顶级监督者，并在顶级监督者终止时采取行动。
- Erlang 运行时会将每个 application 视为一个独立的单元。
- 每个 application 可以作为一个整体被加载，启动，停止和卸载。
  - 记载 application 时，运行时系统加载所有相关模块并检查各个资源。如何任何一个模块损坏，启动将失败，该节点也会被关掉
  - application master 进程创建顶级监督者进程，后者进而又启动了监督树的下级部分，如果监督树中有任何行为启动失败的话，整个节点也会被关闭
  - 当停止 application 时， application master 进程会终止其所管理的顶级监督者，传递退出信号给监督树中所有行为模式进程。
  - 执行 application 卸载的时候，运行时将会清除该 application 的所有已加载模块。

## OTP application 的结构

- appplication 目录的名称由 application 名称后跟版本号构成。

- ebin: 包含 beam 文件和 application 配置文件, 也即是app文件
- src: 包含源代码文件和不希望被使用的头文件
- priv: 包含 application 所需的非 Erlang 类文件，例如图像，驱动程序，脚本或专有配置文件。
- include: 包含导出的可由其它 application 使用的头文件。

## application 资源文件

- 包含 配置数据， 资源和启动 application 所需的信息组成的规范。
- 该规范是 {application, Application, Properties} 的标记式元祖， 其中 Application 是表示 application 名称的原子， Properties 是一个由标记式元祖组成的列表。

```erlang
{application, eq_test,
 [{description, "An OTP application"},
  {vsn, "0.1.0"},
  {registered, []},
  {mod, {eq_test_app, []}},
  {applications,
   [kernel,
    stdlib,
    crypto,
    jsx,
    emqttc
   ]},
  {env,[]},
  {modules, [
   db,
   eq_test_app,
   eq_test_mission_server,
   eq_test_mission_sup,
   eq_test_sup,
   eq_test_util,
   log_server
  ]},

  {maintainers, []},
  {licenses, ["Apache 2.0"]},
  {links, []}
 ]}.

```



### 标准属性包括

- {description, Desscription}
  - 自设定的描述符
- {vsn, Vsn}
  - application 版本的字符串，应该反映目录的名称
- {modules, Modules}
  - 模块列表，用于指明创建发行版和加载 application 时使用的模块列表
  - 在此列出的模块和 ebin 目录中包含的 beam 文件之间是一一对应的。不是对应的则不会加载
  - 还被用于检查各个 application 之间是否存在模块命名空间冲突，以确保名称的唯一性
- {registered, Names}
  - Names 是一个列表，包含了此 application 中运行的全部注册进程名称
  - 包括此属性可以确保此 application 不会与其它 application 存在注册名称冲突问题

- { applications, AppList}
  - AppList 指明了启动当前 application 必须启动的所依赖的其他 application 的列表。
  - 所有 application 都依赖于 kernel 和 stdlib application， 有许多还依赖于 sasl
- {env, EnvList}
  - 其中 EnvList 是 {Key, Value} 元祖构成的列表，用于为 application 设置环境变量。
  - 而环境变量的值可以使用 application 模块的 get_env(Key) 或 get_all_env() 函数来获取
  - 如果要读取的是其它 application 的环境变量而非 当前 application 的，则可以使用 get_env(Application, Key) 和 get_all_env(Application)。
- {mod, Start}
  - 其中 Start 是一个格式为 {Module, Args} 的元祖，指明了 application 的回调模块以及传递给启动函数的参数。
  - 当 application 启动时，此元祖的存在使得 Mod:start(normal, Args) 被调用。省略此属性会导致该 application 被视为库 application。将由其它 application 的监督者或 worker 启动，因而在启动时也不会为当前 application 创建监控树。

### 非标准属性

- {id, Id}
  - 产品标识符的字符串
- {included_applications, Apps}
  - 其中 Apps 是一个列表指明了当前 application 所包含的子 application。
  - 与其他 application 的区别在于，子 application 的顶级监督者必须由其它监督者启动。
- {start_phases, Phases}
  - Phases 是一个元祖列表，由格式为 {Phase, Args} 的元祖组成，这其中的 Phase 是一个原子，而 Args 可以是一个 Erlang 数据项
  - 这一属性主要用于支持 application 的分阶段启动功能。
  - 该项功能使得 application 能够与系统的其他部分相互同步并在后台启动 worker。
  - 在 Module:start/2 返回之前，每一个阶段都会调用 Module:start_phase(StartPhase, StartType, Args)。其中 StartType 是原子 normal 或元祖 {takeover, Node} 或 {failover, Node} 

