---
layout: post
title: "MVVM Tutorial with ReactiveCocoa: Part 2/2"
date: 2014-08-12 21:12:20 +0800
comments: true
categories: translate iOS
---

本文由`Colin Eberhardt`发表于`raywenderlich`，原文可查看[MVVM Tutorial with ReactiveCocoa: Part 2/2](http://www.raywenderlich.com/74131/mvvm-tutorial-with-reactivecocoa-part-2)

在第一部分中，我们介绍了`MVVM`，可以看到`ReactiveCocoa`如何将`ViewModel`绑定到各自对应的`View`上。

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/MVVMReactiveCocoa-700x121.png)

下图是我们程序实现的`Flickr`搜索功能

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/06/FinishedApp-671x500.png)

在这一部分中，我们来看看如何在程序的`ViewModel`中驱动视图间的导航操作。

目前我们的程序允许使用简单的搜索字符串来搜索`Flickr`。我们可以在[这里](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/FlickrSearchPart1Project1.zip)下载程序。`Model`层使用`ReactiveCocoa`来提供搜索结果，`ViewModel`只是简单地记录响应。

现在，我们来看看如何在结果页中进行导航。

## 实现ViewModel导航

当一个`Flickr`成功返回需要的结果时，程序导航到一个新的视图控制器来显示搜索结果。当前的程序只有一个`ViewModel`，即`RWTFlickrSearchViewModel`类。为了实现需要的功能，我们将添加一个新的`ViewModel`来返回到搜索结果视图。添加新的继承自`NSObject`的`RWTSearchResultsViewModel`类到`ViewModel`分组中，并更新其头文件：

``` objective-c
@import Foundation;
#import "RWTViewModelServices.h"
#import "RWTFlickrSearchResults.h"
 
@interface RWTSearchResultsViewModel : NSObject
 
- (instancetype)initWithSearchResults:(RWTFlickrSearchResults *)results services:(id<RWTViewModelServices>)services;
 
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSArray *searchResults;
 
@end
```

上述代码添加了描述视图的两个属性，及一个初始化方法。打开`RWTSearchResultsViewModel.m`并实现初始化方法：

``` objective-c
- (instancetype)initWithSearchResults:(RWTFlickrSearchResults *)results services:(id<RWTViewModelServices>)services {
  if (self = [super init]) {
    _title = results.searchString;
    _searchResults = results.photos;
  }
  return self;
}
```

回想一下第一部分，`ViewModel`在`View`驱动程序之前就已经生成了。下一步就是将`View`连接到对应的`ViewModel`上。

打开`RWTSearchResultsViewController.h`，导入`ViewModel`，并添加以下初始化方法：

``` objective-c
#import "RWTSearchResultsViewModel.h"
 
@interface RWTSearchResultsViewController : UIViewController
 
- (instancetype)initWithViewModel:(RWTSearchResultsViewModel *)viewModel;
 
@end
```

打开`RWTSearchResultsViewController.m`，在类的扩展中添加以下私有属性：

``` objective-c
@property (strong, nonatomic) RWTSearchResultsViewModel *viewModel;
```

在同一个文件下面，实现初始化方法：

``` objective-c
- (instancetype)initWithViewModel:(RWTSearchResultsViewModel *)viewModel {
  if (self = [super init]) {
    _viewModel = viewModel;
  }
  return self;
}
```

在这一步中，我们将重点关注导航如何工作，回到视图控制器中将`ViewModel`绑定到`UI`中。

现在程序有两个`ViewModel`，但是现在将面临一个难题。如何从一个`ViewModel`导航到另一个`ViewModel`中，也就是在对应的视图控制器中导航。`ViewModel`不能直接引用视图，所示我们应该怎么做呢？

答案已经在`RWTViewModelServices`协议中给出来了。它获取了一个`Model`层的引用，我们将使用这个协议来允许`ViewModel`来初始化导航。打开`RWTViewModelServices.h`并添加以下方法来协议中：

``` objective-c
- (void)pushViewModel:(id)viewModel;
```

理论上讲，是`ViewModel`层驱动程序，这一层中的逻辑决定了在`View`中显示什么，及何时进行导航。这个方法允许`ViewModel`层`push`一个`ViewModel`，该方式与`UINavigationController`方式类似。在更新协议实现前，我们将在`ViewModel`层先让这个机制工作。

