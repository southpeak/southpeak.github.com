---

layout: post

title: "源码篇：MBProgressHUD"

date: 2015-03-24 20:41:51 +0800

comments: true

categories: iOS

---

源码来源：[https://github.com/jdg/MBProgressHUD](https://github.com/jdg/MBProgressHUD)

版本：0.9.1

MBProgressHUD是一个显示HUD窗口的第三方类库，用于在执行一些后台任务时，在程序中显示一个表示进度的loading视图和两个可选的文本提示的HUD窗口。我想最多是应用在加载网络数据的时候。其实苹果官方自己有一个带有此功能的类UIProgressHUD，只不过它是私有的，现在不让用。至于实际的效果，可以看看github上工程给出的几张图例(貌似我这经常无法单独打开图片，所以就不在这贴图片了)，也可以运行一下Demo。

具体用法我们就不多说了，参考github上的说明就能用得很顺的。本文主要还是从源码的角度来分析一下它的具体实现。

## 模式

在分析实现代码之前，我们先来看看MBProgressHUD中定义的MBProgressHUDMode枚举。它用来表示HUD窗口的模式，即我们从效果图中看到的几种显示样式。其具体定义如下：

	typedef enum {
	    // 使用UIActivityIndicatorView来显示进度，这是默认值
	    MBProgressHUDModeIndeterminate,
	    
	    // 使用一个圆形饼图来作为进度视图
	    MBProgressHUDModeDeterminate,
	    
	    // 使用一个水平进度条
	    MBProgressHUDModeDeterminateHorizontalBar,
	    
	    // 使用圆环作为进度条
	    MBProgressHUDModeAnnularDeterminate,
	    
	    // 显示一个自定义视图，通过这种方式，可以显示一个正确或错误的提示图
	    MBProgressHUDModeCustomView,
	    
	    // 只显示文本
	    MBProgressHUDModeText
	    
	} MBProgressHUDMode;

通过设置MBProgressHUD的模式，我们可以使用MBProgressHUD自定义的表示进度的视图来满足我们的需求，也可以自定义这个进度视图，当然还可以只显示文本。在下面我们会讨论源码中是如何使用这几个值的。

## 外观

我们先来了解一下MBProgressHUD的基本组成。一个MBProgressHUD视图主要由四个部分组成：

1. loading动画视图(在此做个统称，当然这个区域可以是自定义的一个UIImageView视图)。这个视图由我们设定的模式值决定，可以是菊花、进度条，也可以是我们自定义的视图；
2. 标题文本框(label)：主要用于显示提示的主题信息。这个文本框是可选的，通常位于loading动画视图的下面，且它是单行显示。它会根据labelText属性来自适应文本的大小(有一个长度上限)，如果过长，则超出的部分会显示为"..."；
3. 详情文本框(detailsLabel)。如果觉得标题不够详细，或者有附属信息，就可以将详细信息放在这里面显示。该文本框对应的是显示detailsLabelText属性的值，它是可以多行显示的。另外，详情的显示还依赖于labelText属性的设置，只有labelText属性被设置了，且不为空串，才会显示detailsLabel；
4. HUD背景框。主要是作为上面三个部分的一个背景，用来突出上面三部分。

为了让我们更好地自定义这几个部分，MBProgressHUD还提供了一些属性，我们简单了解一下：

	// 背景框的透明度，默认值是0.8
	@property (assign) float opacity;

	// 背景框的颜色
	// 需要注意的是如果设置了这个属性，则opacity属性会失效，即不会有半透明效果
	@property (MB_STRONG) UIColor *color;

	// 背景框的圆角半径。默认值是10.0
	@property (assign) float cornerRadius;
	
	// 标题文本的字体及颜色
	@property (MB_STRONG) UIFont* labelFont;
	@property (MB_STRONG) UIColor* labelColor;

	// 详情文本的字体及颜色
	@property (MB_STRONG) UIFont* detailsLabelFont;
	@property (MB_STRONG) UIColor* detailsLabelColor;

	// 菊花的颜色，默认是白色
	@property (MB_STRONG) UIColor *activityIndicatorColor;
	
通过以上属性，我们可以根据自己的需要来设置这几个部分的外观。

另外还有一个比较有意思的属性是dimBackground，用于为HUD窗口的视图区域覆盖上一层径向渐变(radial gradient)层，其定义如下：

	@property (assign) BOOL dimBackground;
	
让我们来看看通过它，MBProgressHUD都做了些什么。代码如下：

	- (void)drawRect:(CGRect)rect {
		
		...
	
		if (self.dimBackground) {
			//Gradient colours
			size_t gradLocationsNum = 2;
			CGFloat gradLocations[2] = {0.0f, 1.0f};
			CGFloat gradColors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.75f}; 
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, gradColors, gradLocations, gradLocationsNum);
			CGColorSpaceRelease(colorSpace);
			
			//Gradient center
			CGPoint gradCenter= CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
			//Gradient radius
			float gradRadius = MIN(self.bounds.size.width , self.bounds.size.height) ;
			
			// 由中心向四周绘制渐变
			CGContextDrawRadialGradient (context, gradient, gradCenter,
										 0, gradCenter, gradRadius,
										 kCGGradientDrawsAfterEndLocation);
			CGGradientRelease(gradient);
		}
		...	
	}
	
