# 基础

## 观察者模式

- 按下开关，台灯灯亮
- 台灯是观察者，开关作为被观察者，台灯透过电线来观察开关的状态来并做出相应的处理
- 开关(被观察者)作为事件的产生方（生产 开和关两个事件），是主动的，是整个开灯流程的起点
- 台灯（观察者）作为事件的处理方（处理 灯亮和灯灭两个事件），是被动的，是整个开灯事件流程的终点
- 在起点和终点之间，即事件传递的过程中是可以被加工，过滤，转换，合并等等方式处理的
- 被观察者就是 Observable
- 观察者就是 Observer
- 只有使用了 subscribe() 才会开始发送数据

```java
public static void main(String[] args) {
        // 创建被观察者，是事件的传递的起点
        Observable.just("On", "Off", "On", "On")
                // 传递过程中对事件进行过滤操作
                .filter(Objects::nonNull)
                // 实现订阅
                .subscribe(
                        // 创建观察者，作为事件传递的终点处理事件
                        new Observer<String>() {
                            @Override
                            public void onSubscribe(Disposable disposable) {
                                System.out.println("被观察了");
                            }

                            @Override
                            public void onNext(String s) {
                                System.out.println("handle this");
                            }

                            @Override
                            public void onError(Throwable throwable) {
                                // 出现错误时
                            }

                            @Override
                            public void onComplete() {
                                System.out.println("结束观察");
                            }
                        }
                );
    }
```

## 五种观察者模式

| 类型        | 描述                                                         |
| ----------- | ------------------------------------------------------------ |
| Observable  | 能够发射0或n个数据，并以成功或错误事件终止                   |
| Flowable    | 能发射0或n个数据，并以成功或错误事件终止。支持背压，可以控制数据发射源的速度 |
| Single      | 只发射单个数据或错误事件                                     |
| Completable | 从来不发射数据，只处理 onComplete 和 onError 事件。可以看做是Rx的 Runnable |
| Maybe       | 能发射 0 或 1一个数据，要么成功要么失败，类似于 Optional     |

## do操作符

可以给 Observable 的生命周期的各个阶段加上一系列的回调监听，当 Observable 执行到这个阶段时，这些回调就会触发

```java
public static void main(String[] args) {
    Observable
        .just("Hello")
        .doOnNext(str -> System.out.println("doOnNext: " + str))
        .doAfterNext(str -> System.out.println("doAfterNext: " + str))
        .doOnComplete(() -> System.out.println("doOnComplete"))
        .doOnSubscribe(disposable -> System.out.println("doOnSubscribe"))
        .doAfterTerminate(() -> System.out.println("doAfterTerminate"))
        .doFinally(() -> System.out.println("doFinally"))
        // Observable 每发射一个数据就会触发一次回调，不仅包括 onNext,还有 onError 和 onComplete
        .doOnEach(stringNotification -> System.out.println("doOnEach:" + (stringNotification.isOnNext()
            ? "onNext" : stringNotification.isOnComplete() ? "onComplete" : "onError" )))
        // 订阅后可以取消订阅
        .doOnLifecycle(
            disposable -> System.out.println("doOnLifecycle:" + disposable.isDisposed()),
            () -> System.out.println("doOnLifecycle run: "))
        .subscribe(str ->
          System.out.println("收到消息: " + str)
        );


  }

/* 输出
doOnSubscribe
doOnLifecycle:false
doOnNext: Hello
doOnEach:onNext
收到消息
doAfterNext: Hello
doOnComplete: 
doOnEach:onComplete
doFinally
doAfterTerminate
*/
```



## 背压

- 背压是指在异步场景中，被观察者发送事件速度远快于观察者的处理速度的情况下，一种告诉上游的被观察者降低发送速度的策略
- 所以背压是流速控制的一种策略
  - 必须是异步环境，也就是说，被观察者和观察者需要处在不同的线环境中
  - 背压并不是操作符

### 响应式拉取

- 一般是被观察者主动的去推送数据给观察者，响应式拉取则相反，观察者主动从被观察者那里去拉取数据，而被观察者变成被动的等待通知再发送数据。



### Hot and Cold

- Cold Observables ： 指的是那些在订阅之后才开始发送事件的Observable(每个 Observer 都能收到完整的事件)
- Hot Observables : 指的是那些创建了 Observable 之后，（不管是否订阅）就开始发送事件的 Observable

# 创建操作符

主要包括以下

| api      | 简介                                                         |
| -------- | ------------------------------------------------------------ |
| just     | 将一个或多个对象转换成发射这个或这些对象的一个Observable     |
| from     | 将一个Iterable, 一个 Future或者一个数组转换为Observable      |
| create   | 使用一个函数从头创建一个Observable                           |
| defer    | 只有当订阅者订阅才会创建Observable,为每个订阅创建一个新的Observable |
| range    | 创建一个发射指定范围的整数序列的Observable                   |
| interval | 创建一个按照给定的时间间隔发射整数序列的Observable           |
| timer    | 创建一个在给定的延时之后发射单个数据的Observable             |
| empty    | 创建一个什么都不做直接通知完成的Observable                   |
| error    | 创建一个什么都不做直接通知错误的Observable                   |
| nerver   | 创建一个不发射任何数据的Observable                           |
|          |                                                              |

