---

layout: post

title: "NSNotificationCenter"

date: 2015-03-20 17:45:28 +0800

comments: true

categories: iOS

---

一个NSNotificationCenter对象(通知中心)提供了在程序中广播消息的机制，它实质上就是一个通知分发表。这个分发表负责维护为各个通知注册的观察者，并在通知到达时，去查找相应的观察者，将通知转发给他们进行处理。

本文主要了整理了一下NSNotificationCenter的使用及需要注意的一些问题，并提出了一些未解决的问题，希望能在此得到解答。

## 获取通知中心

每个程序都会有一个默认的通知中心。为此，NSNotificationCenter提供了一个类方法来获取这个通知中心：

	+ (NSNotificationCenter *)defaultCenter
	
获取了这个默认的通知中心对象后，我们就可以使用它来处理通知相关的操作了，包括注册观察者，移除观察者、发送通知等。

通常如果不是出于必要，我们一般都使用这个默认的通知中心，而不自己创建维护一个通知中心。

## 添加观察者

如果想让对象监听某个通知，则需要在通知中心中将这个对象注册为通知的观察者。早先，NSNotificationCenter提供了以下方法来添加观察者：

	- (void)addObserver:(id)notificationObserver
	           selector:(SEL)notificationSelector
	               name:(NSString *)notificationName
	             object:(id)notificationSender
	                        
这个方法带有4个参数，分别指定了通知的观察者、处理通知的回调、通知名及通知的发送对象。这里需要注意几个问题：

1. notificationObserver不能为nil。
2. notificationSelector回调方法有且只有一个参数(NSNotification对象)。
3. 如果notificationName为nil，则会接收所有的通知(如果notificationSender不为空，则接收所有来自于notificationSender的所有通知)。如代码清单1所示。
4. 如果notificationSender为nil，则会接收所有notificationName定义的通知；否则，接收由notificationSender发送的通知。
5. 监听同一条通知的多个观察者，在通知到达时，它们执行回调的顺序是不确定的，所以我们不能去假设操作的执行会按照添加观察者的顺序来执行。

对于以上几点，我们来重点关注一下第3条。以下代码演示了当我们的notificationName设置为nil时，通知的监听情况。

**代码清单1：添加一个Observer，其中notificationName为nil**

	@implementation ViewController
	
	- (void)viewDidLoad {
	    [super viewDidLoad];
	    
	    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:nil object:nil];
	    
	    [[NSNotificationCenter defaultCenter] postNotificationName:TEST_NOTIFICATION object:nil];
	}
	
	- (void)handleNotification:(NSNotification *)notification
	{
	    NSLog(@"notification = %@", notification.name);
	}
	
	@end

运行后的输出结果如下：

	notification = TestNotification
	notification = UIWindowDidBecomeVisibleNotification
	notification = UIWindowDidBecomeKeyNotification
	notification = UIApplicationDidFinishLaunchingNotification
	notification = _UIWindowContentWillRotateNotification
	notification = _UIApplicationWillAddDeactivationReasonNotification
	notification = _UIApplicationDidRemoveDeactivationReasonNotification
	notification = UIDeviceOrientationDidChangeNotification
	notification = _UIApplicationDidRemoveDeactivationReasonNotification
	notification = UIApplicationDidBecomeActiveNotification

可以看出，我们的对象基本上监听了测试程序启动后的所示消息。当然，我们很少会去这么做。

而对于第4条，使用得比较多的场景是监听UITextField的修改事件，通常我们在一个ViewController中，只希望去监听当前视图中的UITextField修改事件，而不希望监听所有UITextField的修改事件，这时我们就可以将当前页面的UITextField对象指定为notificationSender。

在iOS 4.0之后，NSNotificationCenter为了跟上时代，又提供了一个以block方式实现的添加观察者的方法，如下所示：

	- (id<NSObject>)addObserverForName:(NSString *)name
	                            object:(id)obj
	                             queue:(NSOperationQueue *)queue
	                        usingBlock:(void (^)(NSNotification *note))block
	                        
