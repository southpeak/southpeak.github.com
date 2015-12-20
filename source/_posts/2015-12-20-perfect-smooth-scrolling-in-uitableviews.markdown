---
layout: post
title: "Perfect smooth scrolling in UITableViews"
date: 2015-12-20 21:42:15 +0800
comments: true
categories: translate iOS
---



> 原文由[Alexander Orlov](https://medium.com/@plasm)发表于medium，地址为[https://medium.com/ios-os-x-development/perfect-smooth-scrolling-in-uitableviews-fd609d5275a5#.so9tpnlk1](https://medium.com/ios-os-x-development/perfect-smooth-scrolling-in-uitableviews-fd609d5275a5#.so9tpnlk1)
> 
> 
> 
> 这篇文章是前两周[@叶孤城](http://weibo.com/u/1438670852?from=usercardnew&is_all=1) 叶大在微信群里面的分享，一直到这两天才翻出来研究。很多实用的东西，不过由于水平有限，有些地方没能翻译好，还请大家指正。



我已经在iOS这个最好的移动平台上有几年的开发经验了。在这期间，我已以接触过很多的iOS应用和iOS工程师。

我们的世界很多好的开发者，但有时我发现他们中的一些人并不是很清楚如何充分利用这个最受欢迎的移动设备的整体潜力，来开发真正平滑的应用。

现在，我将尝试从我的视角，来说明一下为了让`UITableView`更快更平滑，工程师应该做哪些优化。

------

文章越往后，难度和深度也会不断增加，所以我将以一些你熟悉的东西来开始。文章后面将会讨论iOS绘画系统和UIKit更深层次的一些东西。

## 内建方法

我相信大多数阅读这篇文章的人都知道这些方法，但一些人，即便是使用过这些方法，也没有以正确的姿式来使用它们。



✻ ✻ ✻ ✻ ✻



首先是重用`cell/header/footer`的单个实例，即便是我们需要显示多个。这是优化`UIScrollView`(`UITableView`的父类)最明显的方式，`UIScrollView`是由苹果的工程师提供的。为了正确的使用它，你应该只有`cell/header/footer`类，一次性初始化它们，并返回给`UITableView`。

在苹果的开发文档里面已经描述了重用`cell`的流程，在这就没有必须再重复了。

但重要的事情是：在`UITableView`的`dataSource`中实现的`tableView:cellForRowAtIndexPath:`方法，需要为每个`cell`调用一次，它应该快速执行。所以你需要尽可能快地返回重用`cell`实例。

> 不要在这里去执行数据绑定，因为目前在屏幕上还没有`cell`。为了执行数据绑定，可以在`UITableView`的`delegate`方法`tableView:willDisplayCell:forRowAtIndexPath:`中进行。这个方法在显示`cell`之前会被调用。



✻ ✻ ✻ ✻ ✻



第二点也不难理解，但是有一件事需要解释一下。

这个方法对于`cell`定高的`UITableView`来说没有意义，但如果由于某些原因需要动态高度的`cell`的话，这个方法可以很容易地让滑动更流畅。

正如我们所知，`UITableView`是`UIScrollView`的子类，而`UIScrollView`的作用是让用户可以与比屏幕实际尺寸更大的区域交互。任何`UIScrollView`的实例都使用诸如`contentSize`、`contentOffset`和其它许多属性来将正确的区域显示给用户。

但是`UITableView`的问题在哪？正如所解释的一样，`UITableView`不会同时维护所有`cell`的实例。相反，它只需要维护显示给用户的那些`cell`。

那么，`UITableView`是如何知道它的`contentSize`呢？它是通过计算所以`cell`的高度之和来计算`contentSize`的值。

`UITableView`的`delegate`方法`tableView:heightForRowAtIndexPath:`会为每个`cell`调用一次，所以你应该非常快地返回高度值。

很多人会犯一个错误，他们会在布局初始化`cell`实例并绑定数据后去获取它们的高度。如果你想优化滑动的性能，就不应该以这种方式来计算`cell`的高度，因为这事难以置信的低效，iOS设备标准的`60 FPS`将会降低到`15-20 FPS`，滑动会变得很慢。

如果我们没有一个`cell`的实例，那如何去计算它的高度呢？这里有一段示例代码，它使用类方法，并基于传入的宽度及显示的数据来计算高度值:

![image](https://cdn-images-1.medium.com/max/2000/1*l_1bUrp8OzZcS5cHdnaGvw.png)

可以用以下方式来使用上面这个方法返回高度值给`UITableView`:

![image](https://cdn-images-1.medium.com/max/2000/1*keqsdc6XFmEOdmI4w10zrA.png)

你在实现这一切的时候能获得了多少乐趣呢？大多数人会说没有。我没有保证过这事很容易。当然，我们可以构建我们自己的类来手动布局和计算高度，但有时候我们没有足够的时间来做这件事。你可以在[Telegram](https://telegram.org/apps)的iOS应用代码中找到这种实现的例子。

从iOS 8开始，我们可以在`UITableView`的`delegate`中使用自动高度计算，而不需要实现上面提到的方法。为了实现这一功能，你可能会使用`AutoLayout`，并将`rowHeight`变量设置为`UITableViewAutomaticDimension`。可以在[StackOverflow](http://stackoverflow.com/a/18746930)中找到更多详细的信息。

尽管可以使用这些方法，但我强烈建议不要使用它们。另外，我也不建议使用复杂的数学计算来获取`cell`的高度，如果可能，只使用加、减、乘、除就可以。

但如果是`AutoLayout`呢？它真的跟我所说的一样慢么？你可能会很惊讶，但这是事实。如果你想让你的App在所有设备上都能平滑的滚动，你就会发现这种方法难以置信的慢。你使用的子视图越多，`AutoLayout`的效率越低。

`AutoLayout`相对低效的原因是隐藏在底层的命名为"`Cassowary`"的约束求解系统。如果布局中子视图越多，那么需要求解的约束也越多，进而返回`cell`给`UITableView`所花的时间也越多。

哪一个更快呢：使用少量的值来执行基本的数学计算，还是找一个求解大量线性等式或不等式的系统么？现在想像一下，用户想要快速地滑动，每个`cell`的自动布局也执行着疯狂的计算。



✻ ✻ ✻ ✻ ✻



使用内建方法优化`UITableView`的正确方法是：

- 重用`cell`实例：对于特殊类型的`cell`，你应该只有一个实例，而没有更多。
- 不要在`cellForRowAtIndexPath:`方法中绑定数据，因为在此时`cell`还没有显示。可以使用`UITableView`的`delegate`中的`tableView:willDisplayCell:forRowAtIndexPath:`方法。
- 快速计算`cell`高度。对于工程师来说这是常规工作，但你将会为优化复杂`cell`的平滑滑动所付出的耐心而获取回报。

## 我们需要更深一步

当然，上面提到的这些点不足以实现真正的平滑滚动，特别是当你需要实现一些复杂的`cell`(如有大量的渐变、视图、交互元素、一些修饰元素等等)时，这变得尤其明显。

这种情况下，`UITableView`很容易变得缓慢，即便是做了上面所有的事情。`UITableViewCell`中的视图越多，滑动时FPS越低。但在使用了手动布局和优化了高度计算后，问题就不在布局了，而在渲染了。



✻ ✻ ✻ ✻ ✻



让我们把关注点放在`UIView`的`opaque`属性上。文档中说它用于辅助绘图系统定义`UIView`是否透明。如果不透明，则绘图系统在渲染视图时可以做一些优化，以提高性能。

我们需要性能，或者不是？用户可能快速地滑动table，如使用`scrollsToTop`特性，但他们可能没有最新的`iPhone`，所以`cell`必须快速地被渲染。比通常的视图更快。

渲染最慢的操作之一是混合(`blending`)。混合操作由GPU来执行，因为这个硬件就是用来做混合操作的（当然不只是混合）。

你可能已经猜到，提高性能的方法是减少混合操作的次数。但在此之前，我们需要找到它。让我们来试试。

在iOS模拟器上运行App，在模拟器的菜单中选择'`Debug`'，然后选中'`Color Blended Layers`'。然后iOS模拟器就会将全部区域显示为两种颜色：绿色和红色。

绿色区域没有混合，但红色区域表示有混合操作。

![image](https://cdn-images-1.medium.com/max/1200/1*m3WEuOgVhSEs5KdqCHzgTA.png)

![image](https://cdn-images-1.medium.com/max/1200/1*X1QSvtNaWSwrnvIk8Eidiw.png)

正如你所看到的一样，在`cell`中至少有两处执行了混合操作，但你可能看不出差别来（这个混合操作是不必要的）。

每种情况都应该仔细研究，不同的情况需要使用不同的方法来避免混合。在我这里，我需要做的只是设置`backgroundColor`来实现非透明。

但有时候可能更复杂。看看这个：我们有一个渐变，但是没有混合。

![image](https://cdn-images-1.medium.com/max/1200/1*2A_Ux40OUG27V-h7YGL4pQ.png)

![image](https://cdn-images-1.medium.com/max/1200/1*RxYJW_xd4nUgfZP5E1RSZg.png)

如果想要使用`CAGradientLayer`来实现这个效果，你将会很失望：在iPhone 6中FPS将会降到`25-30`，快速滑动变得不可能。

这确实发生了，因为我们混合了两个不同层的内容：`UILabel`的`CATextLayer`和我们的`CAGradientLayer`。

如果能正确地利用了`CPU`和`GPU`资源，它们将会均匀地负载，FPS保持在`60`帧。看起来就像下面这样：

![image](https://cdn-images-1.medium.com/max/1600/1*VXaKFBhgWjhNbpZtwQG0_w.png)

当设备需要执行很多混合操作时，问题就出现了：`GPU`是满载的，但`CPU`却保持低负载，而显得没有太大用处。

大多数工程师在2010年夏季末时都面临这个问题，当时发布了iPhone 4。Apple发布了革命性的`Retina`显示屏和...非常普通的`GPU`。然而，通常情况下它仍然有足够的能力，但上面描述的问题却变得越来越频繁。

你可以在当前运行iOS 7系统的iPhone 4上看到这一现象--所有的应用都变得很慢，即使是最简单的应用。不过，应用这篇文章中的介绍的方法，即使是在这种情况下，你的应用也能达到`60 FPS`，尽管会有些困难。

所以，需要怎么做呢？事实上，解决方案是：使用`CPU`来渲染！这将不会加载GPU，这样就无法执行混合操作。例如，在执行动画的`CALayer`上。

我们可以在`UIView`的`drawRect:`方法中使用`CoreGraphics`操作来执行`CPU`渲染，如下所示：

![image](https://cdn-images-1.medium.com/max/2000/1*QIsPebLqQ9mJFU2cQ0VDcg.png)

这段代码nice么？我会告诉你并非如此。甚至通过这种方式，你会撤销在一些`UIView`上(在任何情况下，它们都是不必要的)的所有缓存优化操作。但是，这种方法禁用了一些混合操作，卸载`GPU`，从而使`UITableView`的更顺畅。

但是记住：这提高了渲染性能，不是因为`CPU`比`GPU`更快！它可以让我们通过为让`CPU`来执行某些渲染任务，从而卸载`GPU`，因为在很多情况下，`CPU`可能不是100%负载的。

优化混合操作的关键点是在平衡`CPU`和`GPU`的负载。



✻ ✻ ✻ ✻ ✻



优化`UITableView`中绘制数据操作的小结：

- 减少iOS执行无用混合的区域：不要使用透明背景，使用iOS模拟器或者`Instruments`来确认这一点；如果可以，尽量使用没有混合的渐变。
- 优化代码，以平衡`CPU`和`GPU`的负载。你需要清楚地知道哪部分渲染需要使用`GPU`，哪部分可以使用`CPU`，以此保持平衡。
- 为特殊的`cell`类型编写特殊的代码。

## 像素获取

你知道像素看起来是什么样的么？我的意思是，屏幕上的物理像素是什么样的？我肯定你知道，但我还是想让你看一下：

![image](https://cdn-images-1.medium.com/max/1600/1*P3g0HtD5LFzWJXQjsNDbUg.jpeg)

不同的屏幕有不同的制作工艺，但有一件事是一样的。事实上，每个物理像素由三个颜色的子像素组成：红、绿、蓝。

基于这一事实，像素不是原子单位，虽然对于应用来说它是。或者仍然不是？

直到带有`Retina`屏的iPhone 4发布前，物理像素都可以用整型点坐标来描述。自从有了`Retina`屏后，在`Cocoa Touch`环境下，我们就可以用屏幕点来取代像素了，同时屏幕点可以是浮点值。

在完美的世界中(我们尝试构建的)，屏幕点总是被处理成物理像素的整型坐标。但在现实生活中它可能是浮点值，例如，线段可能起始于`x`为`0.25`的地方。这时候，iOS将执行子像素渲染。

这一技术在应用于特定类型的内容(如文本)时很有意义。但当我们绘制平滑直线时则没有必要。

如果所有的平滑线段都使用子像素渲染技术来渲染，那你会让iOS执行一些不必要的任务，从而降低FPS。



✻ ✻ ✻ ✻ ✻



什么情况下会出现这种不必要的子像素抗锯齿操作呢？最常发生的情况是通过代码计算而变成浮点值的视图坐标，或者是一些不正确的图片资源，这些图片的大小不是对齐到屏幕的物理像素上的（例如，你有一张在`Retina`显示屏上的大小为`60*61`的图片，而不是`60*60`的）。

在前面我们讲到，要解决问题，首先需要找到问题在哪。在iOS模拟器上运行程序，在"`Debug`"菜单中选中"`Color Misaligned Image`"。

这一次有两种高亮区域：品红色区域会执行子像素渲染，而黄色区域是图片大小没有对齐的情况。

![image](https://cdn-images-1.medium.com/max/1200/1*wyhCSoZBdQ_tP_Dkq4RXfQ.png)

![image](https://cdn-images-1.medium.com/max/1200/1*ZkN_5mz_NxDFEvZZMAq6Tw.png)

那如何在代码中找到对应的位置呢？我总是使用手动布局，并且部分会自定义绘制，所以通常找到这些地方没有任何问题。如果你使用`Interface Builder`，那我对此深表同情。

通常，为了解决这个问题，你只要简单地使用`ceilf`, `floorf`和`CGRectIntegral`方法来对坐标做四舍五入处理。就是这样！



✻ ✻ ✻ ✻ ✻



通过上面的讨论，我想建议你以下几点：

- 对所有像素相关的数据做四舍五入处理，包括点坐标，`UIView`的高度和宽度。
- 跟踪你的图像资源：图片必须是像素完美的，否则在`Retina`屏幕上渲染时，它会做不必要的抗锯齿处理。
- 定期复查你的代码，因为这种情况可以会经常出现。

## 异步UI

可能这看起来有点奇怪，但这是一种非常有效的方法。如果你知道如何做，那么可以让`UITableView`滑动得更平滑。

现在我们来讨论一下你应该做什么，然后再讨论下你是否可能这么做。



✻ ✻ ✻ ✻ ✻



每个中等以上规模的应用都可能会使用带有媒体内容的`cell`：文本、图片、动画，甚至还有视频。

而所有这些都可能带有装饰元素：圆角头像、还'#'号的文本、用户名等。

我们已经多次提及尽可能快地返回`cell`的需求，而在这里有一些麻烦：`clipsToBounds`很慢，图片需要从网络加载，需要在字符串中定位#号，和许多其它的问题。

优化的目标是很明确的：如果在主线程中执行这些操作，则会让你不能很快地返回`cell`。

在后台加载图片，在相同的地方处理圆角，然后将处理后的图片指定给`UIImageView`。

立刻显示文本，但在后台定位`#`号，然后使用属性字符串来刷新显示。

在你的`cell`中，需要具体情况具体分析，但主要的思想是在后台执行大的操作。这可能不止是网络代码，你需要使用`Instruments`来找到它们。

记住：需要尽快返回`cell`。



✻ ✻ ✻ ✻ ✻



有时候，上面的所有技术可能都帮不上忙。如`GPU`仍然不能使用(iPhone4+iOS7)时，`cell`中有很多内容时，需要`CALayer`的支持以实现动画时(因为在`drawRect:`中实现起来真的很麻烦)。

在这种情况下，我们需要在后台渲染所有其它东西。此外它能在用户快速滑动`UITableView`时有效地提高`FPS`。

我们来看看`Facebook`的应用。为了检测这些，你可能需要往下滑足够的高度，然后点击状态栏。列表会往上滑动，因此你可以清楚地看到此时没有渲染`cell`。如果想要更精确，则不能及时获得。

这很简单，所以你可以自己试试。这时，你需要设置`CALayer`的`drawsAsynchronously`属性为YES。

但是我们可以检查这些行为的必要性。在iOS模拟器上运行程序，然后选择“`Debug`”菜单中的"`Color Offscreen-Rendered`"。现在所有在后台渲染的区域都被高亮为黄色。

![image](https://cdn-images-1.medium.com/max/1200/1*2zcnaJYsfX9IMk87EGZ_Jg.png)

![image](https://cdn-images-1.medium.com/max/1200/1*sdBXh2Ulhc4M92VvdzVEzQ.png)

如果你为某些层开启了这一模式，但是它没有高亮显示，那么它就不够慢。

为了在`CALyaer`层找到瓶颈并进一步减少它，你可以使用`Instruments`里面的`Time Profiler`。



✻ ✻ ✻ ✻ ✻



这里是异步化UI的实现清单：

- 找到让你的`cell`无法快速返回的瓶颈。
- 将操作移到后台线程，并在主线程刷新显示的内容。
- 最后一招是设置你的`CALayer`为异步显示模式(即使只是简单的文本或图片)--这将帮你提高FPS。

## 结论

我尝试解释了iOS绘图系统(没有使用`OpenGL`，因为它的情况更少)的主要思路。当然有些看起来很模糊，但事实上这只是一些方向，你应该朝着这些方向来检查你的代码以找出影响滚动性能的所有问题。

具体情况具体分析，但原则是不变的。

获取完美平滑滚动的关键是非常特殊的代码，它能让你竭尽iOS的能力来让你的应用更加平滑。