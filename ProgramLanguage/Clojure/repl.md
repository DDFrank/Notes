### 可以导入一些方便的函数

```clojure
(require '[clojure.repl :refer :all])
```

```clojure
(doc +)
;; 打印函数的文档

(apropos "+")
;; 参数是string或者可以转换为string的字面量，会寻找符合的函数

(find-doc "trim")
;; 打印所有符合名称条件的函数的文档

(dir clojure.repl)
;; 查看某个 namespace 下暴露的所有 函数

(source clojure.string/trim)
;; 查看某个方法的源码
```

# 基本语法

## 结构

### 映射绑定

- 可以使用某些关键字简化映射的绑定 :keys :strs :syms

```clojure
;; 直接取出key对应的值
(defn greet-user [{:keys [first-name last-name]}]
  println "Welcome, " first-name last-name)
;; 假如键是字符串或者符号(上例中为关键字)，那么可以使用 :strs 或 :syms
```



## 多态及多重方法

### 使用 defmulti 和 defmethod

- defmulti 的语法

```clojure
(defmulti name docstring? attr-map? dispatch-fn & option)
```

- name : 多态方法的名称
- docstring: 可选的文档参数
- attr-map:  可选的元数据参数
- dispatch-fn: 常规参数，接收多重方法调用时传入的参数，方法的返回值会作为分派值
- options: 提供可选规格的键值对
  - :default 选择新的默认分派值, (也就是决定什么分派值会是 :default 分支)
  - :hierarchy 使用一个自定义分派值层次结构



- defmethod 的语法

```clojure
(defmethod multifn dispatch-value & fn-tail)
```

- multifn: 多态方法的名称
- dispatch-value: 用于跟分配值比较的常量
- fn-tail: 函数主体, 可以使用不同数量的参数

```clojure
(defmethod my-many-arity-multi :default
  ([] "no arguments")
  ([x] "one argument")
  ([x & etc] "many arguments"))
```

```clojure
(defn fee-category [user]
  [(:referrer user) (:rating user)])

;; 定义多重方法
;; 首先决定如何分派
(defmulti affiliate-fee (fn [user] (:referrer user)))

;; 下面开始定义多个分派后执行的方法
(defmethod affiliate-fee "mint.com" [user] (fee-amount 0.03M user))
(defmethod affiliate-fee "google.com" [user] (fee-amount 0.01M user))
;; 默认值使用 :default
(defmethod affiliate-fee :default [user] (fee-amount 0.02M user))
```

### 多分派, 定义层次结构



#### 

## 调用Java

| Task            | Java              | Clojure          |      |
| --------------- | ----------------- | ---------------- | ---- |
| Instantiation   | new Widget("foo") | (Widget. "foo")  |      |
| instance method | rnd.nextInt()     | (.nextInt rnd)   |      |
| Instance field  | object.field      | (.-field object) |      |
| Static method   | Math.sqrt(25)     | (Math/sqrt 25)   |      |
| Static field    | Math.PI           | Math/PI          |      |
|                 |                   |                  |      |



## 状态和并发

### 引用

- ref-set : 接收一个引用和新值, 然后用新的值替代旧的值

```clojure
(dosync (ref-set all-users {}))
```

- alter
  - 检查引用的值是否已经因为另一个事务的提交而更改
  - 已更改的话会导致当前事务失败并重试

```clojure
(ns demo.concurrent)
;; 创建引用
(def all-users (ref {}))
;; 定义一个新用户
(defn new-user [id login monthly-budget]
  {:id id
   :login login
   :monthly-budget monthly-budget
   :total-expense 0})
(defn add-new-user [login budget-amount]
  (dosync
   (let [current-number (count @all-users)
         user (new-user (inc current-number) login budget-amount)]
     ;; alter 会返回引用的最终状态
     (alter all-users assoc login user))))

```

- commute : 当函数的应用顺序并不重要时十分有用
  - 对 commute 的所有调用将在事务结束时处理
  - 调用格式与 alter 相似

### 代理

- agent: 创建代理

```clojure
;; 创建代理
(def total-cpu-time (agent 0))
;; 解除代理
@total-cpu-time
```



