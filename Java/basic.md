## 利用System.arraycopy() 来复制数组
```java
public static void arraycopy(Object src,
                             int srcPos,
                             Object dest,
                             int destPos,
                             int length)

/*
   src : 源数组
   srcPos : 源数组要复制的起始位置
   desc : 目标数组
   destPos : 目标数组的开始起始位置
   length : 要复制的长度
*/

```

该方法在ArrayList 的扩容方法 grow() 中用过

## transient 关键字作用
被该关键字修饰的字段的生命周期仅存在于调用者内存
- 一旦变量被transient修饰，变量将不再是对象持久化的一部分，该变量内容在序列化后无法获得访问。 
- transient关键字只能修饰变量，而不能修饰方法和类。注意，本地变量是不能被transient关键字修饰的。变量如果是用户自定义类变量，则该类需要实现Serializable接口。 
- 被transient关键字修饰的变量不再能被序列化，一个静态变量不管是否被transient修饰，均不能被序列化。

## ArrayList 分析
实现了List,RandomAccess接口，支持插入空数据和随机访问
最重要的属性是 int size, 和 E[] elementData

- add
检查容量，将值插入到尾部，并且 size++
- add 指定index
```java
public void add(int index, E element) {
    rangeCheckForAdd(index);

    ensureCapacityInternal(size + 1);  // Increments modCount!!
    //复制，向后移动,把之前的数据都向后移动一位
    System.arraycopy(elementData, index, elementData, index + 1,
                     size - index);
    elementData[index] = element;
    size++;
}
```
- 扩容方法
```java
private void grow(int minCapacity) {
    // overflow-conscious code
    int oldCapacity = elementData.length;
    //  自动扩容 1.5 倍
    int newCapacity = oldCapacity + (oldCapacity >> 1);
    if (newCapacity - minCapacity < 0)
        newCapacity = minCapacity;
    if (newCapacity - MAX_ARRAY_SIZE > 0)
        newCapacity = hugeCapacity(minCapacity);
    // minCapacity is usually close to size, so this is a win:
    // 复制出一个新的数组，没有的内容以 null填充
    elementData = Arrays.copyOf(elementData, newCapacity);
}
```

所以ArrayList在使用的时候最好指定大小

- 序列化
ArrayList 自定义了 writeObject 和 readObject 来确保只有使用的数据才被序列化了



## LinkedList

## HashSet
基本是利用了HashMap来做的
```java
// 实际存储数据的地方
private transient HashMap<E,Object> map;
// 所有的Key的值
// Dummy value to associate with an Object in the backing Map
private static final Object PRESENT = new Object();
```

- add
```java
public boolean add(E e) {
    return map.put(e, PRESENT)==null;
}
```

##HashMap的源码学习
HashMap是基于数组 + 链表的结构
### 1.7
1.7 的hashMap 真正存放数据的是一个 Entry<K,V> 类型的数组
- HashMap 有个默认的负载因子
```
final float loadFactor
```

这个是用来判断hashMap 何时需要扩容的
比如初始大小是16, 负载因子是 0.75f 那么在 16 * 0.75 = 12 的时候，hashMap 就会扩容
扩容涉及到一系列的复杂操作，所以如果可以预估，请尽量在初始化时就给HashMap合适的容量
- Put方法

```java
public V put(K key, V value) {
    // 空表的话初始化表
    if (table == EMPTY_TABLE) {
        inflateTable(threshold);
    }
    // key为空值的时候插入空值key
    if (key == null)
        return putForNullKey(value);
    // 根据key算出hash值
    int hash = hash(key);
    // 根据算出的hashcode定位到相应的桶
    int i = indexFor(hash, table.length);
    // 如果桶不是空的，则遍历这个链表
    for (Entry<K,V> e = table[i]; e != null; e = e.next) {
        Object k;
        // 判断hash值是否相等,判断key值是否相等
        if (e.hash == hash && ((k = e.key) == key || key.equals(k))) {
            // 是的话覆盖旧的值，返回新的值
            V oldValue = e.value;
            e.value = value;
            e.recordAccess(this);
            return oldValue;
        }
    }

    modCount++;
    // 桶是空的就增加新的值
    addEntry(hash, key, value, i);
    return null;
}
```

