# 基础

- groovy 会自动导入 

  - groovy.lang.* 
  - groovy.util.*
  - java.lang.*
  - Java.util.*
  - Java.net.*
  - Java.io.*
  - java.math.Biginteger 和 BigDecimal

  

## 字符串

- 双引号的可以是字符串模板, ${} 可以写表达式

```groovy
def nick = 'ReGina'
def book = 'Groovy in Action, 2nd ed.'
assert "$nick is $book" == 'ReGina is Groovy in Action, 2nd ed.' // true
```

- 三引号也有

```groovy
def egg = '''
asdasdas
asd
as
ds
adas
'''
```

- 三双引号也有

```groovy
def name = 'Groovy'
def template = """
    Dear Mr ${name},

    You're the winner of the lottery!

    Yours sincerly,

    Dave
"""

assert template.toString().contains('Groovy')
```

- 基本用法

```groovy
String greeting = 'Hello Groovy!'

assert greeting.startsWith('Hello')

assert greeting.getAt(0) == 'H'
assert greeting[0] == 'H'

assert greeting.indexOf('Groovy') >= 0
assert greeting.contains('Groovy')

assert greeting[6..11] == 'Groovy'
assert 'Hi' + greeting - 'Hello' == 'Hi Groovy'

assert greeting.count('o') == 3

assert 'x'.padLeft(3) == '  x'
assert 'x'.padRight(3, '_') == 'x__'

assert 'x'.center(3) == ' x '
assert 'x' * 3 == 'xxx'
```

- 改变String, 也就是改变StringBuffer 的用法

```groovy
def greeting = 'Hello'

greeting <<= ' Groovy'

assert greeting instanceof StringBuffer

greeting << '!'

assert greeting.toString() == 'Hello Groovy!'

greeting[1..4] = 'i'

assert greeting.toString() == 'Hi Groovy!'
```

## 正则表达式

p110 待补完

## Number类型

- Number 类型可以调用方法，也可以直接与运算符结合使用

```groovy
def x = 1
def y = 2
assert x + y == 3
assert x.plus(y) == 3
assert x instanceof Integer

```

## 集合类型

### List

```groovy
def list = [1,2,3,4,5,6,7]

assert list[2] == 3

list[7] = 99
assert list.size() == 8
```

- 可以用 -1 去取倒数的

```groovy
def letters = ['a', 'b', 'c', 'd']

assert letters[0] == 'a'     
assert letters[1] == 'b'

assert letters[-1] == 'd'    
assert letters[-2] == 'c'

letters[2] = 'C'             
assert letters[2] == 'C'
// 在 list 末尾加入元素
letters << 'e'               
assert letters[ 4] == 'e'
assert letters[-1] == 'e'
// 获取多个元素，会返回一个新的list
assert letters[1, 3] == ['b', 'd']         
assert letters[2..4] == ['C', 'd', 'e']    
```

- 可以在 list 中使用 range

```groovy
myList = ['a', 'b', 'c', 'd', 'e', 'f']

assert myList[0..2] == ['a', 'b', 'c']
assert myList[0, 2, 4] == ['a', 'c', 'e']

myList[0..2] = ['x', 'y', 'z']
assert myList == ['x', 'y', 'z', 'd', 'e', 'f']

myList[3..5] = []
assert myList == ['x', 'y', 'z']

myList[1..1] = [0, 1, 2]
assert myList == ['x', 0, 1, 2, 'z']

```

- list 和操作符

```groovy
myList = []

myList += 'a'
assert myList == ['a']

myList += ['b', 'c']
assert myList == ['a', 'b', 'c']

myList = []
myList << 'a' << 'b'
assert myList == ['a', 'b']

assert  myList - ['b'] == ['a']

assert myList * 2 == ['a', 'b', 'a', 'b']
```

- 

### Map

```groovy
def colors = [red: '#FF0000', green: '#00FF00', blue: '#0000FF']   
// 取元素
assert colors['red'] == '#FF0000'    
assert colors.green  == '#00FF00'    
// 赋值
colors['pink'] = '#FF00FF'           
colors.yellow  = '#FFFF00'           

assert colors.pink == '#FF00FF'
assert colors['yellow'] == '#FFFF00'

assert colors instanceof java.util.LinkedHashMap

```

- 使用变量做 key

