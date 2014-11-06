---

layout: post

title: "Objective-C Runtime 运行时之四：Method Swizzling"

date: 2014-11-06 21:36:17 +0800

comments: true

categories: iOS

---

理解Method Swizzling是学习runtime机制的一个很好的机会。在此不多做整理，仅翻译由Mattt Thompson发表于nshipster的[Method Swizzling](http://nshipster.com/method-swizzling/)一文。

Method Swizzling是改变一个selector的实际实现的技术。通过这一技术，我们可以在运行时通过修改类的分发表中selector对应的函数，来修改方法的实现。

例如，我们想跟踪在程序中每一个view controller展示给用户的次数：当然，我们可以在每个view controller的viewDidAppear中添加跟踪代码；但是这太过麻烦，需要在每个view controller中写重复的代码。创建一个子类可能是一种实现方式，但需要同时创建UIViewController, UITableViewController, UINavigationController及其它UIKit中view controller的子类，这同样会产生许多重复的代码。

这种情况下，我们就可以使用Method Swizzling，如在代码所示：

	#import <objc/runtime.h>
	@implementation UIViewController (Tracking)
	+ (void)load {	    static dispatch_once_t onceToken;	    dispatch_once(&onceToken, ^{	        Class class = [self class];
			// When swizzling a class method, use the following:	        // Class class = object_getClass((id)self);
			SEL originalSelector = @selector(viewWillAppear:);	        SEL swizzledSelector = @selector(xxx_viewWillAppear:);
			Method originalMethod = class_getInstanceMethod(class, originalSelector);	        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
			BOOL didAddMethod =	            class_addMethod(class,	                originalSelector,	                method_getImplementation(swizzledMethod),	                method_getTypeEncoding(swizzledMethod));
			if (didAddMethod) {	            class_replaceMethod(class,	                swizzledSelector,	                method_getImplementation(originalMethod),	                method_getTypeEncoding(originalMethod));	        } else {	            method_exchangeImplementations(originalMethod, swizzledMethod);	        }	    });	}
	#pragma mark - Method Swizzling
	- (void)xxx_viewWillAppear:(BOOL)animated {	    [self xxx_viewWillAppear:animated];	    NSLog(@"viewWillAppear: %@", self);	}
	@end

在这里，我们通过method swizzling修改了UIViewController的@selector(viewWillAppear:)对应的函数指针，使其实现指向了我们自定义的xxx_viewWillAppear的实现。这样，当UIViewController及其子类的对象调用viewWillAppear时，都会打印一条日志信息。

上面的例子很好地展示了使用method swizzling来一个类中注入一些我们新的操作。当然，还有许多场景可以使用method swizzling，在此不多举例。在此我们说说使用method swizzling需要注意的一些问题：

## Swizzling应该总是在+load中执行

在Objective-C中，运行时会自动调用每个类的两个方法。+load会在类初始加载时调用，+initialize会在第一次调用类的类方法或实例方法之前被调用。这两个方法是可选的，且只有在实现了它们时才会被调用。由于method swizzling会影响到类的全局状态，因此要尽量避免在并发处理中出现竞争的情况。+load能保证在类的初始化过程中被加载，并保证这种改变应用级别的行为的一致性。相比之下，+initialize在其执行时不提供这种保证--事实上，如果在应用中没为给这个类发送消息，则它可能永远不会被调用。

## Swizzling应该总是在dispatch_once中执行

与上面相同，因为swizzling会改变全局状态，所以我们需要在运行时采取一些预防措施。原子性就是这样一种措施，它确保代码只被执行一次，不管有多少个线程。GCD的dispatch_once可以确保这种行为，我们应该将其作为method swizzling的最佳实践。

## 选择器、方法与实现

在Objective-C中，选择器(selector)、方法(method)和实现(implementation)是运行时中一个特殊点，虽然在一般情况下，这些术语更多的是用在消息发送的过程描述中。

以下是Objective-C Runtime Reference中的对这几个术语一些描述：

1. Selector(typedef struct objc_selector *SEL)：用于在运行时中表示一个方法的名称。一个方法选择器是一个C字符串，它是在Objective-C运行时被注册的。选择器由编译器生成，并且在类被加载时由运行时自动做映射操作。
2. Method(typedef struct objc_method *Method)：在类定义中表示方法的类型
3. Implementation(typedef id (*IMP)(id, SEL, ...))：这是一个指针类型，指向方法实现函数的开始位置。这个函数使用为当前CPU架构实现的标准C调用规范。每一个参数是指向对象自身的指针(self)，第二个参数是方法选择器。然后是方法的实际参数。

理解这几个术语之间的关系最好的方式是：一个类维护一个运行时可接收的消息分发表；分发表中的每个入口是一个方法(Method)，其中key是一个特定名称，即选择器(SEL)，其对应一个实现(IMP)，即指向底层C函数的指针。

为了swizzle一个方法，我们可以在分发表中将一个方法的现有的选择器映射到不同的实现，而将该选择器对应的原始实现关联到一个新的选择器中。

## 调用_cmd

我们回过头来看看前面新的方法的实现代码：

	- (void)xxx_viewWillAppear:(BOOL)animated {	    [self xxx_viewWillAppear:animated];	    NSLog(@"viewWillAppear: %@", NSStringFromClass([self class]));	}

咋看上去是会导致无限循环的。但令人惊奇的是，并没有出现这种情况。在swizzling的过程中，方法中的[self xxx_viewWillAppear:animated]已经被重新指定到UIViewController类的-viewWillAppear:中。在这种情况下，不会产生无限循环。不过如果我们调用的是[self viewWillAppear:animated]，则会产生无限循环，因为这个方法的实现在运行时已经被重新指定为xxx_viewWillAppear:了。

## 注意事项

Swizzling通常被称作是一种黑魔法，容易产生不可预知的行为和无法预见的后果。虽然它不是最安全的，但如果遵从以下几点预防措施的话，还是比较安全的：

1. 总是调用方法的原始实现(除非有更好的理由不这么做)：API提供了一个输入与输出约定，但其内部实现是一个黑盒。Swizzle一个方法而不调用原始实现可能会打破私有状态底层操作，从而影响到程序的其它部分。
2. 避免冲突：给自定义的分类方法加前缀，从而使其与所依赖的代码库不会存在命名冲突。
3. 明白是怎么回事：简单地拷贝粘贴swizzle代码而不理解它是如何工作的，不仅危险，而且会浪费学习Objective-C运行时的机会。阅读Objective-C Runtime Reference和查看<objc/runtime.h>头文件以了解事件是如何发生的。
4. 小心操作：无论我们对Foundation, UIKit或其它内建框架执行Swizzle操作抱有多大信心，需要知道在下一版本中许多事可能会不一样。

