# 博客笔记

## Java实现多线程两种方式

- 继承 Thread 类

```java
public class MyThread extends Thread{

  @Override
  public void run() {
    while (true) {
      System.out.println(currentThread().getName());
    }
  }

  public static void main(String[] args) {
    MyThread thread = new MyThread();
    thread.start();
  }
}
```



- 实现 Runnable 接口

```java
public class MyRunnable implements Runnable {

  public void run() {
    System.out.println("123");
  }

  public static void main(String[] args) {
    MyRunnable myRunnable = new MyRunnable();
    new Thread(myRunnable, "t1").start();
  }
}
```

## Synchronized

- 可以在任意对象以及方法上加锁，而加锁的这段代码称为互斥区或临界区。

```java
public class SynThread extends Thread {
  private int count = 5;

  /*
  * 方法以 synchronized 修饰的时候, 多个线程在调用该方法的时候以排队(CPU分配)的方式进行
  * 一个线程想要执行 synchronized 修饰的方法里的代码
  * 首先尝试获得锁，如果拿到锁就执行，拿不到，就不断尝试直到拿到为止
  * */
  @Override
  public synchronized void run() {
    count--;
    System.out.println(currentThread().getName() + " count:" + count);
  }

  public static void main(String[] args) {
    SynThread synThread = new SynThread();
    Thread thread1 = new Thread(synThread, "thread1");
    Thread thread2 = new Thread(synThread, "thread2");
    Thread thread3 = new Thread(synThread, "thread3");
    Thread thread4 = new Thread(synThread, "thread4");
    Thread thread5 = new Thread(synThread, "thread5");
    thread1.start();
    thread2.start();
    thread3.start();
    thread4.start();
    thread5.start();
  }
}
```

- 一个对象一个锁，多个线程多个锁

```java
public class MultiThread {
  private int num = 200;

  /*
  * 一个对象有一把锁，多个线程多个锁
  * 线程执行该方法，会获得该方法所属的对象的锁
  * */
  public synchronized void printNum(String threadName, String tag) {
    if (tag.equals("a")) {
      num = num - 100;
      System.out.println(threadName + " tag a,set num over!");
    } else {
      num = num - 200;
      System.out.println(threadName + " tag b,set num over!");
    }
    System.out.println(threadName + " tag " + tag + ", num = " + num);
  }

  public static void main(String[] args) throws InterruptedException {
    final MultiThread multiThread1 = new MultiThread();
    final MultiThread multiThread2 = new MultiThread();

    /*
    * 这里创建了多个对象,每个对象都有自己的锁，而不是同一个锁，
    * 所以这两个线程各自运行的时候其实是没有排队现象的，所以结果是 100 和 0而不是 100 和 -100
    * */
    new Thread(new Runnable() {
      public void run() {
        multiThread1.printNum("thread1", "a");
      }
    }).start();

    new Thread(new Runnable() {
      public void run() {
        multiThread2.printNum("thread2", "b");
      }
    }).start();
  }

}
```

- Synchronized 锁具有可重入性

  - 使用 Synchronized 的时候，当一个线程得到对象的锁之后，在该锁里执行代码的时候再次可以请求该对象的锁时可以再次得到该对象的锁
  - 当线程请求一个由其它线程持有的对象锁时，该线程会阻塞，当线程请求由自己持有的对象锁时。如果该锁是重入锁，请求就会成功，否则就会阻塞。

  ```java
  public class SyncDubbo {
    /*
    * 请求 method 的锁，由于自己已经持有锁了，所以就重入成功了
    * */
    public synchronized void method1() {
      System.out.println("method1-----");
      method2();
    }
  
    public synchronized void method2() {
      System.out.println("method2-----");
      method3();
    }
  
    public synchronized void method3() {
      System.out.println("method3-----");
    }
  
    public static void main(String[] args) {
      final SyncDubbo syncDubbo = new SyncDubbo();
      new Thread(new Runnable() {
  
        public void run() {
          syncDubbo.method1();
        }
      }).start();
    }
  }
  ```

  - 可重入锁的作用在于避免死锁: 假如有一个线程 T 获得了对象 A 的锁，那么该线程 T 如果在未释放前再次请求该对象的锁时，如果没有可重入锁，就获取不到锁，就死锁了
  - 可重入锁支持 父子类继承的环境

  ```java
  public class SyncDubbo {
    static class Main {
      public int i = 5;
      public synchronized void operationSup() {
        i--;
        System.out.println("Main print i =" + i);
        try {
          Thread.sleep(100);
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
      }
    }
  
    static class Sub extends Main {
      public synchronized void operationSub() {
        while (i > 0) {
          i--;
          System.out.println("Sub print i = " + i);
          try {
            Thread.sleep(100);
          } catch (InterruptedException e) {
            e.printStackTrace();
          }
        }
      }
    }
  
    public static void main(String[] args) {
      new Thread(new Runnable() {
        public void run() {
          Sub sub = new Sub();
          sub.operationSub();
        }
      }).start();
    }
  
  }
  ```

  - 当一个线程执行的代码出现异常的时候，其所持有的锁会自动释放

  ```java
  public class SyncException {
    private int i = 0;
  
    public synchronized void operation(String tag) {
      while (true) {
        i++;
        System.out.println(Thread.currentThread().getName() + " tag :," + tag +" i= " + i);
        /*
        * t1 线程一直执行到 i = 11 才触发异常， t2 线程等到 t1 出现异常后才开始执行
        * */
        if (i > 10) {
          if (tag.equals("a")) {
            Integer.parseInt("a");
          } else {
            break;
          }
        }
      }
    }
  
    public static void main(String[] args) {
      final SyncException se = new SyncException();
      new Thread(new Runnable() {
        public void run() {
          se.operation("a");
        }
      }, "t1").start();
  
      new Thread(new Runnable() {
        public void run() {
          se.operation("b");
        }
      }, "t2").start();
    }
  }
  
  ```

  - 将任意对象作为监视器monitor

    - 多个线程持有 监视器 为同一个对象的前提下，同一时间只有一个线程可以执行 synchronized 同步代码块中的代码

    ```java
    public class StringLock  {
      // 监视器 monitor
      private String lock = "lock";
    
      public void method() {
        synchronized (lock) {
          try {
            System.out.println("当前线程： " + Thread.currentThread().getName() + "开始");
            Thread.sleep(1000);
            System.out.println("当前线程： " + Thread.currentThread().getName() + "结束");
          } catch (InterruptedException e) {
          }
        }
      }
    
      public static void main(String[] args) {
        final StringLock stringLock = new StringLock();
        new Thread(new Runnable() {
          public void run() {
            stringLock.method();
          }
        }, "t1").start();
        new Thread(new Runnable() {
          public void run() {
            stringLock.method();
          }
        }, "t2").start();
      }
    }
    ```

  - volatile : 保证变量的可见性，无法保证原始性