```groovy
def key = 'name'
def person = [key: 'Guillaume']      

assert !person.containsKey('name')   
assert person.containsKey('key') 
// 要这样才能使用变量的值作为key
person = [(key): 'Guillaume']        

assert person.containsKey('name')    
assert !person.containsKey('key')
```



### Range

- .. 表示左右边界都包括在内， ..< 表示排除右边界

- 基本用法

```groovy
def x = 1..10
assert x.contains(5)
assert  !x.contains(15)
assert  x.size()  == 10
assert  x.from == 1
assert  x.to == 10
assert x.reverse() == 10..1
print(x[5])
```

- Range的一些方法

```groovy
def result = ''
// 迭代
(5..9).each { element ->
    result += element
}
assert result == '56789'

assert 5 in 0..10
assert (0..10).isCase(5)

def age = 36
switch (age){
    case 16..20 : insuranceRate = 0.05 ; break
    case 21..50 : insuranceRate = 0.06 ; break
    case 51..65 : insuranceRate = 0.07 ; break
    default: throw new IllegalArgumentException()
}

assert insuranceRate == 0.06

// 过滤
def ages = [20, 36, 42, 56]
def midage = 21..50
assert ages.grep(midage) == [36, 42]
```

- 可以作为Range结构类型的数据需符合两个条件
  - 拓展 ++ 和 -- 操作符
  - 实现 Comparable 接口的 compare 方法, 也就是 拓展 <=> 操作符

```groovy
class Weekday implements Comparable {
    static final DAYS = [
            'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Set'
    ]

    private int index = 0

    Weekday(String day) {
        index = DAYS.indexOf(day)
    }

    Weekday next() {
        return new Weekday(DAYS[(index + 1) % DAYS.size()])
    }

    Weekday previous() {
        return new Weekday(DAYS[index - 1])
    }

    @Override
    int compareTo(Object other) {
        return this.index <=> other.index
    }

    String toString() {
        return DAYS[index]
    }
}

def mon = new Weekday('Mon')
def fri = new Weekday('Fri')

def worklog = ''
for (day in mon..fri) {
    worklog += day.toString() + ' '
}

assert worklog == 'Mon Tue Wed Thu Fri '

```



## 操作符

- 防空: ?.

```groovy
def person = Person.find { it.id == 123 }    
def name = person?.name                      
assert name == null
```

- 方法指向操作符：可以保留一个方法的引用，之后再调用
  - 方法的引用相当于留下了一个闭包

```groovy
def transform(List elements, Closure action) {                    
    def result = []
    elements.each {
        result << action(it)
    }
    result
}
String describe(Person p) {                                       
    "$p.name is $p.age"
}
def action = this.&describe                                       
def list = [
    new Person(name: 'Bob',   age: 42),
    new Person(name: 'Julia', age: 35)]                           
assert transform(list, action) == ['Bob is 42', 'Julia is 35']  
```

 - 方法的引用在运行时解析，可适用于同名的方法的重载

```groovy
def doSomething(String str) { str.toUpperCase() }    
def doSomething(Integer x) { 2*x }                   
def reference = this.&doSomething                    
assert reference('foo') == 'FOO'                     
assert reference(123)   == 246  
```

### 扩散操作符: 收集某个可迭代对象上的所有属性为一个list,null安全的

```groovy
cars = [
   new Car(make: 'Peugeot', model: '508'),
   null,                                              
   new Car(make: 'Renault', model: 'Clio')]
assert cars*.make == ['Peugeot', null, 'Renault']     
assert null*.make == null    
```

​	- 可以用来传递 list 形式的参数

```groovy
int function(int x, int y, int z) {
    x*y+z
}

def args = [4,5,6]

assert function(*args) == 26

```

 - 可以扩散任意可迭代对象

```groovy
def items = [4,5]                      
def list = [1,2,3,*items,6]            
assert list == [1,2,3,4,5,6]   
```

- 也适用于 Map

```groovy
def m1 = [c:3, d:4]                   
def map = [a:1, b:2, *:m1]            
assert map == [a:1, b:2, c:3, d:4] 
```

### 比较操作符 <=>

相当于 compareTo

```groovy
assert (1 <=> 1) == 0
assert (1 <=> 2) == -1
assert (2 <=> 1) == 1
assert ('a' <=> 'z') == -1
```

###  成员操作符

可以用来判断集合内是否有某元素

```groovy
def list = ['Grace','Rob','Emmy']
assert ('Emmy' in list)     
```

