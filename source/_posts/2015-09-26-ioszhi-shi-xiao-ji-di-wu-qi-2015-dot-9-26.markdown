---
layout: post
title: "iOS知识小集 第五期(2015.9.26)"
date: 2015-09-26 23:42:33 +0800
comments: true
categories: iOS
---

忽悠一个月又过去了，今年的9月还是挺精彩的。苹果发布`iPhone 6s`，`iPad Pro`，`iOS 9`，让我们又有很多活可做了；然后是`XCodeGoast`搅得圈内沸沸扬扬的，居然还惊动了`CCAV`；再然后苏宁的小伙伴们给大家送上了一份中秋礼物，虽然是老代码，但这是要搞哪样啊？不过，正是这些事情为我等屌丝的生活平添了许多的乐趣，还是挺酸爽的嘛。

嗯，回到正题上来。这期的知识小集主要是`Swift`开发的一些内容，主要的内容有三点：

1. `Swift`中随机数的使用
2. `Swift`中`String`与`CChar`数组的转换
3. `Swift`中`Selector`方法的访问权限控制问题

相对`Objective-C`来说，个人觉得`Swift`写起来大多数时候还是挺爽的，简洁多了，以后有事没事还是多撸撸`Swift`。

## Swift中随机数的使用

在我们开发的过程中，时不时地需要产生一些随机数。这里我们总结一下`Swift`中常用的一些随机数生成函数。这里我们将在`Playground`中来做些示例演示。

### 整型随机数

如果我们想要一个整型的随机数，则可以考虑用`arc4random`系列函数。我们可以通过`man arc4random`命令来看一下这个函数的定义：

> The arc4random() function uses the key stream generator employed by the arc4 cipher, which uses 8\*8 8 bit S-Boxes.  The S-Boxes can be inabout (2^1700) states.  The arc4random() function returns pseudo-random numbers in the range of 0 to (2^32)-1, and therefore has twice the range of rand(3) and random(3).

`arc4random`使用了`arc4密码`加密的`key stream`生成器(请脑补)，产生一个`[0, 2^32)`区间的随机数(注意是左闭右开区间)。这个函数的返回类型是`UInt32`。如下所示：

``` objective-c
arc4random()				// 2,919,646,954
```

如果我们想生成一个指定范围内的整型随机数，则可以使用`arc4random() % upper_bound`的方式，其中`upper_bound`指定的是上边界，如下处理：

``` objective-c
arc4random() % 10			// 8 
```

