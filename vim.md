# 概念

### 普通模式 : vim 的自然放松状态

### 表达式寄存器

- 大部分Vim 寄存器中保存的都是文本，要么是一个字符串，要么是若干行的文本。

- 删除及复制命令允许我们把文本保存到寄存器中，粘贴命令可以把寄存器中的内容插入到文档里
- 表达式寄存器可以用来执行一段Vim脚本，并返回其结果。可以当计算器用
- 可以使用 = 符号指明使用表达式寄存器。在插入模式中，输入 <C-r>=  就可以访问这一寄存器， 输入表达式后敲一下 <CR>，Vim就会把执行的结果插入到文档的当前位置。

### 可视模式

有三种 面向字符，面向行，面向块

- 普通模式中，先触发修改命令，然后使用动作命令指定其作用范围
- 可视模式中，先选中选区，然后再触发修改命令

#### 面向字符

- 适用于操作单词或短语
- 普通模式下按 v 进入面向字符的可视模式

#### 面向行

- 普通模式下按V 可激活面向行的可视模式

#### 面向块

- 普通模式下<C-v>则可激活面向列块的可视模式

   

# 操作规范

### 用一次按键移动，一次按键操作

可以方便使用 .命令 复制操作

### 操作符 + 动作命令 = 操作

常见的操作符

| 命令 | 用途                               |
| ---- | ---------------------------------- |
| c    | 修改                               |
| d    | 删除                               |
| y    | 复制到寄存器                       |
| g~   | 反转大小写                         |
| gu   | 转换为小写                         |
| gU   | 转换为大写                         |
| >    | 增加缩进                           |
| <    | 减小缩进                           |
| =    | 自动缩进                           |
| !    | 使用外部程序过滤{motion}锁跨越的行 |
|      |                                    |
|      |                                    |

当连续输入两遍操作符时，会自动作用于本行

### . 命令

可以重复上次的操作

### 可重复操作以及如何回退

| 目的                     | 操作                  | 重复 | 回退 |
| ------------------------ | --------------------- | ---- | ---- |
| 做出一个修改             | {edit}                | .    | u    |
| 在行内查找下一指定字符   | f{char} / t{char}     | ;    | ,    |
| 在行内查找上一指定字符   | F{char}/T{char}       | ;    | ,    |
| 在文档中查找下一处匹配项 | /pattern<CR>          | n    | N    |
| 在文档中查找上一处匹配项 | ?pattern<CR>          | n    | N    |
| 执行替换                 | :s/target/replacement | &    | u    |
| 执行一系列修改           | qx{changes}q          | @x   | u    |



### 移动有关的操作

- $ 快速移动到行尾

- A 命令可以在当前行的结尾添加内容, a 命令是在当前光标之后添加内容

- zz 可以重绘屏幕，将当前行显示在窗口正中

  

### 复制粘贴替换有关的操作

- 在插入模式中，可以用<C-r>{register} 命令很方便的粘贴几个单词
- 替换模式中输入会替换文档中的已有文本，除此之外，该模式与插入模式完全相同。
  - 普通模式中按 R 进入替换模式

### 花式输入

- s 先删除光标下的字符，然后进入插入模式
- cw : 删除从光标位置到单词结尾间的字符
- o: 换行并进入插入模式
- daw: 删除一个单词
- 三种删除有关的按键操作
- 输入模式下<C-r>= {expression}<CR> 可以输入表达式的结果
- 输入模式下 <C-v>{code} 可以输入任意字符

| 按键操作 | 用途           |
| -------- | -------------- |
| <C-h>    | 删除前一个字符 |
| <C-w>    | 删除前一个单词 |
| <C-u>    | 删至行首       |

- 插入非常用字符

| 按键操作            | 用途                                   |
| ------------------- | -------------------------------------- |
| <C-v>{123}          | 以十进制字符编码插入字符               |
| <C-v>u{1234}        | 以十六进制字符编码插入字符             |
| <C-v>{nondigit}     | 按原义插入非数字字符                   |
| <C-k>{char1}{char2} | 插入以二合字母{char1}{char2}表示的字符 |



### 查找有关的操作

- 可以用 * 去匹配光标所在的单词，按 n 可以跳到下一个匹配项
- f{char} 查找下一处指定字符出现的位置， 如果找到了，光标就会直接移动到下一个 + 号所在的位置
- ; 命令会重复查找上次 f 命令锁查找的字符, 也可以使用 , 命令反向查找

### 控制撤销的粒度

- 从进入插入模式开始，直到返回普通模式为止，在此期间输入或删除的任何内容都被当做一次修改。因此，控制撤销粒度的关键在于 esc 的使用
- 在插入模式中使用 上下左右 光标键时也会产生新的撤销块

### 插入普通模式

- 可以在执行一次普通模式后马上进入插入模式

- 按 <C-o> 进入 

