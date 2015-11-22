---
layout: post
title: "使用_ObjectiveCBridgeable协议实现Objective-C类与Swift结构体的无缝互转"
date: 2015-10-26 10:33:22 +0800
comments: true
categories: swift ios
---



我们知道在`Swift`中，可以在`NSArray`与`Array`之间做无缝的转换，如下所示：

``` objective-c
let mobile = ["iPhone", "Nokia", "小米Note"]
let mobile1 = (mobile as NSArray).objectAtIndex(1)
print(mobile1)

let animalArray = NSArray(objects: "lion", "tiger", "monkey")
var animalCount = (animalArray as Array).count
print(animalCount)

// 输出
// "Nokia"
// ["lion", "tiger", "monkey"]
```

编译器会为了我们完成所有转换，我们只需要拿来即用就行。当然，除了数组外，还有字典(`Dictionary`)、集合(`Set`)、字符串(`String`)也是一样。

## 问题

不过仔细一想，会发现，`NSArray`是类类型，而`Array`是结构体类型。一个是引用类型，一个是值类型，它们是怎样实现无缝转换的呢？这让我们想到了`Cocoa Foundation`与`Core Foundation`之间转换的`toll-free bridging`技术。那`NSArray`与`Array`之间是不是也应该有类似的桥接实现呢？

## Objective-C Bridge

我们将鼠标移动到`Array`上，然后`"cmd+鼠标点击"`，进入到`Swift`的声明文件中，在`Array`的注释中，可以看到下面这段：

``` objective-c
/// Objective-C Bridge
/// ==================
/// The main distinction between Array and the other array types is that it interoperates seamlessly and efficiently with Objective-C.
/// Array<Element> is considered bridged to Objective-C iff Element is bridged to Objective-C.

// ......
```

可以看到`Array`与`Objective-C`的数组之间确实存在某种桥接技术，我们暂且称之为`"Objective-C Bridge"`桥接。那这又是如何实现的呢？

我们在当前文件中搜索`bridge`，会发现有这样一个协议：`_ObjectiveCBridgeable`。我们先来看看它的声明：

``` objective-c
/// A Swift Array or Dictionary of types conforming to `_ObjectiveCBridgeable` can be passed to Objective-C as an NSArray or NSDictionary, respectively. The elements of the resulting NSArray or NSDictionary will be the result of calling `_bridgeToObjectiveC` on each element of the source container.
public protocol _ObjectiveCBridgeable {
}
```

即一个`Swift`数组或字典，如果其元素类型实现了`_ObjectiveCBridgeable`协议，则该数组或字典可以被转换成`Objective-C`的数组或字典。对于`_ObjectiveCBridgeable`协议，我们目前所能得到的文档就只有这些，也看不到它里面声明了什么属性方法。不过，可以看到这个协议是访问控制权限是`public`，也就意味着可以定义类来实现这个接口。这就好办了，下面就来尝试实现这样一个转换。

## Objective-C类与Swift结构体的互转示例

在此先定义一个`Objective-C`类，如下所示：

``` objective-c
// Mobile.h
@interface Mobile : NSObject

@property (nonatomic, strong) NSString *brand;
@property (nonatomic, strong) NSString *system;

- (instancetype)initWithBrand:(NSString *)brand system:(NSString *)system;

@end

// Mobole.m
@implementation Mobile

- (instancetype)initWithBrand:(NSString *)brand system:(NSString *)system {

    self = [super init];

    if (self) {
        _brand = brand;
        _system = system;
    }

    return self;
}

@end
```

同样，我定义一个`Swift`结构体，如下所示：

``` objective-c
struct SwiftMobile {

    let brand: String
    let system: String
}
```

要想实现`Mobile`类与`SwiftMobile`结构体之间的互转，则`SwiftMobile`结构体需要实现`_ObjectiveCBridgeable`协议，如下所示：