## ThreadLocal 的介绍和使用

- 用该类可以实现让每一个线程都有自己的共享变量
- 每个线程绑定自己的值

```java
public class ThreadLocalDemo {

  public static ThreadLocal<List<String>> threadLocal = new ThreadLocal<>();

  public void setThreadLocal(List<String> values) {
    threadLocal.set(values);
  }

  public void getThreadLocal() {
    System.out.println(Thread.currentThread().getName());
    threadLocal.get().forEach(System.out::println);
  }

  public static void main(String[] args) throws InterruptedException {

    final ThreadLocalDemo threadLocal = new ThreadLocalDemo();
    new Thread(() -> {
      List<String> params = new ArrayList<>(3);
      params.add("张三");
      params.add("李四");
      params.add("王五");
      threadLocal.setThreadLocal(params);
      threadLocal.getThreadLocal();
    }).start();

    new Thread(() -> {
      try {
        Thread.sleep(1000);
        List<String> params = new ArrayList<>(2);
        params.add("Chinese");
        params.add("English");
        threadLocal.setThreadLocal(params);
        threadLocal.getThreadLocal();
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
    }).start();
  }

}
```

## 线程间通信机制的介绍和使用

- 使用 wait/notify 机制实现
- wait() : 使当前执行代码的线程进行等待，该方法会将线程放入 "预执行队列"中，并且在 wait() 所在的代码处停止执行，直到接到通知或中断为止。
  - 调用 wait() 之前，线程必须获得该对象级别的锁，也就是只能在同步代码块中调用该方法
  - 调用wait() 会释放锁，从 wait() 返回后，会重新竞争锁
- notify(): 通知那些可能等待该对象的对象锁的其它线程，如果有多个线程等待，则由线程规划器随机挑选其中一个呈 wait 状态的线程，对其发出通知 notify,并使它等待获取该对象的对象锁
  -  同wait() ，必须在同步代码块中调用，调用前也必须获得锁
  - 执行notify 方法之后，当前线程不会立即释放其拥有的该对象锁，而是执行完之后才会释放该对象锁，被通知的线程也不会立即获得对象锁，而是等待 notify 方法执行完之后，释放了该对象锁，才可以获得该对象锁
- notifyAll(): 通知所有等待统一共享资源的全部线程从等待状态退出，进入可运行状态，重新竞争获取对象锁

```java
public class ThreadA extends Thread {

  private Object lock;

  public ThreadA(Object lock) {
    super();
    this.lock = lock;
  }

  @Override
  public void run() {
    try{
      synchronized (lock) {
        if (MyList.size() != 5) {
          System.out.println("wait begin " + System.currentTimeMillis());
          lock.wait();
          System.out.println("wait end " + System.currentTimeMillis());
        }
      }
    }catch (InterruptedException e){
      e.printStackTrace();
    }
  }
}

public class ThreadB extends Thread {
  private Object lock;

  public ThreadB(Object lock) {
    super();
    this.lock = lock;
  }

  @Override
  public void run() {
    try {
      synchronized (lock) {
        for (int i = 0; i < 10; i++) {
          MyList.add();
          if (MyList.size() == 5) {
            lock.notify();
            System.out.println("已发出通知！");
          }
          System.out.println("添加了" + (i + 1) + "个元素!");
          Thread.sleep(1000);
        }
      }
      System.out.println("同步之外的代码1");
      System.out.println("同步之外的代码2");
      System.out.println("同步之外的代码3");
      System.out.println("同步之外的代码4");
      System.out.println("虽然已经发出通知，但是要等本线程执行完之后才执行别的");
    }catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}

public class Action  {
  public static void main(String[] args) {
    try {
      Object lock = new Object();
      ThreadA a = new ThreadA(lock);
      a.start();
      Thread.sleep(50);
      ThreadB b = new ThreadB(lock);
      b.start();
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}
```

- 简单的阻塞队列

