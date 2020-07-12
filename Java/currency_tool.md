# Lock&Condition

- Lock 用于解决互斥问题
- Condition 用于解决同步问题

## Lock

### 破坏不可抢占性

破解死锁难题时，需要破坏锁的不可抢占性

假如 线程A 获取了 锁a后，去获取锁b时失败了，线程进入了阻塞，其它线程无法获取到锁a

这就是锁是不可抢占的，就容易发生死锁

解决这个问题，有三个思路

- 能够响应中断: 可以给阻塞的线程A发送中断信号，让其退出
- 支持超时：一定时间获取不到后自动退出
- 没有获取到锁就返回

Lock 正好支持这三个

```java
// 支持中断的 API
void lockInterruptibly() 
  throws InterruptedException;
// 支持超时的 API
boolean tryLock(long time, TimeUnit unit) 
  throws InterruptedException;
// 支持非阻塞获取锁的 API
boolean tryLock();
```

### 如何保证可见性

```java
class X {
  private final Lock rtl =
、  new ReentrantLock();
  int value;
  public void addOne() {
    // 获取锁
    rtl.lock();  
    try {
      // 线程T2能看到T1对value的修改
      value+=1;
    } finally {
      // 保证锁能释放
      rtl.unlock();
    }
  }
}
```

### 可重入锁

ReentrantLock 是一个可重入锁

## 公平锁与非公平锁

- ReentrantLock 的构造函数可以决定创造一个公平锁还是非公平锁
- 如果一个线程没有获得锁，就会进入等待队列，当有线程释放锁的时候，就需要从等待队列中唤醒一个等待的线程
  - 公平锁的话: 等待时间最长的线程获取锁
  - 非公平锁：随机唤醒一个



### 用锁的最佳实践

- 永远只在更新对象的成员变量时加锁
- 永远只在访问可变的成员变量时加锁
- 永远不在调用其他对象的方法时加锁



## Condition

可以用于写有多个条件变量的程序，可读性更好

阻塞队列的例子

```java
public class BlockedQueue<T>{
  final Lock lock =
    new ReentrantLock();
  // 条件变量：队列不满  
  final Condition notFull =
    lock.newCondition();
  // 条件变量：队列不空  
  final Condition notEmpty =
    lock.newCondition();
 
  // 入队
  void enq(T x) {
    lock.lock();
    try {
      while (队列已满){
        // 等待队列不满
        notFull.await();
      }  
      // 省略入队操作...
      // 入队后, 通知可出队
      notEmpty.signal();
    }finally {
      lock.unlock();
    }
  }
  // 出队
  void deq(){
    // 这个lock和上面那个lock会导致多线程之间无法出队入队，已验证
    lock.lock();
    try {
      while (队列已空){
        // 等待队列不空
        notEmpty.await();
      }  
      // 省略出队操作...
      // 出队后，通知可入队
      notFull.signal();
    }finally {
      lock.unlock();
    }  
  }
}
```



## 信号量

### 信号量模型

- Init(): 设置计数器的初始值
- down(): 计数器的值减 1；如果此时计数器的值小于 0，则当前线程将被阻塞，否则当前线程可以继续执行
- up(): 计数器的值加 1；如果此时计数器的值小于或者等于 0，则唤醒等待队列中的一个线程，并将其从等待队列中移除

信号量最大的特点就是可以通过设置 init 的值来决定有多少个线程可以访问临界区

#### Java中的信号量SDK

```java
class ObjPool<T, R> {
  final List<T> pool;
  // 用信号量实现限流器
  final Semaphore sem;
  // 构造函数
  ObjPool(int size, T t){
    pool = new Vector<T>(){};
    for(int i=0; i<size; i++){
      pool.add(t);
    }
    sem = new Semaphore(size);
  }
  // 利用对象池的对象，调用 func
  R exec(Function<T,R> func) {
    T t = null;
    sem.acquire();
    try {
      // 因为允许多个线程进入临界区，因此 List<T> 的实现需要是线程安全的容器,因此使用 Vector
      t = pool.remove(0);
      return func.apply(t);
    } finally {
      pool.add(t);
      sem.release();
    }
  }
}
// 创建对象池
ObjPool<Long, String> pool = 
  new ObjPool<Long, String>(10, 2);
// 通过对象池获取 t，之后执行  
pool.exec(t -> {
    System.out.println(t);
    return t.toString();
});
```



# ReadWriteLock

适用于读多写少的场景

### 读写锁普遍遵守的三个原则

- 允许多个线程同时读共享变量
- 只允许一个线程写共享变量
- 如果一个写线程正在执行写操作，此时禁止读线程读共享变量