``` objective-c
extension SwiftMobile: _ObjectiveCBridgeable {

    typealias _ObjectiveCType = Mobile

    // 判断是否能转换成Objective-C对象
    static func _isBridgedToObjectiveC() -> Bool {
        return true
    }

    // 获取转换的目标类型
    static func _getObjectiveCType() -> Any.Type {
        return _ObjectiveCType.self
    }

    // 转换成Objective-C对象
    func _bridgeToObjectiveC() -> _ObjectiveCType {
        return Mobile(brand: brand, system: system)
    }

    // 强制将Objective-C对象转换成Swift结构体类型
    static func _forceBridgeFromObjectiveC(source: _ObjectiveCType, inout result: SwiftMobile?) {
        result = SwiftMobile(brand: source.brand, system: source.system)
    }

    // 有条件地将Objective-C对象转换成Swift结构体类型
    static func _conditionallyBridgeFromObjectiveC(source: _ObjectiveCType, inout result: SwiftMobile?) -> Bool {

        _forceBridgeFromObjectiveC(source, result: &result)

        return true
    }
}
```

可以看到`SwiftMobile`结构体主要实现了`_ObjectiveCBridgeable`接口的`5`个方法，从方法名基本上就能知道每个方法的用途。这里需要注意的是在本例中的`_conditionallyBridgeFromObjectiveC`只是简单地调用了`_forceBridgeFromObjectiveC`，如果需要指定条件，则需要更详细的实现。

让我们来测试一下：

``` objective-c
let mobile = Mobile(brand: "iPhone", system: "iOS 9.0")

let swiftMobile = mobile as SwiftMobile
print("\(swiftMobile.brand): \(swiftMobile.system)")

let swiftMobile2 = SwiftMobile(brand: "Galaxy Note 3 Lite", system: "Android 5.0")
let mobile2 = swiftMobile2 as Mobile
print("\(mobile2.brand): \(mobile2.system)")

// 输出:
// iPhone: iOS 9.0
// Galaxy Note 3 Lite: Android 5.0
```

可以看到只需要使用`as`，就能实现`Mobile`类与`SwiftMobile`结构体的无缝转换。是不是很简单？

## 集合类型的无缝互换

回到数组的议题上来。

我们知道`NSArray`的元素类型必须是类类型的，它不支持存储结构体、数值等类型。因此，`Array`转换成`NSArray`的前提是`Array`的元素类型能被`NSArray`所接受。如果存储在`Array`中的元素的类型是结构体，且该结构体实现了`_ObjectiveCBridgeable`接口，则转换成`NSArray`时，编译器会自动将所有的元素转换成对应的类类型对象。以上面的`SwiftMobile`为例，看如下代码：

``` objective-c
let sm1 = SwiftMobile(brand: "iPhone", system: "iOS 9.0")
let sm2 = SwiftMobile(brand: "Galaxy Note 3", system: "Android 5.0")
let sm3 = SwiftMobile(brand: "小米", system: "Android 4.0")

let mobiles = [sm1, sm2, sm3]

let mobileArray = mobiles as NSArray
print(mobileArray)
for i in 0..<mobiles.count {
    print("\(mobileArray.objectAtIndex(i).brand): \(mobileArray.objectAtIndex(i).system)")
}

// 输出：
// (
//    "<Mobile: 0x100c03f30>",
//    "<Mobile: 0x100c03940>",
//    "<Mobile: 0x100c039c0>"
// )
// iPhone: iOS 9.0
// Galaxy Note 3: Android 5.0
// 小米: Android 4.0
```

可以看到打印`mobileArray`数组时，其元素已经转换成了类`Mobile`的对象。一切都是那么的自然。而如果我们的`SwiftMobile`并没有实现`_ObjectiveCBridgeable`接口，则会报编译器错误：

``` objective-c
'[SwiftMobile]' is not convertible to 'NSArray'
```

