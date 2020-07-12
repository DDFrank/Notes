# 基于 JavaFX11

# 基本架构

## 场景图 (Scene Graph)

### 基本特点

- 是构建 JavaFX 应用的入口。
- 它是一个层级结构的结构树，表示了所有用户界面的视觉元素
- 可以处理输入，并且可以渲染。

### 节点

- 场景图中的一个元素被称为一个节点，每个节点都有一个 Id, 样式表和包围盒(bounding volume)
- 除了根节点之外，在场景图中的所有节点都有一个父节点，任意个子节点
- 节点的特性
  - 效果 (Effect), 例如模糊和阴影
  - 不透明度(Opacity)
  - 变换(Transforms)
  - 事件处理器(Event handlersm, 例如鼠标，键盘和输入法)
  - 应用相关的状态 (Application-specific state)

### 图元

- 场景图还包括图元，比如矩形，文本，还有控件，布局容器，图像和多媒体

### API

- 节点(Node): 包括各种形状(2d或3d) ，图像，多媒体，内嵌的Web浏览器，文本，UI控件，图表，组和容器
- 状态(State): 变换(节点的定位和定向)，视觉效果，以及内容的其它视觉状态。
- 效果(Effects): 可以改变场景图节点的外观的简单对象。例如模糊, 阴影，图像调整。



## 图形系统 (Graphics System)

- 是在JavaFX 场景图层下的实现细节。
- 支持 2D 和 3D 场景图

### JavaFX 平台中实现了两套图形加速流水线

- Prism 用于处理渲染工作， 可以在硬件和软件渲染器之上工作，包括3D
- Quantum Toolkit 将 Glass Windowing ToolKit 绑在一起，使得它们可以被其上层的JavaFX 层使用。它也负责管理与渲染有关的事件处理的线程规则。

## Glass 窗体工具包

- 位于整体架构的中间位置，处于JavaFX图形技术栈的最底层
- 主要职责是提供本地操作服务，比如窗体，计时器，皮肤等。
- 它是连接 JavaFX 层与本地操作系统的平台无关层
- 还负责管理事件队列，使用本地操作系统的事件队列来调度线程

### 线程

- JavaFx 应用程序线程: JavaFX 应用开发者使用的主要线程。
  - 任何活动的场景都是窗体的一部分，它们都需通过此线程来访问。
  - 场景图通过一个后台线程来创建和控制，但是如果其根节点与任何活动对象相关，则该场景图必需通过JavaFX 应用程序线程来访问
- Prism渲染线程: 此线程处理渲染工作，使其与事件调度器独立开来
- 多媒体线程: 此线程会在后台运行， 通过使用JavaFX应用程序线程来在场景图中同步最近的帧。



## 多媒体和图像

- 通过 javafx.scene.media API 可以访问。
- 支持视频和音频媒体。
  - Midia 对象用于标识一个多媒体文件
  - MediaPlayer 用于播放文件
  - MediaView 用于显示内容



## Web 组件

- 是一个基于 Webkit 的JavaFX UI控件，其提供了一个 Web Viewwe, 并通过其API 提供了完全的浏览功能。
- 渲染来自本地或远程URL的HTML内容
- 支持历史记录，提供后退和前进导航
- 内容重加载
- 向Web组件添加效果
- 编辑HTML内容
- 执行JavaScript命令
- 事件处理

### 组成

- WebEngine 提供了基本的Web页面浏览功能
- WebView 封装了WebEngine 对象，将Html 内容整合到应用场景之中，并提供属性和方法来增加效果，变换，它是Node类的一个拓展
- Java 和 JavaScript 可以互相调用



## CSS

- 提供了在不修改应用程序代码的情况下自定义应用程序外观的能力。
- CSS 可以被添加到任何 JavaFX 场景图中的节点之上，这个添加过程是异步的。
- 支持在运行时添加到场景中，这使得动态改变应用外观变得可行。



## UI控件

- 可以在 javafx.scene.control 包中找到



## 布局

- 布局容器(Layoutcontainer) 或面板(Pane) 允许对JavaFX 应用程序场景图中的UI控件进行灵活，动态的排布
- JavaFX Layout API 包括下列容器类
  - BorderPane 将其内容节点放到上下左右中各个区域中
  - HBox 将其内容节点横向排成一行
  - VBox 将其内容纵向排成一列
  - StackPane 将其内容节点摞在一起
  - GrindPane 创建一个灵活的网格，按行列来布局其内容节点
  - FlowPane 将其内容按行或列进行 "流式"布局，当遇到横向或纵向的边界时自动进行换行或换列
  - TilePane 将其内容放到统一大小的单元格中
  - AnchorPane 可以创建锚点，将控件停靠于布局的上下左右各边，也可以居中停靠

## 2D和3D变换

- 每个节点都可以使用下面 javafx,scene,tranform 包中的类来进行 x-y 坐标系变换
  - translate : 将一个节点在 xyz 坐标系中从一个位置移动到另外一个位置
  - scale : 将一个节点在 xyz 坐标系中根据缩放因子进行缩放
  - shear: 旋转一个坐标轴，这样 x 和 y轴就不是垂直的了。节点的坐标值会根据制定的倍数进行变换
  - rotate : 根据 scene 中指定的一个支点对节点进行旋转
  - affine: 执行一个2D/3D坐标系到另外一个2D/3D坐标系的线性映射，同时保留线条的 'straight' 和 'parallel' 属性。一般要与 其它动作配合，不单独使用

## 视觉效果

- 开发富客户端界面包括使用视觉效果来实时地美化JavaFX 应用程序的外观。
- JavaFX 的视觉效果主要是基于像素的图像，因此它们需要先获取场景图中节点渲染成图像，再将视觉效果添加上去
- 通过以下类来添加一个常用的效果
  - Drop Shadow: 为给定的内容渲染一个在它后面的阴影。
  - Reflection: 在真实的内容后面渲染一个反射倒影
  - Lighting: 模拟一个光源的照射效果，是一个平面的对象看起来更真实，具有三维效果。



# 基本代码结构

## HelloWorld

```java
// 必须继承 Application 类
public class Main extends Application {
    // 程序的入口
    @Override
    public void start(Stage primaryStage) throws Exception{
        /*
        * UI容器被定义为舞台(Stage) 和 场景(Scene)。
        * Stage 类是 JavaFX 顶级容器
        * Scene类是所有内容的容器
        *
        * Scene中的内容会以图形节点(Node) 构成的分层场景图(Scene Graph) 来展现
        * */
        Button btn = new Button();
        btn.setText("say hello world");
        btn.setOnAction(event -> System.out.println("Hello World!"));

        //Parent root = FXMLLoader.load(getClass().getResource("sample.fxml"));
        // StackPane 是一个可以调整大小的layout节点
        StackPane root = new StackPane();
        root.getChildren().add(btn);
        primaryStage.setTitle("Hello World");
        primaryStage.setScene(new Scene(root, 300, 275));
        primaryStage.show();
    }

    // 当通过 JavaFx Packager 工具打包时，main() 方法就不是必须的了
    public static void main(String[] args) {
        launch(args);
    }
}

```

## 简单的表单

```java
public class MainForm extends Application {

  @Override
  public void start(Stage primaryStage) throws Exception {

    GridPane grid = new GridPane();
    // 将 grid 的默认位置从靠左上角对齐改为了居中显示
    grid.setAlignment(Pos.CENTER);
    // gap 属性管理行列之间的间隔
    grid.setHgap(10);
    grid.setVgap(10);
    // padding 管理 grid 面板边缘周围的间隔
    grid.setPadding(new Insets(25, 25, 25, 25));

    // 增加 文本 标签和文本域
    // 展示了 如何在 grid 中添加Node
    Text sceneTitle = new Text("Welcome");
    sceneTitle.setFont(Font.font("Tahoma", FontWeight.NORMAL, 20));
    // 后两个参数表示列跨度为2， 行跨度为1
    grid.add(sceneTitle, 0, 0, 2, 1);

    // 创建Label对象，放到第0列，第1行
    Label userName = new Label("User Name:");
    grid.add(userName, 0, 1);

    // 创建文本输入框，放到第1列，第1行
    TextField userTextField = new TextField();
    grid.add(userTextField, 1, 1);

    Label pw = new Label("Password:");
    grid.add(pw, 0, 2);

    PasswordField pwBox = new PasswordField();
    grid.add(pwBox, 1, 2);

    // 增加Button 和 Text
    Button btn = new Button("Sign in");
    HBox hbBtn = new HBox(10);
    hbBtn.setAlignment(Pos.BOTTOM_RIGHT);
    // 将按钮控件当做子节点
    hbBtn.getChildren().add(btn);
    grid.add(hbBtn, 1, 4);

    // 添加一个 Text 控件用于显示消息
    final Text actiontarget = new Text();
    grid.add(actiontarget, 1, 6);

    btn.setOnAction(event -> {
      actiontarget.setFill(Color.FIREBRICK);
      actiontarget.setText("Sign in button pressed");
    });
    Scene scene = new Scene(grid, 300, 275);
    primaryStage.setScene(scene);
    primaryStage.setTitle("JavaFX Welcome");
    primaryStage.show();
  }

  public static void main(String[] args) {
    launch(args);
  }
}
```

## CSS

- 记载CSS文件

```java
scene.getStylesheets().add(this.getClass().getResource("Login.css").toExternalForm());
```



# JavaFX 图形

## 3D处理

TODO 待补完

## JavaFX Canvas

TODO 待补完

## JavaFX Image Ops

TODO 待补完

# JavaFX UI组件

