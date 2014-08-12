---
layout: post

title: "MVVM指南二：Flickr搜索深入"

date: 2014-08-12 21:12:20 +0800

comments: true

categories: iOS

---

本文由Colin Eberhardt发表于raywenderlich，原文可查看[MVVM Tutorial with ReactiveCocoa: Part 2/2](http://www.raywenderlich.com/74131/mvvm-tutorial-with-reactivecocoa-part-2)

在第一部分中，我们介绍了MVVM，可以看到ReactiveCocoa如何将ViewModel绑定到各自对应的View上。

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/MVVMReactiveCocoa-700x121.png)

下图是我们程序实现的Flickr搜索功能

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/06/FinishedApp-671x500.png)

在这一部分中，我们来看看如何在程序的ViewModel中驱动视图间的导航操作。

目前我们的程序允许使用简单的搜索字符串来搜索Flickr。我们可以在[这里](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/FlickrSearchPart1Project1.zip)下载程序。Model层使用ReactiveCocoa来提供搜索结果，ViewModel只是简单地记录响应。

现在，我们来看看如何在结果页中进行导航。

## 实现ViewModel导航

当一个Flickr成功返回需要的结果时，程序导航到一个新的视图控制器来显示搜索结果。当前的程序只有一个ViewModel，即RWTFlickrSearchViewModel类。为了实现需要的功能，我们将添加一个新的ViewModel来返回到搜索结果视图。添加新的继承自NSObject的RWTSearchResultsViewModel类到ViewModel分组中，并更新其头文件：

	@import Foundation;
	#import "RWTViewModelServices.h"
	#import "RWTFlickrSearchResults.h"
	 
	@interface RWTSearchResultsViewModel : NSObject
	 
	- (instancetype)initWithSearchResults:(RWTFlickrSearchResults *)results services:(id<RWTViewModelServices>)services;
	 
	@property (strong, nonatomic) NSString *title;
	@property (strong, nonatomic) NSArray *searchResults;
	 
	@end

上述代码添加了描述视图的两个属性，及一个初始化方法。打开RWTSearchResultsViewModel.m并实现初始化方法：

	- (instancetype)initWithSearchResults:(RWTFlickrSearchResults *)results services:(id<RWTViewModelServices>)services {
	  if (self = [super init]) {
	    _title = results.searchString;
	    _searchResults = results.photos;
	  }
	  return self;
	}

回想一下第一部分，ViewModel在View驱动程序之前就已经生成了。下一步就是将View连接到对应的ViewModel上。

打开RWTSearchResultsViewController.h，导入ViewModel，并添加以下初始化方法：

	#import "RWTSearchResultsViewModel.h"
	 
	@interface RWTSearchResultsViewController : UIViewController
	 
	- (instancetype)initWithViewModel:(RWTSearchResultsViewModel *)viewModel;
	 
	@end

打开RWTSearchResultsViewController.m，在类的扩展中添加以下私有属性：

	@property (strong, nonatomic) RWTSearchResultsViewModel *viewModel;
	
在同一个文件下面，实现初始化方法：

	- (instancetype)initWithViewModel:(RWTSearchResultsViewModel *)viewModel {
	  if (self = [super init]) {
	    _viewModel = viewModel;
	  }
	  return self;
	}

在这一步中，我们将重点关注导航如何工作，回到视图控制器中将ViewModel绑定到UI中。

现在程序有两个ViewModel，但是现在将面临一个难题。如何从一个ViewModel导航到另一个ViewModel中，也就是在对应的视图控制器中导航。ViewModel不能直接引用视图，所示我们应该怎么做呢？

答案已经在RWTViewModelServices协议中给出来了。它获取了一个Model层的引用，我们将使用这个协议来允许ViewModel来初始化导航。打开RWTViewModelServices.h并添加以下方法来协议中：

	- (void)pushViewModel:(id)viewModel;
	
理论上讲，是ViewModel层驱动程序，这一层中的逻辑决定了在View中显示什么，及何时进行导航。这个方法允许ViewModel层push一个ViewModel，该方式与UINavigationController方式类似。在更新协议实现前，我们将在ViewModel层先让这个机制工作。