- addEntry方法
```java

void addEntry(int hash, K key, V value, int bucketIndex) {
    // 判断是否需要扩容,如果map的长度大于等于数组的长度并且数组的最后一个位置也有值的话，就扩容
    if ((size >= threshold) && (null != table[bucketIndex])) {
        // 需要扩容的话,长度变为两倍，这个key的hash也要重新计算
        resize(2 * table.length);
        hash = (null != key) ? hash(key) : 0;
        // 重新定位
        bucketIndex = indexFor(hash, table.length);
    }

    createEntry(hash, key, value, bucketIndex);
}

void createEntry(int hash, K key, V value, int bucketIndex) {
    Entry<K,V> e = table[bucketIndex];
    // 这个e是当前的，如果有了hash冲突，那么就de元素就成为新元素的下家
    table[bucketIndex] = new Entry<>(hash, key, value, e);
    size++;
}
```
- hash冲突就是说，HashMap中加入新值时，如果 hashcode 相同但是key不同，那么要把旧元素链在新元素上,形成一个链表

### 1.8
- 1.8之后设置了一个新属性，在 put的时候回判断链表的大小，如果超过预设值，就把这个链表改为红黑树

- HashMap 是线程不安全的

- 遍历方式
```
// 这种比较好，可以同时取出KV
Iterator<Map.Entry<String, Integer>> entryIterator = map.entrySet().iterator();
        while (entryIterator.hasNext()) {
            Map.Entry<String, Integer> next = entryIterator.next();
            System.out.println("key=" + next.getKey() + " value=" + next.getValue());
        }
// 这种不太好，需要通过key再取一次value
Iterator<String> iterator = map.keySet().iterator();
        while (iterator.hasNext()){
            String key = iterator.next();
            System.out.println("key=" + key + " value=" + map.get(key));

        }
```

## ConcurrentHashMap
### 1.7
- 核心成员
```java
 /**
 * Segment 数组，存放数据时首先需要定位到具体的 Segment 中。
 */
final Segment<K,V>[] segments;

transient Set<K> keySet;
transient Set<Map.Entry<K,V>> entrySet;
```

```java
 static final class Segment<K,V> extends ReentrantLock implements Serializable {

        private static final long serialVersionUID = 2249069246763182397L;
        
        // 和 HashMap 中的 HashEntry 作用一样，真正存放数据的桶
        transient volatile HashEntry<K,V>[] table;

        transient int count;

        transient int modCount;

        transient int threshold;

        final float loadFactor;
        
    }
```
HashEntry 中的value 和 next都是volatile的，保证了其获取时的可见性

- 原理上来说,采用了分段锁技术，每当一个线程占用锁访问一个segment,不会影响其他的segment

put 和 get方法都看不懂...

## 正则表达式
### 元字符
| 元字符 |            说明            |
|--------|----------------------------|
| .      | 匹配除换行符以外的任意字符 |
| \w     | 匹配字母或数字下划线或汉字 |
| \s     | 匹配任意的空白符           |
| \d     | 匹配数字                   |
| \b     | 匹配单词的开始或结束       |
| ^      | 匹配字符串的开始           |
| $      | 匹配字符串的结束                           |

### 重复限定符
|  语法 |       说明       |
|-------|------------------|
| *     | 重复零次或更多次 |
| +     | 重复一次货更多次 |
| ?     | 重复零次或一次   |
| {n}   | 重复n次          |
| {n,}  | 重复n次或更多次  |
| {n,m} | 重复n到m次                 |

### 分组
正则表达式中使用小括号来做分组，也就是括号中的内容作为一个整体
比如，当要匹配多个 ab 字符时，可以这样写
```
^(ab)*
```

### 转义
可以利用 \ 将元字符,限定符或者关键字转义成普通的字符
```
// 匹配 (ab)
^(\(ab)\)*
```

### 条件或
正则表达式使用 | 来表示或,也叫做分支条件，当满足正则里的分支条件的任何一种条件时，都会当成是匹配成功。
```
^(130|131|132|155|156|185|186|145|176)\d{8}$
```

### 零宽断言
#### 零宽
没有宽度，在正则中，断言只是匹配位置，不占用字符，也就是说，匹配结果里是不会返回断言本身
#### 断言
正则可以指明在指定的内容的前面或后面会出现满足指定规则的内容

#### 正向先行断言(正前瞻)
- 语法 : ( ?=pattern )
- 作用 : 匹配 pattern 表达式前面内容，不返回本身
- 例子
```
// <span class='read-count'>阅读数: 641</span> 匹配其中的数字的话
String reg = "\\d+(?=</span>)"
```