## JavaFX UI控件

- 标签 Label
- 按钮 Button
- 单选按钮 Radio Button
- 开关按钮 Toggle Button
- 复选框 Checkbox
- 选择框 Choice Box
- 文本框 Text Field
- 密码框 Password Field
- 滚动条 Scroll Bar
- 滚动面板 Scroll Bar
- 列表视图 List View
- 表格视图 Table View
- 树视图 Tree View
- 树表视图 Tree Table View
- 组合框 Combo Box
- 分隔符 Separator
- 滑块 Slider
- 进度条和进度指示器 Progess Bar and Progress Indicator
- 超链接 Hyperlink
- HTML编辑器 HTML Editor
- 提示信息 Tooltip
- 带有标题的面板和可折叠面板 Titled Pane and Accordion
- 菜单 Menu
- 颜色选择器 Color Picker
- 日期选择器 Date Picker
- 分页控件 Pagination Control
- 文件选择框 File Chooser
- 自定义UI控件 Cusomization of UI Controls
- 嵌入式平台的UI控件 UI Controls on the Embedded Platform

## JavaFX 图表

- 饼图 Pie Chart
- 折线图 Line Chart
- 面积图 Area Chart
- 气泡图 Bubble Chart
- 散布图 Scatter Chart
- 柱状图 Bar Chart

## JavaFx 中使用CSS样式来管理外观

- 在UI控件上使用CSS
- 在图表中使用CSS

## JavaFX 应用中使用文本

- 使用文本
- 添加特效



# JavaFX 应用程序中的HTML内容

## WebView 组件概览

- 是Node 类的一个拓展

## 支持的HTML5特性

## 在程序中添加WebView 组件

## 处理JavaScript

## 完成JavaScript到JavaFX的调用

## 完成Web弹出式窗口

## 管理Web历史记录

## 打印HTML内容



# JavaFX 的布局

## 使用内置的布局面板

- 主要用到的类是 Pane类



### 边框面板 BorderPane

- 被划分为5个区域来放置界面元素: 上，下，左，右，中
- 每个区域的大小没有限制
- 如果不需要某个区域，只要不设置内容即可
- 该面板常用于定义一个经典的布局效果
  - 上方是菜单栏和工具栏
  - 下方是状态栏
  - 左边是导航面板
  - 右边是附加信息面板
  - 中间是核心工作区域
  - 当 BorderPane 所在窗口的大小比各区域内容所需空间大时，都出的空间会默认给中间区域
  - 当 BorderPane 所在窗口的大小比各区域内容所需空间大时, 各个区域会重叠

### 水平盒子 HBox

- 将多个节点排列在一行提供了一个简单的方法

### 垂直盒子 VBox

- 将多个节点排在一列

### 堆栈面板 StackPane

- 将所有的节点放在一个堆栈中进行布局管理
- 后添加进去的节点会显示在前一个添加进去的节点之上
- 该布局将文本，图像，图形相互覆盖来创建更复杂的图形

### 网络面板 GridPane

- 可以创建灵活的基于行和列的网格来放置节点
- 节点可以被放置到任意一个单元格中，也可以设置跨行跨列
- 对应创建表单之类的界面非常方便
- 当窗口大小变化时，网络面板中的节点会根据其自身的布局设置适应大小变化。

### 流面板(FlowPane)

- 包含的节点会连续地平铺放置，并且会在边界处自动换行换列

### 磁贴面板 TitlePane

- 跟 FlowPane 很相似

### 锚面板 AnchorPane

- 可以将节点锚定到面板的顶部，底部，左边，右边或中间位置。当窗体的大小变化时，节点会保持与其锚点之间的相对位置。
- 一个节点可以锚定到一个或者多个位置，并且多个节点可以被锚定到同一个位置。



```java
public class MainPane extends Application {

  @Override
  public void start(Stage primaryStage) throws Exception {
    BorderPane border = new BorderPane();
    HBox hbox = addHBox();
    border.setTop(hbox);
    border.setLeft(addVBox());
    addStackPane(hbox);

    //border.setCenter(addGridPane());
    border.setRight(addFlowPane());
    border.setCenter(addAnchorPane(addGridPane()));
  }

  private HBox addHBox() {
    HBox hbox = new HBox();
    // 节点到边缘的距离
    hbox.setPadding(new Insets(15, 12, 15, 12));
    // 节点之间的间距
    hbox.setSpacing(10);
    // 背景色
    hbox.setStyle("-fx-background-color:#336699");

    Button buttonCurrent = new Button("Current");
    buttonCurrent.setPrefSize(100, 20);

    Button buttonProjected = new Button();
    buttonProjected.setPrefSize(100, 20);
    hbox.getChildren().addAll(buttonCurrent, buttonProjected);
    return hbox;
  }

  private VBox addVBox() {
    VBox vBox = new VBox();
    // 内边距
    vBox.setPadding(new Insets(10));
    // 节点边距
    vBox.setSpacing(8);

    Text tile = new Text();
    tile.setFont(Font.font("Arial", FontWeight.BOLD, 14));
    vBox.getChildren().add(tile);

    Hyperlink[] options = new Hyperlink[] {
        new Hyperlink("Sales"),
        new Hyperlink("Marketing"),
        new Hyperlink("Distribution"),
        new Hyperlink("costs")
    };

    for (int i=0;i<4;i++) {
      // 为每个节点设置外边距
      VBox.setMargin(options[i], new Insets(0, 0, 0, 8));
      vBox.getChildren().add(options[i]);
    }
    return vBox;
  }

  private void addStackPane(HBox hBox) {
    StackPane stack = new StackPane();
    // 创建一个问号的icon
    Rectangle helpIcon = new Rectangle(30.0, 25.0);
    helpIcon.setFill(new LinearGradient(0,0,0,1, true, CycleMethod.NO_CYCLE,
            new Stop(0, Color.web("#4977A3")),
            new Stop(0.5, Color.web("#B0C6DA")),
            new Stop(1, Color.web("#9CB6CF"))
        ));
    helpIcon.setStroke(Color.web("#D0E6FA"));
    helpIcon.setArcHeight(3.5);
    helpIcon.setArcWidth(3.5);

    Text helpText = new Text("?");
    helpText.setFont(Font.font("Verdana", FontWeight.BOLD, 18));
    helpText.setFill(Color.WHITE);
    helpText.setStroke(Color.web("#7080A0"));

    stack.getChildren().addAll(helpIcon, helpText);
    // 右节点对齐
    stack.setAlignment(Pos.CENTER_RIGHT);

    // 设置问号居中显示
    StackPane.setMargin(helpText, new Insets(0, 10, 0, 0));
    // 将StackPane 添加到HBox中去
    hBox.getChildren().add(stack);
    // 将HBox水平多余的空间都给StackPane
    HBox.setHgrow(stack, Priority.ALWAYS);
  }

  private GridPane addGridPane() {
    GridPane grid = new GridPane();
    grid.setHgap(10);
    grid.setVgap(10);
    grid.setPadding(new Insets(0, 10, 0, 10));

    // 将category节点放在第1行,第2列
    Text category = new Text("Sales:");
    category.setFont(Font.font("Arial", FontWeight.BOLD, 20));
    grid.add(category, 1, 0);

    // 将chartTitle节点放在第1行,第3列
    Text chartTitle = new Text("Current Year");
    chartTitle.setFont(Font.font("Arial", FontWeight.BOLD, 20));
    grid.add(chartTitle, 2, 0);

    // 将chartSubtitle节点放在第2行,占第2和第3列
    Text chartSubtitle = new Text("Goods and Services");
    grid.add(chartSubtitle, 1, 1, 2, 1);

    // 将House图标放在第1列，占第1和第2行
    ImageView imageHouse = new ImageView(
        new Image(this.getClass().getResourceAsStream("house.png")));
    grid.add(imageHouse, 0, 0, 1, 2);

    // 将左边的标签goodsPercent放在第3行，第1列，靠下对齐
    Text goodsPercent = new Text("Goods\n80%");
    GridPane.setValignment(goodsPercent, VPos.BOTTOM);
    grid.add(goodsPercent, 0, 2);

    // 将饼图放在第3行，占第2和第3列
    ImageView imageChart = new ImageView(
        new Image(this.getClass().getResourceAsStream("graphics/piechart.png")));
    grid.add(imageChart, 1, 2, 2, 1);

    // 将右边的标签servicesPercent放在第3行，第4列，靠上对齐
    Text servicesPercent = new Text("Services\n20%");
    GridPane.setValignment(servicesPercent, VPos.TOP);
    grid.add(servicesPercent, 3, 2);

    return grid;
  }

  private FlowPane addFlowPane() {
    FlowPane flow = new FlowPane();
    flow.setPadding(new Insets(5, 0, 5, 0));
    flow.setVgap(4);
    flow.setHgap(4);
    flow.setPrefWrapLength(170); // 预设FlowPane的宽度，使其能够显示两列
    flow.setStyle("-fx-background-color: DAE6F3;");

    ImageView pages[] = new ImageView[8];
    for (int i=0; i<8; i++){
      pages[i] = new ImageView(
          new Image(this.getClass().getResourceAsStream(
              "graphics/chart_”+(i+1)+”.png")));
      flow.getChildren().add(pages[i]);
    }

    return flow;
  }

  private AnchorPane addAnchorPane(GridPane grid) {
    AnchorPane anchorpane = new AnchorPane();

    Button buttonSave = new Button("Save");
    Button buttonCancel = new Button("Cancel");

    HBox hb = new HBox();
    hb.setPadding(new Insets(0, 10, 10, 10));
    hb.setSpacing(10);
    hb.getChildren().addAll(buttonSave, buttonCancel);

    anchorpane.getChildren().addAll(grid,hb); //添加来自例1-5 的GridPane
    AnchorPane.setBottomAnchor(hb, 8.0);
    AnchorPane.setRightAnchor(hb, 5.0);
    AnchorPane.setTopAnchor(grid, 10.0);

    return anchorpane;
  }

  public static void main(String[] args) {
    launch(args);
  }
}

```



