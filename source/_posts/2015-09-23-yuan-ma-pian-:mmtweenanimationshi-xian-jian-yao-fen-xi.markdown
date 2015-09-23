---
layout: post
title: "源码篇：MMTweenAnimation实现简要分析"
date: 2015-09-23 20:18:24 +0800
comments: true
categories: iOS
---

先来个效果图吧：

![image](https://raw.githubusercontent.com/adad184/MMTweenAnimation/master/Images/2.gif)

这是`MMTweenAnimation`库实现的一个弹跳动画。`MMTweenAnimation`基于Facebook的`pop`动画库，它提供了10套自定义的动画曲线，分别是：`Back`、`Bounce`、`Circ`、`Cubic`、`Elastic`、`Expo`、`Quad`、`Quart`、`Quint`、`Sine`。具体的效果可以参考[MMTweenAnimation](https://github.com/adad184/MMTweenAnimation)。

在这里，我们主要来`MMTweenAnimation`的具体实现及使用。

我们知道，动画实际上是许多帧静止的画面，以一定的速度连续播放，由于肉眼视觉残象产生的错觉，因此我们感觉画面是活动的。这就是动画的基本原理。所以，我们要做的就是按一定的速率去播放帧，在每一帧中计算曲线的路径，并将其绘制到界面上。这主要涉及到曲线的插值算法。

### 主要部件

`MMTweenAnimation`的主体类主要有两个：`MMTweenAnimation`和`MMTweenFunction`。`MMTweenFunction`类主要定义各种插值算法，`MMTweenAnimation`主要是实现动画操作。

#### MMTweenFunction类

`MMTweenFunction`类主要是实现各种插值算法。这些插值算法分别10类，即上面列出的10套动画。而每套根据不同的缓动方式，又分为`EaseIn`、`EaseOut`、`EaseInOut`三种，因此`MMTweenAnimation`库实际上是实现了30种动画。每个插值算法都实现为一个闭包函数，其定义如下：

``` objective-c
typealias MMTweenFunctionBlock = (t: CFTimeInterval,            // 当前时间与起始时间的差值
                                  b: Double,                    // 起点
                                  c: Double,                    // 起点与终点的差值
                                  d: CFTimeInterval) -> Double  // 动画持续时间
```

而每个动画的插值都是根据数学公式算法出来的，我们以图例中的`Bounce-EaseOut`动画为例，其实现如下：

``` objective-c
let bounceOut: MMTweenFunctionBlock = { (t, b, c, d) -> Double in
    let k: Double = 2.75
    var t1 = t / d
    if t1 < (1 / k) {
        return c * (7.5625 * t1 * t1) + b
    } else if t1 < (2 / k) {
        t1 -= 1.5 / k
        return c * (7.5625 * t1 * t1 + 0.75) + b
    } else if t1 < (2.5 / k) {
        t1 -= 2.25 / k
        return c * (7.5625 * t1 * t1 + 0.9375) + b
    } else {
        t1 -= 2.625 / k
        return c * (7.5625 * t1 * t1 + 0.984375) + b
    }
}
```

计算出来的插值将会用于计算当前帧的终点值。

#### MMTweenAnimation类

`MMTweenAnimation`是实现动画的主体类。这个类继承自`pop`的`POPCustomAnimation`，`POPCustomAnimation` 直接继承自`PopAnimation`类，用于创建自定义动画的基类，它基本上是一个 `display link`的方便的转换，来在动画的每一个`tick`的回调`block`中驱动自定义的动画。

`MMTweenAnimation`定义了几个基本属性，如下所示：

``` objective-c
class MMTweenAnimation: POPCustomAnimation {
    var animationBlock: MMTweenAnimationBlock?          // 动画回调
    var fromValue: [CGFloat]?                           // 起点数组
    var toValue: [CGFloat]?                             // 终点数组
    var duration: Double = 0.3                          // 动画时长

    // ......
    var functionBlock: MMTweenFunctionBlock?			// 动画插值Block
    // ......

    // ......
    var functionType: MMTweenFunctionType				// 动画插值类型
    // ......

    // ......
    var easingType: MMTweenEasingType					// 动画缓动类型
    // ......
}
```

而`MMTweenAnimation`类最关键的是定义它的回调`block`。`MMTweenAnimation`类定义了一个类方法`animation()`，在这个方法中，通过调用从父类继承来的便捷初始化方法

``` objective-c
public convenience init!(block: POPCustomAnimationBlock!)
```

来创建一个`MMTweenAnimation`对象。其实现如下所示：

``` objective-c
class func animation() -> MMTweenAnimation? {

        let tweaner: MMTweenAnimation = MMTweenAnimation { (target, animation) -> Bool in

            let anim: MMTweenAnimation = animation as! MMTweenAnimation

            let t = animation.currentTime - animation.beginTime // 当前时间与起始时间的差值
            let d = anim.duration

            assert(anim.fromValue!.count == anim.toValue!.count, "fromValue.count != toValue.count")

            if t < d {      // 确保在动画持续时间类才处理
                var values: [CGFloat] = [CGFloat]()

                for i in 0..<anim.fromValue!.count {

                    if let functionBlock = anim.functionBlock {     // 计算插值
                        values.append(CGFloat(functionBlock(t: t, b: Double(anim.fromValue![i]), c: Double(anim.toValue![i]) - Double(anim.fromValue![i]), d: d)))
                    }
                }

                if let animationBlock = anim.animationBlock {   // 动画回调，以实现绘制操作
                    animationBlock(time: t, duration: d, values: values, target: target, animation: anim)
                }

                return true
            } else {
                return false
            }
        }

        return tweaner
    }
```

其中动画回调的定义如下：

``` objective-c
typealias MMTweenAnimationBlock = (time: CFTimeInterval, duration: CFTimeInterval, values: [CGFloat], target: AnyObject, animation: MMTweenAnimation) -> Void
```

以上两个类便是`MMTweenAnimation`的主要部件。

### 动画示例

有了主要部件，我们就来看看怎么去使用它。`MMTweenAnimation`给了一个示例，其效果就是开头的图例。为此，`MMTweenAnimation`定义了类`MMPaintView`，这个类的主要目的就是绘制上面的曲线，其主要操作如下：

``` objective-c
func addDot(point: CGPoint) {
    __dots.append(point)
    // __path = __interpolateCGPointsWithHermite(__dots)
    __path = __interpolateCGPointsWithCatmullRom(__dots)
    setNeedsDisplay()
}
```

这个方法首先是将参数中的点(即每一帧计算出来的终点值)添加到对象的`__dots`数组中，然后再通过`__interpolateCGPointsWithCatmullRom`方法创建一条`Bezier`曲线，最后调用`setNeedsDisplay()`来重新绘制曲线。

我们先来看看这个点是如何获取到的。在`MMAnimationController`类，我们定义动画对象时，设置了其动画回调，如下所示：

``` objective-c
__anim!.animationBlock = { [unowned self] (diff: CFTimeInterval, duration: CFTimeInterval, values: [CGFloat], target: AnyObject, animation: MMTweenAnimation) -> Void in
    let value: CGFloat = values[0]          // 获取当前时间结束点的值

    self.__dummy!.center = CGPoint(x: self.__dummy!.center.x, y: value)     // 计算小红点的中心位置
    self.__ball!.center = CGPoint(x: 50.0 + (CGRectGetWidth(UIScreen.mainScreen().bounds) - 150.0) * CGFloat(diff / duration), y: value)

    self.__paintView!.addDot(self.__ball!.center)
}
```

这个动画回调获取当前时间结束点的值，用于设置小红点的中心位置，同时将这个中心位置的值丢给`MMPaintView`对象去生成`Bezier`曲线。

### 动画渲染操作执行的时间点

知道了`MMTweenAnimation`库的主要部件，我们现在来看看动画是如何被驱动的。我们在`MMTweenAnimation`类的`animation()`方法中，在动画回调的起始位置打个断点，运行一下程序，看看调用栈，如下所示：

![image](https://raw.githubusercontent.com/southpeak/Blog-images/master/MMTweenAnimation-stack.png)

可以看到在`Run Loop`中执行了一个观察者回调，在这个回调中调用了`POPAnimator`对象的`_scheduleProcessPendingList`方法的一个`block`回调，一直追溯到我们的动画操作。也就是说，是在`Run Loop`的某个时刻执行了一次动画的渲染。

我们再从代码入手，来看看动画执行代码是什么时候添加到Run Loop中的。在`MMAnimationController`的`viewDidAppear`方法中，有如下调用：

``` objective-c
__dummy!.pop_addAnimation(__anim, forKey: "center")
```

其中`pop_addAnimation`方法是`POPAnimator`类中定义的。顺着代码，我们最终可以找到`_scheduleProcessPendingList`的定义，其实现如下：

``` objective-c
- (void)_scheduleProcessPendingList
{
  // ......

  if (!_pendingListObserver) {
    __weak POPAnimator *weakSelf = self;
	
    // 添加Run Loop监听器
    _pendingListObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopBeforeWaiting | kCFRunLoopExit, false, POPAnimationApplyRunLoopOrder, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
      [weakSelf _processPendingList];
    });

    if (_pendingListObserver) {
      CFRunLoopAddObserver(CFRunLoopGetMain(), _pendingListObserver,  kCFRunLoopCommonModes);
    }
  }
  // ......
}
```

可以看到在这个方法中创建了一个`Run Loop`的观察者，这个观察者在`Run Loop`的`kCFRunLoopBeforeWaiting`或`kCFRunLoopExit`阶段时会执行监听回调处理函数。回调函数中调用了`_processPendingList`方法，然后从调用栈里面可以看到，一直会执行到`MMTweenAnimation`的动画闭包中，即我们打断点的地方。

OK，动画渲染时间点找着了，那整个流程就可以完整拼接起来了。

### 小结

`MMTweenAnimation`的实现并不复杂，只要了解了动画的基本原理和其中的插值算法，再加上一些`pop`动画的基础知识，基本上就OK了。要想做出很牛B的动画，还是需要大量的数学知识。其实在`MMTweenAnimation`库中，除了那10套插值算法外，在`MMPaintView`类中，计算`Bezier`的控制点时，还用到了Catmull-Rom样条与Hermite样条，大家有兴趣可以研究一下。

`MMTweenAnimation`初始源码是`Objective-C`实现的，我将它用`Swift`重写了一遍，并放在github上，地址是[MMTweenAnimation-Swift](https://github.com/southpeak/Swift/tree/master/Animation/MMTweenAnimation-Swift)，有兴趣可以看一下。

本想放在知识小集中，但由于篇幅稍长，所以独立成篇。

### 参考

1. [MMTweenAnimation](https://github.com/adad184/MMTweenAnimation)
2. [交互式动画](http://objccn.io/issue-12-6/)