这段代码由中心向MBProgressHUD视图的四周绘制了一个渐变层。当然，这里的颜色值是写死的，我们无法自行定义。有兴趣的话，大家可以将这个属性设置为YES，看看实际的效果。

## 创建、布局与绘制

除了继承自UIView的-initWithFrame:初始化方法，MBProgressHUD还为我们提供了两个初始化方法，如下所示：

	- (id)initWithWindow:(UIWindow *)window;
	
	- (id)initWithView:(UIView *)view;
	
这两个方法分别传入一个UIWindow对象和一个UIView对象。传入的视图对象仅仅是做为MBProgressHUD视图定义其frame属性的参照，而不会直接将MBProgressHUD视图添加到传入的视图对象上。这个添加操作还得我们自行处理(当然，MBProgressHUD还提供了几个便捷的类方法，我们下面会说明)。

MBProgressHUD提供了几个属性，可以让我们控制HUD的布局，这些属性主要有以下几个：

	// HUD相对于父视图中心点的x轴偏移量和y轴偏移量
	@property (assign) float xOffset;
	@property (assign) float yOffset;
	
	// HUD各元素与HUD边缘的间距
	@property (assign) float margin;
	
	// HUD背景框的最小大小
	@property (assign) CGSize minSize;
	
	// HUD的实际大小
	@property (atomic, assign, readonly) CGSize size;
	
	// 是否强制HUD背景框宽高相等
	@property (assign, getter = isSquare) BOOL square;

需要注意的是，MBProgressHUD视图会充满其父视图的frame内，为此，在MBProgressHUD的layoutSubviews方法中，还专门做了处理，如下代码所示：

	- (void)layoutSubviews {
		[super layoutSubviews];
		
		// Entirely cover the parent view
		UIView *parent = self.superview;
		if (parent) {
			self.frame = parent.bounds;
		}
		
		...
	}

也因此，当MBProgressHUD显示时，它也会屏蔽父视图的各种交互操作。

在布局的过程中，会先根据我们要显示的视图计算出容纳这些视图所需要的总的宽度和高度。当然，会设置一个最大值。我们截取其中一段来看看：

	CGRect bounds = self.bounds;
	
	...

	CGFloat remainingHeight = bounds.size.height - totalSize.height - kPadding - 4 * margin; 
	CGSize maxSize = CGSizeMake(maxWidth, remainingHeight);
	CGSize detailsLabelSize = MB_MULTILINE_TEXTSIZE(detailsLabel.text, detailsLabel.font, maxSize, detailsLabel.lineBreakMode);
	totalSize.width = MAX(totalSize.width, detailsLabelSize.width);
	totalSize.height += detailsLabelSize.height;
	if (detailsLabelSize.height > 0.f && (indicatorF.size.height > 0.f || labelSize.height > 0.f)) {
		totalSize.height += kPadding;
	}
	
	totalSize.width += 2 * margin;
	totalSize.height += 2 * margin;
	