打开`RWTFlickrSearchViewModel.m`并导入以下头文件

``` objective-c
#import "RWTSearchResultsViewModel.h"
```

同时在同一文件中更新`executeSearchSignal`的实现：

``` objective-c
- (RACSignal *)executeSearchSignal {
  return [[[self.services getFlickrSearchService]
    flickrSearchSignal:self.searchText]
    doNext:^(id result) {
      RWTSearchResultsViewModel *resultsViewModel =
        [[RWTSearchResultsViewModel alloc] initWithSearchResults:result services:self.services];
      [self.services pushViewModel:resultsViewModel];
    }];
}
```

上面的代码添加一个`addNext`操作到搜索命令执行时创建的信号。`doNext`块创建一个新的`ViewModel`来显示搜索结果，然后通过`ViewModel`服务将它`push`进来。现在是时候更新协议的实现代码了。为了满足这个需求，代码需要一个导航控制器的引用。

打开`RWTViewModelServicesImpl.h`并添加以下的初始化方法

``` objective-c
- (instancetype)initWithNavigationController:(UINavigationController *)navigationController;
```

打开`RWTViewModelServicesImpl.m`并导入以下头文件：

``` objective-c
#import "RWTSearchResultsViewController.h"
```

然后添加一个私有属性：

``` objective-c
@property (weak, nonatomic) UINavigationController *navigationController;
```

接下来实现初始化方法：

``` objective-c
- (instancetype)initWithNavigationController:(UINavigationController *)navigationController {
  if (self = [super init]) {
    _searchService = [RWTFlickrSearchImpl new];
    _navigationController = navigationController;
  }
  return self;
}
```

这简单地更新了初始化方法来存储传入的导航控制器的引用。最后，添加以下方法：

``` objective-c
- (void)pushViewModel:(id)viewModel {
  id viewController;
 
  if ([viewModel isKindOfClass:RWTSearchResultsViewModel.class]) {
    viewController = [[RWTSearchResultsViewController alloc] initWithViewModel:viewModel];
  } else {
    NSLog(@"an unknown ViewModel was pushed!");
  }
 
  [self.navigationController pushViewController:viewController animated:YES];
}
```

上面的方法使用提供的`ViewModel`的类型来确定需要哪个视图。在上面的例子中，只有一个`ViewModel-View`对，不过我确信你可以看到如何扩展这个模式。导航控制器`push`了结果视图。

最后，打开`RWTAppDelegate.m`，定位到`createInitialViewController`方法的`RWTViewModelServicesImpl`实例创建的地方，用下面的代码替换创建操作：

``` objective-c
self.viewModelServices = [[RWTViewModelServicesImpl alloc] initWithNavigationController:self.navigationController];
```

运行后，点击"`GO`"可以看到程序切换到新的`ViewModel/View`:

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/BlankView-281x500.png)

现在还是空的。别急，我们一步一步来。不过我们的程序现在有多个`ViewModel`，其中导航控制器通过`ViewModel`层来进行控制。我们先回来`UI`绑定上来。

## 渲染结果页

搜索结果的视图对应的`nib`文件中有一个`UITableView`。接下来，我们需要在这个`table`中渲染`ViewModel`的内容。打开`RWTSearchResultsViewController.m`并定位到类扩展。更新它以实现`UITableViewDataSource`协议：

``` objective-c
@interface RWTSearchResultsViewController () <UITableViewDataSource>
```

重写`viewDidLoad`的代码：

``` objective-c
- (void)viewDidLoad {
  [super viewDidLoad];
 
  [self.searchResultsTable registerClass:UITableViewCell.class
                  forCellReuseIdentifier:@"cell"];
  self.searchResultsTable.dataSource = self;
 
  [self bindViewModel];
}
```

这段代码执行`table view`的初始化并将其绑定到`view model`。先忘记硬编码的`cell`标识常量，我们会在后面将其移除。

继续在下面添加`bindViewModel`代码：

``` objective-c
- (void)bindViewModel {
  self.title = self.viewModel.title;
}
```

`ViewModel`有两个属性：上述代码处理的的标题，及渲染到`table`中的`searchResults`数组。那么我们该怎么样将数组绑定到`table view`呢？实际上，我们做不了。`ReactiveCocoa`可以绑定一些简单的UI控件，但是不能处理这种针对`table view`的复杂交互。但不需要担心，还有其它方法。卷起袖子开始做吧。

