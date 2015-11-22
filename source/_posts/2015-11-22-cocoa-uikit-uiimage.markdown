---
layout: post
title: "UIKit: UIImage"
date: 2015-11-22 09:20:56 +0800
comments: true
categories: cocoa iOS
---

> 本系列主要基于`Apple`官方文档，更多的是对参考文档重点内容的翻译与补充。该系列中的每篇文章会持续更新与补充。如有问题，欢迎通过微博告诉我，我将及时进行更正，谢谢！！！

`UIImage`对象是iOS中用来显示图像数据的高级接口。我们可以从文件，`NSData`，`Quartz`图片对象中创建`UIImage`对象。可以说这个类是我们接触频率非常高的一个类。

## UIImage的不可变性

`UIImage`对象是不可变的，所以一旦创建后，我们就不能再改变它的属性。这也就意味着，我们只能在初始化方法中提供属性值或依赖于图片自身的属性值。同样，由于其不可变，所以在任何线程中都可以安全地使用它。

如果我们想修改`UIImage`对象的一些属性，则可以使用便捷方法和自定义的参数值来创建图像的一份拷贝。

另外，由于`UIImage`对象是不可变的，所以它没有提供访问底层图片数据的方法。不过我们可以使用`UIImagePNGRepresentation`或`UIImageJPEGRepresentation`方法来获取包含PNG或JPG格式的数据的`NSData`对象。如下代码所示：

``` objective-c
let image = UIImage(named: "swift");

let imageData:NSData? = UIImageJPEGRepresentation(image!, 1.0)
```

## 创建UIImage对象

对于一个UIImage对象来说，它的数据源主要有以下几种：

1. 文件：我们可以使用`init(contentsOfFile:)`方法来从指定文件中创建对象。
2. 纯图片数据(`NSData`)：如果在内存中有图片的原始数据(表示为`NSData`对象)，则可以使用`init(data:)`来创建。需要注意的是这个方法会对象图片数据做缓存。
3. `CGImage`对象：如果我们有一个`CGImage`对象，则可以使用`init(CGImage:)`或`init(CGImage:scale:orientation:)`创建`UIImage`对象。
4. `CIImage`对象：如果我们有一个`CIImage`对象，则可以使用`init(CIImage:)`或`init(CIImage:scale:orientation:)`创建`UIImage`对象。

需要注意的是，如果是从文件或者纯图片数据中创建`UIImage`对象，则要求对应的图片格式是系统支持的图片类型。

对于`Objective-C`来说，`UIImage`对象也提供了这些初始化方法对应的便捷类方法来创建对象。

## 内存管理

在实际的应用中，特别是图片类应用中，我们可能需要使用大量的图片。我们都知道，图片通常都是非常占内存的。如果同一时间加载大量的图片，就可能占用大量的系统内存。

为此，Apple采用了一种比较巧妙的策略。在低内存的情况下，系统会强制清除`UIImage`对象所指向的图片数据，以释放部分内存。注意，这种清除行为影响到的只是图片数据，而不会影响到`UIImage`对象本身。当我们需要绘制那些图片数据已经被清除的`UIImage`对象时，对象会自动从源文件中重新加载数据。当然，这是以时间换空间的一种策略，会导致一定的性能损耗。

说到这里，我们不得不提一下`init(named:)`方法了。可以说我们平时创建`UIImage`对象用得最多的应该就是这个方法。这个方法主要是使用`bundle`中的文件创建图片的快捷方式。关于这个方法，有几点需要注意：

1. **缓存**：这个方法会首先去系统缓存中查找是否有图片名对应的图片。如果有就返回缓存中的图片；如果没有，则该方法从磁盘或者`asset catalog`中加载图片并返回，同时将图片缓存到系统中。缓存的图片只有在收到内存警告时才会释放。因此，如果图片的使用频率比较低，则可以考虑使用`imageWithContentsOfFile:`方法来加载图片，这样可以减少内存资源的消耗。当然，这需要权衡考虑，毕竟读写磁盘也是有性能消耗的，而且现在的高端机内存已经不小了。
2. **多分辨率图片处理**：在iOS 4.0后，该方法会根据屏幕的分辨率来查找对应尺寸的图片。即我们使用时，只需要写图片名，而不需要指定是1x, 2x还是3x图，该方法会自己判断。
3. **png图片后缀**：在iOS 4.0以后，如果图片是png格式的，则图片文件名不需要附带扩展名。
4. **线程安全性**：该方法在iOS 9.0之前并不是线程安全的，在二级线程中调用可能会导致崩溃。在iOS 9.0之后，Apple作了优化处理，将其改为线程安全的方法。为了避免不必要的麻烦，尽量在主线程中调用这个方法。

## 图片拉伸

当我们的图片比所要填充的区域小时，会导致图片变形。如以下图片，原始大小为100\*30，将其放到一个300\*50的`UIImageView`中时，整个图片被拉伸。

**原始图片**

