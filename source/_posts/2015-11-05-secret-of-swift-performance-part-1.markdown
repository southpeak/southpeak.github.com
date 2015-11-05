---
layout: post
title: "Secret of Swift Performance Part 1 - Measure"
date: 2015-11-05 22:54:01 +0800
comments: true
categories: translate ios
---

原文由`Kostiantyn Koval`发表于`Medium`，地址为[Secret of Swift Performance ：Part 1 — Measure](https://medium.com/swift-programming/secret-of-swift-performance-a8ee86060843)

`Swift`性能方面的讨论已经很多了。如：它真的比`C`快么？它怎样才能更快？ 去`Google`一下吧。

但是作为一个`App`开发者，我们需要知道如何以更简单的方式让我们的`App`更快。那加速`App`的银弹又是什么呢？

## 找出性能瓶颈

找出`App`的性能瓶颈是很重要的。按照`80/20`的原则来说，“大约`20%`的代码占用了`80%`的运行速度”，这意味着我们需要找出这`20%`的代码并优化它，而不用关心剩余的`80%`。

我写了个简单的带有一个闭包参数的测试函数，它的主要功能是测试闭包代码的运行速度。让我们来分析一下这段代码。

``` objective-c
func measure(title: String!, call: () -> Void) {
    let startTime = CACurrentMediaTime()
    call()
    let endTime = CACurrentMediaTime()
    if let title = title {
        print("\(title): ")
    }
    println("Time - \(endTime - startTime)")
}
```

这个测试函数的参数有两个：辅助分析的可选名称(`title`)和类型为`()->()`的闭包函数。相当简单吧。它在调用`call()`的前后分别获取了当前时间，并打印出`call()`执行所花费的时间。

让我们来试一下吧。我有一个函数，它的职责是迭代一个数组，并加载图片。我想看看它需要花费多少时间。我们简单地包装一下这个代码块以方便测试函数调用。在这里我们使用了尾随闭包语义，看上去非常棒。

``` objective-c
func doSomeWork() {

    measure("Array") {
        var ar = [String]()
        for i in 0...10000 {
            ar.append("New elem \(i)")
        }
    }

    measure("Image") {
        let url = NSURL(string: "http://lorempixel.com/1920/1920/")
        let image = UIImage(data:NSData(contentsOfURL:url!)!)
    }
}
```

测试结果是

``` objective-c
Array: Time — 0.0845723639995413
Image: Time — 1.77442857499955
```



![image](https://d262ilb51hltx0.cloudfront.net/max/600/1*zCF2DX5VqNOmxgg8qs7z2w.png)



现在你知道了哪块代码占用了更多时间，然后就需要去优化它或者将其移到二级线程中处理。

## 提醒

应该总是在`Release`模式且`Optimization Level`设置为`[-Os]`或`[-Ofast]`的情况下去测试运行速度。

![image](https://d262ilb51hltx0.cloudfront.net/max/800/1*Ea6yWoxe99jG_-kSAVd8eA.png)