打开RWTFlickrSearchViewModel.m并导入以下头文件

	#import "RWTSearchResultsViewModel.h"

同时在同一文件中更新executeSearchSignal的实现：

	- (RACSignal *)executeSearchSignal {
	  return [[[self.services getFlickrSearchService]
	    flickrSearchSignal:self.searchText]
	    doNext:^(id result) {
	      RWTSearchResultsViewModel *resultsViewModel =
	        [[RWTSearchResultsViewModel alloc] initWithSearchResults:result services:self.services];
	      [self.services pushViewModel:resultsViewModel];
	    }];
	}

上面的代码添加一个addNext操作到搜索命令执行时创建的信号。doNext块创建一个新的ViewModel来显示搜索结果，然后通过ViewModel服务将它push进来。现在是时候更新协议的实现代码了。为了满足这个需求，代码需要一个导航控制器的引用。

打开RWTViewModelServicesImpl.h并添加以下的初始化方法

	- (instancetype)initWithNavigationController:(UINavigationController *)navigationController;

打开RWTViewModelServicesImpl.m并导入以下头文件：

	#import "RWTSearchResultsViewController.h"
	
然后添加一个私有属性：

	@property (weak, nonatomic) UINavigationController *navigationController;

接下来实现初始化方法：

	- (instancetype)initWithNavigationController:(UINavigationController *)navigationController {
	  if (self = [super init]) {
	    _searchService = [RWTFlickrSearchImpl new];
	    _navigationController = navigationController;
	  }
	  return self;
	}

这简单地更新了初始化方法来存储传入的导航控制器的引用。最后，添加以下方法：

	- (void)pushViewModel:(id)viewModel {
	  id viewController;
	 
	  if ([viewModel isKindOfClass:RWTSearchResultsViewModel.class]) {
	    viewController = [[RWTSearchResultsViewController alloc] initWithViewModel:viewModel];
	  } else {
	    NSLog(@"an unknown ViewModel was pushed!");
	  }
	 
	  [self.navigationController pushViewController:viewController animated:YES];
	}

上面的方法使用提供的ViewModel的类型来确定需要哪个视图。在上面的例子中，只有一个ViewModel-View对，不过我确信你可以看到如何扩展这个模式。导航控制器push了结果视图。

最后，打开RWTAppDelegate.m，定位到createInitialViewController方法的RWTViewModelServicesImpl实例创建的地方，用下面的代码替换创建操作：

	self.viewModelServices = [[RWTViewModelServicesImpl alloc] initWithNavigationController:self.navigationController];

运行后，点击"GO"可以看到程序切换到新的ViewModel/View:

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/BlankView-281x500.png)

现在还是空的。别急，我们一步一步来。不过我们的程序现在有多个ViewModel，其中导航控制器通过ViewModel层来进行控制。我们先回来UI绑定上来。

## 渲染结果页

搜索结果的视图对应的nib文件中有一个UITableView。接下来，我们需要在这个table中渲染ViewModel的内容。打开RWTSearchResultsViewController.m并定位到类扩展。更新它以实现UITableViewDataSource协议：

	@interface RWTSearchResultsViewController () <UITableViewDataSource>

重写viewDidLoad的代码：

	- (void)viewDidLoad {
	  [super viewDidLoad];
	 
	  [self.searchResultsTable registerClass:UITableViewCell.class
	                  forCellReuseIdentifier:@"cell"];
	  self.searchResultsTable.dataSource = self;
	 
	  [self bindViewModel];
	}

这段代码执行table view的初始化并将其绑定到view model。先忘记硬编码的cell标识常量，我们会在后面将其移除。

继续在下面添加bindViewModel代码：

	- (void)bindViewModel {
	  self.title = self.viewModel.title;
	}

ViewModel有两个属性：上述代码处理的的标题，及渲染到table中的searchResults数组。那么我们该怎么样将数组绑定到table view呢？实际上，我们做不了。ReactiveCocoa可以绑定一些简单的UI控件，但是不能处理这种针对table view的复杂交互。但不需要担心，还有其它方法。卷起袖子开始做吧。

