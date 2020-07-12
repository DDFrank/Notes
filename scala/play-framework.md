# 基础概念

## Action

- 接收Http请求后，通常会 build 一个 action作为应答



## Controller

- 假如有Controller的话，那么通常通过 Controller来build Action
- Controller 通常会用于DI，所以尽量定义为 class



## Result

- 可以用来描述 Http Response

```scala
import play.api.http.HttpEntity

def index = Action {
  // 跟 Ok一样
  Result(
    header = ResponseHeader(200, Map.empty),
    body = HttpEntity.Strict(ByteString("Hello world!"), Some("text/plain"))
  )
}
```



## 定义 form 的基本步骤

- 定义一个 form 对象
- 给 form 对象加上验证
- 从 action中校验 form
- 