## 调整节点大小和对齐的技巧



## 使用CSS调整布局面板样式



# 事件

## 基本概念

- 是 javafx.event.Event 类或其子类的实例
- 可以通过继承 Event 类来实现自定义事件

### 事件属性

- 事件类型 Event type: 发生事件的类型
- 源 Source : 事件的来源，表示该事件在事件派发链中的位置。事件通过派发链传递时， "源"会随之发生改变
- 目标 Target: 发生动作的节点， 在事件派发链的末尾， 目标不会改变，但是如果某个事件过滤器在事件捕获阶段消费了该事件，目标 将不会收到该事件
- 事件子类提供了一些额外的 信息，通常与该事件的信息是相关的

### 事件类型

- 是EventType 类的实例
- 事件类型对单个事件类的多种事件进行了细化归类
- 事件类型是一个层级结构，每个事件类型都有一个名称和父类型，顶级事件类型的父类型是null

### 事件目标

- 一个事件的目标可以是任何实现了EventTarget 接口的类的实例
- BuildEventDispatchChain 方法的具体实现创建了事件派发链，事件必须经过派发链到达事件目标
- Window Scene 和 Node 类均实现了 EventTarget 接口。因此，在UI中的大多数元素都有它们已经定义好了的派发链。

### 事件分发流程

有以下几个步骤

#### 目标选择

- 当一个动作发生时， 系统根据内部规则决定哪一个Node是事件目标,规则如下
  - 对于键盘事件，事件目标是已获取焦点的Node
  - 对于鼠标事件，事件目标是光标所在位置处的Node；对于合成的(Synthesized)鼠标事件，触摸点被当做是光标所在位置。
  - 对于在触摸屏上产生的连续的手势事件，事件目标是手势开始时所有触碰位置的中心点的Node。对于在非触摸屏（例如触控板）上产生的间接手势，事件目标是光标所在位置的Node。
  - 对于由在触摸屏上划动而产生的划动(swipe)事件，事件目标在所有手指的全部路径的中心处的Node。对于间接划动事件，事件目标是光标所在位置处的Node。
  - 对于触摸事件，每个触摸点的默认事件目标是第一次按下时所在位置处的Node。在 Event Filter 或者 Event Handler 中可通过 ungrab(), grab() 或者 grab(Node) 方法来为触摸点指定不同的事件目标
  - 如果有多个Node位于光标或者触摸处，最上层的Node将被作为事件目标

#### 构造路径

- 初始的事件路径是由事件派发链决定的，派发链是在选中的事件目标的 buildEventDispatchChain 方法实现中创建的
- 当场景图中的一个节点被选中作为事件目标时，那么Node类的buildEventDispatchChain 方法的默认实现中设置的初始事件路径即使从Stage到其自身的一条路径
- 由于路径上的Event Filter 和 Event Handler 均会处理事件，因此路径可能会被修改。
- 如果 Event Filter 或者 Event Handler 在任何时间点消费掉了事件，则在初始路径上的一些节点可能不会收到该事件

#### 捕获事件

- 事件捕获阶段，事件被程序的根节点派发并通过事件派发链向下传递到目标节点
- 如果派发链中的任何节点为所发生的事件类型注册了Event Filter, 则该 Event Filter 将会被调用
- 当 Event filter 执行完成之后，对应的事件会向下传递到事件派发链中的下一个节点。如果该节点未注册过滤器，事件将被传递到事件派发链中的下一个节点
- 如果没有任何过滤器消费掉事件，则事件目标最终会接收到该事件并处理之。

#### 事件冒泡

- 当事件到达目标对象且所有已注册的过滤器都处理完事件以后，该事件将顺着派发链从目标节点返回到根节点
- 如果在事件派发链中有节点为特定类型的事件注册了Event Handler，则在对应类型的事件发生时对应的Event Handler 将会被调用。
- 当Event Handler 执行完成后，对应的事件将会向上传递给事件派发链中的上一个节点。
- 如果没有任何Handler消费掉事件，则根节点最终将接收到对应的事件并且完成处理过程。

#### 

### 事件处理

- 事件处理功能由 Event Filter 和 Event Handler 提供，两者均为EventHandler 接口的实现
- Event Filter 在事件捕获节点执行。
  - 父节点的事件过滤器可以为多个子节点提供公共的事件处理，
  - 如果有需要的话，也可以消费掉事件以阻止子节点收到该事件
  - 当某事件被传递并经过注册了EventFilter 的节点时，为该事件类型注册的 Event Filter 就会被执行
  - 一个节点可以注册多个Event Filter。
    - Event Filter 执行的顺序取决于事件类型的层级关系
    - 特定事件类型的 Event Filter 会优先于通用事件的过滤器执行
- Event Handler 在事件的冒泡阶段执行
  - 如果子节点的 Event Handler 未消耗掉对应的事件，那么父节点的Event Handler 就可以在子节点处理完成以后来处理该事件
  - 父节点的 Event Handler 还可以为多个子节点提供公共的事件处理过程
  - 当某事件返回并经过注册了 Event Handler 的节点时，为该事件类型注册的Event Handler 就会被执行。
  - 一个节点可以注册多个EventHandler, 特点同上

### 事件的消费

- 事件可以被 Event Filter 或 Event Handler 在事件派发链中的任意节点上通过调用 consume() 方法消耗掉
- 被消耗掉的事件在事件派发链上的遍历也就终止了
- 如果消费掉该事件的节点为该事件注册了多个 Event Filter 或者 Handler, 同级别的任然会执行



## 事件API的使用

### 键盘事件

- onKeyPressed
- onKeyReleased
- onKeyTyped

#### KeyEvent

- getCode() : 返回代表的键盘的值
- getCharacter() : 返回代表键盘的UNICODE值
- isAltDown(), isControlDown, isMetaDown, isShiftdown() 表示这些快捷键是否被按下



### 鼠标事件

- onMouseClicked
- onMouseDragEntered
- onMouseDragExited
- onMouseDragged
- onMouseDragOver
- onMouseDragReleased
- onMouseEntered
- onMouseExited
- onMouseMoved
- onMousePressed
- onMouseReleased

#### MouseEvent

- getX() getY() 获取鼠标指针的位置， 相对于当前Node的位置
- getSceneX() getSceneY() 获取相对于 场景图的 X,Y值
- getScreenX() getScreenY() 相对于当前 屏幕的  X,Y值
- isDragDetect() 如果正在发生拖拽，就返回 true
- getButton() isPrimaryButtonDown() isSecondaryButtonDown() isMiddleButtonDown() getClickCount() 



### 拖拽事件

- onDragDetected
- onDragDone
- onDragDropped
- onDragentered
- onDragExited
- onDragOver

### 触摸事件

- onTouchMoved
- onTouchPressed
- onTouchReleased
- onTouchStationary

### 手势事件

- onRotate
- onRotationFinished
- onRotationStarted
- onScroll
- onScrollStarted
- onScrollFinished
- onSwipeLeft
- onSwipeRight
- onSwipeUp
- onSwipeDown
- onZoom
- onZoomStarted
- onZoomFinished



# 动画

## 时间线

- 待补完 TODO

## 



# 整合媒体资源



# 场景图

## 基本概念

- 一个 scene graph(场景图) 是一个树状结构,常见于图形应用程序与一些库
- 场景图的个体称为 node
  - 有子节点的是 branch node
  - 没有子节点的是 leaf node
  - 第一个节点为 root node,它没有父节点
- Javafx.scene 包定义了十几个类，有三个类是最重要的
  - Node: 所有场景图节点的抽象基础类
  - Parent: 所有分支节点的抽象基础类
  - Scene: 场景图中所有内容的基本容器类



#  属性和绑定

## 基本概念

### Observable 接口

- 根接口

- 可以添加或移除监听器去接收 invalidation 事件 (事件是懒加载的)

### ObservableValue 接口

- 继承了 Observable
- 可以获取属性 getValue()
- 可以注册或移除监听器去监听 change 的事件

### WritableValue 接口

- 提供 get set 包装的 Value 的能力
- 所有实现了 WritableValue接口的类也实现了 ObservableValue

### ReadOnlyProperty 接口

- getBean() : 返回 包含本属性的对象，或者null
- getName(): 返回属性的名字, 没有的话就是空字符串

### Property 接口

- 继承了上述全部接口
- bind(ObservableValue): 创建单向的绑定
  - 绑定后， 调用 Property 的 set 等方法会抛异常， 调用 get 方法会获取 ObservableValue 的值 
- unbind()
- isBound() : 如果有一个 单向的绑定就是true
- bindBidirectional(Property<T> tProperty): 只有两种属性才可以双向绑定
- unbindBidirectional(Property<T>  )
- 同一个属性可以跟许多别的属性进行双向绑定, 但是只能有一个单向绑定，调用两遍 bind() 会替换。

### Binding 接口

- isValidd(): 验证绑定是有有效
- invalidate(): 将绑定关系置为无效
- getDependencies(): 获取 依赖列表
- dispose(): 表明 binding 不再使用并且其依赖资源可以被回收了
- 代表 unidirectional 的绑定关系
- Property 和 Bindings 接口并没有任何直接的实现，但是有许多方式可以创建其实现

