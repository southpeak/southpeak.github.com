---
layout: post

title: "Cover Flow特效实现"

date: 2014-07-18 22:12:57 +0800

comments: true

categories: iOS 

---

[原文](http://www.cocoachina.com/bbs/read.php?tid=74500)发表在cocoachina上，现在把它整理过来。


## Cover Flow介绍
Cover flow是苹果首创的将多首歌曲的封面以3D界面的形式显示出来的方式。

![image](http://www.cocoachina.com/bbs/attachment/Fid_6/6_38018_be3432a30663e7e.png) 

#### 随处可见的Cover Flow特效
iTunes:在iTunes音乐中点击搜索框左边“查看”项第三个，即以cover flow形式显示专辑封面（前提是你得添加插图或音乐自带插图），也可以在全屏模式使用
 
iPhone/iPod Touch:在竖屏模式播放音乐，iPhone只会显示一张专辑的封面；但当用户将机身旋转为横屏模式后，则能看到多首歌曲的封面以3D界面的形式显示出来，用手指左右的滑动能够进行歌曲的选择，点击相应的专辑封面则会显示该张唱片的曲目，点击相应歌曲即可开始播放。

苹果官网:官网上有以Flash展示的cover flow界面iPod NANO3/4/5:基本类似于在iphone中的操作，利用触摸轮滑动使封面转换Safari 

使用 Cover Flow，您可以像在 iTunes 中翻看专辑插图一样轻松地翻看网站。Cover Flow 可以将您的书签和历史记录显示为大图预览，这样您就能立即找到网站。要查看 Cover Flow 如何工作，请单击 Safari“书签”栏左端的打开书本图标来打开书签列表。在“精选”列表中选择“历史记录”或您要查看其标签的精选。使用水平滚动条来翻看网页预览。您还可以使用鼠标上的滚动按钮来翻看预览。如果您的触控板已配置为支持触控板手势，则您可以左右扫动。

## 特效制作

#### 方法一：UICoverFlowLayer

正式的SDK并未包含UICoverFlowLayer，但是它仍然是标准的uikit。通过steve nygard的类转储(class-dump), 能从uikit框架中提取 UICoverFlowLayer头文件。

由于UICoverFlowLayer是私有的，无法应用于应用程序(无法通过苹果的审查)，所以在此简单介绍使用方法：

1. 将UICoverFlowLayer.h文件拷贝到工程中创建cover flow视图，并将UICoverFlowLayer图层分配到视图图层中
2. 视图发送dragFlow:atPoint消息，以处理与Cover Flow图层的触摸和拖动的交互过程构建cover flow视图控制器，分配和初始化视图，并提供委托和数据源方法

使用UICoverFlowLayer的方法如下代码所示


	UICoverFlowLayer *cfLayer = [[UICoverFlowLayer alloc] initWithFrame:frame numberOfCovers:count];
		
	[[self layer] addSublayer:cfLayer];

#### 方法二：OpenFlow

OpenFlow是一个用于实现Cover Flow特效的开源库，它是基于Quartz实现的，能很好的实现Cover Flow特效，同时又易于使用。

下载地址：[https://github.com/thefaj/OpenFlow](https://github.com/thefaj/OpenFlow)

使用OpenFlow的基本步骤如下：

1. 创建工程
2. 添加OpenFlow源代码到工程中
3. 添加QuartzCore和CoreGraphics框架到工程中
4. 定义CoverFlowViewController(自定义)类
5. 在CoverFlowViewController.h中导入”AFOpenFlowView.h”
6. 实现AFOpenFlowViewDelegate类和AFOpenFlowDataSource协议

定义CoverFlowViewController类的代码如下所示

	//  CoverFlowViewController.h
	//  CoverFlow
	//
	//  Created by Avinash on 4/7/10.
	//  Copyright Apple Inc 2010. All rights reserved.
	//
	
	#import "AFOpenFlowView.h"
	@interface CoverFlowViewController : UIViewController  {
	    // Queue to hold the cover flow p_w_picpath
	    NSOperationQueue *loadImagesOperationQueue;
	}
	@end

实现CoverFlowViewController类

加载图片

	- (void)viewDidLoad {
	    [super viewDidLoad];
	     // loading p_w_picpath into the queue
	    loadImagesOperationQueue = [[NSOperationQueue alloc] init];
	    NSString *imageName;
	    for (int i=0; i < 10; i++) {
	        imageName = [[NSString alloc] initWithFormat:@"cover_%d.jpg", i];
	        [(AFOpenFlowView *)self.view setImage:[UIImage imageNamed:imageName] forIndex:i];
	        [imageName release];
	        NSLog(@"%d is the index",i); 
	   }
	    [(AFOpenFlowView *)self.view setNumberOfImages:10];
	}

实现委托方法，以设置Cover Flow默认图片及通知哪幅图片被选中

	//delegate protocols
	// delegate protocol to tell which image is selected
	- (void)openFlowView:(AFOpenFlowView *)openFlowView selectionDidChange:(int)index{
	    NSLog(@"%d is selected",index);
	}
	// setting the image 1 as the default pic
	- (UIImage *)defaultImage{
	    return [UIImage imageNamed:@"cover_1.jpg"];
	}

修改xib文件中视图的类UIView为AFOpenFlowView(重要)

完成上述步骤之后，就可以运行一下程序看一下效果了。虽然与苹果的Cover Flow效果还是有点差距，但还是不错哦。

#### 方法三：FlowCover

FlowCover也是一个开源库，它是基于OpenGL ES。FlowCover的源代码非常简单，只有FlowCoverView和DataCache两个类。这两个类的功能如下：

1. FlowCoverView：定义主视图。这是一个OpenGL ES视点，可以被嵌套在其它视图中。
2. DataCache：提供一个简单的数据缓存方案，保存一定量的对象，当对象超过最大值时，旧的对象会被舍弃。

使用FlowCover的基本步骤如下：

1. 创建工程
2. 添加FlowCover源代码到工程中
3. 然后就可以像用其它UIView一样使用FlowCoverView了

FlowCover中需要实现FlowCoverViewDelegate协议，该协议中主要有三个方法：

	-(int)flowCoverNumberImages:(FlowCoverView *)view;

返回FlowCoverView视图中显示的图片数量

	-(UIImage *)flowCover:(FlowCoverView *)view cover:(int)cover;

返回FlowCoverView视图中用cover指定的图片

	-(void)flowCover:(FlowCoverView *)view didSelect:(int)cover;

当用户触击FlowCoverView中的cover时调用。


#### 方法四：Tapku框架

Tapku库是一个开源的iOS框架，它包含CoverFlow, Calendar Grid, Char View等等API，总之还是一个比较强大的库。把Tapku加下工程中还是比较复杂的，有兴趣的童鞋可以去网上搜一下。

Tapku下载地址：[https://github.com/devinross/tapkulibrary](https://github.com/devinross/tapkulibrary)

Tapku中与Cover Flow相关的类主要有如下两个：

1. TKCoverflowCoverView: 该类表示的是单个cover。相当于UITableViewCell
2. TKCoverflowView:该类相当于UITableView类，用来管理和显示cover flow中图片及实现cover flow效果。

同时还有两个相关的协议：TKCoverflowViewDelegate， TKCoverflowViewDataSource，分别是 TKCoverflowView的代理及数据源。这两个协议分别有一个必须实现的方法，分别是
TKCoverflowViewDelegate协议的

	- (void) coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasBroughtToFront:(int)index;

TKCoverflowViewDataSource协议的

	- (void) coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasDoubleTapped:(int)index

在工程中使用Tapku的CoverFlow步骤如下

1. 创建工程
2. 添加Tapku库到工程中(该步骤有点麻烦，而且Tapku库比较大，个人认为可以只把CoverFlow相关的类抽取出来直接用)。
3. 新建一个视图控制器CoverflowViewController，在该控制器中添加如下代码

在头文件CoverflowViewController.h中

	@interface CoverflowViewController : UIViewController <TKCoverflowViewDelegate,TKCoverflowViewDataSource,UIScrollViewDelegate> {
	    TKCoverflowView *coverflow; 
	    NSMutableArray *covers; // album covers p_w_picpath
	    ......
	}

在CoverflowViewController.m文件中主要有如下处理

	//创建视图
	- (void) loadView{
	   [super loadView];
	    ......
	    coverflow = [[TKCoverflowView alloc] initWithFrame:self.view.bounds];
	    coverflow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	    coverflow.coverflowDelegate = self;
	    coverflow.dataSource = self;
	    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad){
	       coverflow.coverSpacing = 100;
	      coverflow.coverSize = CGSizeMake(300, 300);
	    }
	    [self.view addSubview:coverflow];
	   ......
	}

实现代理方法

	- (void) coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasBroughtToFront:(int)index{
	}
	//生成单个cover flow
	- (TKCoverflowCoverView*) coverflowView:(TKCoverflowView*)coverflowView coverAtIndex:(int)index{
	    TKCoverflowCoverView *cover = [coverflowView dequeueReusableCoverView];
	    if(cover == nil){
	       BOOL phone = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
	       CGRect rect = phone ? CGRectMake(0, 0, 224, 300) : CGRectMake(0, 0, 300, 600);
	  
	      cover = [[[TKCoverflowCoverView alloc] initWithFrame:rect] autorelease]; // 224
	       cover.baseline = 224;  
	    }
	    cover.image = [covers objectAtIndex:index%[covers count]];
	   return cover;
	}
	- (void) coverflowView:(TKCoverflowView*)coverflowView coverAtIndexWasDoubleTapped:(int)index{
	   TKCoverflowCoverView *cover = [coverflowView coverAtIndex:index];
	    if(cover == nil) return;
	    [UIView beginAnimations:nil context:nil];
	    [UIView setAnimationDuration:1];
	    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:cover cache:YES];
	    [UIView commitAnimations];
	   NSLog(@"Index: %d",index);
	}


## 效果比较
在效果上个人感觉Tapku会好些，渲染流畅，美中不足的是在快速拖动时，停止下来的时候会有抖动的感觉（当然快速拖动这一功能是否需要可视情况而定，如果将此功能禁掉，跟苹果自身的效果还是差不多的）。

OpenFlow的问题在于当改变图像时，新选中的图像会先放大并置于表层，然后才缓动到中间。这是其一个瑕疵。

总体感觉上来讲，苹果自身的CoverFlow的缓动效果还是最好的，有那种渐进渐出的效果，而如上几个开源的库其动画显得有点生硬，有兴趣的童鞋可以试着改进一下。
