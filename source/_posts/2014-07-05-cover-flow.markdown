---
layout: post

title: "Cover flow基本原理及Tapku实现方法"

date: 2014-07-05 17:51:43 +0800

comments: true

categories: iOS

---

这篇是两年前在CocoaChina上写的(德鲁伊)，现在把它归集到这边来。大家也可以查看[原文](http://www.cocoachina.com/bbs/read.php?tid=75699)。



Cover flow是苹果首创的将多首歌曲的封面以3D界面的形式显示出来的方式。如下图所示：

![image](http://cc.cocimg.com/bbs/attachment/Fid_6/6_38018_be3432a30663e7e.png)

从图中可以看到，显示在中间的图片为目标图片，两侧的图片在y轴都旋转了一定的角度，并且每两张图片之间都保持了一定的距离。在交互（如点击两侧的图片）的时候，滑动到中间的图片会逐渐放大，旋转的角度由原来的旋转角度a变为0，且位置上移动中间，变成新的目标图片；同时原处于中间位置的图片则缩小、旋转一定的角度、位置偏移到一侧。所以在整个过程中，主要有两个属性发生了变化：角度与位置(缩放只是视觉上的，并没有进行缩放操作)。

在每次点击一张图片时，如果这张图片在目标图片的左边，则所有的图片都会向右移动，同时做相应的旋转；相反，点击目标图片右侧的图片时，所有图片都会向左移动并做相应的旋转。

从如上描述的效果，可以看出在Cover Flow中最主要的的操作有两个：3D仿射变换与动画。仿射变换实质上是一种线性变换，通常主要用到的仿射变换有平移(Translation)、旋转(Rotation)、缩放(Scale)。
对于这两种操作，iOS都提供了非常简便的接口来实现。接下来我们便以tapku的实现方法为例，来说明实现Cover Flow的基本过程。

## 一、图片的布局
从效果图可以看出，图片是按一条直接排列，图片与图片之间有一定的间距，目标图片是正向显示，两侧的图片则按一定的角度进行了旋转，与目标图片形成一定的角度。同时我们还能看到每个图片都有一个倒影，并且这个倒影是渐变的，由上而下逐渐透明度逐渐减小。

#### 1、 Cover Flow单元的定义
在tapku中，每一个图片附属于一个视图(TKCoverflowCoverView)，这个视图相当于UITableViewCell，它包含了三个要素：图片(imageView)，倒影图片(reflected)，渐变层(gradientLayer)。渐变层覆盖于倒影图片上，且大小位置一致。

TKCoverflowCoverView的声明及布局代码如下所示：

	@interface TKCoverflowCoverView : UIView {
		float baseline;
		UIImageView *imageView;
		UIImageView *reflected;
		CAGradientLayer *gradientLayer;
	}
	@end
	
	- (id)initWithFrame:(CGRect)frame {
		self = [super initWithFrame:frame];
	 	if (self) {
			self.opaque = NO;
			self.backgroundColor = [UIColor clearColor];
			self.layer.anchorPoint = CGPointMake(0.5, 0.5);
			
			imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.width)];
			[self addSubview:imageView];
			reflected = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.frame.size.width, self.frame.size.width, self.frame.size.width)];
			reflected.transform = CGAffineTransformScale(reflected.transform, 1, -1);
			[self addSubview:reflected];
			
			gradientLayer = [CAGradientLayer layer];
			gradientLayer.colors = [NSArray arrayWithObjects:(id)[UIColor colorWithWhite:0 alpha:0.5].CGColor,(id)[UIColor colorWithWhite:0 alpha:1].CGColor,nil];
			gradientLayer.startPoint = CGPointMake(0, 0);
			gradientLayer.endPoint = CGPointMake(0, 0.4);
			gradientLayer.frame = CGRectMake(0, self.frame.size.width, self.frame.size.width, self.frame.size.width);
			[self.layer addSublayer:gradientLayer];
	    }
	    
		return self;
	}


注意：此次将视图的锚点(anchorPoint属性)设置为(0.5, 0.5)，即视图的中心点，目的是让视图以中心点为基点进行旋转。

在进行仿射变换时，视图作为一个整体进行变换。