实际上，像`Bool`，`Int`， `UInt`，`Float`，`Double`，`CGFloat`这些数值类型也实现了`_ObjectiveCBridgeable`接口。我们可以从文档[OS X v10.11 API Diffs - Swift Changes for Swift](https://developer.apple.com/library/prerelease/mac/releasenotes/General/APIDiffsMacOSX10_11/Swift/Swift.html)中找到一些线索：

``` objective-c
extension Bool : _ObjectiveCBridgeable {
    init(_ number: NSNumber)
}

extension Int : _ObjectiveCBridgeable {
    init(_ number: NSNumber)
}

extension Float : _ObjectiveCBridgeable {
    init(_ number: NSNumber)
}

// ... Double, UInt ...
```

*(注意：整型类型只有`Int`与`UInt`实现了接口，而其它诸如`Int16`，`Uint32`，`Int8`等则没有）*

它们的目标类型都是`NSNumber`类型，如下代码所示：

``` objective-c
let numbers = [1, 29, 40]
let numberArray = (numbers as NSArray).objectAtIndex(2)

print(numberArray.dynamicType)

// 输出:
// __NSCFNumber
```

当然，要想实现`Array`与`NSArray`无缝切换，除了元素类型需要支持这种操作外，`Array`本身也需要能支持`Objective-C Bridge`，即它也需要实现`_ObjectiveCBridgeable`接口。在`Swift`文件的`Array`声明中并没有找到相关的线索：

``` objective-c
public struct Array<Element> : CollectionType, Indexable, SequenceType, MutableCollectionType, MutableIndexable, _DestructorSafeContainer
```

线索依然在[OS X v10.11 API Diffs - Swift Changes for Swift](https://developer.apple.com/library/prerelease/mac/releasenotes/General/APIDiffsMacOSX10_11/Swift/Swift.html)中，有如下声明：

``` objective-c
extension Array : _ObjectiveCBridgeable {
    init(_fromNSArray source: NSArray, noCopy noCopy: Bool = default)
}
```

因此，`Array`与`NSArray`相互转换需要两个条件：

1. `Array`自身实现`Objective-C Bridge`桥接，这个`Swift`已经帮我们实现了。
2. `Array`中的元素如果是数值类型或结构类型，必须实现`Objective-C Bridge`桥接。而如果是类类型或者是`@objc protocol`类型，则不管这个类型是`Objective-C`体系中的，还是纯`Swift`类型(不继承自`NSObject`)，都可以直接转换。

另外，`Array`只能转换成`NSArray`，而不能转换成`NSArray`的子类，如`NSMutableArray`或`NSOrderedArray`。如下所示：

``` objective-c
var objects = [NSObject(), NSObject(), NSObject()]
var objectArray = objects as NSMutableArray

// 编译器错误：
// '[NSObject]' is not convertible to 'NSMutableArray'
```

当然，反过来却是可以的。这个应该不需要太多的讨论。

## 小结

在`Swift`中，我们更多的会使用`Array`，`Dictionary`，`Set`这几个集合类型来存储数据，当然也会遇到需要将它们与`Objective-C`中对应的集合类型做转换的情况，特别是在混合编程的时候。另外，`String`也是可能经常切换的一个地方。不过，`Apple`已经帮我们完成了大部分的工作。如果需要实现自定义的结构体类型与`Objective-C`类的切换，则可以让结构体实现`_ObjectiveCBridgeable`接口。

这里还有个小问题，在`Objective-C`中实际上是有两个类可以用来包装数值类型的值：`NSNumber`与`NSValue`。`NSNumber`我们就不说了，`NSValue`用于包装诸如`CGPoint`，`CGSize`等，不过`Swift`并没有实现`CGPoint`类的值到`NSValue`的转换，所以这个需要我们自己去处理。

在`Swift`与`Objective-C`的集合类型相互转换过程中，还涉及到一些性能问题，大家可以看看对应的注释说明。在后续的文章中，会涉及到这一主题。

本文的部分实例代码已上传至`github`，可以在[这里](https://github.com/southpeak/Swift/tree/master/Basic/ObjectiveCBridgeable)下载。

## 参考

1. [Easy Cast With _ObjectiveCBridgeable](http://nshint.io/blog/2015/10/07/easy-cast-with-_ObjectiveCBridgeable/?utm_campaign=Swift%2BSandbox&utm_medium=web&utm_source=Swift_Sandbox_11)
2. [OS X v10.11 API Diffs - Swift Changes for Swift]((https://developer.apple.com/library/prerelease/mac/releasenotes/General/APIDiffsMacOSX10_11/Swift/Swift.html)

