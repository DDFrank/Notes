# 对于 Future 的理解

## compose

- 第一个版本

```java
/**
	作用应该是按顺序连接两个future
	T : 本 Future 处理成功时期望获得的数据
	U : 下一个Future 所期望获得的数据
	当地一个 future 完成时，会自动返回一个 包含下次执行结果的future
	mapper 中应该包含 
	
**/
default <U> Future<U> compose(Function<T, Future<U>> mapper) {
    if (mapper == null) {
      throw new NullPointerException();
    }
  	/*
  		返回的下一个future
  	*/
    Future<U> ret = Future.future();
  	// 设置本 Future 的 处理器
    setHandler(ar -> {
      // 假如本次 Future 处理成功
      if (ar.succeeded()) {
        Future<U> apply;
        try {
          /*
          	将本次处理成功得到的结果作为参数传入 Function
          	执行，得到一个 future, 这个 apply 的状态决定  ret 的状态
          */
          apply = mapper.apply(ar.result());
        } catch (Throwable e) {
          // 出现异常的话将下一个 future 判定为失败
          ret.fail(e);
          return;
        }
        // 将 ret 作为 apply 的 回调处理, apply 完成或失败的的时候会调用 让 ret 成功或失败
        apply.setHandler(ret);
      } else {
        ret.fail(ar.cause());
      }
    });
    return ret;
  }
```

- 第二个版本

```java
/*
也是连接两个future
*/
default <U> Future<U> compose(Handler<T> handler, Future<U> next) {
    // 设置本 future 的处理器
    setHandler(ar -> {
      if (ar.succeeded()) {
        try {
          /*
	          假如处理成功的话，就调用 handler
	          这个 handler 的执行应该要去 complete next 这个 future
          */ 
          handler.handle(ar.result());
          // 下面都是处理错误的情况，如果处理错误了，就 faile next
        } catch (Throwable err) {
          if (next.isComplete()) {
            throw err;
          }
          next.fail(err);
        }
      } else {
        next.fail(ar.cause());
      }
    });
    return next;
  }
```

