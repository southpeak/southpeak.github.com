---

layout: post

title: "iOS知识小集 第三期 (2015.06.30)"

date: 2015-06-30 00:15:14 +0800

comments: true

categories: iOS

---

Swift2出来了，还是得与时俱进啊，不然就成老古董了。再者它开源了，又有事情要做了。当个程序猿真是累啊，一直在追，可从来没追上，刚有那么点念想了，人家又踩了脚油门。

一个月又要过去了，说好的一月两到三篇的，看来希望也是有点渺茫了。本来想好好整理下僵尸对象的内容，看看时间也不多了，也只好放到后面了。这一期没啥好内容，质量也不高，大家凑合着看吧，有疏漏还请大家指出，我一定好好改正。

这一期主要有三个内容：

1. Tint Color
2. Build Configurations in Swift
3. 键盘事件

## Tint Color

在iOS 7后，UIView新增加了一个tintColor属性，这个属性定义了一个非默认的着色颜色值，其值的设置会影响到以视图为根视图的整个视图层次结构。它主要是应用到诸如app图标、导航栏、按钮等一些控件上，以获取一些有意思的视觉效果。

tintColor属性的声明如下：

	var tintColor: UIColor!
	
默认情况下，一个视图的tintColor是为nil的，这意味着视图将使用父视图的tint color值。当我们指定了一个视图的tintColor后，这个色值会自动传播到视图层次结构(以当前视图为根视图)中所有的子视图上。如果系统在视图层次结构中没有找到一个非默认的tintColor值，则会使用系统定义的颜色值(蓝色，RGB值为[0,0.478431,1]，我们可以在IB中看到这个颜色)。因此，这个值总是会返回一个颜色值，即我们没有指定它。

与tintColor属性相关的还有个tintAdjustmentMode属性，它是一个枚举值，定义了tint color的调整模式。其声明如下：

	var tintAdjustmentMode: UIViewTintAdjustmentMode
	
枚举UIViewTintAdjustmentMode的定义如下：

	enum UIViewTintAdjustmentMode : Int {
	    case Automatic			// 视图的着色调整模式与父视图一致
	    case Normal				// 视图的tintColor属性返回完全未修改的视图着色颜色
	    case Dimmed				// 视图的tintColor属性返回一个去饱和度的、变暗的视图着色颜色
	}

因此，当tintAdjustmentMode属性设置为Dimmed时，tintColor的颜色值会自动变暗。而如果我们在视图层次结构中没有找到默认值，则该值默认是Normal。

与tintColor相关的还有一个tintColorDidChange方法，其声明如下：

	func tintColorDidChange()
	
这个方法会在视图的tintColor或tintAdjustmentMode属性改变时自动调用。另外，如果当前视图的父视图的tintColor或tintAdjustmentMode属性改变时，也会调用这个方法。我们可以在这个方法中根据需要去刷新我们的视图。

### 示例

