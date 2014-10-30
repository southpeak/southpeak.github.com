---

layout: post

title: "Objective-C Runtime 运行时之二：成员变量与属性"

date: 2014-10-30 16:03:21 +0800

comments: true

categories: iOS

---

在前面一篇文章中，我们介绍了Runtime中与类和对象相关的内容，从这章开始，我们将讨论类实现细节相关的内容，主要包括类中成员变量，属性，方法，协议与分类的实现。

本章的主要内容将聚集在Runtime对成员变量与属性的处理。在讨论之前，我们先介绍一个重要的概念：类型编码。

## 类型编码(Type Encoding)

作为对Runtime的补充，编译器将每个方法的返回值和参数类型编码为一个字符串，并将其与方法的selector关联在一起。这种编码方案在其它情况下也是非常有用的，因此我们可以使用@encode编译器指令来获取它。当给定一个类型时，@encode返回这个类型的字符串编码。这些类型可以是诸如int、指针这样的基本类型，也可以是结构体、类等类型。事实上，任何可以作为sizeof()操作参数的类型都可以用于@encode()。

在Objective-C Runtime Programming Guide中的[Type Encoding](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1)一节中，列出了Objective-C中所有的类型编码。需要注意的是这些类型很多是与我们用于存档和分发的编码类型是相同的。但有一些不能在存档时使用。

*注：Objective-C不支持long double类型。@encode(long double)返回d，与double是一样的。*

一个数组的类型编码位于方括号中；其中包含数组元素的个数及元素类型。如以下示例：

	float a[] = {1.0, 2.0, 3.0};
    NSLog(@"array encoding type: %s", @encode(typeof(a)));
    
输出是：

	2014-10-28 11:44:54.731 RuntimeTest[942:50791] array encoding type: [3f]
	
其它类型可参考[Type Encoding](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1)，在此不细说。

另外，还有些编码类型，@encode虽然不会直接返回它们，但它们可以作为协议中声明的方法的类型限定符。可以参考[Type Encoding](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1)。

对于属性而言，还会有一些特殊的类型编码，以表明属性是只读、拷贝、retain等等，详情可以参考[Property Type String](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW6)。

## 成员变量、属性

Runtime中关于成员变量和属性的相关数据结构并不多，只有三个，并且都很简单。不过还有个非常实用但可能经常被忽视的特性，即关联对象，我们将在这小节中详细讨论。

### 基础数据类型

#### Ivar

Ivar是表示实例变量的类型，其实际是一个指向objc_ivar结构体的指针，其定义如下：

	typedef struct objc_ivar *Ivar;

	struct objc_ivar {
	    char *ivar_name               	OBJC2_UNAVAILABLE;	// 变量名
	    char *ivar_type             	OBJC2_UNAVAILABLE;	// 变量类型
	    int ivar_offset            		OBJC2_UNAVAILABLE;	// 基地址偏移字节
	#ifdef __LP64__
	    int space                 		OBJC2_UNAVAILABLE;
	#endif
	} 

#### objc_property_t

objc_property_t是表示Objective-C声明的属性的类型，其实际是指向objc_property结构体的指针，其定义如下：

	typedef struct objc_property *objc_property_t;

#### objc_property_attribute_t

objc_property_attribute_t定义了属性的特性(attribute)，它是一个结构体，定义如下：

	typedef struct {
	    const char *name;           // 特性名
	    const char *value;          // 特性值
	} objc_property_attribute_t;

### 关联对象(Associated Object)

关联对象是Runtime中一个非常实用的特性，不过可能很容易被忽视。

关联对象类似于成员变量，不过是在运行时添加的。我们通常会把成员变量(Ivar)放在类声明的头文件中，或者放在类实现的@implementation后面。但这有一个缺点，我们不能在分类中添加成员变量。如果我们尝试在分类中添加新的成员变量，编译器会报错。

我们可能希望通过使用(甚至是滥用)全局变量来解决这个问题。但这些都不是Ivar，因为他们不会连接到一个单独的实例。因此，这种方法很少使用。

Objective-C针对这一问题，提供了一个解决方案：即关联对象(Associated Object)。

我们可以把关联对象想象成一个Objective-C对象(如字典)，这个对象通过给定的key连接到类的一个实例上。不过由于使用的是C接口，所以key是一个void指针(const void *)。我们还需要指定一个内存管理策略，以告诉Runtime如何管理这个对象的内存。这个内存管理的策略可以由以下值指定：

	OBJC_ASSOCIATION_ASSIGN
	OBJC_ASSOCIATION_RETAIN_NONATOMIC
	OBJC_ASSOCIATION_COPY_NONATOMIC
	OBJC_ASSOCIATION_RETAIN
	OBJC_ASSOCIATION_COPY
	
当宿主对象被释放时，会根据指定的内存管理策略来处理关联对象。如果指定的策略是assign，则宿主释放时，关联对象不会被释放；而如果指定的是retain或者是copy，则宿主释放时，关联对象会被释放。我们甚至可以选择是否是自动retain/copy。当我们需要在多个线程中处理访问关联对象的多线程代码时，这就非常有用了。

我们将一个对象连接到其它对象所需要做的就是下面两行代码：

	static char myKey;
 
	objc_setAssociatedObject(self, &myKey, anObject, OBJC_ASSOCIATION_RETAIN);
	
在这种情况下，self对象将获取一个新的关联的对象anObject，且内存管理策略是自动retain关联对象，当self对象释放时，会自动release关联对象。另外，如果我们使用同一个key来关联另外一个对象时，也会自动释放之前关联的对象，这种情况下，先前的关联对象会被妥善地处理掉，并且新的对象会使用它的内存。

	id anObject = objc_getAssociatedObject(self, &myKey);
	