在同一文件中，添加以下两个数据源方法：

	- (NSInteger)tableView:(UITableView *)tableView
	 numberOfRowsInSection:(NSInteger)section {
	  return self.viewModel.searchResults.count;
	}
	 
	- (UITableViewCell *)tableView:(UITableView *)tableView
	         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	  cell.textLabel.text = [self.viewModel.searchResults[indexPath.row] title];
	  return cell;
	}

这个就不用说了吧。运行后，效果如下：

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/06/PopulatedTable-281x500.png)

## 更好的TableView绑定方法

table view绑定的缺失会很快导致视图控制器代码的增加。而手动绑定看上去又不太优雅。从概念上讲，在ViewModel的searchResults数组中的每一项是一个ViewMode，每个cell是对应一个ViewModel实例。在[这篇博客](http://www.scottlogic.com/blog/2014/05/11/reactivecocoa-tableview-binding.html)中我创建了一个绑定帮助类CETableViewBindingHelper，允许我们定义用于子ViewModel的View，帮助类负责实现数据源协议。我们可以在当前工程的Util分组中找到这个帮助类。

CETableViewBindingHelper的构造方法如下：

	+ (instancetype) bindingHelperForTableView:(UITableView *)tableView
	                              sourceSignal:(RACSignal *)source
	                          selectionCommand:(RACCommand *)selection
	                              templateCell:(UINib *)templateCellNib;

为了将数组绑定到视图中，我们简单创建一个帮助类的实例。它的参数是：

1. 渲染ViewModel数组的table view
2. 处理数组变化的信号
3. 可选的当某行被选中时的命令
4. cell视图的nib文件

nib文件定义的cell必须实现CEReactiveView协议。工程已经包含了一个table view cell，我们可以用它来渲染搜索结果。打开RWTSearchResultsTableViewCell.h并导入协议：

	#import "CEReactiveView.h"
	
采用协议：

	@interface RWTSearchResultsTableViewCell : UITableViewCell <CEReactiveView>

下一步是实现协议。打开RWTSearchResultsTableViewCell.m并添加头文件

	#import <SDWebImage/UIImageView+WebCache.h>
	#import "RWTFlickrPhoto.h"

添加以下方法：

	- (void)bindViewModel:(id)viewModel {
	  RWTFlickrPhoto *photo = viewModel;
	  self.titleLabel.text = photo.title;
	 
	  self.imageThumbnailView.contentMode = UIViewContentModeScaleToFill;
	 
	  [self.imageThumbnailView setImageWithURL:photo.url];
	}

RWTSearchResultsViewModel的searchResults属性包含RWTFlickrPhoto实例的数组。它们被直接绑定到View，而不是在ViewModel中包装这些Model对象。

bindViewModel方法使用了SDWebImage第三方库，它在后台线程下载并解码图片数据，大大提高了scroll的性能。

最后一步是使用绑定帮助类来渲染table。

打开RWTSearchResultsViewController.m并导入头文件：

	#import "CETableViewBindingHelper.h"
	
在该文件下面的代码中移除对UITableDataSource协议的实现，同时移除实现的方法。接下来，添加以下私有属性：

	@property (strong, nonatomic) CETableViewBindingHelper *bindingHelper;
	
在viewDidLoad方法中移除table view的配置代码，回归来方法的最初形式：

	- (void)viewDidLoad {
	  [super viewDidLoad]; 
	  [self bindViewModel];
	}

然后我们在[self bindViewModel]后面添加以下代码：

	UINib *nib = [UINib nibWithNibName:@"RWTSearchResultsTableViewCell" bundle:nil];
	 
	self.bindingHelper =
	  [CETableViewBindingHelper bindingHelperForTableView:self.searchResultsTable
	                                         sourceSignal:RACObserve(self.viewModel, searchResults)
	                                     selectionCommand:nil
	                                         templateCell:nib];

这从nib文件中创建了一个UINib实例并构建了一个绑定帮助类实例，sourceSignal是通过观察ViewModel的searchResults属性改变而创建的。

运行后，得到新的UI：

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/06/UsingTheBindingHelper-281x500.png)

