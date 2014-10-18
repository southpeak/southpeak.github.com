---

layout: post

title: "instancetype"

date: 2014-10-19 00:26:03 +0800

comments: true

categories: iOS

---

注：原文由Mattt Thompson发表于nshipster：[instancetype](http://nshipster.com/instancetype/)。**文章是2012年写的，所以有些内容现在已不适用。**

在Objective-C中，约定(conventions)不仅仅是编码最佳实践的问题，同时对编译器来说，也是一种隐式说明。

例如，alloc和init两个方法都返回id类型，而在Xcode中，编译器会对它们进行类型检查。这是怎么做到的呢？

在Cocoa中，有一个这样的约定，命名为alloc/init的方法总是返回接收者类的实例。这些方法有一个相关的返回类型。

而类的构造方法(类方法)，虽然他们都是返回id类型，但没有从类型检查中获得好处，因为他们不遵循命名约定。

我们可以试试以下代码：

	[[[NSArray alloc] init] mediaPlaybackAllowsAirPlay]; // 报错： "No visible @interface for `NSArray` declares the selector `mediaPlaybackAllowsAirPlay`"
	
	[[NSArray array] mediaPlaybackAllowsAirPlay]; // (No error) 注：这个方法调用只在老的编译器上成立，新的编译器会报相同的错误。

由于alloc和init遵循返回相关结果类型的约定，所以会对NSArray执行类型检查。然而等价的类构造方法array则不遵循这一约定，只解释为id类型。

id类型在不需要确保类型安全时非常有用，但一旦需要时，就无法处理了。

而另一种方法，即显示声明返回类型(如前面例子中的(NSArray *))稍微改善了一些，但写起来有点麻烦，而且在继承体系中表现得不是很好。

这时编译器就需要去解决这种针对Objective-C类型系统的边界情况了:

instancetype是一个上下文关键字，可用在返回类型中以表示方法返回一个相关的结果类型，如：

	@interface Person
	+ (instancetype)personWithName:(NSString *)name;
	@end
	
使用instancetype，编译器可以正确地知道personWithName:的返回结果是一个Person实例。

我们现在看Foundation中的类构造器，可以发现大部分已经开始使用了instancetype了。新的API，如UICollectionViewLayoutAttributes，都是使用instancetype了。

*注：instancetype与id不同的是，它只能用在方法声明的返回值中。*

#### 更进一步的启示

语言特性是特别有趣的，因为它不清楚在软件设计的更高层次方面会带来什么样的影响。

虽然instancetype看上去非常一般，只是对编译器有用，但也可能被用于一些更聪明的目的。

Jonathan Sterling的文章[this quite interesting article](http://www.jonmsterling.com/posts/2012-02-05-typed-collections-with-self-types-in-objective-c.html)，详细描述了instancetype如何被用于编码静态类型集合，而不需要使用泛型：

	NSURL <MapCollection> *sites = (id)[NSURL mapCollection];
	[sites put:[NSURL URLWithString:@"http://www.jonmsterling.com/"]
	        at:@"jon"];
	[sites put:[NSURL URLWithString:@"http://www.nshipster.com/"]
	        at:@"nshipster"];
	
	NSURL *jonsSite = [sites at:@"jon"]; // => http://www.jonmsterling.com/
	
静态类型集合使得API更有表现力，这样开发者将不再需要去确定集合中的参数可以使用使用类型的对象了。

不管这会不会成为Objective-C公认的约定，诸如instancetype这样一个低层特性可用于改变语言的形态已是非常棒的一件事了。