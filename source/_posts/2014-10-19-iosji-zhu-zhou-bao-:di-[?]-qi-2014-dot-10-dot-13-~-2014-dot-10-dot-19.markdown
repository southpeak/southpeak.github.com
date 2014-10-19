---

layout: post

title: "iOS技术周报：第一期(2014.10.13 ~ 2014.10.19)"

date: 2014-10-19 21:12:35 +0800

comments: true

categories: iOS

---


## 1. 自定义下标操作

对于数组与字典，我们可以使用下标来获取指定下标对应的值，如：

    NSArray *array = @[@1, @2, @3];
    id value1 = array[0];        // 1
    
    NSDictionary *dic = @{@"1": @1, @"2": @2, @"3": @3};
    id value2 = dic[@"2"];      // 2
    
另外，Objective-C还支持自定义下标操作。我们先来看看如下代码：

	@interface MyCollection : NSObject
	
	@property (nonatomic, retain) NSMutableArray *array;
	@property (nonatomic, retain) NSMutableDictionary *dictionary;
	
	@end

我们定义MyCollection类的一个实例，然后可以按如下方式访问array的元素

    MyCollection *collection = [[MyCollection alloc] init];
    id arrElement = collection.array[0];
    collection.array[1] = @"1";
    id arrDic = collection.dictionary[@"test"];
    collection.dictionary[@"id"] = @"abc";
    
但这样写代码略显麻烦，毕竟中间多用了一次"."操作。这种情况下，我们就可以为我们的类自定义相应的下标操作，来简单这种集合元素的访问。自定义下标使用到了如下几个方法：

1. NSArray : - (id)objectAtIndexedSubscript:(NSUInteger)index; 
2. NSMutableArray : - (void)setObject: (id)obj atIndexedSubscript: (NSUInteger)index; 
3. NSDictionary : - (id)objectForKeyedSubscript: (id <NSCopying>)key; 
4. NSMutableDictionary : - (void)setObject: (id)anObject forKeyedSubscript: (id <NSCopying>)aKey;

我们为MyCollection类定义下标操作，代码如下所示：

	@implementation MyCollection
	
	- (id)objectAtIndexedSubscript:(NSUInteger)index {
	    return _array[index];
	}
	
	- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)index {
	    _array[index] = obj;
	}
	
	- (id)objectForKeyedSubscript:(id<NSCopying>)key {
	    return _dictionary[key];
	}
	
	- (void)setObject:(id)anObject forKeyedSubscript:(id<NSCopying>)aKey {
	    _dictionary[aKey] = anObject;
	}
	
	@end
	
这样，我们就可以直接用下标操作来访问类中array属性和dictionary属性的元素了，如下所示：

    MyCollection *collection = [[MyCollection alloc] init];
    id arrElement = collection[0];
    collection[1] = @"1";
    id arrDic = collection[@"test"];
    collection[@"id"] = @"abc";
    
*注：数组与字典本身也是实现了这些方法来支持下标操作*

## 2. NSInvocation的使用

一个NSInvocation实例是一个静态呈现的Objective-C消息，换句话说，它是一个被转换成对象的一个动作。NSInvocation对象用于在对象间和应用间存储和转发消息，主要通过NSTimer对象和分布式对象系统来实现转发。

一个NSInvocation对象包含一个Objective-C消息所具有的元素：目标、selector、参数和返回值。所有这些元素可以直接设置，而返回值会在NSInvocation对象分发时被自动设置。

一个NSInvocation对象可以被多次分发到不同的目标(target)；它的参数可以在不同的分发中使用不同的值，以获取到不同的结果；甚至于它的selector也可以修改，只需要方法签名一样即可。这种灵活性使得NSInvocation在多次调用带有较多参数的消息的场景下非常有用；我们不需要为每个消息都键入不同的表达式，我们只需要每次在将消息发到新的目标时根据需要修改NSInvocation对象就可以。

NSInvocation对象不支持带有可变参数或联合参数的方法调用。我们应该使用invocationWithMethodSignature:方法来创建NSInvocation对象；而不应该使用alloc和init来创建。

