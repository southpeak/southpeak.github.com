---

layout: post

title: "UIApearance"

date: 2015-07-20 00:01:05 +0800

comments: true

categories: iOS

---

文章开头先援引一下Mattt Thompson大神在[UIApearance](http://nshipster.com/uiappearance/)里的一句话吧：

	Users will pay a premium for good-looking software.

就如同大多数人喜欢看帅哥美女一样，一款App能不能被接受，长得怎样很重要。虽然大家都明白“人不可貌相”这个理，但大多数人其实还是视觉动物。用户体验用户体验，如果都让用户看得不爽了，又何谈用户体验呢？所以...所以...哎，我也只能在这默默地码字了。

在iOS 5以前，我们想去自定义系统控件的外观是一件麻烦的事。如果想统一地改变系统控件的外观，我们可能会想各种办法，如去继承现有的控件类，并在子类中修改，或者甚至于动用method swizzling这样高大上的方法。不过，苹果在iOS 5之后为我们提供了一种新的方法：UIAppearance，让这些事简单了不少。在这里，我们就来总结一下吧。

## UIApearance是作用

UIApearance实际上是一个协议，我们可以用它来获取一个类的外观代理(appearance proxy)。为什么说是一个类，而不明确说是一个视图或控件呢？这是因为有些非视图对象(如UIBarButtonItem)也可以实现这个协议，来定义其所包含的视图对象的外观。我们可以给这个类的外观代理发送一个修改消息，来自定义一个类的实例的外观。

我们以系统定义的控件UIButton为例，根据我们的使用方式，可以通过UIAppearance修改整个应用程序中所有UIButton的外观，也可以修改某一特定容器类中所有UIButton的外观(如UIBarButtonItem)。不过需要注意的是，这种修改只会影响到那些执行UIAppearance操作之后添加到我们的视图层级架构中的视图或控件，而不会影响到修改之前就已经添加的对象。因此，如果要修改特定的视图，先确保该视图在使用UIAppearance后才通过addSubview添加到视图层级架构中。

## UIAppearance的使用

如上面所说，有两种方式来自定义对象的外观：针对某一类型的所有实例；针对包含在某一容器类的实例中的某一类型的实例。讲得有点绕，我把文档的原文贴出来吧。

	for all instances, and for instances contained within an instance of a container class.
	
为此，UIAppearance声明了两个方法。如果我们想自定义一个类所有实例的外观，则可以使用下面这个方法：

	// swift
	static func appearance() -> Self
	
	// Objective-C
	+ (instancetype)appearance
	
例如，如果我们想修改UINavigationBar的所有实例的背影颜色和标题外观，则可以如下实现：

	UINavigationBar.appearance().barTintColor = UIColor(red: 104.0/255.0, green: 224.0/255.0, blue: 231.0/255.0, alpha: 1.0)
	
    UINavigationBar.appearance().titleTextAttributes = [
        NSFontAttributeName: UIFont.systemFontOfSize(15.0),
        NSForegroundColorAttributeName: UIColor.whiteColor()
    ]

我们也可以指定一类容器，在这个容器中，我们可以自定义一个类的所有实例的外观。我们可以使用下面这个方法：

	+ (instancetype)appearanceWhenContainedIn:(Class<UIAppearanceContainer>)ContainerClass, ...
	
如，我们想修改导航栏中所有的按钮的外面，则可以如下处理：

	[[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil]
       setBackgroundImage:myNavBarButtonBackgroundImage forState:state barMetrics:metrics];
       
	[[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], [UIPopoverController class], nil]
        setBackgroundImage:myPopoverNavBarButtonBackgroundImage forState:state barMetrics:metrics];
        
	[[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], nil]
        setBackgroundImage:myToolbarButtonBackgroundImage forState:state barMetrics:metrics];
        
	[[UIBarButtonItem appearanceWhenContainedIn:[UIToolbar class], [UIPopoverController class], nil]
        setBackgroundImage:myPopoverToolbarButtonBackgroundImage forState:state barMetrics:metrics];
        
注意这个方法的参数是一个可变参数，因此，它可以同时设置多个容器。
	
我们仔细看文档，发现这个方法没有swift版本，至少我在iOS 8.x的SDK中没有找到对应的方法。呵呵，如果想在iOS 8.x以下的系统用swift来调用appearanceWhenContainedIn，那就乖乖地用混编吧。