### 判断对象的引用

== 操作符相当于 java 的 equals ,要比较对象的引用 使用 is

```groovy
def list1 = ['Groovy 1.8','Groovy 2.0','Groovy 2.3']        
def list2 = ['Groovy 1.8','Groovy 2.0','Groovy 2.3']        
assert list1 == list2                                       
assert !list1.is(list2)
```

### 强转操作符

```groovy
Integer x = 123
String s = x as String 
```

- 可以定义类型的强转规则

```groovy
class Identifiable {
    String name
}
class User {
    Long id
    String name
    // 定义该方法来实现强转
    def asType(Class target) {                                              
        if (target == Identifiable) {
            return new Identifiable(name: name)
        }
        throw new ClassCastException("User cannot be coerced into $target")
    }
}
def u = new User(name: 'Xavier')                                            
def p = u as Identifiable                                                   
assert p instanceof Identifiable                                            
assert !(p instanceof User)  
```

### Call 操作符

类里面定义了 call 方法的话，可以直接类名去调用不用写 call

```groovy
class MyCallable {
    int call(int x) {           
        2*x
    }
}

def mc = new MyCallable()
assert mc.call(2) == 4          
assert mc(2) == 4  
```

### 操作符重载, 类范围内

```groovy
class Bucket {
    int size

    Bucket(int size) { this.size = size }
	// 重载了 + 的操作符
    Bucket plus(Bucket other) {                     
        return new Bucket(this.size + other.size)
    }
}

def b1 = new Bucket(4)
def b2 = new Bucket(11)
assert (b1 + b2).size == 15  

```

可重载的操作符是规定好的, 查看 P100

## 闭包

### 声明闭包

- 最普通的就是直接一个大括号

- 将一个方法重用为闭包

```groovy
class SizeFilter {
    Integer limit

    boolean sizeUpTo(String value) {
        return value.size() <= limit
    }
}

SizeFilter filter5 = new SizeFilter(limit:5)
SizeFilter filter6 = new SizeFilter(limit:6)

// 获取其方法得有引用作为闭包，其实这时limit 已经确定是6了，所以这种做法可以看做是
Closure sizeUpTo6 = filter6.&sizeUpTo

def words = ['long string', 'medium', 'short', 'tiny']

assert 'medium' == words.find(sizeUpTo6)
assert 'short' == words.find(filter5.&sizeUpTo)

```

- 闭包可以继承实例方法的重载特性

```groovy
class MultiMethodSample {
    int mysteryMethod (String value) {
        return value.length()
    }

    int mysteryMethod (List list) {
        return list.size()
    }
    int mysteryMethod (int x, int y) {
        return x+ y
    }
}

MultiMethodSample instance = new MultiMethodSample()
Closure multi = instance.&mysteryMethod

assert 10 == multi('string arg')
assert 3 == multi(['list', 'of', 'values'])
assert 14 == multi(6, 8)
```

### 基本用法

```groovy
// 几种闭包的基本用法
Map map = ['a':1, 'b':2]
map.each {key, value -> map[key] = value * 2}
assert map == ['a':2, 'b':4]

Closure doubler = {key, value -> map[key] = value * 2}

map.each(doubler)
assert map == ['a':4, 'b':8]

def doubleMethod (entry){
    entry.value = entry.value * 2
}

doubler = this.&doubleMethod
map.each(doubler)
assert map == ['a':8, 'b':16]
```

- 可以直接 调用闭包会调用 call() 来调用闭包

```groovy
def adder = {x, y -> return x+y}

assert adder(4, 3) == 7
assert adder.call(2, 6) == 8
```

- 闭包可以给参数定义默认值

```groovy
def adder = {x, y=5 -> return x+y}
```

- 柯里化

```groovy
def mult = {x,y -> return x*y}
def twoTimes = mult.curry(2)
assert twoTimes(5) == 10

// 向绑定右边的参数的话
def twoTimes = {y -> mult 2, y}
```

```groovy
package closuredemo

// 日志的配置器
def configurator = { format, filter, line ->
    filter(line) ? format(line) : null
}


def appender = { config, append, line ->
    def out = config(line)
    // 如果不是 null 的话，就执行 append 打印日志
    if (out) append(out)
}

def dateFormatter = { line -> "${new Date()} : $line"}
def debugFilter = { line -> line.contains('debug') }
def consoleAppender = { line -> println line}

def myConf = configurator.curry(dateFormatter, debugFilter)
def myLog = appender.curry(myConf, consoleAppender)

myLog('here is some debug message')
myLog('this will not be printed')

```