大家第一次看到这个方法时是否会有这样的疑问：观察者呢？参数中并没有指定具体的观察者，那谁是观察者呢？实际上，与前一个方法不同的是，前者使用一个现存的对象作为观察者，而这个方法会创建一个匿名的对象作为观察者(即方法返回的id\<NSObject\>对象)，这个匿名对象会在指定的队列(queue)上去执行我们的block。

这个方法的优点在于添加观察者的操作与回调处理操作的代码更加紧凑，不需要拼命滚动鼠标就能直接找到处理代码，简单直观。这个方法也有几个地方需要注意：

1. name和obj为nil时的情形与前面一个方法是相同的。
2. 如果queue为nil，则消息是默认在post线程中同步处理，即通知的post与转发是在同一线程中；但如果我们指定了操作队列，情况就变得有点意思了，我们一会再讲。
3. block块会被通知中心拷贝一份(执行copy操作)，以在堆中维护一个block对象，直到观察者被从通知中心中移除。所以，应该特别注意在block中使用外部对象，避免出现对象的循环引用，这个我们在下面将举例说明。
4. 如果一个给定的通知触发了多个观察者的block操作，则这些操作会在各自的Operation Queue中被并发执行。所以我们不能去假设操作的执行会按照添加观察者的顺序来执行。
5. 该方法会返回一个表示观察者的对象，记得在不用时释放这个对象。

下面我们重点说明一下第2点和第3点。

关于第2点，当我们指定一个Operation Queue时，不管通知是在哪个线程中post的，都会在Operation Queue所属的线程中进行转发，如代码清单2所示：

**代码清单2：在指定队列中接收通知**

	@implementation ViewController
	
	- (void)viewDidLoad {
	    [super viewDidLoad];
	    
	    [[NSNotificationCenter defaultCenter] addObserverForName:TEST_NOTIFICATION object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
	        
	        NSLog(@"receive thread = %@", [NSThread currentThread]);
	    }];
	    
	    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	        
	        NSLog(@"post thread = %@", [NSThread currentThread]);
	        [[NSNotificationCenter defaultCenter] postNotificationName:TEST_NOTIFICATION object:nil];
	    });
	}
	
	@end
	
在这里，我们在主线程里添加了一个观察者，并指定在主线程队列中去接收处理这个通知。然后我们在一个全局队列中post了一个通知。我们来看下输出结果：

	post thread = <NSThread: 0x7ffe0351f5f0>{number = 2, name = (null)}
	receive thread = <NSThread: 0x7ffe03508b30>{number = 1, name = main}
	
可以看到，消息的post与接收处理并不是在同一个线程中。如上面所提到的，如果queue为nil，则消息是默认在post线程中同步处理，大家可以试一下。

对于第3点，由于使用的是block，所以需要注意的就是避免引起循环引用的问题，如代码清单3所示：

**代码清单3：block引发的循环引用问题**

	@interface Observer : NSObject
	
	@property (nonatomic, assign) NSInteger i;
	@property (nonatomic, weak) id<NSObject> observer;
	
	@end
	
	@implementation Observer
	
	- (instancetype)init
	{
	    self = [super init];
	    
	    if (self)
	    {
	        NSLog(@"Init Observer");
	        
	        // 添加观察者
	        _observer =  [[NSNotificationCenter defaultCenter] addObserverForName:TEST_NOTIFICATION object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
	            
	            NSLog(@"handle notification");
	            
	            // 使用self
	            self.i = 10;
	        }];
	    }
	    
	    return self;
	}
	
	@end
	
	#pragma mark - ViewController
	
	@implementation ViewController
	
	- (void)viewDidLoad {
	    [super viewDidLoad];
	    
	    [self createObserver];
	    
	    // 发送消息
	    [[NSNotificationCenter defaultCenter] postNotificationName:TEST_NOTIFICATION object:nil];
	}
	
	- (void)createObserver {
	    
	    Observer *observer = [[Observer alloc] init];
	}
	
	@end
	
运行后的输出如下：

	Init Observer
	handle notification
	
我们可以看到createObserver中创建的observer并没有被释放。所以，使用
- addObserverForName:object:queue:usingBlock:一定要注意这个问题。

## 移除观察者

