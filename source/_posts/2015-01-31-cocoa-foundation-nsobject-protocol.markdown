---
layout: post
title: "Foundation: NSObject Protocol"
date: 2015-01-31 22:41:09 +0800
comments: true
categories: Cocoa iOS
---

前面一章我们整理了`NSObject`类，这一章我们来看看`NSObject`协议的内容。

`NSObject`协议提供了一组方法作为`Objective-C`对象的基础。其实我们对照一个`NSObject`类和`NSObject`协议，可以看到很多方法的方法名都是一样的，只不过`NSObject`类提供的是类方法，是基于类级别的操作；而`NSObject`协议提供的是实例方法，是基于实例对象级别的操作。

如果一个对象如果采用了这个协议，则可以被看作是一级对象。我们可以从这个对象获取以下信息：

1. 类信息，以及类所在的继承体系。
2. 协议信息
3. 响应特定消息的能力

实际上，`Cocoa`的根类`NSObject`就采用了这个类，所以所有继承自`NSObject`类的对象都具备`NSObject`协议中描述的功能。接下来，我们参照`NSObject`类，整理一下这些功能。

## 识别对象

类似于`NSObject`类，`NSObject`协议提供了一些方法来识别类。 

如果想获取对象的类对象，则可以使用如下方法：

``` objective-c
- (Class)class
```

如果想获取对象父类的类对象，则可以使用以下只读属性：

``` objective-c
@property(readonly) Class superclass
```

如果想查看某个对象是否是给定类的实例或者是给定类子类的实例，则可以使用以下方法：

``` objective-c
- (BOOL)isKindOfClass:(Class)aClass
```

这个方法应该是大家常用的方法。需要注意的是在类簇中使用这个方法。在类簇中，我们获取到的对象类型可能并不是我们期望的类型。如果我们调用一个返回类簇的方法，则这个方法返回的实际类型会是最能标识这个类能做些什么的类型。例如，如果一个方法返回一个指向`NSArray`对象的指针，则不能使用`isKindOfClass:`方法查看经是否是一个可变数组，如以下代码：

``` objective-c
if ([myArray isKindOfClass:[NSMutableArray class]])
{
    // Modify the object
}
```

如果我们使用这样的代码，我们可能会认为修改一个实际上不应该被修改的对象是没问题的。这样做可能会对那些期望对象保持不要变的代码产生影响。

另外，查看对象是否是指定类的一个实例还可以使用以下方法：

``` objective-c
- (BOOL)isMemberOfClass:(Class)aClass
```

注意，这个方法无法确定对象是否是指定类子类的实例。另外，类对象可能是编译器创建的对象，但它仍然支持这一概念。

## 测试对象

对于对象的测试，`NSObject`协议也定义了两个方法，其中`respondsToSelector:`方法用于测试对象是否能响应指定的消息，这个方法可以是类自定义的实例方法，也可以是继承而来的实例方法。其声明如下：

``` objective-c
- (BOOL)respondsToSelector:(SEL)aSelector
```

不过我们不能使用`super`关键字来调用`respondsToSelector:`，以查看对象是否是从其父类继承了某个方法。因为我们可以从`super`的定义可知，消息的最终实际接收者还是`self`本身，因此测试的还是对象的整个体系(包括对象所在类本身)，而不仅仅是父类。不过，我们可以使用父类来调用`NSObject`类的类方法`instancesRespondToSelector:`来达到这个目的，如下所示：

``` objective-c
if( [MySuperclass instancesRespondToSelector:@selector(aMethod)] ) {
    // invoke the inherited method
    [super aMethod];
}
```

我们不能简单地使用`[[self superclass] instancesRespondToSelector:@selector(aMethod)]`，因为如果由一个子类来调用，则可能导致方法的失败。

还需要注意的是，如果对象能够转发消息，则也可以响应这个消息，不过这个方法会返回NO。

如果想查看对象是否实现了某个类，则可以使用如下方法：

``` objective-c
- (BOOL)conformsToProtocol:(Protocol *)aProtocol
```