```java
public class RectangleAreaExample {
  public static void main(String[] args) {
    System.out.println("Constructing x with initial value of 2.0.");
    final DoubleProperty x = new SimpleDoubleProperty(null, "x", 2.0);
    System.out.println("Constructing y with initial value of 3.0.");
    final DoubleProperty y = new SimpleDoubleProperty(null, "y", 3.0);
    System.out.println("Creating binding area with dependencies x and y.");
    DoubleBinding area = new DoubleBinding() {
      private double value;
      {
        super.bind(x, y);
      }
      @Override
      protected double computeValue() {
        System.out.println("computeValue() is called.");
        return x.get() * y.get();
      }
    };
    System.out.println("area.get() = " + area.get());
    System.out.println("area.get() = " + area.get());
    System.out.println("Setting x to 5");
    x.set(5);
    System.out.println("Setting y to 7");
    y.set(7);
    System.out.println("area.get() = " + area.get());
  }
}
```

## 经常使用的类

- 最常使用的就是 SimpleIntegerProperty 的一系列的类
- ReadOnlyIntegerWrapper 等一系列的类。
  - getReadOnlyProperty() 方法返回一个 ReadOnlyIntegerProperty ? TODO 不知道有啥用
- ReadOnlyIntegerPropertyBase 可以被继承（很少使用）
- WeakInvalidationListener 和 WeakChangeListener 类可以被用来包装 InvalidationListener 和 ChangeListener 实例
  - 对 listener 保持一个弱连接, 当不再指向 listener 的时候，listener会被垃圾回收，可以防止内存泄漏

### 创建 Bindings

- 继承 IntegerBinding 等一些列的抽象类
- 使用 Bindings 的静态方法去创建
- 使用 IntegerExpression 等系列类的流式API去创建

#### Bindings 工具类

- 有大量的工具方法
- add 系列方法: 会返回一个 NumberBinding ，其依赖为传入的参数,NumberBinding 的结果为 所有参数的和
- 类似的还有 subtract() multiply() 和 divide()

```java
public class TriangleAreaExample {
  /*
  * 计算公式为; Area = (x1*y2 + x2*y3 + x3*y1 – x1*y3 – x2*y1 – x3*y2) / 2
  * */
  public static void main(String[] args) {
    IntegerProperty x1 = new SimpleIntegerProperty(0);
    IntegerProperty y1 = new SimpleIntegerProperty(0);
    IntegerProperty x2 = new SimpleIntegerProperty(0);
    IntegerProperty y2 = new SimpleIntegerProperty(0);
    IntegerProperty x3 = new SimpleIntegerProperty(0);
    IntegerProperty y3 = new SimpleIntegerProperty(0);
    final NumberBinding x1y2 = Bindings.multiply(x1, y2);
    final NumberBinding x2y3 = Bindings.multiply(x2, y3);
    final NumberBinding x3y1 = Bindings.multiply(x3, y1);
    final NumberBinding x1y3 = Bindings.multiply(x1, y3);
    final NumberBinding x2y1 = Bindings.multiply(x2, y1);
    final NumberBinding x3y2 = Bindings.multiply(x3, y2);
    final NumberBinding sum1 = Bindings.add(x1y2, x2y3);
    final NumberBinding sum2 = Bindings.add(sum1, x3y1);
    final NumberBinding sum3 = Bindings.add(sum2, x3y1);
    final NumberBinding diff1 = Bindings.subtract(sum3, x1y3);
    final NumberBinding diff2 = Bindings.subtract(diff1, x2y1);
    final NumberBinding determinant = Bindings.subtract(diff2, x3y2);
    final NumberBinding area = Bindings.divide(determinant, 2.0D);
    x1.set(0); y1.set(0);
    x2.set(6); y2.set(0);
    x3.set(4); y3.set(3);
    printResult(x1, y1, x2, y2, x3, y3, area);
    x1.set(1); y1.set(0);
    x2.set(2); y2.set(2);
    x3.set(0); y3.set(1);
    printResult(x1, y1, x2, y2, x3, y3, area);
  }
  private static void printResult(IntegerProperty x1, IntegerProperty y1,
      IntegerProperty x2, IntegerProperty y2,
      IntegerProperty x3, IntegerProperty y3,
      NumberBinding area) {
    System.out.println("For A(" +
        x1.get() + "," + y1.get() + "), B(" +
        x2.get() + "," + y2.get() + "), C(" +
        x3.get() + "," + y3.get() + "), the area of triangle ABC is " + area.getValue());
  }
}
```

- 除了算式运算符，还有别的运算符
- 逻辑运算符: and or not
- 数字运算符: min max negate
- 对象运算符: isNull, isNotNull : 仅对 string 和 对象有用
- 字符串运算符: length, isEmpty, isNotEmpty : 仅对 string 有用
- 关系运算符: 
  - equal
  - equalIgnoreCase
  - greaterThan
  - ....
- 创建的操作符
  - createBooleanBinding
  - createIntegerBinding
  - ......
- 选择操作符: 仅适用于 JavaFX Beans
  - select
  - selectBoolean:
  - .....

#### 使用  Fluent Interface API

- API 可以在 Integerexpression ， IntegerProperty ,IntegerBinding, NumberExpression 中可以找到

##### 可用的API

- BooleanProperty 和 BooleanBindingBooleanBinding
  - and(ObservableBooleanValue b)
- BooleanBinding 
  - or(ObservableBooleanValue b)
- BooleanBinding 
  - not()
- BooleanBinding 
  - isEqualTo(ObservableBooleanValue b)
- BooleanBinding
  - isNotEqualTo(ObservableBooleanValue b)
- StringBinding
  - asString()

##### 可以被所有的 numeric properties 和 bindings

- BooleanBinding
  - isEqualTo(ObservableNumberValue m)
- BooleanBinding
  - isEqualTo(ObservableNumberValue m, double err)
- ....太多了， 不一一列举了

```java
public class TriangleAreaFluentExample {
  public static void main(String[] args) {
    IntegerProperty x1 = new SimpleIntegerProperty(0);
    IntegerProperty y1 = new SimpleIntegerProperty(0);
    IntegerProperty x2 = new SimpleIntegerProperty(0);
    IntegerProperty y2 = new SimpleIntegerProperty(0);
    IntegerProperty x3 = new SimpleIntegerProperty(0);
    IntegerProperty y3 = new SimpleIntegerProperty(0);
    final NumberBinding area = x1.multiply(y2)
        .add(x2.multiply(y3))
        .add(x3.multiply(y1))
        .subtract(x1.multiply(y3))
        .subtract(x2.multiply(y1))
        .subtract(x3.multiply(y2))
        .divide(2.0D);
    StringExpression output = Bindings.format(
        "For A(%d,%d), B(%d,%d), C(%d,%d), the area of triangle ABC is %3.1f",
        x1, y1, x2, y2, x3, y3, area);
    x1.set(0); y1.set(0);
    x2.set(6); y2.set(0);
    x3.set(4); y3.set(3);
    System.out.println(output.get());
    x1.set(1); y1.set(0);
    x2.set(2); y2.set(2);
    x3.set(0); y3.set(1);
    System.out.println(output.get());
  }
}
```

- 可以利用 when 方法族来进行以下类似的逻辑 

  - new When(b).then(x).otherwise(y)

  ```java
  public class HeronsFormulaExample {
    public static void main(String[] args) {
      DoubleProperty a = new SimpleDoubleProperty(0);
      DoubleProperty b = new SimpleDoubleProperty(0);
      DoubleProperty c = new SimpleDoubleProperty(0);
      DoubleBinding s = a.add(b).add(c).divide(2.0D);
  
      final DoubleBinding areaSquared = new When(
          // 当 a + b > c 的
          a.add(b).greaterThan(c)
              // 并且 b + c > a
              .and(b.add(c).greaterThan(a))
              // c + a > b
              .and(c.add(a).greaterThan(b)))
          // 三个条件都满足的时候,也就是满足为三角形的三边长的公式的时候
          // 执行这一连串的表达式
          .then(s.multiply(s.subtract(a))
              .multiply(s.subtract(b))
              .multiply(s.subtract(c)))
          // 否则输出0
          .otherwise(0.0D);
      a.set(3);
      b.set(4);
      c.set(5);
      System.out.printf("Given sides a = %1.0f, b = %1.0f, and c = %1.0f," +
              " the area of the triangle is %3.2f\n", a.get(), b.get(), c.get(),
          Math.sqrt(areaSquared.get()));
      a.set(2);
      b.set(2);
      c.set(2);
    }
  }
  ```

  ## 理解 JavaFX Beans

  ### JavaFx Bean 规范

  需要提供三个方法

  - getter, setter和 property getter

  #### Eagerly Instantiated Properties Strategy

  - Model

  ```java
  public class JavaFXBeanModelExample {
    private IntegerProperty i = new SimpleIntegerProperty(this, "i", 0);
    private StringProperty str = new SimpleStringProperty(this, "str", "Hello");
    private ObjectProperty<Color> color = new SimpleObjectProperty<>(this, "color",
        Color.BLACK);
    public final int getI() {
      return i.get();
    }
    public final void setI(int i) {
      this.i.set(i);
    }
    public IntegerProperty iProperty() {
      return i;
    }
    public final String getStr() {
      return str.get();
    }
    public final void setStr(String str) {
      this.str.set(str);
    }
    public StringProperty strProperty() {
      return str;
    }
    public final Color getColor() {
      return color.get();
    }
    public final void setColor(Color color) {
      this.color.set(color);
    }
    public ObjectProperty<Color> colorProperty() {
      return color;
    }
  }
  ```

  - View

  ```java
  public class JavaFXBeanViewExample {
    private JavaFXBeanModelExample model;
    public JavaFXBeanViewExample(JavaFXBeanModelExample model) {
      this.model = model;
      hookupChangeListeners();
    }
    // 给 model 的所有属性都添加监听器，当发生变化是，打印新旧值
    private void hookupChangeListeners() {
      model.iProperty().addListener(new ChangeListener<Number>() {
        @Override
        public void changed(ObservableValue<? extends Number> observableValue, Number oldValue, Number newValue) {
          System.out.println("Property i changed: old value = " + oldValue + ", new value = " + newValue);
        }
      });
      model.strProperty().addListener(new ChangeListener<String>() {
        @Override
        public void changed(ObservableValue<? extends String> observableValue, String oldValue, String newValue) {
          System.out.println("Property str changed: old value = " + oldValue + ", new value = " + newValue);
        }
      });
      model.colorProperty().addListener(new ChangeListener<Color>() {
        @Override
        public void changed(ObservableValue<? extends Color> observableValue, Color oldValue, Color newValue) {
          System.out.println("Property color changed: old value = " + oldValue + ", new value = " + newValue);
        }
      }); 
    }
  }
  ```

  - Controller

  ```java
  public class JavaFXBeanControllerExample {
    private JavaFXBeanModelExample model;
    private JavaFXBeanViewExample view;
    public JavaFXBeanControllerExample(JavaFXBeanModelExample model,
        JavaFXBeanViewExample view) {
      this.model = model;
      this.view = view;
    }
    // 此类忽略了对 view的操作
    // 以下方法均用来改变Model的值
    public void incrementIPropertyOnModel() {
  
      model.setI(model.getI() + 1);
    }
    public void changeStrPropertyOnModel() {
      final String str = model.getStr();
      if (str.equals("Hello")) {
        model.setStr("World");
      } else {
        model.setStr("Hello");
      }
    }
    public void switchColorPropertyOnModel() {
      final Color color = model.getColor();
      if (color.equals(Color.BLACK)) {
        model.setColor(Color.WHITE);
      } else {
        model.setColor(Color.BLACK);
      }
    }
  }
  ```





