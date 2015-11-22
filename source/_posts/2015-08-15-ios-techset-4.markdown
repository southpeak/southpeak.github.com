---
layout: post
title: "iOS知识小集 第四期(2015.08.15)"
date: 2015-08-15 22:21:02 +0800
comments: true
categories: techset ios
---



又欠了一屁股债了。积累了一大堆的问题放在那，就是没有整理。不能怪别人，也能怪自己了，犯起懒来，啥事也不想做，连喜爱的户外运动也给拉下了，掐指一算，居然大半年没出去了。然后经常看到老驴子们出去玩耍，回来就是一通的美图，心里那个痒痒啊。

回到正题吧，这次的知识小集知识点不多，还是三个：

1. `ARC`与`MRC`的性能对比
2. `Bitcode`
3. 在`Swift`中实现`NS_OPTIONS`

篇幅超过了预期，大家慢慢看，如有问题还请指正。

## ARC与MRC的性能对比

`MRC`似乎已经是一个上古时代的话题了，不过我还是绕有兴致的把它翻出来。因为，今天我被一个问题问住了：`ARC`与`MRC`的性能方面孰优劣。确实，之前没有对比过。

先来做个测试吧。首先我们需要一个计时辅助函数，我选择使用`mach_absolute_time`，计算时间差的函数如下：

``` objective-c
double subtractTimes(uint64_t endTime, uint64_t startTime) {

    uint64_t difference = endTime - startTime;
    static double conversion = 0.0;

    if(conversion == 0.0) {

        mach_timebase_info_data_t info;
        kern_return_t err = mach_timebase_info(&info);                       //Convert the timebaseinto seconds

        if(err == 0)
            conversion = 1e-9 * (double) info.numer / (double) info.denom;
    }

    return conversion * (double)difference;
}
```

然后定义两个测试类，一个是`ARC`环境下的，一个是`MRC`环境下的，分别如下：

``` objective-c
// Test1.m
+ (void)test {

    uint64_t start,stop;

    start = mach_absolute_time();

    for (int i = 0; i < 1000000; i++) {
        NSArray *array = [[NSArray alloc] init];
    }

    stop = mach_absolute_time();

    double diff = subtractTimes(stop, start);

    NSLog(@"ARC total time in seconds = %f\n", diff);
}

// Test2.m
// 在target->Build Phases->Compile Sources中，添加编译标识-fno-objc-arc
+ (void)test {

    uint64_t start,stop;

    start = mach_absolute_time();

    for (int i = 0; i < 1000000; i++) {
        NSArray *array = [[NSArray alloc] init];
        [array release];
    }

    stop = mach_absolute_time();

    double diff = subtractTimes(stop, start);

    NSLog(@"MRC total time in seconds = %f\n", diff);
}
```

多运行几组测试，然后挑两组吧来看看，数据如下：

``` objective-c
// A组
ARC total time in seconds = 0.077761
MRC total time in seconds = 0.072469

// B组
ARC total time in seconds = 0.075722
MRC total time in seconds = 0.101671
```

从上面的数据可以看到，`ARC`与`MRC`各有快慢的情况。即使上升到统计学的角度，`ARC`也只是以轻微的优势胜出。看来我的测试姿势不对，并没有证明哪一方占绝对的优势。