在同一文件中，添加以下两个数据源方法：

``` objective-c
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
```

这个就不用说了吧。运行后，效果如下：

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/06/PopulatedTable-281x500.png)

## 更好的TableView绑定方法

`table view`绑定的缺失会很快导致视图控制器代码的增加。而手动绑定看上去又不太优雅。从概念上讲，在`ViewModel`的`searchResults`数组中的每一项是一个`ViewMode`，每个`cell`是对应一个`ViewModel`实例。在[这篇博客](http://www.scottlogic.com/blog/2014/05/11/reactivecocoa-tableview-binding.html)中我创建了一个绑定帮助类`CETableViewBindingHelper`，允许我们定义用于子`ViewModel`的`View`，帮助类负责实现数据源协议。我们可以在当前工程的`Util`分组中找到这个帮助类。

`CETableViewBindingHelper`的构造方法如下：

``` objective-c
+ (instancetype) bindingHelperForTableView:(UITableView *)tableView
                              sourceSignal:(RACSignal *)source
                          selectionCommand:(RACCommand *)selection
                              templateCell:(UINib *)templateCellNib;
```

为了将数组绑定到视图中，我们简单创建一个帮助类的实例。它的参数是：

1. 渲染`ViewModel`数组的`table view`
2. 处理数组变化的信号
3. 可选的当某行被选中时的命令
4. `cell`视图的`nib`文件

`nib`文件定义的`cell`必须实现`CEReactiveView`协议。工程已经包含了一个`table view cell`，我们可以用它来渲染搜索结果。打开`RWTSearchResultsTableViewCell.h`并导入协议：

``` objective-c
#import "CEReactiveView.h"
```

采用协议：

``` objective-c
@interface RWTSearchResultsTableViewCell : UITableViewCell <CEReactiveView>
```

下一步是实现协议。打开`RWTSearchResultsTableViewCell.m`并添加头文件

``` objective-c
#import <SDWebImage/UIImageView+WebCache.h>
#import "RWTFlickrPhoto.h"
```

添加以下方法：

``` objective-c
- (void)bindViewModel:(id)viewModel {
  RWTFlickrPhoto *photo = viewModel;
  self.titleLabel.text = photo.title;
 
  self.imageThumbnailView.contentMode = UIViewContentModeScaleToFill;
 
  [self.imageThumbnailView setImageWithURL:photo.url];
}
```

`RWTSearchResultsViewModel`的`searchResults`属性包含`RWTFlickrPhoto`实例的数组。它们被直接绑定到`View`，而不是在`ViewModel`中包装这些`Model`对象。

`bindViewModel`方法使用了`SDWebImage`第三方库，它在后台线程下载并解码图片数据，大大提高了`scroll`的性能。

最后一步是使用绑定帮助类来渲染`table`。

打开`RWTSearchResultsViewController.m`并导入头文件：

``` objective-c
#import "CETableViewBindingHelper.h"
```

在该文件下面的代码中移除对`UITableDataSource`协议的实现，同时移除实现的方法。接下来，添加以下私有属性：

``` objective-c
@property (strong, nonatomic) CETableViewBindingHelper *bindingHelper;
```

在`viewDidLoad`方法中移除`table view`的配置代码，回归来方法的最初形式：

``` objective-c
- (void)viewDidLoad {
  [super viewDidLoad]; 
  [self bindViewModel];
}
```

然后我们在`[self bindViewModel]`后面添加以下代码：

``` objective-c
UINib *nib = [UINib nibWithNibName:@"RWTSearchResultsTableViewCell" bundle:nil];
 
self.bindingHelper =
  [CETableViewBindingHelper bindingHelperForTableView:self.searchResultsTable
                                         sourceSignal:RACObserve(self.viewModel, searchResults)
                                     selectionCommand:nil
                                         templateCell:nib];
```

这从`nib`文件中创建了一个`UINib`实例并构建了一个绑定帮助类实例，`sourceSignal`是通过观察`ViewModel`的`searchResults`属性改变而创建的。

运行后，得到新的`UI`：

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/06/UsingTheBindingHelper-281x500.png)

## 一些UI特效