- 属性的命名格式

```java
class Bill {
 
    // Define a variable to store the property
    private DoubleProperty amountDue = new SimpleDoubleProperty();
 
    // Define a getter for the property's value
    public final double getAmountDue(){return amountDue.get();}
 
    // Define a setter for the property's value
    public final void setAmountDue(double value){amountDue.set(value);}
 
     // Define a getter for the property itself
    public DoubleProperty amountDueProperty() {return amountDue;}
 
}
```

#### Lazily Instantiated Properties Strategy

- 假如 Bean 里属性非常多，一次性初始化完是不太现实的, 这时会可以使用懒加载策略
  - 不理解使用懒加载的机制

#### Select Bindings

```java
public class SelectBindingExample {
  public static void main(String[] args) {
    ObjectProperty<Lighting> root = new SimpleObjectProperty<>(new Lighting());
    final ObjectBinding<Color> selectBinding = Bindings.select(root, "light", "color");
    selectBinding.addListener(new ChangeListener<Color>() {
      @Override
      public void changed(ObservableValue<? extends Color> observableValue, Color
          oldValue, Color newValue) {
        System.out.println("\tThe color changed:\n\t\told color = " +
            oldValue + ",\n\t\tnew color = " + newValue);
      } });

    System.out.println("firstLight is black.");
    Light firstLight = new Light.Point();
    firstLight.setColor(Color.BLACK);
    System.out.println("secondLight is white.");
    Light secondLight = new Light.Point();
    secondLight.setColor(Color.WHITE);
    System.out.println("firstLighting has firstLight.");
    Lighting firstLighting = new Lighting();
    firstLighting.setLight(firstLight);
    System.out.println("secondLighting has secondLight.");
    Lighting secondLighting = new Lighting();
    secondLighting.setLight(secondLight);
    System.out.println("Making root observe firstLighting.");
    root.set(firstLighting);
    System.out.println("Making root observe secondLighting.");
    root.set(secondLighting);
    System.out.println("Changing secondLighting's light to firstLight");
    secondLighting.setLight(firstLight);
    System.out.println("Changing firstLight's color to red");
    firstLight.setColor(Color.RED);
  }
}
```



## 用JavaBean 的Properties 去适配 JavaFX Properties

- javafx.beans.properties.adapter 包下提供了一些类去 帮助创建 JavaFX Properties

待补完... TODO



- 可以利用 javafx.beans.property 下的类来进行属性包装, 实现属性绑定

## 使用高级API

- Fluent API 类
- Binding 类

## 使用底层API

定义上述规范的对象



# JavaFX集合

- 由 javafx.collections 包定义，它由以下接口和类组成

- 接口

  - ObservableList: 一种可以使用监听器(Listener) 在发生改变时进行追踪的列表
  - ListChangeListener: 一种可以接收 ObservableList 的改变通知接口

  - ObservableMap: 一种可以使用观察者(Observer) 在发生改变时进行追踪改变的映射
  - MapChangeListener: 一种可以接收 ObservableMap 的改变通知的接口

- 类

  - FXCollections: 一个工具类,其中包含了一些静态方法, 跟 Collections 中的方法意义对应
  - ListChangeListener.Change: 代表ObservableList 中的改变
  - MapChangeListener.Change: 代表ObservalbeMap 中的改变

  ### ObservableList

```java
public class ObservableListExample {

  public static void main(String[] args) {
    ObservableList<String> strings = FXCollections.observableArrayList();
      // 不能添加重复的监听器
    strings.addListener((Observable observable) -> {
      System.out.println("\tlist invalidated");
    });
    strings.addListener((Change<? extends String> change) -> {
      System.out.println("\tstrings = " + change.getList());
    });
    System.out.println("Calling add(\"First\"): ");
    strings.add("First");
    System.out.println("Calling add(0, \"Zeroth\"): ");
    strings.add(0, "Zeroth");
    System.out.println("Calling addAll(\"Second\", \"Third\"): ");
    strings.addAll("Second", "Third");
    System.out.println("Calling set(1, \"New First\"): ");
    strings.set(1, "New First");
    final List<String> list = Arrays.asList("Second_1", "Second_2");
    System.out.println("Calling addAll(3, list): ");
    strings.addAll(3, list);
    System.out.println("Calling remove(2, 4): ");
    strings.remove(2, 4);
    final Iterator<String> iterator = strings.iterator();
    while (iterator.hasNext()) {
      final String next = iterator.next();
      if (next.contains("t")) {
        System.out.println("Calling remove() on iterator: ");
        iterator.remove();
      }
    }
    System.out.println("Calling removeAll(\"Third\", \"Fourth\"): ");
    strings.removeAll("Third", "Fourth");
  }

}
```

#### change

- 添加的时候
  - getFrom() 返回新添加的元素的下标
  - getTo() 返回 新添加元素前面那个元素的下标
  - getAddedSize() 返回新添加的元素的数量
  - getAddedSublist() 返回新添加的元素 list
- 删除的时候
  - getFrom(), getTo() 返回被删除的元素的下标
  - getRemovedSize() 返回被删除的元素的数量
  - getRemoved() 返回被删除的元素列表
- replace 的时候，可以视作是先添加再删除，下标是一致的
- 重排序的时候
  - getPermutation(int i)  不懂是干什么的
  - getList() 返回原来的列表

```java
public class ListChangeEventExample {
  public static void main(String[] args) {
    ObservableList<String> strings = FXCollections.observableArrayList();
    strings.addListener(new MyListener());
    System.out.println("Calling addAll(\"Zero\", \"One\", \"Two\", \"Three\"): ");
    strings.addAll("Zero", "One", "Two", "Three");
    System.out.println("Calling FXCollections.sort(strings): ");
    FXCollections.sort(strings);
    System.out.println("Calling set(1, \"Three_1\"): ");
    strings.set(1, "Three_1");
    System.out.println("Calling setAll(\"One_1\", \"Three_1\", \"Two_1\", \"Zero_1\"): ");
    strings.setAll("One_1", "Three_1", "Two_1", "Zero_1");
    System.out.println("Calling removeAll(\"One_1\", \"Two_1\", \"Zero_1\"): ");
    strings.removeAll("One_1", "Two_1", "Zero_1");
  }

  private static class MyListener implements ListChangeListener<String> {

    @Override
    public void onChanged(Change<? extends String> change) {
      System.out.println("\tlist = " + change.getList());
      System.out.println(prettyPrint(change));
    }

    private String prettyPrint(Change<? extends String> change) {
      StringBuilder sb = new StringBuilder("\tChange event data:\n");
      int i = 0;
      while (change.next()) {
        sb.append("\t\tcursor = ")
            .append(i++)
            .append("\n");
        final String kind =
            change.wasPermutated() ? "permutated" :
                change.wasReplaced() ? "replaced" :
                    change.wasRemoved() ? "removed" :
                        change.wasAdded() ? "added" : "none";
        sb.append("\t\tKind of change: ")
            .append(kind)
            .append("\n");
        sb.append("\t\tAffected range: [")
            .append(change.getFrom())
            .append(", ")
            .append(change.getTo())
            .append("]\n");
        if (kind.equals("added") || kind.equals("replaced")) {
          sb.append("\t\tAdded size: ")
              .append(change.getAddedSize())
              .append("\n");
          sb.append("\t\tAdded sublist: ")
              .append(change.getAddedSubList())
              .append("\n");
        }
        if (kind.equals("removed") || kind.equals("replaced")) {
          sb.append("\t\tRemoved size: ")
              .append(change.getRemovedSize())
              .append("\n");
          sb.append("\t\tRemoved: ")
              .append(change.getRemoved())
              .append("\n");
        }
        if (kind.equals("permutated")) {
          StringBuilder permutationStringBuilder = new StringBuilder("[");
          for (int k = change.getFrom(); k < change.getTo(); k++) {
            permutationStringBuilder.append(k)
                .append("->")
                .append(change.getPermutation(k));
            if (k < change.getTo() - 1) {
              permutationStringBuilder.append(", ");
            }

          }
          permutationStringBuilder.append("]");
          String permutation = permutationStringBuilder.toString();
          sb.append("\t\tPermutation: ").append(permutation).append("\n");
        } }
      return sb.toString();
    }
  }
}
```