### create

- 给该操作符传递一个接受观察者作为参数的函数，编写这个函数让它的行为表现为一个 Observable
- 正确的行为是调用 观察者的 onComplete 或 onError 一次，之后就不再调用观察者中的任何方法
- 在传递给 create 方法函数时，先检查一下观察者的 isDisposed 状态，以便在没有观察者的时候，让 Observable 停止发射数据

```java
public static void main(String[] args) {
    Observable.create((ObservableEmitter<Integer> emitter)  -> {
      try {
        // 检查一下是否有观察者
        if (!emitter.isDisposed()) {
          for (int i=0;i<10;i++) {
            emitter.onNext(i);
          }
          emitter.onComplete();
        }
      }catch (Exception e) {
        emitter.onError(e);
      }
    }).subscribe(
        integer -> System.out.println("Next: " + integer),
        throwable -> System.out.println("Error: " + throwable.getMessage()),
        () -> System.out.println("Sequence complete")
    );
  }
```

### just

- 创建一个发射指定值的Observable
- 将单个数据转换为发射这个单个数据的Observable

```java
public static void main(String[] args) {
    Observable.just("hello just")
        .subscribe(System.out::println);
  }
```

- 也可以发射多个

```java
Observable.just(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
        .subscribe(
          integer -> System.out.println("Next: " + integer),
          throwable -> System.out.println("Error: " + throwable.getMessage()),
            () -> System.out.println("Sequence complete.")
        );
```

- 若传入 null ,会触发空指针异常

### from

- 可以将其他种类的对象和数据类型转换为 Observable
- from 可以将 Future, Iterable 和 数组转换为 Observable

```java
public static void main(String[] args) {
    Observable
        .fromArray("hello", "from")
        .subscribe(System.out::println);

  }
```

```java
public static void main(String[] args) {
    List<Integer> items = new ArrayList<>();
    for (int i=0;i<10;i++) {
      items.add(i);
    }

    Observable
        .fromIterable(items)
        .subscribe(
            integer -> System.out.println("Next: " + integer),
            throwable -> System.out.println("Error: " + throwable.getMessage()),
            () -> System.out.println("Sequence complete.")
        );
  }
```

```java
public static void main(String[] args) {
    ExecutorService executorService = Executors.newCachedThreadPool();
    Future<String> future = executorService.submit(() -> {
      System.out.println("模拟一些耗时的任务...");
      Thread.sleep(5000);
      return "OK";
    });
    // 指定超长时间
    Observable.fromFuture(future, 4, TimeUnit.SECONDS)
        .subscribe(System.out::println, throwable -> System.out.println("Error: " + throwable.getMessage()));
  }
```

### repeat

- 发射一个特定数据重复多次的Observable
- 可以重复发射某个数据序列，也可以限定重复的次数
- repeat 不是一个 Observable, 而是重复发射原始 Observable 的数据序列，这个序列或者是无限的，或者是通过 repeat(n) 指定的重复次数

```java
public static void main(String[] args) {
    Observable.just("hello repeat")
        .repeat(3)
        .subscribe(str -> System.out.println("s=" + s));
  }
```

#### repeatWhen

- 不是缓存和重发 Observable 的数据序列，而是有条件地重新订阅和发射原来的 Observable
- 接收一个发射 void 通知的Observable 作为输入，返回一个发射 void 数据(重新订阅和发射数据)或者直接终止(用 repeatWhen 终止发射数据)的Observable。

```java
public static void main(String[] args) {
    Observable.range(0, 9)
        .repeatWhen((Observable<Object> source) -> Observable.timer(10, TimeUnit.SECONDS))
        .subscribe(System.out::println);

    try {
      Thread.sleep(12000);
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
```

#### repeatUtil

- 到某个条件就不再重复发射数据
- 当 BooleanSupplier 的 getAsBoolean() 返回 false时，表示重复发射上游的 Observable
- 当为 true 的时候，表示中止重复发射上游的 Observable

```java
public static void main(String[] args) {
    final long startTimeMillis = System.currentTimeMillis();
    Observable
        .interval(500, TimeUnit.MILLISECONDS)
        .take(5)
        .repeatUntil(() -> System.currentTimeMillis() - startTimeMillis > 5000)
        .subscribe(System.out::println);

    try {
      Thread.sleep(6000);
    } catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
```



### defer

- 直到有观察者订阅时才创建 Observable, 并且为每个观察者创建一个全新的Observable
- defer 操作符会一直等待直到有观察者订阅它，然后它使用 Observable 工厂方法生成一个 Observable。
- 每个观察者获取的都是自己单独的数据序列

```java
public static void main(String[] args) {
    Observable observable = Observable
        .defer(() -> Observable.just("hello defer"));

    observable.subscribe(System.out::println);
  }
```

### interval

- 创建一个按固定时间间隔发射整数序列的Observable
- 默认在 computation 调度器上执行

```java
public static void main(String[] args) {
    Observable
        .interval(1, TimeUnit.SECONDS)
        .subscribe(System.out::println);

    try {
      Thread.sleep(10000);
    }catch (InterruptedException e) {
      e.printStackTrace();
    }
  }
```

### timer

- 在给定的延迟后发射一个特殊的值
- 默认在 computation 调度上执行