到目前为止，本指南主要关注于根据MVVM模式来构建程序。接下来，我们做点别的吧：添加特效。

`iOS7`已经发布一年多了，“运动设计(`motion design`)”获取了更多的青睐，很多设计者现在都喜欢用这种微妙的对话和流体行为。

在这一步中，我们将添加一个图片滑动的特效，很不错的。

打开`RWTSearchResultsTableViewCell.h`并添加以下方法：

``` objective-c
- (void) setParallax:(CGFloat)value;
```

`table view`将使用这个方法来为每个`cell`提供视差补偿。

打开`RWTSearchResultsTableViewCell.m`并实现这个方法：

``` objective-c
- (void)setParallax:(CGFloat)value {
  self.imageThumbnailView.transform = CGAffineTransformMakeTranslation(0, value);
}
```

很不错，这只是个简单的变换。

打开`RWTSearchResultsViewController.m`并导入以下头文件：

``` objective-c
#import "RWTSearchResultsTableViewCell.h"
```

然后在类扩展中采用`UITableViewDelegate`协议：

``` objective-c
@interface RWTSearchResultsViewController () <UITableViewDataSource, UITableViewDelegate>
```

我们只是添加一个绑定辅助类来将将它自己设置为`table view`的代理，以便其可以响应行的选择。然而，它也转发代理方法调用到它所有的代理属性，这样我们仍然可以添加自定义行为。

在`bindViewModel`方法中，设置绑定辅助类代理：

``` objective-c
self.bindingHelper.delegate = self;
```

在同一文件下面，添加`scrollViewDidScroll`的实现：

``` objective-c
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
  NSArray *cells = [self.searchResultsTable visibleCells];
  for (RWTSearchResultsTableViewCell *cell in cells) {
    CGFloat value = -40 + (cell.frame.origin.y - self.searchResultsTable.contentOffset.y) / 5;
    [cell setParallax:value];
  }
}
```

`table view`每次滚动时，调用这个方法。它迭代所有的可见`cell`，计算用于视差效果的偏移值。这个偏移值依赖于`cell`在`table view`中可见部分的位置。

运行后，可得到以下效果

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/06/ParallaxAnimation.gif)

现在我们回到业务的`View`和`ViewModel`。

## 查询评论及收藏计数

我们应该在列表界面中每幅图片的右下方显示评论的数量和收藏的数量。当前我们只在`nib`文件中显示一个假数据'`123`'。我们在使用真值来替换这些值前，需要在`Model`层添加这些功能。添加表示查询`Flickr` `API`结果的`Model`对象的步骤跟前面一样。

在`Model`分组中添加`RWTFlickrPhotoMetadata`类，打开`RWTFlickrPhotoMetadata.h`并添加以下属性：

``` objective-c
@property (nonatomic) NSUInteger favorites;
@property (nonatomic) NSUInteger comments;
```

打开`RWTFlickrPhotoMetadata.m`并添加`description`的实现

``` objective-c
- (NSString *)description {
  return [NSString stringWithFormat:@"metadata: comments=%lU, faves=%lU",
          self.comments, self.favorites];
}
```

接下来打开`RWTFlickrSearch.h`并添加以下方法：

``` objective-c
- (RACSignal *)flickrImageMetadata:(NSString *)photoId;
```

`ViewModel`将使用这个方法来请求给定图片的元数据，如评论和收藏。

接下来打开`RWTFlickrSearchImpl.m`并添加以下头文件：

``` objective-c
#import "RWTFlickrPhotoMetadata.h"
#import <ReactiveCocoa/RACEXTScope.h>
```

接下来实现`flickrImageMetadata`方法。不幸的是，这里有些小问题：为了获取图片相关的评论数，我们需要调用`flickr.photos.getinfo`方法；为了获取收藏数，需要调用`flickr.photos.getFavorites`方法。这让事件变得有点复杂，因为`flickrImageMetadata`方法需要调用两个接口请求以获取需要的数据。不过，`ReactiveCocoa`已经为我们解决了这个问题。

添加以下实现：

``` objective-c
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
```

上面的代码使用`signalFromAPIMethod:arguments:transform:`来从底层的基于`ObjectiveFLickr`的接口创建信号。上面的代码创建了一个信号对，一个用于获取收藏的数量，一个用于获取评论的数量。

