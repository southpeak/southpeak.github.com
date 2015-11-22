---
layout: post
title: "iOS知识小集 第二期(2015.05.31)"
date: 2015-05-31 23:50:54 +0800
comments: true
categories: techset ios
---

换了个厂子，还不到1个月。哎，着实是累啊，基本上是996.5的节奏，只会更多。加班把我快加吐了，但人在江湖，身不由已啊。为了讨口饭吃，命也不要了。谁让咱只是个臭写代码的呢。不过加班是多，只是长得太丑，所有没办法，没时间也得抽时间来学习。不然，饭都没得吃了，还得养家糊口呢。

本期总结的内容不是很多，主要有以下几个问题：

1. 使用`UIVisualEffectView`为视图添加特殊效果
2. `Nullability Annotations`
3. `weak`的生命周期

## 使用UIVisualEffectView为视图添加特殊效果

在`iOS 8`后，苹果开放了不少创建特效的接口，其中就包括创建毛玻璃(`blur`)的接口。

通常要想创建一个特殊效果(如`blur`效果)，可以创建一个`UIVisualEffectView`视图对象，这个对象提供了一种简单的方式来实现复杂的视觉效果。这个可以把这个对象看作是效果的一个容器，实际的效果会影响到该视图对象底下的内容，或者是添加到该视图对象的`contentView`中的内容。

我们举个例子来看看如果使用`UIVisualEffectView`：

``` objective-c
let bgView: UIImageView = UIImageView(image: UIImage(named: "visual"))
bgView.frame = self.view.bounds
self.view.addSubview(bgView)

let blurEffect: UIBlurEffect = UIBlurEffect(style: .Light)
let blurView: UIVisualEffectView = UIVisualEffectView(effect: blurEffect)
blurView.frame = CGRectMake(50.0, 50.0, self.view.frame.width - 100.0, 200.0)
self.view.addSubview(blurView)
```

这段代码是在当前视图控制器上添加了一个`UIImageView`作为背景图。然后在视图的一小部分中使用了`blur`效果。其效果如下所示：

