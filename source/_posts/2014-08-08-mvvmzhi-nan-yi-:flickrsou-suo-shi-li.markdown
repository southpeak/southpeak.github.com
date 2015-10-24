---
layout: post
title: "MVVM Tutorial with ReactiveCocoa: Part 1/2"
date: 2014-08-08 18:54:42 +0800
comments: true
categories: translate iOS
---

本文由`Colin Eberhardt`发表于`raywenderlich`，原文可查看[MVVM Tutorial with ReactiveCocoa: Part 1/2](http://www.raywenderlich.com/74106/mvvm-tutorial-with-reactivecocoa-part-1)

你可能已经在`Twitter`上听过这个这个笑话了：

> “iOS Architecture, where MVC stands for Massive View Controller”

当然这在`iOS`开发圈内，这是个轻松的笑话，但我敢确定你大实践中遇到过这个问题：即视图控制器太大且难以管理。

这篇文章将介绍另一种构建应用程序的模式--`MVVM(Model-View-ViewModel)`。通过结合`ReactiveCocoa`便利性，这个模式提供了一个很好的代替`MVC`的方案，它保证了让视图控制器的轻量性。

在本文我，我们将通过构建一个简单的`Flickr`查询程序来一步步了解`MVVM`，这个程序的效果图如下所示：

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/FinishedApp.png)

在开始写代码之前，我们先来了解一些基本的原理。

原文简要介绍了一下`ReactiveCocoa`，在此不再翻译，可以查看以下两篇译文：

[ReactiveCocoa Tutorial – The Definitive Introduction: Part 1/2](http://southpeak.github.io/blog/2014/08/02/reactivecocoazhi-nan-%5B%3F%5D-:xin-hao/)

[ReactiveCocoa Tutorial – The Definitive Introduction: Part 2/2](http://southpeak.github.io/blog/2014/08/02/reactivecocoazhi-nan-er-:twittersou-suo-shi-li/)

## MVVM模式介绍

正如其名称一下，`MVVM`是一个`UI`设计模式。它是`MV*`模式集合中的一员。`MV*`模式还包含`MVC(Model View Controller)`、`MVP(Model View Presenter)`等。这些模式的目的在于将UI逻辑与业务逻辑分离，以让程序更容易开发和测试。为了更好的理解`MVVM`模式，我们可以看看其来源。

`MVC`是最初的`UI`设计模式，最早出现在`Smalltalk`语言中。下图展示了`MVC`模式的主要组成：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/MVCPattern-2.png)

这个模式将`UI`分成`Model`(表示程序状态)、`View`(由UI控件组成)、`Controller`(处理用户交互与更新`model`)。`MVC`模式的最大问题是其令人相当困惑。它的概念看起来很好，但当我们实现`MVC`时，就会产生上图这种`Model-View-Controller`之间的环状关系。这种相互关系将会导致可怕的混乱。

最近`Martin Fowler`介绍了`MVC`模式的一个变种，这种模式命名为`MVVM`，并被微软广泛采用并推广。

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/MVVMPattern.png)

这个模式的核心是`ViewModel`，它是一种特殊的`model`类型，用于表示程序的`UI`状态。它包含描述每个`UI`控件的状态的属性。例如，文本输入域的当前文本，或者一个特定按钮是否可用。它同样暴露了视图可以执行哪些行为，如按钮点击或手势。

我们可以将`ViewModel`看作是视图的模型(`model-of-the-view`)。`MVVM`模式中的三部分比`MVC`更加简洁，下面是一些严格的限制

1. `View`引用了`ViewModel`，但反过来不行。
2. `ViewModel`引用了`Model`，但反过来不行。

如果我们破坏了这些规则，便无法正确地使用`MVVM`。

这个模式有以下一些立竿见影的优势：

1. 轻量的视图：所有的UI逻辑都在`ViewModel`中。
2. 便于测试：我们可以在没有视图的情况下运行整个程序，这样大大地增加了它的可测试性。

现在你可能注意到一个问题。如果`View`引用了`ViewModel`，但`ViewModel`没有引用`View`，那`ViewModel`如何更新视图呢？哈哈，这就得靠`MVVM`模式的私密武器了。

## MVVM和数据绑定

`MVVM`模式依赖于数据绑定，它是一个框架级别的特性，用于自动连接对象属性和UI控件。例如，在微软的`WPF`框架中，下面的标签将一个`TextField`的`Text`属性绑定到`ViewModel`的`Username`属性中。