一旦创建了两个信号，`combineLatest:reduce:`方法生成一个新的信号来组合两者。

这个方法等待源信号的一个`next`事件。`reduce`块使用它们的内容来调用，其结果变成联合信号的`next`事件。

简单明了吧！

不过在庆祝前，我们回到`signalFromAPIMethod:arguments:transform:`方法来修复之前提到的一个错误。你注意到了么？这个方法为每个请求创建一个新的`OFFlickrAPIRequest`实例。然后，每个请求的结果是通过代理对象来返回的，而这种情况下，其代理是它自己。结果是，在并发请求的情况下，没有办法指明哪个`flickrAPIRequest:didCompleteWithResponse:`调用用来响应哪个请求。不过，`ObjectiveFlickr`代理方法签名在第一个参数中包含了相应请求，所以这个问题很好解决。

在`signalFromAPIMethod:arguments:transform:`中，使用下面的代码来替换处理`successSignal`的管道：

``` objective-c
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
```

这只是简单地添加一个`filter`操作来移除任何与请求相关的代理方法调用，而不是生成当前的信号。

最后一步是在`ViewModel`层中使用信号。

打开`RWTSearchResultsViewModel.m`并导入以下头文件：

``` objective-c
#import "RWTFlickrPhoto.h"
```

在同一文件中的初始化的末尾添加以下代码：

``` objective-c
RWTFlickrPhoto *photo = results.photos.firstObject;
RACSignal *metaDataSignal = [[services getFlickrSearchService]
                            flickrImageMetadata:photo.identifier];
    [metaDataSignal subscribeNext:^(id x) {
     NSLog(@"%@", x);
   }];
```

这段代码测试了新添加的方法，该方法从返回的结果中的第一幅图片获取图片元数据。运行程序后，会在控制台输出以下信息：

``` objective-c
2014-06-04 07:27:26.813 RWTFlickrSearch[76828:70b] metadata: comments=120, faves=434
```

​	

## 获取可见cell的元数据

我们可以扩展当前代码来获取所有搜索结果的元数据。然而，如果我们有`100`条结果，则需要立即发起`200`个请求，每幅图片`2`个请求。大多数`API`都有些限制，这种调用方式会阻塞我们的请求调用，至少是临时的。

在一个`table`中，我们只需要获取当前显示的单元格所对象的结果的元数据。所以，如何实现这个行为呢？当然，我们需要一个`ViewModel`来表示这些数据。当前`RWTSearchResultsViewModel`暴露了一个绑定到`View`的`RWTFlickrPhoto`实例的数组，它们的暴露给`View`的`Model`层对象。为了添加这种可见性，我们将给`ViewModel`中的`model`对象添加`view-centric`状态。

在`ViewModel`分组中添加`RWTSearchResultsItemViewModel`类，打开头文件并各以下代码更新：

``` objective-c
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
```

看看初始化方法，这个`ViewModel`封装了一个`RWTFlickrPhoto`模型对象的实例。这个`ViewModel`包含以下几类属性：

1. 表示底层`Model`属性的属性`(title, url)`
2. 当获取到元数据时动态更新的属性`(favorites, comments)`
3. `isVisible`，用于表示`ViewModel`是否可见

打开`RWTSearchResultsItemViewModel.m`并导入以下头文件：

``` objective-c
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACEXTScope.h>
#import "RWTFlickrPhotoMetadata.h"
```

接下来添加几个私有属性：

``` objective-c
@interface RWTSearchResultsItemViewModel ()
 
@property (weak, nonatomic) id<RWTViewModelServices> services;
@property (strong, nonatomic) RWTFlickrPhoto *photo;
 
@end
```

然后实现初始化方法：

``` objective-c
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
```

这基于`Model`对象的`title`和`url`属性，然后通过私有属性来存储服务和图片的引用。

接下来添加`initialize`方法。准备好，这里有些有趣的事情会发生。

``` objective-c
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
```

这个方法的第一部分通过监听`isVisible`属性和过滤`true`值来创建一个名为`fetchMetadata`的信号。结果，信号在`isVisible`属性设置为`true`时发出`next`事件。第二部分订阅这个信号以初始化到`flickrImageMetadata`方法的请求。当这个嵌套的信号发送`next`事件时，`favorite`和`comment`属性使用这个结果来更新值。