```java
/**
 * .Description: 阻塞队列
 * 初始化队列长度为5
 * 需要新加入时，需要判断长度是否为5，是5的话等待插入
 * 需要消费元素的话，判断是否为0，如果是0则等待消费
 * Author: 金君良 Date: 2018/11/22 0022 下午 2:46
 */
public class MyQueue  {
  //1、需要一个承装元素的集合
  private final LinkedList<Object> list = new LinkedList<>();
  //2、需要一个计数器
  private final AtomicInteger count = new AtomicInteger(0);
  //3、需要指定上限和下限
  private final int maxSize = 5;
  private final int minSize = 0;

  //5、初始化锁对象
  private final Object lock = new Object();

  /**
   * put方法
   */
  public void put(Object obj) {
    synchronized (lock) {
      //达到最大无法添加，进入等到
      while (count.get() == maxSize) {
        try {
          lock.wait();
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
      }
      list.add(obj); //加入元素
      count.getAndIncrement(); //计数器增加
      System.out.println(" 元素 " + obj + " 被添加 ");
      lock.notify(); //通知另外一个阻塞的线程方法
    }
  }

  /**
   * get方法
   */
  public Object get() {
    Object temp;
    synchronized (lock) {
      //达到最小，没有元素无法消费，进入等到
      while (count.get() == minSize) {
        try {
          lock.wait();
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
      }
      count.getAndDecrement();
      temp = list.removeFirst();
      System.out.println(" 元素 " + temp + " 被消费 ");
      lock.notify();
    }
    return temp;
  }

  private int size() {
    return count.get();
  }

  public static void main(String[] args) throws Exception {

    final MyQueue myQueue = new MyQueue();
    initMyQueue(myQueue);

    Thread t1 = new Thread(() -> {
      myQueue.put("h");
      myQueue.put("i");
    }, "t1");

    Thread t2 = new Thread(() -> {
      try {
        Thread.sleep(2000);
        myQueue.get();
        Thread.sleep(2000);
        myQueue.get();
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
    }, "t2");

    t1.start();
    Thread.sleep(1000);
    t2.start();

  }

  private static void initMyQueue(MyQueue myQueue) {
    myQueue.put("a");
    myQueue.put("b");
    myQueue.put("c");
    myQueue.put("d");
    myQueue.put("e");
    System.out.println("当前元素个数：" + myQueue.size());
  }

}
```

## 使用 Lock 对象实现同步以及线程间通信

- 比使用 wait / notify 更加方便
- 常用的实现类有 ReentrantLock，也可以用来实现线程同步

```java
public class Action {
  public static void main(String[] args) {

    Lock lock = new ReentrantLock();

    //lambda写法
    new Thread(() -> runMethod(lock), "thread1").start();
    new Thread(() -> runMethod(lock), "thread2").start();
    new Thread(() -> runMethod(lock), "thread3").start();
    new Thread(() -> runMethod(lock), "thread4").start();
  }

  private static void runMethod(Lock lock) {
    // 开始锁
    lock.lock();
    for (int i = 1; i <= 5; i++) {
      System.out.println("ThreadName:" + Thread.currentThread().getName() + (" i=" + i));
    }
    System.out.println();
    // 释放锁
    lock.unlock();
  }
}
```

- 使用 Lock 对象实现线程间通信
- 借助 Condition 对象来实现,可以选择性的通知，而不是notify 的随机通知
- 使用 Lock 对象和 Condition 实现等待/通知实例

```java
public class LockConditionDemo {
  /*
  * Object#wait() 相当于 Condition#await()
  * Object#notify 相当于 Condition#signal()
  * Object#notifyAll 相当于 Condition#signalAll()
  * */
  private Lock lock = new ReentrantLock();
  private Condition condition = lock.newCondition();

  public static void main(String[] args) throws InterruptedException {

    //使用同一个LockConditionDemo对象，使得lock、condition一样
    LockConditionDemo demo = new LockConditionDemo();
    new Thread(() -> demo.await(), "thread1").start();
    Thread.sleep(3000);
    new Thread(() -> demo.signal(), "thread2").start();
  }

  private void await() {
    try {
      // 获取锁
      lock.lock();
      System.out.println("开始等待await！ ThreadName：" + Thread.currentThread().getName());
      // 等待
      condition.await();
      System.out.println("等待await结束！ ThreadName：" + Thread.currentThread().getName());
    } catch (InterruptedException e) {
      e.printStackTrace();
    } finally {
      // 释放锁
      lock.unlock();
    }
  }

  private void signal() {
    // 获取锁
    lock.lock();
    System.out.println("发送通知signal！ ThreadName：" + Thread.currentThread().getName());
    // 通知
    condition.signal();
    lock.unlock();
  }
}
```

- 使用 Lock 对象和多个 Condition 实现等待/通知实例

```java
public class LockConditionDemo2 {
  private Lock lock = new ReentrantLock();
  private Condition conditionA = lock.newCondition();
  private Condition conditionB = lock.newCondition();

  public static void main(String[] args) throws InterruptedException {

    LockConditionDemo2 demo = new LockConditionDemo2();

    new Thread(() -> demo.await(demo.conditionA), "thread1_conditionA").start();
    new Thread(() -> demo.await(demo.conditionB), "thread2_conditionB").start();
    new Thread(() -> demo.signal(demo.conditionA), "thread3_conditionA").start();
    System.out.println("稍等5秒再通知其他的线程！");
    Thread.sleep(5000);
    new Thread(() -> demo.signal(demo.conditionB), "thread4_conditionB").start();

  }

  private void await(Condition condition) {
    try {
      lock.lock();
      System.out.println("开始等待await！ ThreadName：" + Thread.currentThread().getName());
      condition.await();
      System.out.println("等待await结束！ ThreadName：" + Thread.currentThread().getName());
    } catch (InterruptedException e) {
      e.printStackTrace();
    } finally {
      lock.unlock();
    }
  }

  private void signal(Condition condition) {
    lock.lock();
    System.out.println("发送通知signal！ ThreadName：" + Thread.currentThread().getName());
    // 唤醒指定的线程
    condition.signal();
    lock.unlock();
  }

}
```

- 公平锁和非公平锁
- 公平锁表示线程获取锁的顺序是按照线程加锁的顺序来分配，即先进先出
- 非公平是抢占机制，不一定先来的先得到