### Java中的ReadWriteLock

```java
// 缓存的按需加载，不存在的时候去数据库查询
// 有可能多个线程都去数据库查询了，所以获取到写锁后，要再检查一遍是不是已经在缓存了
class Cache<K,V> {
  final Map<K, V> m =
    new HashMap<>();
  final ReadWriteLock rwl = 
    new ReentrantReadWriteLock();
  // 读锁是为了能够与写锁互斥
  final Lock r = rwl.readLock();
  // 写锁自然是为了写写互斥
  final Lock w = rwl.writeLock();
 
  V get(K key) {
    V v = null;
    // 读缓存
    r.lock();         
    try {
      v = m.get(key); 
    } finally{
      r.unlock();     
    }
    // 缓存中存在，返回
    if(v != null) {   
      return v;
    }  
    // 缓存中不存在，查询数据库
    w.lock();         
    try {
      // 再次验证
      // 其他线程可能已经查询过数据库
      v = m.get(key); ⑥
      if(v == null){  ⑦
        // 查询数据库
        v= 省略代码无数
        m.put(key, v);
      }
    } finally{
      w.unlock();
    }
    return v; 
  }
}

```

### 锁的升级和降级

锁的升级是不允许的

```java
// 读缓存
r.lock();         ①
try {
  v = m.get(key); ②
  if (v == null) {
  // 在没释放读锁的时候就去获取写锁，会造成永久阻塞
    w.lock();
    try {
      // 再次验证并更新缓存
      // 省略详细代码
    } finally{
      w.unlock();
    }
  }
} finally{
  r.unlock();     ③
}
```

锁可以降级

```java
class CachedData {
  Object data;
  volatile boolean cacheValid;
  final ReadWriteLock rwl =
    new ReentrantReadWriteLock();
  // 读锁  
  final Lock r = rwl.readLock();
  // 写锁
  final Lock w = rwl.writeLock();
  
  void processCachedData() {
    // 获取读锁
    r.lock();
    if (!cacheValid) {
      // 释放读锁，因为不允许读锁的升级
      r.unlock();
      // 获取写锁
      w.lock();
      try {
        // 再次检查状态  
        if (!cacheValid) {
          data = ...
          cacheValid = true;
        }
        // 释放写锁前，降级为读锁
        // 降级是可以的, 也就是说可以在获取写锁后再去获取读锁
        r.lock(); ①
      } finally {
        // 释放写锁
        w.unlock(); 
      }
    }
    // 此处仍然持有读锁
    try {use(data);} 
    finally {r.unlock();}
  }
}
```



# StampedLock

### 三种模式

- 写锁: 类似于 ReadWriteLock 的写锁
- 悲观读锁: 类似于 ReadWriteLock 的读锁
- 乐观读 : 不会与写操作互斥

```java
final StampedLock sl = 
  new StampedLock();
  
// 获取 / 释放悲观读锁示意代码
long stamp = sl.readLock();
try {
  // 省略业务相关代码
} finally {
  sl.unlockRead(stamp);
}
 
// 获取 / 释放写锁示意代码
long stamp = sl.writeLock();
try {
  // 省略业务相关代码
} finally {
  sl.unlockWrite(stamp);
}
```

```java
class Point {
  private int x, y;
  final StampedLock sl = 
    new StampedLock();
  // 计算到原点的距离  
  // 感觉就是先乐观读一下，假如发现不对，就升级为悲观锁
  int distanceFromOrigin() {
    // 乐观读
    long stamp = 
      sl.tryOptimisticRead();
    // 读入局部变量，
    // 读的过程数据可能被修改
    int curX = x, curY = y;
    // 判断执行读操作期间，
    // 是否存在写操作，如果存在，
    // 则 sl.validate 返回 false
    if (!sl.validate(stamp)){
      // 升级为悲观读锁
      stamp = sl.readLock();
      try {
        curX = x;
        curY = y;
      } finally {
        // 释放悲观读锁
        sl.unlockRead(stamp);
      }
    }
    return Math.sqrt(
      curX * curX + curY * curY);
  }
}

```

### 使用的注意事项

- 不可重入
- 悲观读锁，写锁并不支持条件变量
- 如果线程阻塞在 StampedLock 的 readLock() 或者 writeLock() 上时，此时调用该阻塞线程的 interrupt() 方法，会导致 CPU 飙升

