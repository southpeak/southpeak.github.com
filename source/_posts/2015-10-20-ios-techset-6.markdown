---
layout: post
title: "iOS知识小集 第六期(2015.10.20)"
date: 2015-10-20 17:45:14 +0800
comments: true
categories: techset ios
---



天气有点冷啊，冬天快来了～～然后貌似互联网的冬天也来了啊。阿里缩减校招名额，美团融资失败，大众点评与美团报团，百度腾讯调整招聘，一丝丝的凉意啊～～再然后就是网易邮箱密码泄漏，这又是要搞哪样？不过话说我都不记得自己是不是有网易邮箱啊。额，不知道这个冬天的第一场雪什么时候会来。不管怎样，这个冬天还是窝一窝，等来年春暖花开之时再出去浪了。

这一期的主要内容还是三点：

1. `Xcode 7`中`Playground`中导入并使用图片
2. `Playground`中的字面量(`Xcode 7.1`)
3. `CAEmitterLayer`实现粒子动画

内容不是很多，都是些小东西，主要还是一些知识碎片，这也是知识小集的出发点。所以大家就当是饭后的小点心吧。以后争取勤快一点，至少每个月出个两篇吧（what?不是说过好多次了么？）。

## Xcode 7中Playground中导入并使用图片

在`Playground`中做测试时，可能需要显示图片，这时我们就需要导入一些图片资源。在`Playground`中，没有像普通工程那样有个单独的`Images.xcassets`文件夹来存储图片，不过添加图片也是件非常简单的事情。

如果没有显示`project navigator`，则可以使用快捷键`cmd + 0`打开。默认情况下，我们可以在`project navigator`看到两个`group`。一个是`Source`，另一个是`Resources`。其中`Resources`这个`group`就是用来放置资源的(包括图片资源)，如下图所示：