```java
public static void main(String[] args) throws Exception{
    Observable
        .timer(2, TimeUnit.SECONDS)
        .subscribe(along -> System.out.println("hello timer:" + along));

    Thread.sleep(10000);
  }
```

# 变换操作符

| api                                 | 简介                                                         |
| ----------------------------------- | ------------------------------------------------------------ |
| map                                 | 对序列的每一项都用一个函数啦变换 Observable 发射的数据序列   |
| flatMap, concatMap, flatMapIterable | 将 Observable 发射的数据集合变换为 Observables 集合，然后将这些 Observables 集合 发射的数据平坦化地放进一个单独的 Observable 中 |
| switchMap                           | 将 Observable 发射的数据集合变换为 Observables 集合，然后只发射这些 Observables 最近发射过的数据 |
| scan                                | 对 Observable 发射的每一项数据应用一个函数，然后按顺序依次发射每一个值 |
| groupBy                             | 将 Observable 拆分为 Observable 集合，将原始的 Observable 发射的数据按 Key 分组，每一个 Observable 发射一组不同的数据 |
| buffer                              | 定期从 Observable 收集数据到一个集合，然后把这些集合打包发射，而不是一次发射一个 |
| window                              | 定期将来自 Observable 的数据拆分一些 observable 窗口，然后发射这些窗口，而不是每次发射一个 |
| cast                                | 在发射之前强制将Observable 发射的所有数据转换为指定类型      |

### map

- 将发射的每一项数据应用一个函数，执行变换操作
- 默认不在任何特定的调度器上执行

```java
public static void main(String[] args) {
    Observable
        .just("HELLO")
        .map(str -> str.toLowerCase())
        .map(str -> str + " world")
        .subscribe(System.out::println);
  }
```

### flatmap

- 将一个发射数据的 Observable 变换为多个Observable 变为多个 Observables, 然后将它们发射的数据合并后放进一个单独的Observable
- 使用一个指定的函数对原始的 Observable 发射的每一项数据执行变换操作，这个函数本身也返回一个发射数据的Observable,然后 flatMap 合并这些 Observables 发射的数据，最后将合并后的结果当做它自己的数据序列发射

```java
public static void main(String[] args) {
    User user = init();

    Observable
        .just(user)
        .flatMap(user1 -> Observable.fromIterable(user1.address))
        .subscribe(address -> System.out.println(address.street));
  }

  private static User init() {
    User user = new User();
    user.userName = "tony";
    user.address = new ArrayList<>();
    Address address1 = new Address();
    address1.city = "wu han";
    address1.street = "qiao kou";
    user.address.add(address1);

    Address address2 = new Address();
    address2.city = "wen zhou";
    address2.street = "qiao tou";
    user.address.add(address2);
    return user;
  }
```

- 假如希望 发射数据的顺序不是交错的，可以使用 concatMap

### groupBy

- 将一个 Observable 拆分为一些 Observables 集合，它们中的每一个都发射原始 Observable 的一个子序列
- 哪个数据项由哪一个Observable 发射是由一个函数判定的，这个函数给每一项指定一个Key, Key 相同的数据会被同一个 Observable 发射
- 最终返回的是 Observable 的一个特殊子类 GroupedObservable, 它是一个抽象类。#getKey 用于将数据分组到指定的 Observable

```java
public static void main(String[] args) {
    Observable
        .range(1, 8)
        .groupBy(integer -> integer % 2 == 0 ? "偶数组" : "奇数组")
        .subscribe(stringIntegerGroupedObservable -> {
          if ("奇数组".equals(stringIntegerGroupedObservable.getKey())) {
            stringIntegerGroupedObservable.subscribe( integer -> System.out.println("奇数组:" + integer));
          }
        });
  }
```

### buffer

- 定期收集Observable 数据并放进一个数据包裹，然后发射这些数据包裹，而不是一次发射一个值
- 将一个 Observable 变化为另一个，原来的 Observable 正常发射数据，由变换产生的 Observable 发射这些数据的缓存集合

```java
public static void main(String[] args) {
    Observable
        .range(1, 10)
        .buffer(2)
        .subscribe(
            integers -> System.out.println("onNext: " + integers)
            , throwable -> System.out.println("onError")
            , () -> System.out.println("onComplete:")
        );
  }
```

- 比较常用的还有 buffer(count, skip)
  - 从原始的 Observable 的第一项数据开始创建新的缓存，此后每当收到 skip 项数据，就用 count 项数据填充缓存: 开头的一项和后续的 count -1 项
  - 以列表的形式发射缓存
  - 这些缓存可能会有重叠部分(skip < count 时), 也有可能会有间隙(skip > count 时)

```java
public static void main(String[] args) {
    Observable
        .range(1, 10)
        .buffer(5,1 )
        .subscribe(
            integers -> System.out.println("onNext: " + integers)
            , throwable -> System.out.println("onError")
            , () -> System.out.println("onComplete:")
        );
  }
/*
输出
onNext: [1, 2, 3, 4, 5]
onNext: [2, 3, 4, 5, 6]
onNext: [3, 4, 5, 6, 7]
onNext: [4, 5, 6, 7, 8]
onNext: [5, 6, 7, 8, 9]
onNext: [6, 7, 8, 9, 10]
onNext: [7, 8, 9, 10]
onNext: [8, 9, 10]
onNext: [9, 10]
onNext: [10]
onComplete:
*/
```