- 组合

```groovy
def fourTimes = twoTimes >> twoTimes
def eightTimes = twoTimes << fourTimes

assert eightTimes(1) == twoTimes(fourTimes(1))
```

- 缓存结果

```groovy
def fib
fib = { it < 2 ? 1 : fib(it -1) + fib(it -2)}
// 缓存结果
fib = fib.memoize()
assert fib(40) == 165_580_141
```

- 闭包实现了 isCase 接口可以用来做谓词判断

```groovy
def odd = { it%2 == 1}
assert [1,2,3].grep(odd) == [1, 3]
switch(10) {
    case odd : assert false
}
if (2 in odd) assert false
```

- 高级用法

```groovy
class Mother {
    def prop = 'prop'
    def method() { 'method' }
    Closure birth (param) {
        def local = 'local'
        def closure = {
            [ this, prop, method(), local, param ]
        }
        return closure
    }
}

Mother julia = new Mother()
def closure = julia.birth('param')

def context = closure.call()

assert context[0] == julia
assert context[1, 2] == ['prop', 'method']
assert context[3, 4] == ['local', 'param']

assert closure.thisObject == julia
// 这个属性值是不会变的
assert closure.owner  == julia

// 这个是可以设置的
assert closure.delegate == julia
assert closure.resolveStrategy == Closure.OWNER_FIRST
```

- resolveStrategy
  - OWNER_ONLY
  - OWNER_FIRST(default)
  - DELEGATE_ONLY
  - DELEGATE_FIRST
  - SELF_ONLY

```
def foo(n) {
    return {n += it}
}
// 将 n 绑定到本地变量1的引用上
def accumulator = foo(1)
//  n 变为了3
assert accumulator(2) == 3
// n 变为了 4
assert accumulator(1) == 4
```



## Groovy 中的 truth

- 表达式是否为true

- Matcher 是否match

- Collection是否为空

- Map是否为空

- 字符串是否为空

- 数字是不是0

- 对象是不是null

  

## Groovy 对象

- 动态获取设置对象的属性

```groovy
class Counter {
    public count = 0
}

def counter = new Counter()

counter.coount = 1
assert counter.count == 1

def fieldName = 'count'
counter[fieldName] = 2
assert counter['count'] == 2

```

- 命名参数和参数的默认值

```groovy
class Summer {
    def sumWithDefaults(a, b, c=0) {
        return a + b + c
    }

    def sumWithList(List args) {
        return args.inject(0){sum, i -> sum +=i}
    }

    def sumWithOptionals(a, b, Object[] optionals) {
        return a + b + sumWithList(optionals.toList())
    }

    def sumNamed(Map args) {
        ['a', 'b', 'c'].each {args.get(it, 0)}
        return args.a + args.b + args.c
    }
}

def summer = new Summer()
assert 2 == summer.sumWithDefaults(1,1)
assert 3 == summer.sumWithDefaults(1,1,1)
assert 2 == summer.sumWithList([1,1])
assert 3 == summer.sumWithList([1,1,1])
assert 2 == summer.sumWithOptionals(1,1)
assert 3 == summer.sumWithOptionals(1,1,1)
assert 2 == summer.sumNamed(a:1, b:1)
assert 3 == summer.sumNamed(a:1, b:1, c:1)
assert 1 == summer.sumNamed(c:1)
```

- ?. 防NULL操作符

```groovy
def map = [a:[b:[c:1]]]

assert map.a.b.c == 1

if (map && map.a && map.a.x) {
    assert map.a.x.c == null
}

try {
    assert map.a.x.c == null
}catch(NullPointerException ignore) {}

// 安全的引用，任意一个为Null 就会返回null,不会报空指针异常
assert map?.a?.x?.c == null
```

- 构造器的用法

```groovy
class VendorWithCtor {
    String name, product
    VendorWithCtor(name, product) {
        this.name = name
        this.product = product
    }
}

// 通常的用法
def first = new VendorWithCtor('Canoo', 'ULC')
//
def second = ['Canoo', 'ULC'] as VendorWithCtor
//
VendorWithCtor third = ['Canoo', 'ULC']
```