这个方法与`NSObject`类的类方法`conformsToProtocol:`是一样的。它只是提供了一个便捷方法，我们不需要先去取对象的类，再调用类方法`conformsToProtocol:`。

## 标识和比较对象

如果我们想获取对象本身，则可以使用以下方法：

``` objective-c
- (instancetype)self
```

比较两个对象是否相同，则可以使用以下方法：

``` objective-c
- (BOOL)isEqual:(id)anObject
```

这个方法定义了对象相同的意义。例如，一个容器对象可能会按照特定规则来定义两个对象是否相等，如其所有元素的`isEqual:`请求都返回YES。我们在自定义子类时，可以重写这个方法，以使用我们自己的规则来评判两个对象相等。

如果两个对象相等，则它们必须拥有相同的`hash`值。在子类中定义`isEqual:`方法并打算把子类的实例放入集合中时，这一点非常重要。因此在子类中必须同时定义`hash`。

hash值是一个整数值，它可以用于在`hash`表结构中作为一个表地址。其声明如下：

``` objective-c
@property(readonly) NSUInteger hash
```

如果一个可变对象被添加到一个以`hash`值来确定对象位置的集合中，则当对象还在集合中时，其由`hash`方法返回的值不能改变。因此，`hash`方法不能依赖于对象内部的任何状态信息，或许我们必须确保对象在集合中时，不能改变其内部状态信息。比如，一个可变字典可以放到一个`hash`表中，但当它还在表中时，不能改变它。

## 发送消息

在`NSObject`类中，定义了一系列的发送消息的方法，用于在目标线程中执行方法。`NSObject`协议也定义了如下几个方法，来执行发送消息的任务：

``` objective-c
- (id)performSelector:(SEL)aSelector
- (id)performSelector:(SEL)aSelector withObject:(id)anObject
- (id)performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject
```

这三个方法基本相同，只不过后面两个方法能为`selector`指定的方法携带参数。因此我们以`performSelector:`为例。

`performSelector:`方法的使用与直接将消息发送给对象的效果是一样的，如下面几个操作，做的事情是一样的：

``` objective-c
id myClone = [anObject copy];
id myClone = [anObject performSelector:@selector(copy)];
id myClone = [anObject performSelector:sel_getUid("copy")];
```

区别在于，`performSelector:`允许在运行时再去确定对象是否能处理消息。而`[anObject copy]`中，如果`anObject`不能处理`copy`，编译器就直接会报错。

如果方法的参数过多，以至于上面几个方法都无法处理，则可以考虑使用`NSInvocation`对象。

## 描述对象

描述对象的方法与`NSObject`类中描述类的方法其方法名相同，都是`description`，其声明如下：

``` objective-c
@property(readonly, copy) NSString *description
```

这个方法用于创建一个对象的文本表达方式，例如：

``` objective-c
ClassName *anObject = <#An object#>;
NSString *string = [NSString stringWithFormat:@"anObject is %@", anObject];
```

为了便于调试，`NSObject`协议还定义`debugDescription`方法，该方法声明如下：

``` objective-c
@property(readonly, copy) NSString *debugDescription
```

该方法返回一个在调试器中显示的用于描述对象内容的字符串。在调试器中打印一个对象时，会调用这个方法。`NSObject`类实现这个方法时只是调用了`description`方法，所以默认情况下，这两个方法的输出都是一样的。我们在子类中可以重写这个方法的实现。

## 总结

`NSObject`协议的定义的很多方法都是我们平常经常使用的。我们在创建`NSObject`类的子类时，默认都继承了`NSObject`类对于`NSObject`协议的实现。如果有特殊的需求，我们可以重写这些方法。

当然，`NSObject`协议还定义了一些方法，如我们非常熟悉的`retain`, `release`, `autorelease`, `retainCount`方法，不过这些方法在`ARC`时代已经过时了，我们在此不过多说明。

## 参考

1. [NSObject Protocol Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Protocols/NSObject_Protocol/index.html)