```java
// fair true 表示公平锁，反之为非公平锁
public ReentrantLock(boolean fair) {
  sync = fair ? new FairSync() : new NonfairSync();
}
```

- ReentrantLock  的其它方法
  - getHoldCount() 方法：查询当前线程保持此锁定的个数，也就是调用 lock() 的次数；
  - getQueueLength() 方法：返回正等待获取此锁定的线程估计数目；
  - isFair() 方法：判断是不是公平锁；

### 使用 ReentrantReadWriteLock 实现并发

- ReentrantLock  是完全排他的，同一时间只能有一个线程在执行 ReentrantLock.lock() 之后的任务
- 为了提高效率 可以使用 ReentrantReadWriteLock l类
- ReentrantReadWriteLock  有两个锁
  - 读相关的锁，称为共享锁，多个读锁之间不互斥
  - 与写相关的锁，称为排它锁，读锁与写锁互斥，写锁与写锁互斥
- 同一时间多个线程可以同时进行读操作，但是同一时刻只允许一个线程进行写操作
- 读读共享

```java
public class ReentrantReadWriteLockDemo {

  private ReentrantReadWriteLock lock = new ReentrantReadWriteLock();

  public static void main(String[] args) {

    ReentrantReadWriteLockDemo demo = new ReentrantReadWriteLockDemo();

    new Thread(demo::read, "ThreadA").start();
    new Thread(demo::read, "ThreadB").start();
  }

  private void read() {
    try {
      try {
        lock.readLock().lock();
        // 允许多个线程同时执行 lock() 后面的方法
        System.out.println("获得读锁" + Thread.currentThread().getName()
            + " 时间:" + System.currentTimeMillis());
        //模拟读操作时间为5秒
        Thread.sleep(5000);
      } finally {
        lock.readLock().unlock();
      }
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}
```

- 写写互斥

```java
public class ReentrantReadWriteLockDemo {

  private ReentrantReadWriteLock lock = new ReentrantReadWriteLock();

  public static void main(String[] args) {

    ReentrantReadWriteLockDemo demo = new ReentrantReadWriteLockDemo();

    new Thread(() -> demo.write(), "ThreadA").start();
    new Thread(() -> demo.write(), "ThreadB").start();
  }

  private void write() {
    try {
      try {
        lock.writeLock().lock();
        // 多个写线程是互斥的
        System.out.println("获得写锁" + Thread.currentThread().getName()
            + " 时间:" + System.currentTimeMillis());
        //模拟写操作时间为5秒
        Thread.sleep(5000);
      } finally {
        lock.writeLock().unlock();
      }
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}

```

- 读写互斥或写读互斥

```java
public class ReentrantReadWriteLockDemo {

  private ReentrantReadWriteLock lock = new ReentrantReadWriteLock();

  public static void main(String[] args) throws InterruptedException {
    ReentrantReadWriteLockDemo demo = new ReentrantReadWriteLockDemo();

    new Thread(() -> demo.read(), "ThreadA").start();
    Thread.sleep(1000);
    new Thread(() -> demo.write(), "ThreadB").start();
  }

  private void read() {
    try {
      try {
        lock.readLock().lock();
        System.out.println("获得读锁" + Thread.currentThread().getName()
            + " 时间:" + System.currentTimeMillis());
        Thread.sleep(3000);
      } finally {
        lock.readLock().unlock();
      }
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }

  private void write() {
    try {
      try {
        lock.writeLock().lock();
        System.out.println("获得写锁" + Thread.currentThread().getName()
            + " 时间:" + System.currentTimeMillis());
        Thread.sleep(3000);
      } finally {
        lock.writeLock().unlock();
      }
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
}
```

## 两种常用的线程计数器

### 倒计时 CountDownLatch

- 允许一个或多个线程一直等待，直到其他线程的操作执行完之后再执行

```java
public class SummonDragonDemo {

  private static final int THREAD_COUNT_NUM = 7;
  // 构造函数的参数表示待执行完毕的线程数量,构造后无法修改
  private static CountDownLatch countDownLatch = new CountDownLatch(THREAD_COUNT_NUM);

  public static void main(String[] args) throws InterruptedException {
    for (int i = 1; i <= THREAD_COUNT_NUM; i++) {
      int index = i;
      new Thread(() -> {
        try {
          //模拟收集第i个龙珠,随机模拟不同的寻找时间
          Thread.sleep(new Random().nextInt(3000));
          System.out.println("第" + index + "颗龙珠已收集到！");
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
        //每收集到一颗龙珠,需要等待的颗数减1
        countDownLatch.countDown();
      }).start();
    }
    // 启动全部等待的线程后开始等其完成
    //等待检查，即上述7个线程执行完毕之后，执行await后边的代码
    countDownLatch.await();
    System.out.println("集齐七颗龙珠！召唤神龙！");
  }
}

```

- ### CountDownLatch  在实时系统中的使用场景

  - 实现最大的并行性：有时我们想同时启动多个线程，实现最大程度的并行性。例如，我们想测试一个单例类。如果创建一个初始计数为1的 CountDownLatch，并让所有线程都在这个锁上等待，那么我们可以很轻松地完成测试。我们只需调用一次 countDown() 方法就可以让所有的等待线程同时恢复执行。
  - 开始执行前等待 N 个线程完成各自任务：例如应用程序启动类要确保在处理用户请求前，所有 N 个外部系统已经启动和运行了。
  - 死锁检测：一个非常方便的使用场景是，你可以使用 N 个线程访问共享资源，在每次测试阶段的线程数目是不同的，并尝试产生死锁。

### 循环屏障 CyclicBarrier

