---
layout: post
title: "ReactiveCocoa Tutorial – The Definitive Introduction: Part 2/2"
date: 2014-08-02 23:20:48 +0800
comments: true
categories: translate iOS
---

原文由`Colin Eberhardt`发表于`raywenderlich`，[ReactiveCocoa Tutorial – The Definitive Introduction: Part 2/2](http://www.raywenderlich.com/62796/reactivecocoa-tutorial-pt2)

[第一部分](http://southpeak.github.io/blog/2014/08/02/reactivecocoazhi-nan-%5B%3F%5D-:xin-hao/)我们学习了`ReactiveCocoa`处理信号的基本流程，如何发送流事件，以及分割及组合信号。在这一部分中，我们将继续学习`ReactiveCocoa`更多的特性，包括：

1. `error`和`completed`事件类型
2. 节流(`Throttling`)
3. 线程
4. 扩展

## Twitter Instant

本部分我们将要开发的是一个称为`Twitter Instant`的程序，这是一个`Twitter`搜索应用，用于裡更新搜索结果。可以在[这里](http://cdn5.raywenderlich.com/wp-content/uploads/2014/01/TwitterInstant-Starter2.zip)下载初始程序，同时我们需要通过`Cocoapods`来下载依赖库，这个过程与第一部分相同。完成之后，运行程序，将得到下面的界面：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/01/TwitterInstantStarter.png)

我们花点时间熟悉一下。这个程序很简单。左侧控制面板是`RWSearchFormViewController`，有一个搜索框。右侧是`RWSearchResultsViewController`。如果我们打开`RWSearchFormViewController.m`，我们可以看到`viewDidLoad`方法中指定了`resultsViewController`属性，这个程序的主要逻辑是在`RWSearchFormViewController`中，这个属性将搜索结果提供给`RWSearchResultsViewController`。

## 验证搜索框

首先我们来校验输入框的字符长度是否大于`2`。我们在`RWSearchFormViewController.m`的`viewDidLoad`方法下面添加以下代码：

``` objective-c
- (BOOL)isValidSearchText:(NSString *)text
{
    return text.length > 2;
}
```

接下来，我们在`RWSearchFormViewController.m`中导入`ReactiveCocoa`

``` objective-c
#import <ReactiveCocoa/ReactiveCocoa.h>
```

同时在viewDidLoad方法最后加上以下代码：

``` objective-c
[[self.searchText.rac_textSignal map:^id(NSString *text) {
    return [self isValidSearchText:text] ? [UIColor whiteColor] : [UIColor yellowColor];
}] subscribeNext:^(UIColor *color) {
    self.searchText.backgroundColor = color;
}];
```

这段代码通过信号来检测输入是否有效，并设置相应的输入框背影颜色值。运行后，可以看到如下效果：

![image](http://cdn3.raywenderlich.com/wp-content/uploads/2014/01/ValidatedTextField.png)

其管道流程图如下所示：

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/01/TextValidationPipeline.png)

`rac_textSignal`在每次输入时发出`next`事件，并包含当前输入框的文本。然后`map`操作将其转换为颜色值，最后`subscribeNext:`获取这个颜色值并用它来设置输入框的背景颜色。

在添加Twitter查找逻辑之前，我们先看看一些有趣的东西。

## 格式化管道代码

在调用信号的方法时，我们建议每个操作都新起一行，并排列所有的步骤。如下图所示，一个复杂的管道通过分行，看起来会更加清晰

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/01/PipelineFormatting.png)

## 内存管理

考虑下我们添加到`TwitterInstant`程序中的代码，想知道我们创建的管道是如何被保存的么？当然，因为它没有被指定给变量或属性，所以它没有增加引用计数，因此注定被销毁？`ReactiveCocoa`设计的目的之一是允许这样一种编程样式，即管道可以匿名创建。到目前为止，我们的管道都是这么处理的。为了支持这种模式，`ReactiveCocoa`维护了一个全局的信号集合。如果信号有一个或多个订阅者，它就是可用的。如果所有订阅者都被移除了，信号就被释放了。

剩下最后一个问题：如何取消对信号的订阅？在一个`completed`事件或`error`事件后，一个订阅者会自动将自己移除。手动移除可能通过**RACDisposable**来完成。`RACSignal`的所有订阅方法都返回一个`RACDisposable`实例，我们可以调用它的`dispose`方法来手动移除订阅者。如下代码所示：

``` objective-c
RACSignal *backgroundColorSignal =
    [self.searchText.rac_textSignal
     map:^id(NSString *text) {
         return [self isValidSearchText:text] ? [UIColor whiteColor] : [UIColor yellowColor];
     }];

RACDisposable *subscripion =
    [backgroundColorSignal subscribeNext:^(UIColor *color) {
        self.searchText.backgroundColor = color;
    }];

// 在某个位置调用
[subscripion dispose];
```

当然实际上我们不需要这样来写，只需要知道是这么回事就行。

*注意：如果我们创建了一个管道，但不去订阅它，则管理永远不会执行，包括任何如doNext:块这样的附加操作。*



## 避免循环引用

`ReactiveCocoa`在幕后做了许多事情，让我们不需要担心信号的内存管理问题，但有一点关于内存管理的问题需要特别注意。我们先来看看下面的代码：

``` objective-c
[[self.searchText.rac_textSignal map:^id(NSString *text) {
    return [self isValidSearchText:text] ? [UIColor whiteColor] : [UIColor yellowColor];
}] subscribeNext:^(UIColor *color) {
    self.searchText.backgroundColor = color;
}];
```

`subscribeNext:`块使用了`self`，以获取文本输入域。`Block`会捕获并保留闭包中的值，因此如果在`self`与信号之间有一个强引用，则会导致循环引用问题。这是不是问题取决于`self`对象的生命周期。如果`self`的生命周期是整个程序生存期，则没问题，好好用吧。但在大多数情况下，它确实是一个问题。

为了避循环引用，根据苹果的文档中推荐的捕获`self`的一个弱引用。如下代码所示：

``` objective-c
__typeof(self) __weak weakSelf = self;

[[self.searchText.rac_textSignal map:^id(NSString *text) {
    return [weakSelf isValidSearchText:text] ? [UIColor whiteColor] : [UIColor yellowColor];
}] subscribeNext:^(UIColor *color) {
    weakSelf.searchText.backgroundColor = color;
}];
```

在上面的代码中`weakSelf`是`self`对象的一个弱引用。现在`subscribeNext:`中使用了这个变量。不过`ReactiveCocoa`框架给我们提供了一个更好的选择。首先导入以下头文件：

``` objective-c
#import <RACEXTScope.h>
```

然后使用以下代码：

``` objective-c
@weakify(self)

[[self.searchText.rac_textSignal map:^id(NSString *text) {
    return [self isValidSearchText:text] ? [UIColor whiteColor] : [UIColor yellowColor];
}] subscribeNext:^(UIColor *color) {
    @strongify(self)
    self.searchText.backgroundColor = color;
}];
```

宏`@weakify`与`@strongify`在[Extended Objective-C](https://github.com/jspahrsummers/libextobjc)库中引用，它们包含在`ReactiveCocoa`框架中。`@weakify`允许我们创建一些影子变量，它是都是弱引用(可以同时创建多个)，`@strongify`允许创建变量的强引用，这些变量是先前传递给`@weakify`的。

最后需要注意的是，当在`block`中使用实例变量时，`block`同样会捕获`self`的一个强引用。我们可以打开编译器警告，来提示我们这种情况。如下所求来处理

![image](http://cdn3.raywenderlich.com/wp-content/uploads/2014/01/AvoidRetainSelf.png)

OK，内存问题说得差不多了，现在我们回到正题。

## 请求访问Twitter

我们将使用`Social Framework`以允许`TwitterInstant`程序搜索`Tweets`，同时使用`Accounts Framework`来获取对`Twitter`的访问。

在添加代码前，我们需要先登录`Twitter`。可以在系统的设置中登录，如下图所示：

![image](http://cdn3.raywenderlich.com/wp-content/uploads/2014/01/TwitterCredentials.png)

我们的工程已经添加了所需要的框架，所以只需要在`RWSearchFormViewController.m`导入头文件。

``` objective-c
#import <Accounts/Accounts.h>
#import <Social/Social.h>
```

然后在下面添加枚举及常量用于标识错误：

``` objective-c
typedef NS_ENUM(NSInteger, RWTwitterInstantError) {
    RWTwitterInstantErrorAccessDenied,
    RWTwitterInstantErrorNoTwitterAccounts,
    RWTwitterInstantErrorInvalidResponse
};

static NSString * const RWTwitterInstantDomain = @"TwitterInstant";
```

然后我们`RWSearchFormViewController()`分类中添加以下代码：

``` objective-c
@property (strong, nonatomic) ACAccountStore *accountStore;
@property (strong, nonatomic) ACAccountType *twitterAccountType;
```

`ACAccountsStore`类提供了我们的设备可连接的多种社交账号，`ACAccountType`类表示账号的指定类型。

我们在`viewDidLoad`的结尾处添加以下代码，来创建账户存储及`Twitter`账户标识：

``` objective-c
self.accountStore = [[ACAccountStore alloc] init];
self.twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
```

当账户请求社账号时，用户可以看到一个弹出框。这是一个异步操作，所以将其包装到一个信号中是很好的选择。

仍然在这个文件中，添加以下代码：

``` objective-c
- (RACSignal *)requestAccessToTwitterSignal
{
    // 定义一个错误，如果用户拒绝访问则发送
    NSError *accessError = [NSError errorWithDomain:RWTwitterInstantDomain code:RWTwitterInstantErrorAccessDenied userInfo:nil];
    
    // 创建并返回信号
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        // 请求访问twitter
        @strongify(self)
        [self.accountStore requestAccessToAccountsWithType:self.twitterAccountType
                                                   options:nil
                                                completion:^(BOOL granted, NSError *error) {
                                                    // 处理响应
                                                    if (!granted)
                                                    {
                                                        [subscriber sendError:accessError];
                                                    }
                                                    else
                                                    {
                                                        [subscriber sendNext:nil];
                                                        [subscriber sendCompleted];
                                                    }
                                                }];
        return nil;
    }];
}
```

一个信号可以发送三种事件类型：`next`, `completed`, `error`。

在信号的整个生命周期中，都可能不会发送事件，或者发送一个或多个`next`事件，其后跟着`completed`或`error`事件。

最后，为了使用这个信号，在`viewDidLoad`中添加以下代码：

``` objective-c
[[self requestAccessToTwitterSignal]
 subscribeNext:^(id x) {
     NSLog(@"Access granted");
 } error:^(NSError *error) {
     NSLog(@"An error occurred: %@", error);
 }];
```

运行程序，可以看到下面的提示

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/01/RequestAccessToTwitter.png)

如果点击OK，`subscribeNext:`块中的日志会打印出来。如果点击`Don't allow`，则会执行错误块并打印期望的信息。

## 链接信号

一旦用户获取了`Twitter`账户的访问权限，程序需要继续监听搜索框的输入，以查询`twitter`。程序需要等待请求访问`Twitter`的信号来发出完成事件，然后订阅广西输入框的信号。不同信号的顺序链接是一个问题，但`ReactiveCocoa`已经做了很好的处理。

在`viewDidLoad`中用下面代码来替换当前的管道：

``` objective-c
[[[self requestAccessToTwitterSignal]
 then:^RACSignal *{
     @strongify(self)
     return self.searchText.rac_textSignal;
 }]
 subscribeNext:^(id x) {
     NSLog(@"%@", x);
 } error:^(NSError *error) {
     NSLog(@"An error occurred: %@", error);
 }];
```

`then`方法会等到`completed`事件发出后调用，然后订阅由`block`参数返回的信号。这有效地将控制从一个信号传递给下一个信号。运行程序，获取访问，然后在输入框输入，会在控制台看到以下输出：

``` objective-c
2014-01-04 08:16:11.444 TwitterInstant[39118:a0b] m
2014-01-04 08:16:12.276 TwitterInstant[39118:a0b] ma
2014-01-04 08:16:12.413 TwitterInstant[39118:a0b] mag
2014-01-04 08:16:12.548 TwitterInstant[39118:a0b] magi
2014-01-04 08:16:12.628 TwitterInstant[39118:a0b] magic
2014-01-04 08:16:13.172 TwitterInstant[39118:a0b] magic!
```

下一步，我们添加一个`filter`操作到管道，以移除无效的搜索字符串。在这个实例中，是要求输入长度不小于`3`：

``` objective-c
[[[[self requestAccessToTwitterSignal]
 then:^RACSignal *{
     @strongify(self)
     return self.searchText.rac_textSignal;
 }]
 filter:^BOOL(NSString *text) {
     @strongify(self)
     return [self isValidSearchText:text];
 }]
 subscribeNext:^(id x) {
     NSLog(@"%@", x);
 } error:^(NSError *error) {
     NSLog(@"An error occurred: %@", error);
 }];
```

运行后的输出是

``` objective-c
2014-01-04 08:16:12.548 TwitterInstant[39118:a0b] magi
2014-01-04 08:16:12.628 TwitterInstant[39118:a0b] magic
2014-01-04 08:16:13.172 TwitterInstant[39118:a0b] magic!
```

当前管道如下图所示：

![image](http://cdn3.raywenderlich.com/wp-content/uploads/2014/01/PipelineWithThen.png)

现在我们有一个发送搜索文本的信号了，是时候用它来搜索`Twitter`了。接下来才是正题。

## 搜索Twitter

`Social Framework`是访问`Twitter`搜索`API`的一个选择。但是`Social Framework`不是响应式的。接下来是封装所需要的`API`方法到信号中。现在，我们需要挂起这个过程。

在`RWSearchFormViewController.m`中，添加以下方法：

``` objective-c
- (SLRequest *)requestforTwitterSearchWithText:(NSString *)text
{
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
    NSDictionary *params = @{@"q": text};
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                            requestMethod:SLRequestMethodGET
                                                      URL:url
                                               parameters:params];
    return request;
}
```

这个方法通过[v1.1 REST API](https://dev.twitter.com/docs/api/1.1)创建了一个搜索`Twitter`的请求。关于这个`API`，可以在[Twitter API docs](https://dev.twitter.com/docs/api/1.1/get/search/tweets)中查看更多信息。

接下来创建一个基于请求的信号。在同一文件中，添加以下代码：

``` objective-c
- (RACSignal *)signalForSearchWithText:(NSString *)text {
    // 定义错误
    NSError *noAccountError = [NSError errorWithDomain:RWTwitterInstantDomain code:RWTwitterInstantErrorNoTwitterAccounts userInfo:nil];
    
    NSError *invalidResponseError = [NSError errorWithDomain:RWTwitterInstantDomain code:RWTwitterInstantErrorInvalidResponse userInfo:nil];
    
    // 创建信号block
    @weakify(self)
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self)
        
        // 创建请求
        SLRequest *request = [self requestforTwitterSearchWithText:text];
        
        // 提供Twitter账户
        NSArray *twitterAccounts = [self.accountStore accountsWithAccountType:self.twitterAccountType];
        if (twitterAccounts.count == 0) {
            [subscriber sendError:noAccountError];
        } else {
            [request setAccount:[twitterAccounts lastObject]];
            
            // 执行请求
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if (urlResponse.statusCode == 200) {
                    // 成功，解析响应
                    NSDictionary *timelineData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
                    [subscriber sendNext:timelineData];
                    [subscriber sendCompleted];
                } else {
                    // 失败，发送一个错误
                    [subscriber sendError:invalidResponseError];
                }
            }];
        }
        
        return nil;
    }];
}
```

现在我们来使用这个新信号。

在第一部分中我们学习了如何使用`flattenMap`来将每个`next`事件映射到一个新的被订阅的信号。这里我们再次使用它们。在`viewDidLoad`的最后用如下代码更新：

``` objective-c
[[[[[self requestAccessToTwitterSignal]
 then:^RACSignal *{
     @strongify(self)
     return self.searchText.rac_textSignal;
 }]
 filter:^BOOL(NSString *text) {
     @strongify(self)
     return [self isValidSearchText:text];
 }]
 flattenMap:^RACStream *(NSString *text ) {
     @strongify(self)
     return [self signalForSearchWithText:text];
 }]
 subscribeNext:^(id x) {
     NSLog(@"%@", x);
 } error:^(NSError *error) {
     NSLog(@"An error occurred: %@", error);
 }];
```

运行并在搜索框中输入一些文本。一旦文本字符串长度大于`3`后，我们可以在控制台查看搜索的结果。如下显示了返回数据的一个片断：

``` objective-c
2014-01-05 07:42:27.697 TwitterInstant[40308:5403] {
    "search_metadata" =     {
        "completed_in" = "0.019";
        count = 15;
        "max_id" = 419735546840117248;
        "max_id_str" = 419735546840117248;
        "next_results" = "?max_id=419734921599787007&q=asd&include_entities=1";
        query = asd;
        "refresh_url" = "?since_id=419735546840117248&q=asd&include_entities=1";
        "since_id" = 0;
        "since_id_str" = 0;
    };
    statuses =     (
                {
            contributors = "<null>";
            coordinates = "<null>";
            "created_at" = "Sun Jan 05 07:42:07 +0000 2014";
            entities =             {
                hashtags = ...
```

`signalForSearchText:`方法同样发出了一个`error`事件，其由`subscribeNext:error:`块来处理。

## 线程

现在一定想把返回的`JSON`数据显示到`UI`上了吧，不过，在此之前我们还有一件事情需要处理。要了解这是什么，我们还需要探索一下。

在下图的`subscribeNext:error:`中打个断点：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/01/BreakpointLocation.png)

重新运行程序，如果需要则再次输入`Twitter`账号密码，在搜索框中输入一些文本。当程序运行到断点位置时可以看到类似于下图的场景：

![image](http://cdn5.raywenderlich.com/wp-content/uploads/2014/01/BreakpointResult.png)

注意，从左侧的线程列表中我们可以看到`debugger`到的代码并没有运行在主线程，即线程`Thread 1`。记住，更新`UI`的操作一定得在主线程中操作；因此，如果要在`UI`上显示`tweet`列表，则必须切换线程。

这说明了`ReactiveCocoa`框架的一个重要点。上面显示的操作是在信号初始发出事件时的那个线程执行。尝试在管道的其它步骤添加断点，我们会很惊奇的发现它们会运行在多个不同的线程上。

因此，我们应该如何来更新UI呢？当然`ReactiveCocoa`也为我们解决了这个问题。我们只需要在`flattenMap:`后面添加`deliverOn:`操作：

``` objective-c
[[[[[[self requestAccessToTwitterSignal]
 then:^RACSignal *{
     @strongify(self)
     return self.searchText.rac_textSignal;
 }]
 filter:^BOOL(NSString *text) {
     @strongify(self)
     return [self isValidSearchText:text];
 }] flattenMap:^RACStream *(NSString *text) {
     @strongify(self)
     return [self signalForSearchWithText:text];
 }]
 deliverOn:[RACScheduler mainThreadScheduler]]
 subscribeNext:^(id x) {
     NSLog(@"%@", x);
 } error:^(NSError *error) {
     NSLog(@"An error occurred: %@", error);
 }];
```

现在重新运行，此时我们可以看到`subscribeNext:error:`是运行在主线程了。

![image](http://cdn3.raywenderlich.com/wp-content/uploads/2014/01/BreakpointNowOnUIThread.png)

这样我们就可以安全地更新我们的UI了。

## 更新UI

打开`RWSearchResultsViewController.h`文件，我们可以看到`displayTweets:`方法，这个方法会让右侧的`ViewController`来渲染`tweet`数组。实现非常简单，它只是一个标准`UITableView`数据源。`displayTweets:`只需要一个包含`RWTweet`实例的数组作为参数。我们同样发现`RWTweet`实例是作为初始工程的一部分提供的。

在`subscibeNext:error:`步骤中获取到的数据现在是一个`NSDictionary`，它是在`signalForSearchWithText:`解析`JSON`数据时构造的。那么，我们如何处理这个字典的内容呢？

如果看一看[Twitter API documentation](https://dev.twitter.com/docs/api/1.1/get/search/tweets)，我们可以发现一个示例响应。在`NSDictionary`反映了这种结构，所以我们需要找到一个键名为`statues`的字典，其值为一个`tweets`数组。具体如何解析我们就不在此说明。这里给个更好的实现方式。

我们现在讲的是`ReactiveCocoa`及函数式编程。当我们使用函数式`API`时，数据从一种格式转换到另一种格式会变得更优雅。我们可以使用[LinqToObjectiveC](https://github.com/ColinEberhardt/LinqToObjectiveC)来执行这个任务。

我们需要使用`Cocoapods`来导入`LinqToObjectiveC`。在配置文件中加入以下代码：

``` objective-c
pod 'LinqToObjectiveC', '2.0.0'
```

关闭工程，在终端执行`pod update`命令，完成后在我们的`Pods`工程中就可以看到`LinqToObjectiveC`了。

打开`RWSearchFormViewController.m`并导入以下文件：

``` objective-c
#import "RWTweet.h"
#import "NSArray+LinqExtensions.h"
```

`NSArray+LinqExtensions.h`头文件来自于`LinqToObjectiveC`，并为`NSArray`添加了许多方法以允许我们使用一个流畅的`API`来转换、排序、分组及过滤数组的数据。

现在我们使用这些`API`来更新当前管道操作，在`viewDidLoad`代码中做如下修改：

``` objective-c
[[[[[[self requestAccessToTwitterSignal]
     then:^RACSignal *{
         @strongify(self)
         return self.searchText.rac_textSignal;
     }]
    filter:^BOOL(NSString *text) {
        @strongify(self)
        return [self isValidSearchText:text];
    }]
   flattenMap:^RACStream *(NSString *text) {
       @strongify(self)
       return [self signalForSearchWithText:text];
   }]
  deliverOn:[RACScheduler mainThreadScheduler]]
 subscribeNext:^(NSDictionary *jsonSearchResult) {
     NSArray *statuses = jsonSearchResult[@"statuses"];
     NSArray *tweets = [statuses linq_select:^id(id tweet) {
         return [RWTweet tweetWithStatus:tweet];
     }];
     [self.resultsViewController displayTweets:tweets];
 } error:^(NSError *error) {
     NSLog(@"An error occurred: %@", error);
 }];
```

如上所看到的，`subscribeNext:`块首先获取`tweets`的`NSArray`对象。`linq_select`方法通过执行应用于每个数组元素的`block`来转换`NSDictionary`字典的数组，并生成一个`RWTweet`实例的数组。

一旦转换完成，`tweets`将结果发送给`ViewController`。

运行程序后我们可以看到以下`UI`：

![image](http://cdn4.raywenderlich.com/wp-content/uploads/2014/01/FinallyWeSeeTweets.png)

## 异步加载图片

在上图中，我们可以看到每行数据前面有一片空白，这是用来显示用户头像的。`RWTweet`类已经有一个`profileImageUrl`属性，它是一个图片的`URL`地址。为了让`UITableTable`滑动得更平滑，我们需要让获取指定`URL`的图片的操作不运行在主线程中。这可以使用`GCD`或者是`NSOperationQueue`。不过，`ReactiveCocoa`同样为我们提供了解决方案。

打开`RWSearchResultsViewController.m`，添加以下代码：

``` objective-c
-(RACSignal *)signalForLoadingImage:(NSString *)imageUrl {
    
    RACScheduler *scheduler = [RACScheduler
                               schedulerWithPriority:RACSchedulerPriorityBackground];
    
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageUrl]];
        UIImage *image = [UIImage imageWithData:data];
        [subscriber sendNext:image];
        [subscriber sendCompleted];
        return nil;
    }] subscribeOn:scheduler];
    
}
```

现在我们应该熟悉这种模式了。以上的方法首先获取一个后台`scheduler`作为信号执行的线程，而不是主线程。接下来，创建一个下载图片数据的信号并在其有订阅者时创建一个`UIImage`。最后我们调用`subscribeOn:`，以确保信号在给定的`scheduler`上执行。

现在，我们可以更新`tableView:cellForRowAtIndex:`，在`return`之前添加以下代码：

``` objective-c
cell.twitterAvatarView.image = nil;
 
[[[self signalForLoadingImage:tweet.profileImageUrl]
  deliverOn:[RACScheduler mainThreadScheduler]]
  subscribeNext:^(UIImage *image) {
   cell.twitterAvatarView.image = image;
  }];
```

上面的代码首先重新设置图片，因为重用的单元格可能包含之前的数据。然后创建一个请求信号去获取数据，在`deliverOn:`中我们将后面的`next`事件运行在主线程，这样`subscribeNext:`可以安全运行。

运行后得到如下结果：

![image](http://cdn1.raywenderlich.com/wp-content/uploads/2014/01/AvatarsAtAlast.png)

## 节流

你可能已经发现每次我们输入一个新的字符时，搜索操作都会立即执行。如果我们快速输入，可能会导致程序在一秒钟内执行了多次搜索操作。这当然是不好的，因为：

1. 我们多次调用了`Twitter`搜索`API`，同时扔掉了大部分结果。
2. 我们不断更新结果会分散用户的注意力。

一个更好的方案是如果搜索文本在一个较短时间内没有改变时我们再去执行搜索操作，如`500`毫秒。`ReactiveCocoa`框架让这一任务变得相当简单。

打开`RWSearchFormViewController.m`并更新管道操作：

``` objective-c
[[[[[[[self requestAccessToTwitterSignal]
      then:^RACSignal *{
          @strongify(self)
          return self.searchText.rac_textSignal;
      }]
     filter:^BOOL(NSString *text) {
         @strongify(self)
         return [self isValidSearchText:text];
     }]
    throttle:0.5]
   flattenMap:^RACStream *(NSString *text) {
       @strongify(self)
       return [self signalForSearchWithText:text];
   }]
  deliverOn:[RACScheduler mainThreadScheduler]]
 subscribeNext:^(NSDictionary *jsonSearchResult) {
     NSArray *statuses = jsonSearchResult[@"statuses"];
     NSArray *tweets = [statuses linq_select:^id(id tweet) {
         return [RWTweet tweetWithStatus:tweet];
     }];
     [self.resultsViewController displayTweets:tweets];
 } error:^(NSError *error) {
     NSLog(@"An error occurred: %@", error);
 }];
```

`throttle`操作只有在两次`next`事件间隔指定的时间时才会发送第二个`next`事件。相当简单吧。运行程序看看效果吧。    

## 小结

在庆祝胜利前，看看程序最终的管道是值得的。

![image](http://cdn2.raywenderlich.com/wp-content/uploads/2014/01/CompletePipeline.png)

这是一个相当复杂的数据流，但可以作为一个响应管道简洁地表示出来。看起来不错吧。如果使用非响应式技术，你会觉得这会有多复杂呢？在这样一个程序中，数据流的流动又会是多难以理解呢？听起来很麻烦吧。但有了`ReactiveCocoa`，我们不必再考虑这些了。现在我们知道`ReactiveCocoa`有多棒了吧。

最后，`ReactiveCocoa`让使用`Model View ViewModel(MVVM)`设计模式变成可能。如果有兴趣研究`MVVM`，可以去网上搜索相关的文章。