``` html
<TextField Text=”{DataBinding Path=Username, Mode=TwoWay}”/>
```

WPF框架将这两个属性绑定到一起。

不过可惜的是，`iOS`没有数据绑定框架，幸运的是我们可以通过`ReactiveCocoa`来实现这一功能。我们从`iOS`开发的角度来看看`MVVM`模式，`ViewController`及其相关的`UI`(`nib`, `stroyboard`或纯代码的`View`)组成了View:

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/MVVMReactiveCocoa.png)

......而`ReactiveCocoa`绑定了`View`和`ViewModel`。

理论讲得差不多了，我们可以开始新的历程了。

## 启动项目结构

可以从[FlickrSearchStarterProject.zip](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/FlickrSearchStarterProject1.zip)中下载启动项目。我们使用`Cocoapods`来管理第三方库，在对应目录下执行`pod install`命令生成依赖库后，我们就可以打开生成的`RWTFlickrSearch.xcworkspace`来运行我们的项目了，初始运行效果如下图：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/first-launch.jpg)

我们行熟悉下工程的结构：

![image](http://cdn2.raywenderlich.com/wp-content/uploads/2014/06/EmptyInterface.png)

`Model`和`ViewModel`分组目前是空的，我们会慢慢往里面添加东西。`View`分组包含以下几个类

1. `RWTFlickSearchViewController`：程序的主屏幕，包含一个搜索输入域和一个`GO`按钮。
2. `RWTRecentSearchItemTableViewCell`：用于在主页中显示搜索结果的`table cell`
3. `RWTSearchResultsViewController`：搜索结果页，显示来自`Flickr`的`tableview`
4. `RWTSearchResultsTableViewCell`：渲染来自`Flickr`的单个图片的`table cell`。

现在来写我们的第一个`ViewModel`吧。

## 第一个ViewModel

在`ViewModel`分组中添加一个继承自`NSObject`的新类`RWTFlickrSearchViewModel`。然后在该类的头文件中，添加以下两行代码：

``` objective-c
@property (nonatomic, strong) NSString *searchText;
@property (nonatomic, strong) NSString *title;
```

`searchText`属性表示文本域中显示文本，`title`属性表示导航条上的标题。

打开`RWTFlickrSearchViewModel.m`文件添加以下代码：

``` objective-c
@implementation RWTFlickrSearchViewModel

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        [self initialize];
    }
    
    return self;
}

- (void)initialize
{
    self.searchText = @"search text";
    self.title = @"Flickr Search";
}

@end
```

这段代码简单地设置了`ViewModel`的初始状态。

接下来我们将连接`ViewModel`到`View`。记住`View`保存了一个`ViewModel`的引用。在这种情况下，添加一个给定`ViewModel`的初始化方法来构造`View`是很有必要的。打开`RWTFlickrSearchViewController.h`，并导入`ViewModel`头文件：

``` objective-c
#import "RWTFlickrSearchViewModel.h"
```

并添加以下初始化方法：

``` objective-c
@interface RWTFlickrSearchViewController : UIViewController

- (instancetype)initWithViewModel:(RWTFlickrSearchViewModel *)viewModel;

@end
```

在`RWTFlickrSearchViewController.m`中，在类的扩展中添加以下私有属性：

``` objective-c
@property (weak, nonatomic) RWTFlickrSearchViewModel *viewModel;
```

然后添加以下方法：

``` objective-c
- (instancetype)initWithViewModel:(RWTFlickrSearchViewModel *)viewModel
{
    self = [super init];
    
    if (self)
    {
        _viewModel = viewModel;
    }
    
    return self;
}
```

这就在`view`中存储了一个到`ViewModel`的引用。*注意这是一个弱引用，这样`View`引用了`ViewModel`，但没有拥有它。*

接下来在`viewDidLoad`里面添加下面代码：

``` objective-c
[self bindViewModel];
```

该方法的实现如下：

``` objective-c
- (void)bindViewModel
{
    self.title = self.viewModel.title;
    self.searchTextField.text = self.viewModel.searchText;
}
```

最后我们需要创建`ViewModel`，并将其提供给`View`。在`RWTAppDelegate.m`中，添加以下头文件：

``` objective-c
#import "RWTFlickrSearchViewModel.h"
```

同时添加一个私有属性：

``` objective-c
@property (nonatomic, strong) RWTFlickrSearchViewModel *viewModel;
```

我们会发现这个类中已以有一个`createInitialViewController`方法了，我们用以下代码来更新它：

``` objective-c
- (UIViewController *)createInitialViewController {
    self.viewModel = [RWTFlickrSearchViewModel new];
    return [[RWTFlickrSearchViewController alloc] initWithViewModel:self.viewModel];
}
```

这个方法创建了一个`ViewModel`实例，然后构造并返回了`View`。这个视图作程序导航控制器的初始视图。

运行后的状态如下：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/ViewWithState-333x500.png)