![image](https://github.com/southpeak/Blog-images/blob/master/UIKit_UIImage.png?raw=true)

**拉伸后的图片**

![image](https://github.com/southpeak/Blog-images/blob/master/UIKit_UIImage_Deform.png?raw=true)

这时我们就需要做特殊的处理。

`Android`的同学应该都知道.9图，这种图片可以只拉伸中间的部分，而保持四个角不变形。在iOS中也支持这种操作。在早期的iOS版本中，`UIImage`提供了如下方法来执行此操作：

``` objective-c
func stretchableImageWithLeftCapWidth(_ leftCapWidth: Int, topCapHeight topCapHeight: Int) -> UIImage
```

这个方法通过`leftCapWidth`和`topCapHeight`两个参数来定义四个角的大小。不过这个方法在iOS 5中就被`Deprecated`了，对应的两个属性`leftCapWidth`和`topCapHeight`也是相同的命运。所以现在不建议使用它们。另外，对于如何解释`leftCapWidth`和`topCapHeight`，大家可以参考一下[@M了个J](http://weibo.com/exceptions)的[iOS图片拉伸技巧](http://blog.csdn.net/q199109106q/article/details/8615661)。

在iOS 5中，我们可以使用以下方法来执行相同的操作：

``` objective-c
func resizableImageWithCapInsets(_ capInsets: UIEdgeInsets) -> UIImage
```

这个方法通过一个`UIEdgeInsets`来指定上下左右不变形的宽度或高度。它会返回一个新的图像。而如果图像被拉伸，则会以平铺的方式来处理中间的拉伸区域。

我们对上面的图片做如下处理：

``` objective-c
let resizedButtonImageView = UIImageView(image: normalButtonImage?.resizableImageWithCapInsets(UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)))
resizedButtonImageView.frame = CGRectMake(0, 60, 300, 50)
```

其得到的结果如下所示：

![image](https://github.com/southpeak/Blog-images/blob/master/UIKit_UIImage_Resized.png?raw=true)

在iOS 6，`Apple`又为我们提供了一个新的方法，相较于上面这个方法，只是多一个`resizingMode`参数，允许我们指定拉伸模式。

``` objective-c
func resizableImageWithCapInsets(_ capInsets: UIEdgeInsets, resizingMode resizingMode: UIImageResizingMode) -> UIImage
```

这个方法的拉伸模式分两种：平铺(`Tile`)和拉伸(`Stretch`)。如果是平铺模式，则跟前一个方法是一样的效果。

## 动效图片对象

如果我们有一组大小和缩放因子相同的图片，就可以将这些图片加载到同一个`UIImage`对象中，形成一个动态的`UIImage`对象。为此，`UIImage`提供了以下方法：

``` objective-c
class func animatedImageNamed(_ name: String, duration duration: NSTimeInterval) -> UIImage?
```

这个方法会加载以name为基准文件名的一系列文件。如，假设我们的`name`参数值为"swift"，则这个方法会加载诸如"swift0", "swift1",..., "swift1024"这样的一系列的文件。

这里有两个问题需要注意：

1. 文件的序号必须是从0开始的连续数字，如果不从0开始，则在`Playground`中是会报错的。而如果中间序号有断，而中断后的图片是不会被加载的。
2. 所有文件的大小和缩放因子应该是相同的，否则显示时会有不可预期的结果，这种结果主要表现为播放的顺序可能是杂乱的。

如果我们有一组基准文件名不同的文件，但其大小和缩放因子相同，则可能使用以下方法：

``` objective-c
class func animatedImageWithImages(_ images: [UIImage], duration duration: NSTimeInterval) -> UIImage?
```

传入一个`UIImage`数组来拼装一个动效`UIImage`对象。

另外，`UIImage`也提供了`resizable`版本的动效方法，如下所示：

``` objective-c
class func animatedResizableImageNamed(_ name: String, capInsets capInsets: UIEdgeInsets, duration duration: NSTimeInterval) -> UIImage?

class func animatedResizableImageNamed(_ name: String, capInsets capInsets: UIEdgeInsets, resizingMode resizingMode: UIImageResizingMode, duration duration: NSTimeInterval) -> UIImage?
```

第一个方法的`UIImageResizingMode`默认是`UIImageResizingModeTile`，所以如果想对图片做拉伸处理，可以使用第二个的方法，并传入`UIImageResizingModeStretch`。

## 图片大小的限制

`UIImage`对象使用的图片大小尽量小于1024\*1024。因为这么大的图片消耗的内存过大，在将其作为`OpenGL`中的贴图或者是绘制到`view/layer`中时，可以会出现问题。如果仅仅是代码层面的操作的话，则没有这个限制。比如，将一个大于1024\*1024的图片绘制到位图图形上下文中以重新设定其大小。事实上，我们需要通过这种操作来改变图片大小，以将其绘制到视图中。

## 支持的图片格式

`UIImage`支持的图片格式在[UIImage Class Reference](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIImage_Class)中列出来了，大家可以直接参考。

需要注意的一点是`RGB-565`格式的BMP文件在加载时会被转换成`ARGB-1555`格式。

## 示例代码

本文的示例代码已上传到github，可点击[这里](https://github.com/southpeak/Swift/tree/master/UIKit/UIImage.playground)查看。

## 参考

1. [UIImage Class Reference](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIImage_Class)
2. [iOS图片拉伸技巧](http://blog.csdn.net/q199109106q/article/details/8615661)
3. [iOS 处理图片的一些小 Tip](http://blog.ibireme.com/2015/11/02/ios_image_tips/)