- 也可以实现计数等待功能
- 让一组线程到达一个屏障（也叫作同步点）时被阻塞,直到最后一个线程到达屏障时，屏障才开门，所有被屏障拦截的线程才会继续干活
- 默认的构造方法的参数表示 屏障拦截的线程数量
- 每个线程调用 await 方法告诉 CyclicBarrier 我已经到达了屏障,然后当前线程被阻塞。

```java
public class SummonDragonDemo {

  private static final int THREAD_COUNT_NUM = 7;

  public static void main(String[] args) {

    //设置第一个屏障点，等待召集齐7位法师， 所有线程到达屏障一之后，执行回调
    CyclicBarrier callMasterBarrier = new CyclicBarrier(THREAD_COUNT_NUM, new Runnable() {
      @Override
      public void run() {
        System.out.println("7个法师召集完毕，同时出发，去往不同地方寻找龙珠！");
        summonDragon();
      }
    });
    //召集齐7位法师
    for (int i = 1; i <= THREAD_COUNT_NUM; i++) {
      int index = i;
      new Thread(() -> {
        try {
          System.out.println("召集第" + index + "个法师");
          // 召集到一位，就表示有一个线程已经到达了屏障1
          callMasterBarrier.await();
        } catch (InterruptedException | BrokenBarrierException e) {
          e.printStackTrace();
        }
      }).start();
    }
  }

  /**
   * 召唤神龙：1、收集龙珠；2、召唤神龙
   */
  private static void summonDragon() {
    //设置第二个屏障点，等待7位法师收集完7颗龙珠，召唤神龙
    CyclicBarrier summonDragonBarrier = new CyclicBarrier(THREAD_COUNT_NUM, new Runnable() {
      @Override
      public void run() {
        System.out.println("集齐七颗龙珠！召唤神龙！");
      }
    });
    //收集7颗龙珠
    for (int i = 1; i <= THREAD_COUNT_NUM; i++) {
      int index = i;
      new Thread(() -> {
        try {
          System.out.println("第" + index + "颗龙珠已收集到！");
          summonDragonBarrier.await();
        } catch (InterruptedException | BrokenBarrierException e) {
          e.printStackTrace();
        }
      }).start();
    }
  }
}
```

### CyclicBarrier 和 CountDownLatch 的区别

- CountDownLatch 的计数器只能使用一次。而 CyclicBarrier 的计数器可以使用 reset() 方法重置。所以 CyclicBarrier 能处理更为复杂的业务场景，比如如果计算发生错误，可以重置计数器，并让线程们重新执行一次
- CyclicBarrier 还提供其他有用的方法，比如 getNumberWaiting 方法可以获得 CyclicBarrier 阻塞的线程数量。isBroken 方法用来知道阻塞的线程是否被中断
- CountDownLatch 会阻塞主线程，CyclicBarrier 不会阻塞主线程，只会阻塞子线程。

## 使用线程池实现线程的复用

- 使用线程池好处多多，不多赘述

### JDK 对线程池的支持

常用的类

- newFixedThreadPool:该方法返回一个固定线程数量的线程池
- newSingleThreadExecutor: 该方法返回一个只有一个线程的线程池
- newCachedThreadPool : 返回一个可以根据实际情况调整线程数量的线程池
- newSingleThreadScheduledExecutor : 该方法和 newSingleThreadExecutor 的区别是给定了时间执行某任务的功能，可以进行定时执行等
- newScheduledThreadPool : 在4的基础上可以指定线程数量

### ThreadPoolExecutor

- 创建线程池主要就是创建 ThreadPoolExecutor 对象
- 其构造参数
  - corePoolSize 核心线程池大小
  - maximumPoolSize 线程池最大容量大小
  - keepAliveTime 线程池空闲时，线程存活的时间
  - TimeUnit 时间单位
  - ThreadFactory 线程工厂
  - BlockingQueue任务队列
  - RejectedExecutionHandler 线程拒绝策略

### 实例

- 不要使用 Executor 来创建线程池,其线程最大数量太大，堆积的请求处理队列会耗费非常多的内存
- 示例1

```java
public class ThreadPoolDemo {

  public static void main(String[] args) {

    ExecutorService executorService = new ThreadPoolExecutor(2, 2, 0L,
        TimeUnit.MILLISECONDS,
        new LinkedBlockingQueue<>(10),
        Executors.defaultThreadFactory(),
        new ThreadPoolExecutor.AbortPolicy());

    for (int i = 0; i < 10; i++) {
      int index = i;
      executorService.submit(() -> System.out.println("i:" + index +
          " executorService"));
    }
    executorService.shutdown();
  }
}
```

- 示例2

```java
public static void main(String[] args) {

        ExecutorService executorService = new ThreadPoolExecutor(5, 5, 0L, TimeUnit.MILLISECONDS,
                new LinkedBlockingQueue<>(10),
                new ThreadFactory() { //自定义ThreadFactory
                    @Override
                    public Thread newThread(Runnable r) {
                        Thread thread = new Thread(r);
                        thread.setName(r.getClass().getName());
                        return thread;
                    }
                },
                new ThreadPoolExecutor.AbortPolicy()); //自定义线程拒绝策略

        for (int i = 0; i < 10; i++) {
            int index = i;
            executorService.submit(() -> System.out.println("i:" + index));
        }

        executorService.shutdown();
    }
}
```

### ExecutorService#submit() 的坑

- 该方法执行的时候，错误的堆栈信息会被内部捕获到，所以出错的时候无法打印具体的信息
- 可以用 execute() 方法执行 没有返回值的任务
- 使用 future

```java
public class ThreadPoolDemo {

  public static void main(String[] args) {

    ExecutorService executorService = Executors.newFixedThreadPool(4);

    for (int i = 0; i < 5; i++) {
      int index = i;
      Future future = executorService.submit(() -> divTask(200, index));
      try {
        // 阻塞当前线程直到任务完成
        future.get();
      } catch (InterruptedException | ExecutionException e) {
        e.printStackTrace();
      }
    }
    executorService.shutdown();
  }

  private static void divTask(int a, int b) {
    double result = a / b;
    System.out.println(result);
  }
}
```