### ObservableMap

```java
public class MapChangeEventExample {
  public static void main(String[] args) {
    ObservableMap<String, Integer> map = FXCollections.observableHashMap();
    map.addListener(new MyListener());
    System.out.println("Calling put(\"First\", 1): ");
    map.put("First", 1);
    System.out.println("Calling put(\"First\", 100): ");
    map.put("First", 100);
    Map<String, Integer> anotherMap = new HashMap<>();
    anotherMap.put("Second", 2);
    anotherMap.put("Third", 3);
    System.out.println("Calling putAll(anotherMap): ");
    map.putAll(anotherMap);
    final Iterator<Entry<String, Integer>> entryIterator = map.entrySet().
        iterator();
    while (entryIterator.hasNext()) {
      final Map.Entry<String, Integer> next = entryIterator.next();
      if (next.getKey().equals("Second")) {
        System.out.println("Calling remove on entryIterator: ");
        entryIterator.remove();
      }
    }
    final Iterator<Integer> valueIterator = map.values().iterator();
    while (valueIterator.hasNext()) {
      final Integer next = valueIterator.next();
      if (next == 3) {
        System.out.println("Calling remove on valueIterator: ");
        valueIterator.remove();
      }
    } }

  private static class MyListener implements MapChangeListener<String, Integer> {
    @Override
    public void onChanged(Change<? extends String, ? extends Integer> change) {
      System.out.println("\tmap = " + change.getMap());
      System.out.println(prettyPrint(change));
    }
    private String prettyPrint(Change<? extends String, ? extends Integer> change) {
      StringBuilder sb = new StringBuilder("\tChange event data:\n");
      sb.append("\t\tWas added: ").append(change.wasAdded()).append("\n");
      sb.append("\t\tWas removed: ").append(change.wasRemoved()).append("\n");
      sb.append("\t\tKey: ").append(change.getKey()).append("\n");
      sb.append("\t\tValue added: ").append(change.getValueAdded()).append("\n");
      sb.append("\t\tValue removed: ").append(change.getValueRemoved()).append("\n");
      return sb.toString();
    } }
}
```



### ObservableSet

```java
public class SetChangeEventExample {
  public static void main(String[] args) {
    ObservableSet<String> set = FXCollections.observableSet();
    set.addListener(new MyListener());
    System.out.println("Calling add(\"First\"): ");
    set.add("First");
    System.out.println("Calling addAll(Arrays.asList(\"Second\", \"Third\")): ");
    set.addAll(Arrays.asList("Second", "Third"));
    System.out.println("Calling remove(\"Third\"): ");
    set.remove("Third");
  }
  private static class MyListener implements SetChangeListener<String> {
    @Override
    public void onChanged(Change<? extends String> change) {
      System.out.println("\tset = " + change.getSet());
      System.out.println(prettyPrint(change));
    }
    private String prettyPrint(Change<? extends String> change) {
      StringBuilder sb = new StringBuilder("\tChange event data:\n");
      sb.append("\t\tWas added: ").append(change.wasAdded()).append("\n");
      sb.append("\t\tWas removed: ").append(change.wasRemoved()).append("\n");
      sb.append("\t\tElement added: ").append(change.getElementAdded()).append("\n");
      sb.append("\t\tElement removed: ").append(change.getElementRemoved()).
          append("\n");
      return sb.toString();
    }
  }
}
```

### ObservableArrays

```java
public class ArrayChangeEventExample {
  public static void main(String[] args) {
    final ObservableIntegerArray ints = FXCollections.observableIntegerArray(10, 20);
    ints.addListener((array, sizeChanged, from, to) -> {
      StringBuilder sb = new StringBuilder("\tObservable Array = ").append(array).
          append("\n")
          .append("\t\tsizeChanged = ").append(sizeChanged).append("\n")
          .append("\t\tfrom = ").append(from).append("\n")
          .append("\t\tto = ").append(to).append("\n");
      System.out.println(sb.toString());
    });
    ints.ensureCapacity(20);
    System.out.println("Calling addAll(30, 40):");
    ints.addAll(30, 40);
    final int[] src = {50, 60, 70};
    System.out.println("Calling addAll(src, 1, 2):");
    ints.addAll(src, 1, 2);
    System.out.println("Calling set(0, src, 0, 1):");
    ints.set(0, src, 0, 1);
    System.out.println("Calling setAll(src):");
    ints.setAll(src);
    ints.trimToSize();
    final ObservableIntegerArray ints2 = FXCollections.observableIntegerArray();
    ints2.resize(ints.size());
    System.out.println("Calling copyTo(0, ints2, 0, ints.size()):");
    ints.copyTo(0, ints2, 0, ints.size());
    System.out.println("\tDestination = " + ints2);
  }
}
```

### 使用 FXCollections 中的工具工厂方法

- 有一大堆工厂方法

```java
public class FXCollectionsExample {
  public static void main(String[] args) {
    ObservableList<String> strings = FXCollections.observableArrayList();
    strings.addListener(new MyListener());
    System.out.println("Calling addAll(\"Zero\", \"One\", \"Two\", \"Three\"): ");
    strings.addAll("Zero", "One", "Two", "Three");
    System.out.println("Calling copy: ");
    FXCollections.copy(strings, Arrays.asList("Four", "Five"));
    System.out.println("Calling replaceAll: ");
    FXCollections.replaceAll(strings, "Two", "Two_1");
    System.out.println("Calling reverse: ");
    FXCollections.reverse(strings);
    System.out.println("Calling rotate(strings, 2): ");
    FXCollections.rotate(strings, 2);
    System.out.println("Calling shuffle(strings): ");
    FXCollections.shuffle(strings);
    System.out.println("Calling shuffle(strings, new Random(0L)): ");
    FXCollections.shuffle(strings, new Random(0L));
    System.out.println("Calling sort(strings): ");
    FXCollections.sort(strings);
    System.out.println("Calling sort(strings, c) with custom comparator: ");
    FXCollections.sort(strings, new Comparator<String>() {
      @Override
      public int compare(String lhs, String rhs) {
        // Reverse the order
        return rhs.compareTo(lhs);
      }
    });
    System.out.println("Calling fill(strings, \"Ten\"): ");
    FXCollections.fill(strings, "Ten");
  }

  private static class MyListener implements ListChangeListener<String> {

    @Override
    public void onChanged(Change<? extends String> change) {
      System.out.println("\tlist = " + change.getList());
      System.out.println(prettyPrint(change));
    }

    private String prettyPrint(Change<? extends String> change) {
      StringBuilder sb = new StringBuilder("\tChange event data:\n");
      int i = 0;
      while (change.next()) {
        sb.append("\t\tcursor = ")
            .append(i++)
            .append("\n");
        final String kind =
            change.wasPermutated() ? "permutated" :
                change.wasReplaced() ? "replaced" :
                    change.wasRemoved() ? "removed" :
                        change.wasAdded() ? "added" : "none";
        sb.append("\t\tKind of change: ")
            .append(kind)
            .append("\n");
        sb.append("\t\tAffected range: [")
            .append(change.getFrom())
            .append(", ")
            .append(change.getTo())
            .append("]\n");
        if (kind.equals("added") || kind.equals("replaced")) {
          sb.append("\t\tAdded size: ")
              .append(change.getAddedSize())
              .append("\n");
          sb.append("\t\tAdded sublist: ")
              .append(change.getAddedSubList())
              .append("\n");
        }
        if (kind.equals("removed") || kind.equals("replaced")) {
          sb.append("\t\tRemoved size: ")
              .append(change.getRemovedSize())
              .append("\n");
          sb.append("\t\tRemoved: ")
              .append(change.getRemoved())
              .append("\n");
        }
        if (kind.equals("permutated")) {
          StringBuilder permutationStringBuilder = new StringBuilder("[");
          for (int k = change.getFrom(); k < change.getTo(); k++) {
            permutationStringBuilder.append(k)
                .append("->")
                .append(change.getPermutation(k));
            if (k < change.getTo() - 1) {
              permutationStringBuilder.append(", ");
            }

          }
          permutationStringBuilder.append("]");
          String permutation = permutationStringBuilder.toString();
          sb.append("\t\tPermutation: ").append(permutation).append("\n");
        } }
      return sb.toString();
    }
  }
}

```



# JavaFX 并发

- 可以利用 javafx.concurrent 包提供的功能来创建多线程的应用环境, 在后台委托耗时的任务执行，来保持UI是可响应的

## 概况

