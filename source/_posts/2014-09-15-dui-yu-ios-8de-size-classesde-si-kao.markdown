---
layout: post
title: "Thinking In Terms Of iOS 8 Size Classes"
date: 2014-09-15 17:25:53 +0800
comments: true
categories: translate iOS
---

原文链接：[Thinking In Terms Of iOS 8 Size Classes](http://carpeaqua.com/2014/06/14/thinking-in-terms-of-ios-8-size-classes/)

对于最新的`iOS8 SDK`来说，最性感也最重要的的特性也许莫过于`Size Classes`了。

在聊`Size Classes`之前，我们先来回顾下历史。

## 一堂历史课

最初，`iOS`推出时，我们只有一种设备：`iPhone`。它的屏幕大小是`320\*480`。不过即使如此，它也是同时支付横屏和竖屏。设计同时支持两个方向的`App`不是像`Mobile Safari`或`Messages`那样，简单地拉伸和重新设置视图的大小。在大多数情况下，我们需要移动按钮和其它控件来让其适应横屏(`480\*320`)。

几年后的现在，我们有了高清屏，`iPads`和大屏的`iPhone`。当然，所有这些设备都是支持横屏和竖屏的。解决这个适配问题的传统的方法是在视图控制器和自定义视图中监听设备方向的变化，同时使用多个`xib`或`storyboard`。

假设我已经构建了一个同时支持`iPhone`和`iPad`的的`Glassboard`工程。在`iOS7`和老的版本之前，我们需要针对`iPad`单独创建一个`storyboard`，这个`storyboard`包含重建的视图控制器，`outlet`属性和`target/action`。这相当于是重复工作了。任何程序员都知道这不是个好主意。需要在两个不同的地方做相同的改变真是件糟糕的事。

如果是使用代码，则我们需要在代码中检测屏幕方向及设备大小，以便我们能手动调整我们的约束或基于`frame`的布局。我们的代码会像下面这段代码一样：

``` objective-c
UIDevice *device = [UIDevice currentDevice];
UIDeviceOrientation currentOrientation = device.orientation;
BOOL isPhone = (device.userInterfaceIdiom == UIUserInterfaceIdiomPhone);
BOOL isTallPhone = ([[UIScreen mainScreen] bounds].size.height == 568.0);
if (UIDeviceOrientationIsPortrait(currentOrientation) == YES)
{
    // Do Portrait Things
    if (isPhone == YES)
    {
        // Do Portrait Phone Things
        // Don't deny you've done this at least once.
        if (isTallPhone)
        {
            // iPhone 5+
        }
        else
        {
            // Old phones
        }
    }
    else
    {
        // Do Portrait iPad things.
    }
}
else
{
    // Do Landscape Things.
    if (isPhone == YES)
    {
        // Do Landscape Phone Things
    }
    else
    {
        // Do Landscape iPad things.
    }
}
```

## Size Classes

显然，上面的这些方案都不理想，而且随着苹果新设备的推出，这种情况会变得越来越糟。在今年的`WWDC`上，苹果除了介绍自动布局的新特性外，我们同样也看到了许多可变`iOS`模拟器的事例，以及一种处理所有这些问题和屏幕问题的新技术：`Size Classes`。

`Size Classes`是`iOS`使用的一种新的技术，允许我们为给定的设备自定义我们的程序，而且是基于设备的方向和屏幕大小的。

`Size Classes`有两个目的：

1. 让开发人员和设计人员跳出指定设备的范畴，而是以更广义的范畴来思考问题
2. 为未来做准备

第一个目的也引出了第二个目的。我们看到各种传说，说`iPhone 6, 7`将会是更大的设备。你也看到了苹果已经开发出了可穿戴设备(`Apple Watch`)。那么有什么方法可以让为这些设备开发变得更容易呢？那就是`Size Classes`。

目前从`XCode 6`上可以看到有四种类型的`Size Classes`：

![image](http://cdn.carpeaqua.com.s3.amazonaws.com/images/size-classes/size_class_chart.jpg)

1. 宽紧凑(`Compact`)
2. 长紧凑
3. 宽正常(`Regular`)
4. 长正常

任意时刻，我们的设备都有一个水平方向的`Size Class`和一个竖直方向的`Size Class`。这两者都是用来定义布局属性与物征(`trait`)的集合，以在屏幕上显示内容给用户。

## 特征(Traits)

水平和竖直的Size Class被认为是Traits。结合当前界面术语和显示比例，一起组成了一个特征集合。这不只是包含了指定的控制应该放在屏幕的什么地方。

特征(`Trait`)也可以用于诸如`image assets`的东西上(假设你正在使用`Asset Catalogs`)。在`asset`中，我们不仅可以包含`1x`和`2x`版本，我们还可以为不同的`size class`指定不同的`image asset`。在代码中，它看着仍然是相同的`UIImage`调用。`Asset Catalogs`负责基于当前的特征集合来渲染合适的图片。

## 为Size Classes设计

`Size Classes`对于开发人员来讲是一个很好的扩展，因为当我们需要支持多种设备和方向时，它能简化我们的开发。通过简化我们的工作，苹果可以更容易地开发新的设备，并可以让开发者开发能用的应用，而不仅仅是只为`iPhone`开发程序。

对于开发者来说，最大的改变是我们需要再一次修改我们的关于不同方向的代码。大家已经习惯了吧，谁让我们是开发者呢。

对于设计者来说，特征集合意味着可以少考虑是为哪种设备来做设计，而可以更多的考虑设备的属性。现在，设计者最需要考虑的因素是物理屏幕大小。

由于不能确保每台设备的屏幕尺寸都与`Photoshop`或测试样机保持一致，所以单独为特定的场景做设计已经站不住脚了。相反，我们的目标是应该为一类设备做通用的设计，主要包括：

1. 手机上的肖像模式
2. 平板上的肖像模式
3. 手机上的景观模式
4. 平板上的景观模式

现在`iPhone 6`来了，它的屏幕也变大了，它拥有与`iPhone 4s`和`5`一样的特征集合。当然，`iPhone 6`的尺寸比原来的手机更大了，但是UI应该基于为指定特征集合定义的界面，来做自适应的处理。

这可能意味着设计者需要推翻自己以前的一些设计，但这就是事实。就像软件开发一样，软件设计需要符合这些约束。新的约束就是我们不能再活在只为特定屏幕尺寸做设计的世界里面了。我们不是要像`Android`一样，但这是苹果希望我们前进的方向。

## 采用Size Classes

好消息是，`Interface Builder`可以让我们更好的使用`Size Classes`。更好的消息是，这些`Interface Builder`变化是向后兼容的，所以我们可以在合适的地方简化和合并`Storyboards`和`Xibs`，而不会落下任何用户。

不太好的消息是，如果需要在代码中使用特征集合，则只支持`iOS 8`。这是因为苹果很少为老的系统提供新的`API`接口。这就意味着我们需要在代码中添加一些新的分支来支持不同的系统。例如，为自定义的`UIView`调整`intrinsicContentSize`属性。如果系统是`iOS8`，我们可以使用竖直和水平的`size class`来确定这个值，但如果设备仍然是`iOS 7`或老版本，则已存在的代码仍然需要保留。

因为我使用并推荐`Interface Builder`，所以比起那些仍然活在“将一切写在代码”口号中的人们来说，我的工作明显地减少了。如果你仍然在那个阵营里面，我强烈建议你使用`iOS 8`, `XCode 6`和特征集合，并以此为契机加入到`Interface Builder`阵营中来。这样不仅能减少我们的代码量，同样可以通过提取大量的特征处理到一个视觉`UI`库来简化代码。