## 多线程异步调用之 Future 模式

### Future 主要角色

- Main : 系统启动，调用 Client 发出请求
- Client : 返回 Data 对象，立即发出 FutureData, 并开启ClientThread 线程装配 RealData
- Data : 返回数据的接口
- FutureData : Future 数据，构造很快， 但是是一个虚拟的数据，需要装配 RealData
- RealData : 真实数据，其构造是比较慢的

### Future 模式的简单实现

- Data

```java
/**
 * .Description: 返回数据的接口
 * Author: 金君良 Date: 2018/11/23 0023 上午 9:24
 */
public interface Data {
  String getResult();
}
```

- FutureData

```java
/**
 * .Description: 构造很快，但是其实是一个虚拟的数据，需要装配 RealData
 * Author: 金君良 Date: 2018/11/23 0023 上午 9:26
 */
public class FutureData implements Data {

  // 真实的数据
  private RealData realData;
  // 判断数据是否准备好了
  private boolean isReady;

  private ReentrantLock lock = new ReentrantLock();
  private Condition condition = lock.newCondition();

  @Override
  public String getResult() {
    // 数据没准备好的话就一直阻塞
    while (!isReady) {
      try{
        lock.lock();
        // 线程开始休眠了
        condition.await();
      } catch (InterruptedException e) {
        e.printStackTrace();
      } finally {
        lock.unlock();
      }
    }
    return realData.getResult();
  }

  public void setRealData(RealData realData) {
    lock.lock();
    // 假如数据已经准备好了就不接受新的数据
    if (isReady) {
      return;
    }

    this.realData = realData;
    isReady = true;
    // 唤醒休眠的数据
    condition.signal();
    lock.unlock();
  }
}
```

- RealData

```java
public class RealData implements Data {

  private String result;

  public RealData(String result) {
    StringBuffer sb = new StringBuffer();
    sb.append(result);
    try{
      // 模拟构造真实数据的耗时操作
      Thread.sleep(5000);
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
    this.result = sb.toString();
  }

  @Override
  public String getResult() {
    return result;
  }
}
```

- Client

```java
public class Client {

  public Data request(String param) {
    // 立即返回FutureData
    FutureData futureData = new FutureData();
    // 开启ClientThread线程装配 RealData
    new Thread(() -> {
      // 装配 RealData
      RealData realData = new RealData(param);
      //经历各种操作，将数据写入
      futureData.setRealData(realData);
    }).start();
    return futureData;
  }

}
```

- Main

```java
public class Main {
  public static void main(String[] args) {
    Client client = new Client();
    Data data = client.request("Hello Future!");
    System.out.println("请求完毕！");

    try {
      //模拟处理其他业务
      Thread.sleep(2000);
    } catch (InterruptedException e) {
      e.printStackTrace();
    }

    System.out.println("真实数据：" + data.getResult());
  }
}
```

### JDK 中的 Future 模式的实现

- 真实的数据实现 Callable 接口

```java
public class RealData implements Callable<String> {
  private String result;

  public RealData(String result) {
    this.result = result;
  }

  @Override
  public String call() throws Exception {
    StringBuffer sb = new StringBuffer();
    sb.append(result);
    //模拟耗时的构造数据过程
    Thread.sleep(5000);
    return sb.toString();
  }
}
```

- 使用 FutureTask

```java
public class FutureMain {
  public static void main(String[] args) throws ExecutionException, InterruptedException {

    FutureTask<String> futureTask = new FutureTask<>(new RealData("Hello"));

    ExecutorService executorService = Executors.newFixedThreadPool(1);
    executorService.execute(futureTask);

    System.out.println("请求完毕！");

    try {
      Thread.sleep(2000);
      System.out.println("这里经过了一个2秒的操作！");
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
    /*
    * 计算结果只能使用 get 方法来获取
    * 线程没执行完就阻塞
    * 线程出现异常就会跑出异常
    * 线程被取消抛出 CancellationException
    * */
    System.out.println("真实数据：" + futureTask.get());
    executorService.shutdown();
  }

}
```

## 关于锁优化的几点建议

- 减少锁的持有时间： 只对确实有同步需要的代码加锁，越少越好
- 减少锁的粒度 : 比如 ConcurrentHashMap 所用的锁分段技术
- 使用读写锁替换独占锁: 使用 ReentrantReadWriteLock 的两个锁，没有线程在进行写操作的时候，进行读操作的多个线程都可以获取到锁，而写操作的线程只有获取写锁后才能进行写操作
- 锁分离:基于如下思想: 只要操作互不影响，锁就可以分离, 比如 `LinkedBlockingQueue` ,take是从头取数据，put是从队尾写数据，是不冲突的，所以可以锁分离
- 锁粗化

```java
public void syncMethod() {
        synchronized (lock) { //第一次加锁
            method1();
        }
        method3();
        synchronized (lock) { //第二次加锁
            mutextMethod();
        }
        method4();
        synchronized (lock) { //第三次加锁
            method2();
        }
    }
/*
线程加锁的时间太长了，不如合在一起算了
*/
public void syncMethod() {
        synchronized (lock) {
            method1();
            method3();
            mutextMethod();
            method4();
            method2();
        }
    }
```

- 锁消除 (编译器的优化，大神才搞)

## 无锁 CAS操作及 "18罗汉"

### 无锁

- 线程切换的时候是需要进行上下文切换的，而这个过程有资源开销的，无锁就是一种减少上下文切换的技术