- 场景图不是线程安全的，而且仅可以通过UI线程亦被称为JavaFX应用程序线程访问和修改。所以不能再javaFX线程中处理耗时任务
- 通常实现一个或多个后台线程处理这些任务，仅让JavaFX 应用程序来处理用户事件
- 主要的工具都在 javafx.concurrent 包下
  - 主要由Worker 接口和两个具体的实现Task 和 Service类组成
  - Worker 接口提供了对后台工作与UI之间通信有用的API
  - Task类是 java.util.concurrent.FutureTask 类的一个完整的可观察的实现。Task类使开发者可以在JavaFX应用程序中实现异步任务，Service类执行这些任务
  - WorkerStateEvent 类指定了一个工作实现状态发生变化的事件。Task和Service类都实现了EventTarget 接口，因此可以支持监听这个状态事件

## Worker 接口

- 接口定义了一个执行一个或多个后台线程工作的对象， Worker 对象的状态在JavaFX应用程序线程中是可观察且可用的。
- Worker 对象的生命周期
  - 创建时 READY
  - 开始计划工作时, SCHEDULED
  - 执行工作时 RUNNING
  - 任何异常被抛出时 FAILED, exception属性被设置为产出的异常
  - Worker对象结束前的任何时候，都可以调用cancel 方法终止，此时状态将变为 CANCELLED
- Worker对象的的工作完成过程可以通过三种不同的属性获取: totalWork, workDone 和 progress

### Worker.State 的状态

- READY (initial state)
- SCHEDULED (transitional state)
- RUNNING (transitional state)
- SUCCEEDED (terminal state)
- CANCELLED (terminal state)
- FAILED (terminal state)

### 九个只读属性 和 一个方法

- title String : task 的名字
- message String: work 进度的 消息
- running boolean: 当 woker 是 Worker.State.SCHEDULED 或者 Worker.State.RUNNING 的时候为 true
- state Object : 代表 worker的状态
- totalWork double: 代表 worker 工作的总数量
- workDone double: worker完成的工作数量
- progress double: 完成的工作的百分比
- value Object: 当状态为 Worker.State.SUCCEEDED 的时候表示工作完成的结果
- exeception Object : 状态为 Worker.State.FAILED 时候代表抛出的异常。
- cancel() : 把状态改为 CANCELLED 状态, 假如不是 FAILED 或 SUCCEEDED

## Task类 (Worker 的实现抽象类)

- 用来实现需要在后台完成的工作的逻辑。
- 继承Wroker类，重写其 call 方法来处理后台工作和返回结果
- call方法在后台进程中被调用，因此该方法只能操作后台线程读写安全的状态
- Task类是被设计用来和GUI程序一起使用的，它能确保公有属性，错误或取消的变更通知，事件处理器和状态的修改在JavaFX 应用程序线程执行
- call方法内部，可以使用 updateProgress, updateMessage, updateTitle等方法，这些方法可以在JavaFX应用程序线程更新对应属性的值

### WorkerStateEvent: 

- Task 也实现了 EventTarget 接口，其中提供了回调属性，在状态改变时会相应的调用
- onScheudled property
- onRunning property
- onSucceeded property
- onCancelled property
- OnFailed property
- protected void scheduled()
- protected void running()
- protected void succeeded()
- protected void cancelled()
- protected void failed()

```java
public class WorkerAndTaskExample extends Application {
  private Model model;
  private View view;
  public static void main(String[] args) {
    launch(args);
  }
  public WorkerAndTaskExample() {
    model = new Model();
  }
  @Override
  public void start(Stage stage) throws Exception {
    view = new View(model);
    hookupEvents();
    stage.setTitle("Worker and Task Example");
    stage.setScene(view.scene);
    stage.show();
  }

  private void hookupEvents() {
    // 点击 start 按钮的时候 开启一个新线程开始 worker
    view.startButton.setOnAction(actionEvent -> {
      // 开启一个新任务
      new Thread((Runnable) model.worker).start();
    });
    // 取消 worker
    view.cancelButton.setOnAction(actionEvent -> {
      model.worker.cancel();
    });
    // 抛出异常
    view.exceptionButton.setOnAction(actionEvent -> {
      model.shouldThrow.getAndSet(true);
    });
  }

  // 模型类
  private static class Model {
    public Worker<String> worker;
    public AtomicBoolean shouldThrow = new AtomicBoolean(false);

    private Model() {
      // 定义工作类
      worker = new Task<String>() {
        @Override
        protected String call() throws Exception {
          // 先绑定 View 中的类，之后就可以调用方法去更新了
          updateTitle("Example Task");
          updateMessage("Starting...");
          // 定义工作的总量
          final int total = 250;
          updateProgress(0, total);
          for (int i = 1; i <= total; i++) {
            // 假如取消了就返回
            if (isCancelled()) {
              updateValue("Canceled at " + System.currentTimeMillis());
              return null; // ignored
            }
            try {
              Thread.sleep(20);
            } catch (InterruptedException e) {
              updateValue("Canceled at " + System.currentTimeMillis());
              return null; // ignored
            }
            // 假如按下了抛出异常按钮
            if (shouldThrow.get()) {
              throw new RuntimeException("Exception thrown at " + System.currentTimeMillis());
            }
            // 汇报工作进度
            updateTitle("Example Task (" + i + ")");
            updateMessage("Processed " + i + " of " + total + " items.");
            updateProgress(i, total);

          }
            return "Completed at " + System.currentTimeMillis();
        }

        @Override
        protected void scheduled() {
          System.out.println("The task is scheduled.");
        }
        @Override
        protected void running() {
          System.out.println("The task is running.");
        }
      };

      Task<String> task = (Task<String>)worker;
      // 设置各种状态回调函数
      task.setOnSucceeded(event -> {
        System.out.println("The task succeeded.");
      });
      task.setOnCancelled(event -> {
        System.out.println("The task is canceled.");
      });
      task.setOnFailed(event -> {
        System.out.println("The task failed.");
      });
    }
  }

  // 视图类
  private static class View {
    // 进度条
    public ProgressBar progressBar;
    public Label title;
    public Label message;
    public Label running;
    public Label state;
    public Label totalWork;
    public Label workDone;
    public Label progress;
    public Label value;
    public Label exception;
    public Button startButton;
    public Button cancelButton;
    public Button exceptionButton;
    public Scene scene;
    private View(final Model model) {
      progressBar = new ProgressBar();
      progressBar.setMinWidth(250);
      title = new Label();
      message = new Label();
      running = new Label();
      state = new Label();
      totalWork = new Label();
      workDone = new Label();
      progress = new Label();
      value = new Label();
      exception = new Label();
      startButton = new Button("Start");
      cancelButton = new Button("Cancel");
      exceptionButton = new Button("Exception");
      final ReadOnlyObjectProperty<Worker.State> stateProperty =
          model.worker.stateProperty();
      progressBar.progressProperty().bind(model.worker.progressProperty());
      title.textProperty().bind(
          model.worker.titleProperty());
      message.textProperty().bind(
          model.worker.messageProperty());
      running.textProperty().bind(
          Bindings.format("%s", model.worker.runningProperty()));
      state.textProperty().bind(
          Bindings.format("%s", stateProperty));
      totalWork.textProperty().bind(
          model.worker.totalWorkProperty().asString());
      workDone.textProperty().bind(
          model.worker.workDoneProperty().asString());
      progress.textProperty().bind(
          Bindings.format("%5.2f%%", model.worker.progressProperty().multiply(100)));
      value.textProperty().bind(
          model.worker.valueProperty());
      exception.textProperty().bind(Bindings.createStringBinding(() -> {
        final Throwable exception = model.worker.getException();
        if (exception == null) return "";
        return exception.getMessage();
      }, model.worker.exceptionProperty()));
      startButton.disableProperty().bind(
          stateProperty.isNotEqualTo(Worker.State.READY));
      cancelButton.disableProperty().bind(
          stateProperty.isNotEqualTo(Worker.State.RUNNING));
      exceptionButton.disableProperty().bind(
          stateProperty.isNotEqualTo(Worker.State.RUNNING));
      HBox topPane = new HBox(10, progressBar);
      topPane.setAlignment(Pos.CENTER);
      topPane.setPadding(new Insets(10, 10, 10, 10));
      ColumnConstraints constraints1 = new ColumnConstraints();
      constraints1.setHalignment(HPos.CENTER);
      constraints1.setMinWidth(65);
      ColumnConstraints constraints2 = new ColumnConstraints();
      constraints2.setHalignment(HPos.LEFT);
      constraints2.setMinWidth(200);
      GridPane centerPane = new GridPane();
      centerPane.setHgap(10);
      centerPane.setVgap(10);
      centerPane.setPadding(new Insets(10, 10, 10, 10));
      centerPane.getColumnConstraints()
          .addAll(constraints1, constraints2);
      centerPane.add(new Label("Title:"), 0, 0);
      centerPane.add(new Label("Message:"), 0, 1);
      centerPane.add(new Label("Running:"), 0, 2);
      centerPane.add(new Label("State:"), 0, 3);
      centerPane.add(new Label("Total Work:"), 0, 4);
      centerPane.add(new Label("Work Done:"), 0, 5);
      centerPane.add(new Label("Progress:"), 0, 6);
      centerPane.add(new Label("Value:"), 0, 7);
      centerPane.add(new Label("Exception:"), 0, 8);
      centerPane.add(title, 1, 0);
      centerPane.add(message, 1, 1);
      centerPane.add(running, 1, 2);
      centerPane.add(state, 1, 3);
      centerPane.add(totalWork, 1, 4);
      centerPane.add(workDone, 1, 5);
      centerPane.add(progress, 1, 6);
      centerPane.add(value, 1, 7);
      centerPane.add(exception, 1, 8);
      HBox buttonPane = new HBox(10,
          startButton, cancelButton, exceptionButton);
      buttonPane.setPadding(new Insets(10, 10, 10, 10));
      buttonPane.setAlignment(Pos.CENTER);
      BorderPane root = new BorderPane(centerPane,
          topPane, null, buttonPane, null);
      scene = new Scene(root);
    }
  }
}
```