## 一些UI特效

到目前为止，本指南主要关注于根据MVVM模式来构建程序。接下来，我们做点别的吧：添加特效。

iOS7已经发布一年多了，“运动设计(motion design)”获取了更多的青睐，很多设计者现在都喜欢用这种微妙的对话和流体行为。

在这一步中，我们将添加一个图片滑动的特效，很不错的。

打开RWTSearchResultsTableViewCell.h并添加以下方法：

	- (void) setParallax:(CGFloat)value;
	
table view将使用这个方法来为每个cell提供视差补偿。

打开RWTSearchResultsTableViewCell.m并实现这个方法：

	- (void)setParallax:(CGFloat)value {
	  self.imageThumbnailView.transform = CGAffineTransformMakeTranslation(0, value);
	}

很不错，这只是个简单的变换。

打开RWTSearchResultsViewController.m并导入以下头文件：

	#import "RWTSearchResultsTableViewCell.h"
	
然后在类扩展中采用UITableViewDelegate协议：

	@interface RWTSearchResultsViewController () <UITableViewDataSource, UITableViewDelegate>

我们只是添加一个绑定辅助类来将将它自己设置为table view的代理，以便其可以响应行的选择。然而，它也转发代理方法调用到它所有的代理属性，这样我们仍然可以添加自定义行为。

在bindViewModel方法中，设置绑定辅助类代理：

	self.bindingHelper.delegate = self;
	
在同一文件下面，添加scrollViewDidScroll的实现：

	- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	  NSArray *cells = [self.searchResultsTable visibleCells];
	  for (RWTSearchResultsTableViewCell *cell in cells) {
	    CGFloat value = -40 + (cell.frame.origin.y - self.searchResultsTable.contentOffset.y) / 5;
	    [cell setParallax:value];
	  }
	}

table view每次滚动时，调用这个方法。它迭代所有的可见cell，计算用于视差效果的偏移值。这个偏移值依赖于cell在table view中可见部分的位置。

运行后，可得到以下效果

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/ParallaxAnimation.gif)

现在我们回到业务的View和ViewModel。

## 查询评论及收藏计数

我们应该在列表界面中每幅图片的右下方显示评论的数量和收藏的数量。当前我们只在nib文件中显示一个假数据'123'。我们在使用真值来替换这些值前，需要在Model层添加这些功能。添加表示查询Flickr API结果的Model对象的步骤跟前面一样。

在Model分组中添加RWTFlickrPhotoMetadata类，打开RWTFlickrPhotoMetadata.h并添加以下属性：

	@property (nonatomic) NSUInteger favorites;
	@property (nonatomic) NSUInteger comments;
	
打开RWTFlickrPhotoMetadata.m并添加description的实现

	- (NSString *)description {
	  return [NSString stringWithFormat:@"metadata: comments=%lU, faves=%lU",
	          self.comments, self.favorites];
	}

接下来打开RWTFlickrSearch.h并添加以下方法：

	- (RACSignal *)flickrImageMetadata:(NSString *)photoId;
	
ViewModel将使用这个方法来请求给定图片的元数据，如评论和收藏。

接下来打开RWTFlickrSearchImpl.m并添加以下头文件：

	#import "RWTFlickrPhotoMetadata.h"
	#import <ReactiveCocoa/RACEXTScope.h>

接下来实现flickrImageMetadata方法。不幸的是，这里有些小问题：为了获取图片相关的评论数，我们需要调用flickr.photos.getinfo方法；为了获取收藏数，需要调用flickr.photos.getFavorites方法。这让事件变得有点复杂，因为flickrImageMetadata方法需要调用两个接口请求以获取需要的数据。不过，ReactiveCocoa已经为我们解决了这个问题。