- 并发控制的锁是一种悲观的策略，它假设每一次的临界区操作会产生冲突，所以为了保护临界区，就要牺牲性能让线程进行等待。
- 无锁是一种乐观的策略。它会假设对资源的访问时没有冲突的，既然没有冲突，那就无需等待
- 无锁要是遇到冲突，就会使用一种叫做比较交换的技术(Compare And Swap) 来鉴别线程冲突，一旦检测到冲突产生，就重试当前操作直到没有冲突为止。

### CAS

- 使用CAS 程序会比较复杂，但由于其非阻塞性，就没有死锁问题，性能也很好
- CAS 的算法过程
  - CAS 包含三个参数 (V,E,N)
  - V 代表 更新的变量
  - E 表示预期值
  - N 表示新值
  - 仅当 V值等于E值时，才会将V值设置为N值
  - 如果V值和E值不同，则说明已经有其它线程做了更新，那么当前线程什么都不做
  - 最后，CAS返回当前V的真实值

- 简单说，就是CAS 需要你额外给出一个期望值，也就是你认为这个变量现在应该是什么样子的。如果变量不是你想象的那样，那说明它已经被别人修改过了，就重新读取，再次尝试修改就好了

### Java 中的原子操作类 : 大致分为4类

#### 原子更新基本类型

- AtomicBoolean：原子更新布尔类型
- AtomicInteger：原子更新整数类型
- AtomicLong：原子更新长整型类型
- API 比较好理解

#### 原子更新引用类型

- AtomicReference：原子更新引用类型。对普通对象的引用，可以保证我们在修改对象应用的时候保证线程的安全性
- 假如 compareAndSet 的时候，预期值被线程A修改了，但是线程B又把它改回了原来的值，那么就会认为是没影响
- 所以 AtomicReference 是无法纪录状态的迁移的

```java
public class AtomicReferenceDemo {
  public static AtomicReference<User> atomicReference =
      new AtomicReference<User>();

  public static void main(String[] args) {
    User user = new User("xuliugen", "123456");
    atomicReference.set(user);

    User updateUser = new User("Allen", "654321");
    atomicReference.compareAndSet(user, updateUser);
    System.out.println(atomicReference.get().getUserName());
    System.out.println(atomicReference.get().getUserPwd());
  }

  static class User {
    private String userName;
    private String userPwd;
    //省略get、set、构造方法
  }

}
```



- AtomicStampedReference：原子更新带有版本号的引用类型
- 当AtomicStampedReference更新值的时候还必须要更新时间戳，只有当值满足预期且时间戳满足预期的时候，写才会成功！

```java
public class AtomicStampedReferenceDemo {

    //设置默认余额为19，表示这是一个需要被充值的账户,初始化时间戳为0
    private static AtomicStampedReference<Integer> money =
            new AtomicStampedReference<Integer>(19, 0);

    public static void main(String[] args) {

        //模拟多个线程同时为用户的账户充值
        for (int i = 0; i < 10; i++) {
            //多个线程同时获取一个预期的时间戳，如果线程执行的时候发现和预期值不一样
            //则表示已经被其他线程修改，则无需在充值，保证只充值一次！
            final int timeStamp = money.getStamp();

            new Thread(new Runnable() {
                @Override
                public void run() {
                    while (true) { //CAS模式中的死循环，保证更新成功
                        Integer m = money.getReference();
                        if (m < 20) {
                            if (money.compareAndSet(m, m + 20, timeStamp, timeStamp + 1)) {
                                System.out.println("余额小于20，充值成功，余额为："
                                        + money.getReference() + "元！");
                                break;
                            }
                        } else {
                            //System.out.println("余额大于20，无需充值！");
                            break;
                        }
                    }
                }
            }, "rechargeThread" + i).start();
        }

        new Thread(new Runnable() {
            @Override
            public void run() {
                //模拟多次消费
                for (int i = 0; i < 10; i++) {
                    while (true) {
                        Integer m = money.getReference();
                        int timeStamp = money.getStamp();
                        if (m > 10) {
                            System.out.println("大于10元，可以进行消费！");
                            if (money.compareAndSet(m, m - 10, timeStamp, timeStamp + 1)) {
                                System.out.println("消费成功，余额为：" + money.getReference());
                                break;
                            }
                        } else {
                            //System.out.println("没有足够的余额，无法进行消费！");
                            break;
                        }
                    }
                }
            }
        }, "userConsumeThread").start();
    }
}
```



- AtomicMarkableReference：原子更新带有标记位的引用类型。可以原子更新一个布尔类型的标记为和引用类型

#### 原子更新数组类型

- AtomicIntegerArray: 原子更新整数型数组里的元素

```java
public class AtomicIntegerArrayDemo {

    private static int[] value = new int[]{1, 2, 3, 4, 5};
    private static AtomicIntegerArray atomic =
            new AtomicIntegerArray(value);

    public static void main(String[] args) {
        atomic.getAndSet(2, 100);
        System.out.println(atomic.get(2));
    }
}
```

- AtomicLongArray：原子更新长整型数组里的元素
- AtomicReferenceArray：原子更新引用类型数组里的元素



#### 原子更新属性类型

- 原子的更新某个类里的某个字段
- AtomicIntegerFieldUpdater：原子更新整数型字段

```java
public class AtomicIntegerFieldUpdaterDemo {

    public static AtomicIntegerFieldUpdater atomic =
            AtomicIntegerFieldUpdater.newUpdater(User.class, "age");

    public static void main(String[] args) {
        User user = new User("xuliugen", 24);
        System.out.println(atomic.getAndIncrement(user));
        System.out.println(atomic.get(user));
    }

    static class User {
        private String userName;
        public volatile int age;
        //省略get、set、构造方法
    }
}
//输出结果：
//24
//25
```



