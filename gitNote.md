# 团队工作的基本模型
- 别人 commit 代码到他的本地，并push到GitHub中央仓库
- 你把GitHub的新提交通过pull指令来取到自己的本地
- push冲突的时候，说明你的commit别人也commit了，这时候要先pull一下
将远端仓库上的新内容取回到本地和本地合并，然后再把合并后的本地仓库向远端仓库推送。

以上是最简单的工作模型

# Git的重要概念
## HEAD
Git的使用中，经常会需要对指定的 commit 进行操作。每一个 commit都有一个它唯一的指定方式
这种唯一的方式重复的概率极低，可以用它来指代 comit。但是这很难记忆
所以Git提供了引用的机制:使用固定的字符串作为引用，指向某个commit，作为操作 commit时的快捷方式

HEAD 就是所谓指向当前commit的引用，即为当前的工作目录所对应的commit
所以永远可以用HEAD来操作当前的commit。

## branch
HEAD是Git中一个独特的引用，它是唯一的。
还有一种引用，叫做 branch。HEAD除了可以指向commit之外，还可以指向一个branch。
当HEAD指向某个branch的时候，会通过这个branch来间接地指向某个 commit;
另外,当HEAD在提交时自动向前移动的时候，它会像一个拖钩一样带着他所指向的branch一起移动

## master
master是默认的branch
- 新创建的 repository 是没有任何 commit的。但是在它创建第一个commit时，会把master指向它，并把HEAD指向master
- 当使用了git clone 时，除了从远程仓库把 .git 这个仓库目录下载到工作目录中，
还会checkout（签出）master（checkout 的意思就是把某个commit作为当前commit,把HEAD移动过去，并把工作目录的文件内容替换成这个commit所对应的内容）。

## push的本质
把当前 branch的位置（即它指向哪个commit）上传到远端仓库，并把它的路径上的 commitS 一并上传
push 的时候只会上传当前的 branch的指向，并不会把本地的HEAD的指向也一起上传到远程仓库
事实上，远程仓库的 HEAD 是永远指向它的默认分支并随着默认分支的移动而移动的

## pull
内部操作其实是把远程仓库取到本地后(使用的fetch)，再用一次 merge 来把远端仓库的新 commits 合并到本地

## merge
是用来合并 commits的
指定一个commit, 把它合并到当前的commit来。具体来说:
从目标 commit 和当前 commit （即HEAD所指向的 commit）分叉的位置起，
把目标 commit的路径上的所有 commit 的内容一并应用到当前 commit,然后自动生成一个新的 commit。

### 适用场景
- 当一个branch的开发已经完成，需要把内容合并回去的时候，用 merge 来进行合并
- pull的内部操作

### 特殊情况
#### 冲突
merge 在做合并的时候，有一定的自动合成能力
但是如果两个分支修改了同一部分内容，那就冲突了
最直接的解决冲突的方法
- 利用git的提示(<<< === >>>)手动解决冲突
- 手动提交(要先add)

#### HEAD领先于commit
如果merge时的目标 commit 和 HEAD 处的commit并不存在分叉，而是HEAD领先于目标commit
那么merge就是一个空操作

#### HEAD落后于目标commit - fast-forward
HEAD和目标commit依然是不存在分叉，但HEAD不是领先于目标 commit,而是落后
那么Git会直接把HEAD移动到目标 commit(这个叫fast-forward)

## 最流行的工作流 Feature
响应[边开发边发布，边开发边修复]的持续开发策略

### 核心
- 任何新功能(feature)或 bug修复第全都新建一个branch来写
- branch写完后，合并到master,然后删掉这个branch

### 代码分享
- 开发一个新功能，开启一个新的branch
- 开发完后，将该branch pull 上去
- reviewer从中央仓库拉代码下来读
    + 觉得可以的话就直接把这个branch合并到master上去，并把合并后的结果push到中央仓库上,并删掉了这个branch
    + 如果代码y有问题，就继续改代码然后commit,之后再重复以上流程直到可以

### 一人多任务
建立多个branch,在提交信息里提示自己一下

### add
通过 add可以把改动的内容放进暂存区里

- add.可以暂存全部文件
- add 添加的是文件改动，而不是文件名

# 杂项
## 看看改变了啥

### git log
可以查看操作的历史

### log -p
可以看到每一个commit的每一行改动，适合代码review

### log --stat
查看简要统计

### git show (commit引用)
查看某个commit

### 看未提交的内容，可以用diff

### 对比暂存区和上一条提交
git diff --staged

### 对比工作区和暂存区
git diff

### 对比工作目录和上一条提交
git diff HEAD

## 使用rebase代替merge
rebase是指给你的commit序列重新设置基础点,即，在你指定的commit以及它所在
的 commit 串，以指定的目标 commit 为基础，依次重新提交一次
就是把branch在master的基础上再重新提交一次，而不是合并
先切换去branch，再rebase
在rebase之后，master还要merge一下,把master移到最新的commit里

## 写错了怎么办
- 可以再写一个commit
- commit --amend
amend 修正的意思，加上这个参数，不会增加commit，而是用这个新的commit把当前commit替换掉

## 写错的是倒数第二个提交
rebase -i
交互式rebase
就是说在rebase操作执行之前，可以指定要 rebase的commit链中的每一个commit是否需要进一步修改
可以利用这个特点，进行一次原地rebase

### git的两个偏移符号
- ^
commit后面加 ^ ，可以把commit往回偏移，偏移数量为^的数量
- ~
指定偏移的数量

git rebase -i HEAD^^
把当前 commit rebase到HEAD之前2个的commit上
之后会进入编辑界面
把要修改的commit的用法改成 edit，之后退出编辑界面
再用 commit --amend 来把修正应用到当前最新的commit
继续rebase过程 git rabase --continue
整个过程就完成了

## 丢弃 commit
git reset --hard HEAD^
恢复到这个偏移量的 commit

# 便捷的指令