添加以下实现：

	- (RACSignal *)flickrImageMetadata:(NSString *)photoId {
	 
	  RACSignal *favorites = [self signalFromAPIMethod:@"flickr.photos.getFavorites"
	                                          arguments:@{@"photo_id": photoId}
	                                          transform:^id(NSDictionary *response) {
	                                            NSString *total = [response valueForKeyPath:@"photo.total"];
	                                            return total;
	                                          }];
	 
	  RACSignal *comments = [self signalFromAPIMethod:@"flickr.photos.getInfo"
	                                        arguments:@{@"photo_id": photoId}
	                                        transform:^id(NSDictionary *response) {
	                                          NSString *total = [response valueForKeyPath:@"photo.comments._text"];
	                                          return total;
	                                        }];
	 
	  return [RACSignal combineLatest:@[favorites, comments] reduce:^id(NSString *favs, NSString *coms){
	    RWTFlickrPhotoMetadata *meta = [RWTFlickrPhotoMetadata new];
	    meta.comments = [coms integerValue];
	    meta.favorites = [favs integerValue];
	    return  meta;
	  }];
	}

上面的代码使用signalFromAPIMethod:arguments:transform:来从底层的基于ObjectiveFLickr的接口创建信号。上面的代码创建了一个信号对，一个用于获取收藏的数量，一个用于获取评论的数量。

一旦创建了两个信号，combineLatest:reduce:方法生成一个新的信号来组合两者。

这个方法等待源信号的一个next事件。reduce块使用它们的内容来调用，其结果变成联合信号的next事件。

简单明了吧！

不过在庆祝前，我们回到signalFromAPIMethod:arguments:transform:方法来修复之前提到的一个错误。你注意到了么？这个方法为每个请求创建一个新的OFFlickrAPIRequest实例。然后，每个请求的结果是通过代理对象来返回的，而这种情况下，其代理是它自己。结果是，在并发请求的情况下，没有办法指明哪个flickrAPIRequest:didCompleteWithResponse:调用用来响应哪个请求。不过，ObjectiveFlickr代理方法签名在第一个参数中包含了相应请求，所以这个问题很好解决。

在signalFromAPIMethod:arguments:transform:中，使用下面的代码来替换处理successSignal的管道：

	@weakify(flickrRequest)
	[[[[successSignal
	  filter:^BOOL(RACTuple *tuple) {
	    @strongify(flickrRequest)
	    return tuple.first == flickrRequest;
	  }]
	  map:^id(RACTuple *tuple) {
	    return tuple.second;
	  }]
	  map:block]
	  subscribeNext:^(id x) {
	    [subscriber sendNext:x];
	    [subscriber sendCompleted];
	  }];

这只是简单地添加一个filter操作来移除任何与请求相关的代理方法调用，而不是生成当前的信号。

最后一步是在ViewModel层中使用信号。

打开RWTSearchResultsViewModel.m并导入以下头文件：

	#import "RWTFlickrPhoto.h"
	
在同一文件中的初始化的末尾添加以下代码：

	RWTFlickrPhoto *photo = results.photos.firstObject;
	RACSignal *metaDataSignal = [[services getFlickrSearchService]
	                            flickrImageMetadata:photo.identifier];
	    [metaDataSignal subscribeNext:^(id x) {
	     NSLog(@"%@", x);
	   }];

这段代码测试了新添加的方法，该方法从返回的结果中的第一幅图片获取图片元数据。运行程序后，会在控制台输出以下信息：

	2014-06-04 07:27:26.813 RWTFlickrSearch[76828:70b] metadata: comments=120, faves=434
	
## 获取可见cell的元数据

我们可以扩展当前代码来获取所有搜索结果的元数据。然而，如果我们有100条结果，则需要立即发起200个请求，每幅图片2个请求。大多数API都有些限制，这种调用方式会阻塞我们的请求调用，至少是临时的。

在一个table中，我们只需要获取当前显示的单元格所对象的结果的元数据。所以，如何实现这个行为呢？当然，我们需要一个ViewModel来表示这些数据。当前RWTSearchResultsViewModel暴露了一个绑定到View的RWTFlickrPhoto实例的数组，它们的暴露给View的Model层对象。为了添加这种可见性，我们将给ViewModel中的model对象添加view-centric状态。

