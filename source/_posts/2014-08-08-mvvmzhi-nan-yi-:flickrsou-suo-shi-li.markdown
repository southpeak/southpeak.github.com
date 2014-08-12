---

layout: post

title: "MVVM指南一：Flickr搜索实例"

date: 2014-08-08 18:54:42 +0800

comments: true

categories: iOS

---

本文由Colin Eberhardt发表于raywenderlich，原文可查看[MVVM Tutorial with ReactiveCocoa: Part 1/2](http://www.raywenderlich.com/74106/mvvm-tutorial-with-reactivecocoa-part-1)

你可能已经在Twitter上听过这个这个笑话了：

“iOS Architecture, where MVC stands for Massive View Controller”

当然这在iOS开发圈内，这是个轻松的笑话，但我敢确定你大实践中遇到过这个问题：即视图控制器太大且难以管理。

这篇文章将介绍另一种构建应用程序的模式--MVVM(Model-View-ViewModel)。通过结合ReactiveCocoa便利性，这个模式提供了一个很好的代替MVC的方案，它保证了让视图控制器的轻量性。

在本文我，我们将通过构建一个简单的Flickr查询程序来一步步了解MVVM，这个程序的效果图如下所示：

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/FinishedApp.png)

在开始写代码之前，我们先来了解一些基本的原理。

原文简要介绍了一下ReactiveCocoa，在此不在翻译，可以查看以下文章：

[ReactiveCocoa指南一：信号](http://southpeak.github.io/blog/2014/08/02/reactivecocoazhi-nan-%5B%3F%5D-:xin-hao/)

[ReactiveCocoa指南二：Twitter搜索实例](http://southpeak.github.io/blog/2014/08/02/reactivecocoazhi-nan-er-:twittersou-suo-shi-li/)

## MVVM模式介绍

正如其名称一下，MVVM是一个UI设计模式。它是MV*模式集合中的一员。MV\*模式还包含MVC(Model View Controller)、MVP(Model View Presenter)等。这些模式的目的在于将UI逻辑与业务逻辑分离，以让程序更容易开发和测试。为了更好的理解MVVM模式，我们可以看看其来源。

MVC是最初的UI设计模式，最早出现在Smalltalk语言中。下图展示了MVC模式的主要组成：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/MVCPattern-2.png)

这个模式将UI分成Model(表示程序状态)、View(由UI控件组成)、Controller(处理用户交互与更新model)。MVC模式的最大问题是其令人相当困惑。它的概念看起来很好，但当我们实现MVC时，就会产生上图这种Model-View-Controller之间的环状关系。这种相互关系将会导致可怕的混乱。

最近Martin Fowler介绍了MVC模式的一个变种，这种模式命名为MVVM，并被微软广泛采用并推广。

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/MVVMPattern.png)

这个模式的核心是ViewModel，它是一种特殊的model类型，用于表示程序的UI状态。它包含描述每个UI控件的状态的属性。例如，文本输入域的当前文本，或者一个特定按钮是否可用。它同样暴露了视图可以执行哪些行为，如按钮点击或手势。

我们可以将ViewModel看作是视图的模型(model-of-the-view)。MVVM模式中的三部分比MVC更加简洁，下面是一些严格的限制

1. View引用了ViewModel，但反过来不行。
2. ViewModel引用了Model，但反过来不行。

如果我们破坏了这些规则，便无法正确地使用MVVM。

这个模式有以下一些立竿见影的优势：

1. 轻量的视图：所有的UI逻辑都在ViewModel中。
2. 便于测试：我们可以在没有视图的情况下运行整个程序，这样大大地增加了它的可测试性。

现在你可能注意到一个问题。如果View引用了ViewModel，但ViewModel没有引用View，那ViewModel如何更新视图呢？哈哈，这就得靠MVVM模式的私密武器了。

## MVVM和数据绑定

MVVM模式依赖于数据绑定，它是一个框架级别的特性，用于自动连接对象属性和UI控件。例如，在微软的WPF框架中，下面的标签将一个TextField的Text属性绑定到ViewModel的Username属性中。

	<TextField Text=”{DataBinding Path=Username, Mode=TwoWay}”/>

