# Creating and Destorying Objects
## Consider static factory methods instead of constructors(使用静态工厂来代替构造器)
PS: 静态工厂方法不能等同于工厂模式
### 静态工厂方法的优点
- 静态工厂方法可以取不同的名字，可读性更好
假如多个构造器有相同的方法签名，用静态工厂方法时更好的实践，更能看出方法之间的区别
- 静态工厂方法不一定每一次都需要返回一个新的对象
这样就方便了不可变对象的实现或者缓存机制的实现
- 可以返回想要的类型，比如子类型，私有的内部类之类的

### 主要缺点
- 私有的子类无法被通过静态方法得到
- 有时候方法不太好找

## Consider a builder when faced with many constructor parameters(当成员变量很多的时候，考虑使用 builder 模式)

### 为什么需要

- 当可选的成员变量很多的时候，静态工厂和构造器都不太好

### 执行

```java
public class NutritionFacts {
  private final int servingSize;
  private final int servings;
  private final int calories;
  private final int fat;
  private final int sodium;
  private final int carbohydrate;

  public static class Builder {
    // 必选的成员
    private final int servingSize;
    private final int servings;
    // 可选的成员
    private int calories = 0;
    private int fat = 0;
    private int sodium = 0;
    private int carbohydrate = 0;
	
    // 如果需要的话，也可以在在这些地方做有效性检查
    public Builder(int servingSize, int servings) {
      this.servingSize = servingSize;
      this.servings = servings;
    }

    public Builder calories(int calories) {
      this.calories = calories;
      return this;
    }

    public Builder fat(int fat) {
      this.fat = fat;
      return this;
    }

    public Builder sodium(int sodium) {
      this.sodium = sodium;
      return this;
    }

    public Builder carbohydrate(int carbohydrate) {
      this.carbohydrate = carbohydrate;
      return this;
    }

    public NutritionFacts build() {
      return new NutritionFacts(this);
    }
  }

  private NutritionFacts(Builder builder) {
    this.servingSize = builder.servingSize;
    this.servings = builder.servings;
    this.calories = builder.calories;
    this.fat = builder.fat;
    this.sodium = builder.sodium;
    this.carbohydrate = builder.carbohydrate;
  }
}
```

客户端代码

```java
public class Action {

  public static void main(String[] args) {
    NutritionFacts nutritionFacts = new NutritionFacts
        .Builder(240, 8)
        .calories(100)
        .sodium(35)
        .carbohydrate(27)
        .build();
  }
}
```



抽象父类的例子

```java
public abstract class Pizza {
  public enum Topping { HAM, MUSHROOM, ONION, PEPPER, SAUSAGE }
  final Set<Topping> toppings;

  // 泛型的类型为子类的 Builder
  abstract static class Builder<T extends  Builder<T>> {
    // 空集合
    EnumSet<Topping> toppings = EnumSet.noneOf(Topping.class);

    public T addTopping(Topping topping) {
      toppings.add(Objects.requireNonNull(topping));
      return self();
    }
    // 泛型变量的类型获取交给子类解决
    protected abstract T self();

    abstract Pizza build();
  }
  Pizza(Builder<?> builder) {
    toppings = builder.toppings.clone();
  }
}

public class NyPizza extends Pizza {
  public enum Size {SMALL, MEDIUM, LARGE}
  private final Size size;

  public static class Builder extends Pizza.Builder<Builder> {
    private final Size size;

    public Builder(Size size) {
      this.size = Objects.requireNonNull(size);
    }

    @Override
    protected Builder self() {
      return this;
    }

    @Override
    public NyPizza build() {
      return new NyPizza(this);
    }
  }

  NyPizza(Builder builder) {
    super(builder);
    size = builder.size;
  }
}
```

客户端代码

```java
NyPizza pizza = new NyPizza.Builder(Size.SMALL)
                      .addTopping(Topping.SAUSAGE)
                      .addTopping(Topping.ONION)
                      .build();
```



### 好处

- 类可以是 immutable的
- 代码初始化的地方都在一起了
- 流式API
- 类似于其它语言的 命名参数

### 坏处

- 在建对象前需要先建 builder, 在性能敏感的应用中有坏处
- 代码量比较大



## Enfoce the singleton property with a private constructor or an enum type(用枚举来创建单例)

```java
public enum Elvis {
  INSTANCE;
  int value;
  
  public int getValue() {
    return value;
  }

  public Elvis setValue(int value) {
    this.value = value;
    return this;
  }
}
```



## 