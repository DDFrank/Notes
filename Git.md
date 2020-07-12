

# 常用指令

### 查看所有分支

```shell
git b -a
```

### 删除远程分支

```shell
git push origin --delete feature_log_jinjunliang
```

### 删除本地分支

```shell
git branch -d Chapater8
```

### 从 develop 分支创建一个新分支

```shell
git checkout -b feature_123_jinjunliang develop 
```

### 查看指定分支的迁出后的log

```shell
git reflog show <branch name>
```

### 本地关联远程

```shell
git remote add origin git@192.168.0.205:deli-cloud-platform-v2/ops-gateway.git
```

### 比较两个分支的commit进度

```shell
// 查看feature_message.jinjunliang.dev 比 develop 多提交了哪些内容
git log develop...feature_message.jinjunliang.dev
```

### 创建附注标签

```shell
git tag -a v0.1.2 -m “0.1.2版本”
```

### 撤销远程commit

````shell
git reset 回去后 git push origin branch_name --force
````

### 恢复单个文件的修改

```shell
git checkout -- filename
```

### 临时保存手头的工作

- 临时本地存储手头的工作

```shell
git stash save "修改信息"
```

- 可以查看保存

```shell
git stash list
```

- 删除并应用临时的修改

```shell
git stash pop
```

```
git@github.com/DDFrank/Notes.git
```





