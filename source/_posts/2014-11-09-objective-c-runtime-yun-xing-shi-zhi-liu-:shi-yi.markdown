---

layout: post

title: "Objective-C Runtime 运行时之六：拾遗"

date: 2014-11-09 14:44:53 +0800

comments: true

categories: iOS

---

前面几篇基本介绍了runtime中的大部分功能，包括对类与对象、成员变量与属性、方法与消息、分类与协议的处理。runtime大部分的功能都是围绕这几点来实现的。

本章的内容并不算重点，主要针对前文中对Objective-C Runtime Reference内容遗漏的地方做些补充。当然这并不能包含所有的内容。runtime还有许多内容，需要读者去研究发现。

## super

在Objective-C中，如果我们需要在类的方法中调用父类的方法时，通常都会用到super，如下所示：

	@interface MyViewController: UIViewController
	
	@end

	@implementation	MyViewController
	
	- (void)viewDidLoad {
		[super viewDidLoad];
		
		// do something
		...
	}
	
	@end
	
如何使用super我们都知道。现在的问题是，它是如何工作的呢？

首先我们需要知道的是super与self不同。self是类的一个隐藏参数，每个方法的实现的第一个参数即为self。而super并不是隐藏参数，它实际上只是一个"编译器标示符"，它负责告诉编译器，当调用viewDidLoad方法时，去调用父类的方法，而不是本类中的方法。而它实际上与self指向的是相同的消息接收者。为了理解这一点，我们先来看看super的定义：

	struct objc_super { id receiver; Class superClass; };
	
这个结构体有两个成员：

1. receiver：即消息的实际接收者
2. superClass：指针当前类的父类
	
当我们使用super来接收消息时，编译器会生成一个objc_super结构体。就上面的例子而言，这个结构体的receiver就是MyViewController对象，与self相同；superClass指向MyViewController的父类UIViewController。

接下来，发送消息时，不是调用objc_msgSend函数，而是调用objc_msgSendSuper函数，其声明如下：

	id objc_msgSendSuper ( struct objc_super *super, SEL op, ... );
	
该函数第一个参数即为前面生成的objc_super结构体，第二个参数是方法的selector。该函数实际的操作是：从objc_super结构体指向的superClass的方法列表开始查找viewDidLoad的selector，找到后以objc->receiver去调用这个selector，而此时的操作流程就是如下方式了

	objc_msgSend(objc_super->receiver, @selector(viewDidLoad))
	
由于objc_super->receiver就是self本身，所以该方法实际与下面这个调用是相同的：

	objc_msgSend(self, @selector(viewDidLoad))
	
为了便于理解，我们看以下实例：

	@interface MyClass : NSObject

	@end
	
	@implementation MyClass
	
	- (void)test {
	    NSLog(@"self class: %@", self.class);
	    NSLog(@"super class: %@", super.class);
	}
	
	@end
	
调用MyClass的test方法后，其输出是：

	2014-11-08 15:55:03.256 [824:209297] self class: MyClass
	2014-11-08 15:55:03.256 [824:209297] super class: MyClass

从上例中可以看到，两者的输出都是MyClass。大家可以自行用上面介绍的内容来梳理一下。

## 库相关操作

库相关的操作主要是用于获取由系统提供的库相关的信息，主要包含以下函数：

	// 获取所有加载的Objective-C框架和动态库的名称
	const char ** objc_copyImageNames ( unsigned int *outCount );
	
	// 获取指定类所在动态库
	const char * class_getImageName ( Class cls );
	
	// 获取指定库或框架中所有类的类名
	const char ** objc_copyClassNamesForImage ( const char *image, unsigned int *outCount );

通过这几个函数，我们可以了解到某个类所有的库，以及某个库中包含哪些类。如下代码所示：

    NSLog(@"获取指定类所在动态库");
    
    NSLog(@"UIView's Framework: %s", class_getImageName(NSClassFromString(@"UIView")));
    
    NSLog(@"获取指定库或框架中所有类的类名");
    const char ** classes = objc_copyClassNamesForImage(class_getImageName(NSClassFromString(@"UIView")), &outCount);
    for (int i = 0; i < outCount; i++) {
        NSLog(@"class name: %s", classes[i]);
    }
    
其输出结果如下：

	2014-11-08 12:57:32.689 [747:184013] 获取指定类所在动态库
	2014-11-08 12:57:32.690 [747:184013] UIView's Framework: /System/Library/Frameworks/UIKit.framework/UIKit
	2014-11-08 12:57:32.690 [747:184013] 获取指定库或框架中所有类的类名
	2014-11-08 12:57:32.691 [747:184013] class name: UIKeyboardPredictiveSettings
	2014-11-08 12:57:32.691 [747:184013] class name: _UIPickerViewTopFrame
	2014-11-08 12:57:32.691 [747:184013] class name: _UIOnePartImageView
	2014-11-08 12:57:32.692 [747:184013] class name: _UIPickerViewSelectionBar
	2014-11-08 12:57:32.692 [747:184013] class name: _UIPickerWheelView
	2014-11-08 12:57:32.692 [747:184013] class name: _UIPickerViewTestParameters
	......

## 块操作