这样我们就得到了第一个`ViewModel`。不过仍然有许多东西要学的。你可能已经发现了我们还没有使用`ReactiveCocoa`。到目前为止，用户在输入框上的输入操作不会影响到`ViewModel`。

## 检测可用的搜索状态

现在，我们来看看如何用`ReactiveCocoa`来绑定`ViewModel`和`View`，以将搜索输入框和按钮连接到`ViewModel`。

在`RWTFlickrSearchViewController.m`中，我们使用如下代码更新`bindViewModel`方法。

``` objective-c
- (void)bindViewModel
{
    self.title = self.viewModel.title;
    RAC(self.viewModel, searchText) = self.searchTextField.rac_textSignal;
}
```

在`ReactiveCocoa`中，使用了分类将`rac_textSignal`属性添加到`UITextField`类中。它是一个信号，在文本域每次更新时会发送一个包含当前文本的`next`事件。

`RAC`是一个用于做绑定操作的宏，上面的代码会使用`rac_textSignal`发出的`next`信号来更新`viewModel`的`searchText`属性。

搜索按钮应该只有在用户输入有效时才可点击。为了方便起见，我们以输入字符大于`3`时输入有效为准。在`RWTFlickrSearchViewModel.m`中导入以下头文件。

``` objective-c
#import <ReactiveCocoa/ReactiveCocoa.h>
```

然后更新初始化方法：

``` objective-c
- (void)initialize
{
    self.title = @"Flickr Search";
    
    RACSignal *validSearchSignal =
    [[RACObserve(self, searchText)
      map:^id(NSString *text) {
        return @(text.length > 3);
    }]
     distinctUntilChanged];
    
    [validSearchSignal subscribeNext:^(id x) {
        NSLog(@"search text is valid %@", x);
    }];
}
```

运行程序并在输入框中输入一些字符，在控制台中我们可以看到以下输出：

``` objective-c
2014-08-07 21:50:44.078 RWTFlickrSearch[3116:60b] search text is valid 0
2014-08-07 21:50:59.493 RWTFlickrSearch[3116:60b] search text is valid 1
2014-08-07 21:51:02.594 RWTFlickrSearch[3116:60b] search text is valid 0
```

上面的代码使用`RACObserve`宏来从`ViewModel`的`searchText`属性创建一个信号。`map`操作将文本转化为一个`true`或`false`值的流。

最后，`distinctUntilChanges`确保信号只有在状态改变时才发出值。

到目前为止，我们可以看到`ReactiveCocoa`被用于将绑定`View`绑定到`ViewModel`，确保了这两者是同步的。另进一步地，`ViewModel`内部的`ReactiveCocoa`代码用于观察自己的状态及执行其它操作。

这就是`MVVM`模式的基本处理过程。`ReactiveCocoa`通常用于绑定`View`和`ViewModel`，但在程序的其它层也非常有用。

## 添加搜索命令

本节将上面创建的`validSearchSignal`来创建绑定到`View`的操作。打开`RWTFlickrSearchViewModel.h`并添加以下头文件

``` objective-c
#import <ReactiveCocoa/ReactiveCocoa.h>
```

同时添加以下属性

``` objective-c
@property (strong, nonatomic) RACCommand *executeSearch;
```

`RACCommand`是`ReactiveCocoa`中用于表示`UI`操作的一个类。它包含一个代表了`UI`操作的结果的信号以及标识操作当前是否被执行的一个状态。

在`RWTFlickrSearchViewModel.m`的`initialize`方法的最后添加以下代码：

``` objective-c
self.executeSearch = [[RACCommand alloc] initWithEnabled:validSearchSignal
                                             signalBlock:^RACSignal *(id input) {
                                                 return [self executeSearchSignal];
                                             }];
```

这创建了一个在`validSearchSignal`发送`true`时可用的命令。另外，需要在下面实现`executeSearchSignal`方法，它提供了命令所执行的操作。