与注册观察者相对应的，NSNotificationCenter为我们提供了两个移除观察者的方法。它们的定义如下：

	- (void)removeObserver:(id)notificationObserver
	
	- (void)removeObserver:(id)notificationObserver name:(NSString *)notificationName object:(id)notificationSender
	
前一个方法会将notificationObserver从通知中心中移除，这样notificationObserver就无法再监听任何消息。而后一个会根据三个参数来移除相应的观察者。

这两个方法也有几点需要注意：

1. 由于注册观察者时(不管是哪个方法)，通知中心会维护一个观察者的弱引用，所以在释放对象时，要确保移除对象所有监听的通知。否则，可能会导致程序崩溃或一些莫名其妙的问题。
2. 对于第二个方法，如果notificationName为nil，则会移除所有匹配notificationObserver和notificationSender的通知，同理notificationSender也是一样的。而如果notificationName和notificationSender都为nil，则其效果就与第一个方法是一样的了。大家可以试一下。
3. 最有趣的应该是这两个方法的使用时机。–removeObserver:适合于在类的dealloc方法中调用，这样可以确保将对象从通知中心中清除；而在viewWillDisappear:这样的方法中，则适合于使用-removeObserver:name:object:方法，以避免不知情的情况下移除了不应该移除的通知观察者。例如，假设我们的ViewController继承自一个类库的某个ViewController类(假设为SKViewController吧)，可能SKViewController自身也监听了某些通知以执行特定的操作，但我们使用时并不知道。如果直接在viewWillDisappear:中调用–removeObserver:，则也会把父类监听的通知也给移除。
	                        
关于注册监听者，还有一个需要注意的问题是，每次调用addObserver时，都会在通知中心重新注册一次，即使是同一对象监听同一个消息，而不是去覆盖原来的监听。这样，当通知中心转发某一消息时，如果同一对象多次注册了这个通知的观察者，则会收到多个通知，如代码清单4所示：

**代码清单4：同一对象多次注册同一消息**

	@implementation ViewController
	
	- (void)viewDidLoad {
	    [super viewDidLoad];
	    
	    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:TEST_NOTIFICATION object:nil];
	    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:TEST_NOTIFICATION object:nil];
	    
	    [[NSNotificationCenter defaultCenter] postNotificationName:TEST_NOTIFICATION object:nil];
	}
	
	- (void)handleNotification:(NSNotification *)notification
	{
	    NSLog(@"notification = %@", notification.name);
	}
	
	@end
	
其输出结果如下所示：

	notification = TestNotification
	notification = TestNotification
	
可以看到对象处理了两次通知。所以，如果我们需要在viewWillAppear监听一个通知时，一定要记得在对应的viewWillDisappear里面将观察者移除，否则就可能会出现上面的情况。

**最后，再特别重点强调的非常重要的一点是，在释放对象前，一定要记住如果它监听了通知，一定要将它从通知中心移除。如果是用
- addObserverForName:object:queue:usingBlock:，也记得一定得移除这个匿名观察者。说白了就一句话，添加和移除要配对出现。**

## post消息

注册了通知观察者，我们便可以随时随地的去post一个通知了(当然，如果闲着没事，也可以不注册观察者，post通知随便玩，只是没人理睬罢了)。NSNotificationCenter提供了三个方法来post一个通知，如下所示：


	- postNotification:
	– postNotificationName:object:
	– postNotificationName:object:userInfo:

我们可以根据需要指定通知的发送者(object)并附带一些与通知相关的信息(userInfo)，当然这些发送者和userInfo可以封装在一个NSNotification对象中，由- postNotification:来发送。注意，- postNotification:的参数不能为空，否则会引发一个异常，如下所示：

	*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '*** -[NSNotificationCenter postNotification:]: notification is nil'

每次post一个通知时，通知中心都会去遍历一下它的分发表，然后将通知转发给相应的观察者。

另外，通知的发送与处理是同步的，在某个地方post一个消息时，会等到所有观察者对象执行完处理操作后，才回到post的地方，继续执行后面的代码。如代码清单5所示：

