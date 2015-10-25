---
layout: post
title: "Foundation: NSCache"
date: 2015-02-11 21:45:14 +0800
comments: true
categories: Cocoa iOS
---

`NSCache`是一个类似于集合的容器，即缓存。它存储`key-value`对，这一点类似于`NSDictionary`类。我们通常用使用缓存来临时存储短时间使用但创建昂贵的对象。重用这些对象可以优化性能，因为它们的值不需要重新计算。另外一方面，这些对象对于程序来说不是紧要的，在内存紧张时会被丢弃。如果对象被丢弃了，则下次使用时需要重新计算。

当一个`key-value`对在缓存中时，缓存维护它的一个强引用。存储在`NSCache`中的通用数据类型通常是实现了`NSDiscardableContent`协议的对象。在缓存中存储这类对象是有好处的，因为当不再需要它时，可以丢弃这些内容，以节省内存。默认情况下，缓存中的`NSDiscardableContent`对象在其内容被丢弃时，会被移除出缓存，尽管我们可以改变这种缓存策略。如果一个`NSDiscardableContent`被放进缓存，则在对象被移除时，缓存会调用`discardContentIfPossible`方法。

`NSCache`与可变集合有几点不同：

1. `NSCache`类结合了各种自动删除策略，以确保不会占用过多的系统内存。如果其它应用需要内存时，系统自动执行这些策略。当调用这些策略时，会从缓存中删除一些对象，以最大限度减少内存的占用。
2. `NSCache`是线程安全的，我们可以在不同的线程中添加、删除和查询缓存中的对象，而不需要锁定缓存区域。
3. 不像`NSMutableDictionary`对象，一个缓存对象不会拷贝`key`对象。

这些特性对于`NSCache`类来说是必须的，因为在需要释放内存时，缓存必须异步地在幕后决定去自动修改自身。

## 缓存限制

`NSCache`提供了几个属性来限制缓存的大小，如属性`countLimit`限定了缓存最多维护的对象的个数。声明如下：

``` objective-c
@property NSUInteger countLimit
```

默认值为0，表示不限制数量。但需要注意的是，这不是一个严格的限制。如果缓存的数量超过这个数量，缓存中的一个对象可能会被立即丢弃、或者稍后、也可能永远不会，具体依赖于缓存的实现细节。

另外，`NSCache`提供了`totalCostLimit`属性来限定缓存能维持的最大内存。其声明如下：

``` objective-c
@property NSUInteger totalCostLimit
```

默认值也是0，表示没有限制。当我们添加一个对象到缓存中时，我们可以为其指定一个消耗(`cost`)，如对象的字节大小。如果添加这个对象到缓存导致缓存总的消耗超过`totalCostLimit`的值，则缓存会自动丢弃一些对象，直到总消耗低于`totalCostLimit`值。不过被丢弃的对象的顺序无法保证。

需要注意的是`totalCostLimit`也不是一个严格限制，其策略是与`countLimit`一样的。

## 存取方法

`NSCache`提供了一组方法来存取`key-value`对，类似于`NSMutableDictionary`类。如下所示：

``` objective-c
- (id)objectForKey:(id)key
- (void)setObject:(id)obj forKey:(id)key
- (void)removeObjectForKey:(id)key
- (void)removeAllObjects
```

如上所述，与`NSMutableDictionary`不同的就是它不会拷贝`key`对象。

此外，我们在存储对象时，可以为对象指定一个消耗值，如下所示：

``` objective-c
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)num
```

这个消耗值用于计算缓存中所有对象的一个消耗总和。当内存受限或者总消耗超过了限定的最大总消耗，则缓存应该开启一个丢弃过程以移除一些对象。不过，这个过程不能保证被丢弃对象的顺序。其结果是，如果我们试图操作这个消耗值来实现一些特殊的行为，则后果可能会损害我们的程序。通常情况下，这个消耗值是对象的字节大小。如果这些信息不是现成的，则我们不应该去计算它，因为这样会使增加使用缓存的成本。如果我们没有可用的值传递，则直接传递0，或者是使用`-setObject:forKey:`方法，这个方法不需要传入一个消耗值。

