# 基本概念

## Module

使用 NgModel 标注的 class 为模块

- 模块通常会包含多个组件，用来共同完成一组功能

### Decalarations:

- 定义本模块使用到的组件, 指令 ，管道等

### exports 

- 能在其它模块的组件模板中使用的可声明对象的子集
- 根模块一般没有理由导出其它模块

### imports

- 定义需要导入的模块, 也就是本模块的依赖项

### providers

- 提供的 service 构建器。这些 service 可以在本模块的任何组件或子模块中使用

### boostrap

- 应用的主视图。是应用中所有其它视图的宿主。只有根模块才应该设置这个属性



## Component

略

## Directives

- 可以用来增强已存在元素的功能

## Pipes

- 主要用来格式化输出

## Services

- 通常用来封装可复用，函数式，与渲染无关的逻辑
- 比如获取数据

## 

## Angular 的渲染过程

略

## DI

### injector

- 提供依赖和注册依赖

### provider

- 负责创建对象的实例
- Injector 维护一个 provider 列表，通过 name 来调用工厂方法 返回 实例
- 在 NgModule 的 provider 里注册的内容都可以被 inject



## 变化检测

略

## 

## 模板表达式和绑定

### 特殊的绑定表达式

- [class.ClassName] = 'isActive' : 可以决定是否要往 dom 的 classList 中加入一个 class
- [style.color] = 'getColor()' : 可以决定 style 的 color 对应要添加什么值
- [style.line-height.em]="'2'" : 可以决定 值和单位

## Attribute 绑定

- <input id="username" type="text" [attr.aria-required]="isRequired()" /> : 可以绑定 Attribute 去 dom 上