- 假如发射了 onError 通知，那么 buffer 会立即传递这个通知
- 还有可以指定时间来定期收集的用法

```java
public class BufferOperator {

  public static void main(String[] args) {
    Observable
        .range(1, 10)
        // 每200毫秒收集一次
        .buffer(200, TimeUnit.MILLISECONDS)
        .subscribe(
            integers -> System.out.println("onNext: " + integers)
            , throwable -> System.out.println("onError")
            , () -> System.out.println("onComplete:")
        );
  }
}
```



### window

- 定期将来自原始 Observable 的数据分解为一个 Observable 窗口，发射这些窗口
- window 发射的不是原始 Observable 的数据包，而是 Observables, 这些 Observables 中的每一个都发射原始 Observables 数据的一个子集，最后发射一个 onComplete 通知

```java
public static void main(String[] args) {
    Observable
        .range(1, 10)
        .window(2)
        .subscribe(integerObservable -> {
          System.out.println("onNext");
          integerObservable.subscribe(
              integer -> System.out.println("accept: " + integer),
              throwable -> System.out.println("onError:"),
              () -> System.out.println("onComplete:")
          );
        });
  }
```



# 过滤操作符

| api                          | 简介                                                         |
| ---------------------------- | ------------------------------------------------------------ |
| filter                       | 过滤数据                                                     |
| takeLast                     | 只发射最后的N项数据                                          |
| last                         | 只发射最后一项数据                                           |
| lastOrDefault                | 只发射最后一项数据，如果数据为空，就发射默认值               |
| takeLastBuffer               | 将最后的N项数据当做单个数据发射                              |
| skip                         | 跳过开始的N项数据                                            |
| skipLast                     | 跳过最后的N项数据                                            |
| take                         | 只发射开始的N项数据                                          |
| first takeFirst              | 只发射第一项数据，或者满足某种条件的第一项数据               |
| firstOrDefault               | 只发射第一项数据，如果为空，就发射默认值                     |
| elementAt                    | 发射第N项数据                                                |
| elementOrDefault             | 发射第N项数据，假如为空，就发射默认值                        |
| sample throttleLast          | 定期发射 Observable 最近的数据                               |
| throttleWithTimeout debounce | 只有当 Observable 在指定的时间段后还没有发射数据时，才才发射一个数据 |
| timeout                      | 如果在一个指定的时间段后还没发射数据，就发射一个异常         |
| distinct                     | 过滤掉重复的数据                                             |
| distinctUnitChanged          | 过滤掉连续重复的数据                                         |
| ofType                       | 只发射指定类型的数据                                         |
| ignoredElements              | 丢弃掉所有的正常数据，只发射错误或完成通知                   |
|                              |                                                              |

### first

- 只发射第一项数据
- 还可以指定默认值

```java
public static void main(String[] args) {
    Observable.just(1, 2, 3)
        // 这里指定的是默认值
        .first(7)
        .subscribe(
            integer -> System.out.println("Next:" + integer),
            throwable -> System.out.println("Error: " + throwable.getMessage())
        );
  }
```

### last

- 基本同上，不过是最后一个值

### take

- 只发射前 n项数据
- 当要发射的数据不足 n项时，不会报错，而只是发射所有的数据
- 有一个重载方法能够接受一个时长而不是数量参数。它会丢掉发射 Observable 开始的那段时间发射的数据

```java
public static void main(String[] args) throws Exception{
    Observable
        /*
        * 每隔1 秒发射 1 个数据, 从 0 开始 到 9 结束
        * */
        .intervalRange(0 ,10, 1, 1, TimeUnit.SECONDS)
        .take(3, TimeUnit.SECONDS)
        .subscribe(
            aLong -> System.out.println("Next: " + aLong),
            throwable -> System.out.println("Error:" + throwable.getMessage()),
            () -> System.out.println("Sequence complete")
        );

    Thread.sleep(10000);
  }
```

- 默认在 computation 线程上，可以改

### takeLast

- 同上，不过是倒数的

### skip

- 忽略Observable 发射的前 n 项数据
- 也有一个重载方法能接受一个时长而不是数量参数

### skipLast

- 同上，不过是倒数

### elementAt

- 只发射第 n项数据, 返回一个 Maybe 类型
- 索引值基于0, 传递负数会抛出下标越界异常
- 假如原始 Observables 的数据项小于 index+1,那么会调用 onComplete () 方法
- 重载了一个带默认值的方法，返回 Single 类型

```java
public static void main(String[] args) {
    Observable
        .just(1, 2, 3, 4, 5)
        .elementAt(10, 0)
        .subscribe(
          integer -> System.out.println("Next: " + integer),
          throwable -> System.out.println("Error: " + throwable.getMessage())
        );
  }
```

### ignoreElements

- 不发射任何数据，只发射终止通知
- 也就是只允许 onError 或 onComplete 通过，返回的是一个 Completeable类型

### distinct

- 过滤掉重复的数据
- 过滤规则是: 只允许还没有发射过的数据项通过