- groovy 是运行时分发方法的, 确定参数的类型

```groovy
package objdemo

def oracle(Object o) { return 'object' }
def oracle(String o) { return 'string' }

Object x = 1
Object y = 'foo'

assert 'object' == oracle(x)
assert 'string' == oracle(y)
```

### Trait

```groovy
package objdemo

// 带状态的 trait
trait HasId {
    long id
}

trait HasVersion {
    long version
}

trait Persistent {
    boolean save() {println "saveing ${this.dump()}"}
}

trait Entity implements Persistent, HasId, HasVersion {
    boolean save() {
        version++
        Persistent.super.save()
    }
}

class Publication implements Entity {
    String title
}

class Book extends Publication {
    String isbn
}

Entity gina = new Book(id: 1, version: 1, title: 'gina', isbn: '111111')
// 上面的 Publication 可以不实现Entity, 然后可以使用下面这张方式在运行时完成转变
//Entity gina2 = new Book(title: 'gina', isbn: '11111') as Entity
gina.save()
assert gina.version == 2

```

- expando: 动态添加属性和方法

```groovy
// 不能被Java调用，也不能支持任何类型
def boxer = new Expando()
assert null == boxer.takeThis

boxer.takeThis = 'ouch!'
assert 'ouch!' == boxer.takeThis

boxer.fightBack = { times -> delegate.takeThis * times }
assert 'ouch!ouch!ouch!' == boxer.fightBack(3)
```

- 拓展运算符: *.

```groovy
class Invoice {
    List items
    Date date
}

class LineItem {
    Product product
    int count

    int total() {
        return product.dollar * count
    }
}

class Product {
    String name
    def dollar
}

def ulcDate = Date.parse('yyyy-MM-dd', '2015-01-01')
def otherDate = Date.parse('yyyy-MM-dd', '2015-02-02')
def ulc = new Product(dollar: 1499, name: 'ULC')
def ve = new Product(dollar: 499, name: 'Visual Editor')

def invoices = [
        new Invoice(date: ulcDate, items: [
                new LineItem(count: 5, product: ulc),
                new LineItem(count: 1, product: ve)
        ]),
        new Invoice(date:otherDate, items: [
                new LineItem(count: 4, product: ve)
        ])
]

def allItems = invoices.items.flatten()

assert [5 * 1499, 499, 4 * 499] == allItems*.total()

assert ['ULC'] == allItems.grep{it.total() > 7000}.product.name

def searchDates = invoices.grep{
    it.items.any{it.product == ulc}
}.date*.toString()

assert [ulcDate.toString()] == searchDates
```



## 元编程

- 自定义的 methodMissing

```groovy
class Pretender {
    def methodMissing(String name, Object args) {
        "called $name with $args"
    }
}

def bounce = new Pretender()
// 方法不存在的话，就会调用 methodMissing 方法
assert bounce.hello('world') == 'called hello with [world]'
```

```groovy
class MiniGorm {
    def db = []
    def mehodMissing(String name, Object args) {
        db.find { it[name.toLowerCase() - 'findby'] == args[0]}
    }
}

def people = new MiniGorm()
def dierk = [first: 'Dierk', last:'Koenig']
def paul = [first: 'Paul', last:'King']
people.db << dierk << paul

assert people.findByFirst('Dierk') == dierk
assert people.findByLast('King') == paul
```

- custom propertyMissing

```groovy
class PropPretender {
    def propertyMissing(String name) {
        "accessed $name"
    }
}

def bounce = new PropPretender()
assert bounce.hello == 'accessed hello'
```

- 闭包的钩子函数

```groovy
class DynamicPretender {
    Closure whatToDo = { name -> "accessed $name" }
    def propertyMissing(String name) {
        whatToDo(name)
    }
}
def one = new DynamicPretender()
assert one.hello == 'accessed hello'
// 在运行时改变 闭包的行为，从而改变了 hook 的行为
one.whatToDo = { name -> name.size() }
assert one.hello == 5
```