- AtomicLongFieldUpdater：原子更新长整型字段
- AtomicReferenceFieldUpdater：原子更新引用类型里的字段



# Java并发编程笔记

# 基础概念

## 原子性

## 竞态条件

## 重入

如果某个线程试图获得一个已经由它自己持有的锁，那么这个请求就会成功。
"重入"意味着获取锁的操作的粒度是"线程而不是调用"。

```
public class Father {
    public synchronized void do() {

    }
}


public class Child extends Father {

    @override
    public synchronized void do() {
        System.out.println(....);
        // 子类的 do方法在执行前会去获取父类的锁，假如没有重入，那就没法获得，会永远阻塞下去
        super.dp();
    }
}
```

## 发布

指对象能够在当前作用域之外的代码中使用

## 逸出

某个不该发布的对象被发布时，称为逸出

## 并发 Concurrency 和 并行 Parallelism

- 并发
  并发指多个任务交替执行，多个任务之间有可能串行
  疯狂切换多个任务，看起来像是并行执行
- 并行
  真正意义上的同时执行

## 临界区

表示公共资源，共享数据

## 阻塞 Blocking 和 非阻塞 Non-Blocking

这两个是形容多线程之间的相互影响的

- 阻塞
  如果一个线程占用了临界区资源，其它所有需要这个资源的线程就必须在改临界区等待。等待会造成线程挂起，
  这种情况就是阻塞
- 强调没有一个线程可以妨碍其它线程执行。所有的线程都会尝试不断向前执行

## 死锁 Deadlock 饥饿 Starvation 活锁 Livelock

描述多线程的活跃性问题，以上几种情况都是不活跃

- 死锁
  彼此不愿意释放自己的锁，导致无法进行
- 饥饿
  优先度低的线程无法获得资源从而无法执行的情况
- 活锁
  每个线程都在主动让出资源，导致无法进行

## 并发级别

由于临界区的存在，多线程之间的并发必须受到控制

- 阻塞
  一个线程是阻塞的，那么在其它线程释放资源之前，当前线程是无法继续执行的。
- 无饥饿
  锁是公平的，所有线程都遵循先来后到的原则
- 无障碍
  最弱的线程调度
  所有线程都可以修改共享数据，它认为多个线程之间很可能不会冲突，但是如果检测到冲突，就进行回滚。
  可能导致无限回滚，影响进程的进行。
- 无锁
  线程的并行是无障碍的。但是无锁的并发保证必然有一个线程能够在有限步内完成操作离开临界区
  总是伴随着无限循环而出现
- 无等待
  要求所有的线程都必须在有限步骤内完成

# Java中的线程

## 状态

- NEW
  表示刚刚创建的线程，还没开始执行，从该状态出发后将无法再回来
- RUNNABLE
  线程在执行中
- BLOCKED
  遇到了 synchronized 同步块，正在请求锁
- WAITING
  进入无时间限制的等待，等待一些特殊的事件
  通过wait()方法的线程等待notify()方法
  通过join()方法会等待目标线程的终止
- TIMED_WAITING会进入一个有时限的等待状态
- TERMINATED
  表示结束，一旦进入将无法回头

## 基本的API

- 新建线程

```java
Thread t1 = new Thread();
// start() 方法会新建一个线程并让这个线程执行 run()方法
// 单单调用run()方法是不能新建线程的
t1.start();
```

使用 Runnable 接口来新建线程，执行run()方法更合理

- 终止线程
  不要使用 stop()方法，避免数据不一致
  使用标志类来决定啥时候退出比较好
- 线程中断
  // 中断线程
  Thread.interrupt() 
  // 判断是否被中断
  Thread.isInterrupted()
  // 判断是否被中断，并清除当前中断状态,静态方法
  Thread.interrupted()
- 等待和通知
  wait()
  notify()

线程A调用 obj.wait() 后，线程A就会停止继续执行，转为等待状态,进入object对象的等待队列中
这个等待队列中可能会有多个线程
直到其它线程调用了 obj.notify()方法为止
此时系统会从等待队列中随机选择一个线程并将其唤醒，该选择是不公平的
此时，obj对象就成为了多个线程之间的有效通信手段

notifyAll() 会唤醒所有等待队列中的线程

wait() 方法必须在 synchronzied块中
wait()方法会释放目标对象的锁，但是sleep()方法不会释放任何资源

- 挂起和继续执行线程
  挂起时不会释放资源，因而被废弃了差不多
- 等待和谦让
  等待别的线程完了之后自己再执行
  join()
  join(long millis)
  yield()

join()的本质是让调用线程 wait() 在当前线程对象实例上

# 何时使用 volatile

## 对变量的写入操作不依赖变量的当前值，或者你能确保只有单个线程更新变量的值

## 该变量不会与其它状态变量一起纳入不变性条件中

## 在访问变量时不需要加锁

加锁机制既可以确保可见性又可以确保原子性，而 volatile 变量只能确保可见性。

# ThreadLocal 类的使用

该类能使线程中的某个值与保存值的对象相关联起来。
该类提供了 get 和 set方法，这些方法能保证每个使用该变量的线程都存有一个独立的副本
因此get总是返回由当前执行线程在调用set时设置的最新值。

通常用于防止对可变的单实例对象或全局变量进行共享

# 不可变对象一定是线程安全的

# 对象的组合

利用一些现有的线程安全组件组合为更大规模的组件或程序

## 设计线程安全的类

- 找出构成对象状态的所有变量
- 找出约束状态变量的不变性条件
- 建立对象状态的并发访问管理策略

### 依赖状态的操作

即某个操作中包含有基于状态的先验条件

比如删除 list 中的元素，必须要保证 list中有元素