我们可以使用objc_removeAssociatedObjects函数来移除一个关联对象，或者使用objc_setAssociatedObject函数将key指定的关联对象设置为nil。

我们下面来用实例演示一下关联对象的使用方法。

假定我们想要动态地将一个Tap手势操作连接到任何UIView中，并且根据需要指定点击后的实际操作。这时候我们就可以将一个手势对象及操作的block对象关联到我们的UIView对象中。这项任务分两部分。首先，如果需要，我们要创建一个手势识别对象并将它及block做为关联对象。如下代码所示：

	- (void)setTapActionWithBlock:(void (^)(void))block
	{
		UITapGestureRecognizer *gesture = objc_getAssociatedObject(self, &kDTActionHandlerTapGestureKey);
	 
		if (!gesture)
		{
			gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(__handleActionForTapGesture:)];
			[self addGestureRecognizer:gesture];
			objc_setAssociatedObject(self, &kDTActionHandlerTapGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
		}
	 
		objc_setAssociatedObject(self, &kDTActionHandlerTapBlockKey, block, OBJC_ASSOCIATION_COPY);
	}
	
这段代码检测了手势识别的关联对象。如果没有，则创建并建立关联关系。同时，将传入的块对象连接到指定的key上。注意block对象的关联内存管理策略。

手势识别对象需要一个target和action，所以接下来我们定义处理方法：

	- (void)__handleActionForTapGesture:(UITapGestureRecognizer *)gesture
	{
		if (gesture.state == UIGestureRecognizerStateRecognized)
		{
			void(^action)(void) = objc_getAssociatedObject(self, &kDTActionHandlerTapBlockKey);
	 
			if (action)
			{
				action();
			}
		}
	}
	
我们需要检测手势识别对象的状态，因为我们只需要在点击手势被识别出来时才执行操作。

从上面的例子我们可以看到，关联对象使用起来并不复杂。它让我们可以动态地增强类现有的功能。我们可以在实际编码中灵活地运用这一特性。

### 成员变量、属性的操作方法

#### 成员变量

成员变量操作包含以下函数：

	// 获取成员变量名
	const char * ivar_getName ( Ivar v );
	
	// 获取成员变量类型编码
	const char * ivar_getTypeEncoding ( Ivar v );
	
	// 获取成员变量的偏移量
	ptrdiff_t ivar_getOffset ( Ivar v );
	
● ivar_getOffset函数，对于类型id或其它对象类型的实例变量，可以调用object_getIvar和object_setIvar来直接访问成员变量，而不使用偏移量。

#### 关联对象

关联对象操作函数包括以下：

	// 设置关联对象
	void objc_setAssociatedObject ( id object, const void *key, id value, objc_AssociationPolicy policy );
	
	// 获取关联对象
	id objc_getAssociatedObject ( id object, const void *key );
	
	// 移除关联对象
	void objc_removeAssociatedObjects ( id object );
	
关联对象及相关实例已经在前面讨论过了，在此不再重复。

#### 属性

属性操作相关函数包括以下：

	// 获取属性名
	const char * property_getName ( objc_property_t property );
	
	// 获取属性特性描述字符串
	const char * property_getAttributes ( objc_property_t property );
	
	// 获取属性中指定的特性
	char * property_copyAttributeValue ( objc_property_t property, const char *attributeName );
	
	// 获取属性的特性列表
	objc_property_attribute_t * property_copyAttributeList ( objc_property_t property, unsigned int *outCount );
	
● property_copyAttributeValue函数，返回的char *在使用完后需要调用free()释放。
● property_copyAttributeList函数，返回值在使用完后需要调用free()释放。

## 实例

假定这样一个场景，我们从服务端两个不同的接口获取相同的字典数据，但这两个接口是由两个人写的，相同的信息使用了不同的字段表示。我们在接收到数据时，可将这些数据保存在相同的对象中。对象类如下定义：

	@interface MyObject: NSObject
	
	@property (nonatomic, copy) NSString    *   name;                  
	@property (nonatomic, copy) NSString    *   status;                 
	
	@end
	
接口A、B返回的字典数据如下所示：

	@{@"name1": "张三", @"status1": @"start"}
	
	@{@"name2": "张三", @"status2": @"end"}
	
通常的方法是写两个方法分别做转换，不过如果能灵活地运用Runtime的话，可以只实现一个转换方法，为此，我们需要先定义一个映射字典(全局变量)

	static NSMutableDictionary *map = nil;
	
	@implementation MyObject
	
	+ (void)load
	{
	    map = [NSMutableDictionary dictionary];
	    
	    map[@"name1"]                = @"name";
	    map[@"status1"]              = @"status";
	    map[@"name2"]                = @"name";
	    map[@"status2"]              = @"status";
	}
	
	@end
	
上面的代码将两个字典中不同的字段映射到MyObject中相同的属性上，这样，转换方法可如下处理：

	- (void)setDataWithDic:(NSDictionary *)dic
	{
	    [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
	        
	        NSString *propertyKey = [self propertyForKey:key];
	        
	        if (propertyKey)
	        {
	            objc_property_t property = class_getProperty([self class], [propertyKey UTF8String]);
	            
	            // TODO: 针对特殊数据类型做处理
	            NSString *attributeString = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
	            
	            ...
	            
	            [self setValue:obj forKey:propertyKey];
	        }
	    }];
	}
	
当然，一个属性能否通过上面这种方式来处理的前提是其支持KVC。

## 小结

本章中我们讨论了Runtime中与成员变量和属性相关的内容。成员变量与属性是类的数据基础，合理地使用Runtime中的相关操作能让我们更加灵活地来处理与类数据相关的工作。

## 参考

1. [Objective-C Runtime Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Introduction/Introduction.html)
2. [Associated Objects](http://www.cocoanetics.com/2012/06/associated-objects/)