WPF框架将这两个属性绑定到一起。

不过可惜的是，iOS没有数据绑定框架，幸运的是我们可以通过ReactiveCocoa来实现这一功能。我们从iOS开发的角度来看看MVVM模式，ViewController及其相关的UI(nib, stroyboard或纯代码的View)组成了View:

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/MVVMReactiveCocoa.png)

......而ReactiveCocoa绑定了View和ViewModel。

理论讲得差不多了，我们可以开始新的历程了。

## 启动项目结构

可以从[FlickrSearchStarterProject.zip](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/FlickrSearchStarterProject1.zip)中下载启动项目。我们使用Cocoapods来管理第三方库，在对应目录下执行pod install命令生成依赖库后，我们就可以打开生成的RWTFlickrSearch.xcworkspace来运行我们的项目了，初始运行效果如下图：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/first-launch.jpg)

我们行熟悉下工程的结构：

![image](http://cdn2.raywenderlich.com/wp-content/uploads/2014/06/EmptyInterface.png)

Model和ViewModel分组目前是空的，我们会慢慢往里面添加东西。View分组包含以下几个类

1. RWTFlickSearchViewController：程序的主屏幕，包含一个搜索输入域和一个GO按钮。
2. RWTRecentSearchItemTableViewCell：用于在主页中显示搜索结果的table cell
3. RWTSearchResultsViewController：搜索结果页，显示来自Flickr的tableview
4. RWTSearchResultsTableViewCell：渲染来自Flickr的单个图片的table cell。

现在来写我们的第一个ViewModel吧。

## 第一个ViewModel

在ViewModel分组中添加一个继承自NSObject的新类RWTFlickrSearchViewModel。然后在该类的头文件中，添加以下两行代码：

	@property (nonatomic, strong) NSString *searchText;
	@property (nonatomic, strong) NSString *title;

searchText属性表示文本域中显示文本，title属性表示导航条上的标题。

打开RWTFlickrSearchViewModel.m文件添加以下代码：

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

这段代码简单地设置了ViewModel的初始状态。

接下来我们将连接ViewModel到View。记住View保存了一个ViewModel的引用。在这种情况下，添加一个给定ViewModel的初始化方法来构造View是很有必要的。打开RWTFlickrSearchViewController.h，并导入ViewModel头文件：

	#import "RWTFlickrSearchViewModel.h"
	
并添加以下初始化方法：

	@interface RWTFlickrSearchViewController : UIViewController
	
	- (instancetype)initWithViewModel:(RWTFlickrSearchViewModel *)viewModel;
	
	@end

在RWTFlickrSearchViewController.m中，在类的扩展中添加以下私有属性：

	@property (weak, nonatomic) RWTFlickrSearchViewModel *viewModel;
	
然后添加以下方法：

	- (instancetype)initWithViewModel:(RWTFlickrSearchViewModel *)viewModel
	{
	    self = [super init];
	    
	    if (self)
	    {
	        _viewModel = viewModel;
	    }
	    
	    return self;
	}

这就在view中存储了一个到ViewModel的引用。*注意这是一个弱引用，这样View引用了ViewModel，但没有拥有它。*

接下来在viewDidLoad里面添加下面代码：

    [self bindViewModel];
    
该方法的实现如下：

	- (void)bindViewModel
	{
	    self.title = self.viewModel.title;
	    self.searchTextField.text = self.viewModel.searchText;
	}

最后我们需要创建ViewModel，并将其提供给View。在RWTAppDelegate.m中，添加以下头文件：

	#import "RWTFlickrSearchViewModel.h"

同时添加一个私有属性：

	@property (nonatomic, strong) RWTFlickrSearchViewModel *viewModel;

我们会发现这个类中已以有一个createInitialViewController方法了，我们用以下代码来更新它：

	- (UIViewController *)createInitialViewController {
	    self.viewModel = [RWTFlickrSearchViewModel new];
	    return [[RWTFlickrSearchViewController alloc] initWithViewModel:self.viewModel];
	}

这个方法创建了一个ViewModel实例，然后构造并返回了View。这个视图作程序导航控制器的初始视图。

运行后的状态如下：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/ViewWithState-333x500.png)