```java
public static void main(String[] args) {
    Observable
        .just(1, 2, 1, 2, 3, 4, 5, 5, 6)
        .distinct()
        .subscribe(
            integer -> System.out.println("Next: " + integer),
            throwable -> System.out.println("Error: " + throwable.getMessage()),
            () -> System.out.println("Sequence complete")
        );
  }
/*
输出
Next: 1
Next: 2
Next: 3
Next: 4
Next: 5
Next: 6
Sequence complete
*/
```

- 可以接收一个 Function 类型的参数

### distinctUntilChanged

- 跟 distinct 类似
- 只判断一个数据是否和它的直接前驱有不同

### filter

- 只发射通过谓词测试的数据项

### debounce

- 仅在过了一段指定的时间还没发射数据时才发射一个数据
- 该操作符的主要用处在于过滤掉发射速率过快的数据项

```java
 public static void main(String[] args) throws Exception{
    Observable
        .create((ObservableEmitter<Integer> observableEmitter) -> {
          if (!observableEmitter.isDisposed()) {
           try {
             for (int i=1;i<=10;i++) {
               observableEmitter.onNext(i);
               Thread.sleep(i * 100);
             }
           }catch (Exception e) {
            observableEmitter.onError(e);
           }
          }
        })
        // 假如发射数据的间隔少于 500ms 时，就过滤拦截
        .debounce(500, TimeUnit.MILLISECONDS)
        .subscribe(
            integer -> System.out.println("Next: " + integer),
            throwable -> System.out.println("Error: " + throwable.getMessage()),
            () -> System.out.println("Sequence complete.")
        );

    Thread.sleep(10000);
  }
/*
输出
Next: 6
Next: 7
Next: 8
Next: 9
Next: 10
*/
```

- 还可以接收一个 Function 参数
- 比较类似的是 throttleWithTimeout 操作符，它与只用时间参数来限流的debounce 的功能相同

# 线程操作

### Scheduler

- 对线程控制器的一个抽象，内置了许多实现

| Scheduler       | 作用                                                         |
| --------------- | ------------------------------------------------------------ |
| single          | 使用定长为 1 的线程池(new Scheduled Thread Pool(1)), 重复利用这个线程 |
| newThread       | 每次都启动新线程并在新线程中执行操作                         |
| computation     | 使用固定的线程池, 大小为 CPU  核数，适用于CPU密集型计算      |
| io              | 适合IO操作，内部是一个无数量上限的线程池                     |
| trampoline      | 直接在当前线程运行，如果当前线程有其它任务正在执行，则会先暂停其它任务 |
| Scheudlers.from | 将 java.util.Executor 转换成一个调度器实例，即可自定义一个 Executor 来作为调度器 |

- observerOn 表示在哪个线程生成事件
- subscribeOn 表示在哪个线程消费事件
- 可以利用 TestScheduler 来做测试



# 条件操作符

## amb

- 给定两个或多个Observable, 它只发射首先发射数据或通知的那个Observable 的所有数据
- 不管发射的是一项数据，还是一个 onError 还是 onCompleted 通知，amb将忽略和丢弃其它所有Observable 的发射物
- 有一个类似的操作符 ambWith:  Observable.amb(o1, o2) <==> o1.ambWith(02)
- 需要使用一个 Iterable 对象或 ambArray 来传递可变参数

```java
public class AmbOperator {

	public static void main(String[] args) {
		Observable.ambArray(
				Observable.just(1, 2, 3),
				Observable.just(4, 5, 6)
		).subscribe(integer -> System.out.println("integer: " + integer));
	}
}
```



## defaultIfEmpty

- 发射来自原始  Observable 的值，如果原始Observable 没有发射任何值，就发射一个默认值
- 如果原始Observable 没有发射任何数据，就正常终止(以 onComplete的形式)，然后就会发射一个默认值

```java
public class DefaultIfEmptyOperator {

	public static void main(String[] args) {
		Observable
				.empty()
				.defaultIfEmpty(8)
				.subscribe(object -> System.out.println("defaultIfEmpty(): " + object));
	}
}
```

- defaultIfEmpty 内部就是使用的 switchIfEmpty, 区别是 default 只发送一个数据，想要发射多个的时候可以使用 switchIfEmpty

```java
Observable
				.empty()
				.switchIfEmpty(Observable.just(1, 2, 3))
				.subscribe(obj -> System.out.println("switchIfEmpty():" + obj));
```



## skipUntil

- 丢弃原始 Observable 发射的数据，直到第二个 Observable 发射了一项数据
- 会订阅原始的 Observable, 但是忽略它的发射物，直到第二个 Observable 发射一项数据那一刻，它才开始发射原始 Observable
- 默认不在任何特定的调度器上执行

```java
public class SkipUntilOperator {

	public static void main(String[] args) {
		Observable
				// 发射 1 到 9 九个数字，初始延迟时间为0 每个间隔 1ms
				.intervalRange(1, 9, 0, 1, TimeUnit.MILLISECONDS)
				// 让 Observable 发射 4ms 之后的数据
				.skipUntil(Observable.timer(4, TimeUnit.MILLISECONDS))
				.subscribe(System.out::println);

		try{
			Thread.sleep(1000);
		}catch (InterruptedException e){
			e.printStackTrace();
		}
	}
}

// 打印结果 5 6 7 8 9
```