总的来说，当`isVisible`设置为`true`时，发送`Flickr API`请求，并在将来某个时刻更新`comments`和`favorites`属性。

为了使用新的`ViewModel`，打开`RWTSearchResultsViewModel.m`并导入头文件：

``` objective-c
#import <LinqToObjectiveC/NSArray+LinqExtensions.h>
#import "RWTSearchResultsItemViewModel.h"
```

在初始化方法中，移除当前设置`_searchResults`的代码，并使用以下代码：

``` objective-c
_searchResults =
  [results.photos linq_select:^id(RWTFlickrPhoto *photo) {
    return [[RWTSearchResultsItemViewModel alloc]
              initWithPhoto:photo services:services];
  }];
```

这只是简单地使用一个`ViewModel`来包装每一个`Model`对象。

最后一步是通过视图来设置`isVisible`对象，并使用这些新的属性。

打开`RWTSearchResultsTableViewCell.m`并导入以下头文件：

``` objective-c
#import "RWTSearchResultsItemViewModel.h"
```

然后在下面的`bindViewModel`方法的第一行添加以下代码：

``` objective-c
RWTSearchResultsItemViewModel *photo = viewModel;
```

并在访方法中添加以下代码：

``` objective-c
[RACObserve(photo, favorites) subscribeNext:^(NSNumber *x) {
  self.favouritesLabel.text = [x stringValue];
  self.favouritesIcon.hidden = (x == nil);
}];
 
[RACObserve(photo, comments) subscribeNext:^(NSNumber *x) {
  self.commentsLabel.text = [x stringValue];
  self.commentsIcon.hidden = (x == nil);
}];
 
photo.isVisible = YES;
```

这个代码监听了新的`comments`和`favorites`属性，当它们更新`lable`和`image`时会更新。最后，`ModelView`的`isVisible`属性被设置成`YES`。`table view`绑定辅助类只绑定可见的单元格，所以只有少部分`ViewModel`去请求元数据。

运行后，以看到以下效果：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/06/WithMetadata-333x500.png)

是不是很酷？

## 节流

慢着，还有一个问题没有解决。当我们快速地滚动滑动栏，如果不做特殊，会同时加载大量的元数据和图片，这将明显地降低我们程序的性能。为了解决这个问题，程序应该只在照片显示在界面上的的时候去初始化元数据请求。现在`ViewModel`的`isVisible`属性被设置为`YES`，但不会被设置成`NO`。我们现在来处理这个问题。

打开`RWTSearchResultsTableViewCell.m`，然后修改刚才添加到`bindViewModel:`的代码，以设置`isVisible`属性：

``` objective-c
photo.isVisible = YES;
[self.rac_prepareForReuseSignal subscribeNext:^(id x) {
  photo.isVisible = NO;
}];
```

当`ViewModel`绑定到`View`时，`isVisible`属性会被设置成`YES`。但是当`cell`被移出`table view`进行重用时会被设置成`NO`。我们通过`rac_prepareForReuseSignal`信号来实现这步操作。

返回到`RWTSearchResultsItemViewModel`中。`ViewModel`需要监听`isVisible`属性的修改，当属性被设置成`YES`后一秒钟，将发送一个元数据的请求。

在`RWTSearchResultsItemViewModel.m`中，更新`initialize`方法，移除`fetchMetadata`信号的创建。使用以下代码来替换：

``` objective-c
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
```

你可以想像一下如果没有`ReactiveCocoa`，这会有多复杂。

运行程序，现在我们和滑动显示平滑多了。

## 错误处理

当前搜索`Flickr`的代码只处理了`OFFlickrAPIRequestDelegate`协议中的`flickrAPIRequest:didCompleteWithResponse:`方法。不过，这样网络请求由于多种原因会出错。一个好的应用程序必须处理这些错误，以给用户一个良好的用户体验。代理同时定义了`flickrAPIRequest:didFailWithError:`方法，这个方法在请求出错时调用。我们将用这个方法来处理错误并显示一个提示框给用户。

我们之前讲过信号会发出`next`，`completed`和错误事件。其结果是，我们并不需要做太多的事情。

打开`RWTFlickrSearchImpl.m`，并定位到`signalFromAPIMethod:arguments:transform:`方法。在这个方法中，在创建`successSignal`变量前添加以下代码：