```java
final StampedLock lock
  = new StampedLock();
Thread T1 = new Thread(()->{
  // 获取写锁
  lock.writeLock();
  // 永远阻塞在此处，不释放写锁
  LockSupport.park();
});
T1.start();
// 保证 T1 获取写锁
Thread.sleep(100);
Thread T2 = new Thread(()->
  // 阻塞在悲观读锁
  lock.readLock()
);
T2.start();
// 保证 T2 阻塞在读锁
Thread.sleep(100);
// 中断线程 T2
// 会导致线程 T2 所在 CPU 飙升
T2.interrupt();
T2.join();

```

- 使用 StampedLock 一定不要调用中断操作，如果需要支持中断功能，一定使用可中断的悲观读锁 readLockInterruptibly() 和写锁 writeLockInterruptibly()
- 可以升级和降级

```java
private double x, y;
final StampedLock sl = new StampedLock();
// 假如在原点(x=0,y=0)就移动的方法
void moveIfAtOrigin(double newX, double newY){
 long stamp = sl.readLock();
 try {
   // 读到变量发现不满足要求后
  while(x == 0.0 && y == 0.0){
    // 转换为写锁
   // 返回值为0说明转换失败了,可能锁已经被别人获取了
    // 这里，参数是读锁的stamp，假如写锁不可用，就会返回0
    long ws = sl.tryConvertToWriteLock(stamp);
    if (ws != 0L) {
      x = newX;
      y = newY;
      // 记得要换成新的锁的返回值
      stamp = ws
      break;
    } else {
      sl.unlockRead(stamp);
      stamp = sl.writeLock();
    }
  }
 } finally {
  sl.unlock(stamp);
}
```



### 使用模板

#### 读模板

```java
final StampedLock sl = 
  new StampedLock();
 
// 乐观读
long stamp = 
  sl.tryOptimisticRead();
// 读入方法局部变量
......
// 校验 stamp
if (!sl.validate(stamp)){
  // 升级为悲观读锁
  stamp = sl.readLock();
  try {
    // 读入方法局部变量
    .....
  } finally {
    // 释放悲观读锁
    sl.unlockRead(stamp);
  }
}
// 使用方法局部变量执行业务操作
......

```

#### 写模板

```java
long stamp = sl.writeLock();
try {
  // 写共享变量
  ......
} finally {
  sl.unlockWrite(stamp);
}
```



# CountDownLatch 和 CyclicBarrier

## CountDownLatch 可以用来实现线程等待

```java
// 创建 2 个线程的线程池
Executor executor = 
  Executors.newFixedThreadPool(2);
while(存在未对账订单){
  // 计数器初始化为 2
  CountDownLatch latch = 
    new CountDownLatch(2);
  // 查询未对账订单
  executor.execute(()-> {
    pos = getPOrders();
    latch.countDown();
  });
  // 查询派送单
  executor.execute(()-> {
    dos = getDOrders();
    latch.countDown();
  });
  
  // 等待两个查询操作结束
  latch.await();
  
  // 执行对账操作
  diff = check(pos, dos);
  // 差异写入差异库
  save(diff);
}
```

## CyclicBarrier 可以用来实现线程同步

```java
// 订单队列
Vector<P> pos;
// 派送单队列
Vector<D> dos;
// 执行回调的线程池 
Executor executor = 
  Executors.newFixedThreadPool(1);
final CyclicBarrier barrier =
  new CyclicBarrier(2, ()->{
    executor.execute(()->check());
  });
  
void check(){
  P p = pos.remove(0);
  D d = dos.remove(0);
  // 执行对账操作
  diff = check(p, d);
  // 差异写入差异库
  save(diff);
}
  
void checkAll(){
  // 循环查询订单库
  Thread T1 = new Thread(()->{
    while(存在未对账订单){
      // 查询订单库
      pos.add(getPOrders());
      // 等待
      barrier.await();
    }
  }
  T1.start();  
  // 循环查询运单库
  Thread T2 = new Thread(()->{
    while(存在未对账订单){
      // 查询运单库
      dos.add(getDOrders());
      // 等待
      barrier.await();
    }
  }
  T2.start();
}

```



- 比起这两个工具类，其实 Promise模型更好用



## 并发容器

### List

#### CopyOnWriteArrayList

- 读操作完全无锁
- 迭代操作是只读的，因为只是迭代快照
- 适用于写操作比较少的场景

### Map

#### ConcurrentHashMap

- key 无序

#### ConcurrentSkipListMap

- 是有跳表
- key 有序



### Set

#### CopyOnWriteArraySet

#### ConcurrentSkipListSet



### Queue

#### 单端阻塞队列

##### ArrayBlockingQueue

- 队列是数组

##### LinkedBlockingQueue