![image](https://raw.githubusercontent.com/southpeak/Blog-images/master/playground%20resource%201.png)

选中这个`group`，然后点击左下角的`+`按钮，在弹出的菜单中选择`Add Files to 'Resource'`，然后选择要添加的文件，点确定。这样就把资源文件添加到我们的`Playground`了。

添加完成后，我们就可以使用这些资源了。如要显示图片，则可以使用以下代码：

``` objective-c
let image: UIImage = UIImage(named: "test.png")!
```

在`Playground`中显示如下：

![image](https://raw.githubusercontent.com/southpeak/Blog-images/master/playground%20resource%203.png)

另外，初始情况下，`Playground`的包里面并没有`Resources`文件夹，在我们添加资源后，会自动创建这个文件夹。然后我们可以在`File Inspector`中查看文件夹的具体位置，如下所示：

![image](https://raw.githubusercontent.com/southpeak/Blog-images/master/playground%20resource%202.png)



### 参考

1. [Playground Help - Adding Resources to a Playground](https://developer.apple.com/library/ios/recipes/Playground_Help/Chapters/AddResource.html#//apple_ref/doc/uid/TP40015166-CH29-SW1)
2. [Swift playgrounds with UIImage](http://stackoverflow.com/questions/24069479/swift-playgrounds-with-uiimage)
3. [XCode 6: How To Add Image Assets To Your Playground](http://natashatherobot.com/xcode-6-add-image-assets-to-playground/)



## Playground中的字面量(Xcode 7.1)

`Xcode 7.1`新增了一项特性，让我们可以在`playground`代码中嵌入文件、图片和颜色的字面量。

以图片字面量为例，以往如果需要在`playground`使用图片资源，我们总是需要通过文件名来指定图片，如下代码所示：

``` objective-c
let image = UIImage(named: "swift.png")
```

其效果如下：

![image](https://raw.githubusercontent.com/southpeak/Blog-images/master/Literals%20in%20playerground%20-%20image%20literal%201.png)

而在`Xcode 7.1`中，我们无需在编辑器中键入`"swift.png"`，而只需将图片从`Finder`或是资源中拖到我们的代码里面，就可以直接生成一个`UIImage`对象，如下所示：

![image](https://github.com/southpeak/Blog-images/blob/master/Literals%20in%20playerground%20-%20image%20literal%202.png?raw=true)

可以看到，代码中`=`右侧的那个类似于小图标的东东就是一个图片字面量。是不是很酷来着？

与图片字面量类似，我们同样可以添加颜色字面量和文件字面量，添加方法可以参考[Adding Color Literals](https://developer.apple.com/library/prerelease/ios/recipes/Playground_Help/Chapters/AddColorLiteral.html#//apple_ref/doc/uid/TP40015166-CH50-SW1)和[Adding File Literals](https://developer.apple.com/library/prerelease/ios/recipes/Playground_Help/Chapters/AddFileLiteral.html#//apple_ref/doc/uid/TP40015166-CH51-SW1)。

当然，除了看上去很酷之外，这也让我们在`playground`中写代码时能够更快地去编辑这些资源。我们可以通过颜色选择器来插入我们想要的颜色，可以直接从`Finder`中将文件或图片拖到我们的代码中，而不再需要手动输入颜色值或文件名等。而如果我们想替换资源，只需要双击这些字面量就可以轻松地选择其它的资源。

### 字面量的表示

这里有一个问题，在代码中，这些字面量是如何表示的呢？

我们还是以图片字面量为例。选中一个图片字面量，`cmd+C`一下，然后找个文本编辑器，再`cmd+V`一下，发现拷贝出来的是如下信息：

``` objective-c
[#Image(imageLiteral: "swift.png")#]
```

类似于一个构造器。我们再到`UIImage`中找找，可以看到`UIImage`有一个扩展，如下所示：

``` objective-c
extension UIImage : _ImageLiteralConvertible {
    required public convenience init(imageLiteral name: String)
}
```

这个扩展让`UIImage`类实现了`_ImageLiteralConvertible`协议，看这命名，貌似是一个私有的协议。我们来看看它的字义，如下所示：

``` objective-c
/// Conforming types can be initialized with image literals (e.g.
/// `[#Image(imageLiteral: "hi.png")#]`).
public protocol _ImageLiteralConvertible {
    public init(imageLiteral: String)
}
```

可以看到，实现这个协议的类型就可以使用图片字面量来初始化，即我们上面所看到。当然，我们没办法看到源码是怎么实现的，只能到此为止。

实际上，这些字面量会被转换成平台指定的类型，在官方的`swift blog`中列出了一个清单，如下所示：

![image](https://github.com/southpeak/Blog-images/blob/master/Literals%20in%20playerground%20-%20image%20literal%203.png?raw=true)

还有件看起来很酷但似乎并不太实用的事是：这些字面量不但可以用在`playground`中，而且还有可用在工程代码中。不过之所有不太实用，是因为在工程代码中只能以纯文本的形式来展现，而不是像在`playground`中那样能直观的显示。这种纯文本形式即我们上面拷贝出来的信息，我们再贴一次：

``` objective-c
[#Image(imageLiteral: "swift.png")#]
```

我们码段代码：

``` objective-c
let image = [#Image(imageLiteral: "swift.png")#]

let imageView = UIImageView(image: image)
imageView.frame = CGRect(x: 100, y: 100, width: 100, height: 100)

self.view.addSubview(imageView)
```

其效果如下所示：

![image](https://github.com/southpeak/Blog-images/blob/master/Literals%20in%20playerground%20-%20image%20literal%204.png?raw=true)

从代码实践的角度来看，这种写法看上去并不是那么美啊。不过由于这种写法是与平台相关的，所以如果工程需要同时支持`OSX`、`iOS`和`tvOS`，还是可以考虑用一下的。

### 小结

总之，在`playground`中使用图片、颜色、文件字面量还是一件很酷的事，它大大提高了我们使用资源的效率，同时也更加直观，用起来还是满爽的。

这里附上官方的实例:[Literals.playground](https://developer.apple.com/swift/blog/downloads/Literals.zip)

### 参考

1. [Literals in Playgrounds](https://developer.apple.com/swift/blog/)
2. [Adding Image Literals](https://developer.apple.com/library/prerelease/ios/recipes/Playground_Help/Chapters/AddImageLiteral.html#//apple_ref/doc/uid/TP40015166-CH49-SW1)
3. [Adding Color Literals](https://developer.apple.com/library/prerelease/ios/recipes/Playground_Help/Chapters/AddColorLiteral.html#//apple_ref/doc/uid/TP40015166-CH50-SW1)
4. [Adding File Literals](https://developer.apple.com/library/prerelease/ios/recipes/Playground_Help/Chapters/AddFileLiteral.html#//apple_ref/doc/uid/TP40015166-CH51-SW1)

## CAEmitterLayer实现粒子动画

前段时间[@MartinRGB](http://weibo.com/u/1956547962)做了个带粒子效果的删除单元格动画，今天问他具体的实现方式，然后他把参考的原始工程发我看了一下。于是就找到了这个：[UIEffectDesignerView](https://github.com/icanzilb/UIEffectDesignerView)。是`github`上的一个粒子动画的开源代码。其效果如下图所示：

![image](https://github.com/southpeak/Blog-images/blob/master/CAEmitterLayer%201.jpg?raw=true)

这个动画的实现基于`CAEmitterLayer`类，它继承自`CALayer`。这个类是`Core Animation`提供的用于实现一个粒子发射器系统的类。这个类主要提供了一些属性来设置粒子系统的几何特性。我们可以如下处理：

``` objective-c
let emitter = CAEmitterLayer()

// setup the emitter metrics
emitter.emitterPosition = CGPoint(x: self.bounds.size.width / 2, y: self.bounds.height / 2)
emitter.emitterSize = self.bounds.size

// setup the emitter type and mode
let kEmitterModes = [ kCAEmitterLayerUnordered, kCAEmitterLayerAdditive, kCAEmitterLayerOldestLast, kCAEmitterLayerOldestFirst ]
emitter.emitterMode = kEmitterModes[ Int(valueFromEffect("emitterMode")) ]
```

*需要注意的就是粒子系统会被绘制到层的背影颜色及边框之上。*

当然，要想发射粒子，就需要有粒子源。一个粒子源定义了发射的粒子的方向及其它属性。在`Core Animation`中，使用`CAEmitterCell`对象来表示一个粒子源。`CAEmitterCell`定义了大量的属性来设置一个粒子源的特性，如粒子的显示特性(`color`, `scale`, `style`)、运动特性(如`spin`, `emissionLatitude`)、时间特性(如`lifetime`, `birthRate`, `velocity`)等。我们可以手动来设置这些值，也可以从文件中获取。在`UIEffectDesignerView`工程中，粒子发射器的信息是放在一个`ped`文件中，这个文件以`JSON`格式存储了粒子信息，如下所示：

``` json
{
    "latitude": 0, 
    "alphaSpeed": 0, 
    "scaleSpeed": 0, 
    "blueRange": 0.33, 
    "width": 120, 
    "texture": "....", 
    "spinRange": 0, 
    "lifetime": 5, 
    "greenSpeed": 0, 
    "aux3": null, 
    "emitterType": 0, 
    "version": 0.1, 
    "zAcceleration": 0, 
    "velocity": 100, 
    "velocityRange": 150, 
    ...
    "y": 390, 
    "aux2": null
}
```

我们从文件中把粒子信息读取出来放到一个字典中，然后再将值赋给一个`CAEmitterCell`对象，如下所示：

``` objective-c
// create new emitter cell
let emitterCell: CAEmitterCell = CAEmitterCell()

let effect: [String: AnyObject] = loadFile(filename)

...
emitterCell.birthRate           = effect("birthRate")
emitterCell.lifetime            = effect("lifetime")
emitterCell.lifetimeRange       = effect("lifetimeRange")
emitterCell.velocity            = effect("velocity")
emitterCell.velocityRange       = effect("velocityRange")
...
```

之后，我们便可以把这个粒子源添加到粒子系统中，如下所示：

``` objective-c
emitter.emitterCells = [ emitterCell ]
```

这样就可以发射粒子了。

当然对于一个粒子的特性，除了受粒子源设置的属性影响外，同样也还受粒子系统的一些属性的影响，如下代码所示：

``` objective-c
emitter.scale = 0.5
```

其效果如下图所示：

![image](https://github.com/southpeak/Blog-images/blob/master/CAEmitterLayer%202.jpg?raw=true)

另外，一个粒子源也可以包含一个子粒子源的数组，每个子源都可以作为一个独立的发射源。

### 参考

1. [UIEffectDesignerView](https://github.com/icanzilb/UIEffectDesignerView)
2. [CAEmitterLayer Class Reference](https://developer.apple.com/library/prerelease/ios/documentation/GraphicsImaging/Reference/CAEmitterLayer_class/)
3. [CAEmitterCell Class Reference](https://developer.apple.com/library/prerelease/ios/documentation/GraphicsImaging/Reference/CAEmitterCell_class/index.html)

## 零碎

### C语言的int类型在Swift中的对应类型

一言以蔽之，`C`语言的`int`类型在`Swift`中的对应类型是`CInt`，它是`Int32`的一个别名。今天一哥们用`Swift`写了一段测试代码来调用`C`方法，方法中有个参数是`int`类型，类似于如下代码：

``` objective-c
let str = "Hello, World!"
let a = str.characters.count
Test.test(a)		// test方法接受一个int类型的参数

// 编译器错误：Cannot convert value of type 'Distance'(aka 'Int') to expected argument type Int32
```

可以看到我们需要传入一个`Int32`类型的参数。

之所以使用`Int32`，是因为在`C`语言中，`int`是`4`个字节，而`Swift`中的`Int`则依赖于平台，可能是`4`个字节，也可能是`8`个字节。嗯，这个问题是凑数的，点到为止吧。

### Swift中获取类型的大小

在`C`语言中，如果我们想获取一个变量或数据类型的大小，则可以使用`sizeof`函数。如下所示：

``` objective-c
int a = 10;
printf("%lu, %lu", sizeof(int), sizeof(a));

// 输出：4,4
```

在`Swift`中，也提供了相应的函数。我们可以使用`sizeof`来获取给定类型的大小，使用`sizeofValue`来获取给定值的类型的大小。如下所示：

``` objective-c
sizeof(Int)				// 8

let c: Int = 10
sizeofValue(c)			// 8
```

不过，与`C`语言中的`sizeof`不同的是，`Siwft`中的`sizeof`与`sizeofValue`不包含任何内存对齐的填充部分。如`timeval`结构体，在`C`语言中的大小是`16`，而在`Swift`中，则是`12`，并未包含`4`个填充字节。

``` objective-c
sizeof(timeval)			// 12
```

不过，`Swift`提供了两个对应的函数，来计算经过内存对齐的类型的大小，即`strideof`秘`strideofValue`，如下所示：

``` objective-c
let time = timeval(tv_sec: 10, tv_usec: 10)

strideof(timeval)		// 16
strideofValue(time)		// 16
```

#### 参考

1. [Using Swift with Cocoa and Objective-C (Swift 2)](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithCAPIs.html)

### 问题：纯Playground中使用Objective-C/C代码

今天想在纯`Playground`中测试一下`CC_MD5`方法，发现没招。因为`CC_MD5`实际上是一个`C`方法，需要导入`<CommonCrypto/CommonCrypto.h>`头文件。这就涉及到`Swift`与`Objective-C`混编，需要创建一个桥接文件。但是纯`Playground`貌似并不支持这么做（搜了一下没搜着解决方法）。于是只能采取曲线救国策略，建立一个基于`Swift`的工程，在这里面创建桥接文件，导入头文件。然后在工程中创建一个`Playground`来做测试了。