#### 正向后行断言(正后顾):
- 语法: (?<=pattern)
- 作用: 匹配pattern表达式的后面的内容，不返回本身

#### 负向先行断言(负前瞻)
- 语法: (?!pattern)
- 作用: 匹配非 pattern 表达式的前面内容,不返回本身

#### 负向先行断言(负前瞻)
- 语法:(?< !pattern)
- 作用: 匹配非pattern表达式后面面内容，不反返回本身

### 捕获和非捕获
#### 捕获组
匹配子表达式的内容，把匹配结果保存到内存中数字编号或显示命名的组里，以深度优先进行编号，之后可以通过序号或名称来使用这些匹配结果
##### 数字编号捕获组
- 语法 : (exp)
从表达式左侧开始，每出现一个左括号和它对应的右括号之间的内容为一个分组，在分组中，第0组为整个表达式，第一组开始为分组。
```
String test = "020-85653333";
String reg="(0\\d{2})-(\\d{8})";
Pattern pattern = Pattern.compile(reg);
 Matcher mc= pattern.matcher(test);
if(mc.find()){
    System.out.println("分组的个数有："+mc.groupCount());
    for(int i=0;i<=mc.groupCount();i++){
        System.out.println("第"+i+"个分组为："+mc.group(i));
    }
}


// 结果
1 分组的个数有：2
2 第0个分组为：020-85653333
3 第1个分组为：020
4 第2个分组为：85653333

```

##### 命名编号捕获组
- 语法: (?<name>exp)
分组的命名由表达式中的name指定

```
String test = "020-85653333";
String reg = "(?<quhao>0\\d{2})-(?<haoma>\\d{8})";
Pattern pattern = Pattern.compile(reg);
Matcher mc = pattern.matcher(test);
if(mc.find()){
    System.out.println("分组的个数有："+mc.groupCount());
    System.out.println(mc.group("quhao"));
    System.out.println(mc.group("haoma"));
}

// 结果
分组的个数有：2
分组名称为:quhao,匹配内容为：020
分组名称为:haoma,匹配内容为：85653333
```

#### 非捕获组
- 语法 : (?:exp)
和捕获组相反，用于标识那些不需要捕获的分组
```
(?:\0\d{2})-(\d{8})
```

| 序号 | 编号 |       分组       |     内容     |
|------|------|------------------|--------------|
|    0 |    0 | (0\d{2})-(\d{8}) | 020-85653333 |
|    1 |    1 | (\d{8})          | 85653333             |

### 反向引用
捕获会返回一个捕获组，这个分组是保存在内存中，不仅可以在正则表达式外部通过程序进行引用，也可以在正则表达式内部进行引用，这种引用方式就是反向引用

#### 数字编号组反向引用: \k 或 \number
#### 命名编号组反向引用: \k 或 \'name'

反向引用通常和捕获组配合使用，来查找一些重复的内容或者替换指定字符。
```
String test = "aabbbbgbddesddfiid"
Pattern pattern = Pattern.compile("(\\w)\\1");
Matcher mc = pattern.matcher.(test);
while(mc.find()) {
    System.out.println(mc.group());
}

// 结果

1 aa
2 bb
3 bb
4 dd
5 dd
6 ii
```

### 贪婪和非贪婪
#### 贪婪匹配
当正则表达式中包含能接受重复的限定符时，通常的行为是(在使整个表达式能得到匹配的前提下)匹配尽可能多的字符

#### 懒惰
当正则表达式中包含能接受重复的限定符时，通常的行为是(在使整个表达式能得到匹配的前提下)匹配尽可能少的字符
语法: 在贪婪量词后面加个 "?"

|  代码  |           说明           |
|--------|--------------------------|
| *?     | 重复任意次，但尽可能少   |
| +?     | 重复1次或更多次,尽可能少 |
| ？?    | 重复0此或此,尽可能少     |
| {n,m}? | 重复n到m次,尽可能少      |
| {n,}?  | 重复n次以上,尽可能少                         |

### 反义

|  元字符  |                    解释                    |
|----------|--------------------------------------------|
| \W       | 匹配任意不是字母，数字，下划线，汉字的字符 |
| \S       | 匹配任意不是空白符的字符                   |
| \D       | 匹配任意非数字的字符                       |
| \B       | 匹配不是单词开头或结束的位置               |
| [^x]     | 匹配除了x以外的任意字符                    |
| [^aeiou] | 匹配除了aeiou这几个字母以外的任意字符                                           |