![image](https://github.com/southpeak/Blog-images/blob/master/blur%20effect.png?raw=true)

我们可以看到`UIVisualEffectView`还是非常简单的。需要注意是的，不应该直接添加子视图到`UIVisualEffectView`视图中，而是应该添加到`UIVisualEffectView`对象的`contentView`中。

另外，尽量避免将`UIVisualEffectView`对象的`alpha`值设置为小于`1.0`的值，因为创建半透明的视图会导致系统在离屏渲染时去对`UIVisualEffectView`对象及所有的相关的子视图做混合操作。这不但消耗`CPU/GPU`，也可能会导致许多效果显示不正确或者根本不显示。

我们在上面看到，初始化一个`UIVisualEffectView`对象的方法是`UIVisualEffectView(effect: blurEffect)`，其定义如下：

``` objective-c
init(effect effect: UIVisualEffect)
```

这个方法的参数是一个`UIVisualEffect`对象。我们查看官方文档，可以看到在UIKit中，定义了几个专门用来创建视觉特效的，它们分别是`UIVisualEffect`、`UIBlurEffect`和`UIVibrancyEffect`。它们的继承层次如下所示：

``` objective-c
NSObject
	| -- UIVisualEffect
		| -- UIBlurEffect
		| -- UIVibrancyEffect
```

`UIVisualEffect`是一个继承自`NSObject`的创建视觉效果的基类，然而这个类除了继承自`NSObject`的属性和方法外，没有提供任何新的属性和方法。其主要目的是用于初始化`UIVisualEffectView`，在这个初始化方法中可以传入`UIBlurEffect`或者`UIVibrancyEffect`对象。

一个`UIBlurEffect`对象用于将`blur`(毛玻璃)效果应用于`UIVisualEffectView`视图下面的内容。如上面的示例所示。不过，这个对象的效果并不影响`UIVisualEffectView`对象的`contentView`中的内容。

`UIBlurEffect`主要定义了三种效果，这些效果由枚举`UIBlurEffectStyle`来确定，该枚举的定义如下：

``` objective-c
enum UIBlurEffectStyle : Int {
    case ExtraLight
    case Light
    case Dark
}
```

其主要是根据色调(`hue`)来确定特效视图与底部视图的混合。

与`UIBlurEffect`不同的是，`UIVibrancyEffect`主要用于放大和调整`UIVisualEffectView`视图下面的内容的颜色，同时让`UIVisualEffectView`的`contentView`中的内容看起来更加生动。通常`UIVibrancyEffect`对象是与`UIBlurEffect`一起使用，主要用于处理在`UIBlurEffect`特效上的一些显示效果。接上面的代码，我们看看在blur的视图上添加一些新的特效，如下代码所示：

``` objective-c
let vibrancyView: UIVisualEffectView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: blurEffect))
vibrancyView.setTranslatesAutoresizingMaskIntoConstraints(false)
blurView.contentView.addSubview(vibrancyView)

var label: UILabel = UILabel()
label.setTranslatesAutoresizingMaskIntoConstraints(false)
label.text = "Vibrancy Effect"
label.font = UIFont(name: "HelveticaNeue-Bold", size: 30)
label.textAlignment = .Center
label.textColor = UIColor.whiteColor()
vibrancyView.contentView.addSubview(label)
```

其效果如下图所示：

![image](https://github.com/southpeak/Blog-images/blob/master/Vibrancy%20effect.png?raw=true)

`vibrancy`特效是取决于颜色值的。所有添加到`contentView`的子视图都必须实现`tintColorDidChange`方法并更新自己。需要注意的是，我们使用`UIVibrancyEffect(forBlurEffect:)`方法创建`UIVibrancyEffect`时，参数`blurEffect`必须是我们想加效果的那个`blurEffect`，否则可能不是我们想要的效果。

另外，`UIVibrancyEffect`还提供了一个类方法`notificationCenterVibrancyEffect`，其声明如下：

``` objective-c
class func notificationCenterVibrancyEffect() -> UIVibrancyEffect!
```

这个方法创建一个用于通知中心的`Today`扩展的`vibrancy`特效。

### 参考

1. [UIVisualEffectView Class Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIVisualEffectView/)
2. [UIVisualEffect Class Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIVisualEffect_class/index.html#//apple_ref/occ/cl/UIVisualEffect)
3. [UIBlurEffect Class Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIVisualEffect_class/index.html#//apple_ref/occ/cl/UIVisualEffect)
4. [UIVibrancyEffect Class Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIVibrancyEffect/)
5. [UIVisualEffect – Swift Tutorial](http://swiftoverload.com/tag/uivisualeffectview/)
6. [iOS 8: UIVisualEffect](http://idrawcode.tumblr.com/post/101925733632/ios-8-uivisualeffect)

## Pointer is missing a nullability type specifier (__nonnull or __nullable)问题的处理 -- Nullability Annotations

最近在用`Xcode 6.3`写代码，一些涉及到对象的代码会报如下编译器警告：

``` objective-c
Pointer is missing a nullability type specifier (_nonnull or _nullable)
```

于是`google`了一下，发现这是`Xcode 6.3`的一个新特性，即**nullability annotations**。

### Nullability Annotations

我们都知道在`swift`中，可以使用`!`和`?`来表示一个对象是`optional`的还是`non-optional`，如`view?`和`view!`。而在`Objective-C`中则没有这一区分，`view`即可表示这个对象是`optional`，也可表示是`non-optional`。这样就会造成一个问题：在`Swift`与`Objective-C`混编时，`Swift`编译器并不知道一个`Objective-C`对象到底是`optional`还是`non-optional`，因此这种情况下编译器会隐式地将`Objective-C`的对象当成是`non-optional`。

为了解决这个问题，苹果在`Xcode 6.3`引入了一个`Objective-C`的新特性：`nullability annotations`。这一新特性的核心是两个新的类型注释：**\_\_nullable**和**\_\_nonnull**。从字面上我们可以猜到，**\_\_nullable**表示对象可以是`NULL`或`nil`，而**\_\_nonnull**表示对象不应该为空。当我们不遵循这一规则时，编译器就会给出警告。

我们来看看以下的实例，

``` objective-c
@interface TestNullabilityClass ()

@property (nonatomic, copy) NSArray * items;

- (id)itemWithName:(NSString * __nonnull)name;

@end

@implementation TestNullabilityClass

...

- (void)testNullability {
    [self itemWithName:nil];	// 编译器警告：Null passed to a callee that requires a non-null argument
}

- (id)itemWithName:(NSString * __nonnull)name {
    return nil;
}

@end
```

	

不过这只是一个警告，程序还是能编译通过并运行。

事实上，在任何可以使用`const`关键字的地方都可以使用`__nullable`和`__nonnull`，不过这两个关键字仅限于使用在指针类型上。而在方法的声明中，我们还可以使用不带下划线的`nullable`和`nonnull`，如下所示：

``` objective-c
- (nullable id)itemWithName:(NSString * nonnull)name
```

在属性声明中，也增加了两个相应的特性，因此上例中的items属性可以如下声明：

``` objective-c
@property (nonatomic, copy, nonnull) NSArray * items;
```

当然也可以用以下这种方式：

``` objective-c
@property (nonatomic, copy) NSArray * __nonnull items;
```

推荐使用`nonnull`这种方式，这样可以让属性声明看起来更清晰。

### Nonnull区域设置(Audited Regions)

如果需要每个属性或每个方法都去指定`nonnull`和`nullable`，是一件非常繁琐的事。苹果为了减轻我们的工作量，专门提供了两个宏：`NS_ASSUME_NONNULL_BEGIN`和`NS_ASSUME_NONNULL_END`。在这两个宏之间的代码，所有简单指针对象都被假定为`nonnull`，因此我们只需要去指定那些`nullable`的指针。如下代码所示：

``` objective-c
NS_ASSUME_NONNULL_BEGIN

@interface TestNullabilityClass ()

@property (nonatomic, copy) NSArray * items;

- (id)itemWithName:(nullable NSString *)name;

@end

NS_ASSUME_NONNULL_END
```

在上面的代码中，`items`属性默认是`non null`的，`itemWithName:`方法的返回值也是`non null`，而参数是指定为`nullable`的。

不过，为了安全起见，苹果还制定了几条规则：

1. typedef定义的类型的`nullability`特性通常依赖于上下文，即使是在`Audited Regions`中，也不能假定它为`nonnull`。
2. 复杂的指针类型(如id *)必须显示去指定是`nonnull`还是`nullable`。例如，指定一个指向nullable对象的`nonnull`指针，可以使用`"__nullable id * __nonnull"`。
3. 我们经常使用的`NSError **`通常是被假定为一个指向`nullable NSError`对象的`nullable`指针。

### 兼容性

因为`Nullability Annotations`是`Xcode 6.3`新加入的，所以我们需要考虑之前的老代码。实际上，苹果已以帮我们处理好了这种兼容问题，我们可以安全地使用它们：

1. 老代码仍然能正常工作，即使对`nonnull`对象使用了`nil`也没有问题。
2. 老代码在需要和`swift`混编时，在新的`swift`编译器下会给出一个警告。
3. `nonnull`不会影响性能。事实上，我们仍然可以在运行时去判断我们的对象是否为`nil`。

事实上，我们可以将`nonnull/nullable`与我们的断言和异常一起看待，其需要处理的问题都是同一个：违反约定是一个程序员的错误。特别是，返回值是我们可控的东西，如果返回值是`nonnull`的，则我们不应该返回`nil`，除非是为了向后兼容。

### 参考

1. [Nullability and Objective-C](https://developer.apple.com/swift/blog/?id=25)

## weak的生命周期

我们都知道`weak`表示的是一个弱引用，这个引用不会增加对象的引用计数，并且在所指向的对象被释放之后，`weak`指针会被设置的为`nil`。`weak`引用通常是用于处理循环引用的问题，如代理及block的使用中，相对会较多的使用到`weak`。

之前对weak的实现略有了解，知道它的一个基本的生命周期，但具体是怎么实现的，了解得不是太清晰。今天又翻了翻《Objective-C高级编程》关于`__weak`的讲解，在此做个笔记。

我们以下面这行代码为例：

``` objective-c
{
    id __weak obj1 = obj;
}
```

当我们初始化一个`weak`变量时，`runtime`会调用`objc_initWeak`函数。这个函数在`Clang`中的声明如下：

``` objective-c
id objc_initWeak(id *object, id value);
```

其具体实现如下：

``` objective-c
id objc_initWeak(id *object, id value)
{
    *object = 0;
    return objc_storeWeak(object, value);
}
```

示例代码轮换成编译器的模拟代码如下：

``` objective-c
id obj1;
objc_initWeak(&obj1, obj);
```

因此，这里所做的事是先将`obj1`初始化为`0(nil)`，然后将`obj1`的地址及`obj`作为参数传递给`objc_storeWeak`函数。

`objc_initWeak`函数有一个前提条件：就是`object`必须是一个没有被注册为`__weak`对象的有效指针。而`value`则可以是`null`，或者指向一个有效的对象。

如果`value`是一个空指针或者其指向的对象已经被释放了，则`object`是`zero-initialized`的。否则，`object`将被注册为一个指向`value`的`__weak`对象。而这事应该是`objc_storeWeak`函数干的。`objc_storeWeak`的函数声明如下：

``` objective-c
id objc_storeWeak(id *location, id value);
```

其具体实现如下：

``` objective-c
id objc_storeWeak(id *location, id newObj)
{
    id oldObj;
    SideTable *oldTable;
    SideTable *newTable;
    ......

    // Acquire locks for old and new values.
    // Order by lock address to prevent lock ordering problems. 
    // Retry if the old value changes underneath us.
 retry:
    oldObj = *location;

    oldTable = SideTable::tableForPointer(oldObj);
    newTable = SideTable::tableForPointer(newObj);

    ......

    if (*location != oldObj) {
        OSSpinLockUnlock(lock1);

#if SIDE_TABLE_STRIPE > 1
        if (lock1 != lock2) OSSpinLockUnlock(lock2);
#endif
        goto retry;
    }

    if (oldObj) {
        weak_unregister_no_lock(&oldTable->weak_table, oldObj, location);
    }

    if (newObj) {
        newObj = weak_register_no_lock(&newTable->weak_table, newObj,location);
        
        // weak_register_no_lock returns NULL if weak store should be rejected
    }

    // Do not set *location anywhere else. That would introduce a race.
    *location = newObj;

    ......

    return newObj;
}
```

我们撇开源码中各种锁操作，来看看这段代码都做了些什么。在此之前，我们先来了解下`weak`表和`SideTable`。

`weak`表是一个弱引用表，实现为一个`weak_table_t`结构体，存储了某个对象相关的的所有的弱引用信息。其定义如下(具体定义在[objc-weak.h](http://www.opensource.apple.com/source/objc4/objc4-646/runtime/objc-weak.h)中)：

``` objective-c
struct weak_table_t {
    weak_entry_t *weak_entries;
    size_t    num_entries;
    ......
};
```

其中`weak_entry_t`是存储在弱引用表中的一个内部结构体，它负责维护和存储指向一个对象的所有弱引用`hash`表。其定义如下：

``` objective-c
struct weak_entry_t {

    DisguisedPtr<objc_object> referent;
    union {
        struct {
            weak_referrer_t *referrers;
            uintptr_t        out_of_line : 1;
            ......
        };
        
        struct {
            // out_of_line=0 is LSB of one of these (don't care which)
            weak_referrer_t  inline_referrers[WEAK_INLINE_COUNT];
        };
    };
};
```

其中`referent`是被引用的对象，即示例代码中的`obj`对象。下面的`union`即存储了所有指向该对象的弱引用。由注释可以看到，当`out_of_line`等于`0`时，`hash`表被一个数组所代替。另外，所有的弱引用对象的地址都是存储在`weak_referrer_t`指针的地址中。其定义如下：

``` objective-c
typedef objc_object ** weak_referrer_t;
```

`SideTable`是一个用`C++`实现的类，它的具体定义在[NSObject.mm](http://opensource.apple.com/source/objc4/objc4-532.2/runtime/NSObject.mm)中，我们来看看它的一些成员变量的定义：

``` objective-c
class SideTable {

private:
    static uint8_t table_buf[SIDE_TABLE_STRIPE * SIDE_TABLE_SIZE];

public:
    RefcountMap refcnts;
    weak_table_t weak_table;
    ......
}
```

`RefcountMap refcnts`，大家应该能猜到这个做什么用的吧？看着像是引用计数什么的。哈哈，貌似就是啊，这东东存储了一个对象的引用计数的信息。当然，我们在这里不去探究它，我们关注的是`weak_table`。这个成员变量指向的就是一个对象的`weak`表。

了解了`weak`表和`SideTable`，让我们再回过头来看看`objc_storeWeak`。首先是根据`weak`指针找到其指向的老的对象：

``` objective-c
oldObj = *location;
```

然后获取到与新旧对象相关的SideTable对象：

``` objective-c
oldTable = SideTable::tableForPointer(oldObj);
newTable = SideTable::tableForPointer(newObj);
```

下面要做的就是在老对象的`weak`表中移除指向信息，而在新对象的`weak`表中建立关联信息：

``` objective-c
if (oldObj) {
    weak_unregister_no_lock(&oldTable->weak_table, oldObj, location);
}
if (newObj) {
    newObj = weak_register_no_lock(&newTable->weak_table, newObj,location);
    // weak_register_no_lock returns NULL if weak store should be rejected
}
```

接下来让弱引用指针指向新的对象：

``` objective-c
*location = newObj;
```

最后会返回这个新对象：

``` objective-c
return newObj;
```

`objc_storeWeak`的基本实现就是这样。当然，在`objc_initWeak`中调用`objc_storeWeak`时，老对象是空的，所有不会执行`weak_unregister_no_lock`操作。

而当`weak`引用指向的对象被释放时，又是如何去处理`weak`指针的呢？当释放对象时，其基本流程如下：

1. 调用`objc_release`
2. 因为对象的引用计数为`0`，所以执行`dealloc`
3. 在`dealloc`中，调用了`_objc_rootDealloc`函数
4. 在`_objc_rootDealloc`中，调用了`object_dispose`函数
5. 调用`objc_destructInstance`
6. 最后调用`objc_clear_deallocating`

我们重点关注一下最后一步，`objc_clear_deallocating`的具体实现如下：

``` objective-c
void objc_clear_deallocating(id obj) 
{
    ......

    SideTable *table = SideTable::tableForPointer(obj);
    
    // clear any weak table items
    // clear extra retain count and deallocating bit
    // (fixme warn or abort if extra retain count == 0 ?)
    OSSpinLockLock(&table->slock);

    if (seen_weak_refs) {
        arr_clear_deallocating(&table->weak_table, obj);
    }
    ......
}
```

我们可以看到，在这个函数中，首先取出对象对应的`SideTable`实例，如果这个对象有关联的弱引用，则调用`arr_clear_deallocating`来清除对象的弱引用信息。我们来看看`arr_clear_deallocating`具体实现：

``` objective-c
PRIVATE_EXTERN void arr_clear_deallocating(weak_table_t *weak_table, id referent) {
    {
        weak_entry_t *entry = weak_entry_for_referent(weak_table, referent);

        if (entry == NULL) {
            ......
            return;
        }

        // zero out references
        for (int i = 0; i < entry->referrers.num_allocated; ++i) {

            id *referrer = entry->referrers.refs[i].referrer;
            
            if (referrer) {
                if (*referrer == referent) {
                    *referrer = nil;
                }
                else if (*referrer) {
                    objc_inform("_weak variable @ %p holds %p instead of %p\n", referrer, *referrer, referent);
                }
            }
        }

        weak_entry_remove_no_lock(weak_table, entry);
        weak_table->num_weak_refs--;
    }
}
```

这个函数首先是找出对象对应的`weak_entry_t`链表，然后挨个将弱引用置为`nil`。最后清理对象的记录。

通过上面的描述，我们基本能了解一个`weak`引用从生到死的过程。从这个流程可以看出，一个`weak`引用的处理涉及各种查表、添加与删除操作，还是有一定消耗的。所以如果大量使用`__weak`变量的话，会对性能造成一定的影响。那么，我们应该在什么时候去使用`weak`呢？《Objective-C高级编程》给我们的建议是只在避免循环引用的时候使用`__weak`修饰符。

另外，在`clang`中，还提供了不少关于`weak`引用的处理函数。如`objc_loadWeak`,`objc_destroyWeak`, `objc_moveWeak`等，我们可以在苹果的开源代码中找到相关的实现。等有时间，我再好好研究研究。

### 参考

1. 《Objective-C高级编程》1.4: __weak修饰符
2. [Clang 3.7 documentation - Objective-C Automatic Reference Counting (ARC)](http://clang.llvm.org/docs/AutomaticReferenceCounting.html)
3. [apple opensource - NSObject.mm](http://opensource.apple.com/source/objc4/objc4-532.2/runtime/NSObject.mm)

## 零碎

### CAGradientLayer

`CAGradientLayer`类是用于在其背景色上绘制一个颜色渐变，以填充层的整个形状，包括圆角。这个类继承自`CALayer`类，使用起来还是很方便的。

与`Quartz 2D`中的渐变处理类似，一个渐变有一个起始位置(`startPoint`)和一个结束位置(`endPoint`)，在这两个位置之间，我们可以指定一组颜色值(`colors`，元素是`CGColorRef`对象)，可以是两个，也可以是多个，每个颜色值会对应一个位置(`locations`)。另外，渐变还分为轴向渐变和径向渐变。

我们写个实例来看看`CAGradientLayer`的具体使用：

``` objective-c
CAGradientLayer *layer = [CAGradientLayer layer];
layer.startPoint = (CGPoint){0.5f, 0.0f};
layer.endPoint = (CGPoint){0.5f, 1.0f};
layer.colors = [NSArray arrayWithObjects:(id)[UIColor blueColor].CGColor, (id)[UIColor redColor].CGColor, (id)[UIColor greenColor].CGColor, nil];
layer.locations = @[@0.0f, @0.6f, @1.0f];
layer.frame = self.view.layer.bounds;

[self.view.layer insertSublayer:layer atIndex:0];
```

#### 参考

1. [CAGradientLayer Class Reference](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Reference/CAGradientLayer_class/)

### Xcode中Ineligible Devices的处理

换了台新电脑，装了个`Xcode 6.3`，整了个新证书和`profile`，然后打开`Xcode`，连上手机。额，然后发现设备居然被标识为`Ineligible Devices`，没认出来。情况类似于下图：

![image](http://i.stack.imgur.com/CFOSG.png)

电脑是受信任的，证书和`profile`也都是`OK`的。试了几次重启`Xcode`和重新连接手机，无效。设备就是选不了。最后是在`Product`->`Destination`里面才选中这个设备的。不过在工具栏还是不能选择，郁闷，求解。

### iOS 7后隐藏UITextField的光标

新项目只支持`iOS 7`后，很多事情变得简单多了，就像隐藏`UITextField`的光标一样，就简单的一句话：

``` objective-c
textFiled.tintColor = [UIColor clearColor];
```

通常我们用`UIPickerView`作为我们的`UITextField`的`inputView`时，我们是需要隐藏光标的。当然，如果想换个光标颜色，也是这么处理。

这么处理的有个遗留问题是：通常我们使用`UIPickerView`作为`UITextField`的`inputView`时， 并不希望去执行各种菜单操作(全选、复制、粘帖)，但只是去设置`UITextField`的`tintColor`时，我们仍然可以执行这边操作，所以需要加额外的处理。这个问题，我们可以这样处理：在`textFieldShouldBeginEditing:`中，我们把`UITextField`的`userInteractionEnabled`设置为`NO`，然后在`textFieldShouldEndEditing:`，将将这个值设置回来。如下：

``` objective-c
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.userInteractionEnabled = NO;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    textField.userInteractionEnabled = YES;
    return YES;
}
```

	

这样就`OK`了。当然这只是我们当前使用的一种处理方式，还有其它的方法，直接`google`或者`stackoverflow`吧。

### iOS 7后UIAlertView中文字左对齐问题

在`iOS 7`之前，如果我们想要让`UIAlertView`中的文字居左显示的话，可以使用以下这段代码来处理：

``` objective-c
for (UIView *view in alert.subviews) {
    if([[view class] isSubclassOfClass:[UILabel class]]) {
       ((UILabel*)view).textAlignment = NSTextAlignmentLeft;
    }
}
```

但很遗憾的是，在`iOS 7`之后，苹果不让我们这么干了。我们去取`UIAlertView`的`subviews`时，获得的只是一个空数组，我们没有办法获取到我们想要的`label`。怎么办？三条路：告诉产品经理和UED说这个实现不了(当然，这个是会被鄙视的，人家会说你能力差)；自己写；找第三方开源代码。嘿嘿，不过由于最近时间紧，所以我决定跟他们说实现不了，哈哈。不过在`github`上找了一个开源的，[Custom iOS AlertView](https://github.com/wimagguc/ios-custom-alertview)，`star`的数量也不少，看来不错，回头好好研究研究。