``` objective-c
- (RACSignal *)executeSearchSignal
{
    return [[[[RACSignal empty] logAll] delay:2.0] logAll];
}
```

在这个方法中，我们执行一些业务逻辑操作，以作为命令执行的结果，并通过信号异步返回结果。

到目前为止，上述代码只提供了一个简单的实现：空信号会立即完成。`delay`操作会将其所接收到的`next`或`complete`事件延迟两秒执行。

最后一步是将这个命令连接到`View`中。打开`RWTFlickrSearchViewController.m`并在`bindViewModel`方法的结尾中添加以下代码：

``` objective-c
self.searchButton.rac_command = self.viewModel.executeSearch;
```

`rac_command`属性是`UIButton`的`ReactiveCocoa`分类中添加的属性。上面的代码确保点击按钮执行给定的命令，且按钮的可点击状态反应了命令的可用状态。

运行代码，输入一些字符并点击`GO`，得到如下结果：

![image](http://cdn3.raywenderlich.com/wp-content/uploads/2014/06/GoButtonEnabled-333x500.png)

可以看到，当输入有效点击按钮时，按钮会置灰`2`秒钟，当执行的信号完成时又可点击。我们可以看下控制台的输出，可以发现空信号会立即完成，而延迟操作会在`2`秒后发出事件：

``` objective-c
2014-08-07 22:21:25.128 RWTFlickrSearch[3161:60b] <RACDynamicSignal: 0x17005ba20> name: +empty completed
2014-08-07 22:21:27.329 RWTFlickrSearch[3161:60b] <RACDynamicSignal: 0x17005dd30> name: [+empty] -delay: 2.000000 completed
```

是不是很酷？



## 绑定、绑定还是绑定

`RACCommand`监听了搜索按钮状态的更新，但处理`activity indicator`的可见性则由我们负责。`RACCommand`暴露了一个`executing`属性，它是一个信号，发送`true`或`false`来标明命令开始和结束执行的时间。我们可以用这个来影响当前命令的状态。

在`RWTFlickrSearchViewController.m`中的`bindViewModel`方法结尾处添加以下代码：

``` objective-c
RAC([UIApplication sharedApplication], networkActivityIndicatorVisible) = self.viewModel.executeSearch.executing;
```

这将`UIApplication`的`networkActivityIndicatorVisible`属性绑定到命令的`executing`信号中。这确保了不管命令什么时候执行，状态栏中的网络`activity indicator`都会显示。

接下来添加以下代码：

``` objective-c
RAC(self.loadingIndicator, hidden) = [self.viewModel.executeSearch.executing not];
```

当命令执行时，应该隐藏加载`indicator`。这可以通过`not`操作来反转信号。

最后，添加以下代码：

``` objective-c
[self.viewModel.executeSearch.executionSignals subscribeNext:^(id x) {
    [self.searchTextField resignFirstResponder];
}];
```

这段代码确保命令执行时隐藏键盘。`executionSignals`属性发送由命令每次执行时生成的信号。这个属性是信号的信号(见[ReactiveCocoa Tutorial – The Definitive Introduction: Part 1/2](http://southpeak.github.io/blog/2014/08/02/reactivecocoazhi-nan-%5B%3F%5D-:xin-hao/))。当创建和发出一个新的命令执行信号时，隐藏键盘。

运行程序看看效果如何吧。

## Model在哪？

到目前为止，我们已经有了一个清晰的`View(RWTFlickrSearchViewController)`和`ViewModel(RWTFlickrSearchViewModel`)，但是`Model`在哪呢？

答案很简单：没有！

当前的程序执行一个命令来响应用户点击搜索按钮的操作，但是实现不做任何值的处理。`ViewModel`真正需要做的是使用当前的`searchText`来搜索`Flickr`，并返回一个匹配的列表。

我们应该可以直接在`ViewModel`添加业务逻辑，但相信我，你不希望这么做。如果这是一个`viewcontroller`，我打赌你一定会直接这么做。

`ViewModel`暴露属性来表示`UI`状态，它同样暴露命令来表示`UI`操作(通常是方法)。`ViewModel`负责管理基于用户交互的`UI`状态的改变。然而它不负责实际执行这些交互产生的的业务逻辑，那是`Model`的工作。

接下来，我们将在程序中添加`Model`层。

在`Model`分组中，添加`RWTFlickrSearch`协议并提供以下实现

``` objective-c
#import <ReactiveCocoa/ReactiveCocoa.h>

@protocol RWTFlickrSearch <NSObject>

- (RACSignal *)flickrSearchSignal:(NSString *)searchString;

@end
```

这个协议定义了`Model`层的初始接口，并将搜索`Flickr`的责任移出`ViewModel`。

接下来在`Model`分组中添加`RWTFlickrSearchImpl`类，其继承自`NSObject`，并实现了`RWTFlickrSearch`协议，如下代码所示：

``` objective-c
#import "RWTFlickrSearch.h"

@interface RWTFlickrSearchImpl : NSObject <RWTFlickrSearch>

@end
```

打开`RWTFlickrSearchImpl.m`文件，提供以下实现：

``` objective-c
@implementation RWTFlickrSearchImpl

- (RACSignal *)flickrSearchSignal:(NSString *)searchString
{
    return [[[[RACSignal empty] logAll] delay:2.0] logAll];
}

@end
```

看着是不是有点眼熟？没错，我们在上面的`ViewModel`中有相同的实现。

接下来我们需要在`ViewModel`层中使用`Model`层。在`ViewModel`分组中添加`RWTViewModelServices`协议并如下实现：

``` objective-c
#import "RWTFlickrSearch.h"

@protocol RWTViewModelServices <NSObject>
- (id<RWTFlickrSearch>)getFlickrSearchService;
@end
```

这个协议定义了唯一的一个方法，以允许`ViewModel`获取一个引用，以指向`RWTFlickrSearch`协议的实现对象。

打开`RWTFlickrSearchViewModel.h`并导入头文件

``` objective-c
#import "RWTViewModelServices.h"
```

更新初始化方法并将`RWTViewModelServices`作为一个参数：

``` objective-c
- (instancetype)initWithServices:(id<RWTViewModelServices>)services;
```

在`RWTFlickrSearchViewModel.m`中，添加类的分类并提供一个私有属性来维护一个到`RWTViewModelServices`的引用：

``` objective-c
@interface RWTFlickrSearchViewModel ()
@property (nonatomic, weak) id<RWTViewModelServices> services;
@end
```

在该文件下面，添加初始化方法的实现：

``` objective-c
- (instancetype)initWithServices:(id<RWTViewModelServices>)services
{
    self = [super init];
    
    if (self)
    {
        _services = services;
        [self initialize];
    }
    
    return self;
}
```

这只是简单的存储了`services`的引用。

最后，更新`executeSearchSignal`方法：

``` objective-c
- (RACSignal *)executeSearchSignal
{
    return [[self.services getFlickrSearchService] flickrSearchSignal:self.searchText];
}
```

最后是连接`Model`和`ViewModel`。

在工程的根分组中，添加一个`NSObject`的子类`RWTViewModelServicesImpl`。打开`RWTViewModelServicesImpl.h`并实现`RWTViewModelServices`协议：

``` objective-c
#import "RWTViewModelServices.h"

@interface RWTViewModelServicesImpl : NSObject <RWTViewModelServices>
@end
```

打开`RWTViewModelServicesImpl.m`，并添加实现：

``` objective-c
#import "RWTFlickrSearchImpl.h"

@interface RWTViewModelServicesImpl ()

@property (strong, nonatomic) RWTFlickrSearchImpl *searchService;

@end
  
@implementation RWTViewModelServicesImpl
  
- (instancetype)init
{
    if (self = [super init])
    {
        _searchService = [RWTFlickrSearchImpl new];
    }
    
    return self;
}

- (id<RWTFlickrSearch>)getFlickrSearchService
{
    return self.searchService;
}

@end
```

这个类简单创建了一个`RWTFlickrSearchImpl`实例，用于`Model`层搜索`Flickr`服务，并将其提供给`ViewModel`的请求。

最后，在`RWTAppDelegate.m`中添加以下头文件

``` objective-c
#import "RWTViewModelServicesImpl.h"
```

并添加一个新的私有属性

``` objective-c
@property (nonatomic, strong) RWTViewModelServicesImpl *viewModelServices;
```

再更新`createInitialViewController`方法：

``` objective-c
- (UIViewController *)createInitialViewController {
    self.viewModelServices = [RWTViewModelServicesImpl new];
    self.viewModel = [[RWTFlickrSearchViewModel alloc] initWithServices:self.viewModelServices];
    return [[RWTFlickrSearchViewController alloc] initWithViewModel:self.viewModel];
}
```

运行程序，验证程序有没有按之前的方式来工作。当然，这不是最有趣的变化，不过，可以看看新代码的形状了。

`Model`层暴露了一个`ViewModel`层使用的'服务'。一个协议定义了这个服务的接口，提供了松散的组合。

我们可以使用这种方式来为单元测试提供一个类似的服务实现。程序现在有了正确的`MVVM`结构，让我们小结一下：

1. Model层暴露服务并负责提供程序的业务逻辑实现。
2. `ViewModel`层表示程序的视图状态(`view-state`)。同时响应用户交互及来自`Model`层的事件，两者都受`view-state`变化的影响。
3. `View`层很薄，只提供`ViewModel`状态的显示及输出用户交互事件。

## 搜索Flickr

我们继续来完成Flickr的搜索实现，事情变得越来越有趣了。

首先我们创建表示搜索结果的模型对象。在`Model`分组中，添加`RWTFlickrPhoto`类，并为其添加三个属性。

``` objective-c
@interface RWTFlickrPhoto : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *identifier;

@end
```

这个模型对象表示由`Flickr`搜索`API`返回一个图片。

打开`RWTFlickrPhoto.m`，并添加以下描述方法的实现：

``` objective-c
- (NSString *)description
{
    return self.title;
}
```

接下来，新建一个新的模型对象类`RWTFlickrSearchResults`，并添加以下属性：

``` objective-c
@interface RWTFlickrSearchResults : NSObject

@property (strong, nonatomic) NSString *searchString;
@property (strong, nonatomic) NSArray *photos;
@property (nonatomic) NSInteger totalResults;

@end
```

这个类表示由`Flickr`搜索返回的照片集合。

是时候实现搜索`Flickr`了。打开`RWTFlickrSearchImpl.m`并导入以下头文件：

``` objective-c
#import "RWTFlickrSearchResults.h"
#import "RWTFlickrPhoto.h"
#import <objectiveflickr/ObjectiveFlickr.h>
#import <LinqToObjectiveC/NSArray+LinqExtensions.h>
```

然后添加以下类扩展：

``` objective-c
@interface RWTFlickrSearchImpl () <OFFlickrAPIRequestDelegate>

@property (strong, nonatomic) NSMutableSet *requests;
@property (strong, nonatomic) OFFlickrAPIContext *flickrContext;

@end
```

这个类实现了`OFFlickrAPIRequestDelegate`协议，并添加了两个私有属性。我们会很快看到如何使用这些值。

继续添加代码：

``` objective-c
- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        NSString *OFSampleAppAPIKey = @"YOUR_API_KEY_GOES_HERE";
        NSString *OFSampleAppAPISharedSecret = @"YOUR_SECRET_GOES_HERE";
        
        _flickrContext = [[OFFlickrAPIContext alloc] initWithAPIKey:OFSampleAppAPIKey sharedSecret:OFSampleAppAPISharedSecret];
        
        _requests = [NSMutableSet new];
    }
    
    return self;
}
```

这段代码创建了一个`Flickr`的上下文，用于存储`ObjectiveFlickr`请求的数据。

当前`Model`层服务类提供的`API`有一个单独的方法，用于查找基于文本搜索字符的图片。不过我们一会会添加更多的方法。

在`RWTFlickrSearchImpl.m`中添加以下方法：

``` objective-c
- (RACSignal *)signalFromAPIMethod:(NSString *)method arguments:(NSDictionary *)args transform:(id (^)(NSDictionary *response))block
{
    // 1. 创建请求信号
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        // 2. 创建一个Flick请求对象
        OFFlickrAPIRequest *flickrRequest = [[OFFlickrAPIRequest alloc] initWithAPIContext:self.flickrContext];
        flickrRequest.delegate = self;
        [self.requests addObject:flickrRequest];
        
        // 3. 从代理方法中创建一个信号
        RACSignal *successSignal = [self rac_signalForSelector:@selector(flickrAPIRequest:didCompleteWithResponse:)
                                                  fromProtocol:@protocol(OFFlickrAPIRequestDelegate)];
        
        // 4. 处理响应
        [[[successSignal
         map:^id(RACTuple *tuple) {
             return tuple.second;
         }]
         map:block]
         subscribeNext:^(id x) {
             [subscriber sendNext:x];
             [subscriber sendCompleted];
         }];
        
        // 5. 开始请求
        [flickrRequest callAPIMethodWithGET:method arguments:args];
        
        // 6. 完成后，移除请求的引用
        return [RACDisposable disposableWithBlock:^{
            [self.requests removeObject:flickrRequest];
        }];
    }];
}
```

这个方法需要传入请求方法及请求参数，然后使用`block`参数来转换响应对象。我们重点看一下第`4`步：

``` objective-c
[[[successSignal
  // 1. 从flickrAPIRequest:didCompleteWithResponse:代理方法中提取第二个参数
  map:^id(RACTuple *tuple) {
    return tuple.second;
  }]
  // 2. 转换结果
  map:block]
  subscribeNext:^(id x) {
    // 3. 将结果发送给订阅者
    [subscriber sendNext:x];
    [subscriber sendCompleted];
  }];
```

`rac_signalForSelector:fromProtocol:` 方法创建了`successSignal`，同样也在代理方法的调用中创建了信号。

代理方法每次调用时，发出的`next`事件会附带包含方法参数的`RACTuple`。

实现`Flickr`搜索的最后一步如下：

``` objective-c
- (RACSignal *)flickrSearchSignal:(NSString *)searchString {
  return [self signalFromAPIMethod:@"flickr.photos.search"
                         arguments:@{@"text": searchString,
                                     @"sort": @"interestingness-desc"}
                         transform:^id(NSDictionary *response) {
 
    RWTFlickrSearchResults *results = [RWTFlickrSearchResults new];
    results.searchString = searchString;
    results.totalResults = [[response valueForKeyPath:@"photos.total"] integerValue];
 
    NSArray *photos = [response valueForKeyPath:@"photos.photo"];
    results.photos = [photos linq_select:^id(NSDictionary *jsonPhoto) {
      RWTFlickrPhoto *photo = [RWTFlickrPhoto new];
      photo.title = [jsonPhoto objectForKey:@"title"];
      photo.identifier = [jsonPhoto objectForKey:@"id"];
      photo.url = [self.flickrContext photoSourceURLFromDictionary:jsonPhoto
                                                              size:OFFlickrSmallSize];
      return photo;
    }];
 
    return results;
  }];
}
```

上面的方法使用`signalFromAPIMethod:arguments:transform:`方法。`flickr.photos.search`方法提供的字典来搜索照片。

传递给`transform`参数的`block`简单地将`NSDictionary`响应转化为一个等价的模型对象，让它在`ViewModel`中更容易使用。

最后一步是打开`RWTFlickrSearchViewModel.m`方法，然后更新搜索信号来记录日志：

``` objective-c
- (RACSignal *)executeSearchSignal {
  return [[[self.services getFlickrSearchService]
           flickrSearchSignal:self.searchText]
           logAll];
}
```

编译，运行并输入一些字符后可在控制台看到以下日志：

``` objective-c
2014-06-03 [...] <RACDynamicSignal: 0x8c368a0> name: +createSignal: next: searchString=wibble, totalresults=1973, photos=(
    "Wibble, wobble, wibble, wobble",
    "unoa-army",
    "Day 277: Cheers to the freakin' weekend!",
    [...]
    "Angry sky",
    Nemesis
)
```

这样我们`MVVM`指南的第一部分就差不多结束了，但在结束之前，让我们先看看内存问题吧。

## 内存管理

正如在[ReactiveCocoa Tutorial – The Definitive Introduction: Part 2/2](http://southpeak.github.io/blog/2014/08/02/reactivecocoazhi-nan-er-:twittersou-suo-shi-li/)中所讲的一样，我们在`block`中使用了`self`，这可能会导致循环引用的问题。而为了避免此问题，我们需要使用`@weakify`和`@strongify`宏来打破这种循环引用。

不过看看`signalFromAPIMethod:arguments:transform:`方法，你可能会迷惑为什么没有使用这两个宏来引用`self`？这是因为`block`是作为`createSignal:`方法的一个参数，它不会在`self`和`block`之间建立一个强引用关系。迷茫了吧？不相信的话只需要测试一样这段代码有没有内存泄露就行。当然这时候就得用`Instruments`了，自己去看吧。哈哈。

## 何去何从？

例子工程的完整代码可以在[这里](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/FlickrSearchPart1Project1.zip)下载。在下一部分中，我们将看看如何从`ViewModel`中初始化一个视图控制器并实现更多的`Flickr`请求操作。