不过使用这种方法，在`upper_bound`不是2的幂次方时，会产生一个所谓[Modulo bias(模偏差)](http://eternallyconfuzzled.com/arts/jsw_art_rand.aspx)的问题。

我们在控制台中通过`man arc4random`命令，可以查看`arc4random`的文档，有这么一条：

> arc4random_uniform() will return a uniformly distributed random number less than upper_bound.  arc4random_uniform() is recommended over constructions like ''arc4random() % upper_bound'' as it avoids "modulo bias" when the upper bound is not a power of two.

因此可以使用`arc4random_uniform`，它接受一个`UInt32`类型的参数，指定随机数区间的上边界`upper_bound`，该函数生成的随机数范围是`[0, upper_bound)`，如下所示：

``` objective-c
arc4random_uniform(10)		// 6
```

而如果想指定区间的最小值（如随机数区间在`[5, 100)`），则可以如下处理：

``` objective-c
let max: UInt32 = 100
let min: UInt32 = 5
arc4random_uniform(max - min) + min			// 82
```

当然，在`Swift`中也可以使用传统的`C`函数`rand`与`random`。不过这两个函数有如下几个缺点：

1. 这两个函数都需要初始种子，通常是以当前时间来确定。
2. 这两个函数的上限在`RAND_MAX=0X7fffffff(2147483647)`，是`arc4random`的一半。
3. `rand`函数以有规律的低位循环方式实现，更容易预测

我们以`rand`为例，看看其使用：

``` objective-c
srand(UInt32(time(nil)))            // 种子,random对应的是srandom
rand()								// 1,314,695,483
rand() % 10							// 8
```

### 64位整型随机数

在大部分应用中，上面讲到的几个函数已经足够满足我们获取整型随机数的需求了。不过我们看看它们的函数声明，可以发现这些函数主要是针对`32`位整型来操作的。如果我们需要生成一个`64`位的整型随机数呢？毕竟现在的新机器都是支持`64`位的了。

目前貌似没有现成的函数来生成`64`位的随机数，不过`jstn`在`stackoverflow`上为我们分享了他的方法。我们一起来看看。

他首先定义了一个泛型函数，如下所示：

``` objective-c
func arc4random <T: IntegerLiteralConvertible> (type: T.Type) -> T {
    var r: T = 0
    arc4random_buf(&r, UInt(sizeof(T)))
    return r
}
```

这个函数中使用了`arc4random_buf`来生成随机数。让我们通过`man arc4random_buf`来看看这个函数的定义：

> arc4random_buf() function fills the region buf of length nbytes with ARC4-derived random data.

这个函数使用`ARC4`加密的随机数来填充该函数第二个参数指定的长度的缓存区域。因此，如果我们传入的是`sizeof(UInt64)`，该函数便会生成一个随机数来填充`8`个字节的区域，并返回给`r`。那么`64`位的随机数生成方法便可以如下实现：

``` objective-c
extension UInt64 {
    static func random(lower: UInt64 = min, upper: UInt64 = max) -> UInt64 {
        var m: UInt64
        let u = upper - lower
        var r = arc4random(UInt64)

        if u > UInt64(Int64.max) {
            m = 1 + ~u
        } else {
            m = ((max - (u * 2)) + 1) % u
        }

        while r < m {
            r = arc4random(UInt64)
        }

        return (r % u) + lower
    }
}
```

我们来试用一下：

``` objective-c
UInt64.random()					// 4758246381445086013
```

当然`jstn`还提供了`Int64`，`UInt32`，`Int32`的实现，大家可以脑补一下。

### 浮点型随机数

如果需要一个浮点值的随机数，则可以使用`drand48`函数，这个函数产生一个`[0.0, 1.0]`区间中的浮点数。这个函数的返回值是`Double`类型。其使用如下所示：

``` objective-c
srand48(Int(time(nil)))
drand48()						// 0.396464773760275
```

记住这个函数是需要先调用`srand48`生成一个种子的初始值。

### 一个小示例

最近写了一个随机键盘，需要对`0-9`这几个数字做个随机排序，正好用上了上面的`arc4random`函数，如下所示：

``` objective-c
let arr = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

let numbers = arr.sort { (_, _) -> Bool in
    arc4random() < arc4random()
}
```

在闭包中，随机生成两个数，比较它们之间的大小，来确定数组的排序规则。还是挺简单的。

### 小结

其实如果翻看一下`Swift`中关于`C`函数的`API`，发现还有许多跟随机数相关的函数，如`arc4random_addrandom`，`erand48`等。上面的只是我们经常用到的一些函数，这几个函数基本上够用了。当然，不同场景有不同的需求，我们需要根据实际的需求来选择合适的函数。

以上的代码已上传到`github`，地址是[Random.playground](https://github.com/southpeak/Swift/tree/master/Basic/Random.playground)有需要的可以参考一下。

### 参考

1. [rand(3) / random(3) / arc4random(3) / et al.](http://nshipster.com/random/)
2. [Random Swift](https://medium.com/@skreutzb/random-swift-102c23cd1755)
3. [How does one generate a random number in Apple's Swift language?](http://stackoverflow.com/questions/24007129/how-does-one-generate-a-random-number-in-apples-swift-language)

## Swift中String与CChar数组的转换

在现阶段`Swift`的编码中，我们还是有很多场景需要调用一些`C`函数。在`Swift`与`C`的混编中，经常遇到的一个问题就是需要在两者中互相转换字符串。在`C`语言中，字符串通常是用一个`char数组`来表示，在`Swift`中，是用`CChar数组`来表示。从`CChar`的定义可以看到，其实际上是一个`Int8`类型，如下所示：

``` objective-c
/// The C 'char' type.
///
/// This will be the same as either `CSignedChar` (in the common
/// case) or `CUnsignedChar`, depending on the platform.
public typealias CChar = Int8
```

如果我们想将一个`String`转换成一个`CChar数组`，则可以使用`String`的`cStringUsingEncoding`方法，它是`String`扩展中的一个方法，其声明如下：

``` objective-c
/// Returns a representation of the `String` as a C string
/// using a given encoding.
@warn_unused_result
public func cStringUsingEncoding(encoding: NSStringEncoding) -> [CChar]?
```

参数指定的是编码格式，我们一般指定为`NSUTF8StringEncoding`，因此下面这段代码：

``` objective-c
let str: String = "abc1个"

// String转换为CChar数组
let charArray: [CChar] = str.cStringUsingEncoding(NSUTF8StringEncoding)!
```

其输出结果是：

``` objective-c
[97, 98, 99, 49, -28, -72, -86, 0]
```

可以看到`"个"`字由三个字节表示，这是因为`Swift`的字符串是`Unicode`编码格式，一个字符可能由1个或多个字节组成。另外需要注意的是`CChar`数组的最后一个元素是`0`，它表示的是一个字符串结束标志符`\n`。

我们知道，在`C`语言中，一个数组还可以使用指针来表示，所以字符串也可以用`char *`来表示。在`Swift中`，指针是使用`UnsafePointer`或`UnsafeMutablePointer`来包装的，因此，`char指针`可以表示为`UnsafePointer<CChar>`，不过它与`[CChar]`是两个不同的类型，所以以下代码会报编译器错误：

``` objective-c
// Error: Cannot convert value of type '[CChar]' to specified type 'UnsafePointer<CChar>'
let charArray2: UnsafePointer<CChar> = str.cStringUsingEncoding(NSUTF8StringEncoding)!
```

不过有意思的是我们可以直接将`String`字符串传递给带有`UnsafePointer<CChar>`参数的函数或方法，如以下代码所示：

``` objective-c
func length(s: UnsafePointer<CChar>) {
    print(strlen(s))
}

length(str)

// 输出：7\n
```

而`String`字符串却不能传递给带有`[CChar]`参数的函数或方法，如以下代码会报错误：

``` objective-c
func length2(s: [CChar]) {
    print(strlen(s))
}

// Error: Cannot convert value of type 'String' to expected argument type '[CChar]'
length2(str)
```

实际上，在`C`语言中，我们在使用数组参数时，很少以数组的形式来定义参数，则大多是通过指针方式来定义数组参数。

如果想从`[CChar]`数组中获取一上`String`字符串，则可以使用`String`的`fromCString`方法，其声明如下：

``` objective-c
/// Creates a new `String` by copying the nul-terminated UTF-8 data
/// referenced by a `CString`.
///
/// Returns `nil` if the `CString` is `NULL` or if it contains ill-formed
/// UTF-8 code unit sequences.
@warn_unused_result
public static func fromCString(cs: UnsafePointer<CChar>) -> String?
```

从注释可以看到，它会将`UTF-8`数据拷贝以新字符串中。如下示例：

``` objective-c
let chars: [CChar] = [99, 100, 101, 0]
let str2: String = String.fromCString(chars)!

// 输出：cde
```

这里需要注意的一个问题是，`CChar`数组必须以`0`结束，否则会有不可预料的结果。在我的`Playground`示例代码中，如果没有`0`，报了以下错误：

``` objective-c
Execution was interrupted. reason: EXC_BAD_INSTRUCTION
```

还有可能出现的情况是`CChar`数组的存储区域正好覆盖了之前某一对象的区域，这一对象有一个可以表示字符串结尾的标识位，则这时候，`str2`输出的可能是`"cde1一"`。

### 小结

在`Swift`中，`String`是由独立编码的`Unicode`字符组成的，即`Character`。一个`Character`可能包括一个或多个字节。所以将`String`字符串转换成`C`语言的`char *`时，数组元素的个数与`String`字符的个数不一定相同(即在`Swift`中，与`str.characters.count`计算出来的值不一定相等)。这一点需要注意。另外还需要注意的就是将`CChar`数组转换为`String`时，数组最后一个元素应当为字符串结束标志符，即`0`。

### 参考

1. [UTF8String](https://forums.developer.apple.com/thread/9386)
2. [String Structure Reference](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Reference/Swift_String_Structure/#//apple_ref/swift/structcm/String/s:ZFSS11fromCStringFMSSFGVSs13UnsafePointerVSs4Int8_GSqSS_)
3. [The Swift Programming Language中文版](http://wiki.jikexueyuan.com/project/swift/chapter2/03_Strings_and_Characters.html#counting_characters)

## Swift中Selector方法的访问权限控制问题

今天用`Swift`写了个视图，在视图上加个手势，如下所示：

``` objective-c
panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "beginDragged:")
addGestureRecognizer(panGestureRecognizer)
```

运行了下程序，然后崩溃了。崩溃日志如下：

``` objective-c
[**.SwipeCardView beginDragged:]: unrecognized selector sent to instance 0x125e5bc10
```

而我已经在`SwipeCardView`类中定义了`beginDragged:`方法，如下所示：

``` objective-c
private func beginDragged(gestureRecognizer: UIPanGestureRecognizer) {
	// ....
}
```

由于我并不想将`beginDragged:`方法暴露出去，所以将其定义为一个`private`方法。方法的定义一切正常，手势的`Selector`方法也设置正常，却报了未找到方法的异常。那问题可能就应该在访问权限问题上了。

我们知道`Selector`是`Objective-C`的产物，它用于在运行时作为一个键值去找到对应方法的实现。一个`Objective-C`的方法是由`objc_method`结束体定义的，其声明如下：

``` objective-c
struct objc_method {

    SEL method_name                 	OBJC2_UNAVAILABLE;  // 方法名
    char *method_types                  OBJC2_UNAVAILABLE;
    IMP method_imp                      OBJC2_UNAVAILABLE;  // 方法实现
}  
```

这就要求`selector`引用的方法必须对`ObjC`运行时是可见的。而`Swift`是静态语言，虽然继承自`NSObject`的类默认对`ObjC`运行时是可见的，但如果方法是由`private`关键字修饰的，则方法默认情况下对`ObjC`运行时并不是可见的，所以就导致了以上的异常：运行时并没找到`SwipeCardView`类的`beginDragged:`方法。

所以，我们必须将`private`修饰的方法暴露给运行时。正确的做法是在 `private` 前面加上 `@objc` 关键字，这样就OK了。

``` objective-c
@objc private func beginDragged(gestureRecognizer: UIPanGestureRecognizer) {
	// ....
}
```

另外需要注意的是，如果我们的类是纯`Swift`类，而不是继承自`NSObject`，则不管方法是`private`还是`internal`或`public`，如果要用在`Selector`中，都需要加上`@objc`修饰符。

### 参考

1. [SELECTOR](http://swifter.tips/selector/)
2. [@selector() in Swift?](http://stackoverflow.com/questions/24007650/selector-in-swift)

## 零碎

### Swift中枚举项设置相同的值

在`Objective-C`及`C`语言中，在枚举中我们可以设置两个枚举项的值相等，如下所示：

``` objective-c
typedef NS_ENUM(NSUInteger, Type) {
    TypeIn      = 0,
    TypeOut     = 1,
    TypeInOut   = 2,
    TypeDefault = TypeIn
};
```

在上例中，我们让枚举项`TypeDefault`的值等于`TypeIn`。

而在`Swift`中，要求枚举项的`rawValue`是唯一的，如果像下面这样写，则编译器会报错：

``` objective-c
enum Type: UInt {
    case In         = 0
    case Out        = 1
    case InOut      = 2
    case Default    = 0		// Error: Raw value for enum case is not unique
}
```

那如果我们希望上面枚举中`Default`的值与`In`的值一样，那应该怎么做呢？这时候就需要充分利用`Swift`中`enum`的特性了。我们知道，`Swift`中的`enum`与结构体、类一样，可以为其定义属性和方法，所以我们可以如下处理：

``` objective-c
enum Type: UInt {
    case In         = 0
    case Out        = 1
    case InOut      = 2

    static var Default: Type {
        get {
            return .In
        }
    }
}
```

我们将`Default`定义为`Type`的一个静态只读属性，这个属性与枚举的其它枚举项的调用方式是一样的，可以如下调用：

``` objective-c
let type: Type = .Default
```

#### 参考

1. [Swift enum multiple cases with the same value](http://stackoverflow.com/questions/28037772/swift-enum-multiple-cases-with-the-same-value)

### Swift中如何实现IBOutletCollection

在使用IB做界面开发时，我们经常需要将界面上的元素连接到我们的代码中。`IBOutlet`和`IBAction`就是专门用来做这事的两个关键字。另外在`Objective-C`还提供了一个伪关键字`IBOutletCollection`，它的实际作用是将界面上的一组相同的控件连接到一个数组中。具体可以参考[iOS知识小集 第一期(2015.05.10)](http://southpeak.github.io/blog/2015/05/10/ioszhi-shi-xiao-ji-di-%5B%3F%5D-qi-2015-dot-05-dot-10/)中的`IBOutletCollection`一节。

在`Swift`中，同样提供了`@IBOutlet`和`@IBAction`实现`Objective-C`中对应的功能，不过却没提供`@IBOutletCollection`来将一组相同控件连接到一个数组中。那如果我们想实现类似的功能，需要怎么处理呢？

实际上，我们在IB中选中一组相同的控件，然后将其连到到代码中时，会生成一个`IBOutlet`修饰的控件数组，类似于如下代码：

``` objective-c
@IBOutlet var numberButtons: [UIButton]!
```

这就是`Swift`中类`IBOutletCollection`的处理。如果需要往数组中添加新建的对应的控件，则只需要在代码前面的小圆点与UI上的控件做个连线就OK了。而如果要想将控件从数组中移除，则只需要将对应的连接关系移除就可以了。

#### 参考

1. [iOS知识小集 第一期(2015.05.10)](http://southpeak.github.io/blog/2015/05/10/ioszhi-shi-xiao-ji-di-%5B%3F%5D-qi-2015-dot-05-dot-10/)
2. [Swift - IBOutletCollection equivalent](http://stackoverflow.com/questions/24052459/swift-iboutletcollection-equivalent)