这样我们就得到了第一个ViewModel。不过仍然有许多东西要学的。你可能已经发现了我们还没有使用ReactiveCocoa。到目前为止，用户在输入框上的输入操作不会影响到ViewModel。

## 检测可用的搜索状态

现在，我们来看看如何用ReactiveCocoa来绑定ViewModel和View，以将搜索输入框和按钮连接到ViewModel。

在RWTFlickrSearchViewController.m中，我们使用如下代码更新bindViewModel方法。

	- (void)bindViewModel
	{
	    self.title = self.viewModel.title;
	    RAC(self.viewModel, searchText) = self.searchTextField.rac_textSignal;
	}

在ReactiveCocoa中，使用了分类将rac_textSignal属性添加到UITextField类中。它是一个信号，在文本域每次更新时会发送一个包含当前文本的next事件。

RAC是一个用于做绑定操作的宏，上面的代码会使用rac_textSignal发出的next信号来更新viewModel的searchText属性。

搜索按钮应该只有在用户输入有效时才可点击。为了方便起见，我们以输入字符大于3时输入有效为准。在RWTFlickrSearchViewModel.m中导入以下头文件。

	#import <ReactiveCocoa/ReactiveCocoa.h>

然后更新初始化方法：

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

运行程序并在输入框中输入一些字符，在控制台中我们可以看到以下输出：

	2014-08-07 21:50:44.078 RWTFlickrSearch[3116:60b] search text is valid 0
	2014-08-07 21:50:59.493 RWTFlickrSearch[3116:60b] search text is valid 1
	2014-08-07 21:51:02.594 RWTFlickrSearch[3116:60b] search text is valid 0

上面的代码使用RACObserve宏来从ViewModel的searchText属性创建一个信号。map操作将文本转化为一个true或false值的流。

最后，distinctUntilChanges确保信号只有在状态改变时才发出值。

到目前为止，我们可以看到ReactiveCocoa被用于将绑定View绑定到ViewModel，确保了这两者是同步的。另进一步地，ViewModel内部的ReactiveCocoa代码用于观察自己的状态及执行其它操作。

这就是MVVM模式的基本处理过程。ReactiveCocoa通常用于绑定View和ViewModel，但在程序的其它层也非常有用。

## 添加搜索命令

本节将上面创建的validSearchSignal来创建绑定到View的操作。打开RWTFlickrSearchViewModel.h并添加以下头文件

	#import <ReactiveCocoa/ReactiveCocoa.h>
	
同时添加以下属性

	@property (strong, nonatomic) RACCommand *executeSearch;

RACCommand是ReactiveCocoa中用于表示UI操作的一个类。它包含一个代表了UI操作的结果的信号以及标识操作当前是否被执行的一个状态。

在RWTFlickrSearchViewModel.m的initialize方法的最后添加以下代码：

    self.executeSearch = [[RACCommand alloc] initWithEnabled:validSearchSignal
                                                 signalBlock:^RACSignal *(id input) {
                                                     return [self executeSearchSignal];
                                                 }];

这创建了一个在validSearchSignal发送true时可用的命令。另外，需要在下面实现executeSearchSignal方法，它提供了命令所执行的操作。

	- (RACSignal *)executeSearchSignal
	{
	    return [[[[RACSignal empty] logAll] delay:2.0] logAll];
	}

在这个方法中，我们执行一些业务逻辑操作，以作为命令执行的结果，并通过信号异步返回结果。

到目前为止，上述代码只提供了一个简单的实现：空信号会立即完成。delay操作会将其所接收到的next或complete事件延迟两秒执行。

最后一步是将这个命令连接到View中。打开RWTFlickrSearchViewController.m并在bindViewModel方法的结尾中添加以下代码：

    self.searchButton.rac_command = self.viewModel.executeSearch;
    