之后，就开始从上到下放置各个视图。在布局代码的最后，计算了一个size值，这是为后面绘制背景框做准备的。

在上面的布局代码中，主要是处理了loading动画视图、标题文本框和详情文本框，而HUD背景框主要是在drawRect:中来绘制的。背景框的绘制代码如下：

	// Center HUD
	CGRect allRect = self.bounds;
	// Draw rounded HUD backgroud rect
	CGRect boxRect = CGRectMake(round((allRect.size.width - size.width) / 2) + self.xOffset,
								round((allRect.size.height - size.height) / 2) + self.yOffset, size.width, size.height);
	float radius = self.cornerRadius;
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, CGRectGetMinX(boxRect) + radius, CGRectGetMinY(boxRect));
	CGContextAddArc(context, CGRectGetMaxX(boxRect) - radius, CGRectGetMinY(boxRect) + radius, radius, 3 * (float)M_PI / 2, 0, 0);
	CGContextAddArc(context, CGRectGetMaxX(boxRect) - radius, CGRectGetMaxY(boxRect) - radius, radius, 0, (float)M_PI / 2, 0);
	CGContextAddArc(context, CGRectGetMinX(boxRect) + radius, CGRectGetMaxY(boxRect) - radius, radius, (float)M_PI / 2, (float)M_PI, 0);
	CGContextAddArc(context, CGRectGetMinX(boxRect) + radius, CGRectGetMinY(boxRect) + radius, radius, (float)M_PI, 3 * (float)M_PI / 2, 0);
	CGContextClosePath(context);
	CGContextFillPath(context);
	
这是最平常的绘制操作，在此不多做解释。

我们上面讲过MBProgressHUD提供了几种窗口模式，这几种模式的主要区别在于loading动画视图的展示。默认情况下，使用的是菊花(MBProgressHUDModeIndeterminate)。我们可以通过设置以下属性，来改变loading动画视图：

	@property (assign) MBProgressHUDMode mode;
	
对于其它几种模式，MBProgressHUD专门我们提供了几个视图类。如果是进度条模式(MBProgressHUDModeDeterminateHorizontalBar)，则使用的是MBBarProgressView类；如果是饼图模式(MBProgressHUDModeDeterminate)或环形模式(MBProgressHUDModeAnnularDeterminate)，则使用的是MBRoundProgressView类。上面这两个类的主要操作就是在drawRect:中根据一些进度参数来绘制形状，大家可以自己详细看一下。

当然，我们还可以自定义loading动画视图，此时选择的模式是MBProgressHUDModeCustomView。或者不显示loading动画视图，而只显示文本框(MBProgressHUDModeText)。

具体显示哪一种loading动画视图，是在-updateIndicators方法中来处理的，其实现如下所示：

	- (void)updateIndicators {
		
		BOOL isActivityIndicator = [indicator isKindOfClass:[UIActivityIndicatorView class]];
		BOOL isRoundIndicator = [indicator isKindOfClass:[MBRoundProgressView class]];
		
		if (mode == MBProgressHUDModeIndeterminate) {
			...
		}
		else if (mode == MBProgressHUDModeDeterminateHorizontalBar) {
			// Update to bar determinate indicator
			[indicator removeFromSuperview];
			self.indicator = MB_AUTORELEASE([[MBBarProgressView alloc] init]);
			[self addSubview:indicator];
		}
		else if (mode == MBProgressHUDModeDeterminate || mode == MBProgressHUDModeAnnularDeterminate) {
			if (!isRoundIndicator) {
				...
			}
			if (mode == MBProgressHUDModeAnnularDeterminate) {
				[(MBRoundProgressView *)indicator setAnnular:YES];
			}
		} 
		else if (mode == MBProgressHUDModeCustomView && customView != indicator) {
			...
		} else if (mode == MBProgressHUDModeText) {
			...
		}
	}

## 显示与隐藏