这个类默认情况下不会为调用retain参数。如果这些参数(对象)可能会在创建NSInvocation对象和使用它这个时间段中间被释放，那么我们需要显示地retain这些对象，或者调用retainArguments方法来让调用对象自己retain它们。

NSInvocation的使用如下所示：

	// 代码来自ReactiveCocoa源码的RACBlockTrampoline类
	
	- (id)invokeWithArguments:(RACTuple *)arguments {
		SEL selector = [self selectorForArgumentCount:arguments.count];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]];
		invocation.selector = selector;
		invocation.target = self;
	
		for (NSUInteger i = 0; i < arguments.count; i++) {
			id arg = arguments[i];
			NSInteger argIndex = (NSInteger)(i + 2);
			[invocation setArgument:&arg atIndex:argIndex];
		}
	
		[invocation invoke];
		
		__unsafe_unretained id returnVal;
		[invocation getReturnValue:&returnVal];
		return returnVal;
	}

这里需要注意的是在调用setArgument:atIndex:时，参数的索引位置是从2开始的。因为索引0和1分别指向的是隐藏参数**self**和**_cmd**。这两个值是直接通过target和selector属性来设置的。

#### 参考
1. [NSInvocation Class Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSInvocation_Class)

## 3. 方法签名

在Objective-C中，方法签名由NSMethodSignature类来表示。

一个NSMethodSignature对象记录了方法的参数及返回值的类型信息。它主要用于转发那些接收对象无法响应的消息--最值得注意的是分发对象。通常我们会使用NSObject对象的methodSignatureForSelector:方法来创建一个NSMethodSignature对象。然后这个对象用于创建一个NSInvocation对象，这个对作为参数被传递到forwardInvocation:方法中，以将这个方法调用发送到任何其它对象以处理这个消息。默认情况下，NSObject调用doesNotRecognizeSelector:方法并引发一个异常。对于分发对象，NSInvocation对象通过NSMethodSignature对象的信息来编码，并被发送到一个表示消息接收者的真实对象中。

一个NSMethodSignature对象通过getArgumentTypeAtIndex:方法来获取指定索引位置的参数类型(该方法返回值是const char *, 用C字符串来表示Objective-C类型编码)。对于每个方法来说，有两个隐藏的参数，即self和_cmd，索引分别为0和1。除了参数类型，NSMethodSignature还有几个属性：numberOfArguments属性用来获取参数的个数；frameLength属性用来获取所有参数所占用的栈空间长度，以及methodReturnLength和methodReturnType获取返回值的长度和类型。最后，使用分发对象的程序可以通过isOneway方法来确定方法是否是异步的。

NSMethodSignature示例代码如下：

	// 代码摘自ReactiveCocoa:NSObject+RACLifting
	
	- (RACSignal *)rac_liftSelector:(SEL)selector withSignalOfArguments:(RACSignal *)arguments {
	    NSCParameterAssert(selector != NULL);
	    NSCParameterAssert(arguments != nil);
	    
	    @unsafeify(self);
	    
	    NSMethodSignature *methodSignature = [self methodSignatureForSelector:selector];
	    NSCAssert(methodSignature != nil, @"%@ does not respond to %@", self, NSStringFromSelector(selector));
	    
	    return [[[[arguments
	            takeUntil:self.rac_willDeallocSignal]
	            map:^(RACTuple *arguments) {
	                @strongify(self);
	                
	                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	                invocation.selector = selector;
	                invocation.rac_argumentsTuple = arguments;
	                [invocation invokeWithTarget:self];
	                
	                return invocation.rac_returnValue;
	            }]
	            replayLast]
	            setNameWithFormat:@"%@ -rac_liftSelector: %s withSignalsOfArguments: %@", [self rac_description], sel_getName(selector), arguments];
	}
	
