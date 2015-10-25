---
layout: post
title: "UIKit: UIResponder"
date: 2015-03-07 18:54:23 +0800
comments: true
categories: Cocoa iOS
---

我们的`App`与用户进行交互，基本上是依赖于各种各样的事件。例如，用户点击界面上的按钮，我们需要触发一个按钮点击事件，并进行相应的处理，以给用户一个响应。`UIView`的三大职责之一就是处理事件，一个视图是一个事件响应者，可以处理点击等事件，而这些事件就是在`UIResponder`类中定义的。

一个`UIResponder`类为那些需要响应并处理事件的对象定义了一组接口。这些事件主要分为两类：触摸事件(`touch events`)和运动事件(`motion events`)。`UIResponder`类为每两类事件都定义了一组接口，这个我们将在下面详细描述。

在`UIKit`中，`UIApplication`、`UIView`、`UIViewController`这几个类都是直接继承自`UIResponder`类。另外`SpriteKit`中的`SKNode`也是继承自`UIResponder`类。因此UIKit中的视图、控件、视图控制器，以及我们自定义的视图及视图控制器都有响应事件的能力。这些对象通常被称为响应对象，或者是响应者(以下我们统一使用响应者)。

本文将详细介绍一个`UIResponder`类提供的基本功能。不过在此之前，我们先来了解一下事件响应链机制。

## 响应链

大多数事件的分发都是依赖响应链的。响应链是由一系列链接在一起的响应者组成的。一般情况下，一条响应链开始于第一响应者，结束于`application`对象。如果一个响应者不能处理事件，则会将事件沿着响应链传到下一响应者。

那这里就会有三个问题：

1. 响应链是何时构建的
2. 系统是如何确定第一响应者的
3. 确定第一响应者后，系统又是按照什么样的顺序来传递事件的

### 构建响应链

我们都知道在一个App中，所有视图是按一定的结构组织起来的，即树状层次结构。除了根视图外，每个视图都有一个父视图；而每个视图都可以有0个或多个子视图。而在这个树状结构构建的同时，也构建了一条条的事件响应链。

### 确定第一响应者

当用户触发某一事件(触摸事件或运动事件)后，`UIKit`会创建一个事件对象(`UIEvent`)，该对象包含一些处理事件所需要的信息。然后事件对象被放到一个事件队列中。这些事件按照先进先出的顺序来处理。当处理事件时，程序的`UIApplication`对象会从队列头部取出一个事件对象，将其分发出去。通常首先是将事件分发给程序的主`window`对象，对于触摸事件来讲，`window`对象会首先尝试将事件分发给触摸事件发生的那个视图上。这一视图通常被称为`hit-test`视图，而查找这一视图的过程就叫做`hit-testing`。

系统使用`hit-testing`来找到触摸下的视图，它检测一个触摸事件是否发生在相应视图对象的边界之内(即视图的`frame`属性，这也是为什么子视图如果在父视图的`frame`之外时，是无法响应事件的)。如果在，则会递归检测其所有的子视图。包含触摸点的视图层次架构中最底层的视图就是`hit-test`视图。在检测出`hit-test`视图后，系统就将事件发送给这个视图来进行处理。

我们通过一个示例来演示`hit-testing`的过程。图1是一个视图层次结构，

![image](https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/Art/hit_testing_2x.png)

假设用户点击了视图E，系统按照以下顺序来查找`hit-test`视图：

1. 点击事件发生在视图A的边界内，所以检测子视图B和C；
2. 点击事件不在视图B的边界内，但在视图C的边界范围内，所以检测子图片D和E；
3. 点击事件不在视图D的边界内，但在视图E的边界范围内；

视图E是包含触摸点的视图层次架构中最底层的视图(倒树结构)，所以它就是`hit-test`视图。

`hit-test`视图可以最先去处理触摸事件，如果`hit-test`视图不能处理事件，则事件会沿着响应链往上传递，直到找到能处理它的视图。

### 事件传递

