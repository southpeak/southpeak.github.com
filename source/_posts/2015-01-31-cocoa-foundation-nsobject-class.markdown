---
layout: post
title: "Foundation: NSObject Class"
date: 2015-01-31 22:37:32 +0800
comments: true
categories: Cocoa iOS
---

*`Objective-C`中有两个`NSObject`，一个是`NSObject`类，另一个是`NSObject`协议。而其中`NSObject`类采用了`NSObject`协议。在本文中，我们主要整理一下`NSObject`类的使用。*

说到`NSObject`类，写`Objective-C`的人都应该知道它。它是大部分`Objective-C`类继承体系的根类。这个类提供了一些通用的方法，对象通过继承`NSObject`，可以从其中继承访问运行时的接口，并让对象具备`Objective-C`对象的基本能力。以下我们就来看看`NSObejct`提供给我们的一些基础功能。

## +load与+initialize

这两个方法可能平时用得比较少，但很有用。在我们的程序编译后，类相关的数据结构会保留在目标文件中，在程序运行后会被解析和使用，此时类的信息会经历加载和初始化两个过程。在这两个过程中，会分别调用类的`load`方法和`initialize`方法，在这两个方法中，我们可以适当地做一些定制处理。不当是类本身，类的分类也会经历这两个过程。对于一个类，我们可以在类的定义中重写这两个方法，也可以在分类中重写它们，或者同时重写。

### load方法

对于`load`方法，当`Objective-C`运行时加载类或分类时，会调用这个方法；通常如果我们有一些类级别的操作需要在加载类时处理，就可以放在这里面，如为一个类执行`Swizzling Method`操作。

`load`消息会被发送到动态加载和静态链接的类和分类里面。不过，只有当我们在类或分类里面实现这个方法时，类/分类才会去调用这个方法。

在类继承体系中，`load`方法的调用顺序如下：

1. 一个类的`load`方法会在其所有父类的`load`方法之后调用
2. 分类的`load`方法会在对应类的`load`方法之后调用

在`load`的实现中，如果使用同一库中的另外一个类，则可能是不安全的，因为可能存在的情况是另外一个类的`load`方法还没有运行，即另一个类可能尚未被加载。另外，在`load`方法里面，我们不需要显示地去调用`[super load]`，因为父类的`load`方法会自动被调用，且在子类之前。

在有依赖关系的两个库中，被依赖的库中的类其`load`方法会优先调用。但在库内部，各个类的`load`方法的调用顺序是不确定的。

### initialize方法

当我们在程序中向类或其任何子类发送第一条消息前，`runtime`会向该类发送`initialize`消息。`runtime`会以线程安全的方式来向类发起`initialize`消息。父类会在子类之前收到这条消息。父类的`initialize`实现可能在下面两种情况下被调用：

1. 子类没有实现`initialize`方法，`runtime`将会调用继承而来的实现
2. 子类的实现中显示的调用了`[super initialize]`

如果我们不想让某个类中的`initialize`被调用多次，则可以像如下处理：

``` objective-c
+ (void)initialize {
  if (self == [ClassName self]) {
    // ... do the initialization ...
  }
}
```

因为`initialize`是以线程安全的方式调用的，且在不同的类中`initialize`被调用的顺序是不确定的，所以在`initialize`方法中，我们应该做少量的必须的工作。特别需要注意是，如果我们`initialize`方法中的代码使用了锁，则可能会导致死锁。因此，我们不应该在`initialize`方法中实现复杂的初始化工作，而应该在类的初始化方法(如`-init`)中来初始化。

另外，每个类的`initialize`只会被调用一次。所以，如果我们想要为类和类的分类实现单独的初始化操作，则应该实现`load`方法。