MBRoundProgressView为我们提供了丰富的显示与隐藏HUD窗口的。在分析这些方法之前，我们先来看看MBProgressHUD为显示与隐藏提供的一些属性：

	// HUD显示和隐藏的动画类型
	@property (assign) MBProgressHUDAnimation animationType;
	
	// HUD显示的最短时间。设置这个值是为了避免HUD显示后立即被隐藏。默认值为0
	@property (assign) float minShowTime;
	
	// 这个属性设置了一个宽限期，它是在没有显示HUD窗口前被调用方法可能运行的时间。
	// 如果被调用方法在宽限期内执行完，则HUD不会被显示。
	// 这主要是为了避免在执行很短的任务时，去显示一个HUD窗口。
	// 默认值是0。只有当任务状态是已知时，才支持宽限期。具体我们看实现代码。
	@property (assign) float graceTime;
	
	// 这是一个标识位，标明执行的操作正在处理中。这个属性是配合graceTime使用的。
	// 如果没有设置graceTime，则这个标识是没有太大意义的。在使用showWhileExecuting:onTarget:withObject:animated:方法时，
	// 会自动去设置这个属性为YES，其它情况下都需要我们自己手动设置。
	@property (assign) BOOL taskInProgress;
	
	// 隐藏时是否将HUD从父视图中移除，默认是NO。
	@property (assign) BOOL removeFromSuperViewOnHide;
	
	// 进度指示器，从0.0到1.0，默认值为0.0
	@property (assign) float progress;
	
	// 在HUD被隐藏后的回调
	@property (copy) MBProgressHUDCompletionBlock completionBlock;
	
以上这些属性都还好理解，可能需要注意的就是graceTime和taskInProgress的配合使用。在下面我们将会看看这两个属性的用法。

对于显示操作，最基本的就是-show:方法(其它几个显示方法都会调用该方法来显示HUD窗口)，我们先来看看它的实现，

	- (void)show:(BOOL)animated {
		useAnimation = animated;
		// If the grace time is set postpone the HUD display
		if (self.graceTime > 0.0) {
			self.graceTimer = [NSTimer scheduledTimerWithTimeInterval:self.graceTime target:self 
							   selector:@selector(handleGraceTimer:) userInfo:nil repeats:NO];
		} 
		// ... otherwise show the HUD imediately 
		else {
			[self showUsingAnimation:useAnimation];
		}
	}
	
可以看到，如果我们没有设置graceTime属性，则会立即显示HUD；而如果设置了graceTime，则会创建一个定时器，并让显示操作延迟到graceTime所设定的时间再执行，而-handleGraceTimer:实现如下：

	- (void)handleGraceTimer:(NSTimer *)theTimer {
		// Show the HUD only if the task is still running
		if (taskInProgress) {
			[self showUsingAnimation:useAnimation];
		}
	}
	
可以看到，只有在设置了taskInProgress标识位为YES的情况下，才会去显示HUD窗口。所以，如果我们要自己调用-show:方法的话，需要酌情考虑设置taskInProgress标识位。

除了-show:方法以外，MBProgressHUD还为我们提供了一组显示方法，可以让我们在显示HUD的同时，执行一些后台任务，我们在此主要介绍两个。其中一个是-showWhileExecuting:onTarget:withObject:animated:，它是基于target-action方式的调用，在执行一个后台任务时显示HUD，等后台任务执行完成后再隐藏HUD，具体实现如下所示：

	- (void)showWhileExecuting:(SEL)method onTarget:(id)target withObject:(id)object animated:(BOOL)animated {
		methodForExecution = method;
		targetForExecution = MB_RETAIN(target);
		objectForExecution = MB_RETAIN(object);	
		// Launch execution in new thread
		self.taskInProgress = YES;
		[NSThread detachNewThreadSelector:@selector(launchExecution) toTarget:self withObject:nil];
		// Show HUD view
		[self show:animated];
	}
	
	- (void)launchExecution {
		@autoreleasepool {
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			// Start executing the requested task
			[targetForExecution performSelector:methodForExecution withObject:objectForExecution];
	#pragma clang diagnostic pop
			// Task completed, update view in main thread (note: view operations should
			// be done only in the main thread)
			[self performSelectorOnMainThread:@selector(cleanUp) withObject:nil waitUntilDone:NO];
		}
	}
	