嗯，那我们再来看看官方文档是怎么说的吧。在[Transitioning to ARC Release Notes](https://developer.apple.com/library/ios/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html)中有这么一段话：

> **Is ARC slow?**
> 
> It depends on what you’re measuring, but generally “no.” The compiler efficiently eliminates many extraneous`retain`/`release` calls and much effort has been invested in speeding up the Objective-C runtime in general. In particular, the common “return a retain/autoreleased object” pattern is much faster and does not actually put the object into the autorelease pool, when the caller of the method is ARC code.
> 
> One issue to be aware of is that the optimizer is not run in common debug configurations, so expect to see a lot more `retain`/`release` traffic at `-O0` than at `-Os`.

再来看看别人的数据吧。`Stefan Itterheim`在[Confirmed: Objective-C ARC is slow. Don’t use it! (sarcasm off)](http://www.learn-cocos2d.com/2013/03/confirmed-arc-slow/)一文中给出了大量的测试数据。这篇文章是`2013.3.20`号发表的。`Stefan Itterheim`通过他的测试得出一个结论

> ARC is generally faster, and ARC can indeed be slower

嗯，有些矛盾。不过在文章中，`Steffen Itterheim`指出大部分情况下，`ARC`的性能是更好的，这主要得益于一些底层的优化以及`autorelease pool`的优化，这个从官方文档也能看到。但在一些情况下，`ARC`确实是更慢，`ARC`会发送一些额外的`retain/release`消息，如一些涉及到临时变量的地方，看下面这段代码：

``` objective-c
// this is typical MRC code:
{
    id object = [array objectAtIndex:0];
    [object doSomething];
    [object doAnotherThing];
}

// this is what ARC does (and what is considered best practice under MRC):
{
    id object = [array objectAtIndex:0];
    [object retain]; // inserted by ARC
    [object doSomething];
    [object doAnotherThing];
    [object release]; // inserted by ARC
}
```

另外，在带对象参数的方法中，也有类似的操作：

``` objective-c
// this is typical MRC code:
-(void) someMethod:(id)object
{
    [object doSomething];
    [object doAnotherThing];
}

// this is what ARC does (and what is considered best practice under MRC):
-(void) someMethod:(id)object
{
    [object retain]; // inserted by ARC
    [object doSomething];
    [object doAnotherThing];
    [object release]; // inserted by ARC
}
```

这些些额外的`retain/release`操作也成了降低`ARC`环境下程序性能的罪魁祸首。但实际上，之所以添加这些额外的`retain/release`操作，是为了保证代码运行的正确性。如果只是在单线程中执行这些操作，可能确实没必要添加这些额外的操作。但一旦涉及以多线程的操作，问题就来了。如上面的方法中，`object`完全有可能在`doSoming`和`doAnotherThing`方法调用之间被释放。为了避免这种情况的发生，便在方法开始处添加了`[object retain]`，而在方法结束后，添加了`[object release]`操作。

如果想了解更多关于`ARC`与`MRC`性能的讨论，可以阅读一下[Are there any concrete study of the performance impact of using ARC?](http://stackoverflow.com/questions/12527286/are-there-any-concrete-study-of-the-performance-impact-of-using-arc)与[ARC vs. MRC Performance](http://mjtsai.com/blog/2013/09/10/arc-vs-mrc-performance/)，在此就不过多的摘抄了。

实际上，即便是`ARC`的性能不如`MRC`，我们也应该去使用`ARC`，因此它给我们带来的好处是不言而喻的。我们不再需要像使用`MRC`那样，去过多的关注内存问题(虽然内存是必须关注的)，而将更多的时间放在我们真正关心的事情上。如果真的对性能非常关切的话，可以考虑直接用`C`或`C++`。反正我是不会再回到`MRC`时代了。

### 参考

1. [Are there any concrete study of the performance impact of using ARC?](http://stackoverflow.com/questions/12527286/are-there-any-concrete-study-of-the-performance-impact-of-using-arc)
2. [ARC vs. MRC Performance](http://mjtsai.com/blog/2013/09/10/arc-vs-mrc-performance/)
3. [Confirmed: Objective-C ARC is slow. Don’t use it! (sarcasm off)](http://www.learn-cocos2d.com/2013/03/confirmed-arc-slow/)
4. [Transitioning to ARC Release Notes](https://developer.apple.com/library/ios/releasenotes/ObjectiveC/RN-TransitioningToARC/Introduction/Introduction.html)



## Bitcode

今天试着用`Xcode 7 beta 3`在真机(`iOS 8.3`)上运行一下我们的工程，结果发现工程编译不过。看了下问题，报的是以下错误：

> ld: '/Users/\*\*/Framework/SDKs/PolymerPay/Library/mobStat/lib\*\*SDK.a(\*\*ForSDK.o)' does not contain bitcode. You must rebuild it with bitcode enabled (Xcode setting ENABLE_BITCODE), obtain an updated library from the vendor, or disable bitcode for this target. for architecture arm64

得到的信息是我们引入的一个第三方库不包含`bitcode`。嗯，不知道`bitcode`是啥，所以就得先看看这货是啥了。

### Bitcode是什么？

找东西嘛，最先想到的当然是先看官方文档了。在[App Distribution Guide - App Thinning (iOS, watchOS)](https://developer.apple.com/library/prerelease/ios/documentation/IDEs/Conceptual/AppDistributionGuide/AppThinning/AppThinning.html#//apple_ref/doc/uid/TP40012582-CH35)一节中，找到了下面这样一个定义：

> *Bitcode* is an intermediate representation of a compiled program. Apps you upload to iTunes Connect that contain bitcode will be compiled and linked on the App Store. Including bitcode will allow Apple to re-optimize your app binary in the future without the need to submit a new version of your app to the store.

说的是`bitcode`是被编译程序的一种中间形式的代码。包含`bitcode`配置的程序将会在`App store`上被编译和链接。`bitcode`允许苹果在后期重新优化我们程序的二进制文件，而不需要我们重新提交一个新的版本到`App store`上。

嗯，看着挺高级的啊。

继续看，在[What's New in Xcode-New Features in Xcode 7](https://developer.apple.com/library/prerelease/ios/documentation/DeveloperTools/Conceptual/WhatsNewXcode/Articles/xcode_7_0.html)中，还有一段如下的描述

> **Bitcode.** When you archive for submission to the App Store, Xcode will compile your app into an intermediate representation. The App Store will then compile the bitcode down into the 64 or 32 bit executables as necessary.

当我们提交程序到`App store`上时，`Xcode`会将程序编译为一个中间表现形式(`bitcode`)。然后`App store`会再将这个`bitcode`编译为可执行的`64`位或`32`位程序。

再看看这两段描述都是放在`App Thinning`(App瘦身)一节中，可以看出其与包的优化有关了。喵大([@onevcat](http://weibo.com/onevcat))在其博客[开发者所需要知道的 iOS 9 SDK 新特性](http://onevcat.com/2015/06/ios9-sdk/)中也描述了`iOS 9`中苹果在`App`瘦身中所做的一些改进，大家可以转场到那去研读一下。

### Bitcode配置

在上面的错误提示中，提到了如何处理我们遇到的问题：

> You must rebuild it with bitcode enabled (Xcode setting ENABLE_BITCODE), obtain an updated library from the vendor, or disable bitcode for this target. for architecture arm64

要么让第三方库支持，要么关闭`target`的`bitcode`选项。

实际上在`Xcode 7`中，我们新建一个`iOS`程序时，`bit code`选项默认是设置为`YES`的。我们可以在`”Build Settings”`->`”Enable Bitcode”`选项中看到这个设置。

不过，我们现在需要考虑的是三个平台：`iOS`，`Mac OS`，`watchOS`。

- 对应`iOS`，`bitcode`是可选的。


- 对于`watchOS`，`bitcode`是必须的。


- `Mac OS`不支持`bitcode`。

如果我们开启了`bitcode`，在提交包时，下面这个界面也会有个`bitcode`选项：

![image](https://developer.apple.com/library/prerelease/ios/documentation/IDEs/Conceptual/AppDistributionGuide/Art/6_ios_review_dist_profile_submit_2x.png)

> 盗图，我的应用没办法在这个界面显示`bitcode`，因为依赖于第三方的库，而这个库不支持`bitcode`，暂时只能设置`ENABLE_BITCODE为NO`。
> 
> 所以，如果我们的工程需要支持`bitcode`，则必要要求所有的引入的第三方库都支持`bitcode`。我就只能等着公司那些大哥大姐们啥时候提供一个新包给我们了。

### 题外话

如上面所说，`bitcode`是一种中间代码。`LLVM`官方文档有介绍这种文件的格式，有兴趣的可以移步[LLVM Bitcode File Format](http://llvm.org/docs/BitCodeFormat.html#llvm-bitcode-file-format)。

### 参考

1. [App Distribution Guide - App Thinning (iOS, watchOS)](https://developer.apple.com/library/prerelease/ios/documentation/IDEs/Conceptual/AppDistributionGuide/AppThinning/AppThinning.html#//apple_ref/doc/uid/TP40012582-CH35)
2. [What's New in Xcode-New Features in Xcode 7](https://developer.apple.com/library/prerelease/ios/documentation/DeveloperTools/Conceptual/WhatsNewXcode/Articles/xcode_7_0.html)
3. [开发者所需要知道的 iOS 9 SDK 新特性](http://onevcat.com/2015/06/ios9-sdk/)
4. [LLVM Bitcode File Format](http://llvm.org/docs/BitCodeFormat.html#llvm-bitcode-file-format)



## 在Swift中实现NS_OPTIONS

从`Xcode 4.5`以后，我们在`Objective-C`中使用`NS_ENUM`和`NS_OPTIONS`来定义一个枚举，以替代`C`语言枚举的定义方式。其中`NS_ENUM`用于定义普通的枚举，`NS_OPTIONS`用于定义选项类型的枚举。

而到了`Swift`中，枚举增加了更多的特性。它可以包含原始类型(不再局限于整型)以及相关值。正是由于这些原因，枚举在`Swift`中得到了更广泛的应用。在`Foundation`中，`Objective-C`中的`NS_ENUM`类型的枚举，都会自动转换成`Swift`中`enum`，并且更加精炼。以`Collection View`的滚动方向为例，在`Objective-C`中，其定义如下：

``` objective-c
typedef NS_ENUM(NSInteger, UICollectionViewScrollDirection) {
	UICollectionViewScrollDirectionVertical,
	UICollectionViewScrollDirectionHorizontal
};
```

而在`Swift`中，其定义如下：

``` objective-c
enum UICollectionViewScrollDirection : Int {
	case Vertical
	case Horizontal
}
```

精练多了吧，看着舒服多了，还能少码两个字。我们自己定义枚举时，也应该采用这种方式。

不过对于`Objective-C`中`NS_OPTIONS`类型的枚举，`Swift`中的实现似乎就没有那么美好了。

我们再来对比一下`UICollectionViewScrollPosition`的定义吧，在`Objective-C`中，其定义如下：

``` objective-c
typedef NS_OPTIONS(NSUInteger, UICollectionViewScrollPosition) {
    UICollectionViewScrollPositionNone                 = 0,

    // The vertical positions are mutually exclusive to each other, but are bitwise or-able with the horizontal scroll positions.
    // Combining positions from the same grouping (horizontal or vertical) will result in an NSInvalidArgumentException.
    UICollectionViewScrollPositionTop                  = 1 << 0,
    UICollectionViewScrollPositionCenteredVertically   = 1 << 1,
    UICollectionViewScrollPositionBottom               = 1 << 2,

    // Likewise, the horizontal positions are mutually exclusive to each other.
    UICollectionViewScrollPositionLeft                 = 1 << 3,
    UICollectionViewScrollPositionCenteredHorizontally = 1 << 4,
    UICollectionViewScrollPositionRight                = 1 << 5
};
```

而在`Swift 2.0`中，其定义如下：

``` objective-c
struct UICollectionViewScrollPosition : OptionSetType {
    init(rawValue: UInt)

    static var None: UICollectionViewScrollPosition { get }

    // The vertical positions are mutually exclusive to each other, but are bitwise or-able with the horizontal scroll positions.
    // Combining positions from the same grouping (horizontal or vertical) will result in an NSInvalidArgumentException.
    static var Top: UICollectionViewScrollPosition { get }
    static var CenteredVertically: UICollectionViewScrollPosition { get }
    static var Bottom: UICollectionViewScrollPosition { get }

    // Likewise, the horizontal positions are mutually exclusive to each other.
    static var Left: UICollectionViewScrollPosition { get }
    static var CenteredHorizontally: UICollectionViewScrollPosition { get }
    static var Right: UICollectionViewScrollPosition { get }
}
```

额，光看代码，不看实现，这也是化简为繁的节奏啊。

为什么要这样做呢？`Mattt`给了我们如下解释：

> Well, the same integer bitmasking tricks in C don't work for enumerated types in Swift. An `enum` represents a type with a closed set of valid options, without a built-in mechanism for representing a conjunction of options for that type. An `enum` could, ostensibly, define a case for all possible combinations of values, but for `n > 3`, the combinatorics make this approach untenable.

意思是`Swift`不支持`C`语言中枚举值的整型掩码操作的技巧。在`Swift`中，一个枚举可以表示一组有效选项的集合，但却没有办法支持这些选项的组合操作(“&”、”|”等)。理论上，一个枚举可以定义选项值的任意组合值，但对于`n > 3`这种操作，却无法有效的支持。

为了支持类`NS_OPTIONS`的枚举，`Swift 2.0`中定义了`OptionSetType`协议【在`Swift 1.2`中是使用`RawOptionSetType`，相比较而言已经改进了不少】，它的声明如下：

``` objective-c
/// Supplies convenient conformance to `SetAlgebraType` for any type
/// whose `RawValue` is a `BitwiseOperationsType`.  For example:
///
///     struct PackagingOptions : OptionSetType {
///       let rawValue: Int
///       init(rawValue: Int) { self.rawValue = rawValue }
///     
///       static let Box = PackagingOptions(rawValue: 1)
///       static let Carton = PackagingOptions(rawValue: 2)
///       static let Bag = PackagingOptions(rawValue: 4)
///       static let Satchel = PackagingOptions(rawValue: 8)
///       static let BoxOrBag: PackagingOptions = [Box, Bag]
///       static let BoxOrCartonOrBag: PackagingOptions = [Box, Carton, Bag]
///     }
///
/// In the example above, `PackagingOptions.Element` is the same type
/// as `PackagingOptions`, and instance `a` subsumes instance `b` if
/// and only if `a.rawValue & b.rawValue == b.rawValue`.
protocol OptionSetType : SetAlgebraType, RawRepresentable {

    /// An `OptionSet`'s `Element` type is normally `Self`.
    typealias Element = Self

    /// Convert from a value of `RawValue`, succeeding unconditionally.
    init(rawValue: Self.RawValue)
}
```

从字面上来理解，`OptionSetType`是选项集合类型，它定义了一些基本操作，包括集合操作(`union`, `intersect`, `exclusiveOr`)、成员管理(`contains`, `insert`, `remove`)、位操作(`unionInPlace`, `intersectInPlace`, `exclusiveOrInPlace`)以及其它的一些基本操作。

作为示例，我们来定义一个表示方向的选项集合，通常我们是定义一个实现`OptionSetType`协议的结构体，如下所示：

``` objective-c
struct Directions: OptionSetType {

    var rawValue:Int
    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let Up: Directions = Directions(rawValue: 1 << 0)
    static let Down: Directions = Directions(rawValue: 1 << 1)
    static let Left: Directions = Directions(rawValue: 1 << 2)
    static let Right: Directions = Directions(rawValue: 1 << 3)
}
```

所需要做的基本上就是这些。然后我们就可以创建`Directions`的实例了，如下所示：

``` objective-c
let direction: Directions = Directions.Left
if direction == Directions.Left {
    // ...
}
```

如果想同时支持两个方向，则可以如上处理：

``` objective-c
let leftUp: Directions = [Directions.Left, Directions.Up]
if leftUp.contains(Directions.Left) && leftUp.contains(Directions.Up) {
    // ...
}
```

如果`leftUp`同时包含`Directions.Left`和`Directions.Up`，则返回`true`。

这里还有另外一种方法来达到这个目的，就是我们在`Directions`结构体中直接声明声明`Left`和`Up`的静态常量，如下所示：

``` objective-c
struct Directions: OptionSetType {

    // ...
    static let LeftUp: Directions = [Directions.Left, Directions.Up]
    static let RightUp: Directions = [Directions.Right, Directions.Up]
    // ...
}
```

这样，我们就可以以如下方式来执行上面的操作：

``` objective-c
if leftUp == Directions.LeftUp {
    // ...
}
```

当然，如果单一选项较多，而要去组合所有的情况，这种方法就显示笨拙了，这种情况下还是推荐使用`contains`方法。

总体来说，`Swift`中的对选项的支持没有`Objective-C`中的`NS_OPTIONS`来得简洁方便。而且在`Swift 1.2`的时候，我们还是可以使用"&"和"|”操作符的。下面这段代码在`Swift 1.2`上是`OK`的：

``` objective-c
UIView.animateWithDuration(0.3, delay: 1.0, options: UIViewAnimationOptions.CurveEaseIn | UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
    // ...
}, completion: nil)
```

但到了`Swift 2.0`时，`OptionSetType`已经不再支持"&"和"|”操作了，因此，上面这段代码需要修改成：

``` objective-c
UIView.animateWithDuration(0.3, delay: 1.0, options: [UIViewAnimationOptions.CurveEaseIn, UIViewAnimationOptions.CurveEaseInOut], animations: { () -> Void in
        // ...
}, completion: nil)
```

不过，慢慢习惯就好。

### 参考

1. [RawOptionSetType](http://nshipster.com/rawoptionsettype/)
2. [Exploring Swift 2.0 OptionSetTypes](http://www.swift-studies.com/blog/2015/6/17/exploring-swift-20-optionsettypes)
3. [Notes from WWDC 2015: The Enumerated Delights of Swift 2.0 Option Sets](http://www.informit.com/articles/article.aspx?p=2420231)​
4. 《100个Swift开发必备Tip》— Tip 66. Options

## 零碎

### 静态分析中"Potential null dereference"的处理

我们在写一个方法时，如果希望在方法执行出错时，获取一个`NSError`对象，我们通常会像下面这样来定义我们的方法

``` objective-c
+ (NSString )checkStringLength:(NSString *)str error:(NSError **)error {

	if (str.length <= 0) {
	        *error = [NSError errorWithDomain:@"ErrorDomain" code:-1 userInfo:nil];
    	return nil;
	}

	return str;
}
```

这段代码看着没啥问题，至少在语法上是OK的，所以在编译时，编译器并不会报任何警告。

如果我们用以下方式去调用的话，也是一切正常的：

``` objective-c
NSError *error = nil;
[Test checkStringLength:@"" error:&error];
```

不过我们如果就静态分析器来分析一下，发现会在"`*error = ...`"这行代码处报如下的警告：

> Potential null dereference.  According to coding standards in 'Creating and Returning NSError Objects' the parameter may be null

这句话告诉我们的是这里可能存在空引用。实际上，如果我们像下面这样调用方法的话，程序是会崩溃的：

``` objective-c
[Test checkStringLength:@"" error:NULL];
```

因为此时在方法中，`error`实际上是`NULL`，`*error`这货啥也不是，对它赋值肯定就出错了。

这里正确的姿式是在使用`error`之前，先判断它是否为`NULL`，完整的代码如下：

``` objective-c
+ (NSString )checkStringLength:(NSString *)str error:(NSError **)error {

    if (str.length <= 0) {

        if (error != NULL) {
            *error = [NSError errorWithDomain:@"ErrorDomain" code:-1 userInfo:nil];
        }
        return nil;
    }
    return str;
}
```

实际上，对此这种方式的传值，我们始终需要去做非空判断。

### Charles支持iOS模拟器

咬咬牙花了50刀买了一个`Charles`的`License`。

今天临时需要在模拟器上跑工程，想抓一下数据包，看一下请求`Header`里面的信息。工程跑起来时，发现`Charles`没有抓取到数据。嗯，本着有问题先问`stackoverflow`的原则，跑到上面搜了一下。找到了这个贴子：[How to use Charles Proxy on the Xcode 6 (iOS 8) Simulator?](http://stackoverflow.com/questions/25439756/how-to-use-charles-proxy-on-the-xcode-6-ios-8-simulator)。不过我的处理没有他这么麻烦，基本上两步搞定了：

1.在`Charles`的菜单中选择`Help > SSL Proxying > Install Charles Root Certificate in iOS Simulators`，直接点击就行。这时候会弹出一个提示框，点击OK就行。

2.如果这时候还不能抓取数据，就重启模拟器。

这样就OK了。在`Keychain`里面，真机和模拟器的证书是同一个。

至于`stackoverflow`里面提到的在3.9.3版本上还需要覆盖一个脚本文件，这个没有尝试过，哈哈，我的是最新的3.10.2。

还有个需要注意的是，在抓取模拟器数据时，如果关闭`Charles`，那么模拟器将无法再请求到网络数据。这时需要重新开启`Charles`，或者是重启模拟器。另外如果重置了模拟器的设置(`Reset Content and Settings…`)，`Charles`也抓取不到模拟器的数据，需要重新来过。

#### 参考

1. [How to use Charles Proxy on the Xcode 6 (iOS 8) Simulator?](http://stackoverflow.com/questions/25439756/how-to-use-charles-proxy-on-the-xcode-6-ios-8-simulator)