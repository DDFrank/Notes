# 常用用法

### 使用 comp 来组合函数

- 比如要取出一个序列的倒数第二个数

```clojure
(comp second reverse)
```

### 列表和常量是相等的

```clojure
(= '(1 2 3 4) [1 2 3 4])
;true
```

### 使用 complement 来对 谓词函数取反

### tree-seq 可构造一个深度优先的列表来表示 tree

```clojure
(tree-seq branch? children root)
;; branch 是一个谓词函数，判断该节点是否有子元素 
;; children 是一个单参数函数，假如该节点是子节点，那用来表示如何生成子元素
;; root 是根元素
```