可以看到，-showWhileExecuting:onTarget:withObject:animated:首先将taskInProgress属性设置为YES，这样在调用-show:方法时，即使设置了graceTime，也确保能在任务完成之前显示HUD。然后开启一个新线程，来异步执行我们的后台任务，最后去显示HUD。

而在异步调用方法-launchExecution中，线程首先是维护了自己的一个@autoreleasepool，所以在我们自己的方法中，就不需要再去维护一个@autoreleasepool了。之后是去执行我们的任务，在任务完成之后，再回去主线程去执行清理操作，并隐藏HUD窗口。

另一个显示方法是-showAnimated:whileExecutingBlock:onQueue:completionBlock:，它是基于GCD的调用，当block中的任务在指定的队列中执行时，显示HUD窗口，任务完成之后执行completionBlock操作，最后隐藏HUD窗口。我们来看看它的具体实现：

	- (void)showAnimated:(BOOL)animated whileExecutingBlock:(dispatch_block_t)block onQueue:(dispatch_queue_t)queue
		 completionBlock:(MBProgressHUDCompletionBlock)completion {
		self.taskInProgress = YES;
		self.completionBlock = completion;
		dispatch_async(queue, ^(void) {
			block();
			dispatch_async(dispatch_get_main_queue(), ^(void) {
				[self cleanUp];
			});
		});
		[self show:animated];
	}
	
这个方法也是首先将taskInProgress属性设置为YES，然后开启一个线程去执行block任务，最后主线程去执行清理操作，并隐藏HUD窗口。

对于HUD的隐藏，MBProgressHUD提供了两个方法，一个是-hide:，另一个是-hide:afterDelay:，后者基于前者，所以我们主要来看看-hide:的实现：

	- (void)hide:(BOOL)animated {
		useAnimation = animated;
		// If the minShow time is set, calculate how long the hud was shown,
		// and pospone the hiding operation if necessary
		if (self.minShowTime > 0.0 && showStarted) {
			NSTimeInterval interv = [[NSDate date] timeIntervalSinceDate:showStarted];
			if (interv < self.minShowTime) {
				self.minShowTimer = [NSTimer scheduledTimerWithTimeInterval:(self.minShowTime - interv) target:self 
									selector:@selector(handleMinShowTimer:) userInfo:nil repeats:NO];
				return;
			} 
		}
		// ... otherwise hide the HUD immediately
		[self hideUsingAnimation:useAnimation];
	}
	
我们可以看到，在设置了minShowTime属性并且已经显示了HUD窗口的情况下，会去判断显示的时间是否小于minShowTime指定的时间，如果是，则会开启一个定时器，等到显示的时间到了minShowTime所指定的时间，才会去隐藏HUD窗口；否则会直接去隐藏HUD窗口。

隐藏的实际操作主要是去做了些清理操作，包括根据设定的removeFromSuperViewOnHide值来执行是否从父视图移除HUD窗口，以及执行completionBlock操作，还有就是执行代理的hudWasHidden:方法。这些操作是在私有方法-done里面执行的，实现如下：

	- (void)done {
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		isFinished = YES;
		self.alpha = 0.0f;
		if (removeFromSuperViewOnHide) {
			[self removeFromSuperview];
		}
	#if NS_BLOCKS_AVAILABLE
		if (self.completionBlock) {
			self.completionBlock();
			self.completionBlock = NULL;
		}
	#endif
		if ([delegate respondsToSelector:@selector(hudWasHidden:)]) {
			[delegate performSelector:@selector(hudWasHidden:) withObject:self];
		}
	}
	
## 其它

MBProgressHUD的一些主要的代码差不多已经分析完了，最后还有些边边角角的地方，一起来看看。

### 显示和隐藏的便捷方法

除了上面描述的实例方法之外，MBProgressHUD还为我们提供了几个便捷显示和隐藏HUD窗口的方法，如下所示：

	+ (MB_INSTANCETYPE)showHUDAddedTo:(UIView *)view animated:(BOOL)animated
	
	+ (BOOL)hideHUDForView:(UIView *)view animated:(BOOL)animated
	
	+ (NSUInteger)hideAllHUDsForView:(UIView *)view animated:(BOOL)animated
	