不过在iOS 9的SDK中(记录一下，今天是2015.07.18)，又把这个方法给加上了，不过这回参数换成了数组，如下所示：

	@available(iOS 9.0, *)
    static func appearanceWhenContainedInInstancesOfClasses(containerTypes: [AnyObject.Type]) -> Self
    
嗯，这里有个问题，我在Xcode 7.0 beta 3版本上测试swift版本的这个方法时，把将其放在启动方法里面，如下所示：

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // 此处会崩溃，提示EXC_BAD_ACCESS
		let barButtonItemAppearance = UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([UINavigationBar.self])
   
		let attributes = [
		    NSFontAttributeName: UIFont.systemFontOfSize(13.0),
		    NSForegroundColorAttributeName: UIColor.whiteColor()
		]
    
		barButtonItemAppearance.setTitleTextAttributes(attributes, forState: .Normal)
        
        return true
    }
    
程序崩溃了，在appearanceWhenContainedInInstancesOfClasses这行提示EXC_BAD_ACCESS。既然是内存问题，那就找找吧。我做了如下几个测试：

1.拆分UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses，在其前面加了如下几行代码：

	let appearance = UIBarButtonItem.appearance()
        
    let arr: [AnyObject.Type] = [UINavigationBar.self, UIToolbar.self]
    
    print(arr)
    
可以看到除了appearanceWhenContainedInInstancesOfClasses自身外，其它几个元素都是没问题的。

2.将这段拷贝到默认的ViewController中，运行。同样崩溃了。

3.在相同环境下(Xcode 7.0 beta 3 + iOS 9.0)，用Objective-C对应的方法试了一下，如下：

	- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	    
	    [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]];
	    
	    return YES;
	}

程序很愉快地跑起来了。

额，我能把这个归结为版本不稳定的缘故么？等到稳定版出来后再研究一下吧。

## 支持UIAppearance的组件

