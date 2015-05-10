---

layout: post

title: "iOS知识小集 第一期(2015.05.10)"

date: 2015-05-10 22:06:42 +0800

comments: true

categories: iOS

---

一直想做这样一个小册子，来记录自己平时开发、阅读博客、看书、代码分析和与人交流中遇到的各种问题。之前有过这样的尝试，但都是无疾而终。不过，每天接触的东西多，有些东西不记下来，忘得也是很快，第二次遇到同样的问题时，还得再查一遍。好记性不如烂笔头，所以又决定重拾此事，时不时回头看看，温故而知新。

这里面的每个问题，不会太长。或是读书笔记，或是摘抄，亦或是验证，每个问题的篇幅争取在六七百字的样子。笔记和摘抄的出处会详细标明。问题的个数不限，凑齐3500字左右就发一篇。争取每月至少发两篇吧，权当是对自己学习的一个整理。

本期主要记录了以下几个问题：

1. NSString属性什么时候用copy，什么时候用strong?
2. Foundation中的断言处理
3. IBOutletCollection
4. NSRecursiveLock递归锁的使用
5. NSHashTable

## NSString属性什么时候用copy，什么时候用strong?

我们在声明一个NSString属性时，对于其内存相关特性，通常有两种选择(基于ARC环境)：strong与copy。那这两者有什么区别呢？什么时候该用strong，什么时候该用copy呢？让我们先来看个例子。

### 示例

我们定义一个类，并为其声明两个字符串属性，如下所示：

	@interface TestStringClass ()

	@property (nonatomic, strong) NSString *strongString;
	@property (nonatomic, copy) NSString *copyedString;
	
	@end
	
上面的代码声明了两个字符串属性，其中一个内存特性是strong，一个是copy。下面我们来看看它们的区别。

首先，我们用一个不可变字符串来为这两个属性赋值，

	- (void)test {
	    
	    NSString *string = [NSString stringWithFormat:@"abc"];
	    self.strongString = string;
	    self.copyedString = string;
	    
	    NSLog(@"origin string: %p, %p", string, &string);
	    NSLog(@"strong string: %p, %p", _strongString, &_strongString);
	    NSLog(@"copy string: %p, %p", _copyedString, &_copyedString);
	}
	
其输出结果是：

	origin string: 0x7fe441592e20, 0x7fff57519a48
	strong string: 0x7fe441592e20, 0x7fe44159e1f8
	copy string: 0x7fe441592e20, 0x7fe44159e200
	
我们要以看到，这种情况下，不管是strong还是copy属性的对象，其指向的地址都是同一个，即为string指向的地址。如果我们换作MRC环境，打印string的引用计数的话，会看到其引用计数值是3，即strong操作和copy操作都使原字符串对象的引用计数值加了1。

接下来，我们把string由不可变改为可变对象，看看会是什么结果。即将下面这一句

	NSString *string = [NSString stringWithFormat:@"abc"];
	
改成：

	NSMutableString *string = [NSMutableString stringWithFormat:@"abc"];
	
其输出结果是：

	origin string: 0x7ff5f2e33c90, 0x7fff59937a48
	strong string: 0x7ff5f2e33c90, 0x7ff5f2e2aec8
	copy string: 0x7ff5f2e2aee0, 0x7ff5f2e2aed0
	
可以发现，此时copy属性字符串已不再指向string字符串对象，而是深拷贝了string字符串，并让\_copyedString对象指向这个字符串。在MRC环境下，打印两者的引用计数，可以看到string对象的引用计数是2，而\_copyedString对象的引用计数是1。

此时，我们如果去修改string字符串的话，可以看到：因为\_strongString与string是指向同一对象，所以\_strongString的值也会跟随着改变(需要注意的是，此时\_strongString的类型实际上是NSMutableString，而不是NSString)；而\_copyedString是指向另一个对象的，所以并不会改变。

### 结论

由于NSMutableString是NSString的子类，所以一个NSString指针可以指向NSMutableString对象，让我们的strongString指针指向一个可变字符串是OK的。

而上面的例子可以看出，当源字符串是NSString时，由于字符串是不可变的，所以，不管是strong还是copy属性的对象，都是指向源对象，copy操作只是做了次**浅拷贝**。