接下来我们通过示例来看看tintColor的强大功能(示例盗用了Sam Davies写的一个例子，具体可以查看[iOS7 Day-by-Day :: Day 6 :: Tint Color](https://www.shinobicontrols.com/blog/posts/2013/09/27/ios7-day-by-day-day-6-tint-color)，我就负责搬砖，用swift实现了一下，代码可以在[这里](https://github.com/southpeak/iOS-Dev-Examples/tree/master/UIKit/UIView/1.%20TintColorExample)下载)。

先来看看最终效果吧(以下都是盗图，请见谅，太懒了)：

![image](https://www.shinobicontrols.com/media/371241/tint_color_image_1_350x621.jpg)

这个界面包含的元素主要有UIButton, UISlider, UIProgressView, UIStepper, UIImageView, ToolBar和一个自定义的子视图CustomView。接下来我们便来看看修改视图的tintColor会对这些控件产生什么样的影响。

在ViewController的viewDidLoad方法中，我们做了如下设置：

	override func viewDidLoad() {
        super.viewDidLoad()
        
        println("\(self.view.tintAdjustmentMode.rawValue)")         // 输出：1
        println("\(self.view.tintColor)")                           // 输出：UIDeviceRGBColorSpace 0 0.478431 1 1
        
        self.view.tintAdjustmentMode = .Normal
        self.dimTintSwitch?.on = false
        
        // 加载图片
        var shinobiHead = UIImage(named: "shinobihead")
        // 设置渲染模式
        shinobiHead = shinobiHead?.imageWithRenderingMode(.AlwaysTemplate)
        
        self.tintedImageView?.image = shinobiHead
        self.tintedImageView?.contentMode = .ScaleAspectFit
    }

首先，我们尝试打印默认的tintColor和tintAdjustmentMode，分别输出了[UIDeviceRGBColorSpace 0 0.478431 1 1]和1，这是在我们没有对整个视图层次结构设置任何tint color相关的值的情况下的输出。可以看到，虽然我们没有设置tintColor，但它仍然返回了系统的默认值；而tintAdjustmentMode则默认返回Normal的原始值。

接下来，我们显式设置tintAdjustmentMode的值为Normal，同时设置UIImageView的图片及渲染模式。

当我们点击"Change Color"按钮时，会执行以下的事件处理方法：

	@IBAction func changeColorHandler(sender: AnyObject) {
        
        let hue = CGFloat(arc4random() % 256) / 256.0
        let saturation = CGFloat(arc4random() % 128) / 256.0 + 0.5
        let brightness = CGFloat(arc4random() % 128) / 256.0 + 0.5
        
        let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
        self.view.tintColor = color
        updateViewConstraints()
    }

	private func updateProgressViewTint() {
        self.progressView?.progressTintColor = self.view.tintColor
    }
    
这段代码主要是随机生成一个颜色值，并赋值给self.view的tintColor属性，同时去更新进度条的tintColor值。

*注：有些控件的特定组成部件的tint color由特定的属性控制，例如进度就有2个tint color：一个用于进度条本身，另一个用于背景。*

点击"Change Color"按钮，可得到以下效果：

![image](https://www.shinobicontrols.com/media/371246/tint_color_image_2_350x621.jpg)

可以看到，我们在示例中并有没手动去设置UIButton, UISlider, UIStepper, UIImageView, ToolBar等子视图的颜色值，但随着self.view的tintColor属性颜色值的变化，这些控件的外观也同时跟着改变。也就是说self.view的tintColor属性颜色值的变化，影响到了以self.view为根视图的整个视图层次结果中所有子视图的外观。

看来tintColor还是很强大的嘛。

在界面中还有个UISwitch，这个是用来开启关闭dim tint的功能，其对应处理方法如下：

	@IBAction func dimTimtHandler(sender: AnyObject) {
        if let isOn = self.dimTintSwitch?.on {
            
            self.view.tintAdjustmentMode = isOn ? .Dimmed : .Normal
        }
        
        updateViewConstraints()
    }
    
当tintAdjustmentMode设置Dimmed时，其实际的效果是整个色值都变暗(此处无图可盗)。

另外，我们在子视图CustomView中重写了tintColorDidChange方法，以监听tintColor的变化，以更新我们的自定义视图，其实现如下：

	override func tintColorDidChange() {
        tintColorLabel.textColor = self.tintColor
        tintColorBlock.backgroundColor = self.tintColor
    }
    
所以方框和"Tint color label"颜色是跟着子视图的tintColor来变化的，而子视图的tintColor又是继承自父视图的。

在这个示例中，比较有意思的是还是对图片的处理。对图像的处理比较简单粗暴，对一个像素而言，如果它的alpha值为1的话，就将它的颜色设置为tint color；如果不为1的话，则设置为透明的。示例中的忍者头像就是这么处理的。不过我们需要设置图片的imageWithRenderingMode属性为AlwaysTemplate，这样渲染图片时会将其渲染为一个模板而忽略它的颜色信息，如代码所示：

	var shinobiHead = UIImage(named: "shinobihead")
    // 设置渲染模式
    shinobiHead = shinobiHead?.imageWithRenderingMode(.AlwaysTemplate)

### 题外话

插个题外话，跟主题关系不大。

在色彩理论(color theory)中，一个tint color是一种颜色与白色的混合。与之类似的是shade color和tone color。shade color是将颜色与黑色混合，tone color是将颜色与灰色混合。它们都是基于Hues色调的。这几个色值的效果如下图所示：

![image](http://www.craftsy.com/blog/wp-content/uploads/2013/04/Screen-Shot-2013-04-30-at-12.46.43-PM.png)

一些基础的理论知识可以参考[Hues, Tints, Tones and Shades: What’s the Difference?](http://www.craftsy.com/blog/2013/05/hues-tints-tones-and-shades/)或更专业的一些文章。

### 小结

如果我们想指定整个App的tint color，则可以通过设置window的tint color。这样同一个window下的所有子视图都会继承此tint color。

当弹出一个alert或者action sheet时，iOS7会自动将后面视图的tint color变暗。此时，我们可以在自定义视图中重写tintColorDidChange方法来执行我们想要的操作。

有些复杂控件，可以有多个tint color，不同的tint color控件不同的部分。如上面提到的UIProgressView，又如navigation bars, tab bars, toolbars, search bars, scope bars等，这些控件的背景着色颜色可以使用barTintColor属性来处理。

### 参考
1. [UIView Class Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIView_Class/index.html#//apple_ref/occ/instp/UIView/tintColor)
2. [iOS7 Day-by-Day :: Day 6 :: Tint Color](https://www.shinobicontrols.com/blog/posts/2013/09/27/ios7-day-by-day-day-6-tint-color)
3. [Appearance and Behavior](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/TransitionGuide/AppearanceCustomization.html)
4. [Tints and shades](https://en.wikipedia.org/wiki/Tints_and_shades)
5. [Hues, Tints, Tones and Shades: What’s the Difference?](http://www.craftsy.com/blog/2013/05/hues-tints-tones-and-shades/)

## Build Configurations in Swift

在Objective-C中，我们经常使用预处理指令来帮助我们根据不同的平台执行不同的代码，以让我们的代码支持不同的平台，如：

	#if TARGET_OS_IPHONE
	
	    #define MAS_VIEW UIView	    	    
	
	#elif TARGET_OS_MAC
	
	    #define MAS_VIEW NSView
	
	#endif
	
在swift中，由于对C语言支持没有Objective-C来得那么友好(暂时不知swift 2到C的支持如何)，所以我们无法像在Objective-C中那样自如而舒坦地使用预处理指令。

不过，swift也提供了自己的方式来支持条件编译，即使用build configurations(构建配置)。Build configurations已经包含了字面量true和false，以及两个平台测试函数os()和arch()。

其中os()用于测试系统类型，可传入的参数包含OSX, iOS, watchOS，所以上面的代码在swift可改成：
	
	#if os(iOS)
		typealias MAS_VIEW = UIView
	#elseif os(OSX)
		typealias MAS_VIEW = NSView
	#endif
	
*注：在WWDC 2014的["Sharing code between iOS and OS X"](https://developer.apple.com/videos/wwdc/2014/)一节(session 233)中，Elizabeth Reid将这种方式称为Shimming*

遗憾的是，os()只能检测系统类型，而无法检测系统的版本，所以这些工作只能放在运行时去处理。关于如何检测系统的版本,Mattt Thompson老大在它的[Swift System Version Checking](http://nshipster.com/swift-system-version-checking/)一文中给了我们答案。
	
我们再来看看arch()。arch()用于测试CPU的架构，可传入的值包括x86_64, arm, arm64, i386。需要注意的是arch(arm)对于ARM 64的设备来说，不会返回true。而arch(i386)在32位的iOS模拟器上编译时会返回true。

如果我们想自定义一些在调试期间使用的编译配置选项，则可以使用-D标识来告诉编译器，具体操作是在"Build Setting"->"Swift Compiler-Custom Flags"->"Other Swift Flags"->"Debug"中添加所需要的配置选项。如我们想添加常用的DEGUB选项，则可以在此加上"-D DEBUG"。这样我们就可以在代码中来执行一些debug与release时不同的操作，如

	#if DEBUG
	    let totalSeconds = totalMinutes
	#else
	    let totalSeconds = totalMinutes * 60
	#endif
	
一个简单的条件编译声明如下所示：

	#if build configuration
	    statements
	#else
		statements
	#endif
	
当然，statements中可以包含0个或多个有效的swift的statements，其中可以包括表达式、语句、和控制流语句。另外，我们也可以使用&&和||操作符来组合多个build configuration，同时，可以使用!操作符来对build configuration取反，如下所示：

	#if build configuration && !build configuration
	    statements
    #elseif build configuration
	    statements
    #else
		statements
    #endif
    
需要注意的是，在swift中，条件编译语句必须在语法上是有效的，因为即使这些代码不会被编译，swift也会对其进行语法检查。

### 参考

1. [Cross-platform Swift](http://www.giorgiocalderolla.com/cross-platform-swift.html)
2. [Shimming in Swift](http://stackoverflow.com/questions/24403551/shimming-in-swift)
3. [Swift System Version Checking](http://nshipster.com/swift-system-version-checking/)
4. [Interacting with C APIs](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithCAPIs.html#//apple_ref/doc/uid/TP40014216-CH8-XID_21)

## 键盘事件

在涉及到表单输入的界面中，我们通常需要监听一些键盘事件，并根据实际需要来执行相应的操作。如，键盘弹起时，要让我们的UIScrollView自动收缩，以能看到整个UIScrollView的内容。为此，在UIWindow.h中定义了如下6个通知常量，来配合键盘在不同时间点的事件处理：

	UIKeyboardWillShowNotification			// 键盘显示之前
	UIKeyboardDidShowNotification			// 键盘显示完成后
	UIKeyboardWillHideNotification			// 键盘隐藏之前
	UIKeyboardDidHideNotification			// 键盘消息之后
	UIKeyboardWillChangeFrameNotification	// 键盘大小改变之前
	UIKeyboardDidChangeFrameNotification	// 键盘大小改变之后
	
这几个通知的object对象都是nil。而userInfo字典都包含了一些键盘的信息，主要是键盘的位置大小信息，我们可以通过使用以下的key来获取字典中对应的值：

	// 键盘在动画开始前的frame
	let UIKeyboardFrameBeginUserInfoKey: String
	
	// 键盘在动画线束后的frame
	let UIKeyboardFrameEndUserInfoKey: String
	
	// 键盘的动画曲线
	let UIKeyboardAnimationCurveUserInfoKey: String
	
	// 键盘的动画时间
	let UIKeyboardAnimationDurationUserInfoKey: String
	
在此，我感兴趣的是键盘事件的调用顺序和如何获取键盘的大小，以适当的调整视图的大小。

从定义的键盘通知的类型可以看到，实际上我们关注的是三个阶段的键盘的事件：显示、隐藏、大小改变。在此我们设定两个UITextField，它们的键盘类型不同：一个是普通键盘，一个是数字键盘。我们监听所有的键盘事件，并打印相关日志(在此就不贴代码了)，直接看结果。

1) 当我们让textField1获取输入焦点时，打印的日志如下：

	keyboard will change
	keyboard will show
	keyboard did change
	keyboard did show

2) 在不隐藏键盘的情况下，让textField2获取焦点，打印的日志如下：

	keyboard will change
	keyboard will show
	keyboard did change
	keyboard did show
	
3) 再收起键盘，打印的日志如下：

	keyboard will change
	keyboard will hide
	keyboard did change
	keyboard did hide
	
从上面的日志可以看出，不管是键盘的显示还是隐藏，都会发送大小改变的通知，而且是在show和hide的对应事件之前。而在大小不同的键盘之间切换时，除了发送change事件外，还会发送show事件(不发送hide事件)。

另外还有两点需要注意的是：

1. 如果是在两个大小相同的键盘之间切换，则不会发送任何消息
2. 如果是普通键盘中类似于中英文键盘的切换，只要大小改变了，都会发送一组或多组与上面2)相同流程的消息

了解了事件的调用顺序，我们就可以根据自己的需要来决定在哪个消息处理方法中来执行操作。为此，我们需要获取一些有用的信息。这些信息是封装在通知的userInfo中，通过上面常量key来获取相关的值。通常我们关心的是UIKeyboardFrameEndUserInfoKey，来获取动画完成后，键盘的frame，以此来计算我们的scroll view的高度。另外，我们可能希望scroll view高度的变化也是通过动画来过渡的，此时UIKeyboardAnimationCurveUserInfoKey和UIKeyboardAnimationDurationUserInfoKey就有用了。

我们可以通过以下方式来获取这些值：

	if let dict = notification.userInfo {
            
        var animationDuration: NSTimeInterval = 0
        var animationCurve: UIViewAnimationCurve = .EaseInOut
        var keyboardEndFrame: CGRect = CGRectZero
        
        dict[UIKeyboardAnimationCurveUserInfoKey]?.getValue(&animationCurve)
        dict[UIKeyboardAnimationDurationUserInfoKey]?.getValue(&animationDuration)
        dict[UIKeyboardFrameEndUserInfoKey]?.getValue(&keyboardEndFrame)
        
		......
    }

实际上，userInfo中还有另外三个值，只不过这几个值从iOS 3.2开始就已经废弃不用了。所以我们不用太关注。

最后说下表单。一个表单界面看着比较简单，但交互和UI总是能想出各种方法来让它变得复杂，而且其实里面设计到的细节还是很多的。像我们金融类的App，通常都会涉及到大量的表单输入，所以如何做好，还是需要花一番心思的。空闲时，打算总结一下，写一篇文章。

### 参考

1. [UIWindow Class Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIWindow_Class/#//apple_ref/doc/constant_group/Keyboard_Notification_User_Info_Keys)

## 零碎

### 自定义UIPickerView的行

UIPickerView的主要内容实际上并不多，主要是一个UIPickerView类和对应的UIPickerViewDelegate，UIPickerViewDataSource协议，分别表示代理和数据源。在此不细说这些，只是解答我们遇到的一个小需求。

通常，UIPickerView是可以定义多列内容的，比如年、月、日三列，这些列之间相互不干扰，可以自已滚自己的，不碍别人的事。不过，我们有这么一个需求，也是有三列，但这三列需要一起滚。嗯，这个就需要另行处理了。

在UIPickerViewDelegate中，声明了下面这样一个代理方法：

	- (UIView *)pickerView:(UIPickerView *)pickerView
            viewForRow:(NSInteger)row
          forComponent:(NSInteger)component
           reusingView:(UIView *)view
             
我们通过这个方法就可以来自定义行的视图。时间不早，废话就不多说了，直接上代码吧：

	- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
	    
	    PickerViewCell *pickerCell = (PickerViewCell *)view;
	    
	    if (!pickerCell) {
	        
	        NSInteger column = 3;
	        
	        pickerCell = [[PickerViewCell alloc] initWithFrame:(CGRect){CGPointZero, [UIScreen mainScreen].bounds.size.width, 45.0f} column:column];
	    }
	    
	    [pickerCell setLabelTexts:@[...]];
	    
	    return pickerCell;
	}
	
我们定义了一个PickerViewCell视图，里面根据我们的传入的column参数来等分放置column个UILabel，并通过setLabelTexts来设置每个UILabel的文本。当然，我们也可以在PickerViewCell去定义UILabel的外观显示。就是这么简单。

不过，还有个需要注意的就是，虽然看上去是显示了3列，但实际上是按1列来处理的，所以下面的实现应该是返回1：

	- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	    return 1;
	}
	
#### 参考

1. [UIPickerViewDelegate Protocol Reference](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIPickerViewDelegate_Protocol/)

### Constructing an object of class type '**' with a metatype value must use a 'required' initializer.

参考
1. [Implementing NSCopying in Swift with subclasses](http://stackoverflow.com/questions/28144475/implementing-nscopying-in-swift-with-subclasses) 


### Swift中"[AnyObject]? does not have a member named generator" 问题的处理

有个小需求，需要遍历当前导航控制器栈的所有ViewController。UINavigationController类自身的viewControllers属性返回的是一个[AnyObject]!数组，不过由于我的导航控制器本身有可能是nil，所以我获取到的ViewController数组如下：

	var myViewControllers: [AnyObject]? = navigationController?.viewControllers

获取到的myViewControllers是一个[AnyObject]?可选类型，这时如果我直接去遍历myViewControllers，如下代码所示

	for controller in myViewControllers {
		...
	}
	
编译器会报错，提示如下：

	[AnyObject]? does not have a member named "Generator"
	
实际上，不管是[AnyObject]?还是其它的诸如[String]?类型，都会报这个错。其原因是可选类型只是个容器，它与其所包装的值是不同的类型，也就是说[AnyObject]是一个数组类型，但[AnyObject]?并不是数组类型。我们可以迭代一个数组，但不是迭代一个非集合类型。

在[stackoverflow](http://stackoverflow.com/questions/26852656/loop-through-anyobject-results-in-does-not-have-a-member-named-generator)上有这样一个有趣的比方，我犯懒就直接贴出来了：

	To understand the difference, let me make a real life example: you buy a new TV on ebay, the package is shipped to you, the first thing you do is to check if the package (the optional) is empty (nil). Once you verify that the TV is inside, you have to unwrap it, and put the box aside. You cannot use the TV while it's in the package. Similarly, an optional is a container: it is not the value it contains, and it doesn't have the same type. It can be empty, or it can contain a valid value.
	
所有，这里的处理应该是：

	if let controllers = myViewControllers {
		for controller in controllers {
			......
		}
	}
	
#### 参考

1. [Loop through [AnyObject]? results in does not have a member named generator](http://stackoverflow.com/questions/26852656/loop-through-anyobject-results-in-does-not-have-a-member-named-generator)