- 自定义 GroovyObject 方法， 继承 GroovyObject 的方法会继续以下规则

  - 所有获取属性的方法都会调用 getProperty() 方法
    - 显式定义 getProperty() 会让所有属性都通过该方法获得，所以 propertyMissing 就失效了
  - 所有设置属性的方法都会调用 setProperty() 方法
  - 任何未知的方法调用都会调用 invokeMethod。想让已知的方法调用的话，必须同时实现 GroovyObject 和 GroovyInterceptable

  ```groovy
  class NoParens {
      // 使用 property 来区分是要获取属性还是调用方法
      def getProperty(String propertyName) {
          if (metaClass.hasProperty(this, propertyName)) {
              return metaClass.getProperty(this, propertyName)
          }
          invokeMethod propertyName, null
      }
  }
  
  class PropUser extends NoParens {
      boolean existingProperty = true
  }
  
  def user = new PropUser()
  assert user.existingProperty
  assert user.toString() == user.toString
  ```

- 增加大量原型方法

```groovy
def move(string, distance) {
    string.collect { (it as char) + distance as char }.join()
}

String.metaClass {
    shift = -1
    encode { -> move delegate, shift }
    decode { -> move delegate, -shift }
    getCode { -> encode() }
    getOrig { -> decode() }
}

assert "IBM".encode() == "HAL"
assert "HAL".orig == "IBM"

def ibm = "IBM"
ibm.shift = 7
assert ibm.code == "PIT"
```

- 在原型上增加静态方法

```groovy
Integer.metaClass.static.answer = { ->42 }

assert Integer.answer() == 42
```

- 子类能继承父类动态增加的内容

```groovy
class MySuperGroovy {}
class MySubGroovy extends MySuperGroovy {}

// 给父类动态添加一个闭包
MySuperGroovy.metaClass.added = {-> true}
// 子类也获得了这个闭包
assert new MySubGroovy().added()

Map.metaClass.toTable = { ->
    delegate.collect { [it.key, it.value] }
}

assert [a:1, b:2].toTable() == [
        ['a', 1],
        ['b', 2]
]
```

- 一些关于 metaclass 的规则
  -  所有的方法在调用的时候都会经过其 metaclass
  - 改变 class 的 metaclass 会改变其全部的实例的行为, 改变单个class的 metaclass 只会影响到单个实例
  - metaclass 的改变带来的影响与线程是无关的
  - metaclass 同时允许在 groovy 和 java 代码里进行非入侵的改变, final 的 class 也可以
  - metaclass 可以通过 property accessors, operator methods, GroovyObject methods, MOP hook methods 等方式增强
  - ExpandoMetaClass
  - metaclass 的增强最好只在程序初始化的时候运行一次就可以了
-  临时变动

```groovy
import groovy.time.TimeCategory

def janFirst1970 = new Date(0)
// 临时变动一下, 离开闭包的作用域就无效了
use TimeCategory, {
    Date xmas = janFirst1970 + 1.year - 7.days
    assert xmas.month == Calendar.DECEMBER
    assert xmas.date = 25
}
// 临时变动一下, 离开闭包的作用域就无效了
use Collections, {
    def list = [0, 1, 2, 3]
    list
}
```

### Category Class

- 任何 Class 在作为 use 的参数后会成为 Category class
- 只要 Receiver 有一个以下形式的实例方法 
  - ReturnType methodName(optionalArgs) {...}
- 就可以在 category 类中使用以下形式的静态方法
  - static ReturnType methodName(Receiver self, optionalArgs)

```groovy
class Marshal {
    static String marshal(Integer self) {
        self.toString()
    }

    static Integer unMarshal(String self) {
        self.toInteger()
    }
}

use Marshal, {
    assert 1.marshal() == "1"
    assert "1".unMarshal() == 1
    [Integer.MIN_VALUE, -1, 0, Integer.MAX_VALUE].each {
        assert it.marshal().unMarshal() == it
    }
}
```

- 最好不要用在并行环境中, 因为该方法会共享状态
- 可以随便使用任何一个由静态方法的 Class 来 作为 Category 来使用



### Extension Modules p256

### @Category

```groovy
// 声明一个 Receiver
@Category(Integer)
class IntegerMarshal {
    String marshal() {
        toString()
    }
}

@Category(String)
class StringMarshal {
    Integer unMarshal() {
        this.toInteger()
    }
}

use ([IntegerMarshal, StringMarshal]) {
    assert 1.marshal() == "1"
    assert "1".unMarshal() == 1
}
```

### Mixin

已过期，不管了

### 利用 metaClass 增强代码的表现力

```groovy
Number.metaClass {
    getMm = { delegate }
    getCm = { delegate * 10.mm }
    getM = { delegate * 100.cm}
}

assert 1.m + 20.cm - 8.mm == 1.192.m
```