在ViewModel分组中添加RWTSearchResultsItemViewModel类，打开头文件并各以下代码更新：

	@import Foundation;
	#import "RWTFlickrPhoto.h"
	#import "RWTViewModelServices.h"
	 
	@interface RWTSearchResultsItemViewModel : NSObject
	 
	- (instancetype) initWithPhoto:(RWTFlickrPhoto *)photo services:(id<RWTViewModelServices>)services;
	 
	@property (nonatomic) BOOL isVisible;
	@property (strong, nonatomic) NSString *title;
	@property (strong, nonatomic) NSURL *url;
	@property (strong, nonatomic) NSNumber *favorites;
	@property (strong, nonatomic) NSNumber *comments;
	 
	@end

看看初始化方法，这个ViewModel封装了一个RWTFlickrPhoto模型对象的实例。这个ViewModel包含以下几类属性：

1. 表示底层Model属性的属性(title, url)
2. 当获取到元数据时动态更新的属性(favorites, comments)
3. isVisible，用于表示ViewModel是否可见

打开RWTSearchResultsItemViewModel.m并导入以下头文件：

	#import <ReactiveCocoa/ReactiveCocoa.h>
	#import <ReactiveCocoa/RACEXTScope.h>
	#import "RWTFlickrPhotoMetadata.h"

接下来添加几个私有属性：

	@interface RWTSearchResultsItemViewModel ()
	 
	@property (weak, nonatomic) id<RWTViewModelServices> services;
	@property (strong, nonatomic) RWTFlickrPhoto *photo;
	 
	@end

然后实现初始化方法：

	- (instancetype)initWithPhoto:(RWTFlickrPhoto *)photo services:(id<RWTViewModelServices>)services {
	  self = [super init];
	  if (self) {
	    _title = photo.title;
	    _url = photo.url;
	    _services = services;
	    _photo = photo;
	 
	    [self initialize];
	  }
	  return  self;
	}

这基于Model对象的title和url属性，然后通过私有属性来存储服务和图片的引用。

接下来添加initialize方法。准备好，这里有些有趣的事情会发生。

	- (void)initialize {
	  RACSignal *fetchMetadata =
	    [RACObserve(self, isVisible)
	     filter:^BOOL(NSNumber *visible) {
	       return [visible boolValue];
	     }];
	 
	  @weakify(self)
	  [fetchMetadata subscribeNext:^(id x) {
	    @strongify(self)
	    [[[self.services getFlickrSearchService] flickrImageMetadata:self.photo.identifier]
	     subscribeNext:^(RWTFlickrPhotoMetadata *x) {
	       self.favorites = @(x.favorites);
	       self.comments = @(x.comments);
	     }];
	  }];
	}

这个方法的第一部分通过监听isVisible属性和过滤true值来创建一个名为fetchMetadata的信号。结果，信号在isVisible属性设置为true时发出next事件。第二部分订阅这个信号以初始化到flickrImageMetadata方法的请求。当这个嵌套的信号发送next事件时，favorite和comment属性使用这个结果来更新值。

总的来说，当isVisible设置为true时，发送Flickr API请求，并在将来某个时刻更新comments和favorites属性。

为了使用新的ViewModel，打开RWTSearchResultsViewModel.m并导入头文件：

	#import <LinqToObjectiveC/NSArray+LinqExtensions.h>
	#import "RWTSearchResultsItemViewModel.h"

在初始化方法中，移除当前设置_searchResults的代码，并使用以下代码：

	_searchResults =
	  [results.photos linq_select:^id(RWTFlickrPhoto *photo) {
	    return [[RWTSearchResultsItemViewModel alloc]
	              initWithPhoto:photo services:services];
	  }];

这只是简单地使用一个ViewModel来包装每一个Model对象。

最后一步是通过视图来设置isVisible对象，并使用这些新的属性。

打开RWTSearchResultsTableViewCell.m并导入以下头文件：

	#import "RWTSearchResultsItemViewModel.h"

然后在下面的bindViewModel方法的第一行添加以下代码：

	RWTSearchResultsItemViewModel *photo = viewModel;
	