从iOS 5.0后，有很多iOS的API都已经支持UIAppearance的代理方法了，Mattt Thompson在[UIApearance](http://nshipster.com/uiappearance/)中，给我们提供了以下两行脚本代码，可以获取所有支持UI_APPEARANCE_SELECTOR的方法(我们将在下面介绍UI_APPEARANCE_SELECTOR)：

	$ cd /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS*.sdk/System/Library/Frameworks/UIKit.framework/Headers
	
	$ grep -H UI_APPEARANCE_SELECTOR ./* | sed 's/ __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0) UI_APPEARANCE_SELECTOR;//'
	
大家可以试一下，我这里列出部分输出：

	./UIActivityIndicatorView.h:@property (readwrite, nonatomic, retain) UIColor *color NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
	./UIAppearance.h:/* To participate in the appearance proxy API, tag your appearance property selectors in your header with UI_APPEARANCE_SELECTOR.
	./UIAppearance.h:#define UI_APPEARANCE_SELECTOR __attribute__((annotate("ui_appearance_selector")))
	./UIBarButtonItem.h:- (void)setBackgroundImage:(UIImage *)backgroundImage forState:(UIControlState)state barMetrics:(UIBarMetrics)barMetrics NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
	./UIBarButtonItem.h:- (UIImage *)backgroundImageForState:(UIControlState)state barMetrics:(UIBarMetrics)barMetrics NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
	./UIBarButtonItem.h:- (void)setBackgroundImage:(UIImage *)backgroundImage forState:(UIControlState)state style:(UIBarButtonItemStyle)style barMetrics:(UIBarMetrics)barMetrics NS_AVAILABLE_IOS(6_0) UI_APPEARANCE_SELECTOR;
	./UIBarButtonItem.h:- (UIImage *)backgroundImageForState:(UIControlState)state style:(UIBarButtonItemStyle)style barMetrics:(UIBarMetrics)barMetrics NS_AVAILABLE_IOS(6_0) UI_APPEARANCE_SELECTOR;
	./UIBarButtonItem.h:- (void)setBackgroundVerticalPositionAdjustment:(CGFloat)adjustment forBarMetrics:(UIBarMetrics)barMetrics NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; 
	......
	
大家还可以在[这里](https://gist.github.com/mattt/5135521)查看iOS 7.0下的清单。

## 自定义类实现UIAppearance

我们可以自定义一个类，并让这个类支持UIAppearance。为此，我们需要做两件事：

1. 让我们的类实现UIAppearanceContainer协议
2. 如果是在Objective-C中，则将相关的方法用UI_APPEARANCE_SELECTOR来标记。而在Swift中，需要在对应的属性或方法前面加上dynamic。

当然，要让我们的类可以使用appearance(或appearanceWhenContainedInInstancesOfClasses)来获取自己的类，则还需要实现UIAppearance协议。

在这里，我们来定义一个带边框的Label，通过UIAppearance来设置它的默认边框。实际上，UIView已经实现了UIAppearance和UIAppearanceContainer协议。因此，我们在其子类中不再需要显式地去声明实现这两个接口。

我们的Label的声明如下：

	// RoundLabel.h
	
	@interface RoundLabel : UILabel
	
	@property (nonatomic, assign) CGFloat borderWidth UI_APPEARANCE_SELECTOR;
	@property (nonatomic, assign) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;
	@property (nonatomic, assign) UIColor *borderColor UI_APPEARANCE_SELECTOR;
	
	@end

具体的实现如下：

	@implementation RoundLabel
	
	- (void)drawRect:(CGRect)rect {
	    
	    [super drawRect:rect];
	    
	    self.layer.borderColor = _borderColor.CGColor;
	    self.layer.cornerRadius = _cornerRadius;
	    self.layer.borderWidth = _borderWidth;
	}
	
	- (void)setBorderWidth:(CGFloat)borderWidth {
	    
	    _borderWidth = borderWidth;
	}
	
	- (void)setCornerRadius:(CGFloat)cornerRadius {
	    
	    _cornerRadius = cornerRadius;
	}
	
	- (void)setRectColor:(UIColor *)rectColor {
	    
	    _borderColor = rectColor;
	}
	
	@end
	
我们在drawRect:设置Label的边框，这样RoundLabel的所有实例就可以使用默认的边框配置属性了。

然后，我们可以在AppDelegate或者其它某个位置来设置RoundLabel的默认配置，如下所示：

	UIColor *color = [UIColor colorWithRed:104.0/255.0 green:224.0/255.0 blue:231.0/255.0 alpha:1.0f];
    
    [RoundLabel appearance].cornerRadius = 5.0f;
    [RoundLabel appearance].borderColor = color;
    [RoundLabel appearance].borderWidth = 1.0f;
    
当然，我们在使用RoundLabel时，可以根据实际需要再修改这几个属性的值。

Swift的实现就简单多了，我们只需要如下处理：

	class RoundLabel: UILabel {
	    
	    dynamic func setBorderColor(color: UIColor) {
	        layer.borderColor = color.CGColor
	    }
	    
	    dynamic func setBorderWidth(width: CGFloat) {
	        layer.borderWidth = width
	    }
	    
	    dynamic func setCornerRadius(radius: CGFloat) {
	        layer.cornerRadius = radius
	    }
	}

在UIAppearanceContainer的官方文档中，有对支持UIAppearance的方法作格式限制，具体要求如下：

	// Swift
	func propertyForAxis1(axis1: IntegerType, axis2: IntegerType, axisN: IntegerType) -> PropertyType
	func setProperty(property: PropertyType, forAxis1 axis1: IntegerType, axis2: IntegerType)
	
	// OBJECTIVE-C
	- (PropertyType)propertyForAxis1:(IntegerType)axis1 axis2:(IntegerType)axis2 … axisN:(IntegerType)axisN;
	- (void)setProperty:(PropertyType)property forAxis1:(IntegerType)axis1 axis2:(IntegerType)axis2 … axisN:(IntegerType)axisN;
	
其中的属性类型可以是iOS的任意类型，包括id, NSInteger, NSUInteger, CGFloat, CGPoint, CGSize, CGRect, UIEdgeInsets或UIOffset。而IntegerType必须是NSInteger或者NSUInteger。如果类型不对，则会抛出异常。

我们可以以UIBarButtonItem为例，它定义了以下方法：

	setTitlePositionAdjustment:forBarMetrics:
	
	backButtonBackgroundImageForState:barMetrics:
	
	setBackButtonBackgroundImage:forState:barMetrics:
	
这些方法就是满足上面所提到的格式。

## Trait Collection

我们查看[UIAppearance](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAppearance_Protocol/)的官方文档，可以看到在iOS 8后，这个协议又新增了两个方法：

	// Swift
	static func appearanceForTraitCollection(_ trait: UITraitCollection) -> Self
	
	// Objective-C
	+ (instancetype)appearanceForTraitCollection:(UITraitCollection *)trait
	
	+ (instancetype)appearanceForTraitCollection:(UITraitCollection *)trait
                             whenContainedIn:(Class<UIAppearanceContainer>)ContainerClass, ...
                             
这两个方法涉及到Trait Collection，具体的内容我们在此不过多的分析。

## 一些深入的东西

了解了怎么去使用UIApearance，现在我们再来了解一下它是怎么运作的。我们跟着[UIAppearance for Custom Views](http://petersteinberger.com/blog/2013/uiappearance-for-custom-views/)一文的思路来走。

我们在以下实现中打一个断点：

	- (void)setBorderWidth:(CGFloat)borderWidth {
	    
	    _borderWidth = borderWidth;
	}
	
然后运行程序。程序启动时，我们发现虽然在AppDelegate中调用了

	[RoundLabel appearance].borderWidth = 1.0f;
	
但实际上，此时程序没有到在此断住。我们再进到Label所在的视图控制器，这时程序在断点处停住了。在这里，我们可以看看方法的调用栈。

![image](http://a2.qpic.cn/psb?/V130i6W71atwfr/zvCjuu0CPc6iekXtdNtrAVBFz*dIoWt.RJszsxFSYBk!/b/dA7ptm1gFgAA&bo=IAPxAQAAAAADB*E!&rf=viewer_4)

在调用栈里面，我们可以看到_UIAppearance这个东东，我们从[iOS-Runtime-Headers](https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/UIKit.framework/_UIAppearance.h)可以找到这个类的定义：

	@interface _UIAppearance : NSObject {
	    NSMutableArray *_appearanceInvocations;
	    NSArray *_containerList;
	    _UIAppearanceCustomizableClassInfo *_customizableClassInfo;
	    NSMapTable *_invocationSources;
	    NSMutableDictionary *_resettableInvocations;
	}
	
其中[_UIAppearanceCustomizableClassInfo](https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/UIKit.framework/_UIAppearanceCustomizableClassInfo.h)存储的是外观对应的类的信息。我们可以看看这个类的声明：

	@interface _UIAppearanceCustomizableClassInfo : NSObject {
	    NSString *_appearanceNodeKey;
	    Class _customizableViewClass;
	    Class _guideClass;
	    unsigned int _hash;
	    BOOL _isCustomizableViewClassRoot;
	    BOOL _isGuideClassRoot;
	}
	
	@property (nonatomic, readonly) NSString *_appearanceNodeKey;
	@property (nonatomic, readonly) Class _customizableViewClass;
	@property (nonatomic, readonly) Class _guideClass;
	@property (nonatomic, readonly) unsigned int _hash;
	
	+ (id)_customizableClassInfoForViewClass:(Class)arg1 withGuideClass:(Class)arg2;
	
	- (id)_appearanceNodeKey;
	- (Class)_customizableViewClass;
	- (Class)_guideClass;
	- (unsigned int)_hash;
	- (id)_superClassInfo;
	- (void)dealloc;
	- (id)description;
	- (unsigned int)hash;
	- (BOOL)isEqual:(id)arg1;
	
	@end
	
在\_UIAppearance中，还有一个\_appearanceInvocations变量，我们可以在Debug中尝试用以下命令来打印出它的信息：

	po [[NSClassFromString(@"_UIAppearance") _appearanceForClass:[RoundLabel class] withContainerList:nil] valueForKey:@"_appearanceInvocations"]
	
我们可以得到以下的信息：

	<__NSArrayM 0x7fd44a5c1f80>(
	<NSInvocation: 0x7fd44a5c1d20>
	return value: {v} void
	target: {@} 0x10b545ae0
	selector: {:} setCornerRadius:
	argument 2: {d} 0.000000
	,
	<NSInvocation: 0x7fd44a5bf300>
	return value: {v} void
	target: {@} 0x10b545ae0
	selector: {:} setBorderColor:
	argument 2: {@} 0x7fd44a5bbb80
	,
	<NSInvocation: 0x7fd44a50b8c0>
	return value: {v} void
	target: {@} 0x10b545ae0
	selector: {:} setBorderWidth:
	argument 2: {d} 0.000000
	
	)
	
可以看到这个数组中存储的实际上是NSInvocation对象，每个对象就是我们在程序中设置的RoundLabel外观的方法信息。
	
在Peter Steinberger的文章中，有提到当我们设置了一个自定义的外观时，[_UIAppearanceRecorder](https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/UIKit.framework/_UIAppearanceRecorder.h)会去保存并跟踪这个设置。我们可以看看\_UIAppearanceRecorder的声明：

	@interface _UIAppearanceRecorder : NSObject {
	    NSString *_classNameToRecord;
	    NSArray *_containerClassNames;
	    NSMutableArray *_customizations;
	    Class _superclassToRecord;
	    NSArray *_unarchivedCustomizations;
	}
	
不过有点可惜的是，我没有从这里找到太多的信息。我用runtime检查了一下这个类中的数据，貌似没有太多东西。可能是姿势不对，我把代码和结果贴出来，大家帮我看看。

	unsigned int outCount = 0;
    
    Class recorderClass = NSClassFromString(@"_UIAppearanceRecorder");
    
    id recorder = [recorderClass performSelector:NSSelectorFromString(@"_sharedAppearanceRecorderForClass::whenContainedIn:") withObject:[RoundLabel class] withObject:nil];

    NSLog(@"_UIAppearanceRecorder instance : %@", recorder);
    
    Ivar *variables = class_copyIvarList(recorderClass, &outCount);
    
    for (int i = 0; i < outCount; i++) {
        Ivar variable = variables[i];
        
        id value = object_getIvar(recorder, variable);
        NSLog(@"variable's name: %s, value: %@", ivar_getName(variable), value);
    }
    
    free(variables);

打印结果：

	UIAppearanceExample2[7600:381708] _UIAppearanceRecorder instance : <_UIAppearanceRecorder: 0x7fa29a718960>
	UIAppearanceExample2[7600:381708] variable's name: _classNameToRecord, value: RoundLabel
	UIAppearanceExample2[7600:381708] variable's name: _superclassToRecord, value: (null)
	UIAppearanceExample2[7600:381708] variable's name: _containerClassNames, value: (null)
	UIAppearanceExample2[7600:381708] variable's name: _customizations, value: (
	)
	UIAppearanceExample2[7600:381708] variable's name: _unarchivedCustomizations, value: (null)

我们回过头再来看看\_UIAppearance的\_appearanceInvocations，我们是否可以这样猜测：UIAppearance是否是通过类似于Swizzling Method这种方式，在运行时去更新视图的默认显示呢？求解。

## 遗留问题

这一小篇遗留下了两个问题：

1. 在swift中如何正确地使用appearanceWhenContainedInInstancesOfClasses方法？我在stackoverflow中没有找到答案。
2. iOS内部是如何用UIAppearance设置的信息来在运行时替换默认的设置的？

如果有答案，还请告知。


## 小结

使用UIAppearance，可以让我们方便地去修改一些视图或控件的默认显示。同样，如果我们打算开发一个视图库，也可能会用到相关的内容。我们可以在库的内部自定义一些UIAppearance的规则来代替手动去修改视图外观。这样，库外部就可以方便的通过UIAppearance来整体修改一个类中视图的外观了。

我在github中搜索UIAppearance相关的实例时，找到了[UISS](https://github.com/robertwijas/UISS)这个开源库，它提供了一种便捷的方式来定义程序的样式。这个库也是基于UIAppearance的。看其介绍，如果我们想自定义一个UIButton的外观，可以使用以下方式：

	{
	    "UIButton":{
	        "titleColor:normal":["white", 0.8],
	        "titleColor:highlighted":"white",
	        "backgroundImage:normal": ["button-background-normal", [0,10,0,10]],
	        "backgroundImage:highlighted": ["button-background-highlighted", [0,10,0,10]],
	        "titleEdgeInsets": [1,0,0,0],
	        "UILabel":{
	            "font":["Copperplate-Bold", 18]
	        }
	    }
	}
	
看着像JSON吧？

具体的我也还没有看，回头抽空再研究研究这个库。

*补充：文章中的示例代码已放到github中，可以在[这里](https://github.com/southpeak/iOS-Dev-Examples/tree/master/UIKit/UIApearance)查看(不保证在iOS 9.0以下能正常进行，嘿嘿)*

### 参考

1. [UIApearance](http://nshipster.com/uiappearance/)
2. [UIAppearance Protocol Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIAppearance_Protocol/)
3. [UIAppearanceContainer Protocol Reference](https://developer.apple.com/library//ios/recipes/UIAppearanceContainer_Protocol/index.html)
4. [UIAppearance for Custom Views](http://petersteinberger.com/blog/2013/uiappearance-for-custom-views/)