## skipWhile

- 丢弃 Obsevable 发射的数据，直到一个指定的条件不成立
- 订阅原始的Observble ,但是忽略其发射物，直到指定的某个条件变为false，才开始发射默认的Observable
- 默认不在任何特定的调度器上执行

```java
public class SkipWhileOperator {

	public static void main(String[] args) {
		Observable
				.just(1, 2, 3, 4, 5)
				.skipWhile(integer -> integer <= 2)
				.subscribe(System.out::println);
	}
}

// 打印结果 3, 4, 5
```



## takeUnit

- 当第二个 Observable 发射了一项数据或者终止时，丢弃原始 Observable 发射的任何数据
- 订阅并开始发射原始的 Observable ，它还会监视用户提供的第二个 Observable,，如果第二个 Observable 发射了一项数据或发射了一个终止通知，则takeUntil 返回的 Observable 会停止发射原始 Observable 并终止

```java
public class TakeUntilOperator {

	public static void main(String[] args) {
		Observable.just(1, 2, 3, 4, 5, 6, 7, 9)
				.takeUntil(integer -> integer == 5)
				.subscribe(System.out::println);
	}
}
```

- 默认不在任何特定的调度器上执行

## takeWhile

- 发射原始 Observable 发射的数据，直到一个指定的条件不成立
- 发射原始的 Observable, 直到某个指定的条件不成立，它会立即停止发射原始 Observable，并终止自己的 Observable

```java
public class TakeWhileOperator {

	public static void main(String[] args) {
		Observable
				.just(1, 2, 3, 4, 5)
				.takeWhile(integer -> integer <= 2)
				.subscribe(
						System.out::println,
						System.out::println,
						() -> System.out.println("onComplete"));
	}
}
```





# 布尔操作符

## all

- 判断 Observable 发射的所有数据是否都满足某个条件
- 传递一个谓词函数给 all 操作符
- all 返回一个只发射单个布尔值的 Observable
- all 操作符默认不在任何特定的调度器上执行

```java
public class AllOperator {

	public static void main(String[] args) {
		Observable.just(1, 2, 3, 4, 5)
				.all(integer -> integer < 10)
				.subscribe(System.out::println);
	}
}
```



## contains

- 判断一个 Observable 是否发射了一个特定的值
- 给 contains 传一个指定的值，看Observable是否发射了该值

```java
Observable.just(2, 30, 22, 5, 60, 1)
				.contains(22)
				.subscribe(aBoolean -> System.out.println("contains(22):" + aBoolean));
```



## exitsts

## isEmpty

- 无参数，用来判断是否没有发射数据

```java
Observable.just(2, 30, 22, 5, 60, 1)
				.isEmpty()
				.subscribe(aBoolean -> System.out.println("isEmpty:" + aBoolean));
```



## sequenceEqual

- 判断两个 Observable 是否发射相同的数据序列
- 传递两个 Observable, 或则两个 Observable 一个比较参数来比较发射项是否相等

```java
public class SequenceEqualOperator {

	public static void main(String[] args) {
		Observable
				.sequenceEqual(
						Observable.just(4, 5, 6),
						Observable.just(4, 5, 6),
						Integer::equals
				).subscribe(aBoolean -> System.out.println("sequenceEqual:" + aBoolean));
	}
}
```

- 该操作符默认不在任何特定的调度器执行

# 合并操作符

## startWith

- 在数据序列的开头插入一条指定的项
- 如果想让一个 Observable 在发射数据之前先发射一个指定的数据序列，则可以使用 startWith 操作符
- 如果想在一个 Observable 发射数据的末尾追加一个数据序列，则可以使用 concat操作符

```java
public class StartWithOperator {

	public static void main(String[] args) {
		Observable
				.just("Hello Java", "Hello Kotlin", "Hello Scala")
				.startWith("Hello Rx")
				.subscribe(System.out::println);
	}
}
```

- 支持传递 Iterable, 还可以使用 startWithArray, 还可以传递 Observable

## merge

- 可以让多个Observable的输出合并，使得它们就像是单个的Observable一样

```java
public class MergeOperator {

	public static void main(String[] args) {
		Observable<Integer> odds = Observable.just(1, 3, 5);
		Observable<Integer> evens = Observable.just(2, 4, 6);

		Observable
				.merge(odds, evens)
				.subscribe(
						integer -> System.out.println("Next: " + integer),
						throwable -> System.out.println("Error: " + throwable.getMessage()),
						() -> System.out.println("Sequence complete")
				);

	}
}
```

- merge   是按照时间线并行的如果传递给 merge 的任何一个 Observable 发射了 onError 通知终止，则merge生成的 Observable也会立即以 onError 通知终止
- 如果想在发生错误时不立即终止，直到最后才报告错误的话，可以使用 mergeDelayError
- 该操作符最多合并4个被观察者，如果需要合并更多，可以使用 mergeArray 操作符

## mergeDelayError

- 在 merge 中说明

## zip

- 通过一个函数将多个 Observable 的发射物结合到一起，基于该函数的结果为每个结合体发射单个数据项
- 会按顺序结合两个或多个Observable发射的数据项，然后发射这个函数返回的结果。它按照严格的顺序应用该函数，只发射与发射数据项最少的那个Observable一样多的数据