**代码清单5：通知的同步处理**

	@implementation ViewController
	
	- (void)viewDidLoad {
	    [super viewDidLoad];
	    
	    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:TEST_NOTIFICATION object:nil];
	    
	    [[NSNotificationCenter defaultCenter] postNotificationName:TEST_NOTIFICATION object:nil];
	    
	    NSLog(@"continue");
	}
	
	- (void)handleNotification:(NSNotification *)notification
	{
	    NSLog(@"handle notification");
	}
	
	@end
	
运行后输出结果是：

	handle notification
	continue

## 一些思考

翻了好些资料，还有两个问题始终没有明确的答案。

首先就是通知中心是如何维护观察者对象的。可以明确的是，添加观察者时，通知中心没有对观察者做retain操作，即不会使观察者的引用计数加1。那通知中心维护的是观察者的weak引用呢还是unsafe_unretained引用呢？

个人认为可能是unsafe_unretained的引用，因为我们知道如果是weak引用，其所指的对象被释放后，这个引用会被置成nil。而实际情况是通知中心还会给这个对象发送消息，并引发一个异常。而如果向nil发送一个消息是不会导致异常的。

另外，我们知道NSNotificationCenter实现的是观察者模式，而且通常情况下消息在哪个线程被post，就在哪个线程被转发。而从上面的描述可以发现，
-addObserverForName:object:queue:usingBlock:添加的匿名观察者可以在指定的队列中处理通知，那它的实现机制是什么呢？

## 小结

在我们的应用程序中，一个大的话题就是两个对象之间如何通信。我们需要根据对象之间的关系来确定采用哪一种通信方式。对象之间的通信方式主要有以下几种：

1. 直接方法调用
2. Target-Action
2. Delegate
3. 回调(block)
4. KVO
5. 通知

一般情况下，我们可以根据以下两点来确定使用哪种方式：

1. 通信对象是一对一的还是一对多的
2. 对象之间的耦合度，是强耦合还是松耦合

Objective-C中的通知由于其广播性及松耦合性，非常适合于大的范围内对象之间的通信(模块与模块，或一些框架层级)。通知使用起来非常方便，也正因为如此，所以容易导致滥用。所以在使用前还是需要多想想，是否有更好的方法来实现我们所需要的对象间通信。毕竟，通知机制会在一定程度上会影响到程序的性能。

对于使用NSNotificationCenter，最后总结一些小建议：

1. 在需要的地方使用通知。
2. 注册的观察者在不使用时一定要记得移除，即添加和移除要配对出现。
3. 尽可能迟地去注册一个观察者，并尽可能早将其移除，这样可以改善程序的性能。因为，每post一个通知，都会是遍历通知中心的分发表，确保通知发给每一个观察者。
4. 记住通知的发送和处理是在同一个线程中。
5. 使用-addObserverForName:object:queue:usingBlock:务必处理好内存问题，避免出现循环引用。
6. NSNotificationCenter是线程安全的，但并不意味着在多线程环境中不需要关注线程安全问题。不恰当的使用仍然会引发线程问题。

最后，“[@叶孤城___](http://weibo.com/u/1438670852)”叶大大在微博中推荐了几篇文章，即参考中的4-7，值得细读一下。

## 参考

1. [NSNotificationCenter Class Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSNotificationCenter_Class/)
2. [Notification Programming Topics](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Notifications/Articles/NotificationQueues.html)
3. [NSNotification & NSNotification​Center](http://nshipster.com/nsnotification-and-nsnotificationcenter/)
4. [NSNotificationCenter part 1: Receiving and sending notifications](http://www.hpique.com/2013/12/nsnotificationcenter-part-1/)
5. [NSNotificationCenter part 2: Implementing the observer pattern with notifications](http://www.hpique.com/2013/12/nsnotificationcenter-part-2/)
6. [NSNotificationCenter part 3: Unit testing notifications with OCMock](http://www.hpique.com/2013/12/nsnotificationcenter-part-3/)
7. [NSNotificationCenter part 4: Asynchronous notifications with NSNotificationQueue](http://www.hpique.com/2013/12/nsnotificationcenter-part-4/)
8. [View controller dealloc not called when using NSNotificationCenter code block method with ARC](http://stackoverflow.com/questions/12699118/view-controller-dealloc-not-called-when-using-nsnotificationcenter-code-block-me)