- send
  - 在特定的状态必须以异步的方式更改时非常有用
  - 语法

```clojure
(send the-agent the-function & more-args)
```

- send-off
  - 语法与 send 基本相同
  - 维护的线程池规模更大
  - 同一时间特定代理只能运行一个动作

- await 

  - 当执行必须停止并等待之前委派给某个代理的动作完成时，该函数十分有用
  - 语法

  ```clojure
  (await & the-agents)
  ```

  - 阻塞是无期限的

- await-for

  - 比 await 多接受一个超时的参数

  ```clojure
  (await-for timeout-in-millis & the-agents)
  ```

#### 代理错误

- 代理发生错误时，将抛出一个异常，之后所有的 send 操作都不能执行
- 使用 agent-error 返回代理线程执行时抛出的异常

```clojure
(agent-error bad-agent)
```

- 可以使用 clear-agent-errors 清除错误状态

```
(clear-agent-errors bad-agent)
```

#### 验证

- 创建代理时，有更多选项

```clojure
(agent initial-status & options)
```

- :meta metadata-map : 提供的映射会成为代理的元数据
- :validator validator-fn: 会取得代理的新状态，可以应用任何业务规则以允许或拒绝值的改变



#### 使用代理来产生事务中的副作用

- 因为dosync 块内的代码可能需要执行多次，因此如果有副作用，那么就会产生多次

```clojure
(dosync 
  (send agent-one log-message args-one)
  (send-off agent-two send-message-on-queue args-two)
  (alter a-ref ref-function
         (some-pure-function args-three)))
```

- 上述代码中，事务成功时 send 和 send-off 才会发送，所以可以保证副作用只会发生一次



### 原子

- 可以对可变数据实现同步独立更改
- 对原子的更改独立于其他原子的更改，因此没有必要使用事务

```clojure
;; 创建原子
(def total-rows (atom 0))

(deref total-rows)

;; 将所提供的值设置为原子的新值
(reset! atom new-value)
;; 以同步的方式对原子应用突变函数
(swap! the-atom the-function & more-args)
;; 如果原子的当前值等于所提供的旧值，则这个函数以原子的方式将原子值设置为新值，成功返回 true ，否则 false
(compare-and-set! the-atom old-value new-value)
```



### 变量

不知道跟普通的变量有啥区别

```clojure
(defn db-query [db] 
		(binding [*mysql-host* db] 
      (count *mysql-host*)))
```



### 监视突变

- add-watch: 允许注册一个常规的 Clojure 函数作为任何类型引用的 "监视器"。当该引用的值改变时，运行监视器函数

- 监视器函数必须有四个参数

  - the-key ： 标识监视器的键
  - the-ref: 注册的托管引用
  - old-value: 托管引用的旧值
  - new-value: 托管引用的新值

  ```clojure
  (def adi (atom 0))
  (defn on-change [the-key the-ref old-value new-value]
    (println "Hey, seeing change from" old-value "to" new-value))
  ;; 添加监视器
  (add-watch adi :adi-watcher on-change)
  
  ;; 解除监视器
  (remove-watch adi :adi-watcher)
  ```



### 如何选择使用哪种托管类型

#### 变量

- 只适用于孤立的更改(对于特定的线程)
- 变量不能由代码中的多个部分写入

#### 原子

- 管理必须由多个线程写入和读取状态更改的最简单方法
- 绝大多数时候使用，但是有两个缺点
  - 多个原子无法以原子化的方式一起更改
  - 对一个原子的修改不能有副作用

#### 引用

- 有协调的原子
- 当一个原子管理的值过于巨大时，可以考虑将其拆分为多个引用
- 在一个 dosync 事务中以原子化方式读取和写入多个引用
- 如果有必须同时更新但很少全部出现在一个事务中的多个状态，则可以在应用程序中减少竞争数量，改善并发性
- 事务中同意不能由副作用

#### 代理

- 可以容忍副作用
- 具有错误状态，如果操作失败必须检查和清除错误
- 异步运行，在别的线程中执行完成
- 假如使用引用只有少量副作用，这些副作用必须在事务成功时才完成，那么就可以结合代理和引用使用



### future