#### 参考
1. [NSMethodSignature Class Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSMethodSignature_Class/index.html#//apple_ref/doc/c_ref/NSMethodSignature)


## 4. CFBridgingRelease/CFBridgingRetain

这两个函数的作用类似于__bridge，用于在ARC环境下，在Cocoa Fundation和Core Funcation之间转换可桥接对象。

CFBridgingRetain函数是将Objective-C指针转换为Core Foundation指针，同时会转移对象所有权。如下代码所示：

	NSString *string = <#Get a string#>;
	CFStringRef cfString = (CFStringRef)CFBridgingRetain(string);
	
	// Use the CF string.
	CFRelease(cfString);
	
通过这种转换，我们可以管理对象的生命周期。转换后，对象的释放就由我们来负责了。

相反，CFBridgingRelease函数是将一个非Objective-C指针转换为Objective-C指针，同时转移对象的权(ARC)。如下代码所示：

	CFStringRef cfName = ABRecordCopyValue(person, kABPersonFirstNameProperty);
	NSString *name = (NSString *)CFBridgingRelease(cfName);

转换后，我们不需要手动去释放对象，因为这是在ARC环境所做的转换。

#### 参考
1. [Foundation Functions Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Miscellaneous/Foundation_Functions)

## 5. NSProcessInfo

这个类用来访问当前进程的信息。每一个进程都有一个单独的共享的NSProcessInfo对象，即为进程信息代理(Process information agent)，它可以返回诸如参数，环境变量，主机名或进程名等信息。方法processInfo类方法会返回当前进程共享的代理--即发送消息的对象所在的进程。我们可以如下获取当前进程的名字：

	NSString *processName = [[NSProcessInfo processInfo] processName];
	
NSProcessInfo对象在还能解析环境变量和命令行参数，如果无法使用Unicode编码将其表示为一个UTF-8字符串，则会将其编码成用户默认的C字符串编码格式。如果两种转换都无效，则NSProcessInfo对象会忽略这些值。

#### 管理Activity
系统会以启发式(heuristics)的方法来改善电池寿命，性能和应用的响应。我们可以使用下面的方法来管理一些Activity，以告诉系统程序有特殊的需求：

	beginActivityWithOptions:reason:

	endActivity:

	performActivityWithOptions:reason:usingBlock:

为了响应创建Activity，系统会禁用部分或全部的heuristics，以便我们的程序尽快完成，而如果用户需要的话，同样还能提供响应操作。我们会在程序需要执行一个长时间运行的操作时使用Activity。如果Activity可能会消耗不同的时间，则应该使用这些API。这会在数据量或用户的计算机性能改变时，确保操作的正确。

Activity主要分为两类：

1. 用户启动(User initiated)的Activity：这些是用户显示开启的有限时长的Activity。比如导入或下载一个用户文件。
2. 后台Activity：这些Activity是程序普通操作的一部分且是有限时长的，但不是由用户显示启动的。如自动保存、索引及自动下载文件。

此外，如果程序需要高优先级的I/O操作，则可以包含NSActivityLatencyCritical标识(使用OR操作)。我们只应该在诸如录制视频音频这样确实需要高优先级的Activity中使用这个标识。

如果我们的Activity在主线程的事件回调中同步发生，则不需要使用这些API。

需要注意的是，如果在一个延长的时间周期内没有结束这些Activity，则会对设备的运行性能产生明显的负面影响，所以确保只使用最少的时间。用户偏好设置可能会重写应用的请求。

我们也可以用这些API来控制自动终止或突然终止。如

	id activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityAutomaticTerminationDisabled reason:@"Good Reason"];
	// Perform some work.
	[[NSProcessInfo processInfo] endActivity:activity];
	
当然也可以使用

	[[NSProcessInfo processInfo] disableAutomaticTermination:@"Good Reason"];
	// Perform some work.
	[[NSProcessInfo processInfo] enableAutomaticTermination:@"Good Reason"];

不过由于上面这个接口返回一个对象，它可以方便地匹配开始和结束操作。如果这个对象在endActivity:方法调用之前被释放，则Activity会自动结束。

这个API也提供了禁用/执行系统范围内的闲置睡眠的机制。这可能对用户体验产生重大影响，所以确保不要忘记结束那些禁用睡眠的Activity。