#### 2、图片的布局
tapku中，图片的布局与交互是在TKCoverflowView类中完成的。类TKCoverflowView继承自UIScrollView，相当于是TableView。

该类中定义是两个仿射变量：

	CATransform3D leftTransform, rightTransform

这两个变量分别设置了两侧图片的仿射变换，具体的设置方法为

	- (void) setupTransforms{
	  	leftTransform = CATransform3DMakeRotation(coverAngle, 0, 1, 0);
		leftTransform = CATransform3DConcat(leftTransform,CATransform3DMakeTranslation(-spaceFromCurrent, 0, -300));
	  	rightTransform = CATransform3DMakeRotation(-coverAngle, 0, 1, 0);
		rightTransform = CATransform3DConcat(rightTransform,CATransform3DMakeTranslation(spaceFromCurrent, 0, -300));
	}


其中coverAngle为旋转的角度。对每个仿射变量同时设置了旋转也平移变换。

Cover Flow单元是存储在一个数组中：
复制代码
NSMutableArray *coverViews;

初始化时设置数组的大小，并存入空对象。在后期获取某个索引位置的单元时，如果该单元为空，则生成一个新的TKCoverflowCoverView并放入相应位置。

	if([coverViews objectAtIndex:cnt] == [NSNull null]){
	  	TKCoverflowCoverView *cover = [dataSource coverflowView:self coverAtIndex:cnt];
		[coverViews replaceObjectAtIndex:cnt withObject:cover];
		......
	}


每个Cover Flow单元的位置计算如下

	CGRect r = cover.frame;
	r.origin.y = currentSize.height / 2 - (coverSize.height/2) - (coverSize.height/16);
	r.origin.x = (currentSize.width/2 - (coverSize.width/ 2)) + (coverSpacing) * cnt;
	cover.frame = r;

其中currentSize,coverSize,coverSpacing都是固定值。从中可以看出所有单元的y值都是一样的，而x值则与其在数组中的索引值相关，索引越大，x值也越大。而这就涉及我们之后的一个问题。一会再讲。
假定目标图片的索引为currentIndex，则目标图片两侧的仿射属性设置如下：

	if(cnt > currentIndex){
		cover.layer.transform = rightTransform;
	}
	else
		cover.layer.transform = leftTransform;

如上即为Cover Flow的基本布局，可以与UITableView比较一下。

## 二、交互
Cover Flow的基本交互是点击两侧的图片，则被点击的图片成为新的目标图片并移动中屏幕中间，而其它图片一起移动，在这个过程中所需要做的就两件事：旋转与平移。

方法很简单：在动画块中重新设置Cover Flow单元的transform属性，这样就可以缓动实现这个动画的过程。实际上只有新旧目标图片及中间的图片需要做这种变换，其余图片的transform属性都是不变的。

	float speed = 0.3;
	[UIView beginAnimations:string context:nil];
	[UIView setAnimationDuration:speed];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)]; 
	for(UIView *v in views){
	int i = [coverViews indexOfObject:v];
		if(i < index) v.layer.transform = leftTransform;
		else if(i > index) v.layer.transform = rightTransform;
		else v.layer.transform = CATransform3DIdentity;
	}
	[UIView commitAnimations];


但这在做的只是旋转了Cover Flow的内容，并没有对Cover Flow进行水平平移，Cover Flow水平位置已由其origin.x值固定。那么水平上的平移是如何实现的呢，我们看下面的代码：

	- (void) snapToAlbum:(BOOL)animated{
	  	UIView *v = [coverViews objectAtIndex:currentIndex];
	 	if((NSObject*)v!=[NSNull null]){
			[self setContentOffset:CGPointMake(v.center.x - (currentSize.width/2), 0) animated:animated];
		}
		else
		{  
			[self setContentOffset:CGPointMake(coverSpacing*currentIndex, 0) animated:animated];
		}
	}


其所做的就是以目标图片为中心，整体平移TKCoverflowView视图。

## 三、总结

由上可以看出，Cover Flow特效的原理很简单：对新旧目标图片及中间的图片以动画的形式做仿射变换。至于仿射变换如何处理，有不同的方法。tapku所实现的方法可以说相对简单灵活。

Android, Flash都有类似的Cover Flow特效实现方法，有兴趣的童鞋可以参考一下。