``` objective-c
RACSignal *errorSignal =
  [self rac_signalForSelector:@selector(flickrAPIRequest:didFailWithError:)
                 fromProtocol:@protocol(OFFlickrAPIRequestDelegate)];
 
[errorSignal subscribeNext:^(RACTuple *tuple) {
  [subscriber sendError:tuple.second];
}];
```

上面的代码从代理方法中创建了一个信号，订阅了该信号，如果发生错误则发送一个错误。传递给`subscribeNext`块的元组包含传递给`flickrAPIRequest:didFailWithError:`方法的变量。结果是，`tuple.second`获取源错误并使用它来为错误事件服务。这是一个很好的解决方案，你觉得呢？不是所有的`API`请求都有内建的错误处理。接下来我们使用它。

`RWTFlickrSearchViewModel`不直接暴露信号给视图。相反它暴露一个状态和一个命令。我们需要扩展接口来提供错误报告。

打开`RWTFlickrSearchViewModel.h`并添加以下属性：

``` objective-c
@property (strong, nonatomic) RACSignal *connectionErrors;
```

打开`RWTFlickrSearchViewModel.m`并添加以下代码到`initialize`实现的最后：

``` objective-c
self.connectionErrors = self.executeSearch.errors;
```

`executeSearch`属性是一个`ReactiveCococa`框架的`RACCommand`对象。`RACCommand`类有一个`errors`属性，用于发送命令执行时产生的任何错误。

为了处理这些错误，打开`RWTFlickrSearchViewController.m`并添加以下的代码到`initWithViewModel:`方法中：

``` objective-c
[_viewModel.connectionErrors subscribeNext:^(NSError *error) {
  UIAlertView *alert =
  [[UIAlertView alloc] initWithTitle:@"Connection Error"
                             message:@"There was a problem reaching Flickr."
                            delegate:nil
                   cancelButtonTitle:@"OK"
                   otherButtonTitles:nil];
  [alert show];
}];
```

运行后，处理错误的效果如下：

![image](http://cdn2.raywenderlich.com/wp-content/uploads/2014/06/ErrorMessages-281x500.png)

想知道为什么获取收藏和评论的请求不报告错误么？这是由设计决定的，主要是这些不会影响程序的可用性。

## 添加最近搜索列表

用户可能会回去查看一些重复的图片。所以，我们可以做些简化操作。回想一下本文的开头，最后的程序在搜索输入框下面有一个显示最近搜索结果的列表。

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/06/FinishedApp-671x500.png)

现在我们只需要添加上这个功能，这次我要向你发起一个挑战了。我将这一部分的实现留给读者您来处理，来练习练习`MVVM`技能吧。

在开始之前，我在这些做些总结：

1. 我将创建一个`ViewModel`来表示每个先前的搜索，它包含一些属性，这些属性包括搜索文本，匹配的数量和第一个匹配的图片
2. 我将修改`RWTFlickrSearchViewModel`来暴露这些新的`ViewModel`对象的数组做为一个属性。
3. 使用`CETableViewBindingHelper`可以非常简单地渲染`ViewModel`的数组，我已经添加了一个合适的`cell(RWTRecentSearchItemTableViewCell`)到工程中。

## 接下来何去何从？

在[这里](https://github.com/ColinEberhardt/ReactiveFlickrSearch)可以下载最终的程序。这两部分的内容已经包含了很多内容，这里我们可以好好回顾一下主要点：

1. `MVVM`是`MVC`模式的一个变种，它正逐渐流行起来
2. `MVVM`模式让`View`层代码变得更清晰，更易于测试
3. 严格遵守`View=>ViewModel=>Model`这样一个引用层次，然后通过绑定来将`ViewModel`的更新反映到`View`层上。
4. `ViewModel`层决不应该维护`View`的引用
5. `ViewModel`层可以看作是视图的模型(`model-of-the-view`)，它暴露属性，以直接反映视图的状态，以及执行用户交互相关的命令。
6. `Model`层暴露服务。
7. 针对`MVVM`程序的测试可以在没有`UI`的情况下运行。
8. `ReactiveCocoa`框架提供强大的机制来将`ViewModel`绑定到`View`。它同时也广泛地使用在`ViewModel`和`Model`层中。

怎么样，下次创建程序的时候，是不是试试`MVVM`？试试吧。