```java
public class ZipOperator {

	public static void main(String[] args) {
		Observable<Integer> odds = Observable.just(1, 3, 5, 7, 9);
		Observable<Integer> evens = Observable.just(2, 4, 6);

		Observable.zip(odds, evens, (int1, int2) -> int1 + int2)
				.subscribe(
						int1 -> System.out.println("Next: " + int1),
						throwable -> System.out.println("Error: " + throwable.getMessage()),
						() -> System.out.println("Sequence complete")
				);
	}
}

// 打印结果 3, 7, 11 odds 的 7 9 数据没有发射
```



## combineLatest

- 类似于zip，但是当原始的Observable 中的任意一个发射了数据时就发射一条数据
- 当原始Observable的任何一个发射了一条数据时，combineLatest使用一个函数结合它们最近发射的数据，然后发射这个函数的返回值

```java
public class CombineLatestOperator {

	public static void main(String[] args) {
		Observable<Integer> odds = Observable.just(1, 3, 5);
		Observable<Integer> evens = Observable.just(2, 4, 6);

		Observable.combineLatest(odds, evens, (int1, int2) -> int1 + int2)
				.subscribe(
						int1 ->  System.out.println("Next: " + int1),
						throwable -> System.out.println("Error: " +throwable.getMessage()),
						() -> System.out.println("Sequence complete")
				);
	}
}
```



## join

- 结合两个 Observable 发射的数据，基于时间窗口（针对每条数据特定的原则）选择待集合的数据项
- 将这些时间窗口实现为一些 Observable, 它们的生命周期从任何一条 Observable 发射的每一条数据开始
- 当这个定义时间窗口的 Observable 发射了一条数据或者完成时，与这条数据关联的窗口也会关闭
- 只要这条数据的窗口是打开的，它就继续结合其它 Observable 发射的任何数据项

```java
public class JoinOperator {

	public static void main(String[] args) {
		Observable<Integer> o1 = Observable.just(1, 2, 3);
		Observable<Integer> o2 = Observable.just(4, 5, 6);

		o1.join(o2,
				int1 -> Observable.just(String.valueOf(int1)).delay(200, TimeUnit.MILLISECONDS),
				int2 -> Observable.just(String.valueOf(int2)).delay(200, TimeUnit.MILLISECONDS),
				(int3, int4) -> int3 + ": " +  int4
		).subscribe(s -> System.out.println("onNext " + s));

		try{
			Thread.sleep(2000);
		}catch (InterruptedException e) {
			e.printStackTrace();
		}
	}
}

// 打印的日志
/*
onNext 1: 4
onNext 2: 4
onNext 3: 4
onNext 1: 5
onNext 2: 5
onNext 3: 5
onNext 1: 6
onNext 2: 6
onNext 3: 6
*/
```

- join(Observable, Function, Function, BiFunction)
  - 源 Observable 需要组合的 Observable, 即目标 Observable
  - Function: 接收从源 Observable 发射来的数据，并返回一个 Observable, 这个 Observable 的生命周期决定了源 Observable 发射数据的有效期
  - Function: 接收从目标 Observable 发射来的数据，并返回一个 Observable, 这个 Observable 的生命周期决定了目标 Observable 发射数据的有效期
  - BiFunction: 接收从源 Observable 和 目标 Observable 发射的数据，并将这两个数据组合后返回

## groupJoin

## switchOnNext

# 连接操作符

## connectableObservable.connect()

- ConnectableObservable 只有对其使用 connect 操作符的时候才会发射数据， ConnectableObservable 也是 HotObservable
- publish 操作符可以将普通的 Observable 转换为 ConnectableObservable
- 可以等所有观察者都订阅了 ConnectableObservable 之后再发射数据

```java
public class ConnectableObservableDemo {

	public static void main(String[] args) {
		Observable<Long> obs = Observable
				.interval(1, TimeUnit.SECONDS)
				.take(6);

		ConnectableObservable<Long> connectableObservable = obs.publish();

		connectableObservable
				.subscribe(new Observer<Long>() {
										 @Override
										 public void onSubscribe(Disposable d) {

										 }

										 @Override
										 public void onNext(Long aLong) {
												System.out.println("subscriber1: onNext:" + aLong + "-> time:" + format());
										 }

										 @Override
										 public void onError(Throwable e) {
												System.out.println("subscriber1: onError");
										 }

										 @Override
										 public void onComplete() {
												System.out.println("subscriber1: onComplete");
										 }
									 }

				);
		connectableObservable
				.delay(3, TimeUnit.SECONDS)
				.subscribe(new Observer<Long>() {
					@Override
					public void onSubscribe(Disposable d) {

					}

					@Override
					public void onNext(Long aLong) {
						System.out.println("subscriber2: onNext:" + aLong + "->time:" + format());
					}

					@Override
					public void onError(Throwable e) {
						System.out.println("subscriber2: onError");
					}

					@Override
					public void onComplete() {
						System.out.println("subscriber2: onComplete");
					}
				});

		connectableObservable.connect();

		try{
			Thread.sleep(15000);
		}catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	private static String format() {
		return LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
	}
}
```