最有机会处理事件的对象是`hit-test`视图或第一响应者。如果这两者都不能处理事件，`UIKit`就会将事件传递到响应链中的下一个响应者。每一个响应者确定其是否要处理事件或者是通过`nextResponder`方法将其传递给下一个响应者。这一过程一直持续到找到能处理事件的响应者对象或者最终没有找到响应者。

图2演示了这样一个事件传递的流程，

![image](https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/Art/iOS_responder_chain_2x.png)

当系统检测到一个事件时，将其传递给初始对象，这个对象通常是一个视图。然后，会按以下路径来处理事件(我们以左图为例)：

1. 初始视图(`initial view`)尝试处理事件。如果它不能处理事件，则将事件传递给其父视图。
2. 初始视图的父视图(`superview`)尝试处理事件。如果这个父视图还不能处理事件，则继续将视图传递给上层视图。
3. 上层视图(`topmost view`)会尝试处理事件。如果这个上层视图还是不能处理事件，则将事件传递给视图所在的视图控制器。
4. 视图控制器会尝试处理事件。如果这个视图控制器不能处理事件，则将事件传递给窗口(`window`)对象。
5. 窗口(`window`)对象尝试处理事件。如果不能处理，则将事件传递给单例`app`对象。
6. 如果`app`对象不能处理事件，则丢弃这个事件。

从上面可以看到，视图、视图控制器、窗口对象和`app`对象都能处理事件。另外需要注意的是，手势也会影响到事件的传递。

以上便是响应链的一些基本知识。有了这些知识，我们便可以来看看`UIResponder`提供给我们的一些方法了。

## 管理响应链

`UIResponder`提供了几个方法来管理响应链，包括让响应对象成为第一响应者、放弃第一响应者、检测是否是第一响应者以及传递事件到下一响应者的方法，我们分别来介绍一下。

上面提到在响应链中负责传递事件的方法是`nextResponder`，其声明如下：

``` objective-c
- (UIResponder *)nextResponder
```

`UIResponder`类并不自动保存或设置下一个响应者，该方法的默认实现是返回`nil`。子类的实现必须重写这个方法来设置下一响应者。`UIView`的实现是返回管理它的`UIViewController`对象(如果它有)或者其父视图。而`UIViewController`的实现是返回它的视图的父视图；`UIWindow`的实现是返回`app`对象；而`UIApplication`的实现是返回nil。所以，响应链是在构建视图层次结构时生成的。

一个响应对象可以成为第一响应者，也可以放弃第一响应者。为此，`UIResponder`提供了一系列方法，我们分别来介绍一下。

如果想判定一个响应对象是否是第一响应者，则可以使用以下方法：

``` objective-c
- (BOOL)isFirstResponder
```

如果我们希望将一个响应对象作为第一响应者，则可以使用以下方法：

``` objective-c
- (BOOL)becomeFirstResponder
```

如果对象成为第一响应者，则返回YES；否则返回NO。默认实现是返回YES。子类可以重写这个方法来更新状态，或者来执行一些其它的行为。

一个响应对象只有在当前响应者能放弃第一响应者状态(`canResignFirstResponder`)且自身能成为第一响应者(`canBecomeFirstResponder`)时才会成为第一响应者。

这个方法相信大家用得比较多，特别是在希望`UITextField`获取焦点时。另外需要注意的是只有当视图是视图层次结构的一部分时才调用这个方法。如果视图的`window`属性不为空时，视图才在一个视图层次结构中；如果该属性为`nil`，则视图不在任何层次结构中。

上面提到一个响应对象成为第一响应者的一个前提是它可以成为第一响应者，我们可以使用`canBecomeFirstResponder`方法来检测，

``` objective-c
- (BOOL)canBecomeFirstResponder
```

需要注意的是我们不能向一个不在视图层次结构中的视图发送这个消息，其结果是未定义的。

与上面两个方法相对应的是响应者放弃第一响应者的方法，其定义如下：

``` objective-c
- (BOOL)resignFirstResponder
- (BOOL)canResignFirstResponder
```

`resignFirstResponder`默认也是返回YES。需要注意的是，如果子类要重写这个方法，则在我们的代码中必须调用`super`的实现。