### 泛型
#### 泛型类
```
// 类只需要在后面声明泛型即可,也可以写作 <K,V>, <T,E,K>
class DataHolder<T>{
    T item;
    
    public void setData(T t) {
        this.item=t;
    }
    
    public T getData() {
        return this.item;
    }
}

```

#### 泛型方法
可以存在在泛型类，也可以存在于普通类中, 在泛型类和泛型方法中，应当优先选择泛型类
```
class DataHolder<T>{
    T item;
    
    public void setData(T t) {
        this.item=t;
    }
    
    public T getData() {
        return this.item;
    }
    
    /**
     * 泛型方法
     * @param e
     */
     // 泛型方法使用时需声明泛型,就是前面这个 <E>, 如果是泛型类声明过的E则不用在方法上声明了
    public <E> void PrinterInfo(E e) {
        System.out.println(e);
    }

    // 这个T可以是和泛型类的T不一样的类型
    public <T> void test(T t) {

    }
}

```

#### 泛型接口
```
//定义一个泛型接口
public interface Generator<T> {
    public T next();
}


```

- 泛型接口未传入泛型实参时，与泛型类的定义相同，在声明类的时候，需将泛型的声明也一起加到类中
```
/* 即：class DataHolder implements Generator<T>{
 * 如果不声明泛型，如：class DataHolder implements Generator<T>，编译器会报错："Unknown class"
 */
 // 这里必须有个 <T>,不然就会包编译错误
class FruitGenerator<T> implements Generator<T>{
    @Override
    public T next() {
        return null;
    }
}

```

- 如果泛型接口传入类型参数时，实现该泛型接口的实现类，则所有使用泛型的地方都要替换成传入的实参类型
```
class DataHolder implements Generator<String>{
    @Override
    public String next() {
        return null;
    }
}

```

### 泛型擦除
- 运行时无法获取泛型参数信息，为了兼容旧代码的设计
- 编译器虽然会在编译过程中移除参数的类型信息，但是会保证类或方法内部参数类型的一致性
泛型参数将会被擦除到它的第一个边界（边界可以有多个，重用 extends 关键字，通过它能给与参数类型添加一个边界）。编译器事实上会把类型参数替换为它的第一个边界的类型。如果没有指明边界，那么类型参数将被擦除到Object

```
public interface HasF {
    void f();
}

// extends 关键字后面的类型信息决定了泛型参数能保留的信息。Java类型擦除只会擦除到HasF类型
public class Manipulator<T extends HasF> {
    T obj;
    public T getObj() {
        return obj;
    }
    public void setObj(T obj) {
        this.obj = obj;
    }
}

```

- 泛型类型不能显式地运用在运行时类型的操作当中，例如：转型、instanceof 和 new。因为在运行时，所有参数的类型信息都丢失了
```
public class Erased<T> {
    private final int SIZE = 100;
    public static void f(Object arg) {
        //编译不通过
        if (arg instanceof T) {
        }
        //编译不通过
        T var = new T();
        //编译不通过
        T[] array = new T[SIZE];
        //编译不通过
        T[] array = (T) new Object[SIZE];
    }
}
```

- 可以通过以下方法来辅助判断类型
```
/**
 * 泛型类型判断封装类
 * @param <T>
 */
class GenericType<T>{
    Class<?> classType;
    
    public GenericType(Class<?> type) {
        classType=type;
    }
    
    public boolean isInstance(Object object) {
        return classType.isInstance(object);
    }
}


// 调用
GenericType<A> genericType=new GenericType<>(A.class);
System.out.println("------------");
System.out.println(genericType.isInstance(new A()));
System.out.println(genericType.isInstance(new B()));

```

- 创建类型实例
```
/*
泛型代码中不能new T()的原因有两个，一是因为擦除，不能确定类型；而是无法确定T是否包含无参构造函数。
为了避免这两个问题，我们使用显式的工厂模式：
*/

/**
 * 使用工厂方法来创建实例
 *
 * @param <T>
 */
interface Factory<T>{
    T create();
}

class Creater<T>{
    T instance;
    public <F extends Factory<T>> T newInstance(F f) {
        instance=f.create();
        return instance;
    }
}

class IntegerFactory implements Factory<Integer>{
    @Override
    public Integer create() {
        Integer integer=new Integer(9);
        return integer;
    }
}


// 调用
Creater<Integer> creater=new Creater<>();
System.out.println(creater.newInstance(new IntegerFactory()));

```