并在访方法中添加以下代码：

	[RACObserve(photo, favorites) subscribeNext:^(NSNumber *x) {
	  self.favouritesLabel.text = [x stringValue];
	  self.favouritesIcon.hidden = (x == nil);
	}];
	 
	[RACObserve(photo, comments) subscribeNext:^(NSNumber *x) {
	  self.commentsLabel.text = [x stringValue];
	  self.commentsIcon.hidden = (x == nil);
	}];
	 
	photo.isVisible = YES;

这个代码监听了新的comments和favorites属性，当它们更新lable和image时会更新。最后，ModelView的isVisible属性被设置成YES。table view绑定辅助类只绑定可见的单元格，所以只有少部分ViewModel去请求元数据。

运行后，以看到以下效果：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/WithMetadata-333x500.png)

是不是很酷？

## 节流

慢着，还有一个问题没有解决。当我们快速地滚动滑动栏，如果不做特殊，会同时加载大量的元数据和图片，这将明显地降低我们程序的性能。为了解决这个问题，程序应该只在照片显示在界面上的的时候去初始化元数据请求。现在ViewModel的isVisible属性被设置为YES，但不会被设置成NO。我们现在来处理这个问题。

打开RWTSearchResultsTableViewCell.m，然后修改刚才添加到bindViewModel:的代码，以设置isVisible属性：

	photo.isVisible = YES;
	[self.rac_prepareForReuseSignal subscribeNext:^(id x) {
	  photo.isVisible = NO;
	}];

当ViewModel绑定到View时，isVisible属性会被设置成YES。但是当cell被移出table view进行重用时会被设置成NO。我们通过rac_prepareForReuseSignal信号来实现这步操作。

返回到RWTSearchResultsItemViewModel中。ViewModel需要监听isVisible属性的修改，当属性被设置成YES后一秒钟，将发送一个元数据的请求。

在RWTSearchResultsItemViewModel.m中，更新initialize方法，移除fetchMetadata信号的创建。使用以下代码来替换：

	// 1. 通过监听isVisible属性来创建信号。该信号发出的第一个next事件将包含这个属性的初始状态。
	// 因为我们只关心这个值的改变，所以在第一个事件上调用skip操作。
	RACSignal *visibleStateChanged = [RACObserve(self, isVisible) skip:1];
	 
	// 2. 通过过滤visibleStateChanged信号来创建一个信号对，一个标识从可见到隐藏的转换，另一个标识从隐藏到可见的转换
	RACSignal *visibleSignal = [visibleStateChanged filter:^BOOL(NSNumber *value) {
	  return [value boolValue];
	}];
	 
	RACSignal *hiddenSignal = [visibleStateChanged filter:^BOOL(NSNumber *value) {
	  return ![value boolValue];
	}];
	 
	// 3. 这里是最神奇的地方。通过延迟visibleSignal信号1秒钟来创建fetchMetadata信号，在获取元数据之前暂停一会。
	// takeUntil操作确保如果cell在1秒的时间间隔内又一次隐藏时，来自visibleSignal的next事件被挂起且不获取元数据。
	RACSignal *fetchMetadata = [[visibleSignal delay:1.0f]
	                           takeUntil:hiddenSignal];

你可以想像一下如果没有ReactiveCocoa，这会有多复杂。

运行程序，现在我们和滑动显示平滑多了。

## 错误处理

当前搜索Flickr的代码只处理了OFFlickrAPIRequestDelegate协议中的flickrAPIRequest:didCompleteWithResponse:方法。不过，这样网络请求由于多种原因会出错。一个好的应用程序必须处理这些错误，以给用户一个良好的用户体验。代理同时定义了flickrAPIRequest:didFailWithError:方法，这个方法在请求出错时调用。我们将用这个方法来处理错误并显示一个提示框给用户。

我们之前讲过信号会发出next，completed和错误事件。其结果是，我们并不需要做太多的事情。

