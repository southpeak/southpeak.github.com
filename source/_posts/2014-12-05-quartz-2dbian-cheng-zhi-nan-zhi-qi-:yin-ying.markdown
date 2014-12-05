---

layout: post

title: "Quartz 2D编程指南之七：阴影"

date: 2014-12-05 21:47:51 +0800

comments: true

categories: iOS

---


阴影是绘制在一个图形对象下的且有一定偏移的图片，它用于模拟光源照射到图形对象上所形成的阴影效果，如果7-1所示。文本也可以有阴影。阴影可以让一幅图像看上去是立体的或者是浮动的。

Figure 7-1  A shadow

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/angle.gif)
 
阴影有三个属性：

1. x偏移值，用于指定阴影相对于图片在水平方向上的偏移值。
2. y偏移值，用于指定阴影相对于图片在竖直方向上的偏移值。
3. 模糊(blur)值，用于指定图像是有一个硬边(hard edge，如图7-2左边图片所示)，还是一个漫射边(diffuse edge，如图7-1右边图片所示)

本章将描述阴影是如何工作的及如何用Quartz 2D API来创建阴影。

Figure 7-2  A shadow with no blur and another with a soft edge

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/blur_value.gif)

## 阴影是如何工作的

Quartz中的阴影是图形状态的一部分。我们可以调用函数CGContextSetShadow来创建，并传入一个图形上下文、偏移值及模糊值。阴影被设置后，任何绘制的对象都有一个阴影，且该阴影在设备RGB颜色空间中呈现出黑色的且alpha值为1/3。换句话说，阴影是用RGBA值{0, 0, 0, 1.0/3.0}设置的。

我们可以调用函数CGContextSetShadowWithColor来设置彩色阴影，并传递一个图形上下文、 偏移值、模糊值有CGColor颜色对象。颜色值依赖于颜色空间。

如何在调用CGContextSetShadow或CGContextSetShadowWithColor之前保存了图形状态，我们可以通过恢复图形状态来关闭阴影。我们也可以通过设置阴影颜色为NULL来关闭阴影。

## 基于图形上下文的阴影绘制惯例
偏移值指定了阴影相对于相关图像的位置。这些偏移值由图形上下文来描述，并用于计算阴影的位置：

1. 一个正值的x偏移量指定阴影位于图形对象的右侧。
2. 在Mac OS X中，正值的y指定阴影位于图形对象的上边，这与Quartz 2D默认的坐标值匹配。
3. 在iOS中，如果我们用Quartz 2D API来创建PDF或者位图图形上下文，则正值的y指定阴影位于图形对象的上边。
4. 在iOS中，如果图形上下文是由UIKit创建的，则正值的y指定阴影位于图形对象的下边。这与UIKit坐标系统相匹配。
5. 阴影绘制惯例不受CTM影响

## 绘制阴影

按照如下步骤来绘制阴影

1. 保存图形状态
2. 调用函数CGContextSetShadow，传递相应的值
3. 使用阴影绘制所有的对象
4. 恢复图形状态

按照如下步骤来绘制彩色阴影

1. 保存图形状态
2. 创建一个CGColorSpace对象，确保Quartz能正确地解析阴影颜色
3. 创建一个CGColor对象来指定阴影的颜色
4. 调用CGContextSetShadowWithColor，并传递相应的值
5. 使用阴影绘制所有的对象
6. 恢复图形状态

图7-3显示了两个带有阴影的矩形，其中一个是彩色阴影。

Figure 7-3  A colored shadow and a gray shadow

![image](https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/Art/code_shadows.gif)
 

列表清单显示了如何创建图7-3中的图像。

Listing 7-1  A function that sets up shadows

	void MyDrawWithShadows (CGContextRef myContext, float wd, float ht);
	{
	    CGSize          myShadowOffset = CGSizeMake (-15,  20);
	    float           myColorValues[] = {1, 0, 0, .6};
	    CGColorRef      myColor;
	    CGColorSpaceRef myColorSpace;
	    
	    CGContextSaveGState(myContext);
	    
	    CGContextSetShadow (myContext, myShadowOffset, 5); 
	    
	    // Your drawing code here
	    CGContextSetRGBFillColor (myContext, 0, 1, 0, 1);
	    CGContextFillRect (myContext, CGRectMake (wd/3 + 75, ht/2 , wd/4, ht/4));
	    
	    myColorSpace = CGColorSpaceCreateDeviceRGB ();
	    myColor = CGColorCreate (myColorSpace, myColorValues);
	    CGContextSetShadowWithColor (myContext, myShadowOffset, 5, myColor);
	    
	    // Your drawing code here
	    CGContextSetRGBFillColor (myContext, 0, 0, 1, 1);
	    CGContextFillRect (myContext, CGRectMake (wd/3-75,ht/2-100,wd/4,ht/4));
	    
	    CGColorRelease (myColor);
	    CGColorSpaceRelease (myColorSpace); 
	    
	    CGContextRestoreGState(myContext);
	}