### 提供工厂方法

```groovy
Class.metaClass.make = { Object[] args ->
    delegate.metaClass.invokeConstructor(*args)
}

assert new HashMap() == HashMap.make()
assert new Integer(42) == Integer.make(42)
```

### 看上去是在设置属性，其实是在调用方法，极具迷惑性的代码

```groovy
interface ChannelComponent {}
class Producer implements ChannelComponent {
    List<Integer> outChannel
}
class Adaptor implements ChannelComponent {
    List<Integer> inChannel
    List<String> outChannel
}
class Printer implements ChannelComponent {
    List<String> inChannel
}

class WiringCategory {
    static connections = []
    static setInChannel(ChannelComponent self, value) {
        connections << [target:self, source:value]
    }

    static getOutChannel(ChannelComponent self) {
        self
    }
}

Producer producer = new Producer()
Adaptor adaptor = new Adaptor()
Printer printer = new Printer()

use WiringCategory, {
    // 这里相当于这样调用 WiringCategory.setInChannel(adaptor, WiringCategory.getOutChannel(producer))
    // 以下同理
    adaptor.inChannel = producer.outChannel
    printer.inChannel = adaptor.outChannel
}

assert WiringCategory.connections = [
        [source: producer, target: adaptor],
        [source: adaptor, target: printer]
]
```

### 改变原型方法并还原

```groovy
MetaClass oldMetaClass = String.metaClass
// 找到 instance 方法 size
MetaMethod alias = String.metaClass.metaMethods.find { it.name == 'size' }

String.metaClass {
    // 保留原有的 size 方法
    oldSize = { -> alias.invoke delegate }
    // 改变 size 方法的行为
    size = { -> oldSize() * 2 }
}
// 看到原型方法被变更了
assert 'abc'.size() == 6
assert 'abc'.oldSize() == 3
// 还原
if (oldMetaClass.is(String.metaClass)) {
    String.metaClass {
        size = { -> alias.invoke delegate }
        oldSize = { -> throw new UnsupportedOperationException() }
    }
} else {
    String.metaClass = oldMetaClass
}

assert 'abc'.size() == 3
```

### 使用MOP

```groovy
ArrayList.metaClass.methodMissing = { String name, Object args ->
    assert name.startsWith('findBy')
    assert args.size() == 1
    // 将这个方法加到 Object 的 原型方法上，这样下次调用就不会到 methodMissing 这来
    Object.metaClass."$name" = { value ->
        delegate.find { it[name.toLowerCase() - 'findby'] == value }
    }
    delegate."$name"(args[0])
}

def data = [
        [name:'moon', au: 0.0025],
        [name:'sun', au:1],
        [name:'neptune', au:30],
]

assert data.findByName('moon')
assert data.findByName('sun')
assert data.findByAu(1)
```

# 编译器元编程和AST转换

## 编译期生效的注解

### @toString

### @EqualsAndHashCode

### @TupleConstructor

### @Lazy

### @IndexedProperty

```groovy
class Author {
    String name
    @IndexedProperty List<String> books
}

def books = [
        'The Mysterious Affair at Styles',
        'The Murder at the Vicarage'
]

new Author(name: 'Agatha Christie', books: books).with {
    books[0] = 'Murder on the Orient Express'
    setBooks(0, 'Death on the Nile')
    assert getBooks(0) == 'death on the Nile'
}
```

### InheritConstructors

可以帮助调用父类的构造器

```groovy
import groovy.transform.InheritConstructors

@InheritConstructors
class MyPrintWriter extends PrintWriter {}

def pw1 = new MyPrintWriter(new File('out1.txt'))
def pw2 = new MyPrintWriter('out2.txt', 'US-ASCII')
[pw1, pw2].each {
    // 写入文本
    it << 'foo'
    it.close()
}
assert new File('out1.txt').text == new File('out2.txt').text
['out1.txt', 'out2.txt'].each { new File(it).delete() }
```

### Sortable: 生成 Comparable / Comparator 方法