- refCount 操作符可以将 ConnectableObservable 转换为普通的 Observable, 同时保持 Hot Observable的特性
- 当出现第一个订阅者时， refCount 会调用 connect, 每个订阅者会依次收到相同的数据
- 当所有的订阅者取消订阅时，refCount会自动 dipose 上游的 Observable
- 当所有的订阅者都取消订阅后，则数据流停止，如果重新订阅则数据流重新开始
- 如果不是所有的订阅者都取消了订阅，而只是取消了部分，则部分订阅者重新开始订阅时，不会从头开始数据流

## Observable.publish()

- 将普通的 Observable 转换为 ConnectableObservable

## Observable.replay()

- 保证所有的观察者收到相同的数据序列，即使它们在 Observable 开始发射数据之后才订阅
- 返回一个 connectableObservable 对象，并且可以缓存发射过的数据
- 使用 replay 操作符最好还是先限定缓存的大小，对缓存的控制可以从空间和时间两个方面来考虑

```java
public class ReplayOperator {

	public static void main(String[] args) {
		Observable<Long> obs = Observable
				.interval(1, TimeUnit.SECONDS)
				.take(6);

		ConnectableObservable<Long> connectableObservable = obs.replay();
		connectableObservable.connect();

		connectableObservable.subscribe(new Observer<Long>() {
			@Override
			public void onSubscribe(Disposable d) {

			}

			@Override
			public void onNext(Long aLong) {
				System.out.println("subscriber1: onNext: " + aLong + format());
			}

			@Override
			public void onError(Throwable e) {
				System.out.println("subscriber1: onError");
			}

			@Override
			public void onComplete() {
				System.out.println("suscriber1: onComplete");
			}
		});

		// 延迟开始但是仍然能收到完整的数据
		connectableObservable
				.delaySubscription(3, TimeUnit.SECONDS)
				.subscribe(new Observer<Long>() {
					@Override
					public void onSubscribe(Disposable d) {

					}

					@Override
					public void onNext(Long aLong) {
						System.out.println("subscriber2: onNext: " + aLong + format());
					}

					@Override
					public void onError(Throwable e) {
						System.out.println("subscriber2: onError");
					}

					@Override
					public void onComplete() {
						System.out.println("suscriber2: onComplete");
					}
				});

		try{
			Thread.sleep(15000);
		}catch (InterruptedException e) {
			e.printStackTrace();
		}
	}

	private static String format() {
		return LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
	}
}
```

- replay 有多个不同参数的重载方法，有的可以指定 replay 的最大缓存数量，有的可以指定调度器
- ConnectableObservable 的线程切换只能通过 replay 操作符实现，普通的方法不起作用

## ConnectableObservable.refCount()

- 将 ConnectableObservable 转为普通的 Observable



# 背压策略

Flowable专门用来处理背压，默认支持五种背压策略

### MISSING

- 通过 create 方法创建的 Flowable 没有指定背压策略，不会通过 OnNext 发射的数据做缓存或丢弃处理
- 需要下游通过背压操作符指定背压策略

### ERROR

- 如果放入 Flowable 的异步缓存池中的数据超限了，则会抛出 MIssingBackpressureException 异常

```java
public class ErrorStrategy {

	public static void main(String[] args) {
		Flowable.create((FlowableEmitter<Integer> e) -> {
			// 默认队列大小 128, 所以发送 129 条数据后必然会报错
			for (int i=0; i<129; i++) {
				e.onNext(i);
			}
		}, BackpressureStrategy.ERROR)
				.observeOn(Schedulers.newThread())
				//.subscribeOn(Schedulers.single())
				//.subscribe(System.out::println);
				.subscribe(System.out::println);

	}
}
```

### BUFFER

- 异步缓存池没有固定大小，会无限增长直到 OOM

### DROP

- 如果异步缓存池满了，就丢掉将要放入缓存池中的数据

### LATEST

- 如果缓存池满了，会丢掉将要放入缓存池中的数据。
- 不管缓存池的状态如何，LATEST策略会将最后一条数据强行放入缓存池中



### 也可以在 just from等操作之后通过方法调用来指定背压策略



# Disposable

- 用来取消订阅

## CompositeDisposable

- 得到一个 Disposable 的事实可以调用 CompositeDisposable.add() 将它添加到容器中国
- 需要销毁资源的时候，可以调用 Composable.clear() 来切断所有的事件，避免内存泄漏



# Transformer

- 能够将一个 Observable/Flowable/Single/Completeable/Maybe 对象转换为另一个 Observable/Flowable/Single/Completeable/Maybe 对象，与调用一系列的内联操作符一模一样

```java
public class TransformerSimpleDemo {

	public static void main(String[] args) {
		Observable.just(123, 456)
				.compose(transformer())
				.subscribe(s -> System.out.println("s=" + s));
	}

	// 将integer转换为字符串
	private static ObservableTransformer<Integer, String> transformer() {
		return (Observable<Integer> upstream) -> upstream.map(String::valueOf);
	}
}
```

## 与 compose 操作符结合使用

- compose 操作符能够从数据流中得到原始的被观察者。
- 当创建被观察者时，compose操作符会立即执行，而不像其它操作符需要在 onNext() 后才能被执行

### 切换到主线程



TODO 待补完

# RxJava的并行编程

待TODO 看了 fork/join 之后再补完



# RxBinding 

安卓用的库