如果想详细地了解这两个方法的使用，可以查看`《Effective Objective-C 2.0》`的第51条，里面有非常详细的说明。如果想更深入地了解这两个方法的调用，则可以参考`objc`库的源码，另外，[NSObject的load和initialize方法](http://www.cocoachina.com/ios/20150104/10826.html)一文从源码层面为我们简单介绍了这两个方法。

## 对象的生命周期

一说到对象的创建，我们会立即想到`[[NSObject alloc] init]`这种经典的两段式构造。对于这种两段式构造，唐巧大神在他的"[谈ObjC对象的两段构造模式](http://blog.devtang.com/blog/2013/01/13/two-stage-creation-on-cocoa/)"一文中作了详细描述，大家可以参考一下。

本小节我们主要介绍一下与对象生命周期相关的一些方法。

### 对象分配

`NSObject`提供的对象分配的方法有`alloc`和`allocWithZone:`，它们都是类方法。这两个方法负责创建对象并为其分配内存空间，返回一个新的对象实例。新的对象的`isa`实例变量使用一个数据结构来初始化，这个数据结构描述了对象的信息；创建完成后，对象的其它实例变量被初始化为0。

`alloc`方法的定义如下：

``` objective-c
+ (instancetype)alloc
```

而`allocWithZone:`方法的存在是由历史原因造成的，它的调用基本上和`alloc`是一样的。既然是历史原因，我们就不说了，官方文档只给了一句话：

``` 
This method exists for historical reasons; memory zones are no longer used by Objective-C.
```

我们只需要知道`alloc`方法的实现调用了`allocWithZone:`方法。

### 对象初始化

我们一般不去自己重写`alloc`或`allocWithZone:`方法，不用去关心对象是如何创建、如何为其分配内存空间的；我们更关心的是如何去初始化这个对象。上面提到了，对象创建后，`isa`以外的实例变量都默认初始化为0。通常，我们希望将这些实例变量初始化为我们期望的值，这就是`init`方法的工作了。

`NSObject`类默认提供了一个`init`方法，其定义如下：

``` objective-c
- (instancetype)init
```

正常情况下，它会初始化对象，如果由于某些原因无法完成对象的创建，则会返回nil。注意，对象在使用之前必须被初始化，否则无法使用。不过，`NSObject`中定义的`init`方法不做任何初始化操作，只是简单地返回`self`。

当然，我们定义自己的类时，可以提供自定义的初始化方法，以满足我们自己的初始化需求。需要注意的就是子类的初始化方法需要去调用父类的相应的初始化方法，以保证初始化的正确性。

讲完两段式构造的两个部分，有必要来讲讲`NSObject`类的`new`方法了。

`new`方法实际上是集`alloc`和`init`于一身，它创建了对象并初始化了对象。它的实现如下：

``` objective-c
+ (instancetype)new {
	return [[self alloc] init];
}
```

`new`方法更多的是一个历史遗留产物，它源于`NeXT`时代。如果我们的初始化操作只是调用`[[self alloc] init]`时，就可以直接用`new`来代替。不过如果我们需要使用自定义的初始化方法时，通常就使用两段式构造方式。

### 拷贝

说到拷贝，相信大家都很熟悉。拷贝可以分为“深拷贝”和“浅拷贝”。深拷贝拷贝的是对象的值，两个对象相互不影响，而浅拷贝拷贝的是对象的引用，修改一个对象时会影响到另一个对象。

在`Objective-C`中，如果一个类想要支持拷贝操作，则需要实现`NSCopying`协议，并实现`copyWithZone:`【注意：`NSObject`类本身并没有实现这个协议】。如果一个类不是直接继承自`NSObject`，则在实现copyWithZone:方法时需要调用父类的实现。

虽然`NSObject`自身没有实现拷贝协议，不过它提供了两个拷贝方法，如下：

``` objective-c
- (id)copy
```

这个是拷贝操作的便捷方法。它的返回值是`NSCopying`协议的`copyWithZone:`方法的返回值。如果我们的类没有实现这个方法，则会抛出一个异常。

与`copy`对应的还有一个方法，即：

``` objective-c
- (id)mutableCopy
```

从字面意义来讲，`copy`可以理解为不可变拷贝操作，而`mutableCopy`可以理解为可变操作。这便引出了拷贝的另一个特性，即可变性。

顾名思义，不可变拷贝即拷贝后的对象具有不可变属性，可变拷贝后的对象具有可变属性。这对于数组、字典、字符串、URL这种分可变和不可变的对象来说是很有意义的。我们来看如下示例：

``` objective-c
NSMutableArray *mutableArray = [NSMutableArray array];
NSMutableArray *array = [mutableArray copy];
[array addObject:@"test1"];
```

实际上，这段代码是会崩溃的，我们来看看崩溃日志：

``` objective-c
-[__NSArrayI addObject:]: unrecognized selector sent to instance 0x100107070
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[__NSArrayI addObject:]: unrecognized selector sent to instance 0x100107070'
```

从中可以看出，经过`copy`操作，我们的`array`实际上已经变成不可变的了，其底层元类是`__NSArrayI`。这个类是不支持`addObject:`方法的。

偶尔在代码中，也会看到类似于下面的情况：

``` objective-c
@property (copy) NSMutableArray *array;
```

这种属性的声明方式是有问题的，即上面提到的可变性问题。使用`self.array = **`赋值后，数组其实是不可变的，所以需要特别注意。

`mutableCopy`的使用也挺有意思的，具体的还请大家自己去试验一下。

### 释放

当一个对象的引用计数为0时，系统就会将这个对象释放。此时`runtime`会自动调用对象的`dealloc`方法。在`ARC`环境下，我们不再需要在此方法中去调用`[super dealloc]`了。我们重写这个方法主要是为了释放对象中用到的一些资源，如我们通过C方法分配的内存空间。`dealloc`方法的定义如下：

``` objective-c
- (void)dealloc
```

需要注意的是，我们不应该直接去调用这个方法。这些事都让`runtime`去做吧。

## 消息发送

`Objective-C`中对方法的调用并不是像C++里面那样直接调用，而是通过消息分发机制来实现的。这个机制核心的方法是`objc_msgSend`函数。消息机制的具体实现我们在此不做讨论，可以参考[Objective-C Runtime 运行时之三：方法与消息](http://southpeak.github.io/blog/2014/11/03/objective-c-runtime-yun-xing-shi-zhi-san-:fang-fa-yu-xiao-xi-zhuan-fa/)。

对于消息的发送，除了使用`[obj method]`这种机制之外，`NSObject`类还提供了一系列的`performSelector**`方法。这些方法可以让我们更加灵活地控制方法的调用。接下来我们就来看看这些方法的使用。

### 在线程中调用方法

如果我们想在当前线程中调用一个方法，则可以使用以下两个方法：

``` objective-c
- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay

- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterDelay:(NSTimeInterval)delay inModes:(NSArray *)modes
```

这两个方法会在当前线程的`Run loop`中设置一个定时器，以在`delay`指定的时间之后执行`aSelector`。如果我们希望定时器运行在默认模式(`NSDefaultRunLoopMode`)下，可以使用前一个方法；如果想自己指定`Run loop`模式，则可以使用后一个方法。

当定时器启动时，线程会从`Run loop`的队列中获取到消息，并执行相应的`selector`。如果`Run loop`运行在指定的模式下，则方法会成功调用；否则，定时器会处于等待状态，直到`Run loop`运行在指定模式下。

需要注意的是，调用这些方法时，`Run loop`会保留方法接收者及相关的参数的引用(即对这些对象做`retain`操作)，这样在执行时才不至于丢失这些对象。当方法调用完成后，`Run loop`会调用这些对象的`release`方法，减少对象的引用计数。

如果我们想在主线程上执行某个对象的方法，则可以使用以下两个方法：

``` objective-c
- (void)performSelectorOnMainThread:(SEL)aSelector withObject:(id)arg waitUntilDone:(BOOL)wait

- (void)performSelectorOnMainThread:(SEL)aSelector withObject:(id)arg waitUntilDone:(BOOL)wait modes:(NSArray *)array
```

我们都知道，iOS中所有的UI操作都需要在主线程中处理。如果想在某个二级线程的操作完成之后做UI操作，就可以使用这两个方法。

这两个方法会将消息放到主线程`Run loop`的队列中，前一个方法使用的是`NSRunLoopCommonModes`运行时模式；如果想自己指定运行模式，则使用后一个方法。方法的执行与之前的两个`performSelector`方法是类似的。当在一个线程中多次调用这个方法将不同的消息放入队列时，消息的分发顺序与入队顺序是一致的。

方法中的`wait`参数指定当前线程在指定的`selector`在主线程执行完成之后，是否被阻塞住。如果设置为YES，则当前线程被阻塞。如果当前线程是主线程，而该参数也被设置为YES，则消息会被立即发送并处理。

另外，这两个方法分发的消息不能被取消。

如果我们想在指定的线程中分发某个消息，则可以使用以下两个方法：

``` objective-c
- (void)performSelector:(SEL)aSelector onThread:(NSThread *)thread withObject:(id)arg waitUntilDone:(BOOL)wait

- (void)performSelector:(SEL)aSelector onThread:(NSThread *)thread withObject:(id)arg waitUntilDone:(BOOL)wait modes:(NSArray *)array
```

这两个方法基本上与在主线程的方法差不多。在此就不再讨论。

如果想在后台线程中调用接收者的方法，可以使用以下方法：

``` objective-c
- (void)performSelectorInBackground:(SEL)aSelector withObject:(id)arg
```

这个方法会在程序中创建一个新的线程。由`aSelector`表示的方法必须像程序中的其它新线程一样去设置它的线程环境。

当然，我们经常看到的`performSelector`系列方法中还有几个方法，即：

``` objective-c
- (id)performSelector:(SEL)aSelector
- (id)performSelector:(SEL)aSelector withObject:(id)anObject
- (id)performSelector:(SEL)aSelector withObject:(id)anObject withObject:(id)anotherObject
```

不过这几个方法是在`NSObject`协议中定义的，`NSObject`类实现了这个协议，也就定义了相应的实现。这个我们将在`NSObject`协议中来介绍。

### 取消方法调用请求

对于使用`performSelector:withObject:afterDelay:`方法(仅限于此方法)注册的执行请求，在调用发生前，我们可以使用以下两个方法来取消：

``` objective-c
+ (void)cancelPreviousPerformRequestsWithTarget:(id)aTarget

+ (void)cancelPreviousPerformRequestsWithTarget:(id)aTarget selector:(SEL)aSelector object:(id)anArgument
```

前一个方法会取消所以接收者为`aTarget`的执行请求，不过仅限于当前`run loop`，而不是所有的。

后一个方法则会取消由`aTarget`、`aSelector`和`anArgument`三个参数指定的执行请求。同样仅限于当前`run loop`。

## 消息转发及动态解析方法

当一个对象能接收一个消息时，会走正常的方法调用流程。但如果一个对象无法接收一个消息时，就会走消息转发机制。

消息转发机制基本上分为三个步骤：

1. 动态方法解析
2. 备用接收者
3. 完整转发

具体流程可参考[Objective-C Runtime 运行时之三：方法与消息](http://southpeak.github.io/blog/2014/11/03/objective-c-runtime-yun-xing-shi-zhi-san-:fang-fa-yu-xiao-xi-zhuan-fa/)，`《Effective Objective-C 2.0》`一书的第12小节也有详细描述。在此我们只介绍一下`NSObject`类为实现消息转发提供的方法。

首先，对于动态方法解析，`NSObject`提供了以下两个方法来处理：

``` objective-c
+ (BOOL)resolveClassMethod:(SEL)name
+ (BOOL)resolveInstanceMethod:(SEL)name
```

从方法名我们可以看出，`resolveClassMethod:`是用于动态解析一个类方法；而`resolveInstanceMethod:`是用于动态解析一个实例方法。

我们知道，一个`Objective-C`方法是其实是一个C函数，它至少带有两个参数，即`self`和`_cmd`。我们使用`class_addMethod`函数，可以给类添加一个方法。我们以`resolveInstanceMethod:`为例，如果要给对象动态添加一个实例方法，则可以如下处理：

``` objective-c
void dynamicMethodIMP(id self, SEL _cmd)
{
    // implementation ....
}

+ (BOOL) resolveInstanceMethod:(SEL)aSEL
{
    if (aSEL == @selector(resolveThisMethodDynamically))
    {
          class_addMethod([self class], aSEL, (IMP) dynamicMethodIMP, "v@:");
          return YES;
    }
    return [super resolveInstanceMethod:aSel];
}
```

其次，对于备用接收者，`NSObject`提供了以下方法来处理：

``` objective-c
- (id)forwardingTargetForSelector:(SEL)aSelector
```

该方法返回未被接收消息最先被转发到的对象。如果一个对象实现了这个方法，并返回一个非空的对象(且非对象本身)，则这个被返回的对象成为消息的新接收者。另外如果在非根类里面实现这个方法，如果对于给定的`selector`，我们没有可用的对象可以返回，则应该调用父类的方法实现，并返回其结果。

最后，对于完整转发，`NSObject`提供了以下方法来处理

``` objective-c
- (void)forwardInvocation:(NSInvocation *)anInvocation
```

当前面两步都无法处理消息时，运行时系统便会给接收者最后一个机会，将其转发给其它代理对象来处理。这主要是通过创建一个表示消息的`NSInvocation`对象并将这个对象当作参数传递给`forwardInvocation:`方法。我们在`forwardInvocation:`方法中可以选择将消息转发给其它对象。

在这个方法中，主要是需要做两件事：

1. 找到一个能处理`anInvocation`调用的对象。
2. 将消息以`anInvocation`的形式发送给对象。`anInvocation`将维护调用的结果，而运行时则会将这个结果返回给消息的原始发送者。

这一过程如下所示：

``` objective-c
- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL aSelector = [invocation selector];
 
    if ([friend respondsToSelector:aSelector])
        [invocation invokeWithTarget:friend];
    else
        [super forwardInvocation:invocation];
}
```

当然，对于一个非根类，如果还是无法处理消息，则应该调用父类的实现。而NSObject类对于这个方法的实现，只是简单地调用了`doesNotRecognizeSelector:`。它不再转发任何消息，而是抛出一个异常。`doesNotRecognizeSelector:`的声明如下：

``` objective-c
- (void)doesNotRecognizeSelector:(SEL)aSelector
```

运行时系统在对象无法处理或转发一个消息时会调用这个方法。这个方法引发一个`NSInvalidArgumentException`异常并生成一个错误消息。

任何`doesNotRecognizeSelector:`消息通常都是由运行时系统来发送的。不过，它们可以用于阻止一个方法被继承。例如，一个`NSObject`的子类可以按以下方式来重写`copy`或`init`方法以阻止继承：

``` objective-c
- (id)copy
{
    [self doesNotRecognizeSelector:_cmd];
}
```

这段代码阻止子类的实例响应`copy`消息或阻止父类转发`copy`消息--虽然`respondsToSelector:`仍然报告接收者可以访问`copy`方法。

当然，如果我们要重写`doesNotRecognizeSelector:`方法，必须调用`super`的实现，或者在实现的最后引发一个`NSInvalidArgumentException`异常。它代表对象不能响应消息，所以总是应该引发一个异常。

## 获取方法信息

在消息转发的最后一步中，`forwardInvocation:`参数是一个`NSInvocation`对象，这个对象需要获取方法签名的信息，而这个签名信息就是从`methodSignatureForSelector:`方法中获取的。

该方法的声明如下:

``` objective-c
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
```

这个方法返回包含方法描述信息的`NSMethodSignature`对象，如果找不到方法，则返回nil。如果我们的对象包含一个代理或者对象能够处理它没有直接实现的消息，则我们需要重写这个方法来返回一个合适的方法签名。

对应于实例方法，当然还有一个处理类方法的相应方法，其声明如下：

``` objective-c
+ (NSMethodSignature *)instanceMethodSignatureForSelector:(SEL)aSelector
```

另外，`NSObject`类提供了两个方法来获取一个`selector`对应的方法实现的地址，如下所示：

``` objective-c
- (IMP)methodForSelector:(SEL)aSelector
+ (IMP)instanceMethodForSelector:(SEL)aSelector
```

获取到了方法实现的地址，我们就可以直接将`IMP`以函数形式来调用。

对于`methodForSelector:`方法，如果接收者是一个对象，则`aSelector`应该是一个实例方法；如果接收者是一个类，则`aSelector`应该是一个类方法。

对于`instanceMethodForSelector:`方法，其只是向类对象索取实例方法的实现。如果接收者的实例无法响应`aSelector`消息，则产生一个错误。

## 测试类

对于类的测试，在`NSObject`类中定义了两个方法，其中类方法`instancesRespondToSelector:`用于测试接收者的实例是否响应指定的消息，其声明如下：

``` objective-c
+ (BOOL)instancesRespondToSelector:(SEL)aSelector
```

如果`aSelector`消息被转发到其它对象，则类的实例可以接收这个消息而不会引发错误，即使该方法返回NO。

为了询问类是否能响应特定消息(注意：不是类的实例)，则使用这个方法，而不使用NSObject协议的实例方法`respondsToSelector:`。

`NSObject`还提供了一个方法来查看类是否采用了某个协议，其声明如下：

``` objective-c
+ (BOOL)conformsToProtocol:(Protocol *)aProtocol
```

如果一个类直接或间接地采用了一个协议，则我们可以说这个类实现了该协议。我们可以看看以下这个例子：

``` objective-c
@protocol AffiliationRequests <Joining>

@interface MyClass : NSObject <AffiliationRequests, Normalization>

BOOL canJoin = [MyClass conformsToProtocol:@protocol(Joining)];
```

通过继承体系，`MyClass`类实现了`Joining`协议。

不过，这个方法并不检查类是否实现了协议的方法，这应该是程序员自己的职责了。

## 识别类

`NSObject`类提供了几个类方法来识别一个类，首先是我们常用的`class`类方法，该方法声明如下：

``` objective-c
+ (Class)class
```

该方法返回类对象。当类是消息的接收者时，我们只通过类的名称来引用一个类。在其它情况下，类的对象必须通过这个方法类似的方法(`-class`实例方法)来获取。如下所示：

``` objective-c
BOOL test = [self isKindOfClass:[SomeClass class]];
```

`NSObject`还提供了`superclass`类方法来获取接收者的父类，其声明如下：

``` objective-c
+ (Class)superclass
```

另外，我们还可以使用`isSubclassOfClass:`类方法查看一个类是否是另一个类的子类，其声明如下：

``` objective-c
+ (BOOL)isSubclassOfClass:(Class)aClass
```

## 描述类

描述类是使用`description`方法，它返回一个表示类的内容的字符串。其声明如下：

``` objective-c
+ (NSString *)description
```

我们在`LLDB`调试器中打印类的信息时，使用的就是这个方法。

当然，如果想打印类的实例的描述时，使用的是`NSObject`协议中的实例方法`description`，我们在此不多描述。

​	

## 归档操作

一说到归档操作，你会首先想到什么呢？我想到的是`NSCoding`协议以及它的两个方法：

`initWithCoder:`和`encodeWithCoder:`。如果我们的对象需要支持归档操作，则应该采用这个协议并提供两个方法的具体实现。

在编码与解码的过程中，一个编码器会调用一些方法，这些方法允许将对象编码以替代一个更换类或实例本身。这样，就可以使得归档在不同类层次结构或类的不同版本的实现中被共享。例如，类簇能有效地利用这一特性。这一特性也允许每个类在解码时应该只维护单一的实例来执行这一策略。

`NSObject`类虽然没有采用`NSCoding`协议，但却提供了一些替代方法，以支持上述策略。这些方法分为两类，即通用和专用的。

通用方法由`NSCoder`对象调用，主要有如下几个方法和属性：

``` objective-c
@property(readonly) Class classForCoder

- (id)replacementObjectForCoder:(NSCoder *)aCoder
- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder
```

专用的方法主要是针对`NSKeyedArchiver`对象的，主要有如下几个方法和属性：

``` objective-c
@property(readonly) Class classForKeyedArchiver

+ (NSArray *)classFallbacksForKeyedArchiver
+ (Class)classForKeyedUnarchiver
- (id)replacementObjectForKeyedArchiver:(NSKeyedArchiver *)archiver
```

子类在归档的过程中如果有特殊的需求，可以重写这些方法。这些方法的具体描述，可以参考[官方文档](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSObject_Class)。

在解码或解档过程中，有一点需要考虑的就是对象所属类的版本号，这样能确保老版本的对象能被正确地解析。`NSObject`类对此提供了两个方法，如下所示：

``` objective-c
+ (void)setVersion:(NSInteger)aVersion
+ (NSInteger)version
```

它们都是类方法。默认情况下，如果没有设置版本号，则默认是0.

## 总结

`NSObject`类是`Objective-C`中大部分类层次结构中的根类，并为我们提供了很多功能。了解这些功能更让我们更好地发挥`Objective-C`的特性。

## 参考

1. [NSObject Class Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSObject_Class)
2. [Archives and Serializations Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Archiving/Articles/codingobjects.html)
3. [NSObject的load和initialize方法](http://www.cocoachina.com/ios/20150104/10826.html)
4. [Objective-C Runtime 运行时之三：方法与消息](http://southpeak.github.io/blog/2014/11/03/objective-c-runtime-yun-xing-shi-zhi-san-:fang-fa-yu-xiao-xi-zhuan-fa/)
5. 《Effective Objective-C 2.0》