当源字符串是NSMutableString时，strong属性只是增加了源字符串的引用计数，而copy属性则是对源字符串做了次**深拷贝**，产生一个新的对象，且copy属性对象指向这个新的对象。另外需要注意的是，这个copy属性对象的类型始终是NSString，而不是NSMutableString，因此其是不可变的。

这里还有一个性能问题，即在源字符串是NSMutableString，strong是单纯的增加对象的引用计数，而copy操作是执行了一次深拷贝，所以性能上会有所差异。而如果源字符串是NSString时，则没有这个问题。

所以，在声明NSString属性时，到底是选择strong还是copy，可以根据实际情况来定。不过，一般我们将对象声明为NSString时，都不希望它改变，所以大多数情况下，我们建议用copy，以免因可变字符串的修改导致的一些非预期问题。

关于字符串的内存管理，还有些有意思的东西，可以参考[NSString特性分析学习](http://blog.cnbluebox.com/blog/2014/04/16/nsstringte-xing-fen-xi-xue-xi/)。

### 参考
1. [NSString copy not copying?](http://stackoverflow.com/questions/2521468/nsstring-copy-not-copying)
2. [NSString特性分析学习](http://blog.cnbluebox.com/blog/2014/04/16/nsstringte-xing-fen-xi-xue-xi/)
3. [NSString什么时候用copy，什么时候用strong](http://blog.csdn.net/itianyi/article/details/9018567)

## Foundation中的断言处理

经常在看一些第三方库的代码时，或者自己在写一些基础类时，都会用到断言。所以在此总结一下Objective-C中关于断言的一些问题。

Foundation中定义了两组断言相关的宏，分别是：

	NSAssert / NSCAssert
	NSParameterAssert / NSCParameterAssert

这两组宏主要在功能和语义上有所差别，这些区别主要有以下两点：

1. 如果我们需要确保方法或函数的输入参数的正确性，则应该在方法(函数)的顶部使用NSParameterAssert / NSCParameterAssert；而在其它情况下，使用NSAssert / NSCAssert。
2. 另一个不同是介于C和Objective-C之间。NSAssert / NSParameterAssert应该用于Objective-C的上下文(方法)中，而NSCAssert / NSCParameterAssert应该用于C的上下文(函数)中。

当断言失败时，通常是会抛出一个如下所示的异常：

	*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'true is not equal to false'

Foundation为了处理断言，专门定义了一个NSAssertionHandler来处理断言的失败情况。NSAssertionHandler对象是自动创建的，用于处理失败的断言。当断言失败时，会传递一个字符串给NSAssertionHandler对象来描述失败的原因。**每个线程都有自己的NSAssertionHandler对象**。当调用时，一个断言处理器会打印包含方法和类(或函数)的错误消息，并引发一个NSInternalInconsistencyException异常。就像上面所看到的一样。

我们很少直接去调用NSAssertionHandler的断言处理方法，通常都是自动调用的。

NSAssertionHandler提供的方法并不多，就三个，如下所示：

	// 返回与当前线程的NSAssertionHandler对象。
	// 如果当前线程没有相关的断言处理器，则该方法会创建一个并指定给当前线程
	+ (NSAssertionHandler *)currentHandler
	
	// 当NSCAssert或NSCParameterAssert断言失败时，会调用这个方法
	- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)object lineNumber:(NSInteger)fileName description:(NSString *)line, format,...
	
	// 当NSAssert或NSParameterAssert断言失败时，会调用这个方法
	- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format, ...
	
另外，还定义了一个常量字符串，

	NSString * const NSAssertionHandlerKey;
	
主要是用于在线程的threadDictionary字典中获取或设置断言处理器。

关于断言，还需要注意的一点是在Xcode 4.2以后，在release版本中断言是默认关闭的，这是由宏NS_BLOCK_ASSERTIONS来处理的。也就是说，当编译release版本时，所有的断言调用都是无效的。

我们可以自定义一个继承自NSAssertionHandler的断言处理类，来实现一些我们自己的需求。如Mattt Thompson的[NSAssertion​Handler](http://nshipster.com/nsassertionhandler/)实例一样：

	@interface LoggingAssertionHandler : NSAssertionHandler
	@end
	
	@implementation LoggingAssertionHandler

	- (void)handleFailureInMethod:(SEL)selector
	                       object:(id)object
	                         file:(NSString *)fileName
	                   lineNumber:(NSInteger)line
	                  description:(NSString *)format, ...
	{
	  	NSLog(@"NSAssert Failure: Method %@ for object %@ in %@#%i", NSStringFromSelector(selector), object, fileName, line);
	}
	
	- (void)handleFailureInFunction:(NSString *)functionName
	                           file:(NSString *)fileName
	                     lineNumber:(NSInteger)line
	                    description:(NSString *)format, ...
	{
	  	NSLog(@"NSCAssert Failure: Function (%@) in %@#%i", functionName, fileName, line);
	}
	
	@end
	
上面说过，每个线程都有自己的断言处理器。我们可以通过为线程的threadDictionary字典中的NSAssertionHandlerKey指定一个新值，来改变线程的断言处理器。

如下代码所示：

	- (BOOL)application:(UIApplication *)application
	didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
	{
	  NSAssertionHandler *assertionHandler = [[LoggingAssertionHandler alloc] init];
	  [[[NSThread currentThread] threadDictionary] setValue:assertionHandler
	                                                 forKey:NSAssertionHandlerKey];
	  // ...
	
	  return YES;
	}
	
而什么时候应该使用断言呢？通常我们期望程序按照我们的预期去运行时，如调用的参数为空时流程就无法继续下去时，可以使用断言。但另一方面，我们也需要考虑，在这加断言确实是需要的么？我们是否可以通过更多的容错处理来使程序正常运行呢？

Mattt Thompson在[NSAssertion​Handler](http://nshipster.com/nsassertionhandler/)中的倒数第二段说得挺有意思，在此摘抄一下：

	But if we look deeper into NSAssertionHandler—and indeed, into our own hearts, there are lessons to be learned about our capacity for kindness and compassion; about our ability to forgive others, and to recover from our own missteps. We can't be right all of the time. We all make mistakes. By accepting limitations in ourselves and others, only then are we able to grow as individuals.

### 参考

1. [NSAssertion​Handler](http://nshipster.com/nsassertionhandler/)
2. [NSAssertionHandler Class Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSAssertionHandler_Class/)

## IBOutletCollection

在IB与相关文件做连接时，我们经常会用到两个关键字：IBOutlet和IBAction。经常用xib或storyboard的童鞋应该用这两上关键字非常熟悉了。不过UIKit还提供了另一个伪关键字**IBOutletCollection**，我们使用这个关键字，可以将界面上一组相同的控件连接到同一个数组中。

我们先来看看这个伪关键字的定义，可以从UIKit.framework的头文件UINibDeclarations.h找到如下定义：

	#ifndef IBOutletCollection
	#define IBOutletCollection(ClassName)
	#endif
	
另外，在Clang源码中，有更安全的定义方式，如下所示：

	#define IBOutletCollection(ClassName) __attribute__((iboutletcollection(ClassName)))
	
从上面的定义可以看到，与IBOutlet不同的是，IBOutletCollection带有一个参数，该参数是一个类名。

通常情况下，我们使用一个IBOutletCollection属性时，属性必须是strong的，且类型是NSArray，如下所示：

	@property (strong, nonatomic) IBOutletCollection(UIScrollView) NSArray *scrollViews;
	
假定我们的xib文件中有三个横向的scrollView，我们便可以将这三个scrollView都连接至scrollViews属性，然后在我们的代码中便可以做一些统一处理，如下所示：

	- (void)setupScrollViewImages
	{
	    for (UIScrollView *scrollView in self.scrollViews) {
	        [self.imagesData enumerateObjectsUsingBlock:^(NSString *imageName, NSUInteger idx, BOOL *stop) {
	            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth(scrollView.frame) * idx, 0, CGRectGetWidth(scrollView.frame), CGRectGetHeight(scrollView.frame))];
	            imageView.contentMode = UIViewContentModeScaleAspectFill;
	            imageView.image = [UIImage imageNamed:imageName];
	            [scrollView addSubview:imageView];
	        }];
	    }
	}

这段代码会影响到三个scrollView。这样做的好处是我们不需要手动通过addObject:方法将scrollView添加到scrollViews中。

不过在使用IBOutletCollection时，需要注意两点：

1. IBOutletCollection集合中对象的顺序是不确定的。我们通过调试方法可以看到集合中对象的顺序跟我们连接的顺序是一样的。但是这个顺序可能会因为不同版本的Xcode而有所不同。所以我们不应该试图在代码中去假定这种顺序。
2. 不管IBOutletCollection(ClassName)中的控件是什么，属性的类型始终是NSArray。实际上，我们可以声明是任何类型，如NSSet，NSMutableArray，甚至可以是UIColor，但不管我们在此设置的是什么类，IBOutletCollection属性总是指向一个NSArray数组。

关于第二点，我们以上面的scrollViews为例，作如下修改：

	@property (strong, nonatomic) IBOutletCollection(UIScrollView) NSSet *scrollViews;
	
实际上我们在控制台打印这个scrollViews时，结果如下所示：

	(lldb) po self.scrollViews
	<__NSArrayI 0x1740573d0>(
	<UIScrollView: 0x12d60d770; frame = (0 0; 320 162); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x1740574f0>; layer = <CALayer: 0x174229480>; contentOffset: {0, 0}; contentSize: {0, 0}>,
	<UIScrollView: 0x12d60dee0; frame = (0 0; 320 161); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x174057790>; layer = <CALayer: 0x1742297c0>; contentOffset: {0, 0}; contentSize: {0, 0}>,
	<UIScrollView: 0x12d60e650; frame = (0 0; 320 163); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x1740579a0>; layer = <CALayer: 0x1742298e0>; contentOffset: {0, 0}; contentSize: {0, 0}>
	)

可以看到，它指向的是一个NSArray数组。

另外，IBOutletCollection实际上在iOS 4版本中就有了。不过，现在的Objective-C已经支持object literals了，所以定义数组可以直接用@[]，方便了许多。而且object literals方式可以添加不在xib中的用代码定义的视图，所以显得更加灵活。当然，两种方式选择哪一种，就看我们自己的实际需要和喜好了。

### 参考

1. [IBAction / IBOutlet / IBOutlet​Collection](http://nshipster.com/ibaction-iboutlet-iboutletcollection/)
2. [IBOutletCollection.m](http://www.opensource.apple.com/source/clang/clang-318.0.45/src/tools/clang/test/Index/IBOutletCollection.m)

## NSRecursiveLock递归锁的使用

NSRecursiveLock实际上定义的是一个递归锁，这个锁可以被同一线程多次请求，而不会引起死锁。这主要是用在循环或递归操作中。我们先来看一个示例：

    NSLock *lock = [[NSLock alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        static void (^RecursiveMethod)(int);
        
        RecursiveMethod = ^(int value) {
            
            [lock lock];
            if (value > 0) {
                
                NSLog(@"value = %d", value);
                sleep(2);
                RecursiveMethod(value - 1);
            }
            [lock unlock];
        };
        
        RecursiveMethod(5);
    });
    
这段代码是一个典型的死锁情况。在我们的线程中，RecursiveMethod是递归调用的。所以每次进入这个block时，都会去加一次锁，而从第二次开始，由于锁已经被使用了且没有解锁，所以它需要等待锁被解除，这样就导致了死锁，线程被阻塞住了。调试器中会输出如下信息：

	value = 5
	*** -[NSLock lock]: deadlock (<NSLock: 0x1700ceee0> '(null)')	*** Break on _NSLockError() to debug.	

在这种情况下，我们就可以使用NSRecursiveLock。它可以允许同一线程多次加锁，而不会造成死锁。递归锁会跟踪它被lock的次数。每次成功的lock都必须平衡调用unlock操作。只有所有达到这种平衡，锁最后才能被释放，以供其它线程使用。

所以，对上面的代码进行一下改造，

	NSRecursiveLock *lock = [[NSRecursiveLock alloc] init];
	
这样，程序就能正常运行了，其输出如下所示：

	value = 5
	value = 4
	value = 3
	value = 2
	value = 1
	
NSRecursiveLock除了实现NSLocking协议的方法外，还提供了两个方法，分别如下：

	// 在给定的时间之前去尝试请求一个锁
	- (BOOL)lockBeforeDate:(NSDate *)limit
	
	// 尝试去请求一个锁，并会立即返回一个布尔值，表示尝试是否成功
	- (BOOL)tryLock
	
这两个方法都可以用于在多线程的情况下，去尝试请求一个递归锁，然后根据返回的布尔值，来做相应的处理。如下代码所示：

    NSRecursiveLock *lock = [[NSRecursiveLock alloc] init];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        static void (^RecursiveMethod)(int);
        
        RecursiveMethod = ^(int value) {
            
            [lock lock];
            if (value > 0) {
                
                NSLog(@"value = %d", value);
                sleep(2);
                RecursiveMethod(value - 1);
            }
            [lock unlock];
        };
        
        RecursiveMethod(5);
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        sleep(2);
        BOOL flag = [lock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        if (flag) {
            NSLog(@"lock before date");
            
            [lock unlock];
        } else {
            NSLog(@"fail to lock before date");
        }
    });
    
在前面的代码中，我们又添加了一段代码，增加一个线程来获取递归锁。我们在第二个线程中尝试去获取递归锁，当然这种情况下是会失败的，输出结果如下：

	value = 5
	value = 4
	fail to lock before date
	value = 3
	value = 2
	value = 1
	
另外，NSRecursiveLock还声明了一个name属性，如下：

	@property(copy) NSString *name
	
我们可以使用这个字符串来标识一个锁。Cocoa也会使用这个name作为错误描述信息的一部分。
	
### 参考

1. [NSRecursiveLock Class Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSRecursiveLock_Class/)
2. [Objective-C中不同方式实现锁(二)](http://www.tanhao.me/pieces/643.html/)

## NSHashTable

在看KVOController的代码时，又看到了NSHashTable这个类，所以就此整理一下。

NSHashTable效仿了NSSet(NSMutableSet)，但提供了比NSSet更多的操作选项，尤其是在对弱引用关系的支持上，NSHashTable在对象/内存处理时更加的灵活。相较于NSSet，NSHashTable具有以下特性：

1. NSSet(NSMutableSet)持有其元素的强引用，同时这些元素是使用hash值及isEqual:方法来做hash检测及判断是否相等的。
2. NSHashTable是可变的，它没有不可变版本。
3. 它可以持有元素的弱引用，而且在对象被销毁后能正确地将其移除。而这一点在NSSet是做不到的。
4. 它的成员可以在添加时被拷贝。
5. 它的成员可以使用指针来标识是否相等及做hash检测。
3. 它可以包含任意指针，其成员没有限制为对象。我们可以配置一个NSHashTable实例来操作任意的指针，而不仅仅是对象。

初始化NSHashTable时，我们可以设置一个初始选项，这个选项确定了这个NSHashTable对象后面所有的行为。这个选项是由NSHashTableOptions枚举来定义的，如下所示：

	enum {
	
		// 默认行为，强引用集合中的对象，等同于NSSet
	   	NSHashTableStrongMemory             = 0,
	   	
	   	// 在将对象添加到集合之前，会拷贝对象
	   	NSHashTableCopyIn                   = NSPointerFunctionsCopyIn,
	   	
	   	// 使用移位指针(shifted pointer)来做hash检测及确定两个对象是否相等；
	   	// 同时使用description方法来做描述字符串
	   	NSHashTableObjectPointerPersonality = NSPointerFunctionsObjectPointerPersonality,
	   	
	   	// 弱引用集合中的对象，且在对象被释放后，会被正确的移除。
	   	NSHashTableWeakMemory               = NSPointerFunctionsWeakMemory 
	};
	typedef NSUInteger NSHashTableOptions;
	
当然，我们还可以使用NSPointerFunctions来初始化，但只有使用NSHashTableOptions定义的这些值，才能确保NSHashTable的各个API可以正确的工作--包括拷贝、归档及快速枚举。

个人认为NSHashTable吸引人的地方在于可以持有元素的弱引用，而且在对象被销毁后能正确地将其移除。我们来写个示例：

	
	// 具体调用如下
	@implementation TestHashAndMapTableClass {
    
	    NSMutableDictionary *_dic;
	    NSSet               *_set;
	    
	    NSHashTable         *_hashTable;
	}
	
	- (instancetype)init {
	    
	    self = [super init];
	    
	    if (self) {
	        
	        [self testWeakMemory];
	        
	        NSLog(@"hash table [init]: %@", _hashTable);
	    }
	    
	    return self;
	}

	- (void)testWeakMemory {
	    
	    if (!_hashTable) {
	        _hashTable = [NSHashTable weakObjectsHashTable];
	    }
	    
	    NSObject *obj = [[NSObject alloc] init];
	    
	    [_hashTable addObject:obj];
	    
	    NSLog(@"hash table [testWeakMemory] : %@", _hashTable);
	}
	
这段代码的输出结果如下：

	hash table [testWeakMemory] : NSHashTable {
	[6] <NSObject: 0x7fa2b1562670>
	}
	hash table [init]: NSHashTable {
	}
	
可以看到，在离开testWeakMemory方法，obj对象被释放，同时对象在集合中的引用也被安全的删除。

这样看来，NSHashTable似乎比NSSet(NSMutableSet)要好啊。那是不是我们就应用都使用NSHashTable呢？Peter Steinberger在[The Foundation Collection Classes](http://www.objc.io/issue-7/collections.html)给了我们一组数据，显示在添加对象的操作中，NSHashTable所有的时间差不多是NSMutableSet的2倍，而在其它操作中，性能大体相近。所以，如果我们只需要NSSet的特性，就尽量用NSSet。

另外，Mattt Thompson在[NSHash​Table & NSMap​Table](http://nshipster.com/nshashtable-and-nsmaptable/)的结尾也写了段挺有意思的话，在此直接摘抄过来：

	As always, it's important to remember that programming is not about being clever: always approach a problem from the highest viable level of abstraction. NSSet and NSDictionary are great classes. For 99% of problems, they are undoubtedly the correct tool for the job. If, however, your problem has any of the particular memory management constraints described above, then NSHashTable & NSMapTable may be worth a look.

### 参考

1. [NSHashTable Class Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/NSHashTable_class/)
2. [NSHash​Table & NSMap​Table](http://nshipster.com/nshashtable-and-nsmaptable/)
3. [NSHashTable & NSMapTable](http://billwang1990.github.io/blog/2014/03/31/nshashtable-and-nsmaptable/)
4. [The Foundation Collection Classes](http://www.objc.io/issue-7/collections.html)

## 零碎

### (一) "Unknown class XXViewController in Interface Builder file."" 问题处理

最近在静态库中写了一个XXViewController类，然后在主工程的xib中，将xib的类指定为XXViewController，程序运行时，报了如下错误：

	Unknown class XXViewController in Interface Builder file.

之前也遇到这个问题，但已记得不太清楚，所以又开始在stackoverflow上找答案。

其实这个问题与Interface Builder无关，最直接的原因还是相关的symbol没有从静态库中加载进来。这种问题的处理就是在Target的"Build Setting"->"Other Link Flags"中加上"-all_load -ObjC"这两个标识位，这样就OK了。

### (二)关于Unbalanced calls to begin/end appearance transitions for ...问题的处理

我们的某个业务有这么一个需求，进入一个列表后需要立马又push一个web页面，做一些活动的推广。在iOS 8上，我们的实现是一切OK的；但到了iOS 7上，就发现这个web页面push不出来了，同时控制台给了一条警告消息，即如下：

	Unbalanced calls to begin/end appearance transitions for ...
	
在这种情况下，点击导航栏中的返回按钮时，直接显示一个黑屏。

我们到stackoverflow上查了一下，有这么一段提示：

	occurs when you try and display a new viewcontroller before the current view controller is finished displaying.
	
意思是说在当前视图控制器完成显示之前，又试图去显示一个新的视图控制器。

于是我们去排查代码，果然发现，在viewDidLoad里面去做了次网络请求操作，且请求返回后就去push这个web活动推广页。此时，当前的视图控制器可能并未显示完成(即未完成push操作)。

	Basically you are trying to push two view controllers onto the stack at almost the same time. 
	
当几乎同时将两个视图控制器push到当前的导航控制器栈中时，或者同时pop两个不同的视图控制器，就会出现不确定的结果。所以我们应该确保同一时间，对同一个导航控制器栈只有一个操作，即便当前的视图控制器正在动画过程中，也不应该再去push或pop一个新的视图控制器。

所以最后我们把web活动的数据请求放到了viewDidAppear里面，并做了些处理，这样问题就解决了。

#### 参考

1. [“Unbalanced calls to begin/end appearance transitions for DetailViewController” when pushing more than one detail view controller](http://stackoverflow.com/questions/9088465/unbalanced-calls-to-begin-end-appearance-transitions-for-detailviewcontroller)

2. [Unbalanced calls to begin/end appearance transitions for UITabBarController](http://stackoverflow.com/questions/8563473/unbalanced-calls-to-begin-end-appearance-transitions-for-uitabbarcontroller)