我们都知道block给我们带到极大的方便，苹果也不断提供一些使用block的新的API。同时，苹果在runtime中也提供了一些函数来支持针对block的操作，这些函数包括：

	// 创建一个指针函数的指针，该函数调用时会调用特定的block
	IMP imp_implementationWithBlock ( id block );

	// 返回与IMP(使用imp_implementationWithBlock创建的)相关的block
	id imp_getBlock ( IMP anImp );
	
	// 解除block与IMP(使用imp_implementationWithBlock创建的)的关联关系，并释放block的拷贝
	BOOL imp_removeBlock ( IMP anImp );

● imp_implementationWithBlock函数：参数block的签名必须是method_return_type ^(id self, method_args …)形式的。该方法能让我们使用block作为IMP。如下代码所示：

	@interface MyRuntimeBlock : NSObject

	@end
	
	@implementation MyRuntimeBlock
	
	@end

	// 测试代码
    IMP imp = imp_implementationWithBlock(^(id obj, NSString *str) {
        NSLog(@"%@", str);
    });
    
    class_addMethod(MyRuntimeBlock.class, @selector(testBlock:), imp, "v@:@");
    
    MyRuntimeBlock *runtime = [[MyRuntimeBlock alloc] init];
    [runtime performSelector:@selector(testBlock:) withObject:@"hello world!"];
    
输出结果是

	2014-11-09 14:03:19.779 [1172:395446] hello world!

## 弱引用操作

	// 加载弱引用指针引用的对象并返回
	id objc_loadWeak ( id *location );
	
	// 存储__weak变量的新值
	id objc_storeWeak ( id *location, id obj );

● objc_loadWeak函数：该函数加载一个弱指针引用的对象，并在对其做retain和autoreleasing操作后返回它。这样，对象就可以在调用者使用它时保持足够长的生命周期。该函数典型的用法是在任何有使用__weak变量的表达式中使用。

● objc_storeWeak函数：该函数的典型用法是用于__weak变量做为赋值对象时。

这两个函数的具体实施在此不举例，有兴趣的小伙伴可以参考《Objective-C高级编程：iOS与OS X多线程和内存管理》中对__weak实现的介绍。

## 宏定义

在runtime中，还定义了一些宏定义供我们使用，有些值我们会经常用到，如表示BOOL值的YES/NO；而有些值不常用，如OBJC_ROOT_CLASS。在此我们做一个简单的介绍。

### 布尔值

	#define YES  (BOOL)1
	#define NO   (BOOL)0

这两个宏定义定义了表示布尔值的常量，需要注意的是YES的值是1，而不是非0值。

### 空值

	#define nil  __DARWIN_NULL
	#define Nil  __DARWIN_NULL

其中nil用于空的实例对象，而Nil用于空类对象。

### 分发函数原型

	#define OBJC_OLD_DISPATCH_PROTOTYPES  1
	
该宏指明分发函数是否必须转换为合适的函数指针类型。当值为0时，必须进行转换

### Objective-C根类

	#define OBJC_ROOT_CLASS 
	
如果我们定义了一个Objective-C根类，则编译器会报错，指明我们定义的类没有指定一个基类。这种情况下，我们就可以使用这个宏定义来避过这个编译错误。该宏在iOS 7.0后可用。

其实在NSObject的声明中，我们就可以看到这个宏的身影，如下所示：

	__OSX_AVAILABLE_STARTING(__MAC_10_0, __IPHONE_2_0)
	OBJC_ROOT_CLASS
	OBJC_EXPORT
	@interface NSObject <NSObject> {
	    Class isa  OBJC_ISA_AVAILABILITY;
	}
	
我们可以参考这种方式来定义我们自己的根类。

### 局部变量存储时长

	#define NS_VALID_UNTIL_END_OF_SCOPE 

该宏表明存储在某些局部变量中的值在优化时不应该被编译器强制释放。

我们将局部变量标记为id类型或者是指向ObjC对象类型的指针，以便存储在这些局部变量中的值在优化时不会被编译器强制释放。相反，这些值会在变量再次被赋值之前或者局部变量的作用域结束之前都会被保存。

### 关联对象行为

	enum {
	   OBJC_ASSOCIATION_ASSIGN  = 0,
	   OBJC_ASSOCIATION_RETAIN_NONATOMIC  = 1,
	   OBJC_ASSOCIATION_COPY_NONATOMIC  = 3,
	   OBJC_ASSOCIATION_RETAIN  = 01401,
	   OBJC_ASSOCIATION_COPY  = 01403
	};

这几个值在前面已介绍过，在此不再重复。

## 总结

至此，本系列对runtime的整理已完结。当然这只是对runtime的一些基础知识的归纳，力图起个抛砖引玉的作用。还有许多关于runtime有意思东西还需要读者自己去探索发现。

***注：如有不对之处，还请指正，欢迎加QQ好友：1318202110(南峰子)***

## 参考

1. [Objective-C Runtime Reference](https://developer.apple.com/library/ios/documentation/Cocoa/Reference/ObjCRuntimeRef/)
2. [iOS:Objective-C中Self和Super详解](http://blog.csdn.net/itianyi/article/details/8678452
)
3. [Objective-C的动态特性](http://www.cocoachina.com/industry/20130819/6824.html)