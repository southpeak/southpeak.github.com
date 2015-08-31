---
layout: post
title: "翻译篇：10 Things You Need to Know About Cocoa Auto Layout"
date: 2015-08-31 22:49:30 +0800
comments: true
categories: iOS
---



原文由[Ole Begemann](http://oleb.net/)在2013.3.31发表于其个人博客，地址是[10 Things You Need to Know About Cocoa Auto Layout](http://oleb.net/blog/2013/03/things-you-need-to-know-about-cocoa-autolayout/)

*译注：原文发表的时间有点早，主要是针对Xcode 4.x时代的Auto Layout，特别是第二部分"Interface Builder中的Auto Layout"，所以有些内容已经过时了。不过还是有很多可借鉴的地方。特别感谢[@叶孤城](http://weibo.com/u/1438670852) 叶大在微博中的分享，以及对译文的校对。*



第一次使用Cocoa Auto Layout时，感觉它与Cocoa开发者所熟知的springs-struts模式有很大的不同。尽管Auto Layout有点复杂，但我发现只需要了解一些基本规则就可以使用它。本文就来列出这些规则。

## Auto Layout通用概念

### 1.经验法则：每个维度至少有两个约束

在每个维度(水平与竖直)上，一个视图的位置和大小由三个值来定义：头部空间(leading space)，大小和尾部空间(trailing space)[注释1]。一个视图的leading和trailing空间可以相对于父视图来定义，也可以相对于视图层级架构中的兄弟视图来定义。一般来说，我们的布局约束必须满足这两个值，以便计算第三个值(size)。其结果是，一个标准的视图在每个维度上必须至少有两个约束，以明确视图的布局。

### 2.拥抱固有大小(Intrinsic Size)

一些控件，如标签和按钮，都有一个所谓的固有大小(Intrinsic Size)。视控件的不同，固有大小可以在水平或竖直或同时两个方向上有效。当一个控件没有明确的宽度和高度约束时，就会使用它的固有大小作为约束。这允许我们在每个方向上只使用一个显式约束就可以创建明确的布局(相对于上面第1条规则)，并让控件可以根据自身的内容来自动调整大小。这是在本地化中创建一个最佳布局的关键。

## Interface Builder中的Auto Layout

*更新于2014.3.3：当我写这篇文章时，Xcode的版本是4.x。到了Xcode 5时，Interface Builder对Auto Layout的处理已以有了显著的改变，所以下面的一些内容已经不再有效(特别是第3、4条)。Xcode现在允许Interface Builder在创建模棱两可的布局，并在编译时添加missing constraints来明确一个布局。这使得在开发过程中，原型的设计和快速变更来得更加简单。第5、6条在Xcode 5中仍然是有效的。*

Interface Builder中的Auto Layout编辑器似乎有自己的想法。理解Xcode的工程师为什么这样设计，可以让我们使用它是不至于太过沮丧。

![image](http://oleb.net/media/interface-builder-constraints-editor-context-menu.png)

图1：如果某个约束会导致模棱两可的布局，IB是不允许我们删除它的



### 3.IB总是不让你创建一个模棱两可的布局

IB的主要目标是保护我们自己。它决不会让我们创建一个模棱两可的布局。这意味着IB在我们将一个视图放到一个布局中时，会自动为我们创建约束。沿着IB的自动引导来放置我们的视图，以帮助IB正确的猜测我们想把视图放哪。

### 4.在我们删除一个已存在的约束之前，必须创建另外一个约束

使用Size Inspector来查看一个指定视图的所有约束。当一个约束的Delete菜单项是置灰时，就表示删除这个约束会导致混乱，因此这是不允许的。在删除它之前，我们必须创建至少一个自定义约束来取代它。

![image](http://oleb.net/media/interface-builder-create-constraints-ui.png)

图2：创建新的布局约束的IB界面

为了创建一个新的约束，在布局中选择一个或多个视图，然后使用画布右下角的三个不显眼按钮来创建约束。这都是很容易被忽视的。

### 5.不要显式地调整控件的大小

尝试不要显式地设置一个控件的大小。只要我们不手动去改变它们的大小，大部分控件都会根据它们的内容来调整自己的大小，并使用固有大小(intrinsic size)来创建一个完美的、内容敏感的布局。这对于需要做本地化的UI尤其重要。一旦我们(无意或有意地)手动调整了控件的大小，IB将创建一个很难摆脱的显式大小约束。为了回归到固有大小，可以使用Editor > Size to Fit Content命令。

### 6.避免过早优化

不幸的是，使用Interface Builder来做自动布局将迫使我们更加小心。例如，如果我们发现需要使用一个控件来替换另一个，从布局中删除原始控件可能导致IB自动创建一组新的约束，当我们插入新的控件时，需要再次手动修改这些约束。因此，在我们的布局仍处于不稳定状态时去优化我们的约束，可能并不是一个好主意。更好的是在它更稳定时再去优化它。

## 代码中的Auto Layout

在Interface Builder中使用Auto Layout中可能很快就会有种挫折感，因此更多的开发者喜欢在代码中使用Auto Layout。

### 7.忘记Frame吧

忘记frame属性吧。不要直接设置它。一个视图的frame在自动布局过程中会被自动设置，而不是一个输入结果。我们可以通过改变约束来改变frame。这将强迫我们改变看待UI的方式。不用再去考虑位置和大小了，而是考虑每个视图相对于它的兄弟视图和父视图的位置。这与CSS没有什么不同。

### 8.别忘了禁用Autoresizing Masks

为了保证代码的向后兼容性，sprints-struts模式仍然是默认的。对于每一个代码创建的需要使用Auto Layout的视图，请调用`setTranslatesAutoresizingMaskIntoConstraints:NO`。

### 9.多留意Debugger控制台

当我们写约束时，应该多留意Debugger控制台。我发现Apple关于模棱两可的约束或未满足的约束的错误日志总是可以帮助我们快速定位问题。这个可以参考[Apple’s debugging tips in the Cocoa Auto Layout Guide](https://developer.apple.com/library/ios/documentation/userexperience/conceptual/AutolayoutPG/ResolvingIssues/ResolvingIssues.html#//apple_ref/doc/uid/TP40010853-CH17-SW14)。

### 10.让约束动起来，而不是frame

在Auto Layout中，我们需要重新考虑动画。我们不再可以简单的动画一个视图的frame了；如果我们这样做了，视图将在动画完成后自动恢复到Auto Layout计算出来的位置和大小上。相反，我们需要直接动画布局的约束。要做到这一点，或者修改已存在的约束（我们可以为IB中创建的约束声明`IBOutlet`变量），也可以添加一个新的约束，然后在一个动画block中给我们的视图发送`layoutIfNeeded`消息。

### 注释

1. 在垂直维度，leading和trailing空间分别表示为top和bottom空间。在水平维度，我们可以选择两个方向：“Leading to Trailing” 或者是 “Left to Right”。这两者的不同之处在于，如果本地语言是从右到左的，则"Leading to Trailing”表示的就是”Right to Left”。在大多数时候，我们需要的是“Leading to Trailing”。