##  Service

- Service类是设计来在一个或多个后台线程上执行一个Task对象。
- Service类的方法和状态只可以由JavaFX 应用程序线程访问。
- 此类的目的是为了帮助实现后台线程与JavaFX 应用程序之间的正确交互
- 可以按需启动，取消和重启Service。使用 Service.start() 方法来启动Service对象

- 是 Worker 接口的实现, 也有九大属性和 EventTarget 的状态变化和监听

- 方法

  - Task<V> createTask() : 
  - start(): 
    - 只能在 Service是Worker.State.READY 状态调用
    - 会调用 createTask 方法获取 新的Task,
    - 会从 executor 属性中获取 Executor, 如果没有，会自己创建一个
    - 会将 Task 的状态变为 Worker.State.SCHEDULED
    - 最后通过 Executor 来调用 Task
  - reset() ： Service状态不是 SCEDULED 或 RUNNING 才能调用, 将状态变为 READY
  - restart(): 取消当前进行的任务， 然后调用 restart() 和 start()
  - cancel(): 取消当前任务，并将 Service 的状态转为 CANCELLED

  ```java
  public class ServiceExample extends Application {
  
    private Model model;
    private View view;
  
    public static void main(String[] args) {
      launch(args);
    }
  
    public ServiceExample() {
      model = new Model();
    }
  
    @Override
    public void start(Stage stage) throws Exception {
      view = new View(model);
      hookupEvents();
      stage.setTitle("Service Example");
      stage.setScene(view.scene);
      stage.show();
    }
  
    private void hookupEvents() {
      view.startButton.setOnAction(actionEvent -> {
        model.shouldThrow.getAndSet(false);
        // 可以重复开始
        ((Service) model.worker).restart();
      });
      view.cancelButton.setOnAction(actionEvent -> {
        model.worker.cancel();
      });
      view.exceptionButton.setOnAction(actionEvent -> {
        model.shouldThrow.getAndSet(true);
      });
    }
  
    private static class Model {
      // 用 Service 去实现
      public Worker<String> worker;
      public AtomicBoolean shouldThrow = new AtomicBoolean(false);
      // 自己设定的任务数
      public IntegerProperty numberOfItems = new SimpleIntegerProperty(250);
  
      private Model() {
        worker = new Service<String>() {
          @Override
          protected Task createTask() {
            return new Task<String>() {
              @Override
              protected String call() throws Exception {
                updateTitle("Example Service");
                updateMessage("Starting...");
                final int total = numberOfItems.get();
                updateProgress(0, total);
                for (int i = 1; i <= total; i++) {
                  if (isCancelled()) {
                    updateValue("Canceled at " + System.currentTimeMillis());
                    return null; // ignored
                  }
                  try {
                    Thread.sleep(20);
                  } catch (InterruptedException e) {
                    if (isCancelled()) {
                      updateValue("Canceled at " + System.currentTimeMillis());
                      return null; // ignored
                    }
                  }
                  if (shouldThrow.get()) {
                    throw new RuntimeException("Exception thrown at " +
                        System.currentTimeMillis());
                  }
                  updateTitle("Example Service (" + i + ")");
                  updateMessage("Processed " + i + " of " + total + " items.");
                  updateProgress(i, total);
                }
                return "Completed at " + System.currentTimeMillis();
              }
            };
          }
        };
      }
    }
  
    private static class View {
  
      public ProgressBar progressBar;
      public Label title;
      public Label message;
      public Label running;
      public Label state;
      public Label totalWork;
      public Label workDone;
      public Label progress;
      public Label value;
      public Label exception;
      public TextField numberOfItems;
      public Button startButton;
      public Button cancelButton;
      public Button exceptionButton;
      public Scene scene;
  
      private View(final Model model) {
        progressBar = new ProgressBar();
        progressBar.setMinWidth(250);
        title = new Label();
        message = new Label();
        running = new Label();
        state = new Label();
        totalWork = new Label();
        workDone = new Label();
        progress = new Label();
        value = new Label();
        exception = new Label();
        numberOfItems = new TextField();
        numberOfItems.setMaxWidth(40);
        startButton = new Button("Start");
        cancelButton = new Button("Cancel");
        exceptionButton = new Button("Exception");
        final ReadOnlyObjectProperty<State> stateProperty =
            model.worker.stateProperty();
        progressBar.progressProperty().bind(model.worker.progressProperty());
        title.textProperty().bind(
            model.worker.titleProperty());
        message.textProperty().bind(
            model.worker.messageProperty());
        running.textProperty().bind(
            Bindings.format("%s", model.worker.runningProperty()));
        state.textProperty().bind(
            Bindings.format("%s", stateProperty));
        totalWork.textProperty().bind(
            model.worker.totalWorkProperty().asString());
        workDone.textProperty().bind(
            model.worker.workDoneProperty().asString());
        progress.textProperty().bind(
            Bindings.format("%5.2f%%", model.worker.progressProperty().multiply(100)));
        value.textProperty().bind(
            model.worker.valueProperty());
        exception.textProperty().bind(Bindings.createStringBinding(() -> {
          final Throwable exception = model.worker.getException();
          if (exception == null) {
            return "";
          }
          return exception.getMessage();
        }, model.worker.exceptionProperty()));
        model.numberOfItems.bind(Bindings.createIntegerBinding(() -> {
          final String text = numberOfItems.getText();
          int n = 250;
          try {
            n = Integer.parseInt(text);
          } catch (NumberFormatException e) {
          }
          return n;
        }, numberOfItems.textProperty()));
        startButton.disableProperty().bind(
            stateProperty.isEqualTo(Worker.State.RUNNING));
        cancelButton.disableProperty().bind(
            stateProperty.isNotEqualTo(Worker.State.RUNNING));
        exceptionButton.disableProperty().bind(
            stateProperty.isNotEqualTo(Worker.State.RUNNING));
        HBox topPane = new HBox(10, progressBar);
        topPane.setPadding(new Insets(10, 10, 10, 10));
        topPane.setAlignment(Pos.CENTER);
        ColumnConstraints constraints1 = new ColumnConstraints();
        constraints1.setHalignment(HPos.RIGHT);
        constraints1.setMinWidth(65);
        ColumnConstraints constraints2 = new ColumnConstraints();
        constraints2.setHalignment(HPos.LEFT);
        constraints2.setMinWidth(200);
        GridPane centerPane = new GridPane();
        centerPane.setHgap(10);
        centerPane.setVgap(10);
        centerPane.setPadding(new Insets(10, 10, 10, 10));
        centerPane.getColumnConstraints().addAll(constraints1, constraints2);
        centerPane.add(new Label("Title:"), 0, 0);
        centerPane.add(new Label("Message:"), 0, 1);
        centerPane.add(new Label("Running:"), 0, 2);
        centerPane.add(new Label("State:"), 0, 3);
        centerPane.add(new Label("Total Work:"), 0, 4);
        centerPane.add(new Label("Work Done:"), 0, 5);
        centerPane.add(new Label("Progress:"), 0, 6);
        centerPane.add(new Label("Value:"), 0, 7);
        centerPane.add(new Label("Exception:"), 0, 8);
        centerPane.add(title, 1, 0);
        centerPane.add(message, 1, 1);
        centerPane.add(running, 1, 2);
        centerPane.add(state, 1, 3);
        centerPane.add(totalWork, 1, 4);
        centerPane.add(workDone, 1, 5);
        centerPane.add(progress, 1, 6);
        centerPane.add(value, 1, 7);
        centerPane.add(exception, 1, 8);
        HBox buttonPane = new HBox(10,
            new Label("Process"), numberOfItems, new Label("items"),
            startButton, cancelButton, exceptionButton);
        buttonPane.setPadding(new Insets(10, 10, 10, 10));
        buttonPane.setAlignment(Pos.CENTER);
        BorderPane root = new BorderPane(centerPane, topPane, null, buttonPane, null);
        scene = new Scene(root);
      }
    }
  
  }
  
  ```

  

  ## ScheduledService

  - 继承了 Service 类，其设计目的在于能够定时的执行某些任务
  - 有以下属性
    - delay : 调用 start() 之后多长时间让 task 去 run
    - period: task 的执行间隔
    - backOffStrategy : 失败的时候需要返回一个值去计算重新开始之前需要的时间, 有几个提供值
    - restartOnFailure: 假如任务在执行的时候失败了， false 的话就啥也不做， true的话就会重启
    - maximumFailureCount: 最大失败次数
    - currentFailureCount: 目前为止失败的次数
    - cmulativePeriod: backOffStrategy 的返回值
    - maximumCumulativePeriod: 最大的失败重启等待时间
    - lastValue

  



## Application 的生命周期钩子

- init() : 
- start(Stage stage)
- stop()

## Platform 类

- runLater(Runnable ..) : 在未来某个不确定的时间里 在 JavaFX Application 线程里执行该任务
- isFxApplicationThread() : 确认调用者是否在 JavaFX Application 线程里
- isSupported(ConditionalFeature): 测试执行环境是否支持某些功能
- exit(): 让 JavaFX 退出
- isImplicitExit()  setImplicitExit(boolean) 这个 flag 是 true 的时候，窗口被关掉的时候才退出,不然就等显式调用 exit(), 默认是 true 