rac_command属性是UIButton的ReactiveCocoa分类中添加的属性。上面的代码确保点击按钮执行给定的命令，且按钮的可点击状态反应了命令的可用状态。

运行代码，输入一些字符并点击GO，得到如下结果：

![image](http://cdn3.raywenderlich.com/wp-content/uploads/2014/06/GoButtonEnabled-333x500.png)

可以看到，当输入有效点击按钮时，按钮会置灰2秒钟，当执行的信号完成时又可点击。我们可以看下控制台的输出，可以发现空信号会立即完成，而延迟操作会在2秒后发出事件：

	2014-08-07 22:21:25.128 RWTFlickrSearch[3161:60b] <RACDynamicSignal: 0x17005ba20> name: +empty completed
	2014-08-07 22:21:27.329 RWTFlickrSearch[3161:60b] <RACDynamicSignal: 0x17005dd30> name: [+empty] -delay: 2.000000 completed

是不是很酷？


## 绑定、绑定还是绑定

RACCommand监听了搜索按钮状态的更新，但处理activity indicator的可见性则由我们负责。RACCommand暴露了一个executing属性，它是一个信号，发送true或false来标明命令开始和结束执行的时间。我们可以用这个来影响当前命令的状态。

在RWTFlickrSearchViewController.m中的bindViewModel方法结尾处添加以下代码：

    RAC([UIApplication sharedApplication], networkActivityIndicatorVisible) = self.viewModel.executeSearch.executing;
    
这将UIApplication的networkActivityIndicatorVisible属性绑定到命令的executing信号中。这确保了不管命令什么时候执行，状态栏中的网络activity indicator都会显示。

接下来添加以下代码：

    RAC(self.loadingIndicator, hidden) = [self.viewModel.executeSearch.executing not];
    
当命令执行时，应该隐藏加载indicator。这可以通过not操作来反转信号。

最后，添加以下代码：

    [self.viewModel.executeSearch.executionSignals subscribeNext:^(id x) {
        [self.searchTextField resignFirstResponder];
    }];

这段代码确保命令执行时隐藏键盘。executionSignals属性发送由命令每次执行时生成的信号。这个属性是信号的信号(见[ReactiveCocoa指南一：信号](http://southpeak.github.io/blog/2014/08/02/reactivecocoazhi-nan-%5B%3F%5D-:xin-hao/))。当创建和发出一个新的命令执行信号时，隐藏键盘。

运行程序看看效果如何吧。

## Model在哪？

到目前为止，我们已经有了一个清晰的View(RWTFlickrSearchViewController)和ViewModel(RWTFlickrSearchViewModel)，但是Model在哪呢？

答案很简单：没有！

当前的程序执行一个命令来响应用户点击搜索按钮的操作，但是实现不做任何值的处理。ViewModel真正需要做的是使用当前的searchText来搜索Flickr，并返回一个匹配的列表。

我们应该可以直接在ViewModel添加业务逻辑，但相信我，你不希望这么做。如果这是一个viewcontroller，我打赌你一定会直接这么做。

ViewModel暴露属性来表示UI状态，它同样暴露命令来表示UI操作(通常是方法)。ViewModel负责管理基于用户交互的UI状态的改变。然而它不负责实际执行这些交互产生的的业务逻辑，那是Model的工作。

接下来，我们将在程序中添加Model层。

在Model分组中，添加RWTFlickrSearch协议并提供以下实现

	#import <ReactiveCocoa/ReactiveCocoa.h>
	
	@protocol RWTFlickrSearch <NSObject>
	
	- (RACSignal *)flickrSearchSignal:(NSString *)searchString;
	
	@end

这个协议定义了Model层的初始接口，并将搜索Flickr的责任移出ViewModel。

接下来在Model分组中添加RWTFlickrSearchImpl类，其继承自NSObject，并实现了RWTFlickrSearch协议，如下代码所示：

	#import "RWTFlickrSearch.h"
	
	@interface RWTFlickrSearchImpl : NSObject <RWTFlickrSearch>
	
	@end

打开RWTFlickrSearchImpl.m文件，提供以下实现：

@implementation RWTFlickrSearchImpl

	- (RACSignal *)flickrSearchSignal:(NSString *)searchString
	{
	    return [[[[RACSignal empty] logAll] delay:2.0] logAll];
	}
	
	@end

看着是不是有hkko眼熟？没错，我们在上面的ViewModel中有相同的实现。

接下来我们需要在ViewModel层中使用Model层。在ViewModel分组中添加RWTViewModelServices协议并如下实现：

	#import "RWTFlickrSearch.h"
	
	@protocol RWTViewModelServices <NSObject>
	
	- (id<RWTFlickrSearch>)getFlickrSearchService;
	
	@end

这个协议定义了唯一的一个方法，以允许ViewModel获取一个引用，以指向RWTFlickrSearch协议的实现对象。

打开RWTFlickrSearchViewModel.h并导入头文件

	#import "RWTViewModelServices.h"
	
更新初始化方法并将RWTViewModelServices作为一个参数：

	- (instancetype)initWithServices:(id<RWTViewModelServices>)services;
	
在RWTFlickrSearchViewModel.m中，添加类的分类并提供一个私有属性来维护一个到RWTViewModelServices的引用：

	@interface RWTFlickrSearchViewModel ()
	
	@property (nonatomic, weak) id<RWTViewModelServices> services;
	
	@end

在该文件下面，添加初始化方法的实现：

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

这只是简单的存储了services的引用。

最后，更新executeSearchSignal方法：

	- (RACSignal *)executeSearchSignal
	{
	    return [[self.services getFlickrSearchService] flickrSearchSignal:self.searchText];
	}

最后是连接Model和ViewModel。

在工程的根分组中，添加一个NSObject的子类RWTViewModelServicesImpl。打开RWTViewModelServicesImpl.h并实现RWTViewModelServices协议：

	#import "RWTViewModelServices.h"
	
	@interface RWTViewModelServicesImpl : NSObject <RWTViewModelServices>
	
	@end

打开RWTViewModelServicesImpl.m，并添加实现：

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

这个类简单创建了一个RWTFlickrSearchImpl实例，用于Model层搜索Flickr服务，并将其提供给ViewModel的请求。

最后，在RWTAppDelegate.m中添加以下头文件

	#import "RWTViewModelServicesImpl.h"

并添加一个新的私有属性

	@property (nonatomic, strong) RWTViewModelServicesImpl *viewModelServices;

再更新createInitialViewController方法：

	- (UIViewController *)createInitialViewController {
	    self.viewModelServices = [RWTViewModelServicesImpl new];
	    self.viewModel = [[RWTFlickrSearchViewModel alloc] initWithServices:self.viewModelServices];
	    return [[RWTFlickrSearchViewController alloc] initWithViewModel:self.viewModel];
	}

运行程序，验证程序有没有按之前的方式来工作。当然，这不是最有趣的变化，不过，可以看看新代码的形状了。

Model层暴露了一个ViewModel层使用的'服务'。一个协议定义了这个服务的接口，提供了松散的组合。

我们可以使用这种方式来为单元测试提供一个类似的服务实现。程序现在有了正确的MVVM结构，让我们小结一下：

1. Model层暴露服务并负责提供程序的业务逻辑实现。
2. ViewModel层表示程序的视图状态(view-state)。同时响应用户交互及来自Model层的事件，两者都受view-state变化的影响。
3. View层很薄，只提供ViewModel状态的显示及输出用户交互事件。

## 搜索Flickr

我们继续来完成Flickr的搜索实现，事情变得越来越有趣了。

首先我们创建表示搜索结果的模型对象。在Model分组中，添加RWTFlickrPhoto类，并为其添加三个属性。

	@interface RWTFlickrPhoto : NSObject
	
	@property (nonatomic, strong) NSString *title;
	@property (nonatomic, strong) NSURL *url;
	@property (nonatomic, strong) NSString *identifier;
	
	@end

这个模型对象表示由Flickr搜索API返回一个图片。

打开RWTFlickrPhoto.m，并添加以下描述方法的实现：

	- (NSString *)description
	{
	    return self.title;
	}

接下来，新建一个新的模型对象类RWTFlickrSearchResults，并添加以下属性：

	@interface RWTFlickrSearchResults : NSObject
	
	@property (strong, nonatomic) NSString *searchString;
	@property (strong, nonatomic) NSArray *photos;
	@property (nonatomic) NSInteger totalResults;
	
	@end

这个类表示由Flickr搜索返回的照片集合。

是时候实现搜索Flickr了。打开RWTFlickrSearchImpl.m并导入以下头文件：

	#import "RWTFlickrSearchResults.h"
	#import "RWTFlickrPhoto.h"
	#import <objectiveflickr/ObjectiveFlickr.h>
	#import <LinqToObjectiveC/NSArray+LinqExtensions.h>

然后添加以下类扩展：

	@interface RWTFlickrSearchImpl () <OFFlickrAPIRequestDelegate>
	
	@property (strong, nonatomic) NSMutableSet *requests;
	@property (strong, nonatomic) OFFlickrAPIContext *flickrContext;
	
	@end

这个类实现了OFFlickrAPIRequestDelegate协议，并添加了两个私有属性。我们会很快看到如何使用这些值。

继续添加代码：

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

这段代码创建了一个Flickr的上下文，用于存储ObjectiveFlickr请求的数据。

当前Model层服务类提供的API有一个单独的方法，用于查找基于文本搜索字符的图片。不过我们一会会添加更多的方法。

在RWTFlickrSearchImpl.m中添加以下方法：

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

这个方法需要传入请求方法及请求参数，然后使用block参数来转换响应对象。我们重点看一下第4步：

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

rac_signalForSelector:fromProtocol: 方法创建了successSignal，同样也在代理方法的调用中创建了信号。

代理方法每次调用时，发出的next事件会附带包含方法参数的RACTuple。

实现Flickr搜索的最后一步如下：

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

上面的方法使用signalFromAPIMethod:arguments:transform:方法。flickr.photos.search方法提供的字典来搜索照片。

传递给transform参数的block简单地将NSDictionary响应转化为一个等价的模型对象，让它在ViewModel中更容易使用。

最后一步是打开RWTFlickrSearchViewModel.m方法，然后更新搜索信号来记录日志：

	- (RACSignal *)executeSearchSignal {
	  return [[[self.services getFlickrSearchService]
	           flickrSearchSignal:self.searchText]
	           logAll];
	}

编译，运行并输入一些字符后可在控制台看到以下日志：

	2014-06-03 [...] <RACDynamicSignal: 0x8c368a0> name: +createSignal: next: searchString=wibble, totalresults=1973, photos=(
	    "Wibble, wobble, wibble, wobble",
	    "unoa-army",
	    "Day 277: Cheers to the freakin' weekend!",
	    [...]
	    "Angry sky",
	    Nemesis
	)
	
这样我们MVVM指南的第一部分就差不多结束了，但在结束之前，让我们先看看内存问题吧。

## 内存管理

正如在[ReactiveCocoa指南二：Twitter搜索实例](http://southpeak.github.io/blog/2014/08/02/reactivecocoazhi-nan-er-:twittersou-suo-shi-li/)中所讲的一样，我们在block中使用了self，这可能会导致循环引用的问题。而为了避免此问题，我们需要使用@weakify和@strongify宏来打破这种循环引用。

不过看看signalFromAPIMethod:arguments:transform:方法，你可能会迷惑为什么没有使用这两个宏来引用self？这是因为block是作为createSignal:方法的一个参数，它不会在self和block之间建立一个强引用关系。迷茫了吧？不相信的话只需要测试一样这段代码有没有内存泄露就行。当然这时候就得用Instruments了，自己去看吧。哈哈。

## 何去何从？

例子工程的完整代码可以在[这里](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/FlickrSearchPart1Project1.zip)下载。在下一部分中，我们将看看如何从ViewModel中初始化一个视图控制器并实现更多的Flickr请求操作。