#### 突然终止(Sudden Termination)
在OS X v10.6及后续版本中有一个机制，它允许系统通过杀死应用程序来更快地输出日志或关机，而不是要求程序自行终止。应用程序可以在全局范围内开启这一功能，然后在可能导致数据损坏或较差用户体验的操作中重写这一功能的可用性。或者，我们的应用程序可以手动开启和禁用这一功能。

enableSuddenTermination和disableSuddenTermination方法分别会减少和增加一个计数器，其值在进程首次创建时为1。当计数器值为0时，程序会被认为是可安全杀死的，且可能在没有任何通知或事件被发送到进程时被系统杀死。

应用程序可以在程序的Info.plist文件中添加NSSupportsSuddenTermination键值来决定是否支持突然终止。如果该值存在且值为YES，则相当于在启动时调用了enableSuddenTermination。这使得程序可以立即被杀死。我们可以通过调用disableSuddenTermination方法来修改这种行为。

通常情况下，当我们的程序延迟那些必须在程序终止前才执行的操作时，我们会禁用突然终止行为。例如，如果程序延迟写磁盘操作，而突然终止行为可用，则我们应该将这些操作放在disableSuddenTermination方法与enableSuddenTermination方法之间执(注意，应该是先禁用、然后执行操作、最后再开启)。

一些AppKit功能会临时自动禁用突然终止行为，以确保数据完整性。如

1. NSUserDefaults临时自动禁用突然终止行为以防止进程在设置值和将值写入磁盘这之间被杀死。

#### 参考
1. [NSProcessInfo Class Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSProcessInfo_Class/)

## 6. 快速枚举

快速枚举即我们常写的for...in语句，可以让我们用简洁的语法来安全、有效地枚举集合中的内容。其基本用法如下

	for (type 变量 in 表达式) {
		// to do something
	}
	
其中迭代变量会被赋值为表达式值对象中的每一个元素，并针对每一个元素执行处理语句。当循环结束后，迭代变量会被赋值为nil。如果循环提前结束，则迭代变量的值将指向最后一次遍历的那个对象。

要使用这种控制语句，则表达式的值必须遵循NSFastEnumeration协议。该协议中定义了一个用作上下文信息的结构体：

	typedef struct {
	      unsigned long state;
	      id *itemsPtr;
	      unsigned long *mutationsPtr;
	      unsigned long extra[5];
	} NSFastEnumerationState;

及一个必须实现的方法

	- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
	                                  objects:(id [])stackbuf
	                                    count:(NSUInteger)len

该方法通过C数组返回发送者需要迭代的对象列表，并返回数组中对象的个数。

Cocoa中的集合类NSArray, NSDictionary和NSSet都遵循该协议，NSEnumerator类也是。

示例代码如下：

	// 代码摘自ReactiveCocoa: RACIndexSetSequence
	
	- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id[])stackbuf count:(NSUInteger)len {
		NSCParameterAssert(len > 0);
	
		if (state->state >= self.count) {
			// Enumeration has completed.
			return 0;
		}
		
		if (state->state == 0) {
			// Enumeration begun, mark the mutation flag.
			state->mutationsPtr = state->extra;
		}
		
		state->itemsPtr = stackbuf;
		
		unsigned long index = 0;
		while (index < MIN(self.count - state->state, len)) {
			stackbuf[index] = @(self.indexes[index + state->state]);
			++index;
		}
		
		state->state += index;
		return index;
	}
	
从上面的代码可以看到，快速枚举使用了指针运算，所以它比使用NSEnumerator的标准方法效率更高。

#### 参考
1. [NSEnumerator Class Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/Foundation/Classes/NSEnumerator_Class/index.html)
2. [NSFastEnumeration Protocol Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/NSFastEnumeration_protocol/index.html#//apple_ref/occ/intf/NSFastEnumeration)
3. [Objective-C——在Cocoa Touch框架中使用迭代器模式](http://www.ituring.com.cn/article/details/1348)
4. [快速枚举](http://blog.csdn.net/amdbenq/article/details/7862718)