### 泛型的通配符
#### 上界通配符 <? extends T>
<? extends Fruit> 会使往盘子里放东西的 set() 方法失效，但是get() 方法还有效
Java编译期只知道容器里面存放的是Fruit和它的派生类，具体是什么类型不知道，可能是Fruit？可能是Apple？也可能是Banana，RedApple，GreenApple？编译器在后面看到Plate< Apple >赋值以后，盘子里面没有标记为“苹果”。只是标记了一个占位符“CAP#1”，来表示捕获一个Fruit或者Fruit的派生类，具体是什么类型不知道。所有调用代码无论往容器里面插入Apple或者Meat或者Fruit编译器都不知道能不能和这个“CAP#1”匹配，所以这些操作都不允许。
但是上界通配符是允许读取操作的
所以上界描述符Extends适合频繁读取的场景。

#### 下界通配符 <? super T>
下界通配符的意思是容器中只能存放T及其T的基类类型的数据。
下界通配符<? super T>不影响往里面存储，但是读取出来的数据只能是Object类型。
下界通配符规定了元素最小的粒度，必须是T及其基类，那么我往里面存储T及其派生类都是可以的，因为它都可以隐式的转化为T类型。但是往外读就不好控制了，里面存储的都是T及其基类，无法转型为任何一种类型，只有Object基类才能装下。

#### PECS原则
- 上界<? extends T>不能往里存，只能往外取，适合频繁往外面读取内容的场景。
- 下界<? super T>不影响往里存，但往外取只能放在Object对象里，适合经常往里面插入数据的场景。

#### <?> 无限通配符
无界通配符 意味着可以使用任何对象，因此使用它类似于使用原生类型。但它是有作用的，原生类型可以持有任何类型，而无界通配符修饰的容器持有的是某种具体的类型。举个例子，在List类型的引用中，不能向其中添加Object, 而List类型的引用就可以添加Object类型的变量。

最后提醒一下的就是，List与List并不等同，List是List的子类。还有不能往List<?> list里添加任意对象，除了null。

## 内部类
### 使用内部类的好处
- 每个内部类都能独立地实现一个接口，无论外部类是否实现都没有影响
- 内部类可以用多个实例,每个实例都有自己的状态信息，并且与其他外围对象的信息相互独立
- 在单个外围类中，可以让多个内部类以不同的方式实现同一个接口，或者继承一个类。
- 创建内部类对象的时刻并不依赖于外围类对象的创建。
- 内部类没有令人迷惑的"is-a"关系，他就是一个独立的实体。
- 内部类提供了更好的封装，除了该外围类，其他类都不能访问。

### 内部类的语法
内部类可以无限制的访问外部类的元素
创建某个外部类的内部类时，内部类的对象会捕获一个指向外部类的对象的引用。
```
public class OuterClass {
    private String name ;
    private int age;

    /**省略getter和setter方法**/
    
    public class InnerClass{
        public InnerClass(){
            // private 的，也可以无缝访问
            name = "chenssy";
            age = 23;
        }
        
        public void display(){
            System.out.println("name：" + getName() +"   ;age：" + getAge());
        }
    }
    
    public static void main(String[] args) {
        OuterClass outerClass = new OuterClass();
        // 创建内部类的方法
        OuterClass.InnerClass innerClass = outerClass.new InnerClass();
        innerClass.display();
    }
}
--------------
Output：
name：chenssy   ;age：23
```
内部类是一个编译期的概念，当运行时，会生成两个类

### 成员内部类
成员内部类也是最普通的内部类，它是外围类的一个成员，所以他是可以无限制的访问外围类的所有 成员属性和方法，尽管是private的，但是外围类要访问内部类的成员属性和方法则需要通过内部类实例来访问

- 成员内部类中不能存在任何 static 的变量和方法
- 成员内部类是依附于外部类的，只有先创建了外部类才能创建内部类
- 推荐使用getxxx()来获取成员内部类，尤其是该内部类的构造函数无参数时 。

### 局部内部类
有这样一种内部类，它是嵌套在方法和作用于内的，对于这个类的使用主要是应用与解决比较复杂的问题，想创建一个类来辅助我们的解决方案，到那时又不希望这个类是公共可用的，所以就产生了局部内部类，局部内部类和成员内部类一样被编译，只是它的作用域发生了改变，它只能在该方法和属性中被使用，出了该方法和属性就会失效。

#### 定义在方法中
```
public class Parcel5 {
    public Destionation destionation(String str){
        class PDestionation implements Destionation{
            private String label;
            private PDestionation(String whereTo){
                label = whereTo;
            }
            public String readLabel(){
                return label;
            }
        }
        return new PDestionation(str);
    }
    
    public static void main(String[] args) {
        Parcel5 parcel5 = new Parcel5();
        Destionation d = parcel5.destionation("chenssy");
    }
}
```

#### 定义在作用域内
```
public class Parcel6 {
    private void internalTracking(boolean b){
        if(b){
            class TrackingSlip{
                private String id;
                TrackingSlip(String s) {
                    id = s;
                }
                String getSlip(){
                    return id;
                }
            }
            TrackingSlip ts = new TrackingSlip("chenssy");
            String string = ts.getSlip();
        }
    }
    
    public void track(){
        internalTracking(true);
    }
    
    public static void main(String[] args) {
        Parcel6 parcel6 = new Parcel6();
        parcel6.track();
    }
}
```

### 匿名内部类
略

### 静态内部类
静态内部类没有指向外部类的引用
- 静态内部类的创建不需要依赖外部类
- 静态内部类不能使用外部类的非静态成员和方法

## 匿名内部类中的变量为何需要final修饰
- 匿名内部类编译阶段，编译器会以内部类的形式，帮忙继承该接口,在运行时，会生成一个类，继承该接口，并有一个无参构造器
- 编译期生成匿名内部类的时候局部变量会以参数的形式赋值给内部持有的外部变量，因此可以访问到局部变量，持有外部引用
- 因为局部变量作为参数传入，假如修改了参数，原来的局部变量是不会改变的，所以干脆就不让改变
- 假如想要变量的改变同步，可以用对象封装一下需要改变的值
```java
public class Main {
    public static void main(String[] args) {
        Main main = new Main();
        main.fun();
    }
    public void fun() {
        // 局部变量的对象还是用final修饰
        final TempModel tempModel = new TempModel("Haha");
        System.out.println(tempModel.name);
        new FunLisenter() {
            @Override
            public void fun() {
                System.out.println(tempModel.name);
                // 改变对象的字段的值
                tempModel.name = "Hehe";
            }
        }.fun();
        // 局部变量的修改也同步了
        System.out.println(tempModel.name);
    }
}
public class TempMain {
    private String name;
    public TempMain(String name) {
        this.name = name;
    }
}
```

# 线程池

## 主构造器

```java
ThreadPoolExecutor(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue, RejectedExecutionHandler handler) 

```

- `corePoolSize` : 线程池的基本大小,除非设置了 `allowCoreThreadTimeOut` 不然不会因为空闲而被清除
- `maximumPoolSize`: 线程池最大线程大小
- `keepAliveTime` 和 `unit` :线程空闲后的存活时间。
- `workQueue` : 用于存放任务的阻塞队列
- `handler`: 队列和线程池都满了之后的饱和策略

## 线程池状态

```java
// runState is stored in the high-order bits
// 正常的运行状态
private static final int RUNNING    = -1 << COUNT_BITS;
// 一般是调用了 shutdown的方法，不再接收新的任务，但是会继续执行
private static final int SHUTDOWN   =  0 << COUNT_BITS;
// 调用了 shutdownNow(),不再接收新的任务，也会立即抛弃所有在执行的任务
private static final int STOP       =  1 << COUNT_BITS;
// 所有任务的执行完毕，调用 shutdown() 和 shutdownNow() 后会尝试更新这个状态
private static final int TIDYING    =  2 << COUNT_BITS;
// 终止状态，执行 terminate() 会更新为这个状态
private static final int TERMINATED =  3 << COUNT_BITS;
```



# 数据类型

## Java7 开始，可以在数字字面量上加 _ 方便阅读，编译时会去掉这些__
1_000_000
## Java7 开始,加上前缀0b或0B就可以写二进制数
0b1001就是 9

## 浮点数值不适合用于无法接受误差的金额类计算
主要是因为浮点数值采用二进制系统表示，但是在二进制中无法精确的表示分数 1/10,
金融类的计算应该使用 BigDecimal

## Unicode转义序列会在解析代码之前得到处理
```
"\u0022+\u0022" 不会得到一个 "+"
而是会得到 ""+""
```

## 自增自减
前缀会先执行运算符，后缀会使用原来的变量
PS: 在表达式中使用++可能会带来可读性的问题

## 位运算符

## 大数值
Biglnteger 类实现了任意精度的整数运算， BigDecimal 实现了任意精度的浮点数运算