## NSDiscardableContent协议

`NSDiscardableContent`是一个协议，实现这个协议的目的是为了让我们的对象在不被使用时，可以将其丢弃，以让程序占用更少的内存。

一个`NSDiscardableContent`对象的生命周期依赖于一个“`counter`”变量。一个`NSDiscardableContent`对象实际是一个可清理内存块，这个内存记录了对象当前是否被其它对象使用。如果这块内存正在被读取，或者仍然被需要，则它的`counter`变量是大于或等于1的；当它不再被使用时，就可以丢弃，此时`counter`变量将等于0。当`counter`变量等于0时，如果当前时间点内存比较紧张的话，内存块就可能被丢弃。

为了丢弃这些内容，可以调用对象的`discardContentIfPossible`方法，该方法的声明如下：

``` objective-c
- (void)discardContentIfPossible
```

这样当`counter`变量等于0时将会释放相关的内存。而如果`counter`变量不为0，则该方法什么也不做。

默认情况下，`NSDiscardableContent`对象的`counter`变量初始值为1，以确保对象不会被内存管理系统立即释放。从这个点开始，我们就需要去跟踪`counter`变量的状态。为此。协议声明了两个方法：`beginContentAccess`和`endContentAccess`。

其中调用`beginContentAccess`方法会增加对象的`counter`变量(+1)，这样就可以确保对象不会被丢弃。该方法声明如下：

``` objective-c
- (BOOL)beginContentAccess
```

通常我们在对象被需要或者将要使用时调用这个方法。具体的实现类可以决定在对象已经被丢弃的情况下是否重新创建这些内存，且重新创建成功后返回YES。协议的实现者在`NSDiscardableContent`对象被使用，而又没有调用它的`beginContentAccess`方法时，应该抛出一个异常。

函数的返回值如果是YES，则表明可丢弃内存仍然可用且已被成功访问；否则返回NO。另外需要注意的是，该方法是在实现类中必须实现(`required`)。

与`beginContentAccess`相对应的是`endContentAccess`。如果可丢弃内存不再被访问时调用。其声明如下：

``` objective-c
- (void)endContentAccess
```

该方法会减少对象的`counter`变量，通常是让对象的`counter`值变回为0，这样在对象的内容不再被需要时，就要以将其丢弃。

`NSCache`类提供了一个属性，来标识缓存是否自动舍弃那些内存已经被丢弃的对象(`discardable-content object`)，其声明如下：

``` objective-c
@property BOOL evictsObjectsWithDiscardedContent
```

如果设置为YES，则在对象的内存被丢弃时舍弃对象。默认值为YES。

## NSCacheDelegate代理

`NSCache`对象还有一个代理属性，其声明如下：

``` objective-c
@property(assign) id< NSCacheDelegate > delegate
```

实现`NSCacheDelegate`代理的对象会在对象即将从缓存中移除时执行一些特定的操作，因此代理对象可以实现以下方法：

``` objective-c
- (void)cache:(NSCache *)cache willEvictObject:(id)obj
```

需要注意的是在这个代理方法中不能修改cache对象。

## 小结

实际上，我们常用的`SDWebImage`图片下载库的缓存机制就是通过`NSCache`来实现的。`《Effective Objective-C 2.0》`中也专门用一小篇的内容来介绍`NSCache`的使用(第50条：构建缓存时选用`NSCache`而非`NSDictionary`)，里面有更精彩的内容。如果我们需要构建缓存机制，则应该使用`NSCache`，而不是`NSDictionary`，这样可以减少我们应用对内存的占用，从而达到优化内存的目标。

## 参考

1. [NSCache Class Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/NSCache_Class/)
2. [NSDiscardableContent Protocol Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/NSDiscardableContent_Protocol/index.html)
3. [NSCacheDelegate Protocol Reference](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/NSCacheDelegate_Protocol/index.html)
4. [Objective-C中的缓存: NSCache介绍](http://www.15yan.com/story/45toOUzFGlr/)
5. [NSCache](http://nshipster.cn/nscache/)