方法的签名已经很能说明问题了，在此不多描述。

### 部分属性值的设置

对于部分属性(主要是"外观"一节中针对菊花、标题文本框和详情文本框的几个属性值)，为了在设置将这些属性时修改对应视图的属性，并没有直接为每个属性生成一个setter，而是通过KVO来监听这些属性值的变化，再将这些值赋值给视图的对应属性，如下所示：

	// 监听的属性数组
	- (NSArray *)observableKeypaths {
		return [NSArray arrayWithObjects:@"mode", @"customView", @"labelText", @"labelFont", @"labelColor", ..., nil];
	}
	
	// 注册KVO
	- (void)registerForKVO {
		for (NSString *keyPath in [self observableKeypaths]) {
			[self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:NULL];
		}
	}
	
	- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
		if (![NSThread isMainThread]) {
			[self performSelectorOnMainThread:@selector(updateUIForKeypath:) withObject:keyPath waitUntilDone:NO];
		} else {
			[self updateUIForKeypath:keyPath];
		}
	}
	
	- (void)updateUIForKeypath:(NSString *)keyPath {
		if ([keyPath isEqualToString:@"mode"] || [keyPath isEqualToString:@"customView"] ||
			[keyPath isEqualToString:@"activityIndicatorColor"]) {
			[self updateIndicators];
		} else if ([keyPath isEqualToString:@"labelText"]) {
			label.text = self.labelText;
		} 
		
		...
		
		[self setNeedsLayout];
		[self setNeedsDisplay];
	}
	
### 代理

MBProgressHUD还为我们提供了一个代理MBProgressHUDDelegate，这个代理中只提供了一个方法，即：

	- (void)hudWasHidden:(MBProgressHUD *)hud;
	
这个代理方法是在隐藏HUD窗口后调用，如果此时我们需要在我们自己的实现中执行某些操作，则可以实现这个方法。

## 问题

MBProgressHUD为我们提供了一个HUD窗口的很好的实现，不过个人在使用过程中，觉得它给我们提供的交互功能太少。其代理只提供了一个-hudWasHidden:方法，而且我们也无法通过点击HUD来执行一些操作。在现实的需求中，可能存在这种情况：比如一个网络操作，在发送请求等待响应的过程中，我们会显示一个HUD窗口以显示一个loading框。但如果我们想在等待响应的过程中，在当前视图中取消这个网络请求，就没有相应的处理方式，MBProgressHUD没有为我们提供这样的交互操作。当然这时候，我们可以根据自己的需求来修改源码。

## 与SVProgressHUD的对比

与MBProgressHUD类似，SVProgressHUD类库也为我们提供了在视图中显示一个HUD窗口的功能。两者的基本思路是差不多的，差别更多的是在实现细节上。相对于MBProgressHUD来说，SVProgressHUD的实现有以下几点不同：

1. SVProgressHUD类对外提供的都是类方法，包括显示、隐藏、和视图属性设置都是使用类方法来操作。其内部实现为一个单例对象，类方法实际是针对这个单例对象来操作的。
2. SVProgressHUD主要包含三部分：loading视图、提示文本框和背景框，没有详情文本框。
3. SVProgressHUD默认提供了正确、错误和信息三种状态视图(与loading视图同一位置，根据需要来设置)。当然MBProgressHUD中，也可以自定义视图(customView)来显示相应的状态视图。
4. SVProgressHUD为我们提供了更多的交互操作，包括点击事件、显示事件及隐藏事件。不过这些都是通过通知的形式向外发送，所以我们需要自己去监听这些事件。
5. SVProgressHUD中一些loading动画是以Layer动画的形式来实现的。

SVProgressHUD的实现细节还未详细去看，有兴趣的读者可以去研究一下。这两个HUD类库各有优点，大家在使用时，可根据自己的需要和喜好来选择。

## 小结

总体来说，MBProgressHUD的代码相对朴实，简单易懂，没有什么花哨难懂的东西。就技术点而言，也没有太多复杂的技术，都是我们常用的一些东西。就使用而言，也是挺方便的，参考一下github上的使用指南就能很快上手。