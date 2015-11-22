---
layout: post
title: "Secret of Swift Performance Part 2 - Look under the hood"
date: 2015-11-05 22:56:20 +0800
comments: true
categories: translate ios
---

原文由`Kostiantyn Koval`发表于`Medium`，地址为[Secret of Swift Performance ：Part 2 - Look under the hood](https://medium.com/swift-programming/secret-of-swift-performance-fcc5d2a437a8)。

当想要分析一个`App`的性能时，`Instruments`和`Measure`绝对是我们最好的朋友。我希望每个人都了解`Instruments`并至少使用过一次。`Instruments`提供了许多非常有用的工具，来告诉我们：“我们的`App`使用了多少内存”，“`App`有多快”，“有没有内存泄漏”等等。

但作为一个软件攻城狮，我们同样需要知道“为什么…？”，“为什么它发生了？”

在我使用`Swift`时，我曾经看到一些我当时无法理解但很有意思的东西。“为什么这段代码运行这么快？”为了回答这个问题，我必须查看编译出来的汇编代码。这其实并不难，而且非常有用。接下来就来看看是如何做的。

## 编译Swift代码

我们只是想编译并分析部分代码，而不是整个工程。为此我们需要做几件事：

- 创建一个新的`Swift`文件。
- 创建一个简单的测试函数`func test() { ... // 具体代码 }`。
- 将需要编译和分析的代码拷贝到函数体中。
- 调用函数。

这里我们做的是定义一个测试函数，函数体是我们想要检查和分析的代码。当然，我们需要在顶层调用这个函数。

现在我们需要编译这个文件。可以借助于`xcrun`(Xcode工具)和`swiftc`(Swift编译器命令行工具)。

- 打开终端并通过`cd`命令切换到`Swift`文件所在的目录。
- 运行命令"`xcrun swiftc -Onone inputFile.swift -o resultFileName`"。如**xcrun swiftc -Onone Assembly.swift -o result**。

这个命令将会编译我们的`Swift`文件。

我们可以使用`xcrun swiftc -help`命令来查看`xcrun swiftc`命令的帮助文档。当前我们最感兴趣的是一些优化选项：

- **-O**：编译时优化
- **-Onone**：编译时不做任何优化
- **-Ounchecked**：编译时优化并移除运行时安全检查

使用**-O**选项很重要。它就跟编译`App`时使用`Release`模式一样。通常用来分析要上传到`AppStore`上的代码。

作为测试，我们使用**-Onone**模式，因为它生成的汇编代码非常类似于我们的源代码。也可以分别生成两种模式下的代码来做比较。这样我们可以学习下`Swift`编译器是如何做优化的。

运行：**xcrun swiftc -Onone Assembly.swift -o none**

会生成一个可执行文件，可以双击运行它。

![image](https://cdn-images-1.medium.com/max/600/1*LLrYPKt2oVbzU5CcOrixdQ.png)

当编译一个`Swift`文件时，`Swift`编译器做了以下几件事：

- 创建一个带有**int main(int arg0, int arg1)**函数的控制台应用。这是应用的起点。
- 创建**_top_level_code**函数。该函数的函数体是`Swift`文件的顶层可执行代码。在我们的示例中就是调用了`test()`函数。

## 获取汇编代码

有许多办法来获取汇编代码。我建议使用`Hopper`。可以在[这里](http://www.hopperapp.com/download.html)下载并使用`Demo`模式。使用`Hopper`最棒的是它可以显示汇编的伪代码，使用起来比较方便。

让我们来获取汇编代码：

- 打开`Hopper` > `File` > `Read Executable to Disassemble`，选择可执行文件，点击OK

![image](https://cdn-images-1.medium.com/max/600/1*CcC_vQGU8CWz1qkshLNDWQ.png)



![image](https://cdn-images-1.medium.com/max/600/1*oEF3HyJj3t0pKWUwMyft7w.png)



![image](https://cdn-images-1.medium.com/max/600/1*Zv5uaktNpsTZ9f5KE7xqeg.png)



## Hopper概述

![image](https://cdn-images-1.medium.com/max/800/1*DiIcK4QP2UQ2glHxwgW4rQ.png)



`Hopper`的界面类似于`Xcode`，左侧是导航面板，中间是编辑面板，右侧是帮助和`Inspector`面板。

**左侧面板**—在这里可以找到所有函数，串标记和字符串，可以点击它们导航到对应的汇编代码。

**编辑区**— 显示汇编代码，它类似于`Xcode`的`Swift`或其它。我们可以使用箭头来导航。

## 分析代码

首先我们需要找到应用入口，在我们的示例中是`_main`函数。在左侧导航面板中选择它。下面是`_main`函数的汇编代码。

![image](https://cdn-images-1.medium.com/max/800/1*uzIzPacXGRgXGa_tVi9wlw.png)

汇编代码很难分析，不过`Hopper`可以生成伪代码。使用快捷键"`Alt+Enter`"或者"`Window` > `Show Pseudo Code of Procedure`"。现在可以看到`_main`函数的伪代码了。

![image](https://cdn-images-1.medium.com/max/800/1*Sm4MRfqUCjjf3DCB3udDLA.png)

这样好多了!!

前4行是提取`_main`函数的参数，我们对此不感兴趣。然后调用了**_top_level_code()**，正如前面提到的，这应该就是我们的代码。让我们来看看。关闭伪代码视图，选择**_top_level_code**函数并显示其伪代码。

![image](https://cdn-images-1.medium.com/max/800/1*ev3n_N8Ai6NCN6tJeFLCVg.png)



它只调用了**\_\_TF4none4testFT\_T\_()\_**函数。

`Swift`生成的函数有特定的命名规范。即模块名+函数名+字符数+参数类型+其它东西。[Mike Ash](https://mikeash.com/pyblog/friday-qa-2014-08-15-swift-name-mangling.html)详细介绍了这一规范。

这里可以看到的是**none**(文件名)， **test**(函数名)。基于这一点，我们可以说它就是`test()`函数。让我们来检查一下。查找`__TF4none4testFT_T_`并显示其伪代码。

![image](https://cdn-images-1.medium.com/max/800/1*e5LfhINe2u_73NBzP8aNNQ.png)

它有3个变量，是16进制格式的，转换一下：

``` objective-c
var_8 = 10,
var_10 = 10,
var_18 = 20
```

这和我们的源代码非常相似，但源代码有一个相加操作，`Swift`在编译期直接计算出结果了。

``` objective-c
var x = 10
var y = 10
var c = x + y
```

现在你已经知道了：编译`Swift`代码，反汇编及分析汇编代码。深入后，你可以学习并发现许多有趣的东西。作为比较，我们现在使用**-O**模式来编译下代码，以看看`Swift`编译器是如何优化代码的。

运行**xcrun swiftc -O Assembly.swift -o optimized**命令。

![image](https://cdn-images-1.medium.com/max/800/1*zZTA8GKacYtlFL5QgPaHtg.png)

正如你所见的，在主函数中没有调用任何函数。没有**_top_level_code**。没有调用`test()`函数。

`Swift`编译器检测到`test`函数的结果没有被使用，所以将其忽略。而**_top_level_code**也只调用了一个`test()`函数，所以也被忽略了。结果是我们获得了一个空的主函数。

这篇文章描述了如何使用工具来分析代码。我发现了许多用这些工具优化`Swift`的方法，这些方法非常有意思。我将在第三部分中与你们分享，敬请期待......

*注：强烈建议手动操作一下，看看自己得到的结果是什么。*