`canResignFirstResponder`默认也是返回YES。不过有些情况下可能需要返回NO，如一个输入框在输入过程中可能需要让这个方法返回NO，以确保在编辑过程中能始终保证是第一响应者。

## 管理输入视图

所谓的输入视图，是指当对象为第一响应者时，显示另外一个视图用来处理当前对象的信息输入，如`UITextView`和`UITextField`两个对象，在其成为第一响应者是，会显示一个系统键盘，用来输入信息。这个系统键盘就是输入视图。输入视图有两种，一个是`inputView`，另一个是`inputAccessoryView`。这两者如图3所示：

![image](http://images.cnblogs.com/cnblogs_com/kuku/b.jpg)

与`inputView`相关的属性有如下两个，

``` objective-c
@property(nonatomic, readonly, retain) UIView *inputView
@property(nonatomic, readonly, retain) UIInputViewController *inputViewController
```

这两个属性提供一个视图(或视图控制器)用于替代为`UITextField`和`UITextView`弹出的系统键盘。我们可以在子类中将这两个属性重新定义为读写属性来设置这个属性。如果我们需要自己写一个键盘的，如为输入框定义一个用于输入身份证的键盘(只包含0-9和X)，则可以使用这两个属性来获取这个键盘。

与`inputView`类似，`inputAccessoryView`也有两个相关的属性：

``` 
@property(nonatomic, readonly, retain) UIView *inputAccessoryView
@property(nonatomic, readonly, retain) UIInputViewController *inputAccessoryViewController
```

设置方法与前面相同，都是在子类中重新定义为可读写属性，以设置这个属性。

另外，`UIResponder`还提供了以下方法，在对象是第一响应者时更新输入和访问视图，

``` 
- (void)reloadInputViews
```

调用这个方法时，视图会立即被替换，即不会有动画之类的过渡。如果当前对象不是第一响应者，则该方法是无效的。

## 响应触摸事件

`UIResponder`提供了如下四个大家都非常熟悉的方法来响应触摸事件：

``` objective-c
// 当一个或多个手指触摸到一个视图或窗口
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
// 当与事件相关的一个或多个手指在视图或窗口上移动时
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
// 当一个或多个手指从视图或窗口上抬起时
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
// 当一个系统事件取消一个触摸事件时
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
```

这四个方法默认都是什么都不做。不过，`UIKit`中`UIResponder`的子类，尤其是`UIView`，这几个方法的实现都会把消息传递到响应链上。因此，为了不阻断响应链，我们的子类在重写时需要调用父类的相应方法；而不要将消息直接发送给下一响应者。

默认情况下，多点触摸是被禁用的。为了接受多点触摸事件，我们需要设置响应视图的`multipleTouchEnabled`属性为YES。

## 响应移动事件

与触摸事件类似，`UIResponder`也提供了几个方法来响应移动事件：

``` objective-c
// 移动事件开始
- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
// 移动事件结束
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
// 取消移动事件
- (void)motionCancelled:(UIEventSubtype)motion withEvent:(UIEvent *)event
```

与触摸事件不同的是，运动事件只有开始与结束操作；它不会报告类似于晃动这样的事件。这几个方法的默认操作也是什么都不做。不过，`UIKit`中`UIResponder`的子类，尤其是`UIView`，这几个方法的实现都会把消息传递到响应链上。

## 响应远程控制事件

远程控制事件来源于一些外部的配件，如耳机等。用户可以通过耳机来控制视频或音频的播放。接收响应者对象需要检查事件的子类型来确定命令(如播放，子类型为`UIEventSubtypeRemoteControlPlay`)，然后进行相应处理。

为了响应远程控制事件，`UIResponder`提供了以下方法，

``` objective-c
- (void)remoteControlReceivedWithEvent:(UIEvent *)event
```

我们可以在子类中实现该方法，来处理远程控制事件。不过，为了允许分发远程控制事件，我们必须调用`UIApplication`的`beginReceivingRemoteControlEvents`方法；而如果要关闭远程控制事件的分发，则调用`endReceivingRemoteControlEvents`方法。

## 获取Undo管理器

默认情况下，程序的每一个`window`都有一个undo管理器，它是一个用于管理undo和redo操作的共享对象。然而，响应链上的任何对象的类都可以有自定义undo管理器。例如，`UITextField`的实例的自定义管理器在文件输入框放弃第一响应者状态时会被清理掉。当需要一个undo管理器时，请求会沿着响应链传递，然后`UIWindow`对象会返回一个可用的实例。

`UIResponder`提供了一个只读方法来获取响应链中共享的undo管理器，

``` objective-c
@property(nonatomic, readonly) NSUndoManager *undoManager
```

我们可以在自己的视图控制器中添加undo管理器来执行其对应的视图的undo和redo操作。

## 验证命令

在我们的应用中，经常会处理各种菜单命令，如文本输入框的"复制"、"粘贴"等。`UIResponder`为此提供了两个方法来支持此类操作。首先使用以下方法可以启动或禁用指定的命令：

``` 
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
```

该方法默认返回YES，我们的类可以通过某种途径处理这个命令，包括类本身或者其下一个响应者。子类可以重写这个方法来开启菜单命令。例如，如果我们希望菜单支持"`Copy`"而不支持"`Paser`"，则在我们的子类中实现该方法。需要注意的是，即使在子类中禁用某个命令，在响应链上的其它响应者也可能会处理这些命令。

另外，我们可以使用以下方法来获取可以响应某一行为的接收者：

``` objective-c
- (id)targetForAction:(SEL)action withSender:(id)sender
```

在对象需要调用一个`action`操作时调用该方法。默认的实现是调用`canPerformAction:withSender:`方法来确定对象是否可以调用`action`操作。如果可以，则返回对象本身，否则将请求传递到响应链上。如果我们想要重写目标的选择方式，则应该重写这个方法。下面这段代码演示了一个文本输入域禁用拷贝/粘贴操作：

``` objective-c
- (id)targetForAction:(SEL)action withSender:(id)sender
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    if (action == @selector(selectAll:) || action == @selector(paste:) ||action == @selector(copy:) || action == @selector(cut:)) {
        if (menuController) {
            [UIMenuController sharedMenuController].menuVisible = NO;
        }
        return nil;
    }
    return [super targetForAction:action withSender:sender];
}
```

## 访问快捷键命令

我们的应用可以支持外部设备，包括外部键盘。在使用外部键盘时，使用快捷键可以大大提高我们的输入效率。因此从iOS7后，`UIResponder`类新增了一个只读属性`keyCommands`，来定义一个响应者支持的快捷键，其声明如下：

``` objective-c
@property(nonatomic, readonly) NSArray *keyCommands
```

一个支持硬件键盘命令的响应者对象可以重新定义这个方法并使用它来返回一个其所支持快捷键对象(`UIKeyCommand`)的数组。每一个快捷键命令表示识别的键盘序列及响应者的操作方法。

我们用这个方法返回的快捷键命令数组被用于整个响应链。当与快捷键命令对象匹配的快捷键被按下时，`UIKit`会沿着响应链查找实现了响应行为方法的对象。它调用找到的第一个对象的方法并停止事件的处理。

## 管理文本输入模式

文本输入模式标识当响应者激活时的语言及显示的键盘。`UIResponder`为此定义了一个属性来返回响应者对象的文本输入模式：

``` objective-c
@property(nonatomic, readonly, retain) UITextInputMode *textInputMode
```

对于响应者而言，系统通常显示一个基于用户语言设置的键盘。我们可以重新定义这个属性，并让它返回一个不同的文本输入模式，以让我们的响应者使用一个特定的键盘。用户在响应者被激活时仍然可以改变键盘，在切换到另一个响应者时，可以再恢复到指定的键盘。

如果我们想让`UIKit`来跟踪这个响应者的文本输入模式，我们可以通过`textInputContextIdentifier`属性来设置一个标识，该属性的声明如下：

``` objective-c
@property(nonatomic, readonly, retain) NSString *textInputContextIdentifier
```

该标识指明响应者应保留文本输入模式的信息。在跟踪模式下，任何对文本输入模式的修改都会记录下来，当响应者激活时再用于恢复处理。

为了从程序的`user default`中清理输入模式信息，`UIResponder`定义了一个类方法，其声明如下：

``` objective-c
+ (void)clearTextInputContextIdentifier:(NSString *)identifier
```

调用这个方法可以从程序的`user default`中移除与指定标识相关的所有文本输入模式。移除这些信息会让响应者重新使用默认的文本输入模式。

## 支持User Activities

从iOS 8起，苹果为我们提供了一个非常棒的功能，即`Handoff`。使用这一功能，我们可以在一部iOS设备的某个应用上开始做一件事，然后在另一台iOS设备上继续做这件事。`Handoff`的基本思想是用户在一个应用里所做的任何操作都可以看作是一个`Activity`，一个`Activity`可以和一个特定`iCloud`用户的多台设备关联起来。在编写一个支持`Handoff`的应用时，会有以下三个交互事件：

1. 为将在另一台设备上继续做的事创建一个新的`User Activity`；
2. 当需要时，用新的数据更新已有的`User Activity`；
3. 把一个`User Activity`传递到另一台设备上。

为了支持这些交互事件，在iOS 8后，`UIResponder`类新增了几个方法，我们在此不讨论这几个方法的实际使用，想了解更多的话，可以参考[iOS 8 Handoff 开发指南](http://www.cocoachina.com/ios/20150115/10926.html)。我们在此只是简单描述一下这几个方法。

在`UIResponder`中，已经为我们提供了一个`userActivity`属性，它是一个`NSUserActivity`对象。因此我们在`UIResponder`的子类中不需要再去声明一个`userActivity`属性，直接使用它就行。其声明如下：

``` objective-c
@property(nonatomic, retain) NSUserActivity *userActivity
```

由`UIKit`管理的`User Activities`会在适当的时间自动保存。一般情况下，我们可以重写`UIResponder`类的`updateUserActivityState:`方法来延迟添加表示`User Activity`的状态数据。当我们不再需要一个`User Activity`时，我们可以设置`userActivity`属性为nil。任何由`UIKit`管理的`NSUserActivity`对象，如果它没有相关的响应者，则会自动失效。

另外，多个响应者可以共享一个`NSUserActivity`实例。

上面提到的`updateUserActivityState:`是用于更新给定的`User Activity`的状态。其定义如下：

``` objective-c
- (void)updateUserActivityState:(NSUserActivity *)activity
```

子类可以重写这个方法来按照我们的需要更新给定的`User Activity`。我们需要使用`NSUserActivity`对象的`addUserInfoEntriesFromDictionary:`方法来添加表示用户`Activity`的状态。

在我们修改了`User Activity`的状态后，如果想将其恢复到某个状态，则可以使用以下方法：

``` objective-c
- (void)restoreUserActivityState:(NSUserActivity *)activity
```

子类可以重写这个方法来使用给定`User Activity`的恢复响应者的状态。系统会在接收到数据时，将数据传递给`application:continueUserActivity:restorationHandler:`以做处理。我们重写时应该使用存储在`user activity`的`userInfo`字典中的状态数据来恢复对象。当然，我们也可以直接调用这个方法。

## 参考

1. [UIResponder Class Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIResponder_Class)
2. [Event Handling Guide for iOS](https://developer.apple.com/library/ios/documentation/EventHandling/Conceptual/EventHandlingiPhoneOS/Introduction/Introduction.html)
3. [iOS UIResponder 学习笔记](http://www.cnblogs.com/kuku/archive/2011/11/12/2246389.html)
4. [如何让你的iOS7应用支持键盘快捷键](http://firestudio.cn/blog/2013/12/26/ru-he-rang-ni-de-ios7ying-yong-zhi-chi-jian-pan-kuai-jie-jian/)
5. [iOS 8 Handoff 开发指南](http://www.cocoachina.com/ios/20150115/10926.html)
6. [iOS 8 Handoff Tutorial](http://southpeak.github.io/blog/2015/03/01/fan-yi-pian-:ios-8-handoff-tutorial/)