- 在不同线程上运行代码的简单手段, 对于可能从多线程获益的长时间计算或者阻塞调用很有用
- 语法

```clojure
(future & body)
```

```clojure
(defn fast-run []
  (let [x (future (long-calculation 11 13))
        y (future (long-calculation 13 17))
        z (future (long-calculation 17 19))]
    ;; 按顺序阻塞
    (* @x @y @z)))
```

- 其它API

```clojure
;; 检查对象是不是future
future?
;; 检查计算是否已经完成
future-done?
;; 试图撤销 future 操作，如果已经开始，则不做任何事情
future-cancel?
;; 如果future已经被撤销，则返回true
future-cancelled?
```



### promise

- promise 对象代表某个值的一次提交

```clojure
;; 创建一个新的promise
(def p (promise))
;; 假如没有值的话阻塞当前线程
(def value (deref p))
@p

;; 使用 deliver 函数交付值, 会从不同线程中调用
(deliver promise value)

```

```clojure
(let [p (promise)]
  (future (Thread/sleep 5000)
    (deliver p :done))
  @p)
```



## 宏

### 宏模板

```clojure
(defmacro unless [test then]
  (list 'if (list 'not test)
        then))
```

使用宏模板后可以这么写

```clojure
(defmacro unless [test then]
`(if (not ~test)
	~then)
```

- ` 反引号用于启动模板， 模板将被展开为一个 s- 表达式
- ~ 对于某些固定的文本，不需要更改的内容，可以使用 ~ 字符来解引述,解引述是引述的反面

#### 使用解引述宏拼接读取器宏进行拼接 (~@)

```clojure
(defmacro unless [test & exprs]
  `(if (not ~test)
     ;; 将列表的内容拼接起来，避免多出现一对括号
     (do ~@exprs)))
```

### 自定义呢宏的一些练习

```clojure
(ns demo.macro)

;; 使用中缀表示法
(defmacro infix [expr]
  ;; 绑定表达式中三项
  (let [[left op right] expr]
    (list op left right)))