```groovy
@Sortable(includes = 'last initial')
class Politician {
    String first
    Character initial
    String last
    String initials() { first[0] + initial + last[0] }
}

def politicians = [
        new Politician(first: 'Margaret', initial: 'H', last: 'Thatcher'),
        new Politician(first: 'George', initial: 'W', last: 'Bush')
]
// 排序，因为B在前，所以 第二个排到前面去了
def sorted = politicians.toSorted()
assert sorted*.initials() == ['GWB', 'MHT']
// 获取原来的排序规则
def byInitial = Politician.comparatorByInitial()
sorted = politicians.toSorted(byInitial)
// 默认的排序规则
assert sorted*.initials() == ['MHT', 'GWB']
```

### Builder: 生成builder模式

```groovy
@Builder
class Chemist {
    String first
    String last
    int born
}

def builder = Chemist.builder()
def c = builder.first("Marie").last("Curie").born(1867).build()
assert c.first == "Marie"
assert c.last == "Curie"
assert c.born == 1867

```

- 内置了4种生成策略，也可以实现自己的, 具体查询文档

## 类模式和设计模式注解

### @Canonical

结合了 @ToString @EqualsAndHashCode @TupleConstructor 注解的注解

### @Immutable

用于创建不可变类

### @Delegate 用于创建委托类

```groovy
class NoisySet {
    @Delegate
    Set delegate = new HashSet()

    boolean add(item) {
        println "adding $item"
        delegate.add(item)
    }

    boolean addAll(Collection items) {
        items.each { println "adding $it" }
        delegate.addAll(items)
    }
}

Set ns = new NoisySet()
ns.add(1)
ns.addAll([2, 3])
// 使用了代理注解生成的方法
assert ns.size() == 3
```

### Singleton: 实现单例

```groovy
@Singleton
class Zeus {
}

assert Zeus.instance
def ex = shouldFail(RuntimeException) { new Zeus() }
assert ex.message == 'cannot instantiate singleton Zeus. Use Zeus.instance'
```

### Memoized: 缓存方法的返回值

```groovy
class Calc {
    def log = []

    @Memoized
    int sum(int a, int b) {
        log << "$a+$b"
        a+b
    }
}

new Calc().with {
    assert sum(3, 4) == 7
    assert sum (4, 4) ==8
    assert sum (3, 4) ==7
    assert  log.join(' ') == '3+4 4+4'
}
```

### TailRecursive: 尾递归

```groovy
class ListUtil {
    static reverse(List list) {
        doReverse(list, [])
    }

    @TailRecursive
    private static doReverse(List todo, List done) {
        if (todo.isEmpty()) done
        else doReverse(todo.tail(), [todo.head()] + done)
    }
}

assert  ListUtil.reverse(['a', 'b', 'c']) == ['c', 'b', 'a']
```

## Log 相关的注解

- 首先根据类名创建一个 logger 
- 假如 日志等级并没有打开，那么 相应的日志方法并不会打印
- 假如 传给日志的参数是一个常量，那么就不会检查日志等级直接打印
- 五个主要的日志注解
  - @Log: JDK 自带注解 初始化为: Logger.getLogger(class.name)
  - @Commons : Apache Commons 的logger， 初始化方法为 LogFactory.getLog(class)
  - @Log4j: 初始化为 Logger.getLogger(class)
  - @Log4g2: 初始化为 Logger.getLogger(class)
  - @Slf4j: 初始化为 LoggerFactory.getLogger(class)

## 同步锁相关的注解

略过

## 克隆相关的注解

### AutoClone

```groovy
@AutoClone
class Chef1 {
    String name
    List<String> recipes
    Date born
}

def name = 'Heston Bluemthal'
def recipes = ['Snail porridge', 'Bacon & egg ice cream']
def born = Date.parse('yyyy-MM-dd', '1966-05-27')
def c1 = new Chef1(name: name, recipes: recipes, born: born)
def c2 = c1.clone()
assert c2.recipes == recipes
```

p297

更多的查文档

## 脚本支持

### TimeInterrupt

- 设置最多允许存在的类，假如超过了就抛出 TimeoutException
- 每次方法调用， 闭包执行的第一行，for或while循环前检查

### ThreadInterrupt

- 检查当前线程是不是被 interrupted的了

### ConditionalInterrupt

- 设定自定义逻辑定义 interrupted 的情况

### Filed

- 脚本中创建的变量通常是一个本地变量
- 用该注解标注的变量会升格为成员变量

### BaseScript

- 可以指定脚本的父类

## 理解AST

### Groovy脚本的解析过程

- Read source
- Parse source
- Convert to AST
- Convert to bytecode
- Load class
- Execute