打开RWTFlickrSearchImpl.m，并定位到signalFromAPIMethod:arguments:transform:方法。在这个方法中，在创建successSignal变量前添加以下代码：
	
	RACSignal *errorSignal =
	  [self rac_signalForSelector:@selector(flickrAPIRequest:didFailWithError:)
	                 fromProtocol:@protocol(OFFlickrAPIRequestDelegate)];
	 
	[errorSignal subscribeNext:^(RACTuple *tuple) {
	  [subscriber sendError:tuple.second];
	}];

上面的代码从代理方法中创建了一个信号，订阅了该信号，如果发生错误则发送一个错误。传递给subscribeNext块的元组包含传递给flickrAPIRequest:didFailWithError:方法的变量。结果是，tuple.second获取源错误并使用它来为错误事件服务。这是一个很好的解决方案，你觉得呢？不是所有的API请求都有内建的错误处理。接下来我们使用它。

RWTFlickrSearchViewModel不直接暴露信号给视图。相反它暴露一个状态和一个命令。我们需要扩展接口来提供错误报告。

打开RWTFlickrSearchViewModel.h并添加以下属性：

	@property (strong, nonatomic) RACSignal *connectionErrors;

打开RWTFlickrSearchViewModel.m并添加以下代码到initialize实现的最后：

	self.connectionErrors = self.executeSearch.errors;
	
executeSearch属性是一个ReactiveCococa框架的RACCommand对象。RACCommand类有一个errors属性，用于发送命令执行时产生的任何错误。

为了处理这些错误，打开RWTFlickrSearchViewController.m并添加以下的代码到initWithViewModel:方法中：

	[_viewModel.connectionErrors subscribeNext:^(NSError *error) {
	  UIAlertView *alert =
	  [[UIAlertView alloc] initWithTitle:@"Connection Error"
	                             message:@"There was a problem reaching Flickr."
	                            delegate:nil
	                   cancelButtonTitle:@"OK"
	                   otherButtonTitles:nil];
	  [alert show];
	}];

运行后，处理错误的效果如下：

![image](http://cdn2.raywenderlich.com/wp-content/uploads/2014/06/ErrorMessages-281x500.png)

想知道为什么获取收藏和评论的请求不报告错误么？这是由设计决定的，主要是这些不会影响程序的可用性。

## 添加最近搜索列表

用户可能会回去查看一些重复的图片。所以，我们可以做些简化操作。回想一下本文的开头，最后的程序在搜索输入框下面有一个显示最近搜索结果的列表。

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/06/FinishedApp-671x500.png)

现在我们只需要添加上这个功能，这次我要向你发起一个挑战了。我将这一部分的实现留给读者您来处理，来练习练习MVVM技能吧。

在开始之前，我在这些做些总结：

1. 我将创建一个ViewModel来表示每个先前的搜索，它包含一些属性，这些属性包括搜索文本，匹配的数量和第一个匹配的图片
2. 我将修改RWTFlickrSearchViewModel来暴露这些新的ViewModel对象的数组做为一个属性。
3. 使用CETableViewBindingHelper可以非常简单地渲染ViewModel的数组，我已经添加了一个合适的cell(RWTRecentSearchItemTableViewCell)到工程中。

## 接下来何去何从？

在[这里](https://github.com/ColinEberhardt/ReactiveFlickrSearch)可以下载最终的程序。这两部分的内容已经包含了很多内容，这里我们可以好好回顾一下主要点：

1. MVVM是MVC模式的一个变种，它正逐渐流行起来
2. MVVM模式让View层代码变得更清晰，更易于测试
3. 严格遵守View=>ViewModel=>Model这样一个引用层次，然后通过绑定来将ViewModel的更新反映到View层上。
4. ViewModel层决不应该维护View的引用
5. ViewModel层可以看作是视图的模型(model-of-the-view)，它暴露属性，以直接反映视图的状态，以及执行用户交互相关的命令。
6. Model层暴露服务。
7. 针对MVVM程序的测试可以在没有UI的情况下运行。
8. ReactiveCocoa框架提供强大的机制来将ViewModel绑定到View。它同时也广泛地使用在ViewModel和Model层中。

怎么样，下次创建程序的时候，是不是试试MVVM？试试吧。