;; 接收任意数量的 s- 表达式并随机选择一下
(defmacro randomly [& exprs]
  ;; 计算表达式的数量
  (let [len (count exprs)
        ;; 随机生成一个index
        index (rand-int len)
        ;; 生成判断是否需要执行某个索引的表达式，类似于 (= 0 0)
        conditions (map #(list '= index %) (range len))]
        ;; 根据 条件判断是否要执行后面的表达式, 执行成功一次后就不在往后匹配
    `(cond ~@(interleave conditions exprs))))

;; 跟上面的意思一样, 但是随机的表达式会在宏展开的时候确定
(defmacro randomly-2 [& exprs]
  nth exprs (rand-int (count exprs)))
;; 完全随机的，而且代码量也明显减少了
(defmacro randomly-3 [& exprs]
  (let [c (count exprs)]
    `(case (rand-int ~c) ~@(interleave (range c) exprs))))
(comment
  展开是这种形式  
  (macroexpand-1 '(demo.macro/randomly-3 (println "amit") (println "deephi") (println "adi")))
  (clojure.core/case (clojure.core/rand-int 3) 0 (println "amit") 1 (println "deephi") 2 (println "adi"))  
)
;; 模拟从数据库查询用户账户信息
(defn check-credentials [username password]
  true)
(comment
 (会展开类似于这种函数
  (defn kk [{:keys [username password]}] (println (str username password)))
#'demo.core/kk
  )     
)
(defmacro defwebmethod [name args & exprs]
  `(defn ~name [{:keys ~args}]
     ~@exprs))

;; 模拟WEB请求, 自由的从中取出数据
(defwebmethod login-user [username password]
  (if (check-credentials username password)
    (str "Welcome back, " username ", " password " is correct!")
    (str "Login Failed")))

;; 支持命名参数
;; fname 是方法名称 names 是参数名称 body 就是方法体
(defmacro defnn [fname [& names] & body]
  ;; 这一步先得出 之后需要解析的参数的 映射解构 ,类似于 {:keys [name salary start-date]}
  (let [ks {:keys (vec names)}]
    ;; 将传入的参数封装为map (参数大概是这样传入的 :name "aa" :start-date "10/22/2009")
    `(defn ~fname [& {:as arg-map#}]
       ;; 使用 let 读取 map 的值
       (let [~ks arg-map#]
         ;; 执行函数体
         ~@body))))

;; 下面这个方法的参数就可以以命名的方式输入了
(defnn print-details [name salary start-date]
  (println "Name:" name)
  (println "Salary:" salary)
  (println "Started on:" start-date))

;; 用于断言表达式的宏
(defmacro assert-true [test-expr]
  ;; 判断参数是不是多传了一些
  (if-not (= 3 (count test-expr))
    (throw (RuntimeException.
            "Argument must be of the form
              (operator test-expr expected-expr)")))
  ;; 判断操作符是不是定义的这几个
  (if-not (some #(= (first test-expr) %) '(< > <= >= = not=))
    (throw (RuntimeException.
            "operator must be one of < > <= >= = not=")))
  ;; 将断言表达式 绑定为 操作符 左边 右边的表达式
  (let [[operator lhs rhs] test-expr]
    ;; 执行右边的表达式 ，将右边的值绑定到 rhsv 执行整个表达式并绑定到 ret
    `(let [rhsv# ~rhs ret# ~test-expr]
       ;; 假如表达式的解析结果不是true, 就抛出异常
       (if-not ret#
         (throw (RuntimeException.
                 ;; '~lsh 会被转为 (quote (* 2 4)), 意思是把 lhs 符号的值当做数据使用
                 (str '~lhs " is not" '~operator " " rhsv#)))
         ;; 不然就直接返回 true
         true))))
```



## 协议

### 定义协议

```clojure
(defprotocol AProtocolName
  ;; 可选的文档字符串
  "A doc string for Aprotocol abstraction"
  ;; 方法签名, 会为每个多态函数都生成一个变量
  ;; 多态函数根据 第一个参数 this 进行分发
  (bar [this a b] "bar docs")
  (bar [this a] [this a b] [this a b c] "baz docs"))
```

### 参与协议

```clojure
;; 要参与的协议名称
(extend-protocol ExpenseCalculations 
  ;; 作为分派依据的类型
  main.java.com.curry.expenses.Expense
  (total-cents [e]
    (.amountInCents e))
  (is-category? [e some-category]
                (= (.getCategory e) some-category)))
```

- 多个类型可以参与一个协议

```clojure
(extend-protocol ExpenseCalculations 
  ;; 作为分派依据的类型
  main.java.com.curry.expenses.Expense
  (total-cents [e]
    (.amountInCents e))
  (is-category? [e some-category]
                (= (.getCategory e) some-category))
  clojure.lang.IPersistentMap
  (total-cents [e]
    (-> (:amount-dollars e)
        (* 100)
        (+ (:amount-cents e))))
  (is-category? [e some-category]
                (= (:category e) some-category)))
```

- 可以使用 extend-type 宏，让一个类型实现多个协议

```clojure
(extend-type com.curry.expenses.Expense
  ExpenseCalculations
  (total-cents [e]
               (.amountInCents e))
  (is-category? [e some-category]
                (= (.getCategory e) some-category)))
```

- 以上两种定义协议和类型的关系都是封装的 extend 函数

```clojure
(extend com.curry.expenses.Expense
  ExpenseCalculation {
   :total-cents (fn [e]
                  (.amountInCents e))                     
   :is-category? (fn [e some-category]
                   (= (.getCategory e) some-cateogy))})
```

- nil 可以参与协议

### 协议的相关函数

- extends? 查看某个协议是否由某个类型参与

```clojure
(extends? ExpenseCalculations com.curry.expenses.Expense)
```

- extenders 展示参与协议的所有类型

- satisfies? 检查某个类型实例是否参与了该协议 (一定要是实例，而不是类型本身)

# 高阶函数思维

## 收集函数结果

## 模拟简易的面向对象系统

```clojure
(ns demo.functional)

;; 声明一个动态变量 this
(declare ^:dynamic this)

;; 创建实例
(defn new-object [klass]
  ;; 使用 ref 维护一组状态
  (let [state (ref {})]
    ;; 函数名称声明为 thiz 之后给 this 做绑定用
    (fn thiz [command & args]
      (case command
      ;; 输入 ：class 指令返回Class
        :class klass
      ;; 返回 class 的名称
        :class-name (klass :name)
      ;; 设置属性
        :set! (let [[k v] args]
                (dosync (alter state assoc k v))
                nil)
      ;; 获取属性
        :get (let [[key] args]
               (@state key))
        ;; 调用实例方法, 判断实例方法是否存在, 在这里绑定 this
        (let [method (klass :method command)]
          (if-not method
            (throw (RuntimeException. 
                    (str "Unable to respond to " command))))
          (binding [this thiz]
            (apply method args)))
        ))))

;; 定义class的方法,接收 class 名称 方法定义
(defn new-class [class-name parent methods]
  ;; 返回一个函数, klass 是匿名函数的名称,只是为了方便 new-object 引用
  (fn klass [command & args]
    (case command
      :name (name class-name)
      ;; 当调用 :name 时，会返回class的名字
      ;; 父类
      :parent parent
      ;; 通过new来新建对象的实例
      :new (new-object klass)
      ;; 缓存所有方法的引用，供 find-method 寻找
      :methods methods
      ;; 调用实例方法
      :method (let [[method-name] args]
                (find-method method-name klass)))))

;; 定义共通的父类
(def OBJECT (new-class :OBJECT nil {}))

;; 查找方法, 从子类开始往父类上找, 方法表是一个映射
(defn find-method [method-name klass]
  ;; 先从自己的实例中的methods 中寻找method
  (or ((klass :methods) method-name)
      ;; 假如本类不是 OBJECT
      (if-not (= #'OBJECT klass)
        ;; 就去父类中寻找方法
        (find-method method-name (klass :parent)))))


;; 定义方法, 以 '(method age [] (* 2 10)) 为例的话
(defn method-spec [sexpr]
  ;; second 取出向量的第二个值，keyword 将其变为关键字，也就是说 将 age 取出变为 :age
  (let [name (keyword (second sexpr))
        ;; 去掉第一个 method 后面的当做函数 body
        body (next sexpr)]
    ;; 会变为 [:age (fn age [] (* 2 10))], 也即是一个向量，由 名称和匿名函数组成
    [name (conj body 'fn)]))
;; 定义一堆方法
(defn method-specs [sexprs]
  (->> sexprs
       ;; 保留所有第一个符号是 method 的列表
       (filter #(= 'method (first %)))
       ;; 对所有的方法定义应用 method-spec 然后将向量打平，也就是 ([1 2] [2 3]) => (1 2 2 3) 这样
       (mapcat method-spec)
       ;; 以 向量的第一个符号为键，后面的值为值创建映射，也就是会变为 {:age (fn age [] (* 2 10))} 的形式
       (apply hash-map)))

;; 定义父类
(defn parent-class-spec [sexprs]
  ;; 检查 列表中的第一个 符号是不是 exends
  (let [extends-spec (filter #(= 'extends (first %)) sexprs)
        ;; 取出表示继承的列表
        extends (first extends-spec)]
    (if (empty? extends)
      ;; 没有继承的话就去继承OBJECT
      'OBJECT
      ;; 假如不是空的, 就取出要继承的类
      (last extends))))

;; 新建 class 的宏
(defmacro defclass [class-name & specs]
  ;; 解析父类
  ;; 解析方法, 假如没有方法定义就给一个空映射
  (let [parent-class (parent-class-spec specs)
        fns (or (method-specs specs) {})]
    ;; 将类名和解析后的方法定义传给 new-class 方法
    ;; #' 用于将 符号解析为变量, 这里用于将表示父类的符号变为对应的函数 (也就是类)
    `(def ~class-name (new-class '~class-name #'~parent-class ~fns))))

(defclass Person
  (method age [] (* 2 10))
  (method about [diff]
          (str "I was born about " (+ diff (this :age)) " years ago")))

(defclass Woman
  (extends Person)
  (method greet [v] (str "Hello, " v))
  (method age [] (* 2 9)))
```

expense-greater-than

expenses-greater-than