- 队列是链表

##### SynchronousQueue

- 无队列

##### LinkedTransferQueue

##### PriorityBlockingQueue

- 优先级队列

##### DelayQueue

- 支持延时出队



#### 双端阻塞队列

##### LinkedBlockingDeque



#### 单端非阻塞队列

##### ConcurrentLinkedQueue



#### 双端非阻塞队列

##### ConcurrentLinkedDeque



## CompletionService

感觉还是不如Future



## ForkJoin

```java
static void main(String[] args){
  //创建分治任务线程池  
  ForkJoinPool fjp = 
    new ForkJoinPool(4);
  //创建分治任务
  Fibonacci fib = 
    new Fibonacci(30);   
  //启动分治任务  
  Integer result = 
    fjp.invoke(fib);
  //输出结果  
  System.out.println(result);
}
//递归任务
// RecursiveTask 是有返回值的， RecursiveAction 是没有返回值的
static class Fibonacci extends 
    RecursiveTask<Integer>{
  final int n;
  Fibonacci(int n){this.n = n;}
  protected Integer compute(){
    if (n <= 1)
      return n;
    Fibonacci f1 = 
      new Fibonacci(n - 1);
    //创建子任务  
    f1.fork();
    Fibonacci f2 = 
      new Fibonacci(n - 2);
    //等待子任务结果，并合并结果  
    return f2.compute() + f1.join();
  }
}
```

```java
static void main(String[] args){
  String[] fc = {"hello world",
          "hello me",
          "hello fork",
          "hello join",
          "fork join in world"};
  //创建ForkJoin线程池    
  ForkJoinPool fjp = 
      new ForkJoinPool(3);
  //创建任务    
  MR mr = new MR(
      fc, 0, fc.length);  
  //启动任务    
  Map<String, Long> result = 
      fjp.invoke(mr);
  //输出结果    
  result.forEach((k, v)->
    System.out.println(k+":"+v));
}
//MR模拟类
static class MR extends 
  RecursiveTask<Map<String, Long>> {
  private String[] fc;
  private int start, end;
  //构造函数
  MR(String[] fc, int fr, int to){
    this.fc = fc;
    this.start = fr;
    this.end = to;
  }
  @Override protected 
  Map<String, Long> compute(){
    if (end - start == 1) {
      return calc(fc[start]);
    } else {
      int mid = (start+end)/2;
      MR mr1 = new MR(
          fc, start, mid);
      mr1.fork();
      MR mr2 = new MR(
          fc, mid, end);
      //计算子任务，并返回合并的结果    
      return merge(mr2.compute(),
          mr1.join());
    }
  }
  //合并结果
  private Map<String, Long> merge(
      Map<String, Long> r1, 
      Map<String, Long> r2) {
    Map<String, Long> result = 
        new HashMap<>();
    result.putAll(r1);
    //合并结果
    r2.forEach((k, v) -> {
      Long c = result.get(k);
      if (c != null)
        result.put(k, c+v);
      else 
        result.put(k, v);
    });
    return result;
  }
  //统计单词数量
  private Map<String, Long> 
      calc(String line) {
    Map<String, Long> result =
        new HashMap<>();
    //分割单词    
    String [] words = 
        line.split("\\s+");
    //统计单词数量    
    for (String w : words) {
      Long v = result.get(w);
      if (v != null) 
        result.put(w, v+1);
      else
        result.put(w, 1L);
    }
    return result;
  }
}
```



# 两阶段终止模式

- 线程T1向线程T2发送终止指令
- T2 响应终止指令

```java
class Proxy {
  // 线程终止标志位, 须保证其可见性
  volatile boolean terminated = false;
  boolean started = false;
  // 采集线程
  Thread rptThread;
  // 启动采集功能
  synchronized void start(){
    // 不允许同时启动多个采集线程
    if (started) {
      return;
    }
    started = true;
    terminated = false;
    rptThread = new Thread(()->{
      // 使用标志位来响应终止
      while (!terminated){
        // 省略采集、回传实现
        report();
        // 每隔两秒钟采集、回传一次数据
        try {
          Thread.sleep(2000);
        } catch (InterruptedException e){
          // 捕获异常会清除终止状态，因此要重新设置一下
          // 重新设置线程中断状态
          Thread.currentThread().interrupt();
        }
      }
      // 执行到此处说明线程马上终止
      started = false;
    });
    rptThread.start();
  }
  // 终止采集功能
  synchronized void stop(){
    // 设置中断标志位
    terminated = true;
    // 中断线程 rptThread